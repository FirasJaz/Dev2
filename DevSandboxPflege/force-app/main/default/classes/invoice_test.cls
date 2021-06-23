@isTest
public class invoice_test {
    static testMethod void invoiceTest() {
        list<RecordType> kk_rtList = [SELECT Id FROM RecordType WHERE Name = '03 Kostenträger']; 
        // Pflegekasse gesetzlich
        Account KK = new Account(name='Testpflegekasse', Industry = 'Krankenkassen', type = 'Test');
        KK.RecordTypeId = kk_rtList[0].id;
        KK.IK_Nummer__c = '12345678';
        KK.Kanal_Unterpunkt__c = 'gesetzlich';
        KK.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
        KK.Hilfsmittel_Kennzeichen__c = 'HM';     
        KK.AC__c = 'AC';
        KK.TK__c = 'TK';   
        KK.Medifox_Ausschluss__c = true;
        KK.BillingStreet = 'Teststrasse';
        KK.Billingcity = 'Testort';
        KK.BillingPostalCode = '12345';
        KK.Fax = '04012345678';
        insert KK;  
        
        Invoice__c i = new Invoice__c(Account__c=kk.id);
        insert i;
        update i;
     }
}