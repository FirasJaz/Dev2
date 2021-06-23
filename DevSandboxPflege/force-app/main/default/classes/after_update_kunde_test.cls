@isTest(seealldata=false)
private class after_update_kunde_test {
    static testMethod void myUnitTest() {
        Account KK = new Account();
        KK.Industry = 'Krankenkassen';
        KK.Name = 'TestKK';
        KK.type = 'Test';
        insert KK;

        Kunde__c kd1 = new Kunde__c(Krankenkasse__c = kk.id, 
                                    Name__c = 'TestKunde',
                                    Produktgruppe__c = 'Inko');
        
        insert kd1;
        Kundenstatus__c ks1 = new Kundenstatus__c( Kunde__c = kd1.id,
                                                   Status__c = 'Kandidat',
                                                   Produktgruppe__c = 'Inko');
                                                                        
        
        insert ks1;
        Kundenstatus__c ks3 = new Kundenstatus__c( Kunde__c = kd1.id,
                                                   Status__c = 'Kandidat',
                                                   Produktgruppe__c = 'PG54');
                                                                        
        
        insert ks3;
        Kundenstatus__c ks4 = new Kundenstatus__c( Kunde__c = kd1.id,
                                                   Status__c = 'Kandidat',
                                                   Produktgruppe__c = 'PG51');
                                                                        
        
        insert ks4;        
        /* Kunde__c kd2 = new Kunde__c(Krankenkasse__c = kk.id, 
                                    Name__c = 'TestKunde',
                                    Status__c = 'Kunde'); */
        Kunde__c kd2 = new Kunde__c(Krankenkasse__c = kk.id, 
                                    Name__c = 'TestKunde',
                                    Produktgruppe__c = 'Inko');  
        insert kd2;                                    
        Kundenstatus__c ks2 = new Kundenstatus__c( Kunde__c = kd2.id,
                                                   Status__c = 'Kunde',                                                   
                                                   Produktgruppe__c = 'Inko');                                                         
        insert ks2;
        Artikel__c ar1 = new Artikel__c(Name = 'art1');
        insert ar1;
        
        Auftrag__c au1 = new Auftrag__c(Kunde__c = kd1.id);
        insert au1;
        
        Auftrag__c au2 = new Auftrag__c(Kunde__c = kd2.id, genehmigt_ab__c = date.today());
        insert au2; 

        Auftragsposition__c ap1 = new Auftragsposition__c(Kunde__c = kd1.id, Artikel__c = ar1.id, Auftrag__c = au1.id);
        insert ap1;

        Auftragsposition__c ap2 = new Auftragsposition__c(Kunde__c = kd2.id, Artikel__c = ar1.id, Auftrag__c = au2.id);
        insert ap2;

        Lieferschein__c ls1 = new Lieferschein__c(Kunde__c = kd1.id, Unterschrift__c = true, Lieferschein_text__c = '54');
        insert ls1;

        Lieferschein__c ls2 = new Lieferschein__c(Kunde__c = kd1.id, Unterschrift__c = true, Lieferschein_text__c = '51');
        insert ls2;
        
        Lieferscheinposition__c lp1 = new Lieferscheinposition__c(Kunde__c = kd1.id, Lieferschein__c = ls1.id, Unterschrift__c = true, Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar');
        insert lp1;

        Lieferscheinposition__c lp2 = new Lieferscheinposition__c(Kunde__c = kd1.id, Lieferschein__c = ls2.id, Unterschrift__c = true, Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar');
        insert lp2;     
        
        Task t1 = new Task(ActivityDate = Date.today().addDays(21),
                            Subject='Nachfassen bei PK wg. offener KÜ',
                            WhatId = Kd1.ID,
                            IsReminderSet = true,
                            ReminderDateTime = System.now()+14,                                     
                            Description = 'Nachfassen bei PK wg. offener KÜ',                                       
                            Status='Open');     
        insert t1;

        Task t2 = new Task(ActivityDate = Date.today().addDays(21),
                            Subject='Nachfassen bei PK wg. offener KÜ',
                            WhatId = Kd2.ID,
                            IsReminderSet = true,
                            ReminderDateTime = System.now()+14,                                     
                            Description = 'Nachfassen bei PK wg. offener KÜ',                                       
                            Status='Open');     
        insert t2;      
        // OK, jetzt los

        ks1.Status__c = 'Kunde';        
        update ks1;
        
        kd1.Produktgruppe__c = 'PG54';
        update kd1;
        
        ks1.Status__c = 'Kündigung';         
        update ks1;    
        
        kd1.Produktgruppe__c = 'PG51';
        update kd1;
        
        ks2.Status__c = 'Vorgang geschlossen';
        ks2.K_ndigungsdatum__c = Date.today();
        update ks2;
        
        ks3.Status__c = 'Kunde';
        update ks3;

        ks4.Status__c = 'Kunde';
        update ks4;     
        
        
    }
}