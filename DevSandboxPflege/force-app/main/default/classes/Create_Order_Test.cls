@isTest
private class Create_Order_Test {

    @testSetup static void dataForTest() {
        // custom settings
        Delivery_Date__c delivery = new Delivery_Date__c(Name = 'default', Delivery__c = 18);
        insert delivery;
        // create_test_product.createProducts();
        // create_test_product.createTestContacts(2);
    }

    @isTest static void checkDeliveryDate() {
        // create products test data
        create_test_product.createProducts();
        // create contact
		create_test_product.createTestContacts(2);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create Genehmigung
        create_test_product.createGenehmigung();
        Curabox_Genehmigung__c genehmigung = [SELECT Id, Name, unbefristet_genehmigt__c FROM Curabox_Genehmigung__c WHERE Contact__c =:con.Id AND Nach_Paragraph__c = '54' LIMIT 1];
        genehmigung.unbefristet_genehmigt__c = true;
        genehmigung.genehmigt_ab__c = System.today();
        update genehmigung;
        Date isCB = Create_Order.checkDeliveryDate(contactId, 'CB2');
        Date isKuwv = Create_Order.checkDeliveryDate(contactId, 'KUWV');
        Date today = System.today();
        Date liefertag = today.addMonths(1).toStartOfMonth();
        datetime myDate = datetime.newInstance(liefertag.year(), liefertag.month(), liefertag.day());
        String day = myDate.format('EEEE');
        if (day == 'Saturday') {
            liefertag = liefertag.addDays(2);
        }
        else if (day == 'Sunday') {
            liefertag = liefertag.addDays(1);
        }
        // System.assertEquals(liefertag, isCB);
        // System.assertEquals(liefertag, isKuwv);
    }

    @isTest static void insertNewOrder() {
        // create products test data
        create_test_product.createProducts();
        // create contact
		create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        Date liefertag = System.today();
        String glove1 = 'Peha-soft Vinyl Einmalhandschuhe (Größe S)';
        String glove2 = 'Peha-soft Vinyl Einmalhandschuhe (Größe M)';
        List <Product_List> pList = Product_List.getAllProduct(contactId);
        Product__c product1 = Product_List.getProductByName('Universalsprühkopf 500ml/1l');
        Product_List sprue = Product_List.createProductForFlexbox(product1);
        Product__c product2 = Product_List.getProductByName('Einmalpumpe langer Auslauf 350/500 ml');
        Product_List pump = Product_List.createProductForFlexbox(product2);
        sprue.menge = 2;
        pump.menge = 1;
        String isCB = Create_Order.insertNewOrder(contactId, liefertag, 'monatlich', '54', 'CB3', pList, glove1, 1, glove2, 1, liefertag.addYears(2), sprue, pump);
        String isFlex = Create_Order.insertNewOrder(contactId, liefertag, 'monatlich', '54', 'CB6 - Flexibel', pList, glove1, 1, glove2, 1, liefertag.addYears(2), sprue, pump);

        System.assertNotEquals('er Auftrag konnte nicht generiert werden', isCB);
        System.assertNotEquals('er Auftrag konnte nicht generiert werden', isFlex);
        //
        Order__c order = new Order__c();
        List<Order_Line__c> orderLineList =  new List<Order_Line__c>();
        Create_Order.createDelivery(contactId, '54', order , orderLineList);
    }

    @isTest static void closeOpportunity() {
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders and opportunities
        create_test_product.createOrders();
        // Test
        Create_Order.closeOpportunity(contactId, 'Closed Won');
    }

    @isTest static void getCuraboxes() {
        // create products test data
        create_test_product.createProducts();
        List<curabox__c> gloveList = Create_Order.getCuraboxes();
        System.assertEquals(7, gloveList.size());
    }

    @isTest static void getGloves() {
        // create products test data
        create_test_product.createProducts();
        List<Product__c> gloveList = Create_Order.getGloves();
        System.assertEquals(12, gloveList.size());
    }

    @isTest static void getProductList() {
        // create product
        create_test_product.createProducts();
        // create family
        Account fa = Product_List_Test.createFamily('Transwaggon');
        insert fa;
        curabox__c curabox = Product_List_Test.createCurabox('CB3');

        Product__c handschuhe = [SELECT Id, Name FROM Product__c Where Product_Group__r.Name = 'Einmalhandschuhe' LIMIT 1];
        // create Test contacts
        Contact con = Product_List_Test.createContact('De Jong', fa, handschuhe, curabox, 'Herr');
        insert con;
        // create Genehmigung
        create_test_product.createGenehmigung();
        String conId = con.Id;
        List<Product_List> pList = Create_Order.getProductList('CB1', conId, true);
        List<Product_List> pList2 = Create_Order.getDefaultProducts(conId);
        String wunschbox = Create_Order.getCuraboxByContact(conId);
        List<Product_List> pList3 = Create_Order.getGlovesData(conId, 'CB3');
        System.assertEquals(4, pList.size());
        System.assertEquals(3, pList2.size());
        System.assertEquals('CB3', wunschbox);
        System.assertEquals(1, pList3.size());
    }

    @isTest static void getSpruehkopf() {
        // create products test data
        create_test_product.createProducts();
        Product_List product = Create_Order.getSpruehkopf();
        System.assertEquals(0, product.menge);
    }

    @isTest static void checkMonthCurrentOrder() {
        // create products test data
        create_test_product.createProducts();
        // create contact
        create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create orders and opportunities
        create_test_product.createOrders();
        // Tests
        Boolean isWert = Create_Order.checkMonthCurrentOrder(contactId, System.today(), 'KUWV');
        System.assertNotEquals(true, isWert);
    }

    @isTest static void checkParagraph() {
        String curabox = Create_Order.checkParagraph('CB-Flexibel');
        String kuwv = Create_Order.checkParagraph('KUWV');
        System.assertEquals('54', curabox);
        System.assertEquals('51', kuwv);
    }

    @isTest static void setGenehmigungDateline() {
        // create products test data
        create_test_product.createProducts();
        // create contact
		create_test_product.createTestContacts(1);
        Contact con = [SELECT Id, Name FROM Contact LIMIT 1];
        String contactId = con.Id;
        // create Genehmigung
        create_test_product.createGenehmigung();
        //
        Date result = Create_Order.setGenehmigungDateline(contactId, 'CB4');
        System.assertNotEquals(System.today(), result);
        // set unbefristet_genehmigt__c value
        Curabox_Genehmigung__c genehmigung = [SELECT Id, Name, unbefristet_genehmigt__c FROM Curabox_Genehmigung__c WHERE Contact__c =:con.Id AND Nach_Paragraph__c = '54' LIMIT 1];
        genehmigung.unbefristet_genehmigt__c = true;
        genehmigung.genehmigt_ab__c = System.today();
        update genehmigung;
        // Tests
        Date result2 = Create_Order.setGenehmigungDateline(contactId, 'CB4');
        System.assertNotEquals(System.today(), result2);
    }
}