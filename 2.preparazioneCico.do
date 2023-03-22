/* 
    input:
        ${id}/RETR_0921_TRIMI.dta
    
    output:
        ${id}/cico.dta
 */

use "${id}/RETR_0921_TRIMI.dta",replace
keep if tipodip_inps ==1 // solo dipendenti non agricoli e domestici abbinati 

gen contratto = "I" if inlist(codtipocontratto,1,10,12,16,17,24,26,31,34,52,54,56,58,60,62,69)
replace contratto = "D" if inlist(codtipocontratto,2,3,11,13,18,25,27,28,30,33,35,53,55,57,59,61,70,74)
// replace contratto = "S" non possiamo identificarli
gen flag_apprendistato_cico = "A" if inlist(codtipocontratto,4,5,6,7,45,46,47,48,49,50,51)
replace contratto = "I" if flag_apprendistato_cico=="A"
gen flag_interinale_cico = "Interinale" if inlist(codtipocontratto,14,15)
gen flag_cfl_cico = "CFL" if inlist(codtipocontratto,8,9)

gen flag_contratti_esclusi_cico = (inlist(codtipocontratto,19,20,29,31,32,62,63,72,73,99)) // agricoli 

gen flag_agricoli_cico = (inlist(codtipocontratto,69,70))
gen flag_domestici_cico = (inlist(codtipocontratto,52,53))
gen flag_spettacolo_cico = (inlist(codtipocontratto,26,27))
gen flag_missing_cico = (inlist(codtipocontratto,72,73,99))

gen flag_contratto_cico = flag_apprendistato_cico + flag_interinale_cico + flag_cfl_cico


drop if flag_agricoli_cico==1 | flag_domestici_cico==1 | flag_spettacolo_cico==1 | flag_missing_cico==1 |flag_contratti_esclusi_cico==1 
gen record_cico =_n
save "${td}/cico.dta", replace
