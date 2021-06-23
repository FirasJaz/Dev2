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
//                      This is a test class for the "ApprovalController" apex class. 
//
//********************************************************************************************************************************************
// Changes:
//
//********************************************************************************************************************************************
*/
@isTest
private class ApprovalControllerTest {

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
        
        Contact c2 = new Contact();
        c2.LastName = 'Contact2';
        c2.RecordTypeId = recordTypeId;
        insert c2;
        
        Curabox_Genehmigung__c approval2 = new Curabox_Genehmigung__c();
        approval2.Contact__c = c2.Id;
        approval2.Status__c = 'Antragsversand';
        approval2.Nach_Paragraph__c = '54';
        approval2.KV_status__c = 'pending';
        insert approval2;
    }
    
    static testMethod void testCallApprovalListView() {
        List<Curabox_Genehmigung__c> approvals;
        
        // set current page parameters
        PageReference approvalViewPage = Page.ApprovalView;
        Test.setCurrentPage(approvalViewPage);
        ApexPages.currentPage().getParameters().put('status', 'Antragsversand');
        ApexPages.currentPage().getParameters().put('kvStatus', 'null');
        
        ApprovalController aController1 = new ApprovalController();
        aController1.queryApprovals();
        approvals = aController1.approvals;
        System.assertEquals(approvals.size(), 2);
        Boolean nextBool = aController1.hasNext;
        System.assertEquals(nextBool, false);
        Boolean prevBool = aController1.hasPrevious;
        System.assertEquals(prevBool, false);
        Integer pageNumber = aController1.pageNumber;
        System.assertEquals(pageNumber, 1);
        aController1.sortExpression = null;
        String sortDirection = aController1.getSortDirection();
        System.assertEquals(sortDirection, 'ASC');
        aController1.next();
        approvals = aController1.approvals;
        System.assertEquals(approvals.size(), 2);
        aController1.previous();
        approvals = aController1.approvals;
        System.assertEquals(approvals.size(), 2);
        
        // change current page parameter 'kvStatus'
		ApexPages.currentPage().getParameters().put('kvStatus', 'pending');  
        
        ApprovalController aController2 = new ApprovalController();
        aController2.queryApprovals();
        approvals = aController2.approvals;        
        System.assertEquals(approvals.size(), 1);
        aController2.setSortDirection('DESC');
        sortDirection = aController2.getSortDirection();
        System.assertEquals(sortDirection, 'DESC');
        aController2.sortExpression = 'Contact__r.Name';
        sortDirection = aController2.getSortDirection();
        System.assertEquals(sortDirection, 'ASC');
        aController2.sortExpression = 'Contact__r.Name';
        sortDirection = aController2.getSortDirection();
        System.assertEquals(sortDirection, 'DESC');
        aController2.con = null;
        approvals = aController2.approvals;
        System.assertEquals(approvals, null);
    }
    
    static testMethod void testSetApprovalCurrentEditor() {
        // retrieve approval
		Curabox_Genehmigung__c approval = [select id from Curabox_Genehmigung__c where KV_Status__c = 'pending'];
        
        // set current page parameters
        PageReference approvalViewPage = Page.ApprovalView;
        Test.setCurrentPage(approvalViewPage);
        ApexPages.currentPage().getParameters().put('approvalId', approval.Id);
        
        ApprovalController aController = new ApprovalController();
        aController.setApprovalCurrentEditor();
		approval = [select currentEditor__c from Curabox_Genehmigung__c where KV_Status__c = 'pending'];        
        System.assertEquals(approval.currentEditor__c, UserInfo.getUserId());
    }
}