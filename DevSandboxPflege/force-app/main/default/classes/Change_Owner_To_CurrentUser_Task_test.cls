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
//	test class for "Change_Owner_To_CurrentUser_Task"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class Change_Owner_To_CurrentUser_Task_test {
    
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
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Task;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', t.id);
        Change_Owner_To_CurrentUser_Task co = new Change_Owner_To_CurrentUser_Task(sc);
        
        co.Change_owner();
        
    }
    
    static testMethod void myUnitTest_ownerIsITUser() {
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        if(user_list != null && user_list.size()>0){
            opp.ownerID= user_list[0].id;
        }
        insert opp;
        
        task t = new task();
        t.Subject = 'test';
        t.WhatId = opp.Id;
        if(user_list != null && user_list.size()>0){
            t.ownerID= user_list[0].id;
        }
        insert t;
        
        
        ApexPages.StandardController sc = new ApexPages.standardController(t);
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Task;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', t.id);
        Change_Owner_To_CurrentUser_Task co = new Change_Owner_To_CurrentUser_Task(sc);
        
        co.Change_owner();
    }

}