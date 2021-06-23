@isTest
public class Monatsauflistung_test {
   
  static testMethod void myUnitTest() {
      
      	List<RecordType> rtList =[select id, name,sobjecttype from recordType where sobjecttype  = 'account' and  name ='Pflege.de - Partner' limit 1];
        RecordType rt = rtList [0];
      	
        Account acc= new Account();
      	acc.RecordTypeId = rt.Id;
        acc.name = 'Monatsauflistung_test_ksg';
        acc.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert acc;
      
      	Contact c = new Contact();
      	c.lastname = 'auflistung_test_c';
      	c.Email = 'ziaei@klosesrockepartner.de';
      	c.Empf_nger_der_monatlichen_Auflistung__c = true;
      	c.AccountId = acc.Id;
      	insert c;
      
      	rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        //pp.RecordType = new RecordType();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = acc.Id;
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
      
      	OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB = ASP';
        insert cr; 
      
        Partner_Ticket__c pt = new Partner_Ticket__c();
      	pt.Status_CPL__c = 'Abrechenbar';
      	pt.Partner__c = acc.Id;
      	pt.Opportunity__c = opp.Id;
      	insert pt;
            
      	
      
        ApexPages.StandardController sc = new ApexPages.standardController(acc);
        PageReference pRef = Page.Individual_partner_invoicing;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', acc.id);
        Monatsauflistung ma = new Monatsauflistung(sc);
        ma.timePeriodValue = '2';
        ma.startAuflistung();
      	ma.timePeriodValue = '1';
      	ma.startAuflistung();
      	ma.timePeriodValue = '0';
      	ma.startAuflistung();
      	ma.getTimePeriodItems();
      	ma.zurueck();
  }
  
}