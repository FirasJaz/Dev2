/********************************************************************************************************************************************
// Created 08.07.2019 by BT
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
//                      This class represents a controller for the visualforce page Approval_BackInPool
//                      It marks the approval record as open.
//********************************************************************************************************************************************
// Changes:
//
//********************************************************************************************************************************************
*/
global with sharing class Approval_BackInPool {
    private Curabox_Genehmigung__c approval;

    // constructor
    global Approval_BackInPool(ApexPages.StandardController stdController) {
        this.approval = (Curabox_Genehmigung__c) stdController.getRecord();
    }

    // mark approval record as open
    public PageReference changeCurrentEditor(){
        approval.currentEditor__c = null;
        update approval;
        return toListView();
    }

    // return to approval list view
    public PageReference toListView() {  
        Schema.DescribeSObjectResult result = Curabox_Genehmigung__c.SObjectType.getDescribe();  
        PageReference recordPage = new Pagereference('/' + result.getKeyPrefix());
        return recordPage;   
    }
}