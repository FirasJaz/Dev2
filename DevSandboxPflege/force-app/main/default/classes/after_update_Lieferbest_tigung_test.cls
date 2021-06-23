@isTest(seealldata=false)
private class after_update_Lieferbest_tigung_test {
    static testMethod void myUnitTest() {
        list<Lieferschein__c> lsList = new list<Lieferschein__c>();
        list<Lieferbest_tigung__c> lbList = new list<Lieferbest_tigung__c>();
        Account KK = new Account();
        KK.Industry = 'Krankenkassen';
        KK.Name = 'TestKK';
        KK.type = 'Test';
        insert KK;

        Kunde__c kd = new Kunde__c(Krankenkasse__c = kk.id, 
                                    Name__c = 'TestKunde',
                                    Produktgruppe__c = 'PG54');
        
        insert kd;
        
        test.startTest();
        for(integer i=0; i<200; i++) {
            Lieferschein__c LS = new Lieferschein__c(Kunde__c = kd.id);
            lsList.add(LS);
        }
        insert lsList;
        list<Lieferschein__c> lsListI = [SELECT id FROM Lieferschein__c];
        for(Lieferschein__c LS : lsListI) {
            Lieferbest_tigung__c LB = new Lieferbest_tigung__c();
            LB.Lieferschein__c = LS.id;
            lbList.add(LB);
        }
        insert lbList;
        
        list<Lieferbest_tigung__c> lbListI = [SELECT pdf_erstellt__c FROM Lieferbest_tigung__c];
        test.stopTest();
        
        for(Lieferbest_tigung__c LB : lbListI) {
            LB.pdf_erstellt__c = true;
        }
        
        update lbListI;
        
        
    }
}