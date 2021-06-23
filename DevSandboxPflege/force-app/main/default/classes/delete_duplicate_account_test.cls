/****************************************************************************************************************************
// Erstellt 24.10.2016 von AM
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
// keine 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// löschen doppelten accounts und dazugehörige contacts - aufruf
//
//
//****************************************************************************************************************************
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest(seealldata=false)
public with sharing class delete_duplicate_account_test {
    static testMethod void testAll(){
        Account f1 = new Account(name = 'TestFamilie1', Familien_CRM_ID__c='12345');
        insert f1;
        //Account f2 = new Account(name = 'TestFamilie2', Familien_CRM_ID__c='12345');
        //insert f2;
        
        delete_duplicate_account_run mobject = new delete_duplicate_account_run();
        String sch = '0 0 5 * * ?';
        system.schedule('Schedule TEST', sch, mobject); 
    }
}