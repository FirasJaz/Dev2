@isTest
public class Upload_monatsabrechnung_test {
   
    static testMethod void myUnitTest() {
         List<RecordType> artList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'account' limit 1];
        RecordType artid = artList [0];       
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        a.recordTypeId = artid.id;
        insert a;
        
        //partner p = new partner();
        //insert p;
            
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        //pp.RecordType = new RecordType();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        //opp.RecordType = new RecordType();
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2; 

        Partner_Ticket__c pt = new Partner_Ticket__c(Opportunity__c = opp.id, Partner__c=a.id, Partner_Produkt__c=pp.id, Status_CPO__c = 'Übermittelt', Wert_des_Partner_Tickets_CPO__c = 10.0);
        insert pt;

        list<Partner_Ticket__c> ptList = [SELECT id, name, Partner_Produkt__r.name, Status_CPL__c, Status_CPO__c, Wert_des_Partner_Tickets_Gesamt__c, createddate,
                                Ticket_vom_Partner_storniert__c, Wert_des_Partner_Tickets_CPL__c, Wert_des_Partner_Tickets_CPO__c
                            FROM Partner_Ticket__c]; 
        string ptname = ptList[0].name;
        
        PageReference pRef1 = Page.Upload_monatsabrechnung;

        Test.setCurrentPage(pRef1);
        ApexPages.StandardController con1 = new ApexPages.StandardController(a);
        Upload_monatsabrechnung ext1 = new Upload_monatsabrechnung(con1);  
        
        ext1.contentFile = blob.valueOf(ptname + ';positive ; 10,0\r\nPT-0000001;positive ; 10,0');
        
        ext1.upload();
        ext1.speichern();
        ext1.zurueck();
        ext1.abbrechen();
        ext1.getNameFile();
        ext1.setNameFile('test');
        ext1.getContentFile();
        ext1.setContentFile(blob.valueOf(ptname + ';positive ; 10,0\r\nPT-0000001;positive ; 10,0'));
        ext1.getptList();
    }
        
}