@isTest
private class Lead_zu_Kunde_test {    
    
    static testMethod void neuen_inko_kunden_erstellen_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                  
        
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'Inko',
                                        e_mail__c = 'test@test.de');

        insert testKd;                                        
         
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
                                   
        Lead inkoLead = new Lead( Email = 'inko@inko.de',
                                  Salutation = 'Herr' ,
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  inko_product_id1__c = '1000000000000',
                                  inko_product_id2__c = '2000000000000',
                                  inko_product_id3__c = '3000000000000',
                                  inko_product_id4__c = '4000000000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert inkoLead;                                 
                                                                                                               
        ApexPages.StandardController inkoCtr = new ApexPages.StandardController(inkoLead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(inkoCtr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', inkoLead.id); 
    
        testklasse.konvertieren(); 
        testklasse.kundeMitAuftragErstellen();
        testklasse.aenderungenSpeichern();                        
    }   
    
    static testMethod void neuen_inko_kunden_erstellen_test2(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                  
        
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'Inko',
                                        e_mail__c = 'test@test.de');

        insert testKd;                                        
         
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;  
                                 
        Lead inkoLead = new Lead( Email = 'inko@inko.de',
                                  Salutation = 'Herr' ,
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert inkoLead;                                 
                                                                                                               
        ApexPages.StandardController inkoCtr = new ApexPages.StandardController(inkoLead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(inkoCtr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', inkoLead.id); 
    
        testklasse.konvertieren(); 
        testklasse.kundeMitAuftragErstellen();
        testklasse.aenderungenSpeichern();                        
    }  
    
   static testMethod void neuen_shop_kunden_erstellen_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                  
    
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'shop',
                                        e_mail__c = 'test@test.de');
                                        
        insert testKd;
                                                
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead shopLead = new Lead( Email = 'shop@shop.de',
                                  Salutation = 'Herr' ,
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'Shop',
                                  inko_product_id1__c = '1000000000000',
                                  inko_product_id2__c = '2000000000000',
                                  inko_product_id3__c = '3000000000000',
                                  inko_product_id4__c = '4000000000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert shopLead;                 
        
        Lead_Position__c Leadpos1 = new Lead_Position__c(EAN__c = '1000000000000',
                                                        Lead__c = shopLead.Id,
                                                        Price__c = '4.3',
                                                        Qty_Ordered__c = '15');
        
        insert Leadpos1;                                                               
                                                        
        Lead_Position__c Leadpos2 = new Lead_Position__c(EAN__c = '2000000000000',
                                                        Lead__c = shopLead.Id,
                                                        Price__c = '4.3',
                                                        Qty_Ordered__c = '15');   
                                                        
        insert Leadpos2;                                                                                                                      
                                                                                                               
        ApexPages.StandardController shopCtr = new ApexPages.StandardController(shopLead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(shopCtr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', shopLead.id); 
        
        testklasse.konvertieren(); 
        testklasse.kundeMitAuftragErstellen();                        
    }   
    
    static testMethod void status_update_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                            
        
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'inko',
                                        e_mail__c = 'test@test.de');
                                        
        insert testKd;           
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead updateLead= new Lead( Email = 'update@update.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'Update',
                                  Geburtsdatum__c = '12.01.2010',
                                  OM_Tracking_Order_ID__c = testKd.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert updateLead;                                 
                                                                                                               
        ApexPages.StandardController updateCtr = new ApexPages.StandardController(updateLead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(updateCtr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', updateLead.id); 
    
        testklasse.konvertieren(); 
        testklasse.kundendatenUpdaten();                                
    }   
    
    static testMethod void neuen_shop_auftrag_erstellen_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                  
    
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'shop',
                                        e_mail__c = 'shop@shop.de');
                                        
        insert testKd;                                        
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead shopLead = new Lead( Email = 'shop@shop.de',
                                  Salutation = 'Herr' ,
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'Magento Shop',
                                  inko_product_id1__c = '1000000000000',
                                  inko_product_id2__c = '2000000000000',
                                  inko_product_id3__c = '3000000000000',
                                  inko_product_id4__c = '4000000000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert shopLead;                 
        
        Lead_Position__c Leadpos1 = new Lead_Position__c(EAN__c = '1000000000000',
                                                        Lead__c = shopLead.Id,
                                                        Price__c = '4.3',
                                                        Qty_Ordered__c = '15');
        
        insert Leadpos1;                                                               
                                                        
        Lead_Position__c Leadpos2 = new Lead_Position__c(EAN__c = '2000000000000',
                                                        Lead__c = shopLead.Id,
                                                        Price__c = '4.3',
                                                        Qty_Ordered__c = '15');   
                                                        
        insert Leadpos2;                                                                                                                      
                                                                                                               
        ApexPages.StandardController shopCtr = new ApexPages.StandardController(shopLead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(shopCtr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', shopLead.id); 
        
        testklasse.KdId = testKd.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                       
    }   
    
    static testMethod void AuftragErstellen_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                            
        
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'inko',
                                        e_mail__c = 'test@test.de');
                                        
        insert testKd;           
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead Lead= new Lead( Email = 'test@test.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  Geburtsdatum__c = 'ccccc',
                                  OM_Tracking_Order_ID__c = testKd.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert Lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(Lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', Lead.id); 
        
        testklasse.KdId = testKd.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                                
    }   
    
    static testMethod void AuftragErstellen2_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                            
        
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'PG54',
                                        e_mail__c = 'test@test.de');
                                        
        insert testKd;  
        
        Contact testCont = new Contact (lastname = 'testcontact',                                
                                           Email = 'test@test.de');
        
        insert testCont;  
        
        Kunde__c testKd2 = new Kunde__c( name__c ='testkunde2',
                                        Betreuer__c = testCont.Id,
                                        produktgruppe__c = 'PG54',
                                        e_mail__c = 'test@test.de');
                                        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;  
        Database.SaveResult sr = Database.insert(testKd2, dml);                
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead Lead= new Lead( Email = 'test@test.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  Geburtsdatum__c = 'ccccc',
                                  OM_Tracking_Order_ID__c = testKd.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert Lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(Lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', Lead.id); 
                
        testklasse.KdId = testKd.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                                
    }   
    
    static testMethod void AuftragErstellen3_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                            
        
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'inko',
                                        e_mail__c = 'test@test.de');
                                        
        insert testKd;  
        
        Contact testCont = new Contact (lastname = 'testcontact',                                
                                           Email = 'test@test.de');
        
        insert testCont;  
        
        Kunde__c testKd2 = new Kunde__c( name__c ='testkunde2',
                                        Betreuer__c = testCont.Id,
                                        produktgruppe__c = 'inko',
                                        e_mail__c = 'test@test.de');
                                        
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;  
        Database.SaveResult sr = Database.insert(testKd2, dml);                
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead Lead= new Lead( Email = 'test@test.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  Geburtsdatum__c = 'ccccc',
                                  OM_Tracking_Order_ID__c = testKd.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert Lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(Lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', Lead.id); 
                
        testklasse.KdId = testKd.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                                
    }   
    
    static testMethod void AuftragErstellen4_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                                     
        
        Contact testCont = new Contact (lastname = 'testcontact',                                
                                           Email = 'test@test.de');
        
        insert testCont;  
        
        Kunde__c testKd2 = new Kunde__c( name__c ='testkunde2',
                                        Betreuer__c = testCont.Id,
                                        produktgruppe__c = 'PG54',
                                        e_mail__c = 'test123@test.de');
    
        insert testKd2;                                                       
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead Lead= new Lead( Email = 'test@test.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  Geburtsdatum__c = 'ccccc',
                                  OM_Tracking_Order_ID__c = testKd2.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id1__c = '500er00000000',
                                  inko_product_id2__c = '500er00000000',
                                  inko_product_id3__c = '500er00000000',
                                  inko_product_id4__c = '500er00000000',
                                  inko_product_id5__c = '500er00000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert Lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(Lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', Lead.id); 
                
        testklasse.KdId = testKd2.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                                
    } 
    
    static testMethod void AuftragErstellen5_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                                     
        
        Contact testCont = new Contact (lastname = 'testcontact',                                
                                           Email = 'test@test.de');
        
        insert testCont;  
        
        Kunde__c testKd2 = new Kunde__c( name__c ='testkunde2',
                                        Betreuer__c = testCont.Id,
                                        produktgruppe__c = 'inko',
                                        e_mail__c = 'test123@test.de');
    
        insert testKd2;                                                       
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead Lead= new Lead( Email = 'test@test.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  Geburtsdatum__c = 'ccccc',
                                  OM_Tracking_Order_ID__c = testKd2.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id1__c = '500er00000000',
                                  inko_product_id2__c = '500er00000000',
                                  inko_product_id3__c = '500er00000000',
                                  inko_product_id4__c = '500er00000000',
                                  inko_product_id5__c = '500er00000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert Lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(Lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', Lead.id); 
                
        testklasse.KdId = testKd2.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                                
    } 
    
    static testMethod void AuftragErstellen6_test(){
    
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                            
        
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'PG54',
                                        e_mail__c = 'test@test.de');
                                        
        insert testKd;                        
        
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead Lead= new Lead( Email = 'test@test.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  Geburtsdatum__c = 'ccccc',
                                  OM_Tracking_Order_ID__c = testKd.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id);
        insert Lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(Lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', Lead.id); 
                
        testklasse.KdId = testKd.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                                
    }   
        // SD 2018.07.29 (case 00001616)
       static testMethod void Vorherige_Anfrage_test(){
    /*** SD: I do not know what this part is for. I deactivated it.
        for(integer i= 1; i < 6; i++)
        {
            Decimal j = i*1000000000000.0; 
            Artikel__c art = new Artikel__c( name = string.valueOf(i),
                                                  a_pac_apo_EAN_UPC__c = j,
                                                  EVK__c = 10.0,
                                                  Anlage_4_Preis__c = 0.00);
                                                  
            insert art;                                                  
        }                                                                                                                                                                                                                                                                                                                                                            
     ***/   
           
         // Create new Account record, which will be used later as target for conversion.
         // The main link for finding this account is the email address.
        Kunde__c testKd = new Kunde__c( name__c ='testkunde',
                                        produktgruppe__c = 'PG54',
                                        e_mail__c = 'test@test.de');                       
        insert testKd;                        
        
        // Create new Campaign record. This will be referenced in the Lead record later.
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
           
        /************************************************************************************************
        Create new Opportunity Record. This will be used as 'Vorherige Anfrage' later in the Lead record.
        *************************************************************************************************/
          // retrieve specific record Type ID
          List<RecordType> rtList =[select id, name from recordType where name ='Treppenlift' and SobjectType ='Opportunity' limit 1];
        RecordType rt = rtList [0];
           System.debug('Record Type Id: ' + rt.Id);
           // create new opportunity record
            opportunity opp = new opportunity();
        	opp.Name ='from_test_class';
        	opp.RecordTypeId =rt.Id;
        	opp.StageName = 'Offen';
        	opp.Produkt_Kategorie__c = 'Sitzlift';
            opp.CloseDate = date.today();
        	insert opp;
        
        // Create Lead record. With Opportunity as Vorherige Anfrage ID
        Lead Lead= new Lead( Email = 'test@test.de',
                                  Salutation = 'Herr',
                                  lastname = 'name',
                                  firstname = 'vorname',
                                  Company = 'inko',
                                  Geburtsdatum__c = 'ccccc',
                                  OM_Tracking_Order_ID__c = testKd.Id,
                                  Kostentr_ger__c = 'TKK',
                                  Versicherungsnummer__c = '1000000',
                                  inko_product_id5__c = '5000000000000',
                                  OM_Wizzard_Name2__c = cmp.Id,
                                  Vorherige_Anfrage__c = opp.id   
                           );
        insert Lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(Lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', Lead.id); 
                
        testklasse.KdId = testKd.Id;
        testklasse.Kunde();
        testklasse.cont_Kdlist();
        testklasse.konvertieren(); 
        testklasse.auftragErstellen();                                
    }   
    
    static testMethod void test(){
     
        Campaign cmp = new Campaign();
        cmp.name = 'testclass_ksg';
        insert cmp;
        
        Lead lead = new Lead( Email = 'inko@inko.de',
                salutation = 'Herr',
                                  lastname = 'name',
                                  Company = 'Shop',
                                  OM_Wizzard_Name2__c = cmp.Id);
        
        insert lead;                                 
                                                                                                               
        ApexPages.StandardController Ctr = new ApexPages.StandardController(lead);
        Lead_zu_Kunde testklasse = new Lead_zu_Kunde(Ctr);  
    
        PageReference pRef1 = Page.Lead_zu_Kunde_Seite;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('id', lead.id); 
        
        testklasse.getKdlist();     
        testklasse.zurueck();
        testklasse.getInsert_kunde_error();
        testklasse.getzeilenlist(); 
        testklasse.getNeuZeilenlist();                          
    }   
    
}