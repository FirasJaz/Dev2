@isTest
private class PLZGebietTool_test {    
    
    static testMethod void myUnitTest(){ 
        List<RecordType> rtList = [select id from Recordtype where Name = 'Pflege.de - Partner'];   
                                   
        Account testAcc = new Account( Name = 'testAccount',
                                   RecordType = rtList[0]);
        
        insert testAcc;                                                                                                                                                       
        
        Partner_Produkte__c testPP1 = new Partner_Produkte__c( Name = 'test1',
                                                               Partner__c = testAcc.Id,
                                                               Produktgruppe__c = 'Hublift');
        
        insert testPP1;
        
        Partner_Produkte__c testPP2 = new Partner_Produkte__c( Name = 'test2',
                                                               Partner__c = testAcc.Id,
                                                               Produktgruppe__c = 'Sitzlift');
        
        insert testPP2;
        
        Partner_PLZ_Gebiet__c testPPG1 = new Partner_PLZ_Gebiet__c(Partner_Produkte__c = testPP1.Id,
                                                                  von__c = 11111,
                                                                  bis__c = 22222);
                                                                  
        insert testPPG1;                                                                  
                                                                  
        Partner_PLZ_Gebiet__c testPPG2 = new Partner_PLZ_Gebiet__c(Partner_Produkte__c = testPP2.Id,
                                                                  von__c = 22222,
                                                                  bis__c = 33333);   
                                                                  
        insert testPPG2; 
        
        Test.setCurrentPageReference(new PageReference('Page.myPage')); 
        System.currentPageReference().getParameters().put('id', testAcc.Id);     
        System.currentPageReference().getHeaders().put('User-Agent', 'Windows'); 
                                                                                                                                      
        ApexPages.StandardController ctr = new ApexPages.StandardController(testAcc);
        PLZGebietTool pgt = new PLZGebietTool(ctr);  
        
        pgt.abbrechen();
        List<PLZGebietTool.Ausloeser> ausListe = new List<PLZGebietTool.Ausloeser>();
        PLZGebietTool.Ausloeser testAus1 = new PLZGebietTool.Ausloeser(testPP1);
        PLZGebietTool.Ausloeser testAus2 = new PLZGebietTool.Ausloeser(testPP2);
        ausListe.add(testAus1);
        ausListe.add(testAus2);
        pgt.ppIdsStr = testPP1.Id + ' ' + testPP2.Id;
        pgt.setAusloeserListe(ausListe);        
        pgt.setAusgwListe(ausListe);
        Blob testDatei1 = Blob.valueof('Von;Bis\r\n21112;21113\r\n44552;44662\r\n33669;44558\r\n45689;78945\r\n22222;33333\r\n11111;22222'); 
        pgt.setContentFile(testDatei1);
        pgt.setNameFile('test'); 
        pgt.getAusgwListe();
        pgt.getAusloeserListe();        
        pgt.getContentFile(); 
        pgt.getNameFile();                      
        pgt.speichern();
        System.currentPageReference().getHeaders().put('User-Agent', 'Mac');
        Blob testDatei3 = Blob.valueof('Von;Bis\r2a112;2b113\r44552;44662\r33669;44558\r45689;78945\r22222;33333\r11111;22222');
        pgt.setContentFile(testDatei3);
        pgt.speichern();
        System.currentPageReference().getHeaders().put('User-Agent', 'Linux');
        Blob testDatei4 = Blob.valueof('Von;Bis\n2a112;2b113\n44552;44662\n33669;44558\n45689;78945\n22222;33333\n11111;22222');
        pgt.setContentFile(testDatei4);
        pgt.speichern();
        System.currentPageReference().getHeaders().put('User-Agent', 'Windows'); 
        Blob testDatei5 = Blob.valueof('Von;Bis\r\n2a112;2b113\r\n44552;44662\r\n33669;44558\r\n45689;78945\r\n22222;33333\r\n11111;22222');
        pgt.setContentFile(testDatei5);
        pgt.speichern();        
        pgt.naechsterSchritt = 'Neue PLZ hinzufügen';
        pgt.plzStatus = 'Ausgeschlossen';
        pgt.speichern();
        pgt.setContentFile(testDatei1);
        pgt.speichern();
        pgt.naechsterSchritt = 'Bestehende PLZ löschen';       
        pgt.speichern();      
        pgt.setContentFile(testDatei5);
        pgt.speichern(); 
        Blob testDatei6 = null;
        pgt.setContentFile(testDatei6);  
        pgt.speichern();                       
    }
    
}