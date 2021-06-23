@isTest
public class EditFamilyMember_test {
    static testMethod void myUnitTest() {
        Account a = new Account();
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        Contact con = new Contact();
        con.lastName = 'cunitest';
        insert con;
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        insert opp;
        
        OpportunityContactRole role = new OpportunityContactRole();
        role.contactId = con.id;
        role.role = 'ASP';
        role.opportunityId = opp.id;
        insert role;
        
        //PageReference pRef = Page.EditFamilyMemeberPage;
        //Test.setCurrentPage(pRef);      
        //ApexPages.currentPage().getParameters().put('id', opp.id);
        
        EditFamilyMember efm = new EditFamilyMember(opp.id);
        efm.start();
        efm.getContactOptions();
        efm.getBekannteKrankheitenOptions();
        efm.formatValue('test');
        efm.initiateContactRoles();
        efm.updateContactRoles();
        efm.setSelectedContact();
        efm.abbruchRoles();
        efm.zuOpportunity();
        efm.speichern();
        efm.setPrimary();
        
        efm.abbruch();
    }
    
}