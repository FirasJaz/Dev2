/****************************************************************************************************************************
// Erstellt 18.07.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine
//****************************************************************************************************************************
//
// Beschreibung: set Delivery_Note__c.pod_recieved__c=true if Title LIKE 'Ablieferbeleg...'
//                      
//              
//
//****************************************************************************************************************************
// Test:  
//*****************************************************************************************************************************
// Änderungen:   
// 22.07.2019 AM Erteilen die Berechtigung für document an alle Mitarbeiter  (Organization)
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
trigger after_insert_contentVersion on ContentVersion (after insert) {
    set<id> dnSet = new Set<id>();
    set<id> ivSet = new Set<id>();
    // Map<id, id> genMap = new Map<id, id>();
    set<id> cdidSet = new Set<id>(); 
    id orgId = [SELECT id FROM Organization LIMIT 1].id;
    List<contentDocumentLink> shareList = new List<contentDocumentLink>(); 
    for(ContentVersion cv : Trigger.new) {
        if(cv.FirstPublishLocationId != null) {
            if (cv.FirstPublishLocationId.getSObjectType().getDescribe().getName() == 'Delivery_Note__c') {
                if(cv.Title.containsIgnoreCase('ABLIEFERBELEG')) {
                    dnSet.add(cv.FirstPublishLocationId);
                }
            }
            if (cv.FirstPublishLocationId.getSObjectType().getDescribe().getName() == 'Invoice__c') {
                ivSet.add(cv.FirstPublishLocationId);
            }
            // if (cv.FirstPublishLocationId.getSObjectType().getDescribe().getName() == 'Curabox_Genehmigung__c') {
            //     genMap.put(cv.FirstPublishLocationId, cv.contentDocumentId);
            // }
        }
        if(cv.contentDocumentId != null) {
            cdidSet.add(cv.contentDocumentId);
        }
    }

    // update DeliveryNote
    if(!dnSet.isEmpty()) {
        List<Delivery_Note__c> dnList = [SELECT id, pod_recieved__c FROM Delivery_Note__c WHERE id IN : dnSet];
        if((dnList != null) && (dnList.size() > 0)) {
            for(Delivery_Note__c dn : dnList) {
                dn.pod_recieved__c = true;
            }
            update dnList;
        }
    }

    // update Invoice
    if(!ivSet.isEmpty()) {
        List<Invoice__c> ivList = [SELECT id, pdf_created__c FROM Invoice__c WHERE id IN : ivSet];
        if((ivList != null) && (ivList.size() > 0)) {
            for(Invoice__c iv : ivList) {
                iv.pdf_created__c = true;
            }
            update ivList;
        }
    }

    // Curabox_Genehmigung__c
    // if(!genMap.isEmpty()) {
    //     List<Curabox_Genehmigung__c> gnList= [SELECT id, Contact__c FROM Curabox_Genehmigung__c WHERE id IN : genMap.keySet()];
    //     if((gnList != null) && (gnList.size() > 0)) {
    //         for(Curabox_Genehmigung__c gn : gnList) {
    //             contentDocumentLink cdl= new contentDocumentLink(ShareType='C', Visibility='AllUsers', LinkedEntityId=gn.Contact__c, contentDocumentId=genMap.get(gn.id));
    //             shareList.add(cdl);
    //         }
    //     }        
    // }

    // insert contentDocumentLink 
    if(!cdidSet.isEmpty()) {        
        for(id cdid : cdidSet) {
            contentDocumentLink cdl= new contentDocumentLink(ShareType='C', Visibility='AllUsers', LinkedEntityId=orgId, contentDocumentId=cdid);
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