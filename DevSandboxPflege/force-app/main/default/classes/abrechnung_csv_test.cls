//****************************************************************************************************************************
// Erstellt 15.08.2019 von AM
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
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// test für abrechnung_csv
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
@isTest //(seealldata=true)
public with sharing class abrechnung_csv_test {
    static testMethod void myUnitTest() {   
        
        abrechnung_csv ext1 = new abrechnung_csv();
        PageReference tpageRef = Page.abrechnung_csv;
        Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('call', 'los');
        ApexPages.currentPage().getParameters().put('kk', 'test ziaei');
        ext1.getAufruf();
        ext1.getKkName();
        ext1.setKkName('test');
        ext1.goSend();
    }
}