@isTest
private class Genehmigung_test {

    static testMethod void myUnitTest() {
        Account KK = new Account();
        KK.Industry = 'Krankenkassen';
        KK.Name = 'Krankenkasse';
        KK.type = 'TestKrK';
        insert KK;
        
        Kunde__c kd = new Kunde__c (Krankenkasse__c = kk.id, Name__c = 'Muster', Produktgruppe__c = 'PG54');
        kd.Versichertennummer__c = '1234567';
        insert kd;
        
        Artikel__c ar = Data_For_Tests_Class.createArtikel(1);
        
        Auftrag__c au = new Auftrag__c(
                        Kunde__c = kd.id,
                        Fallpauschale__c = null);
        au.genehmigt_ab__c = date.today().addDays(-7);
        au.genehmigt_bis__c = date.today().addDays(7);
        insert au;      
 
        Auftragsposition__c ap = new Auftragsposition__c(Kunde__c = kd.id,
                                                        Auftrag__c = au.id,
                                                        GenAnzVerp__c = 10,
                                                        Artikel__c = ar.id);
        insert ap;
        List<Auftragsposition__c> lap = new List<Auftragsposition__c>();
        lap.add(ap);
        
    
        date Heute = date.today();
        string pm = 'test';
        string ag = '51'; 
        Genehmigung.GenehmigungsStatus gs = new Genehmigung.GenehmigungsStatus(Heute, pm, ag);
        List<Genehmigung.GenehmigungsStatus> lgs = new List<Genehmigung.GenehmigungsStatus>();
        lgs.add(gs);
        Genehmigung__c ge = new Genehmigung__c(Kunde__c = kd.id, Status__c = 'Antragsversand');
        insert ge;        
        
        Genehmigung.OrderWrapper owr = new Genehmigung.OrderWrapper(au);
        try {
            List<Genehmigung.GenehmigungsStatus> lgsn = Genehmigung.PflegeboxcheckCustomer(lgs, kd, au, lap);
        }
        catch (Exception e) {
        
        }
        try {
            List<Genehmigung.GenehmigungsStatus> lgsnr = Genehmigung.RezeptcheckCustomer(lgs, kd, lap);
        }
        catch (Exception e) {
        
        }       
        List<Kunde__c> lkd = Genehmigung.getCustomer();
        Genehmigung.reserviereFuerAuftrag(au);
        Genehmigung.einfachePruefung(au, kd);
        Genehmigung.AuthorizationWrapper awr = new Genehmigung.AuthorizationWrapper();
        Genehmigung.AuthorizationWrapper awr2 = new Genehmigung.AuthorizationWrapper(ge);
        List<Genehmigung.AuthorizationWrapper> lawr = new List<Genehmigung.AuthorizationWrapper>();
        lawr.add(awr);
        
        Genehmigung.AuthorizationWrapperPosition awp = new Genehmigung.AuthorizationWrapperPosition(ge);
            List<Genehmigung.AuthorizationWrapperPosition> lgawr = Genehmigung.getGenehmigungsposition(ge);
        try {
            List<Genehmigung.GenehmigungsStatus> lgsn3 = Genehmigung.doMonthlyCheck(lgs, owr, lawr, 1);
        }
        catch (Exception e) {
        
        }       
    
        // added by Mansoureh Ziaei 21-9-2015
        Genehmigung.PflegeboxcheckCustomerThisMonth(kd, au, lap, Date.today(), 5);
        map<id,genehmigung__c> genehmigung_map = new map<id,genehmigung__c> ();
        genehmigung_map.put(ge.Id, ge);
        Genehmigung.updAllLSPos(genehmigung_map);
        map<id,Auftrag__c> Auftrag_map = new map<id,Auftrag__c> ();
        Auftrag_map.put(au.Id, au);
    map<id,Auftragsposition__c> APos_map = new map<id,Auftragsposition__c> ();
        APos_map.put(ap.Id, ap);
        Genehmigung.getAufAPosMap(Auftrag_map, APos_map);
        Genehmigung.checkPosition(lgs, Date.today(), ap, awp, ge);
        Genehmigung.checkPositionMg(lgs, Date.today(), ap, awp, ge, 5);
        //awr = new Genehmigung.AuthorizationWrapper();
        Genehmigung.addAuthorizationToAuthorization(awr, awr2);
        Genehmigung.getMinDate(Genehmigung.getOrdersOfCustomer(kd));
        Genehmigung.getMaxDate(Genehmigung.getOrdersOfCustomer(kd));
        try{Genehmigung.getunbefristet(Genehmigung.getOrdersOfCustomer(kd));}catch(Exception e){}
        awr.getPositionByName('test');
        awr.getMinDate();
        awr.getMaxDate();
        awr.getunbefristet();
        awp = new Genehmigung.AuthorizationWrapperPosition(ge, null);
        Genehmigung.doMonthlyCheck(lgs, owr, lawr);
        Genehmigung.CheckDateBoolean(Date.today(), owr, lawr);
    }
    
    static testMethod void genehmigungErhaltenUnitTest() {
        Kunde__c kd = new Kunde__c (Name__c = 'Test', Produktgruppe__c = 'PG54');
        kd.Versichertennummer__c = '1234567';
        insert kd;

        Blob abody = blob.valueOf('test');
        Attachment attach = new Attachment(Body = abody, ParentId = kd.Id, Name = 'Genehmigung_test');
        insert attach;
        PageReference tpageRef = Page.Genehmigung_erhalten;
      Test.setCurrentPage(tpageRef);
        ApexPages.StandardController sc = new ApexPages.standardController(kd);
        ApexPages.currentPage().getParameters().put('kdid', kd.Id);
        Genehmigung_erhalten e = new Genehmigung_erhalten(sc);
        e.checkAttachment();
        e.manuelleAuswahl();
        e.getAtList();
        e.getGnList();
        e.getAttID();
    }
}