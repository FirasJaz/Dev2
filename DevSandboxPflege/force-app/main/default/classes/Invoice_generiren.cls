/****************************************************************************************************************************
// Erstellt 04.10.2015 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: LS.id
//
//****************************************************************************************************************************
//
// Beschreibung:
// Erstellen eine Rechnung aus LS für Magento-shop
//
//****************************************************************************************************************************
//Änderungen:
// 17.11.2015 von AM - alle Preise in Brutto
// 18.11.2015 von AM - Rechnungsnummer_shop__c
// 18.02.2016 von AM - anpassuneg weg. CC 
// 18.03.2016 von TK - Änderung der Versandkosten von 3.90 auf 4.90
// 21.03.2016 von AM - #115928089 Custom Settings Einbauen (Vresandkosten__c)
//****************************************************************************************************************************
*/


global with sharing class Invoice_generiren {

    private list<Rechnung__c> RGList = new list<Rechnung__c>();
    private map<Id, list<Rechnungsposition__c>> RPMap = new map<Id, list<Rechnungsposition__c>>();
    private Map<ID, list<Lieferscheinposition__c>> MapLsLpos = new Map<ID, list<Lieferscheinposition__c>> () ;
    private Lieferschein__c Ls;
    list<Rechnung__c> inserted_rgl = new list<Rechnung__c>();
    // wenn diese true ist so werden die Daten (Preis, Amount, tax usw) aus Magento-Lead genommen werden
    // Andererfalls rechnen wir diese hier auf Brutto-Preis Basis
    
    private boolean useMagentoAmount = false;
    private decimal versandkosten {get; set;}
    
    private Magento__c magento_setting {get; set;}
    
    // constructor for creating many invoices for many Lieferschein
    public Invoice_generiren(Map<ID, list<Lieferscheinposition__c>> MapLsLp){
        MapLsLpos= MapLsLp;
        magento_setting = Magento__c.getValues('Default');
        versandkosten = magento_setting.Versandkosten__c;
        if(versandkosten == null) versandkosten = 4.9;
    }
    
    public Invoice_generiren(ID Lieferschein_id){
        versandkosten = 4.9;
        try {
        magento_setting = Magento__c.getValues('Default');
        versandkosten = magento_setting.Versandkosten__c;
        }
        catch(System.Exception e) {
            versandkosten = 4.9;
        }
        
        system.debug ('######################### Mansi:: Lieferschein_id::' + Lieferschein_id );
        Lieferschein__c tmpLs = [select Id,Kunde__c,Lieferdatum__c  from Lieferschein__c where Id = :Lieferschein_id];
        system.debug ('######################### Mansi:: tmpLs.id::' + tmpLs.Id );
        List<Lieferscheinposition__c> LpList = [SELECT 
                        l.Status__c, l.Name, l.Id, 
                        l.Menge__c, l.VZ_bis__c, l.VZ_von__c,
                        l.Lieferschein__c,
                        l.Lieferdatum__c, 
                        l.Lieferschein__r.Name, 
                        l.Lieferschein__r.Lieferdatum__c,
                        l.Lieferschein__r.Kunde__c,
 
                        l.Artikel__r.Name, 
                        l.Artikel__r.PZN__c,
                        l.Artikel__r.a_pac_apo_Langname__c,
                        l.Artikel__r.Artikelnummer_des_Herstellers__c,
                        l.Artikel__r.Anlage_4_Preis__c,
                        l.Artikel__r.EVK__c,  
                        l.Artikel__r.v_pos_1_Name__c,
                        l.Artikel__r.Einheit__c,
                        l.Artikel__r.a_pac_apo_EAN_UPC__c,
                         
                        l.Kunde__c, 
                        l.Kunde__r.Name,                    
                        l.Kunde__r.Pflegedienst__r.Name, 
                        l.Kunde__r.Pflegedienst__r.Abena_Sammellieferung__c,
                        l.Kunde__r.Krankenkasse__r.Name, 
                        l.Kunde__r.Liefermodus__c, 
                        l.Kunde__r.Art_der_Bestellung__c,
                        l.Kunde__r.Vorname__c, 
                        l.Kunde__r.Name__c, 
                        l.Kunde__r.Kundennummer_abena__c, 
                        l.Kunde__r.Versichertennummer__c, 
                        l.Kunde__r.Ort__c,
                        l.Kunde__r.PLZ__c,
                        l.Kunde__r.Stra_e__c,
                        l.Kunde__r.Geburtsdatum_text__c,  
                        l.Kunde__r.Material_Einmalhandschuhe__c,
                        l.Kunde__r.Gr_e_Einmalhandschuhe__c,
                        
                        l.Auftragsposition__c,
                        l.Auftragsposition__r.Name, 
                        l.Auftragsposition__r.Restmenge__c, 
                        l.Auftragsposition__r.Gen_Menge_Stk_Mon__c, 
                        l.Auftragsposition__r.Gen_Menge_ges__c,
                        l.Auftragsposition__r.genehmigt_bis__c, 
                        l.Auftragsposition__r.Lieferzeitraum__c,
                        l.Auftragsposition__r.Preis__c,
                        l.Auftragsposition__r.Gesamtpreis__c,
                        l.Auftragsposition__r.Positionsart__c,
                        l.Auftragsposition__r.amount__c,
                        l.Auftragsposition__r.grand_amount__c,  
                        l.Auftragsposition__r.tax_amount__c,
                        l.Auftragsposition__r.Auftrag__r.Bezeichnung__c,
                        l.Auftragsposition__r.Auftrag__r.Magento_order_id_c__c,
                        l.Auftragsposition__r.Auftrag__r.magento_total_amount__c,
                        l.Auftragsposition__r.Auftrag__r.magento_grand_total__c,
                        l.Auftragsposition__r.Auftrag__r.magento_shipping_amount__c,
                        l.Auftragsposition__r.Auftrag__r.magento_discount_amount__c,
                        l.Auftragsposition__r.Auftrag__r.magento_tax_amount__c,
                        l.Auftragsposition__r.Auftrag__r.magento_tax_amount02__c
                        FROM Lieferscheinposition__c l
                      where l.Lieferschein__c = :Lieferschein_id];     
        if(LpList != null && LpList.size()>0){
            MapLsLpos.put(Lieferschein_id, LpList);
        }
        system.debug ('######################### Mansi:: LpList.size()::' + LpList.size() );
        create_invoice(tmpLs);
        // insert_invoice();
        
    }

    
    public void create_invoice(Lieferschein__c Ls) {
        try{
        boolean has_RP = false;
        String Magento_order_id;
        decimal magento_discount_amount = 0.00;
        decimal magento_total_amount = 0.00;
        decimal magento_grand_total = 0.00;
        decimal magento_shipping_amount = 0.00;
        decimal magento_tax_amount = 0.00;
        
        Rechnung__c RG = new Rechnung__c();
        list<Rechnungsposition__c> rpl = new list<Rechnungsposition__c>();
        string grnr_shop = neueNummerShop(); 
        list<Lieferscheinposition__c> lpl = MapLsLpos.get(Ls.ID);
        system.debug('####################### Mansi list<Lieferscheinposition__c>.size()::'+ lpl.size());
        if(lpl != null && lpl.size()> 0) {
            
            for(Lieferscheinposition__c lp : lpl) {
                Magento_order_id = lp.Auftragsposition__r.Auftrag__r.Magento_order_id_c__c;
                if( Magento_order_id != null && !Magento_order_id.trim().equals('')){
                    try {
                    if(!has_RP) {
                        magento_discount_amount = lp.Auftragsposition__r.Auftrag__r.magento_discount_amount__c;
                        magento_total_amount = lp.Auftragsposition__r.Auftrag__r.magento_total_amount__c;
                        magento_grand_total = lp.Auftragsposition__r.Auftrag__r.magento_grand_total__c;
                        magento_shipping_amount = lp.Auftragsposition__r.Auftrag__r.magento_shipping_amount__c;
                        magento_tax_amount = lp.Auftragsposition__r.Auftrag__r.magento_tax_amount__c;
                    }
                    system.debug('####################### Mansi in create_invoice Magento_order_id::'+ Magento_order_id);
                    Rechnungsposition__c RP = new Rechnungsposition__c();
                    RP.Lieferscheinposition__c = lp.Id;
                    RP.Kunde__c = Ls.Kunde__c;
                    if(useMagentoAmount) {
                    // Verfahren mit den Magento-Daten
                        if(lp.Auftragsposition__r.grand_amount__c != null){
                            RP.Einzelpreis__c = lp.Auftragsposition__r.Preis__c;
                            RP.Gesamtpreis_Brutto__c = lp.Auftragsposition__r.grand_amount__c;                  
                        }
                        else {
                            RP.Einzelpreis__c = lp.Auftragsposition__r.Preis__c;
                            RP.Gesamtpreis_Brutto__c = lp.Auftragsposition__r.Gesamtpreis__c;
                        }
                        if(lp.Auftragsposition__r.tax_amount__c != null) {
                            RP.MWSt1__c = lp.Auftragsposition__r.tax_amount__c;
                        }   
                    }
                    else {
                    // Verfahren mit den SF-Daten
                        
                        RP.Einzelpreis__c = lp.Artikel__r.EVK__c;
                        system.debug('####################### alex004 RP.Einzelpreis__c=' + RP.Einzelpreis__c);
                        if(lp.Menge__c != null) {
                            RP.Gesamtpreis_Brutto__c = RP.Einzelpreis__c * lp.Menge__c;
                        }
                        else {
                            RP.Gesamtpreis_Brutto__c = RP.Einzelpreis__c;
                        }
                    }                   
                    rpl.add(RP);
                    has_RP = true;
                    }
                    catch (System.Exception e) {
                        system.debug('####################### alex100 Fehler beim RP erstellen e=' + e);
                    }
                }
            }
            if(useMagentoAmount) {
                if(magento_shipping_amount > 0) {
                    Rechnungsposition__c RP = new Rechnungsposition__c();
                    RP.Kunde__c = Ls.Kunde__c;
                    RP.Versandkosten__c = true;
                    RP.Positionstext__c = 'Versandkosten';  
                    RP.Gesamtpreis_Brutto__c = magento_shipping_amount;
                    rpl.add(RP);
                }
                if(magento_discount_amount > 0) {
                    Rechnungsposition__c RP = new Rechnungsposition__c();
                    RP.Kunde__c = Ls.Kunde__c;
                    RP.Versandkosten__c = true;
                    RP.Positionstext__c = 'Rabatt'; 
                    RP.Gesamtpreis_Brutto__c = magento_discount_amount;
                    rpl.add(RP);
                }
            }           
        }
        if(has_RP) {
            system.debug('####################### Mansi has_RP::'+ Magento_order_id);
            RG.Rechnung_text__c = 'OrderID: ' + Magento_order_id;
            RG.Kunde__c = Ls.Kunde__c;
            RG.Lieferschein__c = Ls.Id;
            RG.Rechnungsnummer_shop__c = grnr_shop; 
            // RGList.add(RG);
            // RPMap.put(Ls.Id, rpl);
            system.debug('####################### alex001');
            try {
                insert RG;
            }
            catch(System.Exception e) {
                system.debug('####################### insert rg error:'+ e);
            }
            system.debug('####################### alex002 rg.id=' + rg.id);
            if(RG.id != null) {
                Decimal sum = 0.00;
                for(Rechnungsposition__c RP : rpl) {
                    RP.Rechnung__c = RG.id;
                    if(RP.Gesamtpreis_Brutto__c != null){
                        sum += RP.Gesamtpreis_Brutto__c;
                    }
                }
                system.debug('####################### alex002 sum=' + sum );
                try{
                    insert rpl;
                    system.debug('######################### Mansi + after insert RPList' );
                }catch(system.Dmlexception rechnung_position){
                    system.debug('#########################insert RGList Rechnung__c=' + rechnung_position);
                } 
                if(sum <= 28.99){
                    Rechnungsposition__c extra_RP = new Rechnungsposition__c();
                    // extra_RP.Gesamtpreis_Brutto__c = 4.90;
                    extra_RP.Gesamtpreis_Brutto__c = versandkosten;
                    extra_RP.Kunde__c = RG.Kunde__c;
                    extra_RP.Rechnung__c = RG.Id;
                    extra_RP.Versandkosten__c = true;
                    extra_RP.Positionstext__c = 'Versandkosten';
                    try {
                        insert extra_RP;
                        system.debug('######################### Mansi + in Versandkosten extra_RP::' + extra_RP );
                    }
                    catch(system.Dmlexception rechnung_position){
                        system.debug('#########################insert RGList Rechnung__c=' + rechnung_position);
                    }                                       
                }
                inserted_rgl = [SELECT id, name, PDF_generiert__c, Rechnungsnummer_shop__c, Kunde__r.Name__c, Kunde__r.Vorname__c FROM Rechnung__c WHERE id = : RG.id];
                
            }
        } 
        }catch(Exception e){
            system.debug('####################### Mansi general error in create_invoice::'+ e);
        }
    }
    
    public void insert_invoice(){
        list<Rechnungsposition__c> RPList = new list<Rechnungsposition__c>();
        list<Rechnungsposition__c> rpl = new list<Rechnungsposition__c>();
        try{
            system.debug('####################### Mansi RGList.size() in insert_invoice::'+ RGList.size());
            insert RGList;
            system.debug('######################### Mansi + after insert RGList' );
        }catch(system.Dmlexception rechnung){
            system.debug('#########################insert RGList Rechnung__c=' + rechnung);
        }
        
        inserted_rgl = [SELECT Id, Rechnung_text__c,Lieferschein__c, PDF_generiert__c,Kunde__c, Name, Kunde__r.Name__c, Kunde__r.Vorname__c FROM Rechnung__c 
                        WHERE Lieferschein__c IN :RPMap.keySet()
                       order by Rechnung__c.Id Desc limit :RPMap.keySet().size()];
        system.debug('######################### Mansi + rgl.size()::' + inserted_rgl.size() );
        for(Rechnung__c r : inserted_rgl){
            rpl = RPMap.get(r.Lieferschein__c);
            Decimal sum = 0.00;
            system.debug('######################### Mansi + rpl.size()::' + rpl.size() );
            for(Rechnungsposition__c RP : rpl){
                if(RP.Gesamtpreis_Brutto__c != null){
                    sum += RP.Gesamtpreis_Brutto__c;
                }
                RP.Rechnung__c = r.Id;
                    system.debug('######################### Mansi + r.Id ::' + r.Id );
                RPList.add(RP);
            }
            // try{
            // Versandkosten
            // if(sum <= 28.99){
                // Rechnungsposition__c extra_RP = new Rechnungsposition__c();
                // extra_RP.Gesamtpreis_Brutto__c = 4.90;
                // extra_RP.Kunde__c = r.Kunde__c;
                // extra_RP.Rechnung__c = r.Id;
                // extra_RP.Versandkosten__c = true;
                // extra_RP.Positionstext__c = 'Versandkosten';
                // RPList.add(extra_RP);
                // system.debug('######################### Mansi + in Versandkosten extra_RP::' + extra_RP );
            // } 
            // }catch(Exception e){
                    // system.debug('######################### Mansi + after Versandkosten::' + e );
            // }           
        }
        system.debug('######################### Mansi + after Versandkosten RPList.size()::' + RPList.size() );
        try{
            insert RPList;
            system.debug('######################### Mansi + after insert RPList' );
        }catch(system.Dmlexception rechnung_position){
            system.debug('#########################insert RGList Rechnung__c=' + rechnung_position);
        }        
    }
    
    public List<Rechnung__c> getInsertedRgList(){
        return inserted_rgl;
    }
    
    private string neueNummerShop() {
        string rgnr = null;
        string such = 'SR' + datetime.now().format('yyyyMM');
        string partone = such + '-';
        such = such + '%';
        list<Rechnung__c> rgList = [SELECT Rechnungsnummer_shop__c FROM Rechnung__c WHERE Rechnungsnummer_shop__c LIKE : such ORDER BY Rechnungsnummer_shop__c DESC LIMIT 1];
        if((rgList != null) && (rgList.size() > 0)) {
            try {
                string[] sp = rgList[0].Rechnungsnummer_shop__c.split('-', 2);
                integer n = integer.valueOf(sp[1]);
                n++;
                string parttwo = string.valueOf(n);
                while (parttwo.length() < 5) {
                    parttwo = '0' + parttwo;
                }       
                rgnr = partone + parttwo;
            }
            catch(System.Exception e) {}
            
        }
        if(rgnr == null) rgnr = partone + '00001';
        return rgnr;
    }
   
}