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
// 	Email Message Id
//
//****************************************************************************************************************************
//
// Description:       
//	to reply to an email
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public class EmailMessageActionController {
    
    @AuraEnabled
    public static EmailMessage initializeEmailReply(Id messageId){
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
    public static String initializeEmailForward(){
        return '';
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
    public static Id setReplyToContact(List<Contact> contactList, Id messageId) {
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
    
    //@AuraEnabled
    //removeAttachments
    //
    
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
    public static String sendEmailToContact(String oppId, String emailSubject, String emailBody, String templateId, String contactId, List<Id> documnetIds) {
		return EmailMessageNew_Badumbau.sendEmailToContact(oppId, emailSubject, emailBody, templateId, contactId, documnetIds);
    }

}