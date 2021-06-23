@isTest
public class NachtelefonieZeitpunkt2_test {
    
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
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        nt.Anzahl_der_Versuche__c = 3;
        insert nt;        
        
        PageReference pRef = Page.NachtelefonieZeitpunkt2;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);
        NachtelefonieZeitpunkt2 nz = new NachtelefonieZeitpunkt2();

        nz.setZeitCheckbox(true);
        nz.getZeitCheckbox();
        nz.setZeitCheckbox4Tagen(false);
        nz.getZeitCheckbox4Tagen();
        nz.getFormObj();
        nz.getDummyObj1();
        nz.getDummyObj2();
        nz.erreicht();
        nz.nichtErreicht();
        nz.getItems();
        nz.getCatItems();
        nz.getNextTimeframe();
        nz.getNextPreferredTimeframe('18:00');
        nz.getMorningTimeFrameIn4Days();
        nz.setSelectedCategory('1');
        nz.getSelectedCategory();
        nz.getSelectedTimeFrame('1');
        nz.updateOpportunitystatus();
        nz.neNextFrame();
        nz.selectedTime = '1';
        nz.neGivenFrame();
        Nachtelefonie__c nd1 = new Nachtelefonie__c();
        nd1.F_lligkeitsdatum__c = Datetime.now().addDays(1);
        nz.dummyObj1 = nd1;
        nz.neTermin();
        nz.selectedTimeErreicht= '1';
        nz.eGivenFrame();
        Nachtelefonie__c nd2 = new Nachtelefonie__c();
        nd2.F_lligkeitsdatum__c = Datetime.now().addDays(1);
        nz.dummyObj2 = nd2;
        nz.eTermin();
        nz.isOwner = true;
        nz.Speichern();
        nz.ne4Tagen();
        nz.eKat2Grund();
        nz.eKat2();

        nz.zuNachtelefonie();
        try{
            nz.sendEmailToCustomer();
        }catch(Exception e){
            System.debug('exception in method call');      
        }
        
        ApexPages.currentPage().getParameters().put('id', opp.id);
        NachtelefonieZeitpunkt2 nz2 = new NachtelefonieZeitpunkt2();
        nz2.selectedCategory = '2';
        nz2.updateOpportunitystatus();
        nz2.zuOpportunity();
        nz.isOwner = true;
        nz2.speichern();
        
        
    }
    
    static testMethod void myUnitTest2() {
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
        
        Nachtelefonie__c nt = new Nachtelefonie__c();
        nt.Opportunity__c = opp.Id;
        nt.Anzahl_der_Versuche__c = 3;
        insert nt;        
        
        PageReference pRef = Page.NachtelefonieZeitpunkt2;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', nt.id);
        NachtelefonieZeitpunkt2 nz = new NachtelefonieZeitpunkt2();
        nz.nichtErreichtCheckBox = true;
        nz.zeitCheckbox = false;
        nz.selectedTime = '0';
        nz.setZeitCheckbox4Tagen(false);
        nz.isOwner = true;
        nz.Speichern();
        
        nz.setZeitCheckbox4Tagen(true);
        nz.nichtErreichtCheckBox = true;
        nz.zeitCheckbox = false;
        nz.selectedTime = '0';
        nz.isOwner = true;
        nz.Speichern();
    }
}