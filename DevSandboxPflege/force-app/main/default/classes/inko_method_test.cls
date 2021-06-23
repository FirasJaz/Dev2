@isTest
private class inko_method_test {
    static testMethod void myUnitTest() {
        Artikel__c ar = new Artikel__c( name = 'testname1',
                                         a_pac_apo_EAN_UPC__c = Decimal.valueOf('1111111111111'),
                                         Anlage_4_Preis__c = 0.00);
        insert ar;
        Kunde__c Kd = new Kunde__c( name__c ='testkunde',
                                    produktgruppe__c = 'Inko',
                                    e_mail__c = 'heute@heute.heute');
                                    
        insert Kd;
        Auftrag__c au1 = new Auftrag__c(Kunde__c = kd.id);
        insert au1;
        Auftragsposition__c ap1 = new Auftragsposition__c(Kunde__c = kd.id, Artikel__c = ar.id, Auftrag__c = au1.id,
                                                          GenAnzVerp__c = 2, Gen_Menge_Stk_Mon__c=2 );
        insert ap1;
                        
        inko_method inko_method_c = new inko_method();
        PageReference pRef = new PageReference('http://www.google.com');
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('rowIndex', '0');
        ApexPages.currentPage().getParameters().put('Index', '0');
        
        inko_method_c.auftragEditModeOn(Au1);
        
        inko_method_c.getInkoselect();
        inko_method_c.getSelected();
        inko_method_c.setSelected('test');
        inko_method_c.getAusloeserList();
        inko_method_c.auftragAusloesen();
        inko_method_c.checkAuftrag();
        



        inko_method_c.auswaehlen();
        inko_method_c.loeschen();
        inko_method_c.getGesamtpreis();
        inko_method_c.setLeereZeilen();
        
       
    }
}