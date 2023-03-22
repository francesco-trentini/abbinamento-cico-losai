/*
    input:  losai   .dta
            cico    .dta
    temp:   losai_selezione_t$i.dta
            cico_selezione_t$i.dta
            statistichePrecisione`livelloprecisione'_t$i.dta
    output: precisione.xlsx
            abbinati.dta
            losai_nonabbinato.dta
            datasetFinito.dta
*/

/* seleziono id univoci (per id_individuo id_azienda rapporto_datainizio).Attenzione rimangono quelli con 2 rapporti nello stesso giorno con due datori di lavoro diversi */
use "${td}/losai.dta",clear
bys id_vari (_dataInizio): gen record_losai = _n
drop touse _merge _flag_contratto
drop if _flag_somministrati ==1 | _flag_cfl==1
count // 4,403,397
destring id_vari,replace

// duplicati episodi di lavoro stesso giorno
gen annoinizio = year(_dataInizio)
gen meseinizio = month(_dataInizio)
gen giornoinizio = day(_dataInizio)
tostring annoinizio meseinizio giornoinizio,replace
replace meseinizio = "0"+meseinizio if strlen(meseinizio)==1
replace giornoinizio = "0"+giornoinizio if strlen(giornoinizio)==1
gen rapporto_datainizio= annoinizio+"-"+meseinizio+"-"+giornoinizio
drop giornoinizio meseinizio
rename annoinizio annostr

bys id_individuo rapporto_datainizio: gen dupl_losai = cond(_N==1,0,_n)
drop if dupl_losai >1
drop dupl_losai
count // 4,383,523

gen anno = year(_dataInizio)
keep if inlist(anno,2012,2013,2014,2015,2016,2017,2018)
gen fulltime= (_orarioIngresso=="F")
destring id_individuo,replace
sort id_individuo
encode regione_residenza, gen(regione_abitazione)
gen eta_avviamento= anno-annonascita 
gen eta2015 = 2015-annonascita
//drop if eta2015>35 | eta2015 <15 
compress
count // 2,568,272
drop eta2015
bys id_individuo (rapporto_datainizio): gen id_rl_losai = _n
bys id_individuo (rapporto_datainizio): egen id_rl_losai_max = max(id_rl_losai)

// creo settimana e mese di inizio rapporto per il merge 
gen giorno = substr(rapporto_datainizio,9,2)
destring giorno,replace
gen mese = substr(rapporto_datainizio,6,2)
destring mese,replace
gen anno_r = substr(rapporto_datainizio,1,4)
destring anno_r,replace

gen rapporto_datainizio_s = wofd(mdy(mese,giorno,anno_r))
format rapporto_datainizio_s %tw

gen rapporto_datainizio_m = mofd(mdy(mese,giorno,anno_r))
format rapporto_datainizio_m %tm

save "${td}/losai_selezione_t0.dta",replace

/* seleziono cf univoci (per cflavoratore_crip cfdatore_crip rapporto_datainizio). Attenzione rimangono quelli con 2 rapporti nello stesso giorno con due datori di lavoro diversi*/
use "${td}/cico.dta",clear
bys cflavoratore_crip rapporto_datainizio: gen dupl_cico = cond(_N==1,0,_n)
drop if dupl_cico >1

gen anno = real(substr(rapporto_datainizio,1,4))
keep if inlist(anno, 2012,2013,2014,2015,2016,2017,2018)
gen fulltime = (codtipoorario==1)

recode codregionedomicilio (3=18), gen(regione_abitazione)
replace regione_abitazione = regione_abitazione - 1 if regione_abitazione >2

sort cflavoratore_crip
drop if missing(retrmese_inps) 

gen eta_avviamento = anno-annonascita 
gen eta2015 = 2015-annonascita
su eta2015,d
// drop if eta2015>35 | eta2015 <15
compress
count
// 2,507,701
drop eta2015
bys cflavoratore_crip (rapporto_datainizio): gen id_rl_cico = _n
bys cflavoratore_crip (rapporto_datainizio): egen id_rl_cico_max = max(id_rl_cico)

// genero settimana e mese di abbinamento
gen giorno = substr(rapporto_datainizio,9,2)
destring giorno,replace
gen mese = substr(rapporto_datainizio,6,2)
destring mese,replace
gen anno_r = substr(rapporto_datainizio,1,4)
destring anno_r,replace

gen rapporto_datainizio_s = wofd(mdy(mese,giorno,anno_r))
format rapporto_datainizio_s %tw

gen rapporto_datainizio_m = mofd(mdy(mese,giorno,anno_r))
format rapporto_datainizio_m %tm

gen rapporto_datainizio_cico = mdy(mese,giorno,anno_r)
format rapporto_datainizio_cico %td

save "${td}/cico_selezione_t0.dta",replace

** Abbinamento

global chiavi `" " rapporto_datainizio regione_abitazione codgenere annonascita contratto fulltime" " rapporto_datainizio codgenere annonascita contratto fulltime" " rapporto_datainizio_s codgenere annonascita contratto fulltime" " rapporto_datainizio_m codgenere annonascita contratto fulltime" "'

global i = 0

foreach livelloprecisione in 1 .75 .5 {  
    global nprecisi=6
    global losaiabbinabili = 1
    foreach chiave in $chiavi {    
        /* Procedura iterativa su precisione nell'abbinamento */
        putexcel set "${od}/precisione.xlsx",modify
        putexcel A1 = "Step"
        putexcel B1 = "Soglia di precisione"
        putexcel C1 = "Chiave"

        putexcel D1 = "Individui LoSai"
        putexcel E1 = "Rapporti di lavoro LoSai"
        putexcel F1 = "Individui CICO"
        putexcel G1 = "Rapporti di lavoro CICO"

        putexcel H1 = "Individui CICO abbinabili"
        putexcel I1 = "Individui LoSai abbinati"
        putexcel J1 = "Rapporti di lavoro individui LoSai abbinati"
        putexcel K1 = "Precisione media"
        putexcel L1 = "Precisione minima"
        putexcel M1 = "Precisione massima"

        while $nprecisi > 5 & $losaiabbinabili>0 {
            local riga = $i +2
            putexcel A`riga' = $i
            putexcel B`riga' = `livelloprecisione'
            putexcel C`riga' = "`chiave'"
            local j = $i +1
            use "${td}/losai_selezione_t$i.dta",clear
            count 
            putexcel E`riga'=`r(N)'
            local chiave = "`chiave'"
            merge m:m `chiave' using "${td}/cico_selezione_t$i.dta", keepusing(cflavoratore_crip id_rl_cico_max cfdatore_crip record_cico rapporto_datainizio_cico)
            keep if _merge !=2 // qui togliamo gli episodi che non abbiniamo 
            // sort
            sort cflavoratore_crip `chiave'
            // calcolo il massimo locale di rl di CICO perché alcuni rl di CICO iniziale non sono abbinati.
            bys cflavoratore_crip record_cico: gen touse = cond(_n==1,1,.)
            by cflavoratore_crip: egen id_rl_cico_max_locale = total(touse) if record_cico!=.
            drop touse annostr

            sort id_individuo rapporto_datainizio

            // Se si generano duplicazioni di episodi LoSai dopo il merge m:m (in particolare per il caso di abbinamenti su settimana e mese) calcoliamo la distanza tra l'inizio dell'episodio di LoSai e l'inizio degli espisodi di CICO, tnenedo quello con la distanza minore.
            bys id_individuo cflavoratore_crip record_losai: gen rapporto_datainizio_diff = abs(_dataInizio - rapporto_datainizio_cico)
            bys id_individuo cflavoratore_crip record_losai (rapporto_datainizio_diff): gen tokeep = _n
            keep if tokeep ==1
            
            /* Qualità dell'abbinamento: precisione */
            gen abbinamento=1
            collapse (count) abbinamento (max) id_rl_losai_max (max) id_rl_cico_max_locale (median) eta_avviamento, by(id_individuo cflavoratore_crip)

            /* numero id losai */
            bys id_individuo: gen nid_losai = cond(_N==1,0,_n)
            count if nid_losai < 2
            putexcel D`riga'=`r(N)'

            /* numero individui cico*/
            bys cflavoratore_crip: gen nid_cico = cond(_N==1,0,_n)
            count if nid_cico < 2
            putexcel H`riga'=`r(N)'

            // Precisione
            sort id_individuo

            gen precisione= abbinamento/id_rl_losai_max
            replace precisione=0 if cflavoratore_crip==.
            
            gen precisione_cico= abbinamento/id_rl_cico_max_locale

            by id_individuo: egen precisione_min = min(precisione)
            by id_individuo: egen precisione_max = max(precisione)
            by id_individuo: egen precisione_media = mean(precisione)

            bys id_individuo (precisione precisione_cico): gen n_id_individuo =_n
            bys id_individuo: gen tokeep = 1 if n_id_individuo==_N
            // teniamo un solo record per individuo losai, quello con precisione e precisione_cico più alto // a partità di entrambe le precisioni selezioniamo casualmente.
            count if tokeep==1 & precisione >= `livelloprecisione'
            global losaiabbinabili = `r(N)'
            if `r(N)' > 0 {
                // selezioniamo gli abbinamenti che soddisfano il nostro criterio sul 1) non duplicati e 2) livello di precisione
                keep if tokeep==1 & precisione >= `livelloprecisione'
                
                * a parità di precisione, se abbino più di un id_cico, tengo quello che ha la precisione cico più alta.
                sort cflavoratore_crip
                bys cflavoratore_crip: gen dupl_cf = cond(_N==1,0,_n)

                bys cflavoratore_crip: egen precisione_cico_max = max(precisione_cico)
                bys cflavoratore_crip: egen n_id_individuo_min = min(n_id_individuo)
                // eliminiamo i record duplicati con precisione cico < massima osservata per quell'individuo
                drop if dupl_cf>0 & precisione_cico<precisione_cico_max
                // se ci sono ancora rapporti duplicati, ossia con precisione cico uguale, scegliamo uno dei record in modo casuale
                bys cflavoratore_crip: gen id_rl_cico_N = 1 if _n==_N
                drop if dupl_cf>0 & id_rl_cico_N!=1
                drop dupl_cf
                /* bys cflavoratore_crip: gen dupl_cf = cond(_N==1,0,_n)
                drop dupl_cf */

                /* secondo dato: n id abbinati con precisione >= soglia da abbinamento con cf cico*/
                count
                putexcel I`riga'=`r(N)'
                gen livelloprecisione = `livelloprecisione'
                gen chiave = "`chiave'"
                su precisione
                putexcel K`riga'=`r(mean)'
                putexcel L`riga'=`r(min)'
                putexcel M`riga'=`r(max)'

                save "${td}/statistichePrecisione`livelloprecisione'_t$i.dta",replace
                global nprecisi = `r(N)'

                /* Seleziono due banche dati: quella con i match e quella senza */
                use "${td}/losai_selezione_t$i.dta",clear
                merge m:1 id_individuo using "${td}/statistichePrecisione`livelloprecisione'_t$i.dta", keepusing(cflavoratore_crip) 
                /* Salvo gli episodi di id_individuo losai non abbinati */
                preserve
                keep if _merge==1
                drop _merge cflavoratore_crip
                save "${td}/losai_selezione_t`j'.dta", replace
                restore 
                /* Tengo solo gli abbinati e conto i record*/
                keep if _merge ==3
                count 
                putexcel J`riga'=`r(N)'

                /* Tolgo gli cflavoratore_crip in cico con precisione 1*/
                use "${td}/cico_selezione_t$i.dta",clear
                count 
                putexcel G`riga'=`r(N)' // numero di rapporti in CICO
                bys cflavoratore_crip: gen n=cond(_n==1,1,.)
                count if n==1
                putexcel F`riga'=`r(N)' // numero di individui in CICO
                drop n
                merge m:1 cflavoratore_crip using "${td}/statistichePrecisione`livelloprecisione'_t$i.dta", keepusing(id_individuo) 
                keep if _merge==1
                drop _merge id_individuo
                save "${td}/cico_selezione_t`j'.dta", replace
                // elimino i db da svuotare degli step precedenti per risparmiare spazio su disco
                local dropdb = $i - 2
                if $i > 2 {
                    erase "${td}/cico_selezione_t`dropdb'.dta"
                    erase "${td}/losai_selezione_t`dropdb'.dta"
                }
                global i = $i + 1
            }
        }
        global nprecisi=6
        global losaiabbinabili = 1
    }
}

/* Save remaining records to new file*/
copy "${td}/losai_selezione_t$i.dta" "${od}/losai_nonabbinato.dta", replace
erase "${td}/losai_selezione_t$i.dta"

// lista di coppie losai-cico abbinate 
cd "${td}"
local filesAbbinati: dir . files "statistichePrecisione*"
clear
append using `filesAbbinati', gen(t)
save "${od}/abbinati.dta",replace

/**/
use "${td}/losai.dta",clear
cap drop _merge
merge m:1 id_individuo using "${od}/abbinati.dta" //, keepusing(cflavoratore_crip chiave)
rename _merge flag_abbinato
recode flag_abbinato (1=0) (3=1)
label define flagit 0 "non abbinato" 1 "abbinato"
label values flag_abbinato flagit
destring id_azienda,replace
compress
save "${od}/losai_flag.dta",replace

use "${od}/losai_flag.dta",replace
// Merge con file di impresa sull'anno di inizio
gen anno = year(_dataInizio)
merge m:1 anno id_azienda using "${id}/imprese2005_2018.dta", keepusing(class_dim ateco07_2_calc)
keep if _m==3
drop _merge
recode class_dim (1/3 = 1 "[0-15]") (4/8 = 2 "[16-50]") (9/10 = 3 "[51-200]") (11/14 = 3 "[51-500+]"), gen(dim)
label define classd 1 "[0-5]" 2 "[6-10]" 3 "[11-15]" 4 "[16-20]" 5 "[21-25]" 6 "[26-30]" 7 "[31-40]" 8 "[41-50]" 9 "[51-100]" 10 "[101-200]" 11 "[201-300]" 12 "[301-400]" 13 "[401-500]" 14 "More than 500"
label values class_dim classd
egen ateco2= cut(ateco07_2_calc), at(1,5,10,35,36,41,45,49,55,58,64,68,69,77,84,85,86,90,94,97,99) icodes
label define atec 0 "A - Agricoltura, silvicoltura e pesca" 1 "B - Estrazione di minerali da cave e miniere" 2 "C - Attività manifatturiere" 3 "D - Fornitura di energia elettrica, gas, vapore e aria condizionata" 4 "E - Fornitura di acqua" 5 "F - Costruzioni" 6 "G - Commercio all'ingrosso e al dettaglio; riparazione di autoveicoli e motocicli" 7 "H - Trasporto e magazzinaggio" 8 "I - Attività dei servizi di alloggio e ristorazione" 9 "J - Servizi di informazione e comunicazione" 10 "K - Attività finanziarie e assicurative" 11 "L - Attività immobiliari" 12 "M - Attivià professionali, scientifiche e tecniche" 13 "N - Noleggio, agenzie di viaggio, servizio di supporto alle imprese" 14 "O - Amministrazione pubblica" 15 "P - Istruzione" 16 "Q - Sanità e assistenza sociale" 17 "R - Attività artistiche" 18 "S - Altre attività dei servizi" 19 "T - Personale domestico" 20 "U - Organizzazioni e organismi extraterritoriali"
label values ateco2 atec
count // 1,265,967
save "${od}/datasetFinito.dta",replace
