/****************************************************************************************************************************
// Created 27.08.2020 von  AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstr. 29
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: CSV-Datei als String (UTF-8), datum von, datum bis
//
//****************************************************************************************************************************
//
// Description:       
//  test für uploadCB6Reduzieren_Batch
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public with sharing class uploadCB6Reduzieren_test {
    @testSetup static void dataForTest() {
    }

    static testMethod void TestuploadCB6Reduzieren_Batch() {
        curabox__c cb6 = new curabox__c(name='CB6 - Flexibel', description__c='CB6 - Flexibel', editable__c=true);
        insert cb6;

        Product__c pr1 = new Product__c(name='product1', abda_mwst_knz__c='1');
        insert pr1;
        Product__c pr2 = new Product__c(name='product1', abda_mwst_knz__c='1');
        insert pr2;

        LiefermengeReduzierung__c lmr = new LiefermengeReduzierung__c();
        lmr.product__c = pr1.id;
        lmr.CuraboxName__c = 'All Files';
        insert lmr;   

        String crlf = '\r\n';
        String csvString = String.valueOf(pr1.id) + ';' + String.valueOf(pr2.id) + ';' + String.valueOf(pr1.id) + '_Alt;'  + String.valueOf(pr1.id) + '_Neu;' + String.valueOf(pr2.id) + '_Alt;'  + String.valueOf(pr2.id) + '_Neu;Schluessel' + crlf; 
        csvString += '1;1;1;1;1;1;11' + crlf;
        system.debug('##### ' + csvString);
        attachment at = new attachment(ParentId = lmr.id);
        at.name = 'alle_cb6.csv';
        at.body = blob.valueOf(csvString);
        insert at;        

        
        uploadCB6Reduzieren_Batch b = new uploadCB6Reduzieren_Batch();
        Database.executeBatch(b);
    }


}