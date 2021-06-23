@isTest
public class IndividualPartnerInvoicing_test {
  static testMethod void myUnitTest() {
 List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType rt = rtList [0];
      
        Account acc= new Account();
        acc.name = 'Monatsauflistung_test_ksg';
        acc.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        acc.RecordTypeId = rt.id;
        insert acc;
      
        Partner_Produkte__c product = new Partner_Produkte__c();
        product.Partner__c = acc.Id;
        product.Produktgruppe__c = 'Sitzlift';
        insert product;
        
        Partner_Preise__c price = new Partner_Preise__c();
        price.CPO_Kat_1_Festpreis__c = 50.00;
        price.CPO_Exklusiv_Festpreis__c = 50.00;
        price.Partner_Produkt__c = product.Id;
        price.preis_gueltig_ab_Menge__c = 1;
        insert price;
        
        Contact c = new Contact();
        c.lastname = 'ziaei_Monatsauflistung_test';
        c.salutation = 'Herr';
        c.Empf_nger_der_monatlichen_Auflistung__c = true;
        c.email = 'ziaei@klosesrockepartner.de';
        c.AccountId = acc.id;
        insert c;
      
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        insert opp;
      
        Partner_Ticket__c pt = new Partner_Ticket__c();
        pt.Partner__c = acc.id;
        pt.Status_CPO__c= 'Abrechenbar';
        pt.Status_CPL__c = 'Abrechenbar';
        pt.opportunity__c = opp.id;
        pt.Auftragswert_Partner__c = 100.00;
        pt.Partner_Produkt__c = product.Id;
        pt.Preis_Kategorie_der_Opportunity__c = '1';
        pt.Wert_des_Partner_Tickets_CPO__c = 100.00;
        insert pt;
                        
        ApexPages.StandardController sc = new ApexPages.standardController(acc);
        PageReference pRef = Page.Individual_partner_invoicing;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', acc.id);
        IndividualPartnerInvoicing pi = new IndividualPartnerInvoicing(sc);
      
      
        try{
            pi.startInvoicing();
        }catch(Exception e){
            system.debug(e.getMessage());
        }
      
        pi.zurueck();
        pi.getPlist();
        IndividualPartnerInvoicing.getTimePeriodItems();
    }
}