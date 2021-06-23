/****************************************************************************************************************************
// Created 09.06.2018 von  MZ
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
// 	Email Message Id
//
//****************************************************************************************************************************
//
// Description:       
//	to reply to or forward an email
//
//****************************************************************************************************************************
// Test class:
//  EmailMessageAction_Badumbau_test
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public class EmailMessageAction_Badumbau {
   
    @AuraEnabled
    public static EmailMessage getOriginalEmail(Id messageId){
        List<EmailMessage> emList = [select id,
                                     subject,
                                     Incoming,
                                     Badumbau_inbound__c,
                                     relatedToId,
                                     toAddress,
                                     ccAddress,
                                     textBody,
                                     HtmlBody,
                                     status,
                                     fromAddress,
                                     parentId,
                                     messageDate
                                     from EmailMessage 
                                     where Id = :messageId 
                                     limit 1];
        if(emList != null && emList.size()>0){
            return emList[0];
        }
        return null;
    }
    
    @AuraEnabled
    public static List<Contact> getContacts(String messageId) {
        List<EmailMessage> emList = [select id,
                                     subject,
                                     Incoming,
                                     Badumbau_inbound__c,
                                     relatedToId,
                                     toAddress,
                                     ccAddress,
                                     textBody,
                                     HtmlBody,
                                     status,
                                     fromAddress,
                                     parentId,
                                     messageDate
                                     from EmailMessage 
                                     where Id = :messageId 
                                     limit 1];
        if(emList != null && emList.size()>0){
            return EmailMessageNew_Badumbau.getContacts(emList[0].relatedToId, '');
        }
        return new List<Contact>();
    }
    
    @AuraEnabled
    public static Id getReplyToContactId(Id messageId) {
        Id selectedContactId;
        
        List<EmailMessageRelation> emrList = [select id, 
                                              RelationType, 
                                              EmailMessageId, 
                                              RelationId 
                                              from EmailMessageRelation 
                                              where EmailMessageId = :messageId 
                                              and RelationType = 'FromAddress' limit 1];
        if(emrList != null && emrList.size()>0){
            selectedContactId = emrList[0].RelationId;
        }
        return selectedContactId;
    }
    
    @AuraEnabled
    public static List<Id> addToSelectedList(String selectedAttachment, List<Id> selectedAttachmentList) {
        return EmailMessageNew_Badumbau.addToSelectedList(selectedAttachment, selectedAttachmentList);
    }
    
    @AuraEnabled
    public static List<ContentDocumentLink> getAllAttachments(String oppId) {
        return EmailMessageNew_Badumbau.getAllAttachments(oppId);
    }
    
	@AuraEnabled
    public static List<Id> getNewAttachmentsList() {
        return EmailMessageNew_Badumbau.getNewAttachmentsList();
    }
    
    @AuraEnabled
    public static String sendEmailAction(String oppId, String emailSubject, String emailBody, String contactId, String receiverEmailAddress, List<Id> documnetIds) {
        if(contactId != null && !String.isEmpty(contactId) && contactId != '--keine--'){
            return EmailMessageNew_Badumbau.sendEmailToContact(oppId, emailSubject, emailBody, '', contactId, documnetIds);
        }
        else if(receiverEmailAddress != null && !String.isEmpty(receiverEmailAddress)){
            return sendEmailToEmailAddress(oppId, emailSubject, emailBody, receiverEmailAddress, documnetIds);
        }
        else{
            return 'Error: Bitte wählen Sie Empfänger!';
        }
    }
    
    
    @AuraEnabled
    public static String sendEmailToEmailAddress(String oppId, String emailSubject, String emailBody, String receiverEmailAddress, List<Id> documnetIds) {
        try{
            String emailText = (emailBody.replaceAll('<br />', '\n').replaceAll('<[^>]+>',' ') ).replaceAll('&nbsp;', ' ');
        
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
            
            if(String.isEmpty(receiverEmailAddress)){
                return 'Error: Bitte wählen Sie Empfänger!';
            }else{
                List<String> emailAddresses = receiverEmailAddress.split(';');
                mail.toaddresses = emailAddresses;
            }
            
            if(documnetIds == null){
                documnetIds = new List<Id>();
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