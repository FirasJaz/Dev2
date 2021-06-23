public class ksgEmailCuraboxBearbeiten { 
    private list<contact> ctList = new list<contact>();
    private list<task> tsList = new list<task>();
    private list<attachment> atList = new list<attachment>();
    private set<string> fwSet = new set<string>();
    private String fromAddr = null;
    private id asid = UserInfo.getUserId();
    private id tsid = null;
    private boolean zugeordnet = false;
    private string mailToUnresolved = 'dennis.zietkoff@pflege.de';
    private id rtid = null; 
    
    // public ksgEmailCuraboxBearbeiten () {}
    
    public ksgEmailCuraboxBearbeiten (Messaging.InboundEmail email) {
        rtid = null;                                
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'Email'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }
        if(email.fromname != null) {
            try {
                String fName = email.fromname.substring(0,email.fromname.indexOf(' '));
                String lName = email.fromname.substring(email.fromname.indexOf(' '));
            }
            catch(System.Exception e){
                system.debug('###############################alex000 keine fromname' + e);
            }
        }
        
        String[] toAddr = email.toAddresses;
        system.debug('###############################alex002 toAddr=' + toAddr);
        String[] ccAddr = email.ccAddresses; 
        system.debug('###############################alex003 ccAddr=' + ccAddr);
        String subject = email.Subject;     
        system.debug('###############################alex004 subject=' + subject);      
        
        fromAddr = email.fromAddress;  
        if(fromAddr != null) {
            fromAddr = fromAddr.trim(); 
            
            if(fromAddr == 'mailer-daemon@salesforce.com') {
                if(email.plainTextBody != null){
                    String tmp = email.plainTextBody.substringBetween('failed:', '(Undelivered)').trim();
                    if(!String.isEmpty(tmp)){
                        fromAddr = tmp.replaceAll('>', '').replaceAll('<', '').replaceAll('\n', '').trim();
                    }
                }
            }
                
            system.debug('###############################alex001 fromAddr=' + fromAddr);     
            list<user> usList = [SELECT id, email FROM user WHERE name = 'IT Support'];
            if((usList != null) && (usList.size() > 0)) {
                asid = usList[0].id;
                if(usList[0].email != null) mailToUnresolved = usList[0].email;
            }
            
            list<contact> frList = [SELECT id, AccountId, Account.OwnerID FROM contact WHERE Email = : fromAddr];
            if((frList != null) && (frList.size() == 1 )) {
                contact ct = frList[0];
            
                task ts = new task(Description = email.plainTextBody,
                                    Priority = 'High',
                                    Status = 'Ungelesen',
                                    RecordTypeId = rtId,
                                    Subject = email.subject,
                                    CC__c = string.valueOf(ccAddr),
                                    Email__c = email.fromAddress,
                                    //IsReminderSet = true,
                                    //ReminderDateTime = System.now()+1,
                                    ActivityDate = date.today(),
                                    WhatId = null,
                                    WhoId = ct.Id,
                                    type = 'Email',
                                    OwnerID = asid);
                                    
                                    if(email.plainTextBody == null) {
                                        ts.Description = email.HtmlBody;
                                    }
                try {
                    insert ts;
                    zugeordnet = true;
                    tsid = ts.id;
                    system.debug('###############################alex012 task insert OK');
                }
                catch (System.Exception e) {
                    system.debug('###############################alex013 e='  + e);
                }           
            }           
            
        }

        if(!zugeordnet) {
            // nicht zugeordnet
            createUnresolvedItem(asid, email);
        }
        else {
                if ((email.binaryAttachments != null) && (email.binaryAttachments.size() > 0)) {
                    for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
                        Attachment a = new Attachment(ParentId = tsId,             
                                                Name = email.binaryAttachments[i].filename,
                                                Body = email.binaryAttachments[i].body);
                        atList.add(a);              
                    }
                }
                if ((email.textAttachments != null) && (email.textAttachments.size() > 0)) {
                    for (integer i = 0 ; i < email.textAttachments.size() ; i++) {
                        Attachment a = new Attachment(ParentId = tsId,             
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
    }
        
    public void createUnresolvedItem(id what, Messaging.InboundEmail email) {
                id accid = null;
                list<account> acList = [SELECT id, name FROM account WHERE name = 'NICHT BEKANNT'];
                if((acList != null) && (acList.size() > 0 )) {
                    accid = acList[0].id;
                }
        
                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();         
                mail.setToAddresses(new String[] {mailToUnresolved});
                mail.setSubject(email.subject);
                mail.setPlainTextBody(email.plainTextBody);
                mail.setHtmlBody(email.HtmlBody);
                try {
                    // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
                        system.debug('#########################email unresolved OK #######');
                    }
                catch (System.Exception e)
                {
                    system.debug('#########################email####### error '  + e);
                }
                system.debug('###############################alex032 asid=' + asid);
                
                task ts = new task(Description = email.plainTextBody,
                    Priority = 'High',
                    Status = 'Ungelesen',
                    RecordTypeId = rtId,
                    Subject = email.subject,
                    CC__c = string.valueOf(email.ccAddresses),
                    Email__c = email.fromAddress, 
                    //IsReminderSet = true,
                    //ReminderDateTime = System.now()+1,
                    ActivityDate = date.today(),
                    WhatId = accid,
                    WhoId = null,
                    type = 'Email',
                    OwnerID = asid);
                    if(email.plainTextBody == null) {
                        ts.Description = email.HtmlBody;
                    }
                try {
                    insert ts;
                    tsid = ts.id;
                    system.debug('###############################alex032 task nicht zugeordnet insert OK');
                    if ((email.binaryAttachments != null) && (email.binaryAttachments.size() > 0)) {
                        for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) {
                            Attachment a = new Attachment(ParentId = tsId,             
                                                    Name = email.binaryAttachments[i].filename,
                                                    Body = email.binaryAttachments[i].body);
                            atList.add(a);              
                        }
                    }
                    if ((email.textAttachments != null) && (email.textAttachments.size() > 0)) {
                        for (integer i = 0 ; i < email.textAttachments.size() ; i++) {
                            Attachment a = new Attachment(ParentId = tsId,             
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
                catch (System.Exception e) {
                    system.debug('###############################alex0333 e='  + e);
                } 
                
    }   
    
}