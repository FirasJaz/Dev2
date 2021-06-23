@isTest
public class genehmigungStatusHelper_test {

    @testSetup static void dataForTest() {
        // custom settings
        CompanyInfo__c companyInfo = new CompanyInfo__c(name='Default', IK_Nummer__c='567894939', KDNR_bei_Lieferant__c='12345678', Telefon__c='040665656', Fax__c= '040 888');
        insert companyInfo;
        // products master data
        create_test_product.createProducts();
        // contact master data - Optional: (integer contactCount)
        create_test_product.createTestContacts(2);
        // Genehmigung
        create_test_product.createGenehmigung();
        // transaction data
        // orders+order lines 
        create_test_product.createOrders();
        List<Curabox_Genehmigung__c> gnList = [SELECT id, Status__c FROM Curabox_Genehmigung__c];
        for(Curabox_Genehmigung__c gn : gnList) {
            gn.Status__c = 'Antragsversand';
        }
        update gnList;
    }

    public static testMethod void genehmigungStatusTest(){
        List<Curabox_Genehmigung__c> gnList = [SELECT id, Status__c FROM Curabox_Genehmigung__c];
        for(Curabox_Genehmigung__c gn : gnList) {
            gn.Status__c = 'Bewilligung';
        }
        update gnList;
    }
}