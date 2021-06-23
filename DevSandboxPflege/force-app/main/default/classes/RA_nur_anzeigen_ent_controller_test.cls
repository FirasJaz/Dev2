@isTest
public class RA_nur_anzeigen_ent_controller_test {

    private static testMethod void myUnitTest(){
        Contact co = new Contact(LastName = 'testContact');
        
        insert co;
        
        Account ac = new Account(Name = 'test');                
        ac.Industry='Krankenkassen';
        ac.Kategorie__c = '01 Ambulante Pflegedienste';
        
        insert ac;        
        
        Kunde__c kd = new Kunde__c (Anrede__c = 'Herr', Vorname__c = 'Test', Name__c = 'Kunde', Telefon__c = '123456', 
                                    Kundennummer__c = 10, Produktgruppe__c = 'PG51');
        kd.Betreuer__c = co.id;
        kd.Pflegedienst__c = ac.id;
        
        insert kd;    

        PageReference tpageRef1 = new PageReference('/apex/Anschreiben_Formular_Neu');
        Test.setCurrentPage(tpageRef1);
        ApexPages.currentPage().getParameters().put('id', kd.Id);
        ApexPages.currentPage().getParameters().put('task', 'test');
        ApexPages.currentPage().getParameters().put('retURL', 'test.com');
        ApexPages.currentPage().getParameters().put('rcpt', kd.Id);
        ApexPages.currentPage().getParameters().put('task', 'notask');
        
        RA_nur_anzeigen_ent_controller_class tt = new RA_nur_anzeigen_ent_controller_class(1);
        RA_nur_anzeigen_ent_controller_class t = new RA_nur_anzeigen_ent_controller_class();        
        RA_nur_anzeigen_ent_controller_class t1 = new RA_nur_anzeigen_ent_controller_class(kd.Id);
        
        PageReference tpageRef2 = new PageReference('/apex/Anschreiben_formular_inko_neu');
        Test.setCurrentPage(tpageRef2);
        ApexPages.currentPage().getParameters().put('id', kd.Id);
        ApexPages.currentPage().getParameters().put('task', 'test');
        ApexPages.currentPage().getParameters().put('retURL', 'test.com');        
        ApexPages.currentPage().getParameters().put('rcpt', ac.Id);
        ApexPages.currentPage().getParameters().put('task', 'notask');
        RA_nur_anzeigen_ent_controller_class t2 = new RA_nur_anzeigen_ent_controller_class(kd.Id);
        
        PageReference tpageRef3 = new PageReference('/apex/RA_nur_anzeigen_ent');
        Test.setCurrentPage(tpageRef3);
        ApexPages.currentPage().getParameters().put('id', kd.Id);
        ApexPages.currentPage().getParameters().put('task', 'test');
        ApexPages.currentPage().getParameters().put('retURL', 'test.com');
        ApexPages.currentPage().getParameters().put('rcpt', co.Id);
        ApexPages.currentPage().getParameters().put('task', 'notask');
        RA_nur_anzeigen_ent_controller_class t3 = new RA_nur_anzeigen_ent_controller_class(kd.Id);

        t3.getKunde();
        t3.getAnschrift();
        t3.getKK();
        t3.getAnredeformel();
        t3.getFirmenInfo();
        t3.getRetPage();
        t3.getKdAddr();
        t3.getKdAddrD();
        t3.notask = 'task';
        t3.subject = 'Formular';
        t3.addTask();
        t3.subject = 'Formular_inko';
        t3.addTask();
     
    }
}