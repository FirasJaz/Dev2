/****************************************************************************************************************************
// Created 31.07.2018 von  MZ
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
//  test class for "TaskListView"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class TaskListView_test {
    
    static testMethod void getTaskList(){
        
        //prepare data
        List<RecordType> oppRtList = [select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId = oppRtList[0].Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        List<RecordType> rtList = [select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Task' limit 1];
        Task t = new Task();
        t.RecordTypeId = rtList[0].Id;
        t.activityDate = Date.today();
        t.WhatId = opp.Id;
        t.Status = 'New';
        insert t;
        
        TaskListView tlv = new TaskListView();
        List<Task> tList = tlv.allTasklist;
        tList = tlv.Tasklist;
        tlv.doSearchTasks();
        tlv.taskPhaseChanegd();
        
        tlv.getUserList();
        tlv.getPhaseOptionsList();
        tlv.getSubPhaseOptionsList();
        
        tlv.SortToggle();
        PageReference pRef = Page.TaskListView;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('sortToggleParam', 'Subject');
        tlv.SortToggle();
               
    }
  
}