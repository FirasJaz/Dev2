/*/****************************************************************************************************************************
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Test für email_verschicken_batch2
// testet primär, ob die richtigen Kundenstatus__c-Records genommen und aktualisiert werden
// 
//****************************************************************************************************************************
//Änderungen:    
// 09.10.2018	MS	Case 1752
// 					Test entsprechend angepasst und vereinfacht                                                      
//****************************************************************************************************************************
*/
@isTest
private class email_verschicken_batch2_test {
    // creates Kunde__c and Kundenstatus__c records with the given parameters
     static Kunde__c createKundeAndKundenstatus(String s, String status, Integer AnzahlEmails, Date Creation){
        Kunde__c kd = new Kunde__c();
        kd.Name__c = 'Kunde'+s;    
        kd.Anrede__c = 'Herr';   
        kd.e_mail__c = s+'test@test.de'; 
        kd.Produktgruppe__c = 'PG54';
        kd.Email_Opt_Out__c = false;
        insert kd;
        
        Test.setCreatedDate(kd.id, Creation);
        Kundenstatus__c ks = [SELECT  id, Kunde__c, Produktgruppe__c, Anzahl_Erinnerung_Email__c, Status__c
                                        FROM Kundenstatus__c
                                        WHERE  Kunde__c =: kd.Id LIMIT 1];
        ks.Anzahl_Erinnerung_Email__c = AnzahlEmails;
        ks.Status__c = status;
        Test.setCreatedDate(ks.id, Creation);
        update ks;
        
        return kd;
    }
    
    // gets the kdId's Record and executes the assertEquals with the
    // given parameters (only to simplify the code a bit)
    static void makeAsserts(Id kdId, Integer AnzahlEmails, String status){
        Kundenstatus__c ks_r = [SELECT  id, Kunde__c, Produktgruppe__c, Anzahl_Erinnerung_Email__c, Status__c, createddate
                                        FROM Kundenstatus__c
                                        WHERE  Kunde__c =: kdId ]; 

        System.assertEquals(AnzahlEmails, ks_r.Anzahl_Erinnerung_Email__c);
        System.assertEquals(status, ks_r.Status__c);
    }
    
    static testMethod void myUnitTest() {
        //kd1, in: interessent, counter: null, today-6
        // expect: send email, interessent, counter: 1
        Kunde__c kd1 = createKundeAndKundenstatus('1','Interessent',null,date.today().addDays(-6));
        //kd2, in: interessent, 0, today-6
        // expect: send email an betreuer, interessent, counter: 1
        Kunde__c kd2 = createKundeAndKundenstatus('2-betreuer','Interessent',0,date.today().addDays(-6));
        
        kd2.e_mail__c = null;
        Contact c = new Contact();
        c.firstName = 'Stefan';
        c.lastName = 'Müller';
        c.Email = 'betreuer-test@test.de';
        c.salutation = 'Herr';
        insert c;

        kd2.Betreuer__c = c.id;
        update kd2;
        
        
        //kd3, in: Vorgang geschlossen, 2, today-100
        Kunde__c kd3 = createKundeAndKundenstatus('3','Vorgang geschlossen',2,date.today().addDays(-100));
        
        //kd4, in: Interessent, 1, today-15
        Kunde__c kd4 = createKundeAndKundenstatus('4','Interessent',1,date.today().addDays(-15));
        
        //kd5, in: Interessent, 1, today-9
        Kunde__c kd5 = createKundeAndKundenstatus('5','Interessent',1,date.today().addDays(-9));
        
        //kd6, in: Interessent, null, today-9
        Kunde__c kd6 = createKundeAndKundenstatus('6','Interessent',null,date.today().addDays(-9));
        
        //kd7, in: Interessent, null, today-95
        Kunde__c kd7 = createKundeAndKundenstatus('7','Interessent',null,date.today().addDays(-95));
        
        //kd8, in: Interessent, 2, today-91
        Kunde__c kd8 = createKundeAndKundenstatus('8','Interessent',2,date.today().addDays(-91));
        
        // ms, 10.9.18:
        // more scenarios are possible and maybe shall be tested, just to be sure.
        // furthermore the best would be to check, if emails were sent out or not
        // but that isnt that trivial (one solution: https://salesforce.stackexchange.com/a/73316 )
        
        Test.StartTest();
        email_verschicken_batch2 evb3 = new email_verschicken_batch2();
        Id batchId3 = Database.executeBatch(evb3);
        Test.StopTest(); // causes all asynchronous tasks to execute.
        
        //kd1, in: interessent, counter: null, today-6
        // expect: email, interessent, counter: 1
        makeAsserts(kd1.Id, 1, 'Interessent');
        
        //kd2, in: interessent, 0, today-6
        // expect: email an betreuer, interessent, counter: 1
        makeAsserts(kd2.Id, 1, 'Interessent');
        
        //kd3, in: Vorgang geschlossen, 2, today-100
        // expect: no email, Vorgang geschlossen, counter: 2   
        makeAsserts(kd3.Id, 2, 'Vorgang geschlossen');
                
        //kd4, in: Interessent, 1, today-15
        // expect: email, Interessent, counter: 2
        makeAsserts(kd4.Id, 2, 'Interessent');
                
        //kd5, in: Interessent, 1, today-9
        // expect: no email, Interessent, counter: 1
        makeAsserts(kd5.Id, 1, 'Interessent');
        
        //kd6, in: Interessent, null, today-9
        // expect: no email, Interessent, counter: 0
        makeAsserts(kd6.Id, null, 'Interessent');
        
        //kd7, in: Interessent, null, today-95
        // expect: email, Vorgang geschlossen, counter: 1
        makeAsserts(kd7.Id, 1, 'Vorgang geschlossen');
        
        //kd8, in: Interessent, 2, today-91
        // expect:  email, Vorgang geschlossen, counter: 3
        makeAsserts(kd8.Id, 3, 'Vorgang geschlossen');
    }
    
    static testMethod void runBatchWithoutDataTest() {
        Test.StartTest();
        email_verschicken_batch2 csre = new email_verschicken_batch2();
        Id batchId = Database.executeBatch(csre);
        Test.StopTest();
    }
    

}