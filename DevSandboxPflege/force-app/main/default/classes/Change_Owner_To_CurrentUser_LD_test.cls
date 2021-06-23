@isTest
public class Change_Owner_To_CurrentUser_LD_test {
    
    static testMethod void myUnitTest() {
    
        Campaign cmp = new Campaign(name ='testCMp');
        insert cmp;
        
        Lead lead = new Lead();
        lead.LastName ='test';
        Lead.Company='Notrufsysteme';
        lead.Salutation = 'Herr';
        lead.OM_Wizzard_Name2__c = cmp.Id;
        
        insert lead;
        
        ApexPages.StandardController sc = new ApexPages.standardController(lead);
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Lead;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', lead.id);
        Change_Owner_To_CurrentUser_Ld co = new Change_Owner_To_CurrentUser_Ld(sc);
        
        co.Change_owner();
    }
    
    static testMethod void myUnitTest_ownerIsITUser() {
    
        List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        
        Campaign cmp = new Campaign(name ='testCMp');
        insert cmp;
        
        Lead lead = new Lead();
        lead.Salutation = 'Herr';
        lead.LastName ='test';
        Lead.Company='Notrufsysteme';
        lead.OM_Wizzard_Name2__c = cmp.Id;
        if(user_list != null && user_list.size()>0){
            lead.ownerID= user_list[0].id;
        }
        
        insert lead;
        
        ApexPages.StandardController sc = new ApexPages.standardController(lead);
        PageReference pRef = Page.Change_Owner_To_CurrentUser_Lead;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', lead.id);
        Change_Owner_To_CurrentUser_Ld co = new Change_Owner_To_CurrentUser_Ld(sc);
        
        co.Change_owner();
    }

}