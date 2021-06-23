/*/****************************************************************************************************************************
// Created 31.07.2018 von MZ
//          Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//          Nordkanalstrasse 58
//          20097 Hamburg 
//          Tel.:  04064917161
//          Fax.:  04064917162
//          Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Description: Test for EmailServiceBadumbau
//     
//
//****************************************************************************************************************************
// Changes:
//****************************************************************************************************************************/
@isTest
private class EmailServiceBadumbau_test {
    
    
    static testMethod void myUnitTest() {
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();    
        
        email.subject = 'Test badumabu opportunity';
        email.fromname = 'FirstName LastName';
        email.fromAddress = 'someaddress@email.com';
        String[] toAddress = new String[] {'emailto@email.com'};
        
        email.toAddresses = toAddress;
        email.ccAddresses = toAddress;
        email.plainTextBody = 'test email';      
        email.htmlBody = email.plainTextBody; 
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';      
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        
        Messaging.InboundEmail.TextAttachment tattachment = new Messaging.InboundEmail.TextAttachment();
        tattachment.body = 'my text attachment text';
        tattachment.fileName = 'textfile2.txt';
        tattachment.mimeTypeSubType = 'text/plain';     
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { tattachment };        
        
        env.fromAddress = 'someaddress@email.com';
        EmailServiceBadumbau emailService = new EmailServiceBadumbau();
        emailService.handleInboundEmail(email, env);        
    
    }
    
}