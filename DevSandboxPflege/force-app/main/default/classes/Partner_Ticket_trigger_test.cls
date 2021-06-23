@isTest(seealldata=false)
private class  Partner_Ticket_trigger_test {
    static testMethod void myTest1() {
        test.starttest();
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'account' limit 1];
        RecordType rt = rtList [0];         
        
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.RecordTypeId = rt.Id;
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;

        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        rt = rtList [0];  
        
        Partner_Produkte__c pp = new Partner_Produkte__c();     
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;      
        
        
        rtList =[select id, name,sobjecttype from recordType where name ='Betreuungsleistungen' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2018, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Partner_darf_Infomaterial_senden__c = true;
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        
        insert opp;
        
        list<Partner_Ticket__c> ptList = new list<Partner_Ticket__c>();
        for(integer i = 0; i < 100; i++) {
            Partner_Ticket__c pt = new Partner_Ticket__c();
            pt.Partner__c = a.id;
            pt.Partner_Produkt__c = pp.id;
            pt.Opportunity__c = opp.id;
            ptList.add(pt);
        }
        test.stoptest();
        insert ptList;

        list<Partner_Produkte__c> pptList = [SELECT Kontingent_Auslastung__c FROM Partner_Produkte__c WHERE id = : pp.id];
        integer ka = (integer)pptList[0].Kontingent_Auslastung__c;
        System.assertEquals(100,ka);
        

        ptList = [SELECT id, Ticket_vom_Partner_storniert__c FROM Partner_Ticket__c WHERE Partner_Produkt__c = :pp.id];

        for(Partner_Ticket__c pt : ptList) {
            pt.Ticket_vom_Partner_storniert__c = true;
        }
        update ptList;

        pptList = [SELECT Kontingent_Auslastung__c FROM Partner_Produkte__c WHERE id = : pp.id];
        ka = (integer)pptList[0].Kontingent_Auslastung__c;
        System.assertEquals(0,ka);        



        delete ptList;


    
    }
}