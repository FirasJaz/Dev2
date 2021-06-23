//****************************************************************************************************************************
// Careated 26.09.2018 von MZ
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
//
//****************************************************************************************************************************
//
// Description: #160786560 - ZWB - Stornos 
//              When the field "Status CPL" is changed to "storniert" the field "Wert des Partnertickets CPL" should be 0,00 automatically.         
//
//
//****************************************************************************************************************************
// Changes:
//****************************************************************************************************************************
trigger Partner_Ticket_Cancellation_trigger on Partner_Ticket__c (before update) {
    set<id> ptSet = new set<id>();
    if(trigger.isUpdate) {
        for (Partner_Ticket__c a : trigger.New) {
            if(a.Status_CPL__c == 'Storniert' && a.Wert_des_Partner_Tickets_CPL__c != 0.00 ){
                a.Wert_des_Partner_Tickets_CPL__c = 0.00;
            } 
        }
    }
}