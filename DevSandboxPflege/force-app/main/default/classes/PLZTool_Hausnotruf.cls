/********************************************************************************************************************************************
//  Erstellt 28.03.2017 von MZ
//                      Klose und Srocke Gesellschaft für kreative KonfliktlÃ¶sungen mbH
//                      Mindelweg 11
//                      22393 Hamburg 
//                      Tel.:  04064917161
//                      Fax.: 04064917162
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter: opportunityId
//
//********************************************************************************************************************************************
//
//  Beschreibung: 
//      to separate the "Hausnotruf" special functionalities in PLZ_Tool  
//
//********************************************************************************************************************************************
//  Änderungen:
//  16.01.2018    MZ    #154242952
//********************************************************************************************************************************************
*/

public class PLZTool_Hausnotruf{

    public static String direktVertriebKey = 'Direktvertrieb';
    public static String weiterleitungKey = 'Weiterleitung';
    public static String exklusivKey = 'Exklusives Durchstellen';
    public static String selfmailerKey = 'Selfmailer';
    
    public static String classicPlzTool = 'classicPlzTool';
    public static String createTickets = 'createTickets';
    public static String extraPage = 'extraPage';

    public static String noEmailToCustomer = 'noEmail';
    public static String customerTemplateHnrDVName = 'PLZToolCustomerHnrDVTemplate';
    
    public Id opportunityId {get;set;}
    public String opportunityName {get;set;}
    public Kunden_Interesse__c last_ki {get;set;}
    public Kunden_Interesse__c new_ki {get;set;}
    public List<account> hnr_partners {get;set;}
    public List<PLZTool_PartnerProduct> direktVertriebList {get;set;}
    public List<PLZTool_PartnerProduct> weiterleitungList {get;set;}
    public List<PLZTool_PartnerProduct> exklusivList {get;set;}
    public List<PLZTool_PartnerProduct> selfmailerList {get;set;}
    
    private PLZTool_PartnerProduct slectedProduct;
    
    public SelfmailerController selfmailerCntlr {get; set;}
    public AdditionalInfoController AICntlr {get; set;}
    
    public integer WeiterleitungSize {
    get{
        return weiterleitungList != null ? weiterleitungList .size() : 0 ;
    }set;}
    
    public PLZTool_Hausnotruf(Id oppId, List<PLZTool_PartnerProduct> productList) {
        opportunityId = oppId;
        splitProductList(productList);
        initiateKundenInteresse();
        initiatePartnerInteresse();
        selfmailerCntlr = new SelfmailerController(oppId);
        AICntlr = new AdditionalInfoController();
        List<Opportunity> oppList = [select Id,
                                            Name,
                                            Opportunity_Nummer__c
                                     from Opportunity 
                                     where Id = :opportunityId limit 1];
       if(oppList != null && oppList.size()>0){
           opportunityName = oppList [0].Opportunity_Nummer__c;
       }
    }
    
    public void keepSelected(){
    }
    
    public void splitProductList(List<PLZTool_PartnerProduct> productList){
        direktVertriebList = new List<PLZTool_PartnerProduct>();
        weiterleitungList = new List<PLZTool_PartnerProduct>();
        exklusivList = new List<PLZTool_PartnerProduct>();
        selfmailerList = new List<PLZTool_PartnerProduct>();
        for(PLZTool_PartnerProduct product : productList){
            if(product.pp.PLZ_Tool_Liste__c == direktVertriebKey )
                direktVertriebList.add(product);
            else if(product.pp.PLZ_Tool_Liste__c == weiterleitungKey )
                weiterleitungList .add(product);
            else if(product.pp.PLZ_Tool_Liste__c == exklusivKey )
                exklusivList .add(product);
            else if(product.pp.PLZ_Tool_Liste__c == selfmailerKey )
                selfmailerList .add(product);
        }
    }
    
    public String emailToCustomer(List<Partner_Produkte__c> selectedProducts){
        if(selectedProducts != null && selectedProducts.size()>0){
            if(selectedProducts[0].PLZ_Tool_Liste__c == weiterleitungKey ){
                for(Partner_Produkte__c p : selectedProducts){
                    if(!p.Email_an_kunden__c){
                        return noEmailToCustomer;
                    }
                }
                return PLZTool_Basis.customerTemplateName;
            }
            
            if(selectedProducts[0].Email_an_kunden__c){
                if(selectedProducts[0].PLZ_Tool_Liste__c == direktVertriebKey ){
                    return customerTemplateHnrDVName;
                }
                else if(selectedProducts[0].PLZ_Tool_Liste__c == exklusivKey ){
                    return PLZTool_Basis.customerTemplateName;
                }
            }
        }
        return noEmailToCustomer;
    }
    
    public String continueHnr(List<PLZTool_PartnerProduct> selectedProducts){
        saveKI();
        
        if(selectedProducts != null && selectedProducts.size()>0){
            slectedProduct = selectedProducts[0];
            
            if(slectedProduct.pp.PLZ_Tool_Liste__c == weiterleitungKey ){
                return classicPlzTool;
            }
            
            if(slectedProduct.pp.PLZ_Tool_Liste__c == direktVertriebKey ){
                if(AICntlr.showAdditionalInfo){
                    AICntlr.saveAI();
                    return classicPlzTool;
                }
                if( ! AICntlr.start(opportunityId, new_ki.Produkte_sollen_versendet_werden_an__c ,new_ki.Kontoinhaber__c, slectedProduct.pp.Bankdaten_werden_ben_tigt__c)){
                    return classicPlzTool;
                }
            }
            if(slectedProduct.pp.PLZ_Tool_Liste__c == exklusivKey ){
                //return createTickets;
                return classicPlzTool;
            }
            if(slectedProduct.pp.PLZ_Tool_Liste__c == selfmailerKey ){
                selfmailerCntlr.start(slectedProduct);
            }
        }
        return extraPage;
    }
    
    public void initiatePartnerInteresse(){
        hnr_partners =             [select id,
                                            name,
                                            Telefonisches_Beratungsgespr_ch_gew_nsch__c,
                                            Beratung_vor_Ort_gew_nscht__c,
                                            Infomaterial_gew_nscht__c,
                                            Inbetriebnahmeservice_gew_nscht__c,
                                            Selbstinstallation_gew_nscht__c,
                                            station_res_Ger_t_gew_nscht__c,
                                            mobiles_Ger_t_gew_nscht__c,
                                            X24h_besetzte_Notrufzentrale_gew_nscht__c,
                                            Hintergrunddienst_gew_nscht__c,
                                            GPS_Ortung_gew_nscht__c,
                                            Bezuschussung_durch_die_Kasse_m_glich__c
                                    from account 
                                    where id in (select partner__c 
                                                from Partner_Produkte__c 
                                                where RecordType.Name = :PLZTool_Basis.rtHausnotruf)];
    }
    
    public void initiateKundenInteresse(){
        List<Kunden_Interesse__c> ki_list = 
                                 [select id,
                                         name, 
                                         opportunity__c, 
                                         X24h_besetzte_Notrufzentrale_gewu_nscht__c,
                                         Antrag_f_r_Zuschuss_HNR_zuschicken__c,
                                         Antrag_Pflegegrad_zuschicken__c,
                                         Beratung_vor_Ort_gewu_nscht__c,
                                         Bezuschussung_durch_die_Kasse_mo_glich__c,
                                         Der_Zuschuss_f_r_HNR_ist_genehmigt__c,
                                         Epilepsiematte__c,
                                         Fallsensor__c,
                                         GPS_Ortung_gewu_nscht__c,
                                         Hintergrunddienst_gewu_nscht__c,
                                         Inbetriebnahmeservice_gewu_nscht__c,
                                         Infomaterial_gewu_nscht__c,
                                         Kontoinhaber__c,
                                         Lebendkontrolle__c,
                                         mobiles_Gera_t_gewu_nscht__c,
                                         Produkte_sollen_versendet_werden_an__c,
                                         Rauchmelder__c,
                                         Selbstinstallation_gewu_nscht__c,
                                         stationa_res_Gera_t_gewu_nscht__c,
                                         tele_Beratungsgespr_ch_gew_nscht__c,
                                         zweites_Armband__c,
                                         H_usliche_Situation__c,
                                         Pflegegrad_vorhanden__c,
                                         Sonstiges__c
                                  from Kunden_Interesse__c
                                  where opportunity__r.Id = :opportunityId
                                  order by CreatedDate desc
                                  limit 1];
        if(ki_list != null && ki_list.size()>0){
            last_ki = ki_list[0];
            new_ki = last_ki.clone();
            new_ki.id = null;
        }else{
            setPredefinedFields_KI();
        }
    }
        
    public void setPredefinedFields_KI(){
        new_ki = new Kunden_Interesse__c();
        
        new_ki.opportunity__c = opportunityId;
        
        /* set Pflegegrad_vorhanden__c flag */
        new_ki.Pflegegrad_vorhanden__c = false; 
        Opportunity opp;
        List<Opportunity> oppList = [select Id,
                                        Name, 
                                        Pflegegrad_vorhanden__c 
                                        from Opportunity 
                                        where Id = :opportunityId limit 1];
        if(oppList != null && oppList.size()>0){
            opp = oppList [0];
            if(opp.Pflegegrad_vorhanden__c == 'Pflegegrad vorhanden'){
                new_ki.Pflegegrad_vorhanden__c = true;
            }
        }
        if(!new_ki.Pflegegrad_vorhanden__c){
            List<OpportunityContactRole> contactRoles = [select ContactId, 
                                                                Contact.Pflegegrad__c 
                                                        from OpportunityContactRole 
                                                        where OpportunityId = :opportunityId 
                                                                and IsDeleted = false
                                                                and (Role = :PLZTool_Basis.contactRoleInsured
                                                                or Role = :PLZTool_Basis.contactRoleSame)
                                                        limit 1];
            if(contactRoles != null && contactRoles.size()>0){
                if( contactRoles[0].Contact.Pflegegrad__c != null){
                    for(String val : selfmailerController.PflegegradValues){
                        if( contactRoles[0].Contact.Pflegegrad__c == val){
                            new_ki.Pflegegrad_vorhanden__c = true;
                        }
                    }
                }
            }
        }
    }
    
    public Boolean kundenInteresseHasChanged(){
        List<Kunden_Interesse__c> ki_list = 
                                 [select id,
                                         name, 
                                         opportunity__c, 
                                         X24h_besetzte_Notrufzentrale_gewu_nscht__c,
                                         Antrag_f_r_Zuschuss_HNR_zuschicken__c,
                                         Antrag_Pflegegrad_zuschicken__c,
                                         Beratung_vor_Ort_gewu_nscht__c,
                                         Bezuschussung_durch_die_Kasse_mo_glich__c,
                                         Der_Zuschuss_f_r_HNR_ist_genehmigt__c,
                                         Epilepsiematte__c,
                                         Fallsensor__c,
                                         GPS_Ortung_gewu_nscht__c,
                                         Hintergrunddienst_gewu_nscht__c,
                                         Inbetriebnahmeservice_gewu_nscht__c,
                                         Infomaterial_gewu_nscht__c,
                                         Kontoinhaber__c,
                                         Lebendkontrolle__c,
                                         mobiles_Gera_t_gewu_nscht__c,
                                         Produkte_sollen_versendet_werden_an__c,
                                         Rauchmelder__c,
                                         Selbstinstallation_gewu_nscht__c,
                                         stationa_res_Gera_t_gewu_nscht__c,
                                         tele_Beratungsgespr_ch_gew_nscht__c,
                                         zweites_Armband__c,
                                         H_usliche_Situation__c,
                                         Pflegegrad_vorhanden__c,
                                         Sonstiges__c
                                  from Kunden_Interesse__c
                                  where opportunity__r.Id = :opportunityId
                                  order by CreatedDate desc
                                  limit 1];
                                  
        if(ki_list != null && ki_list.size()>0){
            last_ki = ki_list[0];
        }else{
            return true;
        }
        if(new_ki.X24h_besetzte_Notrufzentrale_gewu_nscht__c != last_ki.X24h_besetzte_Notrufzentrale_gewu_nscht__c){
            return true;
        }
        if(new_ki.Antrag_f_r_Zuschuss_HNR_zuschicken__c != last_ki.Antrag_f_r_Zuschuss_HNR_zuschicken__c){
            return true;
        }
        if(new_ki.Antrag_Pflegegrad_zuschicken__c != last_ki.Antrag_Pflegegrad_zuschicken__c){
            return true;
        }
        if(new_ki.Beratung_vor_Ort_gewu_nscht__c != last_ki.Beratung_vor_Ort_gewu_nscht__c){
            return true;
        }
        if(new_ki.Bezuschussung_durch_die_Kasse_mo_glich__c != last_ki.Bezuschussung_durch_die_Kasse_mo_glich__c){
            return true;
        }
        if(new_ki.Der_Zuschuss_f_r_HNR_ist_genehmigt__c != last_ki.Der_Zuschuss_f_r_HNR_ist_genehmigt__c){
            return true;
        }
        if(new_ki.Epilepsiematte__c != last_ki.Epilepsiematte__c){
            return true;
        }
        if(new_ki.Fallsensor__c != last_ki.Fallsensor__c){
            return true;
        }
        if(new_ki.GPS_Ortung_gewu_nscht__c != last_ki.GPS_Ortung_gewu_nscht__c){
            return true;
        }
        if(new_ki.Hintergrunddienst_gewu_nscht__c != last_ki.Hintergrunddienst_gewu_nscht__c){
            return true;
        }
        if(new_ki.Inbetriebnahmeservice_gewu_nscht__c != last_ki.Inbetriebnahmeservice_gewu_nscht__c){
            return true;
        }
        if(new_ki.Infomaterial_gewu_nscht__c != last_ki.Infomaterial_gewu_nscht__c){
            return true;
        }
        if(new_ki.Kontoinhaber__c != last_ki.Kontoinhaber__c){
            return true;
        }
        if(new_ki.Lebendkontrolle__c != last_ki.Lebendkontrolle__c){
            return true;
        }
        if(new_ki.mobiles_Gera_t_gewu_nscht__c != last_ki.mobiles_Gera_t_gewu_nscht__c){
            return true;
        }
        
        if(new_ki.Produkte_sollen_versendet_werden_an__c != last_ki.Produkte_sollen_versendet_werden_an__c){
            return true;
        }
        if(new_ki.Rauchmelder__c != last_ki.Rauchmelder__c){
            return true;
        }
        if(new_ki.Selbstinstallation_gewu_nscht__c != last_ki.Selbstinstallation_gewu_nscht__c){
            return true;
        }
        if(new_ki.stationa_res_Gera_t_gewu_nscht__c != last_ki.stationa_res_Gera_t_gewu_nscht__c){
            return true;
        }
        if(new_ki.tele_Beratungsgespr_ch_gew_nscht__c != last_ki.tele_Beratungsgespr_ch_gew_nscht__c){
            return true;
        }
        if(new_ki.zweites_Armband__c != last_ki.zweites_Armband__c){
            return true;
        }
        if(new_ki.Pflegegrad_vorhanden__c != last_ki.Pflegegrad_vorhanden__c){
            return true;
        }
        if(new_ki.H_usliche_Situation__c != last_ki.H_usliche_Situation__c){
            return true;
        }
        
        if( String.isBlank(new_ki.Sonstiges__c) ){
            new_ki.Sonstiges__c = '';
        }
        if( String.isBlank(last_ki.Sonstiges__c)){
            last_ki.Sonstiges__c = '';
        }
        if( new_ki.Sonstiges__c != last_ki.Sonstiges__c){
            return true;
        }
        return false;
    }
    
    public Pagereference saveKI(){
        if( kundenInteresseHasChanged() ){
            if(!String.isEmpty(opportunityName)){
                Datetime dt = datetime.now();
                new_ki.Name = 'KI - '+ opportunityName + ' - ' + dt.date().format() + ' - ' + dt.hour() + ':'+ dt.minute() + ':' + dt.second();
                insert new_ki;
                initiateKundenInteresse();
            }
        }
        return null;
    }
    
}