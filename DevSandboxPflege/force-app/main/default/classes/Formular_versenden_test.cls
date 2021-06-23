@isTest
private class Formular_versenden_test {
  static testMethod void formularVersendenInkoUnitTest() {
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        a.Kategorie__c = '01 Ambulante Pflegedienste';
        a.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        insert a;
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.AccountId=a.Id;
        c.Salutation = 'HerrFrau';
        insert c;
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Pflegedienst__c = a.Id;
        k.Betreuer__c = c.Id;
        k.Anrede__c = 'HerrFrau';
        insert k;
        Antragstext__c at = new Antragstext__c(Textkey__c = 'Eingang_andere');
        insert at;
        at = new Antragstext__c(Textkey__c = 'Anschreiben_formular_inko');
        insert at;
        at = new Antragstext__c(Textkey__c = 'Anschreiben_formular');
        insert at;
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        lead l = new lead(Lastname = 'testLead', Company='testCompany', Angehoeriger_Nachname__c = 'testLead', Angehoeriger_Anrede__c='testLead', OM_Wizzard_Name2__c = cmp.Id);
        l.Salutation = 'HerrFrau';
        insert l;

        Formular_versenden_Inko fv = new Formular_versenden_Inko();
    ApexPages.StandardController sc = new ApexPages.standardController(l);
        PageReference tpageRef = Page.Formular_versenden;
      Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('ID', l.Id);
        ApexPages.currentPage().getParameters().put('fmType', 'formular');
      fv = new Formular_versenden_Inko(sc);   
        try{fv.perEmail();}catch(Exception e){}
        ApexPages.currentPage().getParameters().put('fmType', 'eingangsbest');
      fv = new Formular_versenden_Inko(sc);
        try{fv.perEmail();}catch(Exception e){}
        fv.zurueck();
        try{fv.changeRcpt();}catch(Exception e){}  
        fv.addTask('test per Email versandt', 'test per Email versandt an (mansoured.ziaei@gmail.com)' );
        fv.getPageTitle();
        fv.getBeschreibung();
        fv.getEmpfaenger();
        fv.getMailHinweis();
        fv.getAddrHinweis();
        fv.getMainPageName();
        fv.getHasMail();
        fv.getHasAddr();
        fv.getMailAdressen();
        fv.getSelectedRcpt();
        fv.getselRCPT();
    fv.setSelectedRcpt('test');

    }
    
    static testMethod void formularVersendenUnitTest() {
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        a.Kategorie__c = '01 Ambulante Pflegedienste';
        a.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        insert a;
        Contact c = new Contact(firstname = 'Testmann', lastname = 'Betreuer');
        c.AccountId=a.Id;
        c.Salutation = 'HerrFrau';
        insert c;
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Pflegedienst__c = a.Id;
        k.Betreuer__c = c.Id;
        k.Anrede__c = 'HerrFrau';
        insert k;
        Antragstext__c at = new Antragstext__c(Textkey__c = 'Eingang_andere');
        insert at;
        at = new Antragstext__c(Textkey__c = 'Anschreiben_formular_inko');
        insert at;
        at = new Antragstext__c(Textkey__c = 'Anschreiben_formular');
        insert at;
        at = new Antragstext__c(Textkey__c = 'Anschreiben_CB_Assistent_mail');
        insert at;
        Formular_versenden fv = new Formular_versenden();
        ApexPages.StandardController sc = new ApexPages.standardController(k);
        PageReference tpageRef = Page.Formular_versenden;
      Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('ID', k.Id);
        ApexPages.currentPage().getParameters().put('fmType', 'formular');
      fv = new Formular_versenden(sc);
        try{fv.perEmail();}catch(Exception e){}
        try{fv.perEmailInko();}catch(Exception e){}      
        ApexPages.currentPage().getParameters().put('fmType', 'eingangsbest');
      fv = new Formular_versenden(sc);
        try{fv.perEmail();}catch(Exception e){}
        try{fv.perEmailInko();}catch(Exception e){}                
        fv.zurueck();
        try{fv.changeRcpt();}catch(Exception e){}  
        fv.addTask('Formular', 'test per Email versandt an (mansoured.ziaei@gmail.com)' );
        fv.getPageTitle();
        fv.getBeschreibung();
        fv.getEmpfaenger();
        fv.getMailHinweis();
        fv.getAddrHinweis();
        fv.getMainPageName();
        fv.getHasMail();
        fv.getHasAddr();
        fv.getMailAdressen();
        fv.getSelectedRcpt();
        fv.getMainPageName_inko();
        fv.getselRCPT();
        fv.getFmType();
        fv.setSelectedRcpt('test');
        fv.pageBack();
        fv.getMainPageName_Assistent();
        fv.getsubject_Assistent();
        fv.getmText();
        fv.getMailVorschau();
        fv.getatt();
        try{fv.perEmailAssistent();}catch(Exception e){}
        try{fv.startMail();}catch(Exception e){}
    fv.setSelectedRcpt('test');
    }
    
}