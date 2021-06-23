//****************************************************************************************************************************
// Created 10.07.2018      by AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstraße 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.:  04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Description:
//                      
// The trigger will set the field Name_Index__c like this: 
//      cb_(Index_of_campaig_type).(number_of_campaigns_from_this_type)
//
// Case 00001596 (##158556019)
//****************************************************************************************************************************
// Test: 
//****************************************************************************************************************************
// Changes:
//****************************************************************************************************************************
@isTest
private class campaign_trigger_test {

    static testMethod void myUnitTest() {
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        cmp.type='Cross-Selling';
        insert cmp;
        campaign rcmp = [SELECT Name_Index__c from campaign WHERE id = : cmp.id];
        System.assertEquals(rcmp.Name_Index__c , 'cb_2.1');
        
        Campaign cmp2 = new Campaign();
        cmp2.name = 'testclass_ksg';
        cmp2.type='Cross-Selling';
        insert cmp2;
        campaign rcmp2 = [SELECT Name_Index__c from campaign WHERE id = : cmp2.id];
        System.assertEquals(rcmp2.Name_Index__c , 'cb_2.2');
        
    }
}