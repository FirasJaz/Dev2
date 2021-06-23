//****************************************************************************************************************************
// Erstellt 12.04.2017     von BT
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
// Erstellt Tasks für Kunden
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************

public class Task_erstellen_class {
    public static id rtid;
    
    public static void createTask(Set<id> KundenIdSet, string tkName) {
        Id ownId = null;
        
        setRecordTypeId();
        
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
                    Task th = new Task(ActivityDate = Date.today() + 14,
                                       Subject = tkName,
                                       WhatId = kdId,
                                       Description = tkName,
                                       OwnerId = ownId,
                                       RecordTypeId = rtid,
                                       Status = 'Offen');
                    
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
    
    public static void setRecordTypeId() {
        rtid = null;
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'PG54'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }      
    }
}