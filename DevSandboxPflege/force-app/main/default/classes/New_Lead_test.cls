@isTest
public class New_Lead_test {
    
    static testMethod void myUnitTest() {
        //PageReference pRef = Page.NachtelefonieZeitpunkt2;
        //Test.setCurrentPage(pRef);
        Contact con = new Contact();
        con.lastname = 'tester';
        con.Salutation = 'Herr';
        insert con;
        
        NewLead ntl = new NewLead();
        ntl.contact = con;
        ntl.getArtItems();
        ntl.setRecordType();
        ntl.zuLeads();
        ntl.formObj.LastName = 'test_newLead';
        Campaign c = new Campaign();
        c.Name = 'test_campaign';
        insert c;
        ntl.formObj.OM_Wizzard_Name2__c = c.id;
        ntl.speichern();
        ntl.getMessage_layout();
        
        
        ntl.ModalDialogLayout = 'none';
        ntl.formatValue('[Hausnotruf, Mobile Notruflösung]');
        ntl.formatValue('[Hausnotruf]');
        ntl.betreuungOptions = ntl.getProductGroupBEL();
        ntl.getProductGroupHNR();
        ntl.getProductGroupTL();
        ntl.getBetreuung();
        ntl.getProductGroupWS();
        ntl.getProductGroupPI();
        ntl.getLocations();
        ntl.checkSelectedValue();                     
    }
    
}