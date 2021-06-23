/****************************************************************************************************************************
// Erstellt 14.09.2016 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// LsID
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Erstellen einen Partner_PLZ_Gebiet__c Satz von 00000 bis 99999 wenn Deutschlandweit_verf_gbar__c = true
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
trigger after_insert_Partner_Produkte on Partner_Produkte__c (after insert) {
    set<id> ppSet = new set<id>();
    for(Partner_Produkte__c pp : trigger.new) {
        if(pp.Deutschlandweit_verf_gbar__c == true) ppSet.add(pp.id);
    }
    if(!ppSet.isEmpty()) {
        list<Partner_PLZ_Gebiet__c> insList = new list<Partner_PLZ_Gebiet__c>(); 
        for(id ppid : ppSet) {
            Partner_PLZ_Gebiet__c nppg = new Partner_PLZ_Gebiet__c(Partner_Produkte__c=ppid, von__c=0, bis__c=99999, G_ltig_von__c=date.today(), Include_exclude__c='inbegriffen' );
            insList.add(nppg);
        }
        if(!insList.isEmpty()) {
            insert insList;
        }
    }
}