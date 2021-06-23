@isTest //(seealldata=false)
private class AB_normale_genehmigung_test {

    static testMethod void myUnitTest() {   
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde3333', Produktgruppe__c = 'PG54');
        k.Name = 'Testkunde';
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.Art_des_Kontakts__c='kein';
        insert c;
        k.Betreuer__c = c.ID;
        Account ac = new Account(Name = 'tkkstrt');
        ac.Industry='Krankenkassen';
        insert ac;
        
        k.Krankenkasse__c = ac.ID;
        insert k;
        
        Kunde__c asb = new Kunde__c(Name__c = 'TestASB', Krankenkasse__c = ac.ID, Produktgruppe__c = 'PG54');
        insert asb; 
        
        
        //Kunde__c kdas = new Kunde__c(Name__c = 'AS', Krankenkasse__c = ac.ID, Produktgruppe__c = 'PG54');
        //insert kdas;
        //AB_KK__c cs = new AB_KK__c(Name = 'AB_KK_Einstellungen', Abrechnungsfirma__c='AS');
        //insert cs;
        asMail__c asm = new asMail__c(name = 'asb', subject__c = 'test', body__c = 'test', toAddr__c = 'test@test.com', toCC__c = 'test@test.com');
        insert asm;
        
         Anschrift__c shop_addr2 = new Anschrift__c();
        
        shop_addr2.Name = 'test,test3';
        shop_addr2.Anrede__c = 'herr';
        shop_addr2.Kunde__c = k.Id;
        shop_addr2.Art_der_Anschrift__c = 'Kundenadresse';
        shop_addr2.e_mail__c = 'a@a.a';
        shop_addr2.Fax__c = '123';
        //inko_addr.Hausnummer__c = l.Hausnummer__c;
        shop_addr2.Ort__c = 'ort';       
        shop_addr2.Standardrechnungsanschrift__c = true;
        insert shop_addr2;
        
        
        Auftrag__c a = new Auftrag__c(); 
        a.Fallpauschale__c=null;
        a.kunde__c = k.id;
        insert a;
        
        Auftragsposition__c ap = new Auftragsposition__c();
        ap.Auftrag__c = a.Id;
        insert ap;
        
        Lieferschein__c ls1 = new Lieferschein__c(Kunde__c = k.id, Unterschrift__c = true, Lieferschein_text__c = '54');
        insert ls1;

        Lieferbest_tigung__c lt = new Lieferbest_tigung__c();
        lt.an_abena_versendet__c = true;
        lt.Rechnung__c = null;
        lt.Lieferschein__c = ls1.Id;
        insert lt;
        
        Lieferscheinposition__c l = new Lieferscheinposition__c();
        l.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
        l.Status__c = null; 
        l.Unterschrift__c = true;         
        l.kunde__c = k.id;
        l.Lieferschein__c = ls1.Id;
        l.Auftragsposition__c = ap.id;
        insert l;
        
        AB_KK__c ab_kk = new AB_KK__c();
        ab_kk.Name = 'AB_KK_Einstellungen';
        ab_kk.Abrechnungsfirma__c = 'TestASB';
        insert ab_kk;

        asMAil__c asMail = new asMail__c(name = 'asb');
        asMail.subject__c = 'test_ziaei';
        asMail.toAddr__c = 'mansoure.ziaei@gmail.com';
        asMail.toCC__c = 'mansoure.ziaei@gmail.com';
        insert asMail;
        
        Blob abody = blob.valueOf('test');
        Attachment attach = new Attachment(Body = abody, ParentId = ls1.Id, Name = 'Ablieferbeleg_test');
        insert attach;
        
        AB_normale_genehmigung ext1 = new AB_normale_genehmigung();
        ApexPages.StandardSetController t1 = ext1.setCon;
        List<Lieferscheinposition__c> t2 = ext1.zumAbrechnen;
        Boolean bt = ext1.hasNext;
        bt = ext1.hasPrevious;
        Integer t = ext1.pageNumber;
        ext1.getButtonVersenden();
        ext1.getAufruf();
        ext1.first();
        ext1.last();
        ext1.previous();
        ext1.next();
        ext1.getKkName();       
        
        try {
            ext1.createAndSend();
        }
        catch(System.Exception e) {}
        ext1.goBack();
        ext1.startBatch();
        ext1.printZuzahlung(1.2);
        ext1.printZuzahlungBeihilfe(1.2);
        ext1.setKkName('test');
        
        PageReference tpageRef = Page.AB_normale_genehmigung;
        Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('call', 'los');
        ApexPages.currentPage().getParameters().put('kk', 'test ziaei');
        ext1 = new AB_normale_genehmigung();
        ext1.createAndSend();

        ext1.setLeereZeilen();
    }
}