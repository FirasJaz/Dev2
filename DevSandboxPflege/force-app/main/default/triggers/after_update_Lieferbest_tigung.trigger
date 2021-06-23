//****************************************************************************************************************************
// Erstellt 29.12.2015     von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Setzen das Datum Abgerechnet_am auf Lieferschein wenn pdf_erstellt = true
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
trigger after_update_Lieferbest_tigung on Lieferbest_tigung__c (after update) {
    set<id> lsIDSet = new set<id>();
    for(Lieferbest_tigung__c LB : trigger.new) {
        if((LB.pdf_erstellt__c == true) && (trigger.oldMap.get(LB.id).pdf_erstellt__c != true)) lsIDSet.add(LB.Lieferschein__c);
    }
    
    if(!lsIDSet.isEmpty()) {
        list<Lieferschein__c> lsList = [SELECT Abgerechnet_am__c FROM Lieferschein__c WHERE id IN :lsIDSet  ]; 
        if((lsList != null) && (lsList.size() > 0)) {
            for(Lieferschein__c ls : lsList) {
                ls.Abgerechnet_am__c = date.today();
            }
            try {
                update lsList;
            }
            catch(system.exception e) {
                system.debug('######################### error update lsList (Datum) e=' + e);
            }
        }       
        
    }

}