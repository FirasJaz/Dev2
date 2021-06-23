/*/****************************************************************************************************************************
// Erstellt 05.01.2018 von MZ
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
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// reset the field product.Kontingent_Auslastung_pro_Woche__c to "0" every week if the value is not 0 already.
//
//****************************************************************************************************************************
//
//Änderungen: 
// 28.03.2019	MZ	#164498728 - alle Produkte zu Beginn des Monats zurückgesetzt werden                                            
//****************************************************************************************************************************
*/

global class PP_Kontingent_Auslastung_Pro_Woche_batch implements Database.Batchable<sObject>{
    global final String Query = 'select id, Name, Kontingent_Auslastung__c from Partner_Produkte__c where Kontingent_Auslastung__c != 0 and Kontingent_Auslastung__c != null ';
        //(Kontingent_offen_Produkt__c <= 5 and Kontingent_pro_Woche__c != null) or (partner__r.Kontingent_offen_Partner__c <= 5 and partner__r.Kontingent_pro_Woche__c != null)';
    
    global Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
    
        for(Sobject s : scope){
            s.put('Kontingent_Auslastung__c', 0);
        }
        
        try{
            update scope;
        }
        catch(System.exception e) {
            System.debug('######################### Mansi ::: Update fehlgeschlagen!' + e.getMessage());
        }
    }
    
    global void finish(Database.BatchableContext BC){}
}