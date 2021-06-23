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
//                      This is a test class for the "FollowUp_BackInPool" apex class. 
//
//********************************************************************************************************************************************
// Changes:
//
//********************************************************************************************************************************************
*/
@isTest
private class FollowUp_BackInPoolTest {
    
    @testSetup static void insertTestData() {
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Familienangehörige').getRecordTypeId();
        
        Contact c1 = new Contact();
        c1.LastName = 'Contact1';
        c1.RecordTypeId = recordTypeId;        
        insert c1;
        
        Follow_up_Task__c followUp1 = new Follow_up_Task__c();
        followUp1.Subject__c = 'Nachfassen bei PK wg. offener KÜ';
        followUp1.Due_Date__c = Date.today().addDays(-5);
        followUp1.Contact__c = c1.Id;
        followUp1.Status__c = 'Offen';
        insert followUp1;
    }

    static testMethod void testChangeCurrentEditor() {
        Follow_up_Task__c followUp = [select currentEditor__c from Follow_up_Task__c limit 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(followUp);
        FollowUp_BackInPool backInPool = new FollowUp_BackInPool(sc);
        backInPool.changeCurrentEditor();
        
        followUp = [select currentEditor__c from Follow_up_Task__c limit 1];
        System.assertEquals(followUp.currentEditor__c, null);
    }
    
    static testMethod void testToListView() {
        Follow_up_Task__c followUp = [select currentEditor__c from Follow_up_Task__c limit 1];
        
        ApexPages.StandardController sc = new ApexPages.StandardController(followUp);
        FollowUp_BackInPool backInPool = new FollowUp_BackInPool(sc);
        PageReference returnPage = backInPool.toListView();
        
        Schema.DescribeSObjectResult result = Follow_up_Task__c.SObjectType.getDescribe();
        System.assertEquals(returnPage.getUrl().contains('/' + result.getKeyPrefix()), true);
    }
}