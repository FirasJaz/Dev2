/********************************************************************************************************************************************
// Erstellt 29.07.2016 von MZ
//  Klose und Srocke Gesellschaft fÃ¼r kreative KonfliktlÃ¶sungen mbH
//  Nordkanalstraße 58
//  20097 Hamburg
//  Tel.:  0423882986
//  Fax.:  0423882986
//  Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
// Parameter: Opportunity
//
//********************************************************************************************************************************************
//
// Beschreibung:             
//
//********************************************************************************************************************************************
//Änderungen:
// 25.08.2016    BT    Opp.Belastbarkeit__c = 'Weniger als 130 Kg' ==> Suche nach Partner-Produkten wo die Belastbarkeit >= 130 oder gleich null
//                     Opp.Belastbarkeit__c = 'Mehr als 130 Kg' ==> Suche nach Partner-Produkten wo die Belastbarkeit > 130 oder glcih null
//
// 29.08.2016    TK    Filter: "Umgebung" (Innen/Außen) wieder aktiviert
//                     Filter: "Art des Gebäudes" deaktiviert 
//
// 06.09.2016   TK/AM  "Gültig bis" bei PLZ-Abfrage eingebaut.
// 30.01.2017    MZ    query the field "Anmerkungen_f_r_den_Partner__c" from opportunity; a method added to access this field.
// 27.02.2017    MZ    #140658915, query ticket_cc_email_address and ticket_bcc_email_address from partner
// 01.06.2017    MZ    #142772511 Kontingent maximal
// 13.07.2017    BT    Erweiterung um die Recordtypen "Widerspruch" und "Pflegeimmobilien"
// 26.07.2017    BT    Erweiterung "Pflegeimmobilien": Suche nach PLZ-Gebieten anhand der Standortrichtung 
// 31.08.2017    MZ    Kostentr_ger__c added to query from Partner-product
// 20.12.2017    MZ    #153358879
// 05.03.2018    MZ    #155657450 show partner-products with contingent value above zero instead of != 0.
// 12.07.2018    MZ    #155510105 criteria for Badumbau added
// 05.03.2020    DZ    Geändert von "intendedOpportunity.RecordType.Name == PLZTool_Basis.rtBadumbau" auf "rtPflegeschulungen" und "intendedOpportunity.Bezugspunkt_der_PLZ_Suche__c = PlzTypes[]" von 1 auf 0
// 19.06.2020	 BT	   00002501 criteria for Badumbau added - query the products that match one of the selected main products in Opportunity 
//********************************************************************************************************************************************
*/
public class PostleitzahlenTool{ 
    private Id opportunityId{get;set;}
    private Opportunity intendedOpportunity;
    private String intendedPlz;
    
    private static Decimal BelastbarkeitLimit = 130;
    public static String BelastbarkeitWeniger = 'Weniger als 130kg';
    public static String BelastbarkeitMehr = 'Mehr als 130kg';
    public static String[] OpportunityContactRoles = new String[]{'ASP', 'PB', 'PB = ASP'};
    public static String[] PlzTypes = new String[]{'Ort des Angehörigen', 'Ort des Pflegebedürftigen', 'Alternative Postleitzahl'};
          
    public PostleitzahlenTool(Id opportunityId){
        this.opportunityId = opportunityId;
        this.setIntendedOpportunity();
        this.setIntendedPlz();
        System.debug('PostleitzahlenTool.getIntendedPlz :::::: the intended plz is ::::' + this.intendedPlz);
    }
    
    public String getRecordType(){
        return intendedOpportunity.RecordType.Name;
    } 
  
        
    public boolean hasProduct(){
        if(intendedOpportunity != null){
            if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtTreppenlift ){
                if(intendedOpportunity.Produkt_Kategorie__c != null && intendedOpportunity.Produkt_Kategorie__c.trim() != ''){
                    return true;
                }
            } 
            if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtBetreuungsleistungen ){
                if(intendedOpportunity.X24h_Betreuung__c == True ||
                   intendedOpportunity.Stundenweise_Betreuung__c == True ||
                   intendedOpportunity.Hauswirtschaftsleistungen__c == True ||
                   intendedOpportunity.Pflegedienst__c == True){
                    return True;
                }
            }
            if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtPflegeschulungen ){
                return True;    
            }
            if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtHausnotruf ){
                return True;    
            }
            if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtPflegeimmobilien ){
                return True;    
            }
            if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtWiderspruch ){
                return True;    
            }   
            if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtBadumbau ){
                if(intendedOpportunity.Produkt_Kategorie__c != null && intendedOpportunity.Produkt_Kategorie__c.trim() != ''){
                    return true;
                }    
            }       
        }
        return false;
    }
    
    public boolean hasPlz(){
        if(intendedOpportunity != null && intendedOpportunity.RecordType.Name == PLZTool_Basis.rtWiderspruch){
            return true;
        }
        if(intendedOpportunity != null && intendedOpportunity.Bezugspunkt_der_PLZ_Suche__c != null && this.intendedPlz != null ){
            return true;
        }
        return false;
    }
    
    public String getAnmerkungenDenPartner(){
        if(intendedOpportunity != null)
            return intendedOpportunity.Anmerkungen_f_r_den_Partner__c;
        return '';
    }
    
    public List<Partner_Produkte__c> getBestPartners(){          
        return this.findPartnerProducts();
    } 

    public string existingPartners(id oppId) {
        string exPartners = '';
        list<Partner_Ticket__c> paList = [SELECT Partner__c FROM Partner_Ticket__c WHERE Opportunity__c = :oppId];
        if((paList != null) && (paList.size() > 0) ) {
            for(Partner_Ticket__c pt : paList) {
                string paId = string.valueOf(pt.Partner__c);
                if(!exPartners.contains(paId)) {
                    if(exPartners == '') {
                        exPartners = paId;
                    } else exPartners += ',' + paId;        
                }               
            }           
        }
        return exPartners;
    }
    
    private void setIntendedOpportunity(){
        opportunity[] opportunityList = [select 
                                         RecordType.Name, 
                                         Bezugspunkt_der_PLZ_Suche__c, 
                                         Alternative_Postleitzahl__c, 
                                         Produkt_Kategorie__c, 
                                         Preis_maximal__c, 
                                         Neu_und_oder_gebraucht__c, 
                                         Art_der_Finanzierung__c,
                                         Belastbarkeit__c, 
                                         Umgebung__c, 
                                         Treppenbauart__c, 
                                         Art_des_Geb_udes__c, 
                                         Anzahl_der_Etagen__c, 
                                         Kostenfreier_Aufma_termin__c, 
                                         T_V_zertifiziert__c, 
                                         Einbautermin_zeitnah_m_glich__c, 
                                         Beantragung_der_Pflegestufe__c, 
                                         R_ckkauf_von_Liften__c, 
                                         Versicherung__c, 
                                         Servicehotline__c, 
                                         Probefahrt__c, 
                                         Installationsservice__c, 
                                         Notdienst__c, 
                                         Wartung_des_Produkts__c, 
                                         Grube__c, 
                                         Versand_von_Informationsmaterial__c, 
                                         Nutzbare_Fl_che_Au_enma__c, 
                                         Termin_vor_Ort__c, 
                                         Ausland__c, 
                                         F_rderh_he__c, 
                                         Treppenbreite__c, 
                                         Technik__c, 
                                         Anzahl_Haltestellen__c,
                                         X24h_Betreuung__c,
                                         Stundenweise_Betreuung__c, 
                                         Hauswirtschaftsleistungen__c,
                                         Pflegedienst__c,
                                         Anmerkungen_f_r_den_Partner__c,
                                         location_direction__c,
                                         D_weites_Invest__c,
                                         DesiredAdditionalServices__c  
                                         from opportunity 
                                         where Id = :this.opportunityId limit 1];
        if(opportunityList != null && opportunityList.size()>0){
            intendedOpportunity = opportunityList[0];           
        }else{
            System.debug('error in PostleitzahlenTool !!! ::: no opportunity found with Id: ' + this.opportunityId);
        }
    }
    
    

    private void setIntendedPlz(){ 
        if(intendedOpportunity != null && intendedOpportunity.RecordType.Name == PLZTool_Basis.rtPflegeschulungen){
            intendedOpportunity.Bezugspunkt_der_PLZ_Suche__c = PlzTypes[0];
        }
        this.intendedPlz = intendedOpportunity.Alternative_Postleitzahl__c;
        OpportunityContactRole[] OpportunityContactRoleList;
        if(intendedOpportunity.Bezugspunkt_der_PLZ_Suche__c == PlzTypes[0]){
            OpportunityContactRoleList = [select Contact.MailingPostalCode from OpportunityContactRole where OpportunityId = :opportunityId and (Role = :OpportunityContactRoles[0] or Role = :OpportunityContactRoles[2]) limit 1];
        }
        if(intendedOpportunity.Bezugspunkt_der_PLZ_Suche__c == PlzTypes[1]){
            OpportunityContactRoleList = [select Contact.MailingPostalCode from OpportunityContactRole where OpportunityId = :opportunityId and (Role = :OpportunityContactRoles[1] or Role = :OpportunityContactRoles[2]) limit 1];
        }
        if(OpportunityContactRoleList != null && OpportunityContactRoleList.size()>0){
            this.intendedPlz = OpportunityContactRoleList[0].Contact.MailingPostalCode;
        }
    }
    
    private String generateWhereClause(){
        String whereClause = ' ';
        
        // price filter
        if(intendedOpportunity.Preis_maximal__c != Null && intendedOpportunity.Preis_maximal__c != 0){
            whereClause += ' and ( Preisspannen_von__c = null ';
            whereClause += ' or ( Preisspannen_von__c != null and Preisspannen_von__c <= ' + intendedOpportunity.Preis_maximal__c ;
            whereClause += ' )) ';
        }
        
        // weight filter
        if(intendedOpportunity.Belastbarkeit__c != Null){
            if(intendedOpportunity.Belastbarkeit__c == BelastbarkeitWeniger ){
                whereClause += ' and ( Belastbarkeit__c = null ';
                whereClause += ' or ( Belastbarkeit__c != null and Belastbarkeit__c >= ' + BelastbarkeitLimit ;
                whereClause += ' )) ';
            }
            if(intendedOpportunity.Belastbarkeit__c == BelastbarkeitMehr ){
                whereClause += ' and ( Belastbarkeit__c = null ';
                whereClause += ' or ( Belastbarkeit__c != null and Belastbarkeit__c > ' + BelastbarkeitLimit ;
                whereClause += ' )) ';
            }
        }
        
        // Neu_und_oder_gebraucht__c filter
        if(intendedOpportunity.Neu_und_oder_gebraucht__c != Null && intendedOpportunity.Neu_und_oder_gebraucht__c != ''){
            String[] strArray = intendedOpportunity.Neu_und_oder_gebraucht__c.split(';');
            if(strArray.size() > 0){
            whereClause += ' and ( Neu_und_oder_gebraucht__c = null ';
            whereClause += ' or ( Neu_und_oder_gebraucht__c != null and ( ';
            integer i = 0;
            for(String str : strArray){
                whereClause += ' Neu_und_oder_gebraucht__c includes (\''+str+'\')';
                i++;
                if(i < strArray.size()){
                    whereClause += ' or ';
                }
            }
            whereClause += ' ) ';
            whereClause += ' )) ';
            }
        }        

        //Art_der_Finanzierung__c filter        
        if(intendedOpportunity.Art_der_Finanzierung__c != Null && intendedOpportunity.Art_der_Finanzierung__c != ''){
            String[] strArray = intendedOpportunity.Art_der_Finanzierung__c.split(';');
            if(strArray.size() > 0){
            whereClause += ' and ( Art_der_Finanzierung__c = null ';
            whereClause += ' or ( Art_der_Finanzierung__c != null and ( ';
            integer i = 0;
            for(String str : strArray){
                whereClause += ' Art_der_Finanzierung__c includes (\''+str+'\')';
                i++;
                if(i < strArray.size()){
                    whereClause += ' or ';
                }
            }
            whereClause += ' ) ';
            whereClause += ' )) ';
            }
        }        
        
        // innen oder außen filter
        if(intendedOpportunity.Umgebung__c != Null && intendedOpportunity.Umgebung__c != '' ){
            whereClause += ' and ( Umgebung__c = null ';
            whereClause += ' or ( Umgebung__c != null and Umgebung__c includes (\''+intendedOpportunity.Umgebung__c+'\')';
            whereClause += ' )) ';
        }
        
        // Treppenbauart filter
        /*if(intendedOpportunity.Treppenbauart__c != Null && intendedOpportunity.Treppenbauart__c != '' ){
            whereClause += ' and ( Treppenbauart__c = null ';
            whereClause += ' or ( Treppenbauart__c != null and Treppenbauart__c includes (\''+intendedOpportunity.Treppenbauart__c+'\')';
            whereClause += ' )) ';
        }*/              
      
        // Art des Gebäudes Filter
        /*if(intendedOpportunity.Art_des_Geb_udes__c != Null && intendedOpportunity.Art_des_Geb_udes__c != '' ){
            String[] strArray = intendedOpportunity.Art_des_Geb_udes__c.split(' ');
            if(strArray.size() > 0){
            whereClause += ' and ( Art_des_Geb_udes__c = null ';
            whereClause += ' or ( ( Art_des_Geb_udes__c includes (\''+intendedOpportunity.Art_des_Geb_udes__c+'\') ';
            integer i = 0;
            for(String str : strArray){
                if(i < strArray.size()){
                    whereClause += ' or ';
                }
                whereClause += ' Art_des_Geb_udes__c includes (\''+str+'\') ';
                i++;
            }
            whereClause += ' ) ';
            whereClause += ' )) ';
            }
        }*/       

        // Anzahl der Etagen Filter
        /*if(intendedOpportunity.Anzahl_der_Etagen__c != Null && intendedOpportunity.Anzahl_der_Etagen__c != 0 ){
            whereClause += ' and ( Anzahl_der_Etagen__c = null ';
            whereClause += ' or ( Anzahl_der_Etagen__c != null and Anzahl_der_Etagen__c >= ' + intendedOpportunity.Anzahl_der_Etagen__c;
            whereClause += ' )) ';
        } */
        
        /********  Sonstige Produkteigenschaften ********/
        // Grube filter
        if(intendedOpportunity.Grube__c == true){
            whereClause += ' and Grube__c = true ';
        }
        
        // Versand von Informationsmaterial filter
        if(intendedOpportunity.Versand_von_Informationsmaterial__c == true){
            whereClause += ' and Versand_von_Informationsmaterial__c = true ';
        }
        
        // Nutzbare Fläche Außenmaß filter
        if(intendedOpportunity.Nutzbare_Fl_che_Au_enma__c != null ){
            whereClause += ' and Nutzbare_Fl_che_Au_enma__c = \'' + intendedOpportunity.Nutzbare_Fl_che_Au_enma__c + '\' ';
        }
        
        // Termin vor Ort filter
        if(intendedOpportunity.Termin_vor_Ort__c == true){
            whereClause += ' and Termin_vor_Ort__c = true ';
        }
        
        // Ausland filter
        if(intendedOpportunity.Ausland__c == true){
            whereClause += ' and Ausland__c = true ';
        }
        
        // Förderhöhe filter
        if(intendedOpportunity.F_rderh_he__c != null){
            whereClause += ' and F_rderh_he__c = '+ intendedOpportunity.F_rderh_he__c +' ';
        }
        
        // Treppenbreite filter
        if(intendedOpportunity.Kostenfreier_Aufma_termin__c == true){
            whereClause += ' and Kostenfreier_Aufma_termin__c = true ';
        }
        
        // Treppenbreite filter
        if(intendedOpportunity.Treppenbreite__c != null){
            whereClause += ' and Treppenbreite__c >= '+ intendedOpportunity.Treppenbreite__c +' ';
        }
        
        // Anzahl Haltestellen filter
        if(intendedOpportunity.Anzahl_Haltestellen__c != null){
            whereClause += ' and Anzahl_Haltestellen__c >=  '+ intendedOpportunity.Anzahl_Haltestellen__c +' ';
        }
        
        // Technik filter 
        if(intendedOpportunity.Technik__c != Null && intendedOpportunity.Technik__c != ''){
            String[] strArray = intendedOpportunity.Technik__c.split(';');
            if(strArray.size() > 0){
            whereClause += ' and ( Technik__c = null ';
            whereClause += ' or ( Technik__c != null and ( ';
            integer i = 0;
            for(String str : strArray){
                whereClause += ' Technik__c includes (\''+str+'\')';
                i++;
                if(i < strArray.size()){
                    whereClause += ' or ';
                }
            }
            whereClause += ' ) ';
            whereClause += ' )) ';
            }
        }

        
        /******  weitere Services/Zusatzleistungen ******/
        // Kostenfreier Aufmaßtermin filter
        if(intendedOpportunity.Kostenfreier_Aufma_termin__c == true){
            whereClause += ' and Kostenfreier_Aufma_termin__c = true ';
        }
        
        // Zertifizierung filter 
        if(intendedOpportunity.T_V_zertifiziert__c == true){
            whereClause += ' and Zertifizierungen__c != null ';
        }
        
        // Einbautermin zeitnah möglich filter
        if(intendedOpportunity.Einbautermin_zeitnah_m_glich__c == true){
            whereClause += ' and Einbautermin_zeitnah_m_glich__c = true ';
        }
        
        // Beantragung der Pflegestufe filter
        if(intendedOpportunity.Beantragung_der_Pflegestufe__c == true){
            whereClause += ' and Beantragung_der_Pflegestufe__c = true ';
        }
        

        if(intendedOpportunity.R_ckkauf_von_Liften__c == true){
            whereClause += ' and R_ckkauf_von_Liften__c = true ';
        }
        
        // Versicherung filter 
        if(intendedOpportunity.Versicherung__c == true){
            whereClause += ' and Versicherungen__c = true ';
        }
        
        // Servicehotline filter
        if(intendedOpportunity.Servicehotline__c == true){
            whereClause += ' and Servicehotline__c = true ';
        }
        
        // Probefahrt filter
        if(intendedOpportunity.Probefahrt__c == true){
            whereClause += ' and Probefahrt__c = true ';
        }
        
        // Installationsservice filter
        if(intendedOpportunity.Installationsservice__c == true){
            whereClause += ' and Installationsservice__c = true ';
        }
        
        // Notdienst filter
        if(intendedOpportunity.Notdienst__c == true){
            whereClause += ' and Notdienst__c = true ';
        }
        
        // Wartung des Produkts
        if(intendedOpportunity.Wartung_des_Produkts__c == true){
            whereClause += ' and Wartung_des_Produkts__c = true ';
        }
        
        System.debug('##### MANSI :::: optionalwhreclause::::: ' + whereClause);
        return whereClause + ' ';        
    }
    
    private String tlWhereClause(){
        String whereClause = ' ';
        String[] productList = intendedOpportunity.Produkt_Kategorie__c.split(';');
        if(productList.size()>0){
            whereClause += ' and ( ';
            integer i = 0;
            for(String prdct : productList){
                whereClause += ' Produktgruppe__c Like \'%'+prdct+'%\' ';
                i++;
                if(i < productList.size()){
                    whereClause += ' or ';
                }
            }
            whereClause += ' ) ';
        }
        // add optional critria
        String optionalWhereClause = this.generateWhereClause();
        if(optionalWhereClause != null && optionalWhereClause.trim() != '' ){
            whereClause += optionalWhereClause;
        }
        return whereClause + ' '; 
    }
    
    private String belWhereClause(){
        String whereClause = ' ';
        if(intendedOpportunity.X24h_Betreuung__c == true ||
           intendedOpportunity.Stundenweise_Betreuung__c == true ||
           intendedOpportunity.Hauswirtschaftsleistungen__c == true)
        {        
            whereClause += ' and ( ';
            if(intendedOpportunity.X24h_Betreuung__c == true){
                whereClause += ' Produktgruppe__c Like \'%24h Betreuung%\' ';
            }
            if(intendedOpportunity.Stundenweise_Betreuung__c == true){
                if(intendedOpportunity.X24h_Betreuung__c == true){
                    whereClause += ' or ';
                }
                whereClause += ' Produktgruppe__c Like \'%Stundenweise Betreuung%\' ';
            }
            if(intendedOpportunity.Hauswirtschaftsleistungen__c == true){
                if(intendedOpportunity.X24h_Betreuung__c == true || 
                   intendedOpportunity.Stundenweise_Betreuung__c == true){
                    whereClause += ' or ';
                }
                whereClause += ' Produktgruppe__c Like \'%Hauswirtschaftsleistungen%\' ';
            }
            whereClause += ' ) ';
        }
        return whereClause + ' '; 
    }
    
    private String hnrWhereClause(){
        String whereClause = ' ';
        return whereClause + ' ';
    }

    private String wsWhereClause(){
        String whereClause = ' ';
        return whereClause + ' ';
    }
    
    private String badWhereClause(){
        // query all the peroducts that can be provided in PB area.
        /*
        String whereClause = ' ';
        return whereClause + ' ';
		*/
		String whereClause = ' ';
        String[] productList = intendedOpportunity.Produkt_Kategorie__c.split(';');
        if(productList.size()>0){
            whereClause += ' and ( ';
            integer i = 0;
            for(String prdct : productList){
                whereClause += ' Produktgruppe__c Like \'%'+prdct+'%\' ';
                i++;
                if(i < productList.size()){
                    whereClause += ' or ';
                }
            }
            whereClause += ' ) ';
        }    
        return whereClause + ' ';
        
        /*
        // query the products that match one of the selected main products in Opportunity + all additional products
        // the other criteria is added in PlzTool_Badumbau; because the criteria is based on partners not based on partner-products.
        // another class is needed becaus
        String whereClause = ' and ( ProduktType__c = \'Zusatzleistung\' or ';
        
        String[] productList = intendedOpportunity.Produkt_Kategorie__c.split(';');
        if(productList.size()>0){
            whereClause += ' ( ProduktType__c = \'Produkt\' and ( ';
            integer i = 0;
            for(String prdct : productList){
                whereClause += ' Produktgruppe__c Like \'%'+prdct+'%\' ';
                i++;
                if(i < productList.size()){
                    whereClause += ' or ';
                }
            }
            whereClause += ' ) ) ';
        }
        
        return whereClause + ' ) ';
*/
        
    }
    
    private String piWhereClause(){
        String whereClause = ' and ( (PLZ_Tool_Liste__c = \'Regionen irrelevant\') ';
        
        if(intendedOpportunity.D_weites_Invest__c){
            whereClause += ' or (PLZ_Tool_Liste__c = \'D-weites Invest und D-weiter Wohnort\') or ( PLZ_Tool_Liste__c = \'D-weites Invest und eingeschränkter Wohnort\' and ( Id in :inclPartnerSet ) ) ';
        }
        else if(intendedOpportunity.location_direction__c != null){
            String location_values = '';
            if(intendedOpportunity.location_direction__c.indexOf('Norddeutschland') != -1) {
                location_values += '\'Norddeutschland\'';
                //whereClause += ' or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und D-weiter Wohnort\' and location_direction__c Like \'%Norddeutschland%\' ) or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und eingeschränkter Wohnort\' and location_direction__c Like \'%Norddeutschland%\' and Id in :inclPartnerSet ) ';
            }
            if(intendedOpportunity.location_direction__c.indexOf('Süddeutschland') != -1) {
                if(!String.isempty(location_values))
                    location_values += ',';
                location_values += '\'Süddeutschland\'';
                //whereClause += ' or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und D-weiter Wohnort\' and location_direction__c Like \'%Süddeutschland%\' ) or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und eingeschränkter Wohnort\' and location_direction__c Like \'%Süddeutschland%\' and Id in :inclPartnerSet ) ';
            }
            if(intendedOpportunity.location_direction__c.indexOf('Westdeutschland') != -1) {
                if(!String.isempty(location_values))
                    location_values += ',';
                location_values += '\'Westdeutschland\'';
                //whereClause += ' or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und D-weiter Wohnort\' and location_direction__c Like \'%Westdeutschland%\' ) or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und eingeschränkter Wohnort\' and location_direction__c Like \'%Westdeutschland%\' and Id in :inclPartnerSet ) ';
            }
            if(intendedOpportunity.location_direction__c.indexOf('Ostdeutschland') != -1) {
                if(!String.isempty(location_values))
                    location_values += ',';
                location_values += '\'Ostdeutschland\'';
                //whereClause += ' or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und D-weiter Wohnort\' and location_direction__c Like \'%Ostdeutschland%\' ) or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und eingeschränkter Wohnort\' and location_direction__c Like \'%Ostdeutschland%\' and Id in :inclPartnerSet ) ';
            }
            whereClause += ' or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und D-weiter Wohnort\' and location_direction__c includes ('+ location_values +') ) or (PLZ_Tool_Liste__c = \'Eingeschränktes Invest und eingeschränkter Wohnort\' and location_direction__c includes ('+ location_values +') and Id in :inclPartnerSet ) ';
        }
        
        return whereClause + ' ) ';
    }        
    
    private List<Partner_Produkte__c> findPartnerProducts(){
        
        // store the list of plz_included partners in inclPartnerSet
        set<Id> inclPartnerSet = new set<Id>();
        for(Partner_PLZ_Gebiet__c incl_ptnr_plz : [select Partner_Produkte__c from Partner_PLZ_Gebiet__c where IsDeleted = false and  Include_exclude__c = 'inbegriffen' and PLZ_von__c <= :intendedPlz and PLZ_bis__c >= :intendedPlz and (G_ltig_bis__c = null OR G_ltig_bis__c > :Date.today()) and (G_ltig_von__c = null OR G_ltig_von__c <= :Date.today())])
        {
            inclPartnerSet.add(incl_ptnr_plz.Partner_Produkte__c);
        }
        
        // store the list of plz_excluded partners in exclPartnerSet
        set<Id> exclPartnerSet = new set<Id>();
        for(Partner_PLZ_Gebiet__c excl_ptnr_plz : [select Partner_Produkte__c from Partner_PLZ_Gebiet__c where IsDeleted = false and  Include_exclude__c = 'ausgeschlossen' and PLZ_von__c <= :intendedPlz and PLZ_bis__c >= :intendedPlz and (G_ltig_bis__c = null OR G_ltig_bis__c > :Date.today())])
        {
            exclPartnerSet.add(excl_ptnr_plz.Partner_Produkte__c);
        }
        
        // get required fields 
        String queryString = 'select Id, Name, Kontingent_offen_Produkt__c, Partner__r.Kontingent_offen_Partner__c, Partner__c, Partner__r.Name, Produktgruppe__c, ' +
                        ' Kontingent_offen_Produkt_pro_Tag__c, Partner__r.Kontingent_offen_Partner_pro_Tag__c, Kontingent_offen_Produkt_pro_Monat__c, Partner__r.Kontingent_offen_Partner_pro_Monat__c, ' +
                        // ' CPL_Exklusiv__c,CPL_Kategorie_1__c, CPL_Kategorie_2__c, CPO_prozentuale_Beteiligung__c, CPO__c, CPO_Exclusiv__c, ' +
                        ' partner__r.BillingStreet, partner__r.BillingCity, partner__r.BillingPostalCode, partner__r.Phone, partner__r.Website, ' + 
                        ' partner__r.Logo_Url__c, Anmerkung__c, ' + //' partner__r.Zielerf_llung_bei_Anzahl_Tickets__c, ' +
                        // ' CPL_Kategorie_1_Ziel__c, CPL_Kategorie_2_Ziel__c, CPL_Exklusiv_Ziel__c, ' +
                        ' Medizinische_Pflege__c, Leichte_Pflege__c, Betreuung__c, Hauswirtschaft__c, Vermittlungsmodell__c, '+
                        ' Priorit_t__c, Kosten__c, Mindestdauer_des_Einsatzes__c, Herkunftsland_der_Betreuer__c, ' +
                        ' partner__r.ticket_email_address__c, partner__r.ticket_cc_email_address__c, partner__r.ticket_bcc_email_address__c, '+
                        ' Individuelle_Partner_Email__c, Strukturierte_Partner_Email__c, Kostenstelle__c, Belastbarkeit__c , location_direction__c, '+
                        ' PLZ_Tool_Liste__c, Bankdaten_werden_ben_tigt__c, Kontingent_maximal__c, email_an_kunden__c, Abrechnungsmethode__c, '+
                        ' partner__r.Zust_ndigkeit_F_higkeiten__c, ProduktType__c   from Partner_Produkte__c ';
        
        // add recordType conditions
        queryString += ' where RecordType.Name = \'' + intendedOpportunity.RecordType.Name + '\' ';
        

            // add Kontingent_offen per week filter
            queryString += ' and (Kontingent_offen_Produkt__c = null or Kontingent_offen_Produkt__c > 0) and (Partner__r.Kontingent_offen_Partner__c = null or Partner__r.Kontingent_offen_Partner__c > 0 )';
            
            // add Kontingent_offen per day filter
            queryString += ' and (Kontingent_offen_Produkt_pro_Tag__c = null or Kontingent_offen_Produkt_pro_Tag__c > 0) and (Partner__r.Kontingent_offen_Partner_pro_Tag__c = null or Partner__r.Kontingent_offen_Partner_pro_Tag__c > 0 )';
            
            // add Kontingent_offen per month filter
            queryString += ' and (Kontingent_offen_Produkt_pro_Monat__c = null or Kontingent_offen_Produkt_pro_Monat__c > 0) and (Partner__r.Kontingent_offen_Partner_pro_Monat__c = null or Partner__r.Kontingent_offen_Partner_pro_Monat__c > 0 )';

        
        // add Pausiert condition
        queryString += ' and Pausiert__c = false and Partner__r.Pausiert__c = false ';
        
        
        
        
        // add Treppenlift filter
        if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtTreppenlift ){
            // add plz, inclPartnerSet, and inclPartnerSet condition
            // queryString += ' and ( (Deutschlandweit_verf_gbar__c = false and Id in :inclPartnerSet) or (Deutschlandweit_verf_gbar__c = true and Id not in :exclPartnerSet) ) ';
            // AM 14.09.2016 - da wir nur inclPartnerSet haben ist Deutschlandweit_verf_gbar__c nicht von Bedeutung.
            queryString += ' and ( Id in :inclPartnerSet ) ';
            String tlWhereClause = this.tlWhereClause();
            if(tlWhereClause != null && tlWhereClause.trim() != '' ){
                queryString += tlWhereClause;
            }
        }
        
        // add Betreuungsleistungen criteria
        if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtBetreuungsleistungen ){
            // add plz, inclPartnerSet, and inclPartnerSet condition
            // queryString += ' and ( (Deutschlandweit_verf_gbar__c = false and Id in :inclPartnerSet) or (Deutschlandweit_verf_gbar__c = true and Id not in :exclPartnerSet) ) ';
            // AM 14.09.2016 - da wir nur inclPartnerSet haben ist Deutschlandweit_verf_gbar__c nicht von Bedeutung.
            queryString += ' and ( Id in :inclPartnerSet ) ';
            
            String belWhereClause = this.belWhereClause();
            if( belWhereClause != null && belWhereClause.trim() != '' ){
                queryString += belWhereClause;
            }
        }
        
        // add Hausnotruf criteria
        if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtHausnotruf ){
            // add plz, inclPartnerSet, and inclPartnerSet condition
            // queryString += ' and ( (Deutschlandweit_verf_gbar__c = false and Id in :inclPartnerSet) or (Deutschlandweit_verf_gbar__c = true and Id not in :exclPartnerSet) ) ';
            // AM 14.09.2016 - da wir nur inclPartnerSet haben ist Deutschlandweit_verf_gbar__c nicht von Bedeutung.
            queryString += ' and ( Id in :inclPartnerSet ) ';
            
            String hnrWhereClause = this.hnrWhereClause();
            if( hnrWhereClause != null && hnrWhereClause.trim() != '' ){
                queryString += hnrWhereClause;
            }
        }
        
        // add Pflegeimmobilien criteria
        if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtPflegeimmobilien) {
            String piWhereClause = this.piWhereClause();
            if( piWhereClause != null && piWhereClause.trim() != ''){
                queryString += piWhereClause;
            }
        } 
        
        // add Widerspruch criteria
        if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtWiderspruch) {
            String wsWhereClause = this.wsWhereClause();
            if( wsWhereClause != null && wsWhereClause.trim() != ''){
                queryString += wsWhereClause;
            }
        }
        
        // add Badumbau criteria
        if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtBadumbau) {
            queryString += ' and ( Id in :inclPartnerSet ) ';
            
            String badWhereClause = this.badWhereClause();
            if( badWhereClause != null && badWhereClause.trim() != ''){
                queryString += badWhereClause;
            }
        }    
        
        // sort the list
        //queryString += ' order by CPL_Kategorie_1__c desc Nulls last,  CPL_Exklusiv__c desc Nulls last ';
        
        if(intendedOpportunity.RecordType.Name == PLZTool_Basis.rtBadumbau) {
            queryString += ' order by Partner__c, ProduktType__c Asc ';
        } 
        
        List<Partner_Produkte__c> ProductsList =  Database.query(queryString);  
        
        // check for Kontingent maximal
        Map<Id, Integer> ppMapIndex = new Map<Id, Integer>();
        for(integer i=0; i<ProductsList.size(); i+=1){
            if(ProductsList[i].Kontingent_maximal__c != null){
                ppMapIndex.put(ProductsList[i].Id, i);
            }
        }
        if(ppMapIndex!= null && ppMapIndex.size()>0){
            list<AggregateResult> ptList = [SELECT Partner_Produkt__c, COUNT(id) cnt 
                    FROM Partner_Ticket__c 
                    WHERE Partner_Produkt__c IN : ppMapIndex.keySet()
                    GROUP BY Partner_Produkt__c];
            if(ptList != null && ptList.size()>0) {
                for(AggregateResult ar : ptList) {
                    integer ticketCount = (integer)ar.get('cnt');
                    id ppid = (id)ar.get('Partner_Produkt__c');
                    integer indx = ppMapIndex.get(ppid);
                    Partner_Produkte__c prdct = ProductsList[indx];
                    if(prdct.Kontingent_maximal__c != null && prdct.Kontingent_maximal__c <= ticketCount){
                        ProductsList.remove(indx);
                    }
                }
            }
        }        
        return ProductsList;
    }
    
    

}