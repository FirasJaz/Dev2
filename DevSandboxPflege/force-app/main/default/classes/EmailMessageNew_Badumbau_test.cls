/****************************************************************************************************************************
// Created 31.07.2018 von  MZ
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
//	test class for "EmailMessageNew_Badumbau"
//
//****************************************************************************************************************************
// Changes:
// 12.03.2019	AD	#164300658 Email für Abrechnungsunterlagen in der Empfänger-Liste hinzugefügt. 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class EmailMessageNew_Badumbau_test {
    
    
    static testMethod void callAllMethods(){
        
        List<EmailTemplate> etList = EmailMessageNew_Badumbau.getTemplates();
        
        Id temlpateId;
        if(etList != null && etList.size()>0){
            temlpateId = etList[0].Id;
        }
        EmailMessageNew_Badumbau.getTemplateBody(temlpateId);
        
        // create an opportunity to test
        Account account = new Account();
        account.Name = 'TestName';
        insert account;
        
        opportunity opp = TestDataFactory.createOpportunity('Badumbau', 'from_test_class');
        opp.AccountId = account.Id;
        update opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        c.AccountId = account.Id;
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
        
        EmailMessageNew_Badumbau.getContacts(opp.Id, temlpateId);
        
        EmailMessageNew_Badumbau.getAllAttachments(opp.Id);
        
        EmailMessageNew_Badumbau.addToSelectedList(attachment.Id, null);
        
        EmailMessageNew_Badumbau.getNewAttachmentsList();
        
        List<Id> docIds = new List<Id>();
        docIds.add(attachment.Id);
        EmailMessageNew_Badumbau.sendEmailToContact(opp.Id, 'test subject', 'test body', temlpateId, c.Id , docIds);
            
    }
    
    /*
    static testMethod void sendEmailWithAttachment(){
        List<Folder> fList = [select Id, name from Folder where name = 'Badumbau' limit 1];
            
        EmailTemplate et = new EmailTemplate();
        et.name = 'sendEmailWithAttachment_test';
        et.Body = 'test';
        et.IsActive = true;
        et.DeveloperName = 'sendEmailWithAttachment_test';
        et.FolderId = fList[0].Id;
        et.TemplateType = 'custom';
        insert et;
        
        
       // Blob b = Blob.valueOf('Test Data');
       // Attachment attachment = new Attachment();
       // attachment.ParentId = et.Id;
       // attachment.Name = 'Test Attachment for Parent';
       // attachment.Body = b;
       // insert attachment;
		
        List<RecordType> oppRtList = [select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId = oppRtList[0].Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        DateTime myDateTime = DateTime.newInstance(2019, 1, 31, 7, 8, 19);
        opp.CloseDate = myDateTime.date();
        Test.startTest();
        Database.SaveResult result = Database.insert(opp);
        Test.stopTest();
        
        system.debug('' + result.getErrors());
        
        Contact cv = new Contact();
        cv.FirstName = 'ksg_cv_test';
        cv.LastName = 'test cv';
        cv.Email = 'tset@klosesrockepartner.de';
        cv.MailingPostalCode = '23213';
        insert cv;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        c.Vermieter__c = cv.Id;
        insert c;
        
        EmailMessageNew_Badumbau.sendEmailToContact(opp.Id, 'test subject', 'test body', et.Id, c.Id , new List<Id>());
        
    }*/
    
    @isTest
    public static void getEmptyAccountIds(){
        
        // create an opportunity to test
        opportunity opp = TestDataFactory.createOpportunity('Badumbau', 'from_test_class');
        
        // First test case: get Account that not exists
        List<Id> leerList = new List<Id>();
        System.assertEquals(leerList, EmailMessageNew_Badumbau.getAccountFromOpportunity(opp.Id));
        System.assertEquals(leerList, EmailMessageNew_Badumbau.getAccountFromOffer(opp.Id));
        System.assertEquals(leerList, EmailMessageNew_Badumbau.getAccountFromAbrechnungsunterlagen(opp.Id));
    }
    
    @isTest
    Public static void getAccountIds(){
        
        List<Id> testList = new List<Id>();
        Account account = new Account();
        account.Name = 'TestName';
        insert account;
        
        opportunity opp = TestDataFactory.createOpportunity('Badumbau', 'from_test_class');
        opp.AccountId = account.Id;
        opp.Partner_Badumbau__c = account.Id;
        opp.account_sponsor__c = account.Id;
        opp.Partner_fuer_Begutachtung__c = account.Id;
        update opp;
        System.assertNotEquals(testList, EmailMessageNew_Badumbau.getAccountFromOpportunity(opp.Id));
        
        List<RecordType> acctList = [select id, name from RecordType where SobjectType = 'Account' and developerName ='Vermieter' limit 1];
        Account landlord = new Account();
        landlord.Name = 'TestLandlord';
        landlord.RecordTypeId = acctList[0].Id;
        insert landlord;
        Offer__c offer = new Offer__c();
        offer.account_landlord__c = landlord.Id;
        offer.opportunity__c = opp.Id;
        insert offer;
        EmailMessageNew_Badumbau.getAccountFromOffer(opp.Id);
        
        Abrechnungsunterlagen__c abrech = new Abrechnungsunterlagen__c();
        abrech.opportunity__c = opp.Id;
        abrech.Factoring_Partner__c = landlord.Id;
        insert abrech;
        System.assertNotEquals(testList, EmailMessageNew_Badumbau.getAccountFromAbrechnungsunterlagen(opp.Id));  
    }
    
    
    
}