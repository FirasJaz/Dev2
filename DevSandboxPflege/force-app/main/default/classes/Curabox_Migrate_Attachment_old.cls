/****************************************************************************************************************************
// Created 07.08.2019 von  AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// 
//
//****************************************************************************************************************************
//
// Description:       
// This class generate delivery Note data from clients to contacts
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global class Curabox_Migrate_Attachment_old implements Database.Batchable<sObject>, Database.Stateful{

    public static List<ContentVersion> files {get; set;}
     public static list<string> errorList = new list<string>();
     
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Date today = Date.today();
        //Datetime dt = datetime.newInstance(today.year(), today.month(),today.day());
        //String timeFormat = dt.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        //string timeFormat = '2019-10-30T15:55:00Z';
        string timeFormat = '2019-11-04T16:57:00Z';
        
        return Database.getQueryLocator(
            'SELECT Id, ParentId, Name, Body, ContentType, OwnerId, Description FROM Attachment WHERE Description != \'convertet\' ' +
            'AND ParentId IN (SELECT Id from Lieferschein__c where lieferschein_logik__c = true and LastModifiedDate >=' + timeFormat + ') ' +
            'limit 150000'
        );
    }

    global void execute(Database.BatchableContext bc, List<Attachment> attList){
        Set<Id> parentIds = new Set<Id>();
        Set<Id> parentIdsDN = new Set<Id>();
        files = new List<ContentVersion>();
        if (attList != null && attList.size() > 0) {            
            for (Attachment att : attList) {                
                if(att.ParentId.getSObjectType().getDescribe().getName() == 'Lieferschein__c') { 
                    parentIdsDN.add(att.ParentId);
                    att.Description = 'convertet';
                    System.debug('###BT2019 att:' + att.Name);
                }
            }            
            if(!parentIdsDN.isEmpty()) {
                Map<id, id> lsDnMap = getLsDn(parentIdsDN);
                for (Attachment attachment : attList) {
                    if (lsDnMap.containsKey(attachment.ParentId)) {
                        files.add(newFile(lsDnMap.get(attachment.ParentId), attachment));
                    }
                }
            }

            // insert Files
            if (files != null && files.size() > 0) {
                try {
                    Database.SaveResult[] srList = Database.insert(files, false);
                    
                    for(Database.saveResult sr: srList) {
                        if (sr.isSuccess()) {
                            system.debug('#### ok ' + sr.getId());
                        }
                        else {
                            for(Database.Error err : sr.getErrors()) {
                                errorList.add('Error! On insert file' + err.getMessage());
                            }
                        }
                    }
                    
                    Database.SaveResult[] srList2 = Database.update(attList, false);
                    
                    for(Database.saveResult sr: srList2) {
                        if (sr.isSuccess()) {
                            system.debug('#### ok ' + sr.getId());
                        }
                        else {
                            for(Database.Error err : sr.getErrors()) {
                                errorList.add('Error! On update attachment ' + err.getMessage());
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Fehler beim Inserieren der Files');
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()];
            // send email to system admin
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        mail.setSaveAsActivity(true);
        mail.setSubject('Attachments wurden übernommen');
        mail.setPlainTextBody('Attachments wurden übernommen.');
        mail.setHtmlBody('Attachments wurden übernommen.');
        String email = 'kontakt@klosesrockepartner.de';
        String[] toAddress = new String[] {email};
        mail.setToAddresses(toAddress);
       
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
        } catch (Exception e) {
            System.debug('Datenübernahme Error: ' + e.getMessage());
        }       
    }

    public static ContentVersion newFile(String contactId, Attachment att){
        ContentVersion file = new ContentVersion();
        file.VersionData = att.Body;
        file.Title = att.Name;
        //file.PathOnClient = att.Name + '.pdf';
        file.PathOnClient = att.Name;
        file.FirstPublishLocationId = contactId;
        file.ContentLocation = 'S';
        return file;
    }   

    public static Map<id, id> getLsDn(Set<Id> lsIds){
        Map<id, id> lsDnMap = new Map<id, id>();
        try {
            Map<string, id> lsNameMap = new Map<String, id>();
            List<Lieferschein__c> lsList = [SELECT id, name FROM Lieferschein__c WHERE id IN : lsIds];
            if((lsList != null) && (lsList.size() > 0)) {
                for(Lieferschein__c ls : lsList) { 
                    lsNameMap.put(ls.name, ls.id);
                }
                List<Delivery_Note__c> dnList = [SELECT id, old_LS_Name__c FROM Delivery_Note__c WHERE old_LS_Name__c IN : lsNameMap.keySet()];
                for(Delivery_Note__c dn : dnList) {
                    lsDnMap.put(lsNameMap.get(dn.old_LS_Name__c), dn.id);
                }                
            }
        } catch (Exception e) {
            System.debug(e);
        }
        return lsDnMap;
    }    

}