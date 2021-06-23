//****************************************************************************************************************************
// Erstellt 15.10.2016 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//
//
//****************************************************************************************************************************
//Änderungen:
//
// bt   31.08.2016    Abrechnungspositionen werden je PositionTyp, Produkt und Kategorie erstellt
// wds  01.09.2016    Einzelpreis in die Abrechnungsposition eingefügt und mit dem Produktpreis ( cpl_price_map.get(cpl_posName) ) gefüllt, damit 
//                     es im XML für Scopevisio mit übergeben werden kann
// wds  13.09.2016    Erweiterung um die Kostenstelle aus dem Partner-Tickert. Es wird ausgelesen und in den Abrechnungssatz geschrieben
// bt   15.09.2016    Abrechnungspositionen werden auch einzeln erstellt
// am   22.09.2016    Neue Benennung ( + ContactRolle)
// TK   23.09.2016    Leichte Anpassung ABP-Name: Bindestriche ersetzt durch Kommas, einfügen von "ASP: "
// MZ   31.08.2017    Erweiterung um die Kostenträger aus dem Partner-Tickert. Es wird ausgelesen und in den Abrechnungssatz geschrieben
// MZ   05.12.2017    #152721179 generate different rows for "kumuliert" tickets if the price is different.
//****************************************************************************************************************************
public class PartnerTicketsInvoice {
    private static String invoitcePositionTypeCpl = 'Vergütung für übermittelte Interessenten: ';
    private static String invoitcePositionTypeCpo = 'Vergütung für erfolgreich abgeschlossene Verträge: ';
    
    private static String cpo_status = 'Abrechenbar';
    private static String cpo_status_uebermittelt = 'Übermittelt';
    private static String cpo_status_closed = 'Keinen Auftrag erhalten';
    private static String cpl_status = 'Abrechenbar';
    private static String after_invoice_status = 'Abgerechnet';
    
    public String[] ppArr;
    private String timePeriodValue; 
    
    private static String KST = ' ';
    // private static String KTG = ' ';
    
    List<Id> partnerId_list = new List<Id>();
    private map<Id, List<Partner_Ticket__c> > cplTickets = new map<Id, List<Partner_Ticket__c> >();
    private map<Id, List<Partner_Ticket__c> > cpoTickets = new map<Id, List<Partner_Ticket__c> >();
    
    private map<string, Abrechnungspositionen__c> AP_gesamt_cpl_map = new map<string, Abrechnungspositionen__c>();
    private map<string, Abrechnungspositionen__c> AP_gesamt_cpo_map = new map<string, Abrechnungspositionen__c>();
    private map<Partner_Ticket__c, Abrechnungspositionen__c> AP_einzeln_map = new map<Partner_Ticket__c, Abrechnungspositionen__c>();
    
    
    private map<Id, Abrechnung_Partner__c> invoice_map = new map<Id, Abrechnung_Partner__c>();
    private map<Id, List<Abrechnungspositionen__c>> invoicePos_CPL_map = new map<Id, List<Abrechnungspositionen__c>>();
    private map<Id, List<Abrechnungspositionen__c>> invoicePos_CPO_map = new map<Id, List<Abrechnungspositionen__c>>();
    
    
    public PartnerTicketsInvoice(List<Id> partners, String[] pAr, String tpv){
        partnerId_list = partners;        
        ppArr = pAr;
        timePeriodValue = tpv;
    }
    
    public ApexPages.message invoicingAndScopevisioRequest(){
        ApexPages.message msg = startInvoicing();
        for(Abrechnung_Partner__c invoice: invoice_map.values()){            
            PartnerInvoiceScopevisioRequest.sendRequest(invoice.Id);
        }        
        return msg;
    }
    
    private ApexPages.message startInvoicing(){
        Boolean has_pos = generateInvoice();
        Savepoint sp = Database.setSavepoint();     
        List<Abrechnungspositionen__c> cpl_pos_list = new List<Abrechnungspositionen__c>();
        List<Abrechnungspositionen__c> cpo_pos_list = new List<Abrechnungspositionen__c>();
        try {      
            if( has_pos ){ // && invoice_map != null && invoice_map.size()>0 
                insert invoice_map.values();
                
                // update invoice reference of invoice positions
                if(invoicePos_CPL_map != null && invoicePos_CPL_map.size()>0){
                    for(Id partnerId : invoicePos_CPL_map.keySet()){                        
                        cpl_pos_list = invoicePos_CPL_map.get(partnerId);
                        
                        for(Abrechnungspositionen__c cpl_pos: cpl_pos_list){
                            cpl_pos.Abrechnung__c = invoice_map.get(partnerId).Id;
                        }
                    }
                    if(cpl_pos_list != null && cpl_pos_list.size() != 0) insert cpl_pos_list;                    
                }
                if(invoicePos_CPO_map != null && invoicePos_CPO_map.size()>0){
                    for(Id partnerId : invoicePos_CPO_map.keySet()){                        
                        cpo_pos_list = invoicePos_CPO_map.get(partnerId);
                        
                        for(Abrechnungspositionen__c cpo_pos: cpo_pos_list){
                            cpo_pos.Abrechnung__c = invoice_map.get(partnerId).Id;
                        }
                    }
                    if(cpo_pos_list != null && cpo_pos_list.size() != 0) insert cpo_pos_list;
                }
                
                // update partner tickets
                Date today = Datetime.now().date();
                if(cplTickets != null && cplTickets.size()>0){
                    List<Partner_Ticket__c> to_update_tickets = new List<Partner_Ticket__c>();
                    for(Id partnerId : cplTickets.keySet()){
                        List<Partner_Ticket__c> ticket_list = cplTickets.get(partnerId);
                        for(Partner_Ticket__c t : ticket_list){
                            if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && (t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL kumuliert') || t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL und CPO kumuliert'))){
                                //String posName = invoitcePositionTypeCpl + t.Partner_Produkt__r.Produktgruppe__c + ', ' + 'Kat. ' + t.Preis_Kategorie_der_Opportunity__c;
                                //t.Abrechnung_CPL__c = AP_gesamt_map.get(posName).Id;
                                t.Abrechnung_CPL__c = AP_gesamt_cpl_map.get(String.valueOf(t.Wert_des_Partner_Tickets_CPL__c)).Id;
                            }
                            if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && (t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL einzeln') || t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL und CPO einzeln'))){
                                t.Abrechnung_CPL__c = AP_einzeln_map.get(t).Id;
                            }                            
                            t.CPL_abgerechnet_worden_am__c = today;
                            t.Status_CPL__c = after_invoice_status;
                            System.debug('mansi::::t in cpl_ticket List'+ t);
                        }
                        System.debug('mansi::::ticket_list'+ ticket_list);
                        to_update_tickets.addAll(ticket_list);
                    }
                    update to_update_tickets;
                }
                
                if(cpoTickets != null && cpoTickets.size()>0){
                    List<Partner_Ticket__c> to_update_tickets = new List<Partner_Ticket__c>();
                    for(Id partnerId : cpoTickets.keySet()){
                        List<Partner_Ticket__c> ticket_list = cpoTickets.get(partnerId);
                        for(Partner_Ticket__c t : ticket_list){
                            if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPO kumuliert')){
                                //String posName = invoitcePositionTypeCpo + t.Partner_Produkt__r.Produktgruppe__c + ', ' + 'Kat. ' + t.Preis_Kategorie_der_Opportunity__c;
                                //t.Abrechnung_CPO__c = AP_gesamt_map.get(posName).Id;
                                t.Abrechnung_CPO__c = AP_gesamt_cpo_map.get(String.valueOf(t.Wert_des_Partner_Tickets_CPO__c)).Id;
                            }
                            if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPO einzeln')){
                                t.Abrechnung_CPO__c = AP_einzeln_map.get(t).Id;
                            }
                            t.CPO_abgerechnet_worden_am__c = today;
                            t.Status_CPO__c = after_invoice_status;
                        }
                        to_update_tickets.addAll(ticket_list);
                        // close the rest of opportunity tickets
                        to_update_tickets.addAll(closeRemainingCPOTickets(ticket_list));
                    }
                    update to_update_tickets;
                }
                System.debug('Mansi:::: ta  inja ro miad::::update to_update_tickets');
            }

        } catch (Exception ex) {
            // Roll the database back to before we saved ANYTHING
            Database.rollback(sp);
            System.debug(ex);
            return new ApexPages.message(ApexPages.severity.Error, ex.getMessage());
        }
        return new ApexPages.message(ApexPages.severity.Confirm, 'Abrechnung abgeschlossen erfolgreich!');
    }
    
    public Boolean generateInvoice(){
        Boolean flag = false;
        for(Id partnerId : partnerId_list){
            Abrechnung_Partner__c invoice = new Abrechnung_Partner__c();
            invoice.Partner__c = partnerId;
            invoice_map.put(partnerId, invoice);           
            Boolean has_pos = generateInvoicePos(partnerId);
            if(flag == false){
                flag = has_pos;
            }       
        }
        return flag;
    }
    
    private Boolean generateInvoicePos(Id partnerId){
        Boolean has_pos = false;
        List<Abrechnungspositionen__c> cpl_pos_list = new List<Abrechnungspositionen__c>();
        List<Abrechnungspositionen__c> cpo_pos_list = new List<Abrechnungspositionen__c>();        
        String queryString =        ' select Id, '+
                                  + ' Status_CPL__c, '+
                                  + ' Kostenstelle__c,  '+
                                 // + ' Kostentr_ger__c, '+
                                  + ' Partner_Produkt__c, '+
                                  + ' Partner_Produkt__r.Produktgruppe__c, '+
                                  + ' Preis_Kategorie_der_Opportunity__c, '+
                                  + ' Opportunity__c, '+
                                  + ' Wert_des_Partner_Tickets_CPL__c, '+
                                  + ' Partner_Produkt__r.Abrechnungsmethode__c, '+
                                  + ' Opportunity__r.Name, '+
                                  + ' Abrechnung_CPL__c  '+
                                  + ' from Partner_Ticket__c  '+
                                  + ' where Partner__c = \''+ partnerId + '\' '+
                                  + ' and Status_CPL__c = \''+ cpl_status + '\' '+
                                  + ' and Wert_des_Partner_Tickets_CPL__c != null ';
        String ppArr_parameter = '\'\'';
        if(ppArr != null && ppArr.size() > 0 ){
            for(Integer i=0; i<ppArr.size() ; i += 1){
                if( i == 0 ){
                    ppArr_parameter = '\''+ ppArr[i] +'\'';
                }else{
                    ppArr_parameter = ppArr_parameter + ',\''+ ppArr[i] +'\'';
                }
            } 
        }
        queryString += ' and Partner_Produkt__c IN (' + ppArr_parameter + ') ';
        if(timePeriodValue == IndividualPartnerInvoicing.letztenMonatKey){
            queryString += ' and createdDate = LAST_MONTH ';
        }
        else if(timePeriodValue == IndividualPartnerInvoicing.diesenMonatKey){
            queryString += ' and DAY_IN_MONTH(createdDate) >= 1 '+
                           ' and DAY_IN_MONTH(createdDate) <= 15 '+
                           ' and createdDate = THIS_MONTH ';
        }
        else if(timePeriodValue == IndividualPartnerInvoicing.letztesQuartalKey){
            queryString += ' and createdDate = LAST_QUARTER ';
        }
        System.debug('mansi::: generateInvoicePos.queryString:::' + queryString);
        List<Partner_Ticket__c> currCplTickets = Database.query(queryString);
                
        if(currCplTickets != null && currCplTickets.size()>0) {
            cplTickets.put(partnerId, currCplTickets);
            //Abrechnungspositionen__c pos = new Abrechnungspositionen__c();
            //pos.Positions_Typ__c = invoitcePositionTypeCpl;
            //pos.Anzahl_der_Tickets_CPL__c = currCplTickets.size();
            //Decimal totalAmount = 0;
            // AM 22.09.2016
            
            set<id> oppIdSet = new set<id>();
            for(Partner_Ticket__c t: currCplTickets) oppIdSet.add(t.Opportunity__c);
            list<OpportunityContactRole> contactRoles = [select OpportunityId, Contact.firstname, Contact.lastname from OpportunityContactRole where OpportunityId IN :oppIdSet and IsDeleted = false and IsPrimary = true];
            map<id, OpportunityContactRole> oppCRmapCpl = new map<id, OpportunityContactRole>();
            if((contactRoles != null) &&(contactRoles.size() > 0)) {
                for(OpportunityContactRole ocr : contactRoles) oppCRmapCpl.put(ocr.OpportunityId, ocr);
            }
            
            map<string, Decimal> cpl_price_map = new map<string, Decimal>();
            map<string, Integer> cpl_number_map = new map<string, Integer>();
            map<string, String> cpl_pos_name_map = new map<string, String>();
    
            for(Partner_Ticket__c t: currCplTickets){
                if(t.Wert_des_Partner_Tickets_CPL__c != null){
                     kst = t.kostenstelle__c;
                     //ktg = t.kostentr_ger__c;
                     String beschreibung = invoitcePositionTypeCpl + t.Partner_Produkt__r.Produktgruppe__c + ', ' + 'Kat. ' + t.Preis_Kategorie_der_Opportunity__c;                     
                     Decimal wert = t.Wert_des_Partner_Tickets_CPL__c;
                    //totalAmount += t.Wert_des_Partner_Tickets_CPL__c;
                    
                    if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && (t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL kumuliert') || t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL und CPO kumuliert'))){
                        String sWert = String.valueOf(wert);
                        
                        cpl_pos_name_map.put(sWert, beschreibung);
                        cpl_price_map.put(sWert, wert);
                        
                        if(cpl_number_map.get(sWert) == null){
                            cpl_number_map.put(sWert, 1);
                        }
                        else{
                            Integer value = cpl_number_map.get(sWert) + 1; 
                            cpl_number_map.put(sWert, value);
                        }
                        
                        //cpl_price_map.put(beschreibung, wert);
                    
                        //if(cpl_number_map.get(beschreibung) == null){
                        //    cpl_number_map.put(beschreibung, 1);
                        //}
                        //else {
                        //    Integer value = cpl_number_map.get(beschreibung) + 1; 
                        //    cpl_number_map.put(beschreibung, value);
                        //}     
                    }      
                    
                    if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && (t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL einzeln') || t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPL und CPO einzeln'))){
                         string oppContRole = '';
                         if(oppCRmapCpl.containsKey(t.Opportunity__c)) {
                             oppContRole = oppCRmapCpl.get(t.Opportunity__c).Contact.firstname + ' ' + oppCRmapCpl.get(t.Opportunity__c).Contact.lastname;
                         }
                         
                         Abrechnungspositionen__c pos = new Abrechnungspositionen__c();
                         pos.Einzelpreis__c = wert;
                         pos.Kostenstelle__c = kst;
                        // pos.Kostentr_ger__c = ktg;
                         pos.Positions_Typ__c = invoitcePositionTypeCpl;
                         pos.Anzahl_der_Tickets_CPL__c = 1;
                         pos.AbrechnungspositionName__c = beschreibung + ', ' + t.Opportunity__r.Name + ', ASP: ' + oppContRole;
                         pos.Gesamtwert_CPL__c = wert;   
                         cpl_pos_list.add(pos);
                         invoicePos_CPL_map.put(partnerId, cpl_pos_list);
                         AP_einzeln_map.put(t, pos);
                         has_pos = true;                   
                    }         
                }                                                
            }
          
            for(string sWert: cpl_price_map.keySet()){                 
                 Decimal gesamtpreis = cpl_price_map.get(sWert) * cpl_number_map.get(sWert); 
                 
                 Abrechnungspositionen__c pos = new Abrechnungspositionen__c();
                 pos.Einzelpreis__c = cpl_price_map.get(sWert);
                 pos.Kostenstelle__c = kst;
                 //pos.Kostentr_ger__c = ktg;
                 pos.Positions_Typ__c = invoitcePositionTypeCpl;
                 pos.Anzahl_der_Tickets_CPL__c = cpl_number_map.get(sWert);
                 pos.AbrechnungspositionName__c = cpl_pos_name_map.get(sWert);
                 pos.Gesamtwert_CPL__c = gesamtpreis;   
                 cpl_pos_list.add(pos);
                 invoicePos_CPL_map.put(partnerId, cpl_pos_list);
                 AP_gesamt_cpl_map.put(sWert, pos);
                 has_pos = true;                
            }
                  
        }
        
        List<Partner_Ticket__c> currCpoTickets = [select Id, 
                                                         Status_CPO__c,
                                                         Kostenstelle__c,
                                                        // Kostentr_ger__c, 
                                                         Partner_Produkt__c,
                                                         Partner_Produkt__r.Produktgruppe__c, 
                                                         Preis_Kategorie_der_Opportunity__c, 
                                                         Opportunity__c, 
                                                         Wert_des_Partner_Tickets_CPO__c, 
                                                         Partner_Produkt__r.Abrechnungsmethode__c,
                                                         Opportunity__r.Name,
                                                         Abrechnung_CPO__c 
                                                         from Partner_Ticket__c 
                                                         where Partner_Produkt__c IN: ppArr and Partner__c = :partnerId and Status_CPO__c = :cpo_status and Wert_des_Partner_Tickets_CPO__c != null ];      
        if(currCpoTickets != null && currCpoTickets.size()>0){
            cpoTickets.put(partnerId, currCpoTickets);
            
            //Abrechnungspositionen__c pos = new Abrechnungspositionen__c();
            //pos.Positions_Typ__c = invoitcePositionTypeCpo;
            //pos.Anzahl_der_Tickets_CPO__c = currCpoTickets.size();
            //Decimal totalAmount = 0;
            set<id> oppIdSet = new set<id>();
            for(Partner_Ticket__c t: currCpoTickets) oppIdSet.add(t.Opportunity__c);
            list<OpportunityContactRole> contactRoles = [select OpportunityId, Contact.firstname, Contact.lastname from OpportunityContactRole where OpportunityId IN :oppIdSet and IsDeleted = false and IsPrimary = true];
            map<id, OpportunityContactRole> oppCRmapCpo = new map<id, OpportunityContactRole>();
            if((contactRoles != null) &&(contactRoles.size() > 0)) {
                for(OpportunityContactRole ocr : contactRoles) oppCRmapCpo.put(ocr.OpportunityId, ocr);
            }
            
            map<string, Decimal> cpo_price_map = new map<string, Decimal>();
            map<string, Integer> cpo_number_map = new map<string, Integer>();  
            map<string, String> cpo_pos_name_map = new map<string, String>();        
    
            for(Partner_Ticket__c t: currCpoTickets){          
                if(t.Wert_des_Partner_Tickets_CPO__c != null){
                    KST = t.kostenstelle__c;
                  //  KTG = t.kostentr_ger__c;
                    String beschreibung = invoitcePositionTypeCpo + t.Partner_Produkt__r.Produktgruppe__c + ', ' + 'Kat. ' + t.Preis_Kategorie_der_Opportunity__c;                     
                    Decimal wert = t.Wert_des_Partner_Tickets_CPO__c;
                    //totalAmount += t.Wert_des_Partner_Tickets_CPO__c;   
                    
                    if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPO kumuliert')){                 
                        String sWert = String.valueOf(wert);
                        
                        cpo_pos_name_map.put(sWert, beschreibung);
                        cpo_price_map.put(sWert, wert);
                        if(cpo_number_map.get(sWert) == null){
                            cpo_number_map.put(sWert, 1);
                        }
                        else {
                            Integer value = cpo_number_map.get(sWert) + 1; 
                            cpo_number_map.put(sWert, value);
                        }
                        
                        //cpo_price_map.put(beschreibung, wert);                              
                   
                        //if(cpo_number_map.get(beschreibung) == null){
                        //    cpo_number_map.put(beschreibung, 1);
                        //}
                        //else {
                        //    Integer value = cpo_number_map.get(beschreibung) + 1; 
                        //    cpo_number_map.put(beschreibung, value);
                        //} 
                    } 
                    
                    if(t.Partner_Produkt__r.Abrechnungsmethode__c != null && t.Partner_Produkt__r.Abrechnungsmethode__c.contains('CPO einzeln')){      
                         string oppContRole = '';
                         if(oppCRmapCpo.containsKey(t.Opportunity__c)) {
                             oppContRole = oppCRmapCpo.get(t.Opportunity__c).Contact.firstname + ' ' + oppCRmapCpo.get(t.Opportunity__c).Contact.lastname;
                         }                        

                        Abrechnungspositionen__c pos = new Abrechnungspositionen__c();
                         pos.Einzelpreis__c = wert;
                         pos.Kostenstelle__c = KST;
                   //      pos.Kostentr_ger__c = KTG;
                         pos.Positions_Typ__c = invoitcePositionTypeCpo;
                         pos.Anzahl_der_Tickets_CPO__c = 1;
                         pos.AbrechnungspositionName__c = beschreibung + ', ' + t.Opportunity__r.Name+ ', ASP: ' + oppContRole;
                         pos.Gesamtwert_CPO__c = wert;   
                         cpo_pos_list.add(pos);
                         invoicePos_CPO_map.put(partnerId, cpo_pos_list);
                         AP_einzeln_map.put(t, pos);
                         has_pos = true;                      
                    }                                    
                }                              
            }
            
            for(string sWert: cpo_price_map.keySet()){
                 Decimal gesamtpreis = cpo_price_map.get(sWert) * cpo_number_map.get(sWert); 
                 
                 Abrechnungspositionen__c pos = new Abrechnungspositionen__c();
                 pos.Einzelpreis__c = cpo_price_map.get(sWert);
                 pos.Kostenstelle__c = KST;
               //  pos.Kostentr_ger__c = KTG;
                 pos.Positions_Typ__c = invoitcePositionTypeCpo;
                 pos.Anzahl_der_Tickets_CPO__c = cpo_number_map.get(sWert);
                 pos.AbrechnungspositionName__c = cpo_pos_name_map.get(sWert);
                 pos.Gesamtwert_CPO__c = gesamtpreis;   
                 cpo_pos_list.add(pos);
                 invoicePos_CPO_map.put(partnerId, cpo_pos_list);
                 AP_gesamt_cpo_map.put(sWert, pos);
                 has_pos = true;                
            } 
                              
        }
        return has_pos;
    }
    
    private List<Partner_Ticket__c> closeRemainingCPOTickets(List<Partner_Ticket__c> tlist){
        List<Partner_Ticket__c> to_close_tickets = new List<Partner_Ticket__c>();
        for (Partner_Ticket__c t : tlist){
            List<Partner_Ticket__c> remainingCpoTickets = [select id, Status_CPO__c from Partner_Ticket__c where Opportunity__c = :t.Opportunity__c and Id != :t.Id and Status_CPO__c = :cpo_status_uebermittelt ];
            if(remainingCpoTickets != null && remainingCpoTickets.size()>0){
                for(Partner_Ticket__c rt : remainingCpoTickets){
                    rt.Status_CPO__c = cpo_status_closed;
                }
                to_close_tickets.addAll(remainingCpoTickets);
            }
        }
        return to_close_tickets;
    }
    
}