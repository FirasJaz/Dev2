trigger after_insert_ContentDocumentLink on ContentDocumentLink (after insert) {
    Map<id, id> genIdMap = new Map<id, id>();
    Map<id, id> conIdMap = new Map<id, id>();
    Map<id, id> docIdMap = new Map<id, id>();
    List<contentDocumentLink> shareList = new List<contentDocumentLink>(); 
    List<contentDocumentLink> shareListG = new List<contentDocumentLink>(); 

    for(ContentDocumentLink cvl : trigger.new) {
        System.debug('###### object=' + cvl.LinkedEntityId.getSObjectType().getDescribe().getName());
        if (cvl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Curabox_Genehmigung__c') {
                genIdMap.put(cvl.LinkedEntityId, cvl.ContentDocumentId);
                System.debug('###### Gen=' + cvl.LinkedEntityId);
        }
        if (cvl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'contact') {
                conIdMap.put(cvl.ContentDocumentId, cvl.LinkedEntityId);
                System.debug('###### Gen=' + cvl.LinkedEntityId);
                docIdMap.put(cvl.LinkedEntityId, cvl.ContentDocumentId);
        }
    }

    if(!genIdMap.isEmpty()) {
        List<Curabox_Genehmigung__c> gnList = [SELECT id, Contact__c FROM Curabox_Genehmigung__c WHERE id IN : genIdMap.keySet()];
        if((gnList != null) && (gnList.size() > 0)) {
            for(Curabox_Genehmigung__c gn : gnList) {
                contentDocumentLink cdl= new contentDocumentLink(ShareType='I', Visibility='AllUsers', LinkedEntityId=gn.Contact__c, contentDocumentId=genIdMap.get(gn.id));
                shareList.add(cdl); 
            }
        }
        if(!shareList.isEmpty()) {
            // insert shareList;    
            Database.SaveResult[]  sriList = Database.insert(shareList, false); 
            for(Database.SaveResult dr : sriList) {
                if (dr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully insert contentDocumentLink with ID: ' + dr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('contentDocumentLink fields that affected this error: ' + err.getFields());
                    }
                }  
            }
        }
    }

    if(!conIdMap.isEmpty()) {
        System.debug('###### alex=');
        Set<id> pg51 = new Set<id>();
        Set<id> pg54 = new Set<id>();
        Set<id> pg5X = new Set<id>();
        List<contentDocument> cdList = [SELECT id, title FROM contentDocument WHERE id IN :conIdMap.keySet()];
        for(contentDocument cd : cdList) {
            system.debug('#### alex6060 title='+ cd.Title);
            if(cd.Title.startsWithIgnoreCase('Genehmigung_PG54')) {
                pg54.add(cd.id);
                system.debug('#### alex6061 title='+ cd.Title);
            }
            else if(cd.Title.startsWithIgnoreCase('Genehmigung_PG51')) {
                pg51.add(cd.id);
                system.debug('#### alex6062 title='+ cd.Title);
            }
            else if(cd.Title.startsWithIgnoreCase('Genehmigung_PG5X')) {
                pg5X.add(cd.id);
                system.debug('#### alex6063 title='+ cd.Title);
            }
        }  
        map<id, id> contGenMap = new map<id, id>();
        if(!pg54.isEmpty()) {
            set<id> ct54 = new Set<id>();
            for(id cdid : pg54) {
                ct54.add(conIdMap.get(cdid));
            }
            List<curabox_genehmigung__c> gn54List = [SELECT id, Contact__c FROM curabox_genehmigung__c WHERE Contact__c IN :ct54 AND Nach_Paragraph__c = '54' ORDER BY createddate desc];
            if((gn54List != null) && (gn54List.size() > 0)) {
                for(Curabox_Genehmigung__c gn : gn54List) {
                    if(!contGenMap.containsKey(gn.Contact__c)) {
                        contGenMap.put(gn.Contact__c, gn.id);
                        system.debug('##### alex6001 54 ' + gn.id);
                    }                    
                }                
            }
        }
        if(!pg51.isEmpty()) {
            set<id> ct51 = new Set<id>();
            for(id cdid : pg51) {
                ct51.add(conIdMap.get(cdid));
            }
            List<curabox_genehmigung__c> gn51List = [SELECT id, Contact__c FROM curabox_genehmigung__c WHERE Contact__c IN :ct51 AND Nach_Paragraph__c = '51' ORDER BY createddate desc];
            if((gn51List != null) && (gn51List.size() > 0)) {
                for(Curabox_Genehmigung__c gn : gn51List) {
                    if(!contGenMap.containsKey(gn.Contact__c)) {
                        contGenMap.put(gn.Contact__c, gn.id);
                        system.debug('##### alex6001 51 ' + gn.id);
                    }                    
                }                
            }
        }
        if(!pg5X.isEmpty()) {
            set<id> ct5X = new Set<id>();
            for(id cdid : pg5X) {
                ct5X.add(conIdMap.get(cdid));
            }
            List<curabox_genehmigung__c> gn5XList = [SELECT id, Contact__c FROM curabox_genehmigung__c WHERE Contact__c IN :ct5X AND Nach_Paragraph__c = '5X' ORDER BY createddate desc];
            if((gn5XList != null) && (gn5XList.size() > 0)) {
                for(Curabox_Genehmigung__c gn : gn5XList) {
                    if(!contGenMap.containsKey(gn.Contact__c)) {
                        contGenMap.put(gn.Contact__c, gn.id);
                        system.debug('##### alex6001 5X ' + gn.id);
                    }                    
                }                
            }
        }   

        if(!contGenMap.isEmpty()) {
            for(id ctid : contGenMap.keySet()) {
                
                contentDocumentLink cdl= new contentDocumentLink(ShareType='I', Visibility='AllUsers', LinkedEntityId=contGenMap.get(ctid), contentDocumentId=docIdMap.get(ctid));
                shareListG.add(cdl); 
            }
        }
        if(!shareListG.isEmpty()) {
            // insert shareList;    
            Database.SaveResult[]  sri2List = Database.insert(shareListG, false); 
            for(Database.SaveResult dr : sri2List) {
                if (dr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully insert contentDocumentLink with ID: ' + dr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('contentDocumentLink fields that affected this error: ' + err.getFields());
                    }
                }  
            }
        }

    }
}