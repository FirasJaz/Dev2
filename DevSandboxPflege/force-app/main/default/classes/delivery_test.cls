/****************************************************************************************************************************
// Erstellt 25.05.2019 von AM
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
//****************************************************************************************************************************
//
// Beschreibung: test for delivery.cls
//                      
//****************************************************************************************************************************     
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class delivery_test {
    @testSetup static void dataForTest() {
        // custom settings
        CompanyInfo__c companyInfo = new CompanyInfo__c(name='Default', IK_Nummer__c='567894939', KDNR_bei_Lieferant__c='12345678', Telefon__c='040665656', Fax__c= '040 888');
        insert companyInfo;


        // products master data
        create_test_product.createProducts();
    }

    static testMethod void TestDeliveryXml() {

        // contact master data - Optional: (integer contactCount)
        create_test_product.createTestContacts();
        // Genehmigung
        create_test_product.createGenehmigung();
        // transaction data
        // orders+order lines 
        create_test_product.createOrders();
        // delivery lines (Bedarf)
        create_test_product.createDeliverLinesBedarf();

        Set<id> ctSet = new Set<id>();
        List<contact> ctList = [SELECT id FROM contact WHERE id IN (SELECT Contact__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'Bedarf') ];
        for(contact c : ctList) {
            ctSet.add(c.id);
        }
        List<Delivery_Line__c> bedarfBevor = [SELECT id, Name FROM Delivery_Line__c WHERE Delivery_Status__c = 'Bedarf'];
        System.debug('####### bedarfBevor.size()' + bedarfBevor.size());
        test.startTest();
        delivery_xml dxml = new delivery_xml();
        dxml.processBedarf(ctSet);
        test.stopTest();
        List<Delivery_Line__c> geliefert = [SELECT id, Name FROM Delivery_Line__c WHERE Delivery_Status__c = 'geliefert'];
        System.debug('####### geliefert.size()' + geliefert.size());
        List<Delivery_Line__c> bedarfDanach = [SELECT id, Name FROM Delivery_Line__c WHERE Delivery_Status__c = 'Bedarf'];
        System.debug('####### bedarfDanach.size()' + bedarfDanach.size());
        if(dxml.getErrorListSize() > 0) {
            for(String rec : dxml.getErrorList()) {
                System.debug('####### Error:' + rec);
            }
        }
        // system.assertEquals(0, dxml.getErrorListSize());
        // system.assertEquals(bedarfBevor.size(), geliefert.size());
        // system.assertEquals(bedarfBevor.size(), bedarfDanach.size());
    }

    static testMethod void checkCB_KUWV_Zusammen() {
        // contact master data 
        create_test_product.createTestContacts(5);
        create_test_product.createGenehmigung();
        create_test_product.createOrders();
        create_test_product.createDeliverLinesBedarf();   
        List<Delivery_Line__c> dlList = [SELECT id, contact__c, Delivery_date__c, Order_Line__r.Order__r.Description__c FROM Delivery_Line__c WHERE Order_Line__r.Order__r.Description__c = 'KUWV'];
        boolean firstkuwv = false;
        id kundeMitKombiniertenLieferung = null;
        // wir haben 2 KUWV Bedarfe. Der 1. setzen wir Del.Date auf morgen (muss aber heute ausgeliefert werden)
        // Der 2. hat Del.Date im nächsten Monat (soll nicht geliefert werden)
        for(Delivery_Line__c dl: dlList) {
            system.debug('####### ' + dl.Order_Line__r.Order__r.Description__c + ' deldate:' + dl.Delivery_date__c);           
                if (!firstkuwv) {
                    dl.Delivery_date__c = dl.Delivery_date__c.addDays(1);
                    kundeMitKombiniertenLieferung = dl.contact__c;
                    firstkuwv = true;
                }
                else {
                    dl.Delivery_date__c = dl.Delivery_date__c.addMonths(1);
                }

            update dlList;
        }

        Set<id> ctSet = new Set<id>();
        List<Delivery_Line__c> dlnList = [SELECT Contact__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'Bedarf' AND Delivery_date__c <= TODAY ];
        for(Delivery_Line__c dl : dlnList) {
            ctSet.add(dl.Contact__c);
        }
        Test.startTest();
        delivery_xml dxml = new delivery_xml();
        dxml.processBedarf(ctSet);
        Test.stopTest();
        // wir ewarten 5 Delivery notes
        integer totalDN = 0;
        // davon 1 kombiniert
        integer kombDN = 0;
        List<Delivery_note__c> dnList = [SELECT id, Delivery_text__c, Delivery_date__c FROM Delivery_note__c];
        for(Delivery_note__c dn: dnList) {
            totalDN++;
            if(dn.Delivery_text__c.containsIgnoreCase('+ KUWV')) {
                kombDN++;
            }
            system.debug('####### ' + dn.Delivery_text__c + ' deldate: ' + dn.Delivery_date__c);   
        }            
        system.assertEquals(5, totalDN);
        system.assertEquals(1, kombDN);
    }

    static testMethod void TestLimitInfo() {
        Test.startTest();
        limitInfo.limitImage(limitInfo.getCurrentClassMethod());
        Test.stopTest();
        List<appLimitInformation__c> l = [SELECT id FROM appLimitInformation__c];
        system.assertEquals(1, l.size());


     }

     static testMethod void TestDeliveryBatch() {
        Test.startTest();
        ID batchprocessid = Database.executeBatch(new delivery(), 1);
        Test.stopTest();
     }

     static testMethod void TestDeliveryExecute() {
        List<contact> ctList = [SELECT id FROM contact WHERE id IN (SELECT Contact__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'Bedarf') ];
        Test.startTest();
        delivery dl = new delivery();
        dl.execute(null, ctList);
        Test.stopTest();
     }

    static testMethod void testInvalidData() {  
        // contact master data 
        create_test_product.createTestContacts(5);
        create_test_product.createGenehmigung();
        create_test_product.createOrders();
        create_test_product.createDeliverLinesBedarf();

        List<Contact_address__c> caList = [SELECT id, Contact__c, Street__c FROM contact_address__c LIMIT 2];
        caList[0].Street__c = null;
        id cnId = caList[1].Contact__c;
        update caList;

        List<Curabox_Genehmigungsposition__c> gpList = [SELECT id, genehmigt_bis__c FROM Curabox_Genehmigungsposition__c
                                                            WHERE Genehmigung__r.Contact__c = :cnid];
        gpList[0].genehmigt_bis__c = date.today();
        update gpList;

        Set<id> ctSet = new Set<id>();
        List<contact> ctList = [SELECT id FROM contact WHERE id IN (SELECT Contact__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'Bedarf') ];
        for(contact c : ctList) {
            ctSet.add(c.id);
        }

        Test.startTest();
        delivery_xml dxml = new delivery_xml();
        dxml.processBedarf(ctSet);
        Test.stopTest();
        if(dxml.getErrorListSize() > 0) {
            for(String rec : dxml.getErrorList()) {
                System.debug('####### Error:' + rec);
            }
        }

    }


}