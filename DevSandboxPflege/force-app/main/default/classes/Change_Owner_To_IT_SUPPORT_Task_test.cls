/****************************************************************************************************************************
// Created 01.08.2018 von  MZ
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
//	test class for "Change_Owner_To_IT_SUPPORT_Task"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class Change_Owner_To_IT_SUPPORT_Task_test {
	static testMethod void myUnitTest() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        task t = new task();
        t.Subject = 'test';
        t.WhatId = opp.Id;
        insert t;
        
        ApexPages.StandardController sc = new ApexPages.standardController(t);
        PageReference pRef = Page.Change_Owner_To_IT_SUPPORT_Task;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', t.id);
        Change_Owner_To_IT_SUPPORT_Task co = new Change_Owner_To_IT_SUPPORT_Task(sc);
        
        co.Change_owner();
    }
}