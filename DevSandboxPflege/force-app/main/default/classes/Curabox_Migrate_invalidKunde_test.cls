@isTest
public with sharing class Curabox_Migrate_invalidKunde_test {
    public static testmethod void test() {  
        Account a = new Account(Name = 'Test KK');
        a.Industry='Krankenkassen';
        insert a;
        Account p = new Account(Name = 'Pflegedienst Test');
        p.Industry='Pflegedienste';
        
        List<RecordType> rt = [Select Id, Name From RecordType Where SobjectType = 'Account' and Name = 'X01' LIMIT 1];
        if((rt != null) && (rt.size() > 0)){
            String strRecordTypeId = String.valueOf(rt[0].Id);
//          p.RecordtypeID = '012m00000004J06';
            p.RecordtypeID = rt[0].id;
        
        }
        insert p;
        
        Kunde__c kd = new Kunde__c( Krankenkasse__c = a.ID, Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        insert kd;
        
        Anschrift__c neu3 = new Anschrift__c();
        neu3.Standardlieferanschrift__c = true;
        neu3.Art_der_Anschrift__c = 'Betreuer';
        neu3.Kunde__c = kd.ID;
        insert neu3;
        
        list<RecordType> fam_rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
        list<RecordType> con_rtList = [SELECT Id FROM RecordType WHERE Name = 'Familienangehörige'];
        Account testFamilie = new Account(RecordTypeId = fam_rtList[0].id, Name = 'Mustermann - Familie');
        insert testFamilie;
        Contact testContact = new Contact( 
            RecordTypeId = con_rtList[0].id,
            lastname = 'Mustermann kunde',
            firstname = 'test_firstname',
            AccountId = testFamilie.Id,
            Email = 'test@test.de',
            Phone = '0123456789',
            MailingStreet = 'contactstreet',
            MailingPostalCode='23456',
            MailingCity='contactcity',
            //Kranken_Pflegekasse__c=KK.id,
            Versicherungsnummer__c='VERSNR01234567',
            Birthdate=date.today().addYears(-60)
            //Wunschbox__c = cbList[cb].id,
            //Art_des_Kontakts__c = 'Pflegebedürftige',
            //Pflegedienst__c = PD.id
            // Art_Von_Handschuhe__c=p1.id
            );
         insert testContact;
         Contact testContact2 = new Contact( 
            RecordTypeId = con_rtList[0].id,
            lastname = 'Mustermann2 kunde',
            firstname = 'test_firstname',
            AccountId = testFamilie.Id,
            Email = 'test@test.de',
            Phone = '0123456789',
            MailingStreet = 'contactstreet',
            MailingPostalCode='13456',
            MailingCity='contactcity',
            //Kranken_Pflegekasse__c=KK.id,
            Versicherungsnummer__c='VERSNR01234567',
            Birthdate=date.today().addYears(-60),
            Betreuer__c = testContact.id
            //Wunschbox__c = cbList[cb].id,
            //Art_des_Kontakts__c = 'Pflegebedürftige',
            //Pflegedienst__c = PD.id
            // Art_Von_Handschuhe__c=p1.id
            );
         insert testContact2; 
         
         ID batchprocessid = Database.executeBatch(new Curabox_Migrate_invalidKunde(), 200);
    
    }
}