global class updateCPOPrices{
    
    @InvocableMethod
    public static void updatePrices(List<string> parameters) {
        System.debug('mansi in method updateCPOPrices.updatePrices::::partnerTicketId:::' + parameters.get(0));
        
        Partner_Ticket__c pt;
        List<Partner_Ticket__c> ptList = [select Id, Preis_Kategorie_der_Opportunity__c, Partner_Produkt__c from Partner_Ticket__c where Id = :parameters.get(0) ];
        if(ptList != null && ptList.size()>0){
            pt = ptList[0];
        }
        
        Partner_Preise__c prc;
        Integer ticketsCount = [select count() from Partner_Ticket__c where Partner_Produkt__c = :pt.Partner_Produkt__c and (Status_CPO__c = 'Übermittelt' or Status_CPO__c = 'Abrechenbar') ];
        List<Partner_Preise__c> prclist = [select Id, CPO_Exklusiv_Festpreis__c, CPO_Exklusiv_Prozentual__c, 
                            CPO_Kat_1_Festpreis__c, CPO_Kat_1_Prozentual__c, CPO_Kat_2_Festpreis__c, CPO_Kat_2_Prozentual__c, preis_gueltig_ab_Menge__c 
                            from Partner_Preise__c where preis_gueltig_ab_Menge__c  <= :ticketsCount and Partner_Produkt__c  = :pt.Partner_Produkt__c order by preis_gueltig_ab_Menge__c desc Nulls last limit 1];
        if( prclist != null && prclist.size()> 0){
            prc = prclist[0];
            
            // update current ticket and all te previous tickets as well
            ptList = [select Id, Preis_Kategorie_der_Opportunity__c, Auftragswert_Partner__c, Wert_des_Partner_Tickets_CPO__c from Partner_Ticket__c where Partner_Produkt__c = :pt.Partner_Produkt__c and Status_CPO__c = 'Abrechenbar' ];
            for( Partner_Ticket__c t: ptList ){
                
                if(t.Preis_Kategorie_der_Opportunity__c == '1'){
                    if(prc.CPO_Kat_1_Festpreis__c != null){
                        t.Wert_des_Partner_Tickets_CPO__c = prc.CPO_Kat_1_Festpreis__c;
                    }
                    if(prc.CPO_Kat_1_Prozentual__c != null){
                        t.Wert_des_Partner_Tickets_CPO__c = t.Auftragswert_Partner__c * prc.CPO_Kat_1_Prozentual__c * 0.01;
                    }
                    
                }else if(t.Preis_Kategorie_der_Opportunity__c == '2'){
                    if(prc.CPO_Kat_2_Festpreis__c != null){
                        t.Wert_des_Partner_Tickets_CPO__c = prc.CPO_Kat_2_Festpreis__c;
                    }
                    if(prc.CPO_Kat_2_Prozentual__c != null){
                        t.Wert_des_Partner_Tickets_CPO__c = t.Auftragswert_Partner__c * prc.CPO_Kat_2_Prozentual__c * 0.01;
                    }
                }if(t.Preis_Kategorie_der_Opportunity__c == 'Exklusiv'){
                    if(prc.CPO_Exklusiv_Festpreis__c != null){
                        t.Wert_des_Partner_Tickets_CPO__c = prc.CPO_Exklusiv_Festpreis__c;
                    }
                    if(prc.CPO_Exklusiv_Prozentual__c != null){
                        t.Wert_des_Partner_Tickets_CPO__c = t.Auftragswert_Partner__c * prc.CPO_Exklusiv_Prozentual__c * 0.01;
                    }
                }
                System.debug('mansi:::'+ 't.Wert_des_Partner_Tickets_CPO__c ::::' + t.Wert_des_Partner_Tickets_CPO__c );
            }
            update ptList;
        }
       
    }
    
}