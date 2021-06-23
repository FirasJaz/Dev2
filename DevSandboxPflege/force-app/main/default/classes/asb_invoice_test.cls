/****************************************************************************************************************************
// Erstellt 15.06.2019 von AM
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
// Beschreibung: test for asb_invoice.cls
//                      
//****************************************************************************************************************************     
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class asb_invoice_test {
    @testSetup static void dataForTest() {
        // custom settings
        CompanyInfo__c companyInfo = new CompanyInfo__c(name='Default', IK_Nummer__c='567894939', KDNR_bei_Lieferant__c='12345678', Telefon__c='040665656', Fax__c= '040 888');
        insert companyInfo;
        AB_KK__c abkk = new AB_KK__c(name='AB_KK_Einstellungen', Kundennummer__c=2, maNummerMedifox__c='2183', maNummerWebcare__c='2182', Abrechnungsfirma__c='AS Abrechnungsstelle für Heil-, Hilfs- und Pflegeberufe AG' );
        insert abkk;

        account asb = new account(name='AS Abrechnungsstelle für Heil-, Hilfs- und Pflegeberufe AG');
        insert asb;

        // products master data
        create_test_product.createProducts();
        // contact master data - Optional: (integer contactCount)
        create_test_product.createTestContacts(10);
        // Genehmigung
        create_test_product.createGenehmigung();
        // transaction data
        // orders+order lines 
        create_test_product.createOrders();   
        // delivery lines (Bedarf)
        create_test_product.createDeliverLinesBedarf();

        // Ausliefern
        Set<id> ctSet = new Set<id>();
        List<contact> ctList = [SELECT id FROM contact WHERE id IN (SELECT Contact__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'Bedarf') ];
        for(contact c : ctList) {
            ctSet.add(c.id);
        }
        delivery_xml dxml = new delivery_xml();
        dxml.processBedarf(ctSet);

    }

    static testMethod void testCreateInvoiceWebcare() {
        Set<id> dnSet = new Set<id>();
        integer medifox = 0;
        integer beihilfe = 0;
        integer gesetzlich = 0;
        integer privat = 0;
        List<Delivery_Line__c> dlList = [SELECT id, Abrechnungsstatus_Krankenkasse__c FROM Delivery_Line__c WHERE Delivery_Status__c != 'Bedarf'];
        for (Delivery_Line__c dl : dlList) {
            dl.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
        }
        update dlList;

        List<Delivery_Note__c> dnList = [SELECT id, Name, xml_send__c, xml_confirmed__c, pod_recieved__c,
                                                Contact__r.Beihilfeberechtigt__c, Contact__r.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c, Contact__r.Medifox_Kunde__c
                                                FROM Delivery_Note__c 
                                                WHERE Status__c = 'nicht abgerechnet'
                                                AND Contact__r.Medifox_Kunde__c = false
                                                ];
        system.debug('#################alex3000 dnList.size()=' + dnList.size());
        for(Delivery_Note__c dn: dnList) {
            dn.xml_send__c = true;
            dn.xml_confirmed__c = true;
            dn.pod_recieved__c = true;
            dnSet.add(dn.id);
            if(dn.Contact__r.Beihilfeberechtigt__c) beihilfe++;
            if(dn.Contact__r.Medifox_Kunde__c) medifox++;
            if(dn.Contact__r.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c == 'privat') {
                privat++;
            }
            else {
                gesetzlich++;
            }
        }
        // system.debug('#################alex3100 dnSet=' + dnSet);
        // List<Delivery_Line__c> dll1List = [SELECT id, Delivery_Note__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'geliefert'];
        // for(Delivery_Line__c dl : dll1List) {
        //     system.debug('#################alex3200 ' + dl.Delivery_Note__c );
        // }
        test.startTest();
            createInvoiceLines cil = new createInvoiceLines();
            cil.createLines(dnSet, false);

            cil.computeZuzahlung(2, 20, 'mindestens');
            cil.computeZuzahlung(2, 20, 'pro Artikel');
            cil.computeZuzahlung(2, 20, '10%');
            List<Invoice__c> ivL = [SELECT name FROM Invoice__c LIMIT 2];
            string param = '';
            for(Invoice__c i : ivL) {
               if(param == '') {
                   param = i.name;
               }
               else {
                   param += ', ' + i.name;
               }
            }
            cil.recreateCSV(param);
        test.stopTest();

        List<Invoice__c> ivList = [SELECT id, Name, Kostenstelle__c FROM Invoice__c];
        for(Invoice__c iv : ivList) {
            system.debug('##################alex330 iv=' + iv);
        }


        System.debug('#############alex3001 medifox='+medifox);
        System.debug('#############alex3001 beihilfe='+beihilfe);
        System.debug('#############alex3001 gesetzlich='+gesetzlich);
        System.debug('#############alex3001 privat='+privat);
        set<id> dnuset = new set<id>();
        List<Delivery_Line__c> dll1List = [SELECT id, name, Delivery_Note__c, CSV_Line__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'geliefert'];
        for(Delivery_Line__c dl : dll1List) {
            dnuSet.add(dl.Delivery_note__c);
            system.debug('#################alex3600 ' + dl.name + ' ' + dl.CSV_Line__c );
        }

        List<Delivery_Note__c> dnuList = [SELECT name, csv_block__c, Delivery_text__c FROM Delivery_Note__c WHERE id IN : dnuSet];
        for(Delivery_Note__c dn : dnuList) {
             system.debug('#################alex3601 ' + dn.name + ' ' + dn.Delivery_text__c + ' ' + dn.CSV_block__c );
        }

    }

   static testMethod void testCreateInvoiceMedifox() {
        Set<id> dnSet = new Set<id>();
        integer medifox = 0;
        integer beihilfe = 0;
        integer gesetzlich = 0;
        integer privat = 0;
        List<Delivery_Line__c> dlList = [SELECT id, Abrechnungsstatus_Krankenkasse__c FROM Delivery_Line__c WHERE Delivery_Status__c != 'Bedarf'];
        for (Delivery_Line__c dl : dlList) {
            dl.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
        }
        update dlList;
        List<Delivery_Note__c> dnList = [SELECT id, Name, xml_send__c, xml_confirmed__c, pod_recieved__c,
                                                Contact__r.Beihilfeberechtigt__c, Contact__r.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c, Contact__r.Medifox_Kunde__c
                                                FROM Delivery_Note__c 
                                                WHERE Status__c = 'nicht abgerechnet'
                                                AND Contact__r.Medifox_Kunde__c = true];
        system.debug('#################alex3000 dnList.size()=' + dnList.size());
        for(Delivery_Note__c dn: dnList) {
            dn.xml_send__c = true;
            dn.xml_confirmed__c = true;
            dn.pod_recieved__c = true;
            dnSet.add(dn.id);
            if(dn.Contact__r.Beihilfeberechtigt__c) beihilfe++;
            if(dn.Contact__r.Medifox_Kunde__c) medifox++;
            if(dn.Contact__r.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c == 'privat') {
                privat++;
            }
            else {
                gesetzlich++;
            }
        }
        // system.debug('#################alex3100 dnSet=' + dnSet);
        // List<Delivery_Line__c> dll1List = [SELECT id, Delivery_Note__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'geliefert'];
        // for(Delivery_Line__c dl : dll1List) {
        //     system.debug('#################alex3200 ' + dl.Delivery_Note__c );
        // }
        test.startTest();
            createInvoiceLines cil = new createInvoiceLines();
            cil.createLines(dnSet, true);
        //test.stopTest();

        List<Invoice__c> ivList = [SELECT id, Name, Kostenstelle__c FROM Invoice__c];
        for(Invoice__c iv : ivList) {
            system.debug('##################alex330 iv=' + iv);
            iv.asb_pdf_created__c = true;
        }

        //test.startTest();
            update ivList;
        test.stopTest();


        System.debug('#############alex3001 medifox='+medifox);
        System.debug('#############alex3001 beihilfe='+beihilfe);
        System.debug('#############alex3001 gesetzlich='+gesetzlich);
        System.debug('#############alex3001 privat='+privat);
        set<id> dnuset = new set<id>();
        List<Delivery_Line__c> dll1List = [SELECT id, name, Delivery_Note__c,  CSV_Line__c FROM Delivery_Line__c WHERE Delivery_Status__c = 'geliefert'];
        for(Delivery_Line__c dl : dll1List) {
            dnuSet.add(dl.Delivery_note__c);
            system.debug('#################alex3600 ' + dl.name + ' ' + dl.CSV_Line__c );
        }

        List<Delivery_Note__c> dnuList = [SELECT name, Delivery_text__c, csv_block__c FROM Delivery_Note__c WHERE id IN : dnuSet];
        for(Delivery_Note__c dn : dnuList) {
             system.debug('#################alex3601 ' + dn.name + ' ' + dn.Delivery_text__c + ' ' + dn.CSV_block__c );
        }



    }

    static testMethod void testCreateInvoiceRest() {

    }
    
}