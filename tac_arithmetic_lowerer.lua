local Operand = require("operand")
local util = require("util")

local operand = Operand.operand
local reg_rvalue_operands = Operand.reg_rvalue_operands
local rvalue_operands = Operand.rvalue_operands
local lvalue_operands = Operand.lvalue_operands
local mem_lvalue_operands = Operand.mem_lvalue_operands

local tac_arithmetic_lowerer = {}

function fixed_point_division_16(dividend, divisor, quotient, remainder)
    assert(divisor.type == "i", "divisor must be an immediate")
    assert(reg_rvalue_operands[dividend.type], "dividend must be an rvalue oriented operand in a register")

    local fixed_point_factor = (1 << 16) // divisor.value
    local end_label = operand.lb()
    local divisor_temp = operand.t()
    return {
        {type="mulh", source=dividend, third=operand.i(fixed_point_factor), dest=quotient},
        {type="mull3", source=quotient, third=divisor, dest=remainder},
        {type="sub3", source=dividend, third=remainder, dest=remainder},
        {type="mov", source=divisor, dest=divisor_temp},
        {type="cmp", first=remainder, second=divisor_temp},
        {type="jb", target=end_label}, -- ja is similar to jl since the operands are reversed
        {type="add", source=operand.i(1), dest=quotient},
        {type="sub", source=divisor, dest=remainder},
        {type="label", target=end_label}
    }

end

function magic_number_division_32(dividend, divisor, quotient, remainder)
    assert(divisor.type == "i", "divisor must be an immediate")
    assert(reg_rvalue_operands[dividend.type], "dividend must be an rvalue oriented operand in a register")

    if(divisor.value == 1) then
        return {{type="mov3", low=dividend, high=dividend, dest=quotient},
                {type="mov", source=operand.i(0), dest=remainder}            
        }
    end

    local magic_number = math.ceil((1 << 32) / divisor.value)
    local magic_number_low = operand.i(magic_number % 65536)
    local magic_number_high = operand.i(magic_number >> 16)
    local end_label = operand.lb()

    local dividend_high = operand.t()
    local dividend_low = operand.t()
    local quotient_16 = operand.t()
    local quotient_32 = operand.t()
    local quotient_48 = operand.t()
    local quotient_64 = operand.t()
    local remainder_low = operand.t()
    local remainder_high = operand.t()
    local temp = operand.t()

    local original_16 = operand.t()
    local original_32 = operand.t()

    local negative_remainder_label = operand.lb()
    local positive_remainder_label = operand.lb()

    return {
        {type="exh", low=dividend, dest=dividend_high, high=operand.r("r0")},
        {type="mov", source=dividend, dest=dividend_low},
        {type="mull3", source=dividend_low, third=magic_number_low, dest=quotient_16},
        {type="mulh", source=dividend_low, third=magic_number_low, dest=quotient_32},
        {type="mulh", source=dividend_high, third=magic_number_low, dest=quotient_48},
        {type="mulh", source=dividend_high, third=magic_number_high, dest=quotient_64},

        {type="mull3", source=dividend_low, third=magic_number_high, dest=temp},
        {type="add", source=temp, dest=quotient_32},
        {type="adc", source=operand.r("r0"), dest=quotient_48},
        {type="adc", source=operand.r("r0"), dest=quotient_64},

        {type="mull3", source=dividend_high, third=magic_number_low, dest=temp},
        {type="add", source=temp, dest=quotient_32},
        {type="adc", source=operand.r("r0"), dest=quotient_48},
        {type="adc", source=operand.r("r0"), dest=quotient_64},

        {type="mulh", source=dividend_low, third=magic_number_high, dest=temp},
        {type="add", source=temp, dest=quotient_48},
        {type="adc", source=operand.r("r0"), dest=quotient_64},
        
        {type="mull3", source=dividend_high, third=magic_number_high, dest=temp},
        {type="add", source=temp, dest=quotient_48},
        {type="adc", source=operand.r("r0"), dest=quotient_64},

        

        -- -- calculate remainder
        {type="mull3", source=quotient_48, third=operand.i(divisor.value % 65536), dest=original_16},
        {type="mulh", source=quotient_48, third=operand.i(divisor.value % 65536), dest=original_32},
        {type="mull3", source=quotient_64, third=operand.i(divisor.value % 65536), dest=temp},
        {type="add", source=temp, dest=original_32},
        {type="mull3", source=quotient_48, third=operand.i(divisor.value >> 16), dest=temp},
        {type="add", source=temp, dest=original_32},


        {type="cmp", first=dividend_high, second=original_32},
        {type="jb", target=negative_remainder_label},
        {type="ja", target=positive_remainder_label},
        {type="cmp", first=dividend_low, second=original_16},
        {type="jae", target=positive_remainder_label},

        {type="label", target=negative_remainder_label},
        -- add divisor
        {type="sub", dest=quotient_48, source=operand.i(1)},
        {type="sbb", dest=quotient_64, source=operand.r("r0")},
        {type="sub", dest=original_16, source=operand.i(divisor.value % 65536)},
        {type="sbb", dest=original_32, source=operand.i(divisor.value >> 16)},

        {type="label", target=positive_remainder_label},
        {type="sub3", source=dividend_low, third=original_16, dest=remainder_low},
        {type="sbb3", source=dividend_high, third=original_32, dest=remainder_high},
        {type="exh", low=operand.r("r0"), dest=remainder_high, high=remainder_high},
        {type="mov3", low=remainder_low, high=remainder_high, dest=remainder},

        {type="exh", low=operand.r("r0"), dest=quotient_64, high=quotient_64},
        {type="mov3", low=quotient_48, high=quotient_64, dest=quotient},


    }
end

function tac_arithmetic_lowerer.fixed_point_division(instruction, dividend, divisor, quotient, remainder)
    
    if(divisor.bitsize == 16 and dividend.bitsize == 16) then
        return fixed_point_division_16(dividend, divisor, quotient, remainder)
    else
        return magic_number_division_32(dividend, divisor, quotient, remainder)
    end
end

function tac_arithmetic_lowerer.long_division_16(instruction, dividend, divisor, quotient, remainder)
    assert(reg_rvalue_operands[dividend.type], "dividend must be an rvalue oriented operand in a register")
    assert(reg_rvalue_operands[divisor.type], "divisor must be an rvalue oriented operand in a register")

    local bit_index = operand.t()
    local loop_label = operand.lb()
    local temp = operand.t()
    local r_lt_d_label = operand.lb()
    local end_label = operand.lb()
    return {
        {type="mov", source=operand.i(0), dest=quotient},
        {type="mov", source=operand.i(0), dest=remainder},
        {type="mov", source=operand.i(15), dest=bit_index},
        {type="label", target=loop_label},
        {type="cmp", first=bit_index, second=operand.i(0)},
        {type="jl", target=end_label},
        {type="shl", source=operand.i(1), dest=remainder},
        {type="shr3", source=dividend, third=bit_index, dest=temp},
        {type="and", source=operand.i(1), dest=temp},
        {type="or", source=temp, dest=remainder},
        {type="cmp", first=remainder, second=divisor},
        {type="jb", target=r_lt_d_label},
        {type="sub", source=divisor, dest=remainder},
        {type="mov", source=operand.i(1), dest=temp},
        {type="shl", source=bit_index, dest=temp},
        {type="or", source=temp, dest=quotient},
        {type="label", target=r_lt_d_label},
        {type="sub", source=operand.i(1), dest=bit_index},
        {type="jmp", target=loop_label},
        {type="label", target=end_label}
    }
end

function tac_arithmetic_lowerer.long_division(instruction, dividend, divisor, quotient, remainder)
    if(divisor.bitsize == 16 and dividend.bitsize == 16) then
        return tac_arithmetic_lowerer.long_division_16(instruction, dividend, divisor, quotient, remainder)
    else
        return tac_arithmetic_lowerer.long_division_32(instruction, dividend, divisor, quotient, remainder)
    end
end

function tac_arithmetic_lowerer.long_division_32(instruction, dividend, divisor, quotient, remainder)
    assert(reg_rvalue_operands[dividend.type], "dividend must be an rvalue oriented operand in a register")
    assert(reg_rvalue_operands[divisor.type], "divisor must be an rvalue oriented operand in a register")

    local dividend_high = operand.t()
    local divisor_high = operand.t()
    local bit_index = operand.t()
    local temp = operand.t()
    local temp2 = operand.t()
    local loop_label = operand.lb()
    local end_label = operand.lb()
    local continue_label1 = operand.lb()
    local bit_index_is_high = operand.lb()
    local remainder_lt_divisor_label = operand.lb()
    local update_quotient_end = operand.lb()
    local update_quotient_bit_index_is_high = operand.lb()
    local resolve_bit_index_size_end = operand.lb()
    local remainder_gt_divisor_label = operand.lb()
    local remainder_high = operand.t()
    local quotient_high = operand.t()

    return {
        {type="exh", low=dividend, dest=dividend_high, high=operand.r("r0")},
        {type="exh", low=divisor, dest=divisor_high, high=operand.r("r0")},
        {type="mov", source=operand.i(0), dest=quotient},
        {type="mov", source=operand.i(0), dest=remainder},
        {type="mov", source=operand.i(0), dest=remainder_high},
        {type="mov", source=operand.i(0), dest=quotient_high},
        {type="mov", source=operand.i(31), dest=bit_index},
        {type="label", target=loop_label},
        {type="cmp", first=bit_index, second=operand.i(0)},
        {type="jl", target=end_label},

        -- shift remainder
        {type="shl", source=operand.i(1), dest=remainder_high},
        {type="test", first=remainder, second=operand.i(0x8000)},
        {type="jz", target=continue_label1},
        {type="add", source=operand.i(1), dest=remainder_high},
        {type="label", target=continue_label1},
        {type="shl", source=operand.i(1), dest=remainder},

        {type="cmp", first=bit_index, second=operand.i(15)},
        {type="jg", target=bit_index_is_high},
        
        {type="shr3", source=dividend, third=bit_index, dest=temp},
        {type="jmp", target=resolve_bit_index_size_end},
        {type="label", target=bit_index_is_high},
        {type="sub3", source=bit_index, third=operand.i(16), dest=temp},
        {type="shr3", source=dividend_high, third=temp, dest=temp},

        {type="label", target=resolve_bit_index_size_end},
        {type="and", source=operand.i(1), dest=temp},
        {type="or", source=temp, dest=remainder},
        

        -- check if remainder is less than divisor
        {type="cmp", first=remainder_high, second=divisor_high},
        {type="jb", target=remainder_lt_divisor_label},
        {type="ja", target=remainder_gt_divisor_label},
        {type="cmp", first=remainder, second=divisor},
        {type="jb", target=remainder_lt_divisor_label},

        -- subtract divisor from remainder and update quotient
        {type="label", target=remainder_gt_divisor_label},
        {type="sub", source=divisor, dest=remainder},
        {type="sbb", source=divisor_high, dest=remainder_high},

        {type="mov", source=operand.i(1), dest=temp},
        {type="cmp", first=bit_index, second=operand.i(15)},
        {type="jg", target=update_quotient_bit_index_is_high},
        {type="shl", source=bit_index, dest=temp},
        {type="or", source=temp, dest=quotient},

        {type="jmp", target=update_quotient_end},

        {type="label", target=update_quotient_bit_index_is_high},
        {type="sub3", source=bit_index, third=operand.i(16), dest=temp},
        {type="mov", source=operand.i(1), dest=temp2},
        {type="shl", source=temp, dest=temp2},
        {type="or", source=temp2, dest=quotient_high},

        {type="label", target=update_quotient_end},
        {type="label", target=remainder_lt_divisor_label},
        {type="sub", source=operand.i(1), dest=bit_index},
        {type="jmp", target=loop_label},
        {type="label", target=end_label},
        {type="exh", low=operand.r("r0"), dest=quotient_high, high=quotient_high},
        {type="mov3", low=quotient, high=quotient_high, dest=quotient},
        {type="exh", low=operand.r("r0"), dest=remainder_high, high=remainder_high},
        {type="mov3", low=remainder, high=remainder_high, dest=remainder},

    }
end

function tac_arithmetic_lowerer.shl(instruction, source, dest)
    assert(reg_rvalue_operands[source.type] or source.type == "i", "source must be an rvalue oriented operand in a register or an immediate")
    assert(reg_rvalue_operands[dest.type], "dest must be an rvalue oriented operand in a register")
    if(dest.bitsize == 16) then
        return {instruction}
    else

        if(source.type == "i" and source.value == 0) then
            return {}
        end

        local source_reg = operand.t()
        local dest_high = operand.t()
        local temp = operand.t()
        local carry_part = operand.t()
        local end_label = operand.lb()
        local simulate_carry = operand.lb()
        local shift_ge_16_label = operand.lb()
        local build_long_label = operand.lb()
        return {
            {type="mov", source=source, dest=source_reg},
            {type="cmp", first=source_reg, second=operand.r("r0")}, -- if shift == 0, exit
            {type="jz", target=end_label},

            {type="exh", low=dest, high=operand.r("r0"), dest=dest_high}, -- get high dest

            {type="cmp", first=source_reg, second=operand.i(16)}, -- if shift >= 16, move words around rather than simulating a shift carry
            {type="jge", target=shift_ge_16_label},
            {type="jmp", target=simulate_carry},

            {type="label", target=shift_ge_16_label},
            {type="sub", source=operand.i(16), dest=source_reg},
            {type="mov", source=dest, dest=dest_high},
            {type="shl", source=source_reg, dest=dest_high},
            {type="mov", source=operand.i(0), dest=dest},
            {type="jmp", target=build_long_label},
            {type="label", target=simulate_carry},


            {type="mov", source=operand.i(16), dest=temp},  -- temp = 16 - shift
            {type="sub", dest=temp, source=source_reg},
            
            {type="mov", dest=carry_part, source=dest},  -- carry_part = dest >> (16 - shift_cap_16)
            {type="shr", dest=carry_part, source=temp},

            {type="shl", source=source_reg, dest=dest_high},
            {type="or", source=carry_part, dest=dest_high}, -- dest_high |= carry_part

            {type="shl", source=source_reg, dest=dest},

            {type="label", target=build_long_label},
            {type="exh", low=operand.r("r0"), dest=dest_high, high=dest_high},
            {type="mov3", low=dest, high=dest_high, dest=dest},

            

            {type="label", target=end_label}
        }
    end
end

function tac_arithmetic_lowerer.shr(instruction, source, dest)
    assert(reg_rvalue_operands[source.type] or source.type == "i", "source must be an rvalue oriented operand in a register or an immediate")
    assert(reg_rvalue_operands[dest.type], "dest must be an rvalue oriented operand in a register")
    if(dest.bitsize == 16) then
        return {instruction}
    else

        if(source.type == "i" and source.value == 0) then
            return {}
        end

        local source_reg = operand.t()
        local dest_high = operand.t()
        local temp = operand.t()
        local carry_part = operand.t()
        local end_label = operand.lb()
        local simulate_carry = operand.lb()
        local shift_ge_16_label = operand.lb()
        local build_long_label = operand.lb()
        return {
            {type="mov", source=source, dest=source_reg},
            {type="cmp", first=source_reg, second=operand.r("r0")}, -- if shift == 0, exit
            {type="jz", target=end_label},

            {type="exh", low=dest, high=operand.r("r0"), dest=dest_high}, -- get high dest

            {type="cmp", first=source_reg, second=operand.i(16)}, -- if shift >= 16, move words around rather than simulating a shift carry
            {type="jge", target=shift_ge_16_label},
            {type="jmp", target=simulate_carry},

            {type="label", target=shift_ge_16_label},
            {type="sub", source=operand.i(16), dest=source_reg},
            {type="mov", source=dest, dest=dest_high},
            {type="shr", source=source_reg, dest=dest_high},
            {type="mov", source=operand.i(0), dest=dest},
            {type="jmp", target=build_long_label},
            {type="label", target=simulate_carry},


            {type="mov", source=operand.i(16), dest=temp},  -- temp = 16 - shift
            {type="sub", dest=temp, source=source_reg},
            
            {type="mov", dest=carry_part, source=dest_high},  -- carry_part = dest >> (16 - shift_cap_16)
            {type="shl", dest=carry_part, source=temp},

            {type="shr", source=source_reg, dest=dest},
            {type="or", source=carry_part, dest=dest}, -- dest_high |= carry_part

            {type="shr", source=source_reg, dest=dest_high},

            {type="label", target=build_long_label},
            {type="exh", low=operand.r("r0"), dest=dest_high, high=dest_high},
            {type="mov3", low=dest, high=dest_high, dest=dest},

            

            {type="label", target=end_label}
        }
    end
end

function tac_arithmetic_lowerer.neg(instruction, primary)
    assert(reg_rvalue_operands[primary.type], "primary must be an rvalue oriented operand in a register")
    -- two's complement negation
    if(primary.bitsize == 16) then
        return  {
            {type="xor", source=operand.i(65535), dest=primary},
            {type="add", source=operand.i(1), dest=primary}
        }
    else
        local primary_high = operand.t()
        return {
            {type="exh", low=primary, high=operand.r("r0"), dest=primary_high},
            {type="xor", source=operand.i(65535), dest=primary},
            {type="xor", source=operand.i(65535), dest=primary_high},
            {type="add", source=operand.i(1), dest=primary},
            {type="adc", source=operand.r("r0"), dest=primary_high},
            {type="exh", low=operand.r("r0"), dest=primary_high, high=primary_high},
            {type="mov3", low=primary, high=primary_high, dest=primary}
        }
    end
end

function tac_arithmetic_lowerer.mull(instruction, source, dest)
    local mul_instruction = nil
    if(source.bitsize == 16 and dest.bitsize == 16) then
        mul_instruction = {instruction}
    else
        local temp_low = operand.t()
        local temp_high = operand.t()
        local temp = operand.t()
        local dest_high = operand.t()
        local source_high = operand.t()

        if(source.type == "i") then
            if(source.value < 65536) then
                mul_instruction = {
                    {type="exh", low=dest, dest=dest_high, high=operand.r("r0")},
                    {type="mull3", source=dest, third=source, dest=temp_low},
                    {type="mulh", source=dest, third=source, dest=temp_high},
                    {type="mull3", source=dest_high, third=source, dest=temp},
                    {type="add", source=temp, dest=temp_high},
                    {type="exh", low=operand.r("r0"), dest=temp_high, high=temp_high},
                    {type="mov3", low=temp_low, dest=dest, high=temp_high}
                }
            else
                local source_low = operand.i(source.value % 65536)
                local source_high = operand.i(source.value >> 16)
                mul_instruction = {
                    {type="exh", low=dest, dest=dest_high, high=operand.r("r0")},
                    {type="mull3", source=dest, third=source_low, dest=temp_low},
                    {type="mulh", source=dest, third=source_low, dest=temp_high},
                    {type="mull3", source=source_high, third=dest, dest=temp},
                    {type="add", source=temp, dest=temp_high},
                    {type="mull3", source=dest, third=source_high, dest=temp},
                    {type="add", source=temp, dest=temp_high},
                    {type="exh", low=operand.r("r0"), dest=temp_high, high=temp_high},
                    {type="mov3", low=temp_low, dest=dest, high=temp_high}
                }
            end
        else
            mul_instruction = {
                {type="exh", low=source, dest=source_high, high=operand.r("r0")},
                {type="exh", low=dest, dest=dest_high, high=operand.r("r0")},
                {type="mull3", source=source, third=dest, dest=temp_low},
                {type="mulh", source=source, third=dest, dest=temp_high},
                {type="mull3", source=source_high, third=dest, dest=temp},
                {type="add", source=temp, dest=temp_high},
                {type="mull3", source=source, third=dest_high, dest=temp},
                {type="add", source=temp, dest=temp_high},
                {type="exh", low=operand.r("r0"), dest=temp_high, high=temp_high},
                {type="mov3", low=temp_low, dest=dest, high=temp_high}
            }
        end

    end

    return mul_instruction
end

function tac_arithmetic_lowerer.cmp(instruction, first, second)
    if(first.bitsize == 16 and second.bitsize == 16) then
        return {instruction}
    else
        local first_high = operand.t()
        local second_high = operand.t()
        local not_equal_high_label = operand.lb()
        return {
            {type="exh", low=first, dest=first_high, high=operand.r("r0")},
            {type="exh", low=second, dest=second_high, high=operand.r("r0")},
            {type="cmp", first=first_high, second=second_high},
            {type="jne", target=not_equal_high_label},
            {type="cmp", first=first, second=second},
            {type="label", target=not_equal_high_label}
        }
    end
end

function tac_arithmetic_lowerer.movsx(instruction, source, dest)
    assert(Operand.reg_rvalue_operands[source.type] and Operand.reg_rvalue_operands[dest.type], "source and dest must be register operands holding rvalues")

    if(source.bitsize == 16 and dest.bitsize == 32) then
        local positive_label = operand.lb()
        local end_label = operand.lb()
        local temp = operand.t()

        return {{type="cmp", first=source, second=operand.i(0x8000)},
                {type="jae", target=positive_label},
                {type="mov", source=operand.i(0xFFFF), dest=temp},
                {type="exh", low=operand.r("r0"), dest=temp, high=temp},
                {type="mov3", low=source, high=temp, dest=dest},
                {type="jmp", target=end_label},
                {type="label", target=positive_label},
                {type="mov3", low=source, high=operand.r("zero_high_reg"), dest=dest},
                {type="label", target=end_label}
            }
    else
        return {{type="mov", source=source, dest=dest}}
    end
end


function tac_arithmetic_lowerer.mov(instruction, source, dest)
    if(source.bitsize == 16) then
        return {instruction}
    else
        if(source.type == "i") then
            if(source.value < 65536) then
                return {{type="mov3", low=source, high=operand.r("zero_high_reg"), dest=dest}}
            else
                local temp = operand.t()
                return {
                    {type="mov", source=operand.i(source.value >> 16), dest=temp},
                    {type="exh", low=operand.r("r0"), high=temp, dest=temp},
                    {type="mov3", low=operand.i(source.value % 65536), high=temp, dest=dest}
                }
            end
        else
            -- otherwise, ensure that the full value is moved rather than just the lower 16 bits
            return {{type="mov3", low=source, high=source, dest=dest}}
        end
    end
end

-- function tac_arithmetic_lowerer.and(instruction, source, dest)
--     if(source.bitsize == 16 or dest.bitsize == 16) then

--     end
-- end

function tac_arithmetic_lowerer.add(instruction, source, dest)
    local add_instruction = nil
    if(source.bitsize == 16 and dest.bitsize == 16) then
        add_instruction = {instruction}
    elseif(source.bitsize == 16 and dest.bitsize == 32) then
        local dest_high = operand.t()
        add_instruction = {
            {type="exh", low=dest, dest=dest_high, high=operand.r("r0")},
            {type="add", source=source, dest=dest},
            {type="adc", source=operand.r("r0"), dest=dest_high},
            {type="exh", low=operand.r("r0"), dest=dest_high, high=dest_high},
            {type="mov3", low=dest, high=dest_high, dest=dest}
        }
        

    else
        local source_high = operand.t()
        local dest_high = operand.t()
        
        if(source.type == "i") then
            add_instruction = {
                {type="exh", low=dest, dest=dest_high, high=operand.r("r0")},
                {type="add", source=source, dest=dest},
                {type="adc", source=operand.i(source.value >> 16), dest=dest_high},
                {type="exh", low=operand.r("r0"), dest=dest_high, high=dest_high},
                {type="mov3", low=dest, high=dest_high, dest=dest}
            }

        else
            add_instruction = {
                {type="exh", low=source, dest=source_high, high=operand.r("r0")},
                {type="exh", low=dest, dest=dest_high, high=operand.r("r0")},
                {type="add", source=source, dest=dest},
                {type="adc", source=source_high, dest=dest_high},
                {type="exh", low=operand.r("r0"), dest=dest_high, high=dest_high},
                {type="mov3", low=dest, dest=dest, high=dest_high}
            }

        end
    end

    return add_instruction
end

function tac_arithmetic_lowerer:build_dispatches()
    local dispatch_table = {}
    for key, value in pairs(self) do
        if(type(value) == "function") then
            
            local func_info = debug.getinfo(value)
            local params = {}
            -- The first parameter is always instruction
            for i = 2, func_info.nparams do
                local param = debug.getlocal(value, i)
                params[i - 1] = param
            end
            local inverted_params = util.invert_table(params)
            local instruction_name = key

            dispatch_table[instruction_name] = function(instruction_table) 
                local instruction_params = {}
                for k, v in pairs(instruction_table) do
                    if(inverted_params[k]) then
                        instruction_params[inverted_params[k]] = v
                    end
                end
                return value(instruction_table, table.unpack(instruction_params))
            end

        end
    end
    self.dispatch_table = dispatch_table
end

tac_arithmetic_lowerer:build_dispatches()

function tac_arithmetic_lowerer:lower(tac)
    
    
    for _, method_id in ipairs(tac) do
        local method_tac = tac[method_id]
        local lowered_method_tac = {}
        for _, instruction in ipairs(method_tac) do
            if(self.dispatch_table[instruction.type]) then
                local lowered_instruction = self.dispatch_table[instruction.type](instruction)
                for _, instruction in ipairs(lowered_instruction) do
                    table.insert(lowered_method_tac, instruction)
                end
            else
                table.insert(lowered_method_tac, instruction)
            end
        end

        tac[method_id] = lowered_method_tac
    end
    
end

return tac_arithmetic_lowerer