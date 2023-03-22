/* 
    input:
        ${id}/rapporti_lavoro1985_2018.dta
        ${id}/anagrafica_2018.dta
    
    output:
        ${id}/losai.dta
 */


clear all

/* Merge anagrafica e rapporti di lavoro  - solo dopo 2010*/
use "${id}/rl_finale_consolidato.dta",clear

rename rapporto_datainizio _dataInizio
rename rapporto_datacessazione _dataCessazione
rename qualifica _qualificaIngresso
rename contratto_iniziale _contrattoIngresso
rename tipo_contratto_2 _contrattoUscita
rename tipo_orario _orarioIngresso

// aggiunta anagrafica e variabili come in CICO
merge m:1 id_vari using "${id}/anagrafica_2018.dta"

keep if _m==3 & segnale_cf==1

**** genero variabili come in CICO
// anno di nascita
gen annonascita = anno_nascita

// genere
gen codgenere = 1 if genere=="M"
replace codgenere = 2 if genere == "F"

//tipo orario
gen codtipoorario = 1 if _orarioIngresso == "F"
replace codtipoorario = 2 if _orarioIngresso == "P"
replace codtipoorario = 3 if _orarioIngresso == "V"
replace codtipoorario = 4 if _orarioIngresso == "M"

// regione di residenza
local regioniLoSai `""ABRUZZO" "BASILICATA" "CALABRIA" "CAMPANIA" "EMILIA ROMAGNA" "FRIULI VENEZIA GIULIA" "LAZIO" "LIGURIA" "LOMBARDIA" "MARCHE" "MOLISE" "PIEMONTE" "PUGLIA" "SARDEGNA" "SICILIA" "TOSCANA" "TRENTINO ALTO ADIGE" "UMBRIA" "VALLE D'AOSTA" "VENETO""'
local regioniStandard `" "Abruzzo" "Basilicata" "Calabria" "Campania" "Emilia Romagna" "Friuli Venezia Giulia" "Lazio" "Liguria" "Lombardia" "Marche" "Molise" "Piemonte" "Puglia" "Sardegna" "Sicilia" "Toscana" "Trentino Alto Adige" "Umbria" "Val D'Aosta" "Veneto" "Estero" "'
gen regione_residenza_new = regione_residenza
forvalues i = 1/22 {
    local regioneStandard: word `i' of `regioniStandard'
    local regioneLoSai: word `i' of `regioniLoSai'
    replace regione_residenza_new = "`regioneStandard'" if regione_residenza == "`regioneLoSai'"
}

compress
drop if year(_dataInizio)<2005

save  "${td}/losai.dta", replace
