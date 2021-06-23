/****************************************************************************************************************************
// Erstellt 02.01.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: none
//
//****************************************************************************************************************************
//
// Description: test for LS_XML_generieren_batch
//              
//
//****************************************************************************************************************************
// Änderungen:   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
private class LS_XML_generieren_batch_test {


   @testSetup static void setup_data() {

        CompanyInfo__c cu = new CompanyInfo__c(name='Default', KDNR_bei_Lieferant__c='0999', Telefon__c='123', Fax__c='123' );
        insert cu;   
        // Pflegekassen
        Account KK1 = new Account(name='test1', Industry = 'Krankenkassen', type = 'Test');
        KK1.IK_Nummer__c = '12345678';
        KK1.Kanal_Unterpunkt__c = 'gesetzlich';
        KK1.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
        KK1.Hilfsmittel_Kennzeichen__c = 'HM';     
        KK1.AC__c = 'AC';
        KK1.TK__c = 'TK';   
        KK1.Medifox_Ausschluss__c = true;
        insert KK1;

        Account KK2 = new Account(name='test2', Industry = 'Krankenkassen', type = 'Test');
        KK2.IK_Nummer__c = '23456789';
        KK2.Kanal_Unterpunkt__c = 'gesetzlich';
        KK2.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
        KK2.Hilfsmittel_Kennzeichen__c = 'HM';      
        KK2.AC__c = 'AC';
        KK2.TK__c = 'TK';  
        KK2.Abrechnung_HM_Positionsnummer__c = '54000000';
        insert KK2;

        Account KK3 = new Account(name='test3', Industry = 'Krankenkassen', type = 'Test');
        KK3.IK_Nummer__c = '34567812';
        KK3.Kanal_Unterpunkt__c = 'gesetzlich';
        KK3.PG51_Abrechnungs_Methode__c = '10% Zuzahlung, mindestens 5,- € pro Artikel';
        KK3.Hilfsmittel_Kennzeichen__c = 'HM';     
        KK3.AC__c = 'AC';
        KK3.TK__c = 'TK';   
        insert KK3;

        Account KK4 = new Account(name='private', Industry = 'Krankenkassen', type = 'Test');
        KK4.IK_Nummer__c = '45678123';
        KK4.Kanal_Unterpunkt__c = 'privat';
        KK4.PG51_Abrechnungs_Methode__c = '10% Zuzahlung, mindestens 5,- € pro Artikel';
        KK4.Hilfsmittel_Kennzeichen__c = 'HM';     
        KK4.AC__c = 'AC';
        KK4.TK__c = 'TK';   
        insert KK4;

        Kunde__c kd0 = new Kunde__c(
                            Name__c = 'AS Abrechnungsstelle für Heil-', Vorname__c = 'Hilfs- und Pflegeberufe AG',                       
                            Ort__c = 'Bremen', PLZ__c = 29195, Stra_e__c = 'Am Wall 96 - 98', Produktgruppe__c = 'Abrechnungsstelle');
        insert kd0;
        Kunde__c abb = [SELECT name FROM Kunde__c WHERE id = : kd0.id];
        
        // Custom settings
        AB_KK__c cs = new AB_KK__c(name= 'AB_KK_Einstellungen', Abrechnungsfirma__c = abb.name);
        cs.Kundennummer__c = 2;
        cs.maNummerMedifox__c = '4001';
        cs.maNummerWebcare__c = '4002';
        insert cs;
        
        // Kunden
        List<Kunde__c> kdList = new List<Kunde__c>();
        Kunde__c kd1 = new Kunde__c(Krankenkasse__c = kk1.id, 
                            Name__c = 'TestKunde1', Vorname__c = 'Max', Anrede__c = 'Herr', Geburtsdatum_text__c = '10.10.2010',
                            Beihilfeberechtigt__c = false,                            
                            Ort__c = 'Hamburg', PLZ__c = 20000, Stra_e__c = 'Reeperbahn',
                            Produktgruppe__c = 'PG51, PG54');
        kdList.add(kd1);

        Kunde__c kd2 = new Kunde__c(Krankenkasse__c = kk2.id, 
                            Name__c = 'TestKunde2', Vorname__c = 'Max', Anrede__c = 'Herr', Geburtsdatum_text__c = '10.10.2010',
                            Beihilfeberechtigt__c = false,                            
                            Ort__c = 'Hamburg', PLZ__c = 20000, Stra_e__c = 'Reeperbahn',
                            Produktgruppe__c = 'PG51, PG54');
        kdList.add(kd2);  

        Kunde__c kd3 = new Kunde__c(Krankenkasse__c = kk3.id, 
                            Name__c = 'TestKunde3', Vorname__c = 'Max', Anrede__c = 'Herr', Geburtsdatum_text__c = '10.10.2010',
                            Beihilfeberechtigt__c = false,                             
                            Ort__c = 'Hamburg', PLZ__c = 20000, Stra_e__c = 'Reeperbahn',
                            Produktgruppe__c = 'PG51, PG54');
        kdList.add(kd3);   

        Kunde__c kd4 = new Kunde__c(Krankenkasse__c = kk4.id, 
                            Name__c = 'TestKunde4', Vorname__c = 'Max', Anrede__c = 'Herr', Geburtsdatum_text__c = '10.10.2010',
                            Beihilfeberechtigt__c = false,                            
                            Ort__c = 'Hamburg', PLZ__c = 20000, Stra_e__c = 'Reeperbahn',
                            Produktgruppe__c = 'PG51, PG54');
        kdList.add(kd4);    
        List<id> kdSet = new List<id>();
        Database.SaveResult[] srList = Database.insert(kdList, false); 
        for (Database.SaveResult sr : srList) {
            kdSet.add(sr.getId());
        }


        List<Kundenstatus__c> ksList = [SELECT id, Status__c FROM Kundenstatus__c] ;
        for(Kundenstatus__c ks : ksList) {
            ks.Status__c = 'Kunde';
        } 
        update ksList;

        // Genehmigung
        List<Genehmigung__c>gnList =new List<Genehmigung__c>();
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[0], Name__c = 'PG54', Nach_Paragraph__c = '54', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[0], Name__c = 'PG51', Nach_Paragraph__c = '51', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[1], Name__c = 'PG54', Nach_Paragraph__c = '54', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[1], Name__c = 'PG51', Nach_Paragraph__c = '51', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true));
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[2], Name__c = 'PG54', Nach_Paragraph__c = '54', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[2], Name__c = 'PG51', Nach_Paragraph__c = '51', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true));  
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[3], Name__c = 'PG54', Nach_Paragraph__c = '54', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        gnList.add(new Genehmigung__c(Kunde__c = kdSet[3], Name__c = 'PG51', Nach_Paragraph__c = '54', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        List<id> gnSet = new List<id>();
        srList = Database.insert(gnList, false); 
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                gnSet.add(sr.getId());
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Gen. fields that affected this error: ' + err.getFields());
                    System.debug('##### alex_error ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }
        // Auftrag
        List<Auftrag__c> auList = new List<Auftrag__c>();
        Auftrag__c au1c = new Auftrag__c(Kunde__c = kdSet[0], Bezeichnung__c = 'CB1');
        auList.add(au1c);
        Auftrag__c au1k = new Auftrag__c(Kunde__c = kdSet[0], Bezeichnung__c = 'KUWV');
        auList.add(au1k);
        Auftrag__c au2c = new Auftrag__c(Kunde__c = kdSet[1], Bezeichnung__c = 'CB2');
        auList.add(au2c);
        Auftrag__c au2k = new Auftrag__c(Kunde__c = kdSet[1], Bezeichnung__c = 'KUWV');
        auList.add(au2k);
        Auftrag__c au3c = new Auftrag__c(Kunde__c = kdSet[2], Bezeichnung__c = 'CB3');
        auList.add(au3c);
        Auftrag__c au3k = new Auftrag__c(Kunde__c = kdSet[2], Bezeichnung__c = 'KUWV');
        auList.add(au3k);
        Auftrag__c au4c = new Auftrag__c(Kunde__c = kdSet[3], Bezeichnung__c = 'CB4');
        auList.add(au4c);
        Auftrag__c au4k = new Auftrag__c(Kunde__c = kdSet[3], Bezeichnung__c = 'KUWV');
        auList.add(au4k);
        List<id> auSet = new List<id>();
        srList = Database.insert(auList, false); 
        for (Database.SaveResult sr : srList) {
            auSet.add(sr.getId());
        }
        // Artikel
        List<Artikel__c> arList = new List<Artikel__c>();
        Artikel__c ar1 = new Artikel__c(name = 'a1', Anlage_4_Preis__c = 10.0, Pflege_Hilfsmittelnr__c = '5400001', v_pos_1_Name__c='54');
        arList.add(ar1);
        Artikel__c ar2 = new Artikel__c(name = 'a2', Anlage_4_Preis__c = 10.0, Pflege_Hilfsmittelnr__c = '5400002', v_pos_1_Name__c='54');
        arList.add(ar2);
        Artikel__c ar3 = new Artikel__c(name = 'a3', Anlage_4_Preis__c = 10.0, Pflege_Hilfsmittelnr__c = '5400003', v_pos_1_Name__c='54');
        arList.add(ar3);
        Artikel__c ar4 = new Artikel__c(name = 'KUWV', Anlage_4_Preis__c = 20.0, Pflege_Hilfsmittelnr__c = '5100001', v_pos_1_Name__c='51');
        arList.add(ar4);
        List<id> arSet = new List<id>();
        srList = Database.insert(arList, false); 
        for (Database.SaveResult sr : srList) {
            arSet.add(sr.getId());
        }        

        List<Auftragsposition__c> apList = new List<Auftragsposition__c>();
        Auftragsposition__c ap11 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[0], Artikel__c = arSet[0], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap11);
        Auftragsposition__c ap12 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[0], Artikel__c = arSet[1], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap12);
        Auftragsposition__c ap13 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[0], Artikel__c = arSet[2], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap13);
        Auftragsposition__c ap14 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[1], Artikel__c = arSet[3], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'jährlich');
        apList.add(ap14);
        
        Auftragsposition__c ap21 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[2], Artikel__c = arSet[0], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap21);
        Auftragsposition__c ap22 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[2], Artikel__c = arSet[1], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap22);
        Auftragsposition__c ap23 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[2], Artikel__c = arSet[2], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap23);
        Auftragsposition__c ap24 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[3], Artikel__c = arSet[3], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'jährlich');
        apList.add(ap24);

        Auftragsposition__c ap31 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[4], Artikel__c = arSet[0], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap31);
        Auftragsposition__c ap32 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[4], Artikel__c = arSet[1], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap32);
        Auftragsposition__c ap33 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[4], Artikel__c = arSet[2], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap33);
        Auftragsposition__c ap34 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[5], Artikel__c = arSet[3], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'jährlich');
        apList.add(ap34);

        Auftragsposition__c ap41 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[6], Artikel__c = arSet[0], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap41);
        Auftragsposition__c ap42 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[6], Artikel__c = arSet[1], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap42);
        Auftragsposition__c ap43 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[6], Artikel__c = arSet[2], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apList.add(ap43);
        Auftragsposition__c ap44 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[7], Artikel__c = arSet[3], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'halbjährlich');
        apList.add(ap44);
        List<id> apSet = new List<id>();
        srList = Database.insert(apList, false); 
        for (Database.SaveResult sr : srList) {
            apSet.add(sr.getId());
        }  

        List<Anschrift__c> anList = [SELECT id, Kunde__c, Stra_e__c, Ort__c, PLZ__c FROM Anschrift__c];
        Map<id, Anschrift__c> anMap = new map<id, Anschrift__c>();
        for(Anschrift__c an : anList) {
            anMap.put(an.Kunde__c, an);
        } 

        // Liferscheinposition
        List<Lieferscheinposition__c> lpList = new List<Lieferscheinposition__c>();
        List<Auftragsposition__c> apnList = [SELECT id, Kunde__c, Artikel__c, Auftrag__r.Bezeichnung__c FROM Auftragsposition__c];
        for(Auftragsposition__c ap : apnList) {
            Lieferscheinposition__c lpp = new Lieferscheinposition__c(Kunde__c = ap.Kunde__c, Artikel__c=ap.Artikel__c, Auftragsposition__c=ap.id, Status__c = 'Bedarf',  Abrechnungsstatus_Krankenkasse__c = 'nicht abechenbar', VZ_von__c = date.today(), VZ_bis__c = date.today().addMonths(1), Menge__c =1, Lieferdatum__c=date.today());
            lpList.add(lpp);
        }       
        srList = Database.insert(lpList, false); 

        // jetzt liefern
        List<Auftrag__c> aujList = new List<Auftrag__c>();
        Auftrag__c au1cj = new Auftrag__c(Kunde__c = kdSet[0], Bezeichnung__c = 'CB1');
        aujList.add(au1cj);
        Auftrag__c au1kj = new Auftrag__c(Kunde__c = kdSet[0], Bezeichnung__c = 'KUWV');
        aujList.add(au1kj);
        List<id> aujSet = new List<id>();
        srList = Database.insert(aujList, false); 
        for (Database.SaveResult sr : srList) {
            aujSet.add(sr.getId());
        }
        List<Auftragsposition__c> apjList = new List<Auftragsposition__c>();
        Auftragsposition__c ap11j = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = aujSet[0], Artikel__c = arSet[0], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apjList.add(ap11j);
        Auftragsposition__c ap12j = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = aujSet[0], Artikel__c = arSet[1], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apjList.add(ap12j);
        Auftragsposition__c ap13j = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = aujSet[0], Artikel__c = arSet[2], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'monatlich');
        apjList.add(ap13j);
        Auftragsposition__c ap14j = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = aujSet[1], Artikel__c = arSet[3], genehmigt_bis__c=date.today().addYears(20), Lieferzeitraum__c = 'jährlich');
        apjList.add(ap14j);
        List<id> apjSet = new List<id>();
        srList = Database.insert(apjList, false); 
        for (Database.SaveResult sr : srList) {
            apjSet.add(sr.getId());
        } 
        // Liefescheine 
        List<Lieferschein__c> lsList = new List<Lieferschein__c>();
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[0], Genehmigung__c = gnSet[0], Lieferanschrift__c = anMap.get(kdSet[0]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '54', Liefertext__c='CB1'));
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[1], Genehmigung__c = gnSet[3], Lieferanschrift__c = anMap.get(kdSet[1]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '51', Liefertext__c='KUWV'));        
        List<id> lsSet = new List<id>();
        srList = Database.insert(lsList, false); 
        for (Database.SaveResult sr : srList) {
            lsSet.add(sr.getId());
        } 
        List<Lieferscheinposition__c> lpjList = new List<Lieferscheinposition__c>();
        lpjList.add(new Lieferscheinposition__c(Kunde__c = kdSet[0], Artikel__c = arSet[0], Auftragsposition__c=apjSet[0], Lieferschein__c=lsSet[0], VZ_von__c = date.today(), Menge__c =1, Lieferdatum__c=date.today(), Status__c='jetzt liefern'));
        lpjList.add(new Lieferscheinposition__c(Kunde__c = kdSet[0], Artikel__c = arSet[1], Auftragsposition__c=apjSet[1], Lieferschein__c=lsSet[0], VZ_von__c = date.today(), Menge__c =1, Lieferdatum__c=date.today(), Status__c='jetzt liefern'));
        lpjList.add(new Lieferscheinposition__c(Kunde__c = kdSet[0], Artikel__c = arSet[2], Auftragsposition__c=apjSet[2], Lieferschein__c=lsSet[0], VZ_von__c = date.today(), Menge__c =1, Lieferdatum__c=date.today(), Status__c='jetzt liefern'));
        lpjList.add(new Lieferscheinposition__c(Kunde__c = kdSet[1], Artikel__c = arSet[3], Auftragsposition__c=apjSet[3], Lieferschein__c=lsSet[1], VZ_von__c = date.today(), Menge__c =1, Lieferdatum__c=date.today(), Status__c='jetzt liefern'));
        srList = Database.insert(lpjList, false); 
 
    }

    static testMethod void createLS_bedarf() {
        list<Kunde__c> kdList = [SELECT id FROM Kunde__c];
        Set<id> kdset = new Set<id>();
        for(Kunde__c kd : kdList) {
            kdset.add(kd.id);
        }
        Test.startTest();
        LS_XML_generieren_batch lb = new LS_XML_generieren_batch();
        lb.createLS_bedarf(kdset);
        Test.stopTest();  

        List<Lieferschein__c> lsList = [SELECT id, Liefertext__c, Lieferschein_text__c FROM Lieferschein__c];
        System.assertEquals(10, lsList.size());

        list<attachment> xmlAtt = [SELECT id, name FROM attachment WHERE name LIKE '%.XML'];
        System.assertEquals(8, xmlAtt.size());

        list<Lieferscheinposition__c> pList = [SELECT id, Lieferdatum__c, Artikel__r.Name FROM Lieferscheinposition__c WHERE Status__c = 'Bedarf'];
        System.assertEquals(16, pList.size());
    }

    static testMethod void LS_XML_Test_dummy() {
        LS_XML_generieren_batch lb = new LS_XML_generieren_batch();
        lb.createLS_bedarf() ;
        lb.setLeereZeilen();
        lb.getErrorList();
        lb.getErrorListSize();
        List<Lieferschein__c> LSList = [SELECT id FROM Lieferschein__c LIMIT 1];
        lb.readDirect(LSList[0].id);
    }

    static testMethod void LS_XML_Test_jetzt_liefern() {
        Test.startTest();
        LS_XML_generieren_batch lb = new LS_XML_generieren_batch();
        lb.createLS_jetzt_liefern();
        Test.stopTest();  
    }

    static testMethod void lieferungen_test() {
        ID bid = Database.executeBatch(new Lieferungen());
    }
}