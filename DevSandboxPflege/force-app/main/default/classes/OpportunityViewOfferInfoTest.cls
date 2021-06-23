/****************************************************************************************************************************
// Created 13.07.2018 von  MS
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Description:       
//	Test for OpportunityViewOfferInfo
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class OpportunityViewOfferInfoTest {
	static testMethod void opportunityHasAbrechnungsunterlagen() {
        Opportunity o1 = new Opportunity();
        o1.Name ='from_test_class';
        o1.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        o1.CloseDate = myDateTime.date();
        insert o1;
        
        Offer__c a = new Offer__c();
        a.Opportunity__c = o1.id;
        insert a;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(o1);
        OpportunityViewOfferInfo OpViAbIn = new OpportunityViewOfferInfo(sc);
        
        PageReference pRef = Page.OpportunityViewOfferInfo;
        Test.setCurrentPage(pRef);
        ApexPages.currentPage().getParameters().put('id', o1.id);
    }

    static testMethod void opportunityHasNoAbrechnungsunterlagen() {
        Opportunity o1 = new Opportunity();
        o1.Name ='from_test_class';
        o1.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        o1.CloseDate = myDateTime.date();
        insert o1;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(o1);
        OpportunityViewOfferInfo OpViAbIn = new OpportunityViewOfferInfo(sc);
        
        PageReference pRef = Page.OpportunityViewOfferInfo;
        Test.setCurrentPage(pRef);
        ApexPages.currentPage().getParameters().put('id', o1.id);
        
    }
}