import math
precision = 35
MAGIC_NUMBER = math.ceil(2**precision / 10)

flags = {"carry":0}

class uint16:

    def __init__(self,value):
        self.value = value & 0xFFFF

    def __str__(self):
        return hex(self.value)

    def __add__(self, other):
        flags["carry"] = 1 if self.value + other.value > 2**16 - 1 else 0
        return uint16(self.value + other.value)

    def __sub__(self, other):
        return self.__add__(uint16(((other.value ^ 0xFFFF) + 1) & 0xFFFF))

    def __mul__(self, other):
        return uint16(self.value * other.value >> 16), uint16(self.value * other.value)

    def __rshift__(self, other):
        return uint16(self.value >> other.value)

    def __lshift__(self, other):
        return uint16(self.value << other.value)

def divide_by_10(n):
    mn_16 = uint16(MAGIC_NUMBER)
    mn_32 = uint16(MAGIC_NUMBER >> 16)
    # mn_48 = uint16(MAGIC_NUMBER >> 32) # MAGIC_NUMBER is < 2**32

    n_16 = uint16(n)
    n_32 = uint16(n >> 16)
    # print(n_16, n_32)

    product_uints = [uint16(0) for _ in range(64 // 16)]
    product_uints[1], product_uints[0] = n_16 * mn_16
    temp_48, temp_32 = n_32 * mn_16
    temp_48_2, temp_32_2 = n_16 * mn_32
    product_uints[3], product_uints[2] = n_32 * mn_32

    # make sure to add carry!
    product_uints[1] += temp_32
    product_uints[2] += uint16(flags["carry"])
    product_uints[3] += uint16(flags["carry"])
    
    product_uints[1] += temp_32_2
    product_uints[2] += uint16(flags["carry"])
    product_uints[3] += uint16(flags["carry"])
    
    product_uints[2] += temp_48
    product_uints[3] += uint16(flags["carry"])
    product_uints[2] += temp_48_2
    product_uints[3] += uint16(flags["carry"])
    
    quotient_16 = product_uints[2]
    quotient_32 = product_uints[3]
    # print(product_uints[2], product_uints[3])
    quotient_16 = (product_uints[2] >> uint16(3))  + (product_uints[3] << uint16(13)) # This and the following line!
    quotient_32 = (product_uints[3] >> uint16(3))
    # print(quotient_16, quotient_32)

    reverse_dividend_32, reverse_dividend_16 = quotient_16 * uint16(10)
    reverse_dividend_48, temp = quotient_32 * uint16(10)
    reverse_dividend_32 += temp
    # reverse_dividend_32_2, rd_32_2 = quotient_32 * uint16(10)
    # reverse_dividend_32 += rd_32_2
    # print(reverse_dividend_32, reverse_dividend_16, n_16)
    # subtract from original dividend (n) carry??? + shouldn't need r_32 since remainder < 10
    

    remainder_16 = n_16 - reverse_dividend_16

    # remainder_32 = n_32 - reverse_dividend_32

    return quotient_32, quotient_16

    
from random import randint
print(divide_by_10(2222981120).value)
for i in range(1000000):
    n = randint(0, 2**32 - 1)
    if (n // 10) % 65536  != divide_by_10(n).value:
        print(n, (n // 10) % 65536, divide_by_10(n).value)
        print(divide_by_10(n).value)
        break