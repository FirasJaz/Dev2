@isTest
public class StructuredPartnerEmailTest {
    
    static testMethod void myUnitTest() {
        
        Strukturierte_Partner_Emails__c st = new Strukturierte_Partner_Emails__c();
        st.name = 'test st email';
        st.Inhalt_der_Email__c = '{{opp.Id}} {{tkt.name}} {{asp.name}} {{pb.name}} {{acc.Id}}';
        insert st;
        
        PageReference pRef = Page.StructuredPartnerEmail;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', st.id);
        ApexPages.StandardController sc = new ApexPages.standardController(st);
        StructuredPartnerEmail se = new StructuredPartnerEmail(sc);
        
        se.getObjList();
        se.getFieldList();
        se.refreshFieldMap();
        se.Speichern();
    }
}