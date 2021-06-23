@isTest
private class Preislisteneintrag_test {

    static testMethod void myPlTest() {
        Artikel__c testArt = new Artikel__c ();
        Preislisteneintrag__c testPLE = new Preislisteneintrag__c ();
        Account KK = new Account();
        ID artID = null;
        KK.Industry = 'Krankenkassen';
        KK.Name = 'Test KK';
        insert KK;
        
        testArt.Name = 'Test Artikel';
        testArt.a_pac_apo_Apo_EK__c = 100;
        testArt.a_pac_apo_Apo_EK__c = 100;
        testArt.a_pac_apo_Apo_VK__c = 10000;
        testArt.EEK__c = 100;
        testArt.EVK__c = 100;
        testArt.a_pac_apo_Mwst__c ='1';
        insert testArt;
        testPLE.Krankenkasse__c = KK.Id;
        testPLE.Artikel__c = testArt.Id;
        testPLE.Preis_faktor__c = 10;
        testPLE.Preis_berechnungsart__c = 'Prizent';
        testPLE.Preisgrundlage__c = 'AEK';
        testPLE.Preis_netto__c = 300;
        insert testPLE;
        
        testArt.a_pac_apo_Apo_EK__c = 200;
        
        update testArt;
        
        testArt.a_pac_apo_Apo_EK__c = 20000;
        
        update testArt;
        
        testArt.a_pac_apo_Apo_VK__c = 20000;
        
        update testArt;
        
        testArt.EEK__c = 200;
        
        update testArt;
        
        testArt.EVK__c = 200;
        
        update testArt;
// ple



        
        List<Preislisteneintrag__c> prList = [
        SELECT Preis_netto__c
        FROM Preislisteneintrag__c
       // WHERE ID =: testPLE.id     
       WHERE Preisgrundlage__c =: 'AEK' 
        ];  
        system.debug('############# select Preislisteneintrag : '+prList.size());
        if (prList != null && prList.size() != 0){
            for(Integer p = 0; p < prList.size(); p++) {    
                prList.get(p).Preis_netto__c = 600;
                prList.get(p).Preisgrundlage__c = 'EVK';
            }
            try {
                //system.debug('############# update Preislisteneintrag : '+prList.size());
                update prList;
            }
            catch (system.dmlexception d) {         
                system.debug('############# update Preislisteneintrag error: '+d);
            } 
 
        testArt.EVK__c = 300;
        
        update testArt;  
        }
                  
        List<Preislisteneintrag__c> prList2 = [
        SELECT Preis_netto__c
        FROM Preislisteneintrag__c
       // WHERE ID =: testPLE.id     
       WHERE Preisgrundlage__c =: 'EVK' 
        ];  
        system.debug('############# select Preislisteneintrag : '+prList2.size());
        if (prList2 != null && prList2.size() != 0){       
            
            for(Integer p = 0; p < prList2.size(); p++) {    
                prList2.get(p).Preis_netto__c = 800;
                prList2.get(p).Preisgrundlage__c = 'EEK';
                
            }
            try {
                //system.debug('############# update Preislisteneintrag : '+prList.size());
                update prList2;
            }
            catch (system.dmlexception d) {         
                system.debug('############# update Preislisteneintrag error: '+d);
            }     
        testArt.EEK__c = 250;
        
        update testArt;       
           
        }
        
        List<Preislisteneintrag__c> prList3 = [
        SELECT Preis_netto__c
        FROM Preislisteneintrag__c
       // WHERE ID =: testPLE.id     
       WHERE Preisgrundlage__c =: 'EEK' 
        ];  
        system.debug('############# select Preislisteneintrag : '+prList3.size());
        if (prList3 != null && prList3.size() != 0){       
            
            for(Integer p = 0; p < prList3.size(); p++) {    
                prList3.get(p).Preis_netto__c = 800;
                prList3.get(p).Preisgrundlage__c = 'AVK';
                
            }
            try {
                //system.debug('############# update Preislisteneintrag : '+prList.size());
                update prList3;
            }
            catch (system.dmlexception d) {         
                system.debug('############# update Preislisteneintrag error: '+d);
            }     
        testArt.a_pac_apo_Apo_VK__c = 15000;
        
        update testArt;       
           
        }
        
        
        Decimal nnp = 0;
        
        
        
                

        
        
        
        
        
    }   
    
    

}