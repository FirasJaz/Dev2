@isTest(seealldata=false)
private class before_insert_lieferscheinposition_test {
    
    static testMethod void myTest1() {
        Artikel__c art1 = new Artikel__c (a_pac_apo_EAN_UPC__c = decimal.valueOf('4031678000234'));
        Artikel__c art2 = new Artikel__c (a_pac_apo_EAN_UPC__c = decimal.valueOf('4031678000255'));
        insert art1;
        insert art2;
        Kunde__c kd = new Kunde__c(Name__c = 'testnachname', Produktgruppe__c ='PG54');
        insert kd;
        Lieferscheinposition__c Pos1 = new Lieferscheinposition__c (Kunde__c= kd.id, Artikel__c = art1.id );
        Lieferscheinposition__c Pos2 = new Lieferscheinposition__c (Kunde__c= kd.id, Artikel__c = art2.id );
        
        insert Pos1;
        insert Pos2;
    }
}