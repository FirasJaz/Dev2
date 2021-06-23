@isTest
public class Rueckmeldung_benoetigt_test {

    static testMethod void myUnitTest() {
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        if(rtList != null && rtList.size()>0){
            opp.RecordTypeId = rtList[0].Id;
        }
        
        insert opp;
        
        Contact c = new Contact();
        c.LastName='test ksg__Rueckmeldung_benoetigt';
        c.Email = 'ziaei@klosesrockepartner.de';
        insert c;
        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.OpportunityId = opp.id;
        ocr.Role = 'PB = ASP';
        ocr.ContactId = c.id;
        insert ocr;
            
        
        ApexPages.StandardController sc = new ApexPages.standardController(opp);
        PageReference pRef = Page.Rueckmeldung_benoetigt;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        Rueckmeldung_benoetigt rb = new Rueckmeldung_benoetigt(sc);
        
        rb.getPickListValuesIntoList();
        
        try{
            rb.selectedCause = 'fake Telefonnummer / Telefonnummer nicht ausgefüllt';
            rb.start_rueckmeldung();
        }catch(Exception e){
            system.debug('method returned an exception::' + e.getMessage());
        }
    }
}