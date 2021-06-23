@isTest
private class Create_Genehmigung_Positionen_Test {
    
    public static Curabox_Genehmigung__c createGenehmigung(String conId, String pg){
        Curabox_Genehmigung__c genehmigung = Create_Genehmigung.newGenehmigung(conId, pg, '');
        return genehmigung;
    }
    
    @isTest static void createPositions(){
   		// create products test data
        create_test_product.createProducts();
        List<Product_Group__c> pgList = [SELECT Id, Name FROM Product_Group__c WHERE Positionsnummer__c = '54'];
        List<Product_Group__c> kuwvList = [SELECT Id, Name FROM Product_Group__c WHERE Positionsnummer__c = '51'];
        // create family
        Account fa = Product_List_Test.createFamily('Transwaggon');
        insert fa;
        curabox__c curabox = Product_List_Test.createCurabox('CB3');
        Product__c handschuhe = [SELECT Id, Name FROM Product__c Where Product_Group__r.Name = 'Einmalhandschuhe' LIMIT 1];
        // create Test contacts
        Contact con = Product_List_Test.createContact('De Jong', fa, handschuhe, curabox, 'Herr');
        insert con;
        // create Genehmigung
        String contactId = con.Id;
        Curabox_Genehmigung__c genehmigung = createGenehmigung(contactId, '54');
        insert genehmigung;
        List<Curabox_Genehmigungsposition__c> gPositions = Create_Genehmigung_Positionen.createPositions(genehmigung, pgList);
        List<Curabox_Genehmigungsposition__c> kuwvPositions = Create_Genehmigung_Positionen.createPositions(genehmigung, kuwvList);
        // 
        System.assertEquals(7, gPositions.size());
        System.assertEquals(1, kuwvPositions.size());
    }
}