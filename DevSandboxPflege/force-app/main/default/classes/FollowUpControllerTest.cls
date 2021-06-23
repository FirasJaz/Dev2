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
//                      This is a test class for the "FollowUpController" apex class. 
//
//********************************************************************************************************************************************
// Changes:
//
//********************************************************************************************************************************************
*/
@isTest
private class FollowUpControllerTest {
    
    @testSetup static void insertTestData() {
        Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Familienangehörige').getRecordTypeId();
        
        Contact c1 = new Contact();
        c1.LastName = 'Contact1';
        c1.RecordTypeId = recordTypeId;        
        insert c1;
        
        Contact c2 = new Contact();
        c2.LastName = 'Contact2';
        c2.RecordTypeId = recordTypeId;
        insert c2;
        
        Follow_up_Task__c followUp1 = new Follow_up_Task__c();
        followUp1.Subject__c = 'Nachfassen bei PK wg. offener KÜ';
        followUp1.Due_Date__c = Date.today().addDays(-5);
        followUp1.Contact__c = c1.Id;
        followUp1.Status__c = 'Offen';
        insert followUp1;
        
        Follow_up_Task__c followUp2 = new Follow_up_Task__c();
        followUp2.Subject__c = 'Auftrag pausiert';
        followUp2.Due_Date__c = Date.today().addDays(10);
        followUp2.Contact__c = c2.Id;
        followUp2.Status__c = 'Offen';
        insert followUp2;
    }
    
    static testMethod void testCallFollowUpListView(){
        List<Follow_up_Task__c> followUpTasks;
        
        // set current page parameters
        PageReference followUpViewPage = Page.FollowUpView;
        Test.setCurrentPage(followUpViewPage);
        ApexPages.currentPage().getParameters().put('status', 'Offen');
        ApexPages.currentPage().getParameters().put('isDue', 'false');
        ApexPages.currentPage().getParameters().put('subject', 'Auftrag pausiert');
        
        FollowUpController fuController1 = new FollowUpController();
        fuController1.queryFollowUpTasks();
        followUpTasks = fuController1.followUpTasks;
        System.assertEquals(followUpTasks.size(), 1);
        Boolean nextBool = fuController1.hasNext;
        System.assertEquals(nextBool, false);
        Boolean prevBool = fuController1.hasPrevious;
        System.assertEquals(prevBool, false);
        Integer pageNumber = fuController1.pageNumber;
        System.assertEquals(pageNumber, 1);
        fuController1.sortExpression = null;
        String sortDirection = fuController1.getSortDirection();
        System.assertEquals(sortDirection, 'ASC');
        fuController1.next();
        followUpTasks = fuController1.followUpTasks;
        System.assertEquals(followUpTasks.size(), 1);
        fuController1.previous();
        followUpTasks = fuController1.followUpTasks;
        System.assertEquals(followUpTasks.size(), 1);
        
        // change current page parameters 'subject' and 'isDue'
        ApexPages.currentPage().getParameters().put('isDue', 'true');
        ApexPages.currentPage().getParameters().put('subject', 'Nachfassen bei PK wg. offener KÜ');
        
        FollowUpController fuController2 = new FollowUpController();
        fuController2.queryFollowUpTasks();
        followUpTasks = fuController2.followUpTasks;
        System.assertEquals(followUpTasks.size(), 1);
        fuController2.setSortDirection('DESC');
        sortDirection = fuController2.getSortDirection();
        System.assertEquals(sortDirection, 'DESC');
        fuController2.sortExpression = 'Contact__r.Name';
        sortDirection = fuController2.getSortDirection();
        System.assertEquals(sortDirection, 'ASC');
        fuController2.sortExpression = 'Contact__r.Name';
        sortDirection = fuController2.getSortDirection();
        System.assertEquals(sortDirection, 'DESC');
        fuController2.con = null;
        followUpTasks = fuController2.followUpTasks;
        System.assertEquals(followUpTasks, null);
        
        // change current page parameter 'isDue'
        ApexPages.currentPage().getParameters().put('isDue', 'null');
        
        FollowUpController fuController3 = new FollowUpController();
        fuController3.queryFollowUpTasks();
        followUpTasks = fuController3.followUpTasks;
        System.assertEquals(followUpTasks.size(), 1);
    }
    
    static testMethod void testSetFollowUpCurrentEditor() {
        // retrieve follow-up task
        Follow_up_Task__c followUp = [select id from Follow_up_Task__c where Status__c = 'Offen' limit 1];
        
        // set current page parameters
        PageReference followUpViewPage = Page.FollowUpView;
        Test.setCurrentPage(followUpViewPage);
        ApexPages.currentPage().getParameters().put('followUpId', followUp.Id);
        
        FollowUpController fuController = new FollowUpController();
        fuController.isDue = 'true';
        fuController.status = 'Offen';
        fuController.setFollowUpCurrentEditor();
        followUp = [select currentEditor__c, Status__c from Follow_up_Task__c where Id =: followUp.Id limit 1];
        System.assertEquals(followUp.CurrentEditor__c, UserInfo.getUserId());
        System.assertEquals(followUp.Status__c, 'In Bearbeitung');
    }
}