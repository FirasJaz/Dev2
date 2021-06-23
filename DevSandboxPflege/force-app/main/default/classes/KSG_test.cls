@isTest
private class KSG_test {

    static testMethod void myUnitTest() {
        Account a = new Account(Name = 'Testkrankenkasse', industry='Krankenkassen'); 
        insert a;
        date gdat = date.today().addMonths(24);
        Kunde__c KD = new Kunde__c(Name = 'Testkunde',
                                    Krankenkasse__c = a.ID,
                                    Name__c = 'Testkunde',
                                    Kundennummer__c = 123,
                                    Produktgruppe__c = 'PG54');
        insert KD;      
        Date Ldat = Date.today();
        Lieferschein__c LS = new Lieferschein__c(Kunde__c = KD.id,
                                                Lieferdatum__c = lDat);
                                            
        insert LS;

        Genehmigung__c GN = new Genehmigung__c(Kunde__c = kd.id, Name__c = 'PG54', Status__c = 'Teilbewilligung', 
                                                Antrag_beantwortet_am__c = gdat, 
                                                Antrag_eingegangen_am__c = gdat, 
                                                Antrag_versandt_am__c = gdat, 
                                                genehmigt_ab__c = gdat);
        insert GN;
        
        ls.Genehmigung__c = gn.id;
        update LS;
        
        GN.Status__c = 'Bewilligung';
        update GN;
        GN.Status__c = 'Ablehnung';
        update GN;      
        Blob abody = blob.valueOf('test');
        Attachment attach = new Attachment(Body = abody, ParentId = gn.id, Name = 'test');
        insert attach;
        Attachment attach1 = new Attachment(Body = abody, ParentId = kd.id, Name = 'Antrag');
        insert attach1;
        Attachment attach2 = new Attachment(Body = abody, ParentId = kd.id, Name = 'Genehmigung');
        insert attach2;
        
        delete attach;
    }
}