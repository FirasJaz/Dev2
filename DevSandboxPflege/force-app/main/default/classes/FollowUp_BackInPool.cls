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
//                      This class represents a controller for the visualforce page FollowUp_BackInPool
//                      It marks the follow up task as open.
//********************************************************************************************************************************************
// Changes:
//
//********************************************************************************************************************************************
*/
global with sharing class FollowUp_BackInPool {
    private Follow_up_Task__c followUp;

    // constructor
    global FollowUp_BackInPool(ApexPages.StandardController stdController) {
        this.followUp = (Follow_up_Task__c) stdController.getRecord();
    }

    // mark follow up task as open
    public PageReference changeCurrentEditor(){
        followUp.currentEditor__c = null;
        update followUp;
        return toListView();
    }

    // return to follow up task list view
    public PageReference toListView() {
        Schema.DescribeSObjectResult result = Follow_up_Task__c.SObjectType.getDescribe();  
        PageReference recordPage = new Pagereference('/' + result.getKeyPrefix());
        return recordPage;
    }
}