@isTest
public class Auftragsverwaltung_test {
    
  static testMethod void myUnitTest() {
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'test_group');
        insert k;
        Auftrag__c af = new Auftrag__c(); 
        af.kunde__c = k.id;
        insert af;
        PageReference tpageRef = Page.Auftragsverwaltung;
      Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('id', k.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(af);
      Auftragsverwaltung a = new Auftragsverwaltung(sc);
        String bn = a.boxName;
        bn = a.applyPBVlfdName;
        bn = a.SelectedTab;
        bn = a.getSectionTitle();
        Boolean b = a.getArtikelEditMode();
        b = a.getInkoEditMode();
        b = a.getInkoAuftragEditMode();
        b = a.getAuftragEditMode();
        b = a.getKeineAdresse();
        b = a.getFBenable();
        b = a.getKandidat();
        b = a.getKandidat51();
        integer i = a.getColNum();
        a.applyAuId = af.Id;
        a.zurueck();
        a.inkoZuAuftrag();
        try{a.boxZuAuftrag();}catch(Exception e){}
        try{a.boxZuAuftragR();}catch(Exception e){}
        try{a.boxZuAuftragAbbrechen();}catch(Exception e){}
        a.inkoZuAuftragErstellen();
        try{a.boxEditAuftragSpeichern();}catch(Exception e){}
        a.inkoEditAuftragSpeichern();
        a.boxEditAuftragAbbrechen();
        try{a.boxZuAuftragErstellen();}catch(Exception e){}       
        try{a.PflegeBoxAuftragBearbeiten();}catch(Exception e){}
        try{a.auftragNachMeldungErstellen();}catch(Exception e){}
        try{a.inkoZuAuftragAbbrechen();}catch(Exception e){}
        a.PflegeBoxAuftragBeenden();
        a.PflegeBoxAuftragAnhalten();
        a.PflegeBoxAuftragAktivieren();
        try{a.pruefen();}catch(Exception e){}
        a.setLeereZeilen();
        try{a.selectArt();}catch(Exception e){}
        try{a.selectArtEdit();}catch(Exception e){}
    Auftrag__c tt =  a.getEaU();
        a.setEaU(tt);
        list<Auftrag__c> li = a.getLAU();
        Kunde__c kc =  a.getKDe();
        Id d = a.getKdID(); 
        a.getLnList();
    }
}