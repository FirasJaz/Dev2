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
//	test class for "TaskNewBadumbau"
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class TaskNewBadumbau_test {

    static testMethod void createNewTask(){
        
        // Perform our data preparation.
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        
        insert opp;
    	
        // get page reference
        ApexPages.StandardController oppController = new ApexPages.StandardController(opp);
        TaskNewBadumbau tnb = new TaskNewBadumbau(oppController); 
        
        tnb.phaseChanged();
        tnb.subPhaseChanged();
        tnb.saveTask();
    }
    
}