/****************************************************************************************************************************
// Erstellt 07.01.2019 von AM
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
// Description: test for ASB_CSV
//              
//
//****************************************************************************************************************************
// Änderungen:   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest(seealldata=false)
private class ASB_CSV_test {
      @testSetup static void setup_data() {

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
            gnSet.add(sr.getId());
        }
        // Auftrag
        List<Auftrag__c> auList = new List<Auftrag__c>();
        Auftrag__c au1c = new Auftrag__c(Kunde__c = kdSet[0], Bezeichnung__c = 'CB1');
        auList.add(au1c);
        Auftrag__c au1k = new Auftrag__c(Kunde__c = kdSet[0], Bezeichnung__c = 'KUWV');
        auList.add(au1k);
        Auftrag__c au2c = new Auftrag__c(Kunde__c = kdSet[1], Bezeichnung__c = 'CB1');
        auList.add(au2c);
        Auftrag__c au2k = new Auftrag__c(Kunde__c = kdSet[1], Bezeichnung__c = 'KUWV');
        auList.add(au2k);
        Auftrag__c au3c = new Auftrag__c(Kunde__c = kdSet[2], Bezeichnung__c = 'CB1');
        auList.add(au3c);
        Auftrag__c au3k = new Auftrag__c(Kunde__c = kdSet[2], Bezeichnung__c = 'KUWV');
        auList.add(au3k);
        Auftrag__c au4c = new Auftrag__c(Kunde__c = kdSet[3], Bezeichnung__c = 'CB1');
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
        Artikel__c ar1 = new Artikel__c(name = 'a1', Anlage_4_Preis__c = 10.0, Pflege_Hilfsmittelnr__c = '5400001', v_pos_1_Name__c='54', a_pac_apo_Mwst__c='1');
        arList.add(ar1);
        Artikel__c ar2 = new Artikel__c(name = 'a2', Anlage_4_Preis__c = 10.0, Pflege_Hilfsmittelnr__c = '5400002', v_pos_1_Name__c='54', a_pac_apo_Mwst__c='1');
        arList.add(ar2);
        Artikel__c ar3 = new Artikel__c(name = 'a3', Anlage_4_Preis__c = 10.0, Pflege_Hilfsmittelnr__c = '5400003', v_pos_1_Name__c='54', a_pac_apo_Mwst__c='1');
        arList.add(ar3);
        Artikel__c ar4 = new Artikel__c(name = 'KUWV', Anlage_4_Preis__c = 20.0, Pflege_Hilfsmittelnr__c = '5100001', v_pos_1_Name__c='51', a_pac_apo_Mwst__c='1');
        arList.add(ar4);
        List<id> arSet = new List<id>();
        srList = Database.insert(arList, false); 
        for (Database.SaveResult sr : srList) {
            arSet.add(sr.getId());
        }        

        List<Auftragsposition__c> apList = new List<Auftragsposition__c>();
        Auftragsposition__c ap11 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[0], Artikel__c = arSet[0]);
        apList.add(ap11);
        Auftragsposition__c ap12 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[0], Artikel__c = arSet[1]);
        apList.add(ap12);
        Auftragsposition__c ap13 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[0], Artikel__c = arSet[2]);
        apList.add(ap13);
        Auftragsposition__c ap14 = new Auftragsposition__c(Kunde__c = kdSet[0], Auftrag__c = auSet[1], Artikel__c = arSet[3]);
        apList.add(ap14);
        
        Auftragsposition__c ap21 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[2], Artikel__c = arSet[0]);
        apList.add(ap21);
        Auftragsposition__c ap22 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[2], Artikel__c = arSet[1]);
        apList.add(ap22);
        Auftragsposition__c ap23 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[2], Artikel__c = arSet[2]);
        apList.add(ap23);
        Auftragsposition__c ap24 = new Auftragsposition__c(Kunde__c = kdSet[1], Auftrag__c = auSet[3], Artikel__c = arSet[3]);
        apList.add(ap24);

        Auftragsposition__c ap31 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[4], Artikel__c = arSet[0]);
        apList.add(ap31);
        Auftragsposition__c ap32 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[4], Artikel__c = arSet[1]);
        apList.add(ap32);
        Auftragsposition__c ap33 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[4], Artikel__c = arSet[2]);
        apList.add(ap33);
        Auftragsposition__c ap34 = new Auftragsposition__c(Kunde__c = kdSet[2], Auftrag__c = auSet[5], Artikel__c = arSet[3]);
        apList.add(ap34);

        Auftragsposition__c ap41 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[6], Artikel__c = arSet[0]);
        apList.add(ap41);
        Auftragsposition__c ap42 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[6], Artikel__c = arSet[1]);
        apList.add(ap42);
        Auftragsposition__c ap43 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[6], Artikel__c = arSet[2]);
        apList.add(ap43);
        Auftragsposition__c ap44 = new Auftragsposition__c(Kunde__c = kdSet[3], Auftrag__c = auSet[7], Artikel__c = arSet[3]);
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

        // Liefescheine 
        List<Lieferschein__c> lsList = new List<Lieferschein__c>();
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[0], Genehmigung__c = gnSet[0], Lieferanschrift__c = anMap.get(kdSet[0]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '54', Liefertext__c='CB1'));
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[0], Genehmigung__c = gnSet[1], Lieferanschrift__c = anMap.get(kdSet[0]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '51', Liefertext__c='KUWV'));
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[1], Genehmigung__c = gnSet[2], Lieferanschrift__c = anMap.get(kdSet[1]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '54', Liefertext__c='CB1'));
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[1], Genehmigung__c = gnSet[3], Lieferanschrift__c = anMap.get(kdSet[1]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '51', Liefertext__c='KUWV'));
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[2], Genehmigung__c = gnSet[4], Lieferanschrift__c = anMap.get(kdSet[2]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '54', Liefertext__c='CB1'));
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[2], Genehmigung__c = gnSet[5], Lieferanschrift__c = anMap.get(kdSet[2]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '51', Liefertext__c='KUWV'));       
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[3], Genehmigung__c = gnSet[6], Lieferanschrift__c = anMap.get(kdSet[3]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '54', Liefertext__c='CB1'));
        lsList.add(new Lieferschein__c(Kunde__c = kdSet[3], Genehmigung__c = gnSet[7], Lieferanschrift__c = anMap.get(kdSet[3]).id, Lieferdatum__c = date.today(), Lieferschein_text__c = '51', Liefertext__c='KUWV'));
        
        List<id> lsSet = new List<id>();
        srList = Database.insert(lsList, false); 
        for (Database.SaveResult sr : srList) {
            lsSet.add(sr.getId());
        }  
        List<Lieferschein__c> lsnList = [SELECT id, Kunde__c, Liefertext__c FROM Lieferschein__c];
        
        List<attachment> atList = new List<attachment>();
        map<id, Lieferschein__c> lsMap54 = new map<id, Lieferschein__c>();
        map<id, Lieferschein__c> lsMap51 = new map<id, Lieferschein__c>();
        for(Lieferschein__c ls : lsnList) {
            if(ls.Liefertext__c == 'KUWV') {
                lsMap51.put(ls.Kunde__c, ls);
            }
            else {
                lsMap54.put(ls.Kunde__c, ls);
            }
            
            attachment at = new attachment(ParentId = ls.id);
            at.name = 'ABLIEFERBELEG.XML';
            string  csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

            at = new attachment(ParentId = ls.id);
            at.name = 'Ablieferbeleg_zuLS.PDF';
            csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

            at = new attachment(ParentId = ls.Kunde__c);
            at.name = 'Genehmigung_PG51.PDF';
            csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

            at = new attachment(ParentId = ls.Kunde__c);
            at.name = 'Genehmigung_PG54.PDF';
            csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

            at = new attachment(ParentId = ls.Kunde__c);
            at.name = 'Antrag_PG51.PDF';
            csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

            at = new attachment(ParentId = ls.Kunde__c);
            at.name = 'Antrag_PG54.PDF';
            csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

            at = new attachment(ParentId = gnSet[0]);
            at.name = 'Genehmigung_PG54.PDF';
            csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

            at = new attachment(ParentId = gnSet[1]);
            at.name = 'Genehmigung_PG51.PDF';
            csv = 'test';
            at.body = blob.valueOf(csv);
            atList.add(at);

        }

        


        // Liferscheinposition
        List<Lieferscheinposition__c> lpList = new List<Lieferscheinposition__c>();
        List<Auftragsposition__c> apnList = [SELECT id, Kunde__c, Artikel__c, Auftrag__r.Bezeichnung__c FROM Auftragsposition__c];
        for(Auftragsposition__c ap : apnList) {
            Lieferscheinposition__c lpp = new Lieferscheinposition__c(Kunde__c = ap.Kunde__c, Artikel__c=ap.Artikel__c, Auftragsposition__c=ap.id,  Abrechnungsstatus_Krankenkasse__c = 'abgerechnet', VZ_von__c = date.today().addMonths(-1), VZ_bis__c = date.today(), Menge__c =1, Lieferdatum__c=date.today());
            if(ap.Auftrag__r.Bezeichnung__c == 'KUWV') {
                lpp.Lieferschein__c=lsMap51.get(ap.Kunde__c).id;
            }
            else {
                lpp.Lieferschein__c=lsMap54.get(ap.Kunde__c).id;
            }
            lpList.add(lpp);
        }       
        srList = Database.insert(lpList, false); 

        // Rechnungen
        List<Rechnung__c> rgList = new List<Rechnung__c>();
        rgList.add(new Rechnung__c(Kunde__c = kd0.id, BUCHUNGSTEXT__C='St', Rechnung_text__c='54'));
        rgList.add(new Rechnung__c(Kunde__c = kd0.id, BUCHUNGSTEXT__C='St', Rechnung_text__c='KUWV'));
        rgList.add(new Rechnung__c(Kunde__c = kd0.id, BUCHUNGSTEXT__C='Medifox', Rechnung_text__c='54'));
        rgList.add(new Rechnung__c(Kunde__c = kd0.id, BUCHUNGSTEXT__C='Medifox', Rechnung_text__c='KUWV'));
        srList = Database.insert(rgList, false); 
        Map<String, Rechnung__c> rgMap = new Map<String, Rechnung__c>(); 
        rgList = [SELECT id, name, BUCHUNGSTEXT__C, Rechnung_text__c FROM Rechnung__c];
        for(Rechnung__c rg : rgList) {
            rgMap.put(rg.BUCHUNGSTEXT__C + rg.Rechnung_text__c, rg);
        }

        // Rechnungspositionen // LBs
        Map<id, Lieferbest_tigung__c> lbMap = new Map<id, Lieferbest_tigung__c>();
        List<Rechnungsposition__c> rpList = new List<Rechnungsposition__c>();
        lpList = [SELECT id, Lieferschein__c, Lieferschein__r.Lieferschein_text__c, Kunde__c, Kunde__r.Medifox_2__c FROM Lieferscheinposition__c];
        for(Lieferscheinposition__c lp : lpList) {
            Rechnungsposition__c rp = new Rechnungsposition__c(Kunde__c = lp.Kunde__c, Lieferscheinposition__c = lp.id);
            rp.Gesamtpreis_Brutto__c = 20.00;
            rp.gesetzliche_Zuzahlung__c = 2.00;
            if((lp.Lieferschein__r.Lieferschein_text__c == '51') && (lp.Kunde__r.Medifox_2__c)) {
                rp.Rechnung__c = rgMap.get('MedifoxKUWV').id;
                if(!lbMap.containsKey(lp.Lieferschein__c)) {
                    lbMap.put(lp.Lieferschein__c, new Lieferbest_tigung__c(Kunde__c =lp.Kunde__c, Lieferschein__c=lp.Lieferschein__c, Rechnung__c = rgMap.get('MedifoxKUWV').id, Rechnungsname__c = rgMap.get('MedifoxKUWV').name));
                }
            } 
            if((lp.Lieferschein__r.Lieferschein_text__c == '54') && (lp.Kunde__r.Medifox_2__c)) {
                rp.Rechnung__c = rgMap.get('Medifox54').id;
                if(!lbMap.containsKey(lp.Lieferschein__c)) {
                    system.debug('##### alex_test ' + rgMap.get('Medifox54').name);
                    lbMap.put(lp.Lieferschein__c, new Lieferbest_tigung__c(Kunde__c =lp.Kunde__c, Lieferschein__c=lp.Lieferschein__c, Rechnung__c = rgMap.get('Medifox54').id, Rechnungsname__c = rgMap.get('Medifox54').name));
                }
            } 
            if((lp.Lieferschein__r.Lieferschein_text__c == '51') && (!lp.Kunde__r.Medifox_2__c)) {
                rp.Rechnung__c = rgMap.get('StKUWV').id;
                if(!lbMap.containsKey(lp.Lieferschein__c)) {
                    lbMap.put(lp.Lieferschein__c, new Lieferbest_tigung__c(Kunde__c =lp.Kunde__c, Lieferschein__c=lp.Lieferschein__c, Rechnung__c = rgMap.get('StKUWV').id, Rechnungsname__c = rgMap.get('StKUWV').name));
                }
            } 
            if((lp.Lieferschein__r.Lieferschein_text__c == '54') && (!lp.Kunde__r.Medifox_2__c)) {
                rp.Rechnung__c = rgMap.get('St54').id;
                if(!lbMap.containsKey(lp.Lieferschein__c)) {
                    lbMap.put(lp.Lieferschein__c, new Lieferbest_tigung__c(Kunde__c =lp.Kunde__c, Lieferschein__c=lp.Lieferschein__c, Rechnung__c = rgMap.get('St54').id, Rechnungsname__c = rgMap.get('St54').name));
                }
            } 
            rpList.add(rp);

        }
        srList = Database.insert(rpList, false); 
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {

            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('RP. fields that affected this error: ' + err.getFields());
                    System.debug('##### alex_error ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        }     
        set<id> lbSet = new set<id>();   
        srList = Database.insert(lbMap.values(), false); 
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                lbSet.add(sr.getId());
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('RP. fields that affected this error: ' + err.getFields());
                    System.debug('##### alex_error ' + err.getStatusCode() + ': ' + err.getMessage());
                }
            }
        } 

        srList = Database.insert(atList, false); 
    }

    static testMethod void testCreateAndSendMedifox() { 


        List<Lieferbest_tigung__c> lbList = [SELECT Lieferschein__c, Rechnung__r.name, Rechnungsname__c FROM Lieferbest_tigung__c];
        for(Lieferbest_tigung__c lb : lbList) {
            system.debug('############# alex_test' + lb.Rechnung__r.name + ' ### ' + lb.Rechnungsname__c + ' ### ' + lb.Lieferschein__c);
        } 



        List<Rechnung__c> rgList = [SELECT name, Rechnung_text__c, BUCHUNGSTEXT__C FROM Rechnung__c];
        String parammf = '';
        String paramst = '';
        set<string> testset = new set<string>();
        string  csv = 'v2.0.0.3 / id:6232 / 09.11.2018 06:00:12 / start hidden\r\n';
        for(Rechnung__c rg : rgList) {
            testset.add(rg.name);
            if(rg.BUCHUNGSTEXT__C == 'Medifox') {
                csv += 'v2.0.0.3 / id:6764 / 09.11.2018 11:10:26 / Rechnung ' + rg.name + ' gelesen\r\n';
                csv += 'v2.0.0.3 / id:6764 / 09.11.2018 11:10:26 / 1217 Rechnugspositionen erstellt\r\n';
            }
            else {
                csv += 'v2.0.0.3 / id:6765 / 09.11.2018 11:10:26 / Rechnung ' + rg.name + ' gelesen\r\n';
                csv += 'v2.0.0.3 / id:6765 / 09.11.2018 11:10:26 / 1217 Rechnugspositionen erstellt\r\n';                
            }

            if(rg.Rechnung_text__c == 'KUWV') {               
                if(parammf == '') {
                    parammf = '\'' + rg.name + '\'';
                }
                else {
                    parammf += ', \'' + rg.name + '\'';
                }
            }
            else {
                if(paramst == '') {
                    paramst = '\'' + rg.name + '\'';
                }
                else {
                    paramst += ', \'' + rg.name + '\'';
                }
            }
        }
        system.debug('############## alex_test' + paramst);
        system.debug('############## alex_test' + parammf);

        Test.startTest();
        // ksgloader_joblog (trigger after insert attachment)
        ksgLoader__c ksgl = new ksgLoader__c(start__c=DateTime.now());
        insert ksgl;
        attachment atj = new attachment(ParentId = ksgl.id);
        atj.name = 'joblog.txt';
        csv += 'v2.0.0.3 / id:2052 / 09.11.2018 18:53:33 / Ende\r\n';
        atj.body = blob.valueOf(csv);
        insert atj;
        // ASB_CSV.createCsvFromInvoice(parammf, false);
        // ASB_CSV.createCsvFromInvoice(parammf, true);
        // ASB_CSV.createCsvFromInvoice(paramst, false);
        // ASB_CSV.createCsvFromInvoice(paramst, true);
        Test.stopTest();   
    }

}