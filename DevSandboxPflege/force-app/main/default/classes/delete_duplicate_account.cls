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
// löschen doppelten accounts und dazugehörige contacts (batch)
//
//
//****************************************************************************************************************************
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

global class delete_duplicate_account implements Database.Batchable<sObject> { 

    global list<string> famIdList; 
    
    global delete_duplicate_account(list<string> famIdList) {
        this.famIdList = famIdList;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) { 
        System.debug('##########################alex001' + famIdList.size());        
        String query; 
        query = 'SELECT id, name, LastModifiedDate, CreatedDate, Familien_CRM_ID__c FROM account WHERE Familien_CRM_ID__c IN : famIdList ORDER BY name'; 
        return Database.getQueryLocator(query); 
    }   
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){ 
        set<id> accToDelSet = new set<id>();
        list<deleted_accounts__c> daList = new list<deleted_accounts__c>();
        System.debug('##########################alex010' + scope.size());   
        account a = new account();
        account b = new account();
        for(sObject s : scope) { 
            if(a.id == null) {
                a = (account)s;
            } else {
                b = (account)s;
                if(a.Familien_CRM_ID__c == b.Familien_CRM_ID__c) {
                    if(a.LastModifiedDate > b.LastModifiedDate) {
                        accToDelSet.add(b.id);
                    }
                    else {
                        accToDelSet.add(a.id);
                    }
                    a = new account();
                    b = new account();
                    deleted_accounts__c da = new deleted_accounts__c();
                    da.Familien_CRM_ID__c = a.Familien_CRM_ID__c;
                    daList.add(da);
                }
            }

            if(accToDelSet.size() > 999) break;
        }
        System.debug('##########################alex011' + accToDelSet.size()); 
        if(!accToDelSet.isEmpty()) {
            list<account> accToDelList = [SELECT id FROM account WHERE id IN: accToDelSet];
            list<contact> conToDelList = [SELECT id FROM contact WHERE accountid IN: accToDelSet];
            if((accToDelList != null) && (accToDelList.size() > 0)) {
                try {
                    insert daList;
                    delete accToDelList;
                    System.debug('##########################alex012 accounts:' + accToDelList.size() + ' gelöscht'); 
                }
                catch(System.Exception e) {
                    System.debug('##########################alex013 error löschen accounts e:' + e); 
                }
            }
            if((conToDelList != null) && (conToDelList.size() > 0)) {
                try {
                    delete conToDelList;
                    System.debug('##########################alex014 contacts:' + conToDelList.size() + ' gelöscht'); 
                }
                catch(System.Exception e) {
                    System.debug('##########################alex015 error löschen contacts e:' + e); 
                }
            }           
        } 
            
    } 

    global void finish(Database.BatchableContext BC){ 
        AsyncApexJob a = 
        [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems,CreatedBy.Email FROM AsyncApexJob WHERE Id = :BC.getJobId()]; 
        System.debug('##########################alex020 a.Id: ' + a.Id); 
    } 
}