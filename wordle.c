
/*
    This compiler does not have a real preprocessor so directives like #include are not supported.
    I have implemented several "standard library" functions that should help with programming.
    These functions are automatically linked to the program when compiled.

    These include:
        void __scan_unsigned_int(int *)
        void __print_signed_int(int)
        void __print_char_array(char *)
        void putchar(char c)
        char getchar()
        void set_colour(int)
        void set_cursor(int, int)

*/

char data_string[] = "aaronaboutaboveabuseacidsacresactoracuteadamsaddedadminadmitadobeadoptadultafteragainagentagingagreeaheadaimedalarmalbumalertaliasalicealienalignalikealiveallahallanallenallowalloyalonealongalphaalteramberamendaminoamongangelangerangleangryanimeannexannieapartapnicappleapplyaprilarborareasarenaarguearisearmedarmorarrayarrowarubaasciiasianasideaskedassetatlasaudioauditautosavoidawardawareawfulbabesbaconbadgebadlybakerballsbandsbanksbarrybasedbasesbasicbasinbasisbatchbathsbeachbeadsbeansbearsbeastbeatsbeganbeginbegunbeingbellebellybelowbeltsbenchberrybettybiblebikesbillsbillybingobirdsbirthbisonblackbladeblairblakeblameblankblastblendblessblindblinkblockblogsblondbloodbloombluesboardboatsbobbybondsbonesbonusbonzabooksboostboothbootsbootyboredboundboxedboxesbrainbrakebrandbrassbravebreadbreakbreedbrianbrickbridebriefbringbroadbrokebrookbrownbrucebrushbryanbucksbuddybuildbuiltbunchbunnyburkeburnsburstbusesbustybuttsbuyerbytescabincablecachecakescallscamelcampscanalcandycanoncardscareycargocarlocarolcarrycasescaseycasiocatchcausecedarcellscentschainchairchaoscharmchartchasecheapcheatcheckchesschestchevychickchiefchildchilechinachipschoirchosechrischuckcindyciscocitedciviccivilclaimclaraclarkclasscleanclearclerkclickcliffclimbclipsclockclonecloseclothcloudclubscoachcoastcoatscodescohencoinscolincoloncolorcombocomescomiccondocongoconstcoralcorpscostacostscouldcountcourtcovercrackcraftcraigcrapscrashcrazycreamcreekcrestcrimecropscrosscrowdcrowncrudecubiccurvecybercycleczechdaddydailydairydaisydancedannydateddatesdaviddavisdealsdealtdeathdebugdebutdecordelaydelhideltadensedepotdepthderbyderekdeveldevildevondianadianediarydiceddidntdiegodiffsdigitdinerdirtydiscodiscsdisksdodgedoingdollsdonnadonordoorsdoubtdoverdozendraftdraindramadrawndrawsdreamdressdrieddrilldrinkdrivedropsdrovedrugsdrumsdrunkdryerdubaidutchdyingdylaneagleearlyearthebonyebookeddieedgaredgesegypteightelderelecteliteellenelliselvisemacsemailemilyemptyendedendifenemyenjoyenterentryepsonequalerroressayessexeurosevanseventeveryexactexamsexcelexistextrafacedfacesfactsfailsfairyfaithfallsfalsefancyfaresfarmsfatalfattyfaultfavorfearsfeedsfeelsfenceferryfeverfewerfiberfibrefieldfifthfiftyfightfiledfilesfilmefilmsfinalfindsfiredfiresfirmsfirstfixedfixesflagsflameflashfleetfleshfloatfloodfloorflourflowsfloydfluidflushflyerfocalfocusfolksfontsfoodsforceforgeformsforthfortyforumfotosfoundframefrankfraudfreshfrontfrostfruitfullyfundsfunkyfunnyfuzzygainsgamesgammagatesgaugegenesgenreghanaghostgiantgiftsgirlsgivengivesglassglennglobeglorygnomegoalsgoinggonnagoodsgottagracegradegraingramsgrandgrantgraphgrassgravegreatgreekgreengrillgrossgroupgrovegrowngrowsguardguessguestguideguildhairyhaitihandshandyhappyharryhavenhayesheadsheardheartheathheavyhelenhellohelpshencehenryherbshighshillshinduhintshiredhobbyholdsholeshollyhomeshondahoneyhonorhopedhopeshordehorsehostshotelhourshousehowtohumanhumoriconsidahoidealideasimageinboxindexindiaindieinnerinputintelinterintroiraqiirishisaacislamissueitalyitemsivoryjacobjamesjamiejanetjapanjasonjeansjennyjerryjessejesusjeweljimmyjohnsjoinsjointjokesjonesjoycejudgejuicejuliajuliekarenkarmakathykatiekeepskeithkellykennykenyakerrykevinkillskindakindskingskittykleinknifeknockknownknowskodakkorealabellaborladenlakeslampslancelandslaneslankalargelarrylaserlaterlatexlatinlaughlauralayerleadslearnleaseleastleaveleedslegallemonleonelevellewislexuslightlikedlikeslimitlindalinedlineslinkslinuxlionslistslivedliverliveslloydloadsloanslobbylocallockslodgeloganlogicloginlogoslooksloopslooselopezlotuslouislovedloverloveslowerlucaslucialuckylunchlycoslyinglyricmacromagicmailsmainemajormakermakesmalesmaltamambomangamanormaplemarchmarcomardimariamariemariomarksmarshmasonmatchmaybemayormazdamealsmeansmeantmedalmediameetsmenusmercymergemeritmerrymetalmetermetromeyermiamimicromightmilanmilesmilkymillsmindsminesminorminusmixedmixermodelmodemmodesmoneymontemonthmooremoralmosesmotelmotormountmousemouthmovedmovesmoviempegsmsgidmultimusicmyersmysqlnailsnakednamednamesnancynastynavalneedsnepalnervenevernewernewlynigernightnikonnoblenodesnoisenokianorthnotednotesnotrenovelnursenylonoasisoccuroceanofferoftenolderoliveomahaomegaonionopensoperaorbitorderorganoscarotheroughtouterownedowneroxideozonepackspagespaintpairspanelpanicpantspaperpapuaparisparkspartspartypastapastepatchpathspatiopaxilpeacepearlpeerspenalpennyperryperthpeterphasephonephotophpbbpianopickspiecepillspilotpipespitchpixelpizzaplaceplainplaneplansplantplateplaysplazaplotspoemspointpokerpolarpollspoolspoppyportspostspoundpowerpresspriceprideprimeprintpriorprizeprobepromoproofproudproveproxypulsepumpspunchpuppypursepushyqatarqueenqueryquestqueuequickquietquiltquitequoteracesracksradarradioraiserallyralphranchrandyrangeranksrapidratedratesratioreachreadsreadyrealmrebelreferrehabrelaxrelayremixrenewreplyresetretrorhoderickyriderridesridgerightringsrisksriverroadsrobinrobotrocksrockyrogerrolesrollsromanroomsrootsrosesrougeroughroundrouteroverroyalrugbyruledrulesruralsafersagemsaintsaladsalemsalessallysalonsambasamoasandysantasanyosarahsatinsaucesaudisavedsaversavessbjctscalescaryscenescoopscopescorescottscoutscrewscubaseatsseedsseeksseemssellssendssenseserumservesetupsevenshadeshaftshakeshallshameshapesharesharksharpsheepsheersheetshelfshellshiftshineshipsshirtshockshoesshootshopsshoreshortshotsshownshowssidessightsigmasignssillysimonsincesinghsitessixthsizedsizesskillskinsskirtskypeslavesleepslideslopeslotsslowssmallsmartsmellsmilesmithsmokesnakesockssolarsolidsolvesongssonicsorrysortssoulssoundsouthspacespainspanksparcsparespeakspecsspeedspellspendspentspicespicespiesspinesplitspokesportspotsspraysquadstackstaffstagestakestampstandstarsstartstatestatsstaysstealsteamsteelstepsstevestickstillstockstonestoodstopsstorestormstorystrapstripstuckstudystuffstylesuckssudansugarsuitesuitssunnysupersurgesusansweetswiftswingswissswordsyriatabletahoetakentakestalestalkstamiltampatankstapestaskstastetaxesteachteamstearsteddyteensteethtellstermsterryteststexastextsthankthatsthefttheirthemetherethesethetathickthingthinkthirdthornthosethreethrowthumbtigertighttilestimertimestionstiredtirestitletodaytokentokyotommytonertonestoolstoothtopictotaltouchtoughtourstowertownstoxictracetracktracttracytradetrailtraintranstrashtreattreestrendtrialtribetricktriedtriestripstrouttrucktrulytrunktrusttruthtubestulsatumortunertunesturboturnstwicetwikitwinstwisttylertypesultrauncleunderunionunitsunityuntilupperupseturbanusageusersusingusualutilsvalidvaluevalvevaultvegasvenueverdeversevideoviewsvillavinylviralvirusvisitvistavitalvocalvoicevolvovotedvotesvsnetwageswagonwaleswalkswallswannawantswastewatchwaterwattswaveswayneweeksweirdwellswelshwendywhalewhatswheatwheelwherewhichwhilewhitewholewhompwhosewiderwidthwileywindswineswingswiredwireswitchwiveswomanwomenwoodswordsworksworldworryworseworstworthwouldwoundwristwritewrongwrotexanaxxeroxxhtmlyachtyahooyardsyearsyeastyemenyieldyoungyoursyouthyukonzebrazones";
int letter_boundaries[] = {0, 79, 187, 298, 368, 408, 487, 534, 577, 599, 622, 645, 717, 794, 821, 844, 923, 933, 993, 1169, 1273, 1288, 1311, 1366, 1369, 1380, 1382};

char __scan_signed_int(int *num);
int __scan_char_array(char *str);


char __scan_signed_int(int *num) {
    // Register variables can be more efficiently accessed and updated than local variables
    register char c;
    register int res = 0;
    register int sign = 1;
    if((c = getchar()) == '-') {
        sign = -1;
    }else{
        sign = 1;
        res = c - '0';
    }
    putchar(c);
    while((c = getchar()) >= '0' && c <= '9') {
        putchar(c);
        res = res * 10 + (c - '0');
    }

    if(sign == -1) {
        res = -res;
    }

    *num = res;
    return c;
}


int __scan_char_array(char *str) {
    register char c;
    register char *ptr = str;
    while((c = getchar()) != '\n') {
        putchar(c);
        *(ptr++) = c;
    }
    
    *ptr = 0;

    return (int)(ptr - str);
}


void move_cursor(int x, int y) {
    // Idk how to configure the terminal properly so that set_cursor works predictably so this is fine for now
    set_cursor(0);
    for(register int k = 0; k < y; ++k) {
        putchar('\n');
    }
    for(register int l = 0; l < x; ++l) {
        putchar(' ');
    }
}

void clear_screen() {
    set_cursor(0);
    __print_char_array("                                                                                                ");
}

enum Colour { YELLOW = 6, GREY = 8, GREEN = 2, WHITE = 15};

int is_letter_in_word[26];
int main() {
    __print_char_array("Enter a\nnumber to\nhelp\nrandomize\n(1-100): ");
    int mnum;
    __scan_signed_int(&mnum);  // Cannot take address of register operand, so must use a local variable instead

    // Compute a pseudo-random number from the input
    // Gets a value between 0 and 1023
    register int num = mnum;
    num ^= (num << 5);
    num *= 313;
    num ^= (num >> 3);
    num &= 1023;
    clear_screen();

    // Get the word pointed to by the random number and update the is_letter_in_word_array
    register char *word = data_string + num * 5;
    // Avoid overhead by unrolling the loop
    register int word_base = (int)word;
    is_letter_in_word[word[0] - 'a'] = 1;
    is_letter_in_word[word[1] - 'a'] = 1;
    is_letter_in_word[word[2] - 'a'] = 1;
    is_letter_in_word[word[3] - 'a'] = 1;
    is_letter_in_word[word[4] - 'a'] = 1;

    __print_char_array("Enter a word\n");
    
    
    // User enters their guess into query
    char query[10];
    register int word_found = 0;
    for(register int i = 1;i < 6 && !word_found; ++i) {

        putchar(' ');
        putchar(' ');
        putchar(' ');

        // Use the first letter to narrow down the search
        query[0] = getchar();
        register int diff = *query - 'a';
        putchar(*query);
        register int l = letter_boundaries[diff];
        register int h = letter_boundaries[diff + 1] - 1;


        // Can simply compare the next letter to narrow down search even more
        // Cannot do this for the second letter since we can't expect query[1] and word[1] to match
        query[1] = getchar();
        putchar(query[1]);
        register int mid = (l + h) >> 1;
        register char mid_char = data_string[mid * 5 + 1];
        if(query[1] > mid_char) {
            l = mid + 1;
        } else if(query[1] < mid_char) {
            h = mid - 1;
        }

        // Let user enter the remainder of their guess
        __scan_char_array(query + 2);

        // Binary search
        register int result;
        while(l <= h) {
            result = 0;
            mid = (l + h) >> 1;

            // Avoid overhead of strcmp() (I used to have it here) by avoiding function call and unrolling the loop
            register int temp_mid = mid * 5;
            // We already know that query[0] == word[0]
            if(query[1] != data_string[temp_mid + 1]) {
                result = query[1] - data_string[temp_mid + 1];
            }else
            if(query[2] != data_string[temp_mid + 2]) {
                result = query[2] - data_string[temp_mid + 2];
            }else
            if(query[3] != data_string[temp_mid + 3]) {
                result = query[3] - data_string[temp_mid + 3];
            }else
            if(query[4] != data_string[temp_mid + 4]) {
                result = query[4] - data_string[temp_mid + 4];
            }

            
            if(result == 0) { // If the word is found
                break;
            }else if(result < 0) {
                h = mid - 1;
            } else {
                l = mid + 1;
            }
        }

        // If the word is not in the vocabulary
        if((l > h)) {
            move_cursor(3, i);
            __print_char_array("?????");
            move_cursor(0, i + 1);
        } else {
            move_cursor(3, i);
            register int cnt = 0;
            for(register int j = 0; j < 5; ++j) {
                if(word[j] == query[j]) {
                    ++cnt;
                    set_colour(GREEN);
                }else if(is_letter_in_word[query[j] - 'a']) {
                    set_colour(YELLOW);
                }else{
                    set_colour(GREY);
                }
                putchar(query[j]);
            }
            set_colour(WHITE);
            putchar('\n');
            // If every letter in the word is a match, the word has been found
            if(cnt == 5) {
                __print_char_array("Correct!");
                word_found = 1;
                break;
            }
        }
    }

    if(!word_found) {
        __print_char_array("The word was\n");
        word[5] = 0;
        __print_char_array(word);
    }
    
}