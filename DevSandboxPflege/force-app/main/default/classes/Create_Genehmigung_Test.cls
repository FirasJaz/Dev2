@isTest
private class Create_Genehmigung_Test {

    @testSetup static void dataForTest() {
        // custom settings
        Due_Date__c dueDate = new Due_Date__c(Name = 'Antrag an PK', Follow_Up_Task_Due_Date__c = 14);
        insert dueDate;

        azhCredetials__c azh = new azhCredetials__c(name='Sandbox', Endpoint__c='test', User__c='test', password__c='test');
        insert azh;
        azh = new azhCredetials__c(name='Production', Endpoint__c='test', User__c='test', password__c='test');
        insert azh;
    }

    @isTest static void createGenehmigung(){
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        // create Genehmigung
        String contactId = con.Id;
        String str54 = Create_Genehmigung.createGenehmigung(contactId, '54', '');
        String str5x = Create_Genehmigung.createGenehmigung(contactId, '5X', '');
        String str = Create_Genehmigung.createGenehmigung(contactId, '', '');
        // Tests
        System.assertEquals('OK', str54);
        System.assertEquals('OK', str5x);
        System.assertEquals('Fehler beim Erzeugen der Genehmigung', str);

        // Test getGenehmigung(contactId, paragraph)
        Curabox_Genehmigung__c genehmigung = Create_Genehmigung.getGenehmigung(contactId, '54');
        System.assertNotEquals(null, genehmigung.Name);

        // Test sentToAZH(genehmigungId);
        Curabox_Genehmigung__c azhGenehmigung = [SELECT ID, Name FROM Curabox_Genehmigung__c WHERE Contact__c =: contactId AND Nach_Paragraph__c = '54' LIMIT 1];
        String genehmigungId = azhGenehmigung.Id;
        String azh = Create_Genehmigung.sentToAZH(genehmigungId);
        System.assertNotEquals(null, azh);
    }
}