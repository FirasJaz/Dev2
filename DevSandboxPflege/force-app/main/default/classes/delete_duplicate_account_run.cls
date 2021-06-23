/****************************************************************************************************************************
// Erstellt 24.10.2016 von AM
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
// keine 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// löschen doppelten accounts und dazugehörige contacts - aufruf
//
//
//****************************************************************************************************************************
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global class delete_duplicate_account_run implements Schedulable { 
 
    @ReadOnly 
    global void execute (SchedulableContext ctx) { 
        List<AggregateResult> query = [SELECT Familien_CRM_ID__c, count(id) ct
                                        FROM account 
                                        WHERE Familien_CRM_ID__c != null 
                                        GROUP BY Familien_CRM_ID__c 
                                        HAVING count(id) > 1 
                                        ORDER BY Familien_CRM_ID__c]; 
         
        list<string> famIdList = new list<string>(); 
         
        for(AggregateResult ar : query) { 
            string faId = (string)ar.get('Familien_CRM_ID__c'); 
            famIdList.add(faId);
        } 
         
        delete_duplicate_account rq = new delete_duplicate_account(famIdList); 
        Database.executeBatch(rq); 
    } 
}