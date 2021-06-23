/****************************************************************************************************************************
// Created 24.07.2018 von  MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Description:       
//	controller for EmailMessageInboundList component
//
//****************************************************************************************************************************
// Changes: 
// 26.10.2018	MZ	 161444088 set messageDate of the new message
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public without sharing class EmailMessageInboundList_Badumbau {
    
    /**
     * returns a list of all new email message that are generated from Badumbau email service handler
     **/
	@AuraEnabled
    public static List<EmailMessage> getAllNewEmails() {
         return [SELECT id, subject, fromAddress, messageDate 
                                        FROM EmailMessage
                                        WHERE ( status = '0' and Incoming = true and Badumbau_inbound__c = true)
                                        ORDER BY messageDate ASC];
    }
    
    /**
     * assign the email to opportunity. creates a new email with status Read
     * emailMessageRelation records are created automatically. no need to add extra create and delete for them.
     * */
    @AuraEnabled
    public static String assignToOpportunity(Id oppId, Id messageId){
        EmailMessage myEmailMessage = new EmailMessage();
        List<EmailMessage> emList = [select id,
                                     MessageDate,
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
                                     FromName
                                     from EmailMessage 
                                     where Id = :messageId 
                                     limit 1];
        
        if(emList != null && emList.size()>0){
            myEmailMessage = emList[0];
        }
        
        Id relatedToId = myEmailMessage.relatedToId;
        if(oppId != null){
            relatedToId = oppId;
        }
        if(relatedToId == null || relatedToId == getDummyRelatedTo()){
            return 'Error: Opportunity darf nicht leer sein!';
        }
        
        // cloning the object creates all EmailMessageRelation records automatically and removes RelationId. So every field should be copied seprately
        EmailMessage readMessage = new EmailMessage(); //myEmailMessage.clone();
        readMessage.MessageDate = myEmailMessage.MessageDate;
        readMessage.Incoming = myEmailMessage.Incoming;
        readMessage.Subject = myEmailMessage.Subject;
        readMessage.TextBody = myEmailMessage.TextBody;
        readMessage.HtmlBody = myEmailMessage.HtmlBody;
        readMessage.FromAddress = myEmailMessage.FromAddress;
        readMessage.FromName = myEmailMessage.FromName;
        //readMessage.ValidatedFromAddress = myEmailMessage.ValidatedFromAddress;
        readMessage.toAddress = myEmailMessage.toAddress;
        readMessage.ccAddress = myEmailMessage.ccAddress;
        readMessage.Status = '1';
        readMessage.Badumbau_inbound__c = false;
        readMessage.relatedToId = relatedToId;
        readMessage.Id = null;
        
        List<EmailMessageRelation> emrList = [select id, 
                                              RelationType, 
                                              EmailMessageId, 
                                              RelationId, 
                                              RelationAddress 
                                              from EmailMessageRelation 
                                              where EmailMessageId = :myEmailMessage.Id];
        
        List<EmailMessageRelation> emrListToInsert = new List<EmailMessageRelation>();
        for(EmailMessageRelation e : emrList){
            EmailMessageRelation emr = new EmailMessageRelation();
            emr.RelationType = e.RelationType;
            emr.RelationAddress = e.RelationAddress;
            emr.RelationId = e.RelationId;
            emrListToInsert.add(emr);
        }
        
        
        System.debug('####mansi::::readMessage:::'+ readMessage);
        List<Attachment> attList = [SELECT id, ParentId, Name, Body from attachment where ParentId = :messageId ];
        List<Attachment> attListToinsert = new List<Attachment>();
        
        Savepoint sp = Database.setSavepoint();
        try{
            insert readMessage;
            for(EmailMessageRelation e : emrListToInsert){
                e.EmailMessageId = readMessage.Id;
            }
            insert emrListToInsert;
            for(Attachment att : attList){
                Attachment a = new Attachment(ParentId = readMessage.Id,
                                              Name = att.name,
                                              Body = att.body);
                attListToinsert.add(a);
            }
            insert attListToinsert;
            
            delete myEmailMessage;
            
        }catch(Exception e){
            Database.rollback(sp);
            return 'Error: ' + e.getMessage();
        }
        return String.valueOf(relatedToId);
    }
    
    
    public static Id getDummyRelatedTo(){
        List<Account> aList = [select Id, name from account where name = 'DummyCuraboxAccount' limit 1];
        if(aList != null && aList.size()>0){
        	return aList[0].Id;
        }
        return null;
    }

}