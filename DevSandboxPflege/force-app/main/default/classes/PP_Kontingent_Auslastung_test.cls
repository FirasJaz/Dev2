@isTest
private class PP_Kontingent_Auslastung_test {
    
    public static testMethod void testBatch_pro_Tag() {
        Account a = new Account();
        a.Name = 'testbatch';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        pp.Kontingent_pro_Tag__c = 5;
        pp.Kontingent_Auslastung_pro_Tag__c = 4;
        insert pp;
       
        Test.startTest();
        PP_Kontingent_Auslastung_Pro_Tag_start mobject = new PP_Kontingent_Auslastung_Pro_Tag_start();
        String sch = '0 0 5 * * ?';
        system.schedule('Schedule TEST', sch, mobject);
        Test.stopTest();
 
    }
    
    public static testMethod void testBatch_pro_Woche() {
        Account a = new Account();
        a.Name = 'testbatch';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        pp.Kontingent_pro_Woche__c = 5;
        pp.Kontingent_Auslastung__c = 4;
        insert pp;
        
        Test.startTest();
        PP_Kontingent_Auslastung_Pro_Woche_start mobject = new PP_Kontingent_Auslastung_Pro_Woche_start();
        String sch = '0 0 5 * * ?';
        system.schedule('Schedule TEST', sch, mobject);
        Test.stopTest();
 
    }
    
    public static testMethod void testBatch_pro_Monat() {
        Account a = new Account();
        a.Name = 'testbatch';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        pp.Kontingent_pro_Monat__c = 5;
        pp.Kontingent_Auslastung_pro_Monat__c = 4;
        insert pp;
       
        Test.startTest();
        PP_Kontingent_Auslastung_Pro_Monat_start mobject = new PP_Kontingent_Auslastung_Pro_Monat_start();
        String sch = '0 0 5 * * ?';
        system.schedule('Schedule TEST', sch, mobject);
        Test.stopTest();
 
    }
    
}