@isTest(seealldata=false)
private class before_update_kundenstatus_test {
    static testMethod void myTest1() {
        Kunde__c Kd1 = new Kunde__c( name__c ='testkunde1', produktgruppe__c = 'PG54');
        insert kd1;
        Kundenstatus__c ks = new Kundenstatus__c( Kunde__c = kd1.id,
                                                   Status__c = 'Kandidat',
                                                   Produktgruppe__c = 'Inko');
        insert ks;
        ks.status__c = 'Kündigung';
        ks.K_ndigungsbemerkung__c = 'verstorben';
        update ks;
        ks.K_ndigungsbemerkung__c = 'Kunde/In geht ins Pflegeheim';
        update ks;
        
    }
}