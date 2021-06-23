//****************************************************************************************************************************
// Created on 02.08.2019   by BT
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
//      Creates follow-up tasks on contacts
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************

public class Follow_up_Task_erstellen_class {    
    public static void createFollowUpTask(Set<id> KundenIdSet, string tkName) {
        Id ownId = null;        
        
        Taskerstellung__c cs = Taskerstellung__c.getValues('Curabox');
        
        if(cs != null) {    
            
            if(tkName == 'Ist PG51 gewünscht ?' && cs.Ist_PG51__c != null){
                List<User> uList = [select Id, name from User where name = :cs.Ist_PG51__c limit 1];
                if(uList != null && uList.size() > 0 ) ownId = uList[0].id;
            }
            else if(tkName.contains('Ablehnung') && cs.Ablehnungen__c != null){
                List<User> uList = [select Id, name from User where name = :cs.Ablehnungen__c limit 1];
                if(uList != null && uList.size() > 0 ) ownId = uList[0].id;
            }
            
            if(ownId != null) {          
                for(Id kdId: KundenIdSet) { 
                    Follow_up_Task__c th = new Follow_up_Task__c(Due_Date__c = Date.today() + 14,
                                       Subject__c = tkName,
                                       Contact__c = kdId,
                                       Description__c = tkName,
                                       Owner__c = ownId,                                       
                                       Status__c = 'Offen');
                    
                    try {
                        insert th;
                    }
                    catch(system.exception e) {
                        system.debug('############BT2017 Task konnte nicht angelegt werden !');
                    }            
                }
            }
        }
        else {
            system.debug('###########BT2017 Es konnte kein passendes Custom setting gefunden werden');
        }
    }       
}