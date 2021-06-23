/*********************************************************************************************************************************************
// Created 04.07.2018 by MZ
//                      Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                      Nordkanalstraße 58
//                      20097  Hamburg 
//                      Tel.:  0423882986
//                      Fax.:  0423882986
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:    
//    #155510105 - Bad goes Salesforce.com
//    to handel inbound emails to Badumabu
//    if the key "OP-OP-{000000}" was found in email subject, email will be assigned to opportunity automatically.
//
//********************************************************************************************************************************************
//  Changes:
//  30.07.2018  MZ  if no opportunity found, related to would be filled with DummyCuraboxAccount
//  09.11.2018  MZ  System.DmlException: Insert failed. First exception on row 0; first error: STRING_TOO_LONG, HTML Body: data value too large:
//  04.01.2019  MZ  Unzustellbar: null - System.NullPointerException: Attempt to de-reference a null object
//  28.02.2019  MZ  163975596 Badumabu - EmailService Error. exception handeling on email.Subject.substring(index, index + 9) added
//********************************************************************************************************************************************
*/
public without sharing class EmailServiceHandlerBadumbau {
    
    /**
     * creates an EmailMessage based on the inbound email. the message would be added to Badumbau-Emails in notification center */
    public EmailServiceHandlerBadumbau(Messaging.InboundEmail email) {
        
        Boolean opportunityFound = false;
        Boolean contactFound = false;
        
        EmailMessage msg = new EmailMessage();
        msg.Incoming = true;
        msg.Subject = email.Subject;
        msg.Badumbau_inbound__c = true;
        msg.relatedToId = getDummyRelatedTo();
        
        if(String.isEmpty(email.Subject)){
            msg.Subject = 'kein Betreff';
        }else{
            // find the opportunity number from email. to be able to assign it to opportunity. OP-{000000}
            try{
                Integer index = email.Subject.indexOfIgnoreCase('OP-');
                if(index != -1){
                    String oppNumber = email.Subject.substring(index, index + 9);
                    List<Opportunity> oppList = [select id, name from Opportunity where Opportunity_Nummer__c = :oppNumber limit 1];
                    if(oppList != null && oppList.size()>0){
                        msg.relatedToId = oppList[0].Id;
                        opportunityFound = true;
                    }
                }
            }
            catch(Exception e){
                msg.Subject = email.Subject;
            }
        }
        
        
        String[] toAddr = email.toAddresses;
        if(toAddr != null && toAddr.size()>0 ){
            msg.toAddress = toAddr[0];
        }
        
        String[] ccAddr = email.ccAddresses; 
        if(ccAddr != null && ccAddr.size()>0 ){
            msg.ccAddress = ccAddr[0];
        }
         
        if(email.plainTextBody != null && email.plainTextBody.length() > 32000 ){
            msg.textBody = email.plainTextBody.substring(0, 32000) ;
        }else{
            msg.textBody = email.plainTextBody;
        }
        
        if(email.htmlBody != null && email.htmlBody.length() > 32000 ){
            msg.HtmlBody = email.htmlBody.substring(0, 32000) ;
        }else{
            msg.HtmlBody = email.htmlBody;
        }
        
        msg.status = '0';
        
        String fromAddr = email.fromAddress;  
        if(fromAddr != null) {
            fromAddr = fromAddr.trim(); 
            
            // to get fromAddress if it is an undelivered email.
            // TODO: check if it is undelivered then maybe a task should be created instead of email message
            if(fromAddr == 'mailer-daemon@salesforce.com') {
                if(email.plainTextBody != null){
                    try{
                        String tmp = email.plainTextBody.substringBetween('failed:', '(Undelivered)').trim();
                        if(!String.isEmpty(tmp)){
                            fromAddr = tmp.replaceAll('>', '').replaceAll('<', '').replaceAll('\n', '').trim();
                        }
                    }catch(Exception e){
                        msg.fromAddress= fromAddr;
                    }
                }
            }
        }
        msg.fromAddress= fromAddr;
        
        
        List<Id> toIds = new List<Id>();
        List<EmailMessageRelation> msgRelationList= new List<EmailMessageRelation>();
        
        EmailMessageRelation msgr = new EmailMessageRelation();
        
        msgr.RelationType = 'FromAddress';
        msgr.RelationAddress = fromAddr;
        
        
        list<contact> contactList = [SELECT id FROM contact WHERE Email = : fromAddr order by createdDate desc limit 1];
        if((contactList != null) && (contactList.size() > 0 )) {
            msgr.RelationId = contactList[0].Id;
            toIds.add(contactList[0].Id);
            contactFound = True;
        }
        msgRelationList.add(msgr);
        
        EmailMessageRelation msgrTo = new EmailMessageRelation();
        msgrTo.EmailMessageId = msg.Id;
        msgrTo.RelationType = 'ToAddress';
        msgrTo.RelationAddress = msg.toAddress;
        msgRelationList.add(msgrTo);
                
        if(contactFound){
            msg.ToIDs = toIds;
        }
                
        try{
            insert msg;
            for(EmailMessageRelation emr : msgRelationList){
                emr.EmailMessageId = msg.Id;
            }
            insert msgRelationList;
        
            list<attachment> atList = new list<attachment>();
            if ((email.binaryAttachments != null) && (email.binaryAttachments.size() > 0)) {
                for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
                    Attachment a = new Attachment(ParentId = msg.Id,             
                                                    Name = email.binaryAttachments[i].filename,
                                                    Body = email.binaryAttachments[i].body);
                    atList.add(a);
                }
            }
            if ((email.textAttachments != null) && (email.textAttachments.size() > 0)) {
                for (integer i = 0 ; i < email.textAttachments.size() ; i++) {
                    Attachment a = new Attachment(ParentId = msg.Id,             
                                                    Name = email.textAttachments[i].filename,
                                                    Body = blob.valueOf(email.textAttachments[i].body));
                    atList.add(a);                  
                }
            }
            if((atList != null) && (atList.size() > 0)) {
                try {
                    insert atList;
                    system.debug('###############################alex012 attachment insert OK');
                }
                catch (System.Exception e) {
                    system.debug('###############################alex015 attachment insert error='  + e);
                }    
            } 
        }
        catch(Exception e){
            system.debug('###############################alex016 could not insert message error='  + e);
        }
    }
    
    // Either one of the fields "relatedTo" or "ParentId" should be filled in Email message object.
    // when both of them are null, user won't be able to see the record
    public Id getDummyRelatedTo(){
        List<Account> aList = [select Id, name from account where name = 'DummyCuraboxAccount' limit 1];
        if(aList != null && aList.size()>0){
            return aList[0].Id;
        }
        return null;
    }
    

}