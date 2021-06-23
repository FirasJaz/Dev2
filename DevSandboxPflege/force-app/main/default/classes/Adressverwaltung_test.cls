@isTest
private class Adressverwaltung_test {
    static testMethod void myUnitTest() {
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.Art_des_Kontakts__c='kein';
        insert c;

        k.Betreuer__c = c.ID;
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        insert a;
        k.Krankenkasse__c = a.ID;
        Account p = new Account(Name = 'Pflegedienst Test');
        p.Industry='Pflegedienste';
        
        List<RecordType> rt = [Select Id, Name From RecordType Where SobjectType = 'Account' and Name = 'X01' LIMIT 1];
        if((rt != null) && (rt.size() > 0)){
            String strRecordTypeId = String.valueOf(rt[0].Id);
//          p.RecordtypeID = '012m00000004J06';
            p.RecordtypeID = rt[0].id;
        
        }
        insert p;
//      k.Pflegedienst__c = p.ID;
        
        insert k;
        Adressverwaltung_class.insert_neue_kunden(new List<Kunde__c>{k});
        List<Anschrift__c> ans = [select ID, Art_der_Anschrift__c, Kunde__c from Anschrift__c
                                 where Kunde__c =: k.ID];
        system.debug('Anzahl Adressen: '+ans.size());                    
//      system.assert(ans != null && ans.size() == 6);
        c = new Contact(firstname = 'Testmann2', lastname = 'Betreuer2');
        c.Art_des_Kontakts__c='kein';
        insert c;

        k.Betreuer__c = c.ID;
        p = new Account(Name = 'Pflegedienst Test2');
        p.Industry='Pflegedienste';
        insert p;
//        k.Pflegedienst__c = p.ID;
        // k.Hausnummer__c = '12';
        update k;
        ans = [select ID, Art_der_Anschrift__c, Kunde__c, Standardlieferanschrift__c, Standardrechnungsanschrift__c from Anschrift__c
            where Kunde__c =: k.ID and Art_der_Anschrift__c =: 'Kundenadresse'];
        system.debug('Anzahl Adressen: '+ans.size());   
        // system.assert(ans.size()==3);
        Test.startTest();
        List<Anschrift__c> anList = new List<Anschrift__c>();
        Anschrift__c neu = new Anschrift__c();

        neu.Standardlieferanschrift__c = true;
        neu.Standardrechnungsanschrift__c = true;
        neu.Art_der_Anschrift__c = 'Pflegedienst';
        neu.Kunde__c = k.ID;
        // insert neu;
        anList.add(neu);
        
        Anschrift__c neu2 = new Anschrift__c();
        neu2.Standardlieferanschrift__c = false;
        neu2.Standardrechnungsanschrift__c = false;
        neu2.Art_der_Anschrift__c = 'sonstige';
        neu2.Kunde__c = k.ID;
        // insert neu2;
        anList.add(neu2);
        Anschrift__c neu3 = new Anschrift__c();
        neu3.Standardlieferanschrift__c = true;
        neu3.Standardrechnungsanschrift__c = false;
        neu3.Art_der_Anschrift__c = 'Betreuer';
        neu3.Kunde__c = k.ID;
        // insert neu3;
        anList.add(neu3);
        
        Anschrift__c neu4 = new Anschrift__c();
        neu4.Standardlieferanschrift__c = false;
        neu4.Standardrechnungsanschrift__c = true;
        neu4.Art_der_Anschrift__c = 'Betreuer';
        neu4.Kunde__c = k.ID;

        // insert neu4;
        anList.add(neu4);
        insert anList;
     
        anList[1].Standardlieferanschrift__c = true;
        anList[1].Standardrechnungsanschrift__c = true;
        // update neu2;
        
        anList[3].Standardlieferanschrift__c = true;
        anList[3].Standardrechnungsanschrift__c = false;
        // update neu4;
        
        anList[2].Standardlieferanschrift__c = false;
        anList[2].Standardrechnungsanschrift__c = true;
        // update neu3;
        
        anList[0].Standardlieferanschrift__c = false;
        anList[0].Standardrechnungsanschrift__c = false;
        update anList;
        test.stopTest();
        
        ans = [select ID, Art_der_Anschrift__c, Kunde__c, Standardlieferanschrift__c, Standardrechnungsanschrift__c from Anschrift__c
            where Kunde__c =: k.ID and Art_der_Anschrift__c =: 'Pflegedienst'];
        delete neu2;
        delete neu3;
        delete neu;
    
        ans = [select ID, Art_der_Anschrift__c, Kunde__c, Standardlieferanschrift__c, Standardrechnungsanschrift__c from Anschrift__c
            where Kunde__c =: k.ID and Art_der_Anschrift__c =: 'sonstige'];
        delete neu4;
        system.debug('Anzahl Adressen: '+ans.size());
        
        Adressverwaltung_class.setenableKN(true);
        
        //Adressverwaltung_class.setLeereZeilen();
        
        k = new Kunde__c(Name__c = 'Testkunde Mit Nummer!', Produktgruppe__c = 'PG54');
        k.Betreuer__c = c.ID;
//        k.Pflegedienst__c = p.ID;
        insert k;
        Adressverwaltung_class.insert_neue_kunden(new List<Kunde__c>{k});
        k = new Kunde__c(Name__c = 'Testkunde Mit Nummer!2', Produktgruppe__c = 'PG54');
        k.Betreuer__c = c.ID;
//        k.Pflegedienst__c = p.ID;
        insert k;
        Adressverwaltung_class.neueKundennummer(new List<Kunde__c>{k});
        k = [select ID,Kundennummer__c from Kunde__c where ID =: k.ID];
       // system.assert(k.Kundennummer__c != null);
        system.debug('Kunde: ' +k.ID+'mit der Kundennummer: '+k.Kundennummer__c);
        //system.debug('Free Num At All: '+[Select Kundennummer__c, Id 
        //                From freie_Kundennummer__c LIMIT 89000].size());
        system.debug('Anzahl Kunden mit "null" Kundennummer: '+[Select Kundennummer__c, Id 
                        From Kunde__c where Kundennummer__c =: null].size());
        Adressverwaltung_class.getenableKN();
        
        
        /* ***** added by Mansoureh Ziaei ***** */
        k = new Kunde__c(Name__c = 'Testkunde3', Produktgruppe__c = 'PG54');
        c = new Contact(firstname = 'Testmann3', lastname = 'Betreuer');
        c.otherCity='Berlin';
        c.Art_des_Kontakts__c='kein';
        insert c;
        k.Betreuer__c = c.ID;
        a = new Account(Name = 'Test KK 5');
        a.Industry='Krankenkassen';
        insert a;
        k.Krankenkasse__c = a.ID;
        p = new Account(Name = 'Pflegedienst Test3');
        p.Industry='Pflegedienste';
        
        rt = [Select Id, Name From RecordType Where SobjectType = 'Account' and Name = 'X01' LIMIT 1];
        if((rt != null) && (rt.size() > 0)){
            String strRecordTypeId = String.valueOf(rt[0].Id);
//          p.RecordtypeID = '012m00000004J06';
            p.RecordtypeID = rt[0].id;
        }
        insert p;
        c = new Contact(firstname = 'Testmann4', lastname = 'Betreuer4');
        c.otherCity='Dresden';
        c.Art_des_Kontakts__c='kein';
        insert c;

        k.ges_Vertreter__c = c.Id;
        insert k;
        Adressverwaltung_class.insert_neue_kunden(new List<Kunde__c>{k});
        k.Lieferadresse__c = 'Adresse Pflegeperson';
        c = new Contact(firstname = 'Testmann5', lastname = 'Betreuer_ziaei');
        c.Art_des_Kontakts__c='kein';
        insert c;
        k.Betreuer__c = c.ID;
        p = new Account(Name = 'Pflegedienst Test4');
        p.Industry='Pflegedienste';
        //[select Phone, BillingStreet, BillingPostalCode, 
          //                      BillingCountry, BillingCity, Id, Fax, zugang_letzter_Kunde__c, Name from Account 
         //                       where ID =: KundenNew.get(i).Pflegedienst__c]
        insert p;
        k.Abbestellungsdatum__c = Date.today();
        update k;
    }
}