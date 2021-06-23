/****************************************************************************************************************************
// Created 29.04.2019 von  AD
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
// This class contains the help methods that uses curabox classes
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Curabox_Helper {

    @AuraEnabled
    public static Contact getContactById(String contactId){
        Contact contact = new Contact();
        List<Contact> contactList = new List<Contact>();
        try{ 
            contactList = [select Id, 
                                Wunschbox__r.Name, 
                                Pflegegrad__c, 
                                Salutation, 
                                LastName, 
                                FirstName,
                                Email, 
                                Kranken_Pflegekasse__c,
                                Kranken_Pflegekasse__r.Kanal_Unterpunkt__c, 
                                Art_Von_Handschuhe__r.Name,
                                Betreuer__r.Salutation,
                                Betreuer__r.FirstName,
                                Betreuer__r.LastName,
                                Betreuer__r.Email,
                                Pflegedienst__r.Name,
                                Pflegedienst__r.Email_Firma__c 
                                from Contact 
                                where Id=: contactId
                            ];    
        }      
        catch(Exception e){
            System.debug(e);
        }
        if(contactList != null && contactList.size() > 0){
                 contact = contactList[0];
        } 
        return contact;
    }

    // get email template
    public static EmailTemplate getTemplateByName(String templateName) {
        EmailTemplate template = new EmailTemplate();
        List<EmailTemplate> templateList = new List<EmailTemplate>();
        try{
            templateList = [select Id, 
                                    Name, 
                                    DeveloperName, 
                                    isActive, 
                                    Subject, 
                                    HtmlValue, 
                                    Body 
                                    from EmailTemplate 
                                    where Name =:templateName 
                                    limit 1];
        }
        catch(Exception e){
            System.debug(e);
        }
        if(templateList != null && templateList.size() > 0){
                template = templateList[0];
        }
        return template;
    }

    // get the curabox opportunity Id for a contact and return this.
    public static OpportunityContactRole getOpportunityByContact(String contact){
        OpportunityContactRole role = new OpportunityContactRole();
        List<OpportunityContactRole> roleList = new List<OpportunityContactRole>();
        try{ 
            roleList = [SELECT OpportunityId, Role FROM OpportunityContactRole where ContactId =: contact ORDER BY CreatedDate DESC];
            if(roleList != null && roleList.size() > 0){
                role = roleList[0];
            }
        }
        catch(Exception e){
            System.debug(e);
        }
        return role;
    }

    /**
    *  This method get the opportunity stage for a contact
    */
    public static Opportunity getOpportunityStage(String contactId){
        String oppId = getOpportunityByContact(contactId).OpportunityId;
        List<RecordType> recordTypList = [SELECT Id, SobjectType, Name FROM RecordType WHERE Name ='Curabox' AND SobjectType = 'Opportunity'];
        RecordType rt = recordTypList[0]; 
        Opportunity opportunity = new Opportunity();
        List<Opportunity> oppList = new List<Opportunity>();
        try{ 
            OppList = [SELECT Id, Name, StageName, CloseDate FROM Opportunity WHERE Id =: oppId  AND RecordTypeId =: rt.Id AND StageName != 'Abbruch' ORDER BY CreatedDate DESC];
            if(OppList != null && OppList.size() > 0){
                 opportunity = OppList[0];
            }
        }
        catch(Exception e){
            System.debug(e);
        }
        return opportunity;
    }

    // check if a curabox is flexible.
    public static Boolean isCB6Flexibel(String curabox){
        Boolean returnValue = false;
        if (curabox != null && !String.isEmpty(curabox)) { 
            if (curabox == 'CB1' || curabox == 'CB2' || curabox == 'CB3' || curabox == 'CB4' || curabox == 'CB5' || curabox == 'KUWV'){
                returnValue = false;
            }
            else {
                returnValue = true;
            }
        }
        else{
            returnValue = true;
        }
        return returnValue;
    }

    // get order by orderId
    public static Order__c getOrderById(String orderId){
        List<Order__c> orderList = new List<Order__c>();
        Order__c order = new Order__c();
        try {
            orderList = [Select Id, Name, Status__c, Liefertag__c, Delivery_frequency__c, Contact__c from Order__c where Id =:orderId];
            order = orderList[0];
        } catch (Exception e) {
            System.debug(e);
        }
        return order;
    }

    // get Genehmigung by contact
    public static Curabox_Genehmigung__c getGenehmigungByContact(String contactId, String paragraph){
        List<Curabox_Genehmigung__c> genehmigungList = new List<Curabox_Genehmigung__c>();
        Curabox_Genehmigung__c genehmigung = new Curabox_Genehmigung__c();
        try {
            genehmigungList = [SELECT Id, Name, Status__c, genehmigt_ab__c, genehmigt_bis__c, unbefristet_genehmigt__c, Nach_Paragraph__c from Curabox_Genehmigung__c 
                                WHERE Contact__c =:contactId AND Nach_Paragraph__c=:paragraph AND (Status__c ='Antragsversand' OR Status__c ='Bewilligung')
                                ORDER BY Antrag_eingegangen_am__c DESC];
            if (genehmigungList != null && genehmigungList.size() > 0) {
                genehmigung = genehmigungList[0];   
            }
        } catch (Exception e) {
            System.debug(e);
        }
        return genehmigung;
    }

    public static ContentDocumentLink getDocumentLink(String recordId, String documentId){
        List<ContentDocumentLink> cdl = [SELECT Id,  ContentDocumentId, LinkedEntityId, Visibility FROM ContentDocumentLink WHERE LinkedEntityId =: recordId AND ContentDocumentId =: documentId];
        return cdl[0];
    }

}