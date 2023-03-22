/* 
    input:  
        MdL - CICO LoSai /01_03_05_06_07.LoSaI_2018/01.ANAGRAFICA/ANAGRAFICA_2018.TXT 
        MdL - CICO LoSai /01_03_05_06_07.LoSaI_2018/02.DIPENDENTI/Rapporti_lavoro1985_2018.txt
        MdL - CICO LoSai /CICO_I_TRIM_2021/Microdati/RETR_0921_TRIMI.csv
    output:
        ${id}/rapporti_lavoro1985_2018.dta
        ${id}/anagrafica2018.dta
        ${id}/RETR_0921_TRIMI.dta
 */

global losaiAnagrafica "yourdir/01_03_05_06_07.LoSaI_2018/01.ANAGRAFICA/ANAGRAFICA_2018.TXT"
global losaiRapportiLavoro "yourdir/02.DIPENDENTI/Rapporti_lavoro1985_2018.TXT"
global losaiImprese2005_2016 "yourdir/03.IMPRESE_1990-2014_2005-2016/MATR_LOSAI_2005_2016.TXT" 
global losaiImprese2015_2018 "yourdir/03.IMPRESE/MATR_LOSAI_2015_2018.TXT" 
global cicoRetr "CICO_I_TRIM_2021/Microdati/RETR_0921_TRIMI.csv" 
clear all

/* Import anagrafica e salvo dta */
infix anno_nascita 1-8 str genere 9-9 anno_morte 10-17 segnale_cf 18-25 str id_vari 26-33 id_individuo 34-41 str regione_residenza 42-71 using ${losaiAnagrafica}
save "${id}/anagrafica_2018.dta",replace

/* Import rapporti_lavoro e salvo dta */
clear all 
infix str id_vari 1-8 anno 9-16 str tipo_orario  18-18 str qualifica  20-30 gg_retribuite 31-38 str sett_retribuite 39-46 str sett_utili 47-54 str tipo_politica 55-62 str data_cessazione  64-67 str retribuzione 68-75 str tipo_contratto  77-77 str data_assunzione  79-82 str motivo_cessazione  84-85 str motivo_assunzione  87-88 str id_azienda 89-97 using ${losaiRapportiLavoro},replace

infix ID_AZIENDA 1-8 ID_AZIENDA_MADRE 9-16 str POSIZIONE 17-17 CLASS_DIM 18-25 ATECO07_2_CALC 26-27 ANNO 28-35 using ${losaiImprese2005_2016},clear
rename *, lower
save "${id}/imprese2005_2016.dta",replace

infix ID_AZIENDA 1-8 ID_AZIENDA_MADRE 9-16 str POSIZIONE 17-17 CLASS_DIM 18-25 ATECO07_2_CALC 26-27 ANNO 28-35 using ${losaiImprese2015_2018},clear
rename *, lower
append using "${id}/imprese2005_2016.dta"

bys id_azienda id_azienda_madre anno: gen dupl_az = _n-1
drop if dupl_az>0
save "${id}/imprese2005_2018.dta",replace
erase "${id}/imprese2005_2016.dta"

// integrazione di aziende 2015-2018 e 2005-2016. Usiamo azeinda madre come azienda e deduplichiamo
use "${id}/imprese2005_2018.dta",clear
preserve 
drop id_azienda 
duplicates drop anno id_azienda_madre,force
rename id_azienda_madre id_azienda
save "${td}/imprese2005_2018_temp.dta"
restore
drop id_azienda_madre
append using "${td}/imprese2005_2018_temp.dta"
duplicates drop id_azienda anno,force
save "${id}/imprese2005_2018.dta",replace
erase "${td}/imprese2005_2018_temp.dta"

/* Import CICO e salvo dta */
import delimited ${cicoRetr}, numericcols(21) clear
save "${id}/RETR_0921_TRIMI.dta",replace
