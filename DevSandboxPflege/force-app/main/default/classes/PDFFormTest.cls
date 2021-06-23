/****************************************************************************************************************************
// Created on 26.05.2020 by BT
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
//****************************************************************************************************************************
//
// Description: 
//                         test class for the apex class PDFForm      
//
//****************************************************************************************************************************
// Changes:   
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
private class PDFFormTest {
    @testSetup
    static void setup(){
        Account a = new Account(Name='Test Account');
        insert a;
        
        Contact c = new Contact(LastName='Test Contact',
                                AccountId=a.Id);
        insert c; 
        
        PDF_Form_Settings__c setting = new PDF_Form_Settings__c(Name='Antragsformular',
                                                               Endpoint__c ='http://ec2-52-57-158-21.eu-central-1.compute.amazonaws.com/fillVertrag.php',
                                                               Password__c='Sebastian1',
                                                               PDF_IDs__c='<ids original="243551168BAA407E9BFAB91A5A5B8C20" modified="4FD814BA2DF16E4ABD379E91CAB0ADD8"/>',
                                                               User__c='salesforce');
        insert setting;        
    }
    
	@isTest
    static void testFillAntragFormular(){        
        Contact c = [SELECT Id, Account.Familien_ID__c FROM Contact WHERE LastName = 'Test Contact'];
        ApexPages.StandardController sc = new ApexPages.StandardController(c);                
        PageReference pdfPage = Page.PdfFormPage; 
        pdfPage.getParameters().put('id', String.valueOf(c.Id));
        Test.setCurrentPage(pdfPage);   
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PDFFormMock());
        PDFForm form = new PDFForm();
        form.fillAntragFormular();
        Test.stopTest();
        Integer numberOfDocuments = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id];
        System.assertEquals(1, numberOfDocuments);
    }
    
	@isTest
    static void testGetFilledPdfForm(){        
        Contact c = [SELECT Id, Account.Familien_ID__c FROM Contact WHERE LastName = 'Test Contact'];  
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PDFFormMock());      
        PDFForm.getFilledPdfForm('Antrag', c.Account.Familien_ID__c, c.Id);
        Test.stopTest();
        Integer numberOfDocuments = [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :c.Id];
        System.assertEquals(1, numberOfDocuments);
    }    
    
    @isTest
    static void testGetPdfFormId(){
        PDFForm form = new PDFForm();
        String result = form.getPdfFormId();
        System.assert(result==null);
    }
}