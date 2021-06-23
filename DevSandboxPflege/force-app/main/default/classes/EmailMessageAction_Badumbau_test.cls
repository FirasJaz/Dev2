/****************************************************************************************************************************
// Created 16.08.2018 von  MZ
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
//
//****************************************************************************************************************************
//
// Description:       
//	test class for "EmailMessageAction_Badumbau"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class EmailMessageAction_Badumbau_test {

    static testMethod void callAllMethods(){
        
        // create an opportunity to test
        List<RecordType> oppRtList = [select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId = oppRtList[0].Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB = ASP';
        insert cr;
        
        Blob b = Blob.valueOf('Test Data');
        Attachment attachment = new Attachment();
        attachment.ParentId = opp.Id;
        attachment.Name = 'Test Attachment for Parent';
        attachment.Body = b;
        insert attachment;
        
        // create a ew message to test
        EmailMessage msg = new EmailMessage();
        //msg.ActivityId = emailTask.Id;
        msg.Incoming = true;
        msg.Subject = 'email subject';
        msg.Badumbau_inbound__c = true;
        msg.relatedToId = EmailMessageInboundList_Badumbau.getDummyRelatedTo();
        msg.toAddress = 'ziaei@klosesrockepartner.de';
        msg.textBody = 'email text body';
        msg.HtmlBody = 'email html body';
        msg.status = '0';
        insert msg;
        
        
        EmailMessageAction_Badumbau.getOriginalEmail(msg.Id);
        
        EmailMessageAction_Badumbau.getContacts(msg.Id);
        
        EmailMessageAction_Badumbau.getReplyToContactId(msg.Id);
        
        EmailMessageAction_Badumbau.getAllAttachments(opp.Id);
        
        EmailMessageAction_Badumbau.addToSelectedList(attachment.Id, null);
        
        EmailMessageAction_Badumbau.getNewAttachmentsList();
        
        List<Id> docIds = new List<Id>();
        docIds.add(attachment.Id);
        
        Test.startTest();
        // send email to contact
        EmailMessageAction_Badumbau.sendEmailAction(opp.Id, 'test subject', 'test body', c.Id, '' , docIds);

        // send email to an address
        EmailMessageAction_Badumbau.sendEmailAction(opp.Id, 'test subject', 'test body', '', 'test@test.test' , docIds);
        Test.stopTest();
    }
}