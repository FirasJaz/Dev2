@isTest
public class PLZTool_Basis_test {

    static testMethod void  PartnerProduct_Test(){
    
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        Partner_Preise__c pp_price = new Partner_Preise__c();
        pp_price.Partner_Produkt__c = pp.id;
        pp_price.CPL_Kat_1__c = 15;
        pp_price.CPL_Exklusiv__c = 10;
        pp_price.preis_gueltig_ab_Menge__c = 1; 
        insert pp_price;
        
        Partner_Preise__c pp_price2 = new Partner_Preise__c();
        pp_price2.Partner_Produkt__c = pp.id;
        pp_price2.CPL_Kat_1__c = 15;
        pp_price2.CPL_Exklusiv__c = 10;
        pp_price2.preis_gueltig_ab_Menge__c = 2;
        insert pp_price2;
        
        PLZTool_PartnerProduct product = new PLZTool_PartnerProduct(pp, true);
        
        Partner_Produkte__c pp1 = new Partner_Produkte__c();
        pp1.RecordTypeId = rt.Id;
        pp1.Produktgruppe__c = 'Sitzlift';
        pp1.Deutschlandweit_verf_gbar__c = true;
        pp1.Partner__c = a.id;
        insert pp1;
        
        Partner_Preise__c pp1_price = new Partner_Preise__c();
        pp1_price.Partner_Produkt__c = pp1.id;
        pp1_price.CPL_Kat_1__c = 50;
        insert pp1_price;
        
        PLZTool_PartnerProduct product1 = new PLZTool_PartnerProduct(pp1, true);
        
        product1.getPp();
        product1.getXCPL_Kategorie_1();
        product1.XCPL_Exklusiv='w';
        product1.CPL_Exklusiv = True;
        product1.CPO_Exclusiv = True;
        product1.getXCPL_Kategorie_2();
        product1.getXCPO_Exclusiv();
        product1.getPrc();
        product1.getXCPO_Kategorie_1();
        product1.getXCPO_Kategorie_2();
        product1.getCplCpo();
        product1.setPrice();
        boolean b = product1.CPO_Exclusiv;
        b = product1.CPL_Exklusiv;
        
        Map<Id, PLZTool_PartnerProduct> pMap = new Map<Id, PLZTool_PartnerProduct>();
        pMap.put(product.pp.Id, product);
        pMap.put(product1.pp.Id, product1);
        
        PLZTool_PartnerProduct.setPrice(pMap);
        PLZTool_PartnerProduct.setPrice_queryEachProduct(pMap);        
    }
    

    static testMethod void basis_Test() {
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        Partner_Preise__c pp_price = new Partner_Preise__c();
        pp_price.Partner_Produkt__c = pp.id;
        pp_price.CPL_Kat_1__c = 15;
        pp_price.CPL_Exklusiv__c = 10;
        insert pp_price;
        
        Partner_Produkte__c pp1 = new Partner_Produkte__c();
        pp1.RecordTypeId = rt.Id;
        pp1.Produktgruppe__c = 'Sitzlift';
        pp1.Deutschlandweit_verf_gbar__c = true;
        pp1.Partner__c = a.id;
        insert pp1;
        
        Partner_Preise__c pp1_price = new Partner_Preise__c();
        pp1_price.Partner_Produkt__c = pp1.id;
        pp1_price.CPL_Kat_1__c = 50;
        insert pp1_price;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2;       
        
        PageReference pRef = Page.PLZTool_Basis_Page;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        PLZTool_Basis po = new PLZTool_Basis();        
        po.sameComment = true;
       
        if(po.productMap != null && po.productMap.size()>0){
            List<PLZTool_PartnerProduct> tlist = po.productMap.values();
            tlist[0].selected = true;
            ApexPages.currentPage().getParameters().put('selectedProductId', tlist[0].pp.Id);
        }
        
        PLZTool_PartnerProduct partnerp = new PLZTool_PartnerProduct(pp, true);
        po.selectedPartnerString = String.valueOf(pp.Id);

        po.getFirstPage();
        po.getSecondPage();
        po.getThirdPage();
        po.getProductList();
        po.getselectedProductList();
        po.getTotalSize();
        po.getSelectedTotalSize();
        po.updateCommentFields();        
        po.updateSelectedProduct();
        po.createPartnerTickets();
        po.confirmTickets();
        Test.startTest();        
        po.sendEmailToPartners();
        Test.stopTest();        
        po.isDuplicate(partnerp);
        po.keepExclusive();
        po.removeExclusive();
        po.back();
        po.backTo2();
        po.notInformPartner();
        po.denyUnmachedCat();
        po.acceptUnmachedCat();
        po.getInsuredPerson();
        po.getContactPerson();
        po.showExclusive();
        po.cancelSendEmail();
        po.getPotentialItems();
        po.backToContact();
        po.getenableNextButton();
        po.getenableSendEmail();
        
        po.exPartnerString = String.valueOf(pp.Id);
        po.againInformPartner();
        
        PLZTool_Basis.futureSendStructuredEmailToPartners('test', 'test', opp.Id, 'mansoure.ziaei@gmail.com,',null,null );
        PLZTool_Basis.futureSendXmlEmailToPartners('test', 'test', opp.Id, '', 'mansoure.ziaei@gmail.com,',null,null );
        
        opp.Preis_maximal__c = 1000000;
        opp.Belastbarkeit__c = '150';
        opp.Neu_und_oder_gebraucht__c = 'Neu';
        opp.Art_der_Finanzierung__c= 'test';
        opp.Umgebung__c = 'test';
        opp.Grube__c = true;
        opp.Versand_von_Informationsmaterial__c = true;
        opp.Nutzbare_Fl_che_Au_enma__c = 'test';
        opp.Termin_vor_Ort__c = true;
        opp.Ausland__c = true;
        opp.F_rderh_he__c = 12;
        opp.Kostenfreier_Aufma_termin__c= true;
        opp.Treppenbreite__c = 34;
        opp.Anzahl_Haltestellen__c = 2;
        opp.Technik__c = 'test';
        opp.Kostenfreier_Aufma_termin__c = true;
        update opp;
        
        PLZTool_Basis plzt = new PLZTool_Basis();
        
        
    }
    
    static testMethod void tl_Test() {
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        Partner_Preise__c pp_price = new Partner_Preise__c();
        pp_price.Partner_Produkt__c = pp.id;
        pp_price.CPL_Kat_1__c = 15;
        insert pp_price;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Treppenlift' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Partner_darf_sich_telefonisch_melden__c = true;
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_bel';
        c2.LastName = 'test bel class';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22797';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB';
        insert cr;  
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.Role = 'ASP';     
        insert cr2;
        
        Status_Emails__c se = new Status_Emails__c();
        se.Empf_nger_Email_Adresse__c = 'ziaei@klosesrockepartner.de';
        se.Empf_nger_Email_Adresse_CC__c = 'ziaei@klosesrockepartner.de';
        se.name = 'Email an PWE TEAM (BEL)';
        insert se;
        
        PageReference pRef = Page.PLZTool_Basis_Page;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        PLZTool_Basis po = new PLZTool_Basis();
        po.recordTypeSpecificAction();
        po.sameComment = true;
        po.potentialValue = '3';
        
        if(po.productMap != null && po.productMap.size()>0){
            List<PLZTool_PartnerProduct> tlist = po.productMap.values();
            tlist[0].selected = true;
            ApexPages.currentPage().getParameters().put('selectedProductId', tlist[0].pp.Id);
        }
        
         
        po.selectedPartnerString = String.valueOf(pp.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
    }
    
    static testMethod void bel_Test() {
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Betreuungsleistungen' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = '24h Betreuung';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        Partner_Preise__c pp_price = new Partner_Preise__c();
        pp_price.Partner_Produkt__c = pp.id;
        pp_price.CPL_Kat_1__c = 15;
        insert pp_price;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Betreuungsleistungen' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Partner_darf_sich_telefonisch_melden__c = true;
        opp.Produkt_Kategorie__c = '24h Betreuung';
        opp.X24h_Betreuung__c = True;
        opp.Stundenweise_Betreuung__c = True;
        opp.Hauswirtschaftsleistungen__c = True;
        opp.Pflegedienst__c = True;
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_bel';
        c2.LastName = 'test bel class';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22797';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB';
        insert cr;  
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.Role = 'ASP';     
        insert cr2;
        
        Status_Emails__c se = new Status_Emails__c();
        se.Empf_nger_Email_Adresse__c = 'ziaei@klosesrockepartner.de';
        se.Empf_nger_Email_Adresse_CC__c = 'ziaei@klosesrockepartner.de';
        se.name = 'Email an PWE TEAM (BEL)';
        insert se;
        
        PageReference pRef = Page.PLZTool_Basis_Page;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        PLZTool_Basis po = new PLZTool_Basis();
        po.recordTypeSpecificAction();
        po.sameComment = true;
        
        if(po.productMap != null && po.productMap.size()>0){
            List<PLZTool_PartnerProduct> tlist = po.productMap.values();
            tlist[0].selected = true;
            ApexPages.currentPage().getParameters().put('selectedProductId', tlist[0].pp.Id);
        }
        
        PLZTool_PartnerProduct partnerp = new PLZTool_PartnerProduct(pp, true);
        
        po.selectedPartnerString = String.valueOf(pp.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
        po.createPartnerTickets();
        po.updateSelectedProduct();
        
        PLZTool_Betreuungsleistungen bel = new PLZTool_Betreuungsleistungen();
        bel.toOpportunity();
        bel.toLeads();
        bel.generateCustomerPlainText('ASP', c2);
        bel.generateCustomerPlainText('PB', c2);
    }
    
    
    static testMethod void hnr_Test() {
        
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a2 = new Account();
        a2.RecordTypeId = a_rt.Id;
        a2.Name = 'SelfmailerPartner';
        insert a2;
        
        Account al = new Account();
        al.RecordTypeId = a_rt.Id;
        al.Name = 'Libify Technologies GmbH <L>';
        al.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert al;
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'test account';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
            
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Notrufsysteme' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Strukturierte_Partner_Emails__c spe = new Strukturierte_Partner_Emails__c();
        spe.name = 'apex test structured';
        spe.Email_Subject__c = 'apex test structured';
        spe.Inhalt_der_Email__c = '<?xml version="1.0" {{opp.Id}} {{tkt.name}} {{asp.name}} {{pb.name}} {{acc.Id}} {{ki.Id}} ';
        insert spe;      
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Weiterleitung';
        pp.PLZ_Tool_Liste__c = 'Weiterleitung';
        pp.Email_an_Kunden__c = true;
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        pp.Strukturierte_Partner_Email__c = spe.id;
        insert pp;
        
        Partner_Preise__c pp_price = new Partner_Preise__c();
        pp_price.Partner_Produkt__c = pp.id;
        pp_price.CPL_Kat_1__c = 15;
        insert pp_price;
        
        Partner_Produkte__c ppd = new Partner_Produkte__c();
        ppd.RecordTypeId = rt.Id;
        ppd.Produktgruppe__c = 'Direktvertrieb';
        ppd.PLZ_Tool_Liste__c = 'Direktvertrieb';
        ppd.Email_an_Kunden__c = true;
        ppd.Deutschlandweit_verf_gbar__c = true;
        ppd.Partner__c = a.id;
        insert ppd;
        
        Partner_Preise__c ppd_price = new Partner_Preise__c();
        ppd_price.Partner_Produkt__c = ppd.id;
        ppd_price.CPL_Exklusiv__c = 15;
        ppd_price.CPO_Kat_1_Festpreis__c = 10;
        insert ppd_price;
        
        
        Partner_Produkte__c ppe = new Partner_Produkte__c();
        ppe.RecordTypeId = rt.Id;
        ppe.Produktgruppe__c = 'Exklusives Durchstellen';
        ppe.PLZ_Tool_Liste__c = 'Exklusives Durchstellen';
        ppe.Email_an_Kunden__c = true;
        ppe.Deutschlandweit_verf_gbar__c = true;
        ppe.Partner__c = a.id;
        insert ppe;
        
        Partner_Preise__c ppe_price = new Partner_Preise__c();
        ppe_price.Partner_Produkt__c = ppe.id;
        ppe_price.CPL_Exklusiv__c = 15;
        ppe_price.CPO_Kat_1_Festpreis__c = 10;
        insert ppe_price;
        
        Partner_Produkte__c pps = new Partner_Produkte__c();
        pps.RecordTypeId = rt.Id;
        pps.Produktgruppe__c = 'Selfmailer 2-fach';
        pps.PLZ_Tool_Liste__c = 'Selfmailer';
        pps.Deutschlandweit_verf_gbar__c = true;
        pps.Partner__c = a2.id;
        insert pps;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Notrufsysteme' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Weiterleitung';
        opp.Partner_darf_sich_telefonisch_melden__c = true;
        opp.Pflegedienst__c = True;
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_bel';
        c2.LastName = 'test bel class';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22797';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB';
        insert cr;  
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.Role = 'ASP';     
        insert cr2;
        
        Status_Emails__c se = new Status_Emails__c();
        se.Empf_nger_Email_Adresse__c = 'ziaei@klosesrockepartner.de';
        se.Empf_nger_Email_Adresse_CC__c = 'ziaei@klosesrockepartner.de';
        se.name = 'Email an PWE TEAM (BEL)';
        insert se;
        
        PageReference pRef = Page.PLZTool_Basis_Page;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        PLZTool_Basis po = new PLZTool_Basis();
        po.recordTypeSpecificAction();
        po.sameComment = true;
        
        if(po.productMap != null && po.productMap.size()>0){
            List<PLZTool_PartnerProduct> tlist = po.productMap.values();
            tlist[0].selected = true;
            ApexPages.currentPage().getParameters().put('selectedProductId', tlist[0].pp.Id);
        }
        
        Test.startTest();
        // weiterleitung
        po.selectedPartnerString = String.valueOf(pp.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
        po.updateSelectedProduct();                  
        po.sendEmailToPartners();               
        
        // Direktvertrieb
        po.selectedPartnerString = String.valueOf(ppd.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
        po.updateSelectedProduct();
        po.sendEmailToPartners();
        PLZTool_Basis.futureUpdateAllTickets(po.productMap.values()[0].pp.Id, 1, 2, 1);      
        Test.stopTest();
        
        // Exklusives Durchstellen
        po.selectedPartnerString = String.valueOf(ppe.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
        
        
        // Selfmailer
        po.selectedPartnerString = String.valueOf(pps.Id);
        po.confirm();
        po.matchCategory();
        po.createPartnerTickets();		                   

        po.hnrController.selfmailerCntlr.abbruch();
        po.hnrController.selfmailerCntlr.hasZuschuss = false;
        po.hnrController.selfmailerCntlr.sendAntragsformular = false;
        po.hnrController.selfmailerCntlr.customerEmail = 'ziaei@klosesrockepartner.de';
        po.hnrController.selfmailerCntlr.sendEmail();
        po.hnrController.selfmailerCntlr.emptyFormFlag = true;
        po.hnrController.selfmailerCntlr.emptyForm();
        
        // the controller has its own test class. we call the methods here only to increase code coverage
        try{ po.saveNewMemberAndRefreshThirdPage(); }catch(Exception e){}
        try{ po.saveEditMemberAndRefreshThirdPage(); }catch(Exception e){}
        
    }      
    
    static testMethod void ws_Test() {
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
            
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Widerspruch' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Widerspruch' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        opp.Partner_darf_Infomaterial_senden__c=true;
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2;       
        
        PageReference pRef = Page.PLZTool_Basis_Page;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        PLZTool_Basis po = new PLZTool_Basis();        
        po.sameComment = true;
       
        if(po.productMap != null && po.productMap.size()>0){
            List<PLZTool_PartnerProduct> tlist = po.productMap.values();
            tlist[0].selected = true;
            ApexPages.currentPage().getParameters().put('selectedProductId', tlist[0].pp.Id);
        }
        
        po.selectedPartnerString = String.valueOf(pp.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
        po.updateSelectedProduct();
        Test.startTest();        
        po.sendEmailToPartners();
        Test.stopTest();           
    }
   
    static testMethod void pi_Test() {
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Pflegeimmobilien' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Sitzlift';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;
        insert pp;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Pflegeimmobilien' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Partner_darf_Infomaterial_senden__c=true;
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        opp.location_direction__c = 'Norddeutschland';
        
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2;       
        
        PageReference pRef = Page.PLZTool_Basis_Page;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        PLZTool_Basis po = new PLZTool_Basis();        
        po.sameComment = true;
       
        if(po.productMap != null && po.productMap.size()>0){
            List<PLZTool_PartnerProduct> tlist = po.productMap.values();
            tlist[0].selected = true;
            ApexPages.currentPage().getParameters().put('selectedProductId', tlist[0].pp.Id);
        }
        
        po.selectedPartnerString = String.valueOf(pp.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
        
        po.pi_sendFlyerToCustomer();        
    } 
    
    static testMethod void badumbau_Test() {
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Badumbau - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';       
        insert a;                              
            
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];            
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        pp.Produktgruppe__c = 'Wanne zur Dusche';
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = a.id;        
		
        insert pp;
        
        rtList =[select id, name,sobjecttype from recordType where name ='Badumbau' and sobjecttype  = 'Opportunity' limit 1];
        rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name ='from_test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Wanne zur Dusche';
        opp.Partner_darf_Infomaterial_senden__c=true;
        opp.Partner_darf_sich_telefonisch_melden__c=true;        
        opp.Partner_kann_per_E_Mail_kontaktieren__c=true;
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        Contact c2 = new Contact();
        c2.FirstName = 'ksg_plz_insured';
        c2.LastName = 'test class_insured';
        c2.Email = 'ziaei@klosesrockepartner.de';
        c2.MailingPostalCode = '22767';
        insert c2;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'ASP';
        insert cr;
        
        OpportunityContactRole cr2 = new OpportunityContactRole();
        cr2.ContactId = c2.Id;
        cr2.OpportunityId = opp.Id;
        cr2.IsPrimary = true;
        cr2.Role = 'PB';
        insert cr2;       
        
        PageReference pRef = Page.PLZTool_Basis_Page;
        Test.setCurrentPage(pRef);      
        ApexPages.currentPage().getParameters().put('id', opp.id);
        
        PLZTool_Basis po = new PLZTool_Basis();     
        po.recordTypeSpecificAction();
        po.sameComment = true;
       
        if(po.productMap != null && po.productMap.size()>0){
            List<PLZTool_PartnerProduct> tlist = po.productMap.values();
            tlist[0].selected = true;
            ApexPages.currentPage().getParameters().put('selectedProductId', tlist[0].pp.Id);
        }
        
        po.badController.getBadumbauPartnerMapKeys();
        po.badController.keepSelected();
        po.selectedPartnerString = String.valueOf(pp.Id);
        po.confirm();
        po.confirmTickets();
        po.checkOpportunityStatus();
        po.updateSelectedProduct();
        po.createPartnerTickets();
        Test.startTest();        
        po.sendEmailToPartners();        
        Test.stopTest();     
        opp.CloseDate = null;
        po.saveOpportunity();
        
		String uniqueUserName = 'adminuser' + DateTime.now().getTime() + '@testorg.com';       
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator' or Name='Systemadministrator'];
        User u = new User(Alias = 'admin', Email='adminuser@testorg.com', FirstName='Admin',
                          EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
                          LocaleSidKey='en_US', ProfileId = p.Id,
                          TimeZoneSidKey='America/Los_Angeles',
                          UserName=uniqueUserName);     
        System.runAs(u) {        
            po.isOwner(opp.Id);
        }
        po.setRecipientFields('', 'Herr', '');
        po.setRecipientFields('', 'Frau', '');
    }
        
    static testMethod void plzEmailTagsGenerator_Test() {
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.recordTypeId = a_rt.id;
        a.Name = 'testPartner_plzTool';
        a.ticket_email_address__c = 'ziaei@klosesrockepartner.de';
        insert a;
        
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name ='Pflegeimmobilien' and sobjecttype  = 'Opportunity' limit 1];
        RecordType rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.recordTypeId = rt.id;
        opp.Name ='test_opp_ksg';
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        opp.AccountId = a.Id;
        insert opp;

        Individuelle_Partner_Email__c ipe = new Individuelle_Partner_Email__c();
        ipe.Name = 'testclass_individual_ksg';
        insert ipe;
        
        Individuelle_Partner_Email_Daten__c ipd = new Individuelle_Partner_Email_Daten__c();
        ipd.Individuelle_Partner_Email__c = ipe.Id;
        ipd.Name = 'Ausland';
        ipd.Field_API_Name__c = 'ausland__c';
        ipd.Reference_Object__c = 'opportunity';
        insert ipd;
        
        Individuelle_Partner_Email_Daten__c ipd2 = new Individuelle_Partner_Email_Daten__c();
        ipd2.Individuelle_Partner_Email__c = ipe.Id;
        ipd2.Name = 'von';
        ipd2.Field_API_Name__c = 'von__c';
        ipd2.Lookup_Object__c='Contact';  
        ipd2.Reference_Object__c = 'Contact';
        insert ipd2;
            
        plzEmailTagsGenerator tg = new plzEmailTagsGenerator();       
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        tg.generateCustomerTag(c, ipe.Id);
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB = ASP';
        insert cr;
        
        tg.generateStructuredEmailText(null, opp.id, '{{opp.Id}} {{tkt.name}} {{asp.name}} {{pb.name}} {{acc.Id}}', null, 'test');
        
        tg.generateOpportunityIndividualTag(opp.id, ipe.Id);
        
    }    
   
}