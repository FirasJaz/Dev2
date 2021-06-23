/****************************************************************************************************************************
// Created 19.07.2019 von  AD
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
//****************************************************************************************************************************
//
// Description:       
//  Test Klasse.
//****************************************************************************************************************************
// Changes:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
private class Curabox_Formular_Versenden_Test {

    @testSetup static void EmailTemplateForTest() {
        // create email template
        List<EmailTemplate> templateList = new List<EmailTemplate>();
        EmailTemplate blanko = new EmailTemplate(Name = 'curabox_blanko_per_email', DeveloperName = 'Alex', isActive = true, Subject = 'Antragsformular', 
                                                    HtmlValue = 'Test body', Body = 'Test body', FolderId= UserInfo.getUserId(),TemplateType = 'Text');
        EmailTemplate vorausgefuellt =  new EmailTemplate(Name = 'curabox_vorausgefuellt_per_email', DeveloperName = 'Alex_D', isActive = true, Subject = 'Antragsformular', 
                                                    HtmlValue = 'Test body', Body = 'Test body', FolderId= UserInfo.getUserId(),TemplateType = 'Text');
        EmailTemplate privat =  new EmailTemplate(Name = 'curabox_empfangsschreiben_privat', DeveloperName = 'TDAS', isActive = true, Subject = 'Antragsformular', 
                                                    HtmlValue = 'Test body', Body = 'Test body', FolderId= UserInfo.getUserId(),TemplateType = 'Text');
        EmailTemplate gesetzlich =  new EmailTemplate(Name = 'curabox_empfangsschreiben_gesetzlich', DeveloperName = 'TAS', isActive = true, Subject = 'Antragsformular', 
                                                    HtmlValue = 'Test body', Body = 'Test body', FolderId= UserInfo.getUserId(),TemplateType = 'Text');
        templateList.add(blanko);
        templateList.add(vorausgefuellt);
        templateList.add(privat);
        templateList.add(gesetzlich);
        insert templateList;
    }
    
    @isTest static void setDefaultReceiverPB(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name, AccountId FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE AccountId =: con.AccountId LIMIT 1];
        OpportunityContactRole role = new OpportunityContactRole (ContactId = con.Id, OpportunityId = opp.Id, IsPrimary = false, Role = 'PB');
        insert role;
        // Test 
        String res = Curabox_Formular_Versenden.setDefaultReceiver(contactId);
        System.assertNotEquals('', res);                                                               
    }

    @isTest static void setDefaultReceiverASP(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name, AccountId FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE AccountId =: con.AccountId LIMIT 1];
        OpportunityContactRole role = new OpportunityContactRole (ContactId = con.Id, OpportunityId = opp.Id, IsPrimary = false, Role = 'ASP');
        insert role;
        // Test 
        String res = Curabox_Formular_Versenden.setDefaultReceiver(contactId);
        String receiver = Curabox_Formular_Versenden.getReceiverEmail(contactId, 'AnsprechpartnerIn');
        System.assertNotEquals('', res);                                                               
    }

    @isTest static void setDefaultReceiverASPB(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name, AccountId FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders
        create_test_product.createOrders();
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE AccountId =: con.AccountId LIMIT 1];
        OpportunityContactRole role = new OpportunityContactRole (ContactId = con.Id, OpportunityId = opp.Id, IsPrimary = false, Role = 'PB = ASP');
        insert role;
        // Test 
        String res = Curabox_Formular_Versenden.setDefaultReceiver(contactId);
        String receiver = Curabox_Formular_Versenden.getReceiverEmail(contactId, 'Pflegedienst');
        System.assertNotEquals('', res);                                                               
    }

    @isTest static void mainTestMethod(){
        // custom settings
        Due_Date__c dueDate = new Due_Date__c(Name = 'Formularversand', Follow_Up_Task_Due_Date__c = 3);
        insert dueDate;
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(3);
        List<Contact> conList = [SELECT Id, Salutation, Name, FirstName, LastName, Email, AccountId, Betreuer__r.Salutation, Betreuer__r.Firstname, Betreuer__r.LastName FROM Contact];
        Contact con = conList[0];
        con.Salutation = 'Herr';
        con.Email = 'stephanealex72@yahoo.fr';
        String contactId = con.Id;
        // attach filled document to contact
        ContentVersion attach = new ContentVersion();
        Blob atbody  = Blob.valueOf('Test document');
        attach.VersionData = atbody;
        attach.Title = 'CB_Formular_Alex';
        attach.PathOnClient ='CB_Formular_Alex.pdf';
        attach.FirstPublishLocationId = con.Id;
        attach.ContentLocation = 'S';
        insert attach;
        // create orders
        create_test_product.createOrders();
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE AccountId =: con.AccountId LIMIT 1];
        OpportunityContactRole role = new OpportunityContactRole (ContactId = con.Id, OpportunityId = opp.Id, IsPrimary = false, Role = 'PB');
        insert role;
        // create second contact role
        Contact con1 = conList[1];
        String conId = con1.Id;
        con1.Salutation = 'Frau';
        Opportunity opp1 = [SELECT Id, Name FROM Opportunity WHERE AccountId =: con.AccountId LIMIT 1];
        OpportunityContactRole role1 = new OpportunityContactRole (ContactId = con1.Id, OpportunityId = opp1.Id, IsPrimary = false, Role = 'ASP');
        insert role1;
        // Test setEmailData(Contact contact, String receiver, String emailBody) 
        String res = Curabox_Formular_Versenden.setEmailData(con, 'AnsprechpartnerIn', '$anredeformel$ Test email body');
        String res1 = Curabox_Formular_Versenden.setEmailData(con1, 'AnsprechpartnerIn', '$anredeformel$ Test email body');
        String res2 = Curabox_Formular_Versenden.setEmailData(con, 'Pflegebedürftiger', '$anredeformel$ Test email body');
        String res3 = Curabox_Formular_Versenden.setEmailData(con1, 'Pflegedienst', '$anredeformel$ Test email body');
        System.assertNotEquals('', res);
        System.assertNotEquals('', res1);
        System.assertNotEquals('', res2);
        System.assertEquals('Sehr geehrte Damen und Herren Test email body', res3);
        // Test getReceiverId(String contactId, String receiver)
        String rev = Curabox_Formular_Versenden.getReceiverId(contactId, 'AnsprechpartnerIn');
        String rev1 = Curabox_Formular_Versenden.getReceiverId(conId, 'AnsprechpartnerIn');
        String rev2 = Curabox_Formular_Versenden.getReceiverId(contactId, 'Pflegebedürftiger');
        String rev3 = Curabox_Formular_Versenden.getReceiverId(conId, 'Pflegedienst');
        System.assertNotEquals('', rev);
        System.assertNotEquals('', rev1);
        System.assertNotEquals('', rev2);
        System.assertNotEquals('', rev3);

        // Test sendMailToClient(String contactId, String receiver)
        Test.setMock(HttpCalloutMock.class, new PDFFormMock());
        Test.startTest();
        String str = Curabox_Formular_Versenden.sendMailToClient(contactId, 'Pflegebedürftiger');
        Test.stopTest();
        String str2 = Curabox_Formular_Versenden.sendFilledFormular(contactId, 'Pflegebedürftiger');
        String str3 = Curabox_Formular_Versenden.sendConfirmationToClient(contactId, 'Pflegebedürftiger');
        Boolean isAttch = Curabox_Formular_Versenden.setFilledButton(contactId);
        System.assertEquals('Email wurde erfolgreich Versendet!', str);
        System.assertEquals('Email wurde erfolgreich Versendet!', str2);
        System.assertEquals('Email wurde erfolgreich Versendet!', str3);
        System.assertEquals(true, isAttch);                                                        
    }

}