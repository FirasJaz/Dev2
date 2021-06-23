/****************************************************************************************************************************
// Erstellt 08.01.2019 von AM
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
// Description: test for after_insert_attachment.trigger
//              
//
//****************************************************************************************************************************
// Änderungen:   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest(seealldata=false)
private class after_insert_attachment_test {
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

        Kunde__c kd1 = new Kunde__c(Krankenkasse__c = kk1.id, 
                            Name__c = 'TestKunde1', Vorname__c = 'Max', Anrede__c = 'Herr', Geburtsdatum_text__c = '10.10.2010',
                            Beihilfeberechtigt__c = false,                            
                            Ort__c = 'Hamburg', PLZ__c = 20000, Stra_e__c = 'Reeperbahn',
                            Produktgruppe__c = 'PG51, PG54');
        insert kd1;

        List<Kundenstatus__c> ksList = [SELECT id, Status__c FROM Kundenstatus__c WHERE Kunde__c = :kd1.id] ;
        for(Kundenstatus__c ks : ksList) {
            ks.Status__c = 'Kandidat';
        } 
        update ksList;

        ksgLoader__c ksgl = new ksgLoader__c(start__c=DateTime.now());
        insert ksgl;

        // Genehmigung
        List<Genehmigung__c>gnList =new List<Genehmigung__c>();
        gnList.add(new Genehmigung__c(Kunde__c = kd1.id, Name__c = 'PG54', Nach_Paragraph__c = '54', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        gnList.add(new Genehmigung__c(Kunde__c = kd1.id, Name__c = 'PG51', Nach_Paragraph__c = '51', Status__c = 'Bewilligung', genehmigt_ab__c = date.today().addMonths(-1), Antrag_beantwortet_am__c = date.today(), unbefristet_genehmigt__c = true)); 
        List<id> gnSet = new List<id>();
        Database.SaveResult[]  srList = Database.insert(gnList, false); 
        for (Database.SaveResult sr : srList) {
            gnSet.add(sr.getId());
        }

        // Liefescheine 
        List<Lieferschein__c> lsList = new List<Lieferschein__c>();
        lsList.add(new Lieferschein__c(Kunde__c = kd1.id, Genehmigung__c = gnSet[0], Lieferdatum__c = date.today(), Lieferschein_text__c = '54', Liefertext__c='CB1'));
        lsList.add(new Lieferschein__c(Kunde__c = kd1.id, Genehmigung__c = gnSet[1], Lieferdatum__c = date.today(), Lieferschein_text__c = '51', Liefertext__c='KUWV'));
        List<id> lsSet = new List<id>();
        srList = Database.insert(lsList, false); 
        for (Database.SaveResult sr : srList) {
            lsSet.add(sr.getId());
        }  

        Lieferbest_tigung__c lb1 = new Lieferbest_tigung__c(Kunde__c =kd1.id, Lieferschein__c=lsSet[0]);
        insert lb1;
        Lieferbest_tigung__c lb2 = new Lieferbest_tigung__c(Kunde__c =kd1.id, Lieferschein__c=lsSet[1]);
        insert lb2;
      }

    static testMethod void testTrigger() { 
        list<account> acList = [SELECT id FROM account LIMIT 1];
        // test trigger 
        // Kandidat
        Kunde__c kdt = [SELECT id FROM Kunde__c];
        List<Kundenstatus__c> ksList = [SELECT id, Status__c FROM Kundenstatus__c WHERE Kunde__c = :kdt.id] ;
             id rtid = null;                                
            list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'Inko'];
            if((rtList != null) && (rtList.size() > 0)) {
                rtId = rtList[0].id;
            } 
        List<task> tsList = new List<task>();
        Task t = new Task(ActivityDate = Date.today().addDays(3),
                            Subject='Nachtelefonie von Interessenten',
                            WhatId = Kdt.ID,
                            OwnerId = UserInfo.getUserId(),
                            IsReminderSet = true,
                            ReminderDateTime = System.now()+3,                                     
                            Description = 'Nachtelefonie von Interessenten',                                        
                            Status='Open');
        tsList.add(t);
        t = new Task(ActivityDate = Date.today().addDays(3),
                            Subject='Nachtelefonie INKO-Formular',
                            WhatId = Kdt.ID,
                            RecordTypeID = rtId,
                            OwnerId = UserInfo.getUserId(),
                            IsReminderSet = true,
                            ReminderDateTime = System.now()+3,                                     
                            Description = 'Nachtelefonie INKO-Formular',                                        
                            Status='Open');
        tsList.add(t);

        insert tsList;

        List<Lieferschein__c> lsList = [SELECT id FROM Lieferschein__c];
        List<Genehmigung__c> gnList = [SELECT id FROM Genehmigung__c];
        List<ksgLoader__c> ksgList = [SELECT id FROM ksgLoader__c];

        List<attachment> atList = new List<attachment>();
        attachment at = new attachment(ParentId = kdt.id);
        at.name = 'Antrag_PG51.PDF';
        string csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = kdt.id);
        at.name = 'Antrag_PG54.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = kdt.id);
        at.name = 'Antrag_PGXX.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = kdt.id);
        at.name = 'LIEFERSCHEIN.XML';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);     

        at = new attachment(ParentId = kdt.id);
        at.name = 'Genehmigung_PG51.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = kdt.id);
        at.name = 'Genehmigung_PG54.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = kdt.id);
        at.name = 'Inko.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = kdt.id);
        at.name = 'Inkoformular.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = lsList[0].id);
        at.name = 'Lieferschein.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = lsList[0].id);
        at.name = 'LIEFERSCHEIN.XML';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);    

        at = new attachment(ParentId = lsList[1].id);
        at.name = 'Ablieferbeleg_zuLS.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = gnList[0].id);
        at.name = 'Genehmigung_PG51.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = gnList[1].id);
        at.name = 'Genehmigung_PG54.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = ksgList[0].id);
        at.name = 'joblog.txt';
        csv = 'v2.0.0.3 / id:6232 / 09.11.2018 06:00:12 / start hidden\r\n';
        csv += 'v2.0.0.3 / id:6764 / 09.11.2018 11:10:26 / 1217 Rechnugspositionen erstellt\r\n';
        csv += 'v2.0.0.3 / id:2052 / 09.11.2018 18:53:33 / Ende\r\n';
        at.body = blob.valueOf(csv);
        atList.add(at);

        at = new attachment(ParentId = acList[0].id);
        at.name = 'Account.PDF';
        csv = 'test';
        at.body = blob.valueOf(csv);
        atList.add(at);

        Test.startTest();
        Database.SaveResult[] srList = Database.insert(atList, false); 

        list<attachment> atl = [SELECT id FROM attachment  WHERE name LIKE 'Account%' LIMIT 1];
        delete atl;        
        Test.stopTest();   
    }     
 
}