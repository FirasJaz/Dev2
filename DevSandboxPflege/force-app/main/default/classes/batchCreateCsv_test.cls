@isTest
public with sharing class batchCreateCsv_test {
    @testSetup static void setupData() {
        // Custom settings
        AB_KK__c cs = new AB_KK__c(name= 'AB_KK_Einstellungen', Abrechnungsfirma__c = 'AS Abrechnungsstelle für Heil-Hilfs- und Pflegeberufe AG');
        cs.Kundennummer__c = 2;
        cs.maNummerMedifox__c = '4001';
        cs.maNummerWebcare__c = '4002';
        insert cs;
    }

    static testMethod void directBatch() {
        account a = new account(name='test');
        insert a;
        id batchid = Database.executeBatch(new batchCreateCsv('test'));
    }

    static testMethod void updateInvoice() {
        account a = new account(name='test');
        insert a;
        invoice__c i = new invoice__c(Account__c = a.id, invoice_text__c = 'abc def');
        insert i;

        i.asb_pdf_created__c = true;
        update i;
    }
}