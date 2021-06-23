@isTest
public class Change_Owner_To_IT_SUPPORT_LD_test {
   
    static testMethod void myUnitTest() {
        Campaign cmp = new Campaign(name ='testCMp');
        insert cmp;
        
        Lead lead = new Lead();
        lead.LastName ='test';
        lead.Salutation = 'Herr';
        Lead.Company='Notrufsysteme';
        lead.OM_Wizzard_Name2__c = cmp.Id;
        insert lead;
        
        
        ApexPages.StandardController sc = new ApexPages.standardController(lead);
        PageReference pRef = Page.Change_Owner_To_IT_SUPPORT_Ld;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', lead.id);
        Change_Owner_To_IT_SUPPORT_LD co = new Change_Owner_To_IT_SUPPORT_LD(sc);
        
        co.Change_owner();
    }
}