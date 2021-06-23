/****************************************************************************************************************************
// Created 12.06.2018 von  MZ
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
//  opportunity Id
//
//****************************************************************************************************************************
//
// Description:       
//  to send a new email based on selected template 
//
//****************************************************************************************************************************
// Changes: 
// 28.09.2018   MZ  #160817165 Badumbau - Look up field Kostenträger-Service; contact of all lookup acounts added to contact list
// 11.03.2019   AD  #164300658 Email für Abrechnungsunterlagen in der Empfänger-Liste hinzugefügt. 
// 06.08.2019   DZ  #166870242 Added Look-Up Field for Badumbau partner for application
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class EmailMessageNew_Badumbau {
    /* to be added to select option
     * */
    private static String KEINE = '--keine--';
    
    /* get list of al Badumabu templates. user can select one of the templates.
     * */
    @AuraEnabled
    public static List<EmailTemplate> getTemplates() {
        List<EmailTemplate> emailTemplates = new List<EmailTemplate>();
        try{
            emailTemplates = [select id, name, developername from EmailTemplate where folderId in (select Id from Folder where developerName = 'Bad_Umbau') And DeveloperName != 'Partner_Weiterleitung_Aufmasskoordinierung' order by Name limit 100];
        }
        catch(Exception e){
            System.debug(e);
        } 
        return emailTemplates;
    }
    
    /* when user selects a template, email body should be filled in with the body of template
     * */
    @AuraEnabled
    public static EmailTemplate getTemplateBody(String templateId) {
        EmailTemplate et = new EmailTemplate();
        try{
            List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body from EmailTemplate where Id = :templateId limit 1];
            if(etList != null && etList.size() > 0){
                et = etList[0];
            }
        }
        catch(Exception e){
            System.debug(e);
        } 
        return et;
    }
    
    
    /* to get related contacts to opportunity to send an email to
     * */
    @AuraEnabled
    public static List<Contact> getContacts(String oppId, String templateId) {
        List<Contact> contactList = new List<Contact>();
        
        List<Contact> oppContact = [select id, name, title, email, Vermieter__c  from Contact where id in (select contactID from OpportunityContactRole where OpportunityId = :oppId)];
        if(oppContact != null && oppContact.size()>0){
            contactList.addAll(oppContact);
        }
        
        // list of all accounts that are related to opportunity. all of their contacts shoulb be available for user to send an email to.
        Set<ID> accountIds =  new Set<ID>();
        accountIds.addAll(getAccountFromOpportunity(oppId));
        accountIds.addAll(getAccountFromOffer(oppId));
        accountIds.addAll(getAccountFromAbrechnungsunterlagen(oppId));
        
        List<Contact> accContacts = [select id, name, title, email from Contact where accountid in : accountIds];
        if(accContacts != null && accContacts.size()>0){
            contactList.addAll(accContacts);
        }
        
        return contactList;
    }
    
    // get all account lookups from opportunity
    public static List<Id> getAccountFromOpportunity(String oppId){
        List<Id> accountList = new List<Id>();
        List<Opportunity> oppList = [select Partner_Badumbau__c, account_sponsor__c, Partner_fuer_Begutachtung__c, PartnerForApplication__c  from Opportunity where Id = :oppId];
        // list has one element only
        if(oppList != null && oppList.size()>0){
            for(Opportunity opp : oppList){
                if(opp.Partner_Badumbau__c != null){
                    accountList.add(opp.Partner_Badumbau__c);
                }
                if(opp.account_sponsor__c != null){
                    accountList.add(opp.account_sponsor__c);
                }
                if(opp.Partner_fuer_Begutachtung__c != null){
                    accountList.add(opp.Partner_fuer_Begutachtung__c);
                }
                
                if(opp.PartnerForApplication__c != null){
                    accountList.add(opp.PartnerForApplication__c);
                }
            }
        }
        return accountList;
    } 
    
    // get acounts that are related to offer of opportunity
    public static List<Id> getAccountFromOffer(String oppId){
        List<Id> accountList = new List<Id>();
        List<Offer__c> offerList = [select id, opportunity__c, account_landlord__c from Offer__c where opportunity__c = :oppId];
        // list may have more elements
        if(offerList != null && !offerList.isEmpty()){
            for(Offer__c offer : offerList){
                if(offer.account_landlord__c != null){
                    accountList.add(offer.account_landlord__c);
                }
            }
        }
        return accountList;
    } 
    
    // #164300658 - get acounts that are related to Abrechnungsunterlagen of opportunity
    public static List<Id> getAccountFromAbrechnungsunterlagen(String oppId){
        List<Id> accountList = new List<Id>();
        List<Abrechnungsunterlagen__c> abrechList = [select id, Factoring_Partner__c from Abrechnungsunterlagen__c where opportunity__c = :oppId];
        // list may have more elements
        if(abrechList != null && !abrechList.isEmpty()){
            for(Abrechnungsunterlagen__c abrech : abrechList){
                if(abrech.Factoring_Partner__c != null){
                    accountlist.add(abrech.Factoring_Partner__c);
                }
            }
        }
        return accountList;
    }   
    
    
    @AuraEnabled
    public static List<ContentDocumentLink> getAllAttachments(String oppId) {
        List<ContentDocumentLink> allAttachments = new List<ContentDocumentLink>();
        try{
            List<ContentDocumentLink> oppDocuments = [SELECT ContentDocumentID, LinkedEntityId, ContentDocument.Title  FROM ContentDocumentLink where LinkedEntityId = :oppId limit 100];
            if(oppDocuments != null && oppDocuments.size()>0){
                allAttachments.addAll(oppDocuments);
            }
            
            List<ContentDocumentLink> offerDocuments = [SELECT ContentDocumentID, LinkedEntityId, ContentDocument.Title  FROM ContentDocumentLink where LinkedEntityId in (select Id from offer__c where opportunity__c = :oppId) limit 100];
            if(offerDocuments != null && offerDocuments.size()>0){
                allAttachments.addAll(offerDocuments);
            }
            
            List<ContentDocumentLink> invoiceDocuments = [SELECT ContentDocumentID, LinkedEntityId, ContentDocument.Title  FROM ContentDocumentLink where LinkedEntityId in (select Id from Abrechnungsunterlagen__c where opportunity__c = :oppId) limit 100];
            if(invoiceDocuments != null && invoiceDocuments.size()>0){
                allAttachments.addAll(invoiceDocuments);
            }
        }
        catch(Exception e){
            System.debug(e);
        }
        return allAttachments;
    }
    
    @AuraEnabled
    public static List<Id> addToSelectedList(String selectedAttachment, List<Id> selectedAttachmentList) {
        if(selectedAttachmentList == null){
            selectedAttachmentList = new List<Id>();
        }
        selectedAttachmentList.add(Id.valueOf(selectedAttachment));
        return selectedAttachmentList;
    }
    
    @AuraEnabled
    public static List<Id> getNewAttachmentsList() {
        return new List<Id>();
    }
    
    @AuraEnabled
    public static String sendEmailToContact(String oppId, String emailSubject, String emailBody, String templateId, String contactId, List<Id> documnetIds) {
        try{
            String emailText = (emailBody.replaceAll('<br />', '\n').replaceAll('<[^>]+>',' ') ).replaceAll('&nbsp;', ' ');
        
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
            
            if(!String.isEmpty(contactId) && contactId != KEINE){
                mail.settargetobjectid(contactId);
            }else{
                return 'Error: Bitte wählen Sie Empfänger!';
            }
            
            if(documnetIds == null){
                documnetIds = new List<Id>();
            }
            List<Attachment> templateAttachments = new List<Attachment>();
            List<Document> templateDocuments = new List<Document>();
            if(!String.isEmpty(templateId) && templateId != KEINE){
                List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body from EmailTemplate where Id = :templateId limit 1];
                if(etList != null && etList.size() > 0){
                    EmailTemplate et = etList[0];
                    emailBody = et.HtmlValue;
                    emailText = et.Body;
                    emailSubject = et.Subject;
                    
                    templateAttachments = [select ID, Name, ContentType, Body From Attachment where parentId = :et.Id];
                    List<DocumentAttachmentMap> templateAttachmentMap = [select id, parentId, DocumentId from DocumentAttachmentMap where parentId = :et.Id];
                    if(templateAttachmentMap != null && templateAttachmentMap.size()>0){
                        Set<Id> td = new Set<Id>();
                        for(DocumentAttachmentMap tam : templateAttachmentMap){
                            td.add(tam.DocumentId);
                        }
                        templateDocuments = [select ID, name, ContentType, Body from Document where Id in :td];
                    }
                }
            }
            // replace merge fields --> ASP, PB, Opportunity
            emailBody = EmailMessageTagGenerator_Badumbau.resolveMergeFields(oppId, emailBody, UserInfo.getUserId());
            emailText = EmailMessageTagGenerator_Badumbau.resolveMergeFields(oppId, emailText, UserInfo.getUserId());
            emailSubject = EmailMessageTagGenerator_Badumbau.resolveMergeFields(oppId, emailSubject, UserInfo.getUserId());
            
            
            mail.setSaveAsActivity(true);
            if(!String.isEmpty(oppId)){
                mail.setWhatId(oppId);
            }
            mail.setSubject(emailSubject);
            mail.setPlainTextBody(emailText);
            mail.setHtmlBody(emailBody);
            
            List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Badumbau'];
            if(orgWideAddresses != null && orgWideAddresses.size()>0){
                mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
                mail.setReplyTo(orgWideAddresses[0].Address);
            }
            
            Messaging.EmailFileAttachment[] emailAttachments = new List<Messaging.EmailFileAttachment>();
            for(Attachment att : templateAttachments){
                Messaging.EmailFileAttachment fa = new Messaging.EmailFileAttachment();
                fa.setBody(att.body);
                if(att.name != null && att.name.containsIgnoreCase('.pdf')){
                    fa.setFileName(att.name);
                }else{
                    fa.setFileName(att.name + '.pdf');
                }
                fa.setContentType('application/pdf');
                emailAttachments.add(fa);
            }
            for(Document att : templateDocuments){
                Messaging.EmailFileAttachment fa = new Messaging.EmailFileAttachment();
                fa.setBody(att.body);
                if(att.name != null && att.name.containsIgnoreCase('.pdf')){
                    fa.setFileName(att.name);
                }else{
                    fa.setFileName(att.name + '.pdf');
                }
                fa.setContentType('application/pdf');
                emailAttachments.add(fa);
            }
            
            set<Id> documnetIdSet = new Set<Id>(); 
            documnetIdSet.addAll(documnetIds);
            
            List<ContentVersion> cvList = [select ID, versionData, FileType, title From ContentVersion where IsLatest= true and ContentDocumentId in : documnetIdSet];
            if(cvList != null && cvList.size()>0){
            for(ContentVersion cv : cvList){
                Messaging.EmailFileAttachment fa = new Messaging.EmailFileAttachment();
                fa.setBody(cv.versionData);
                if(cv.title != null && cv.title.containsIgnoreCase('.pdf')){
                    fa.setFileName(cv.title);
                }else{
                    fa.setFileName(cv.title + '.pdf');
                }
                fa.setContentType('application/pdf');                
                emailAttachments.add(fa);
            }
            }
            
            mail.setFileAttachments(emailAttachments);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );
            
            return 'Email wurde erfolgreich Versendet!';
            
        }catch(Exception e){
            System.debug('#####mansi::::' + e.getMessage());
            System.debug('#####mansi::::' + e);
            return 'Error: ' + e.getMessage();
        }
        
    }        

}