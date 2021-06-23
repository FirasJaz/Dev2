@isTest
public class IndividuellePartnerEmail_lghtng_test {
	static testMethod void myUnitTest() {
        Individuelle_Partner_Email__c ipe = new Individuelle_Partner_Email__c();
        ipe.Name = 'testclass_individual_ksg';
        insert ipe;
                
        PageReference pRef = Page.IndividuellePartnerEmailFieldEditlghtng;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', ipe.id);
        IndividuellePartnerEmailFieldEdit_lghtng ie = new IndividuellePartnerEmailFieldEdit_lghtng();
        
        ie.onRecordTypeChange();
        ie.Speichern();
        ie.Abbruch();
        ie.getContactFields();
        ie.getOpportunityFields();
        
    }
}