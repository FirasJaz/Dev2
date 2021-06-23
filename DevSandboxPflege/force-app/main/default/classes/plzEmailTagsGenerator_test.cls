@isTest
private class plzEmailTagsGenerator_test {

    static testMethod void myUnitTest() {   
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        Opportunity opp = new Opportunity();
        opp.closeDate = Date.today();
        opp.AccountId = a.id;
        opp.Name = 'test Opportunity';
        opp.stageName = 'Offen';
        opp.ForecastCategoryName = 'Omitted';
        
        insert opp;
        
        Kunden_Interesse__c ki = new Kunden_Interesse__c();
        ki.opportunity__c = opp.Id;

        insert ki;                
        
       // plzEmailTagsGenerator.prepareHnrDVBody('testValue', pp, opp.id);
       // plzEmailTagsGenerator.generatePartnerPlainText(new List<Partner_Produkte__c>{pp});
       // plzEmailTagsGenerator.generatePartnerListTag(new List<Partner_Produkte__c>{pp});
       // plzEmailTagsGenerator.setOpportunityFields(opp.id, '');
    }
}