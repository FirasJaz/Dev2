/********************************************************************************************************************************************
// Created 09.07.2019 by BT
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
//                      This is a test class for the "Approval_BackInPool" apex class. 
//
//********************************************************************************************************************************************
// Changes:
//
//********************************************************************************************************************************************
*/
@isTest
private class Approval_BackInPoolTest {

    @testSetup static void insertTestData() {
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Familienangehörige').getRecordTypeId();
        
        Contact c1 = new Contact();
        c1.LastName = 'Contact1';
        c1.RecordTypeId = recordTypeId;        
        insert c1;
        
        Curabox_Genehmigung__c approval1 = new Curabox_Genehmigung__c();
        approval1.Contact__c = c1.Id;
        approval1.Status__c = 'Antragsversand';
        approval1.Nach_Paragraph__c = '54';
        approval1.KV_status__c = 'send';
        insert approval1; 
    }
    
    static testMethod void testChangeCurrentEditor() {
        Curabox_Genehmigung__c approval = [select currentEditor__c from Curabox_Genehmigung__c limit 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(approval);
        Approval_BackInPool backInPool = new Approval_BackInPool(sc);
        backInPool.changeCurrentEditor();
        
        approval = [select currentEditor__c from Curabox_Genehmigung__c limit 1];
        System.assertEquals(approval.CurrentEditor__c, null);        
    }
    
    static testMethod void testToListView(){
        Curabox_Genehmigung__c approval = [select currentEditor__c from Curabox_Genehmigung__c limit 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(approval);
        Approval_BackInPool backInPool = new Approval_BackInPool(sc);
        PageReference returnPage = backInPool.toListView();
        
        Schema.DescribeSObjectResult result = Curabox_Genehmigung__c.SObjectType.getDescribe();
        System.assertEquals(returnPage.getUrl().contains('/' + result.getKeyPrefix()), true);
        
    } 
}