@isTest
private class KSG_test_attachment {

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

    
        Blob abody = blob.valueOf('test');

        Attachment attach3 = new Attachment(Body = abody, ParentId = LS.id, Name = 'LS.XML');
        insert attach3;
        

    }
}