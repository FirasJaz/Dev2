@isTest
private class Brief_schreiben_controller_class_test {
    static testMethod void myUnitTest() {
        Account KK = new Account();
        KK.Industry = 'Krankenkassen';
        KK.Name = 'Krankenkasse';
        KK.type = 'TestKrK';
        
        insert KK;
        Kunde__c kd = new Kunde__c (Krankenkasse__c = kk.id, Name__c = 'Muster', Produktgruppe__c='PG54');
        kd.e_mail__c = 'test@test.com';
        insert kd;
        
        Anschrift__c neu = new Anschrift__c();
        neu.Standardlieferanschrift__c = true;
        neu.Standardrechnungsanschrift__c = true;
        neu.Art_der_Anschrift__c = 'Kundenadresse';
        neu.Kunde__c = kd.ID;
        insert neu;
        

        
        ApexPages.StandardController con = new ApexPages.StandardController(kd);
        Brief_schreiben_controller_class ext = new Brief_schreiben_controller_class(con);       
        PageReference pRef = Page.Brief_schreiben_Form;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', kd.id);   
        try {
            ext.processBriefSchreiben();
        }
        catch (System.Exception e) {}
        
        
        ext.getKunde();
        ext.Brief_schreiben_Pdf();
        //ext.perEmail();
        ext.setLeereZeilen();
        ext.createTask();
        ext.createTaskEmail();
        ext.GotoTemplateSelect();
        ext.getselRCPT();
        ext.getSelectedRcpt();
        ext.getUser();
        ext.setSelectedRcpt('rtcpt');
        ext.getadr();
        ext.gethasMail();
        
        ext.zurueck();
        
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {                
            try {
                EmailTemplate mt = new EmailTemplate(Name='AM test', DeveloperName='AM_test',  TemplateType='text', isActive = true, FolderId = UserInfo.getUserId(), Subject ='test');
                insert mt;
                ApexPages.StandardController con2 = new ApexPages.StandardController(kd);
                Brief_schreiben_controller_class ext2 = new Brief_schreiben_controller_class(con2);     
                PageReference pRef2 = Page.Brief_schreiben_Form;
                Test.setCurrentPage(pRef2);     
                ApexPages.currentPage().getParameters().put('id', kd.id);   
                ApexPages.currentPage().getParameters().put('etid', mt.id); 
                ext2.processBriefSchreiben();  
            }
            catch (System.Exception e) {}           
            } 
    }
}