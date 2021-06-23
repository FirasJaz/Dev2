/*/****************************************************************************************************************************
// Erstellt 29.05.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: List delivery_line__c (Bedarf, jetzt liefern)
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  XML für Hartmann erstellen
//  Delivery Note generieren
//  Bedarf generieren 
//****************************************************************************************************************************
//Änderungen:       
// 16.09.2019   AM  Bedarfe immer generiere, Genehmigung nicht prüfen
// 24.09.2019   AM  enmalig war nicht abgefragt und als monatlich btrachtet
// 21.11.2019   AM  #169619597 - Lieferungen KUWV u CB zusammenführen
// 23.03.2020   am  #171895823 - Anforderungen Lieferscheinpositionen für April 
// 06.05.2020   AM  #172578887 - Preisänderung
// 26.05.2020   AM  #173000185 - (00002477) - Temp Product
//                  wir erstellen beim Start die Liste delivery_lines aus temp products, die im Zeitraum liegen.
//                  Beim Kundenwechsel addieren wir diese zu den Delivery Notes.
//                  Beime Bedarferstellen werden die temp products nicht gezogen.
// 25.08.2020   AM  #174005505 (00002544) - Liefermenge Reduzieren
// 02.04.2021   AM  00002637 - Es werden nur die ausgewählte LMR in einer Map geladen werden 
// 02.05.2021   AM  00002650 - DHL/DPD Anpassung der Schnittstelle von Hartmann
//****************************************************************************************************************************
*/
public with sharing class delivery_xml {
    private List<String> errorList = new List<String>();
    private integer totalDN = 0;
    private string kdnrBeiHartmann{get; set;}
    private CompanyInfo__c FirmenInfo {get; set;}
    private Organization orgDetails {get; set;}

    private Map<id, contact> contactMap = new Map<id, contact>();
    private Map<id, contact_address__c> deliveryAddressMap = new Map<id, contact_address__c>();
    private Map<id, Delivery_Note__c> dnMap = new Map<id, Delivery_Note__c>(); 
    private Map<id, id> DnCtMap = new Map<id, id>(); 
    private Map<id, list<Delivery_Line__c>> MapDnDl = new Map<ID, list<Delivery_Line__c>> () ;
    private Map<id, Map<id, Curabox_Genehmigungsposition__c>> gpMap = new Map<id, Map<id, Curabox_Genehmigungsposition__c>>();

    private List<Delivery_Line__c> LSpos {get; set;}
    private List<Delivery_Line__c> Bedarf = new List<Delivery_Line__c>();
    private List<ContentVersion> xmlList = new List<ContentVersion>();

    private set<id> currentOrdersIdSet = new Set<id>();
    private integer maxFutureBedarf = 0;
    private Map<id, date> CtNextDeliveryDateMap = new Map<id, date>(); 

    private Map<String, Bedarfe_Reduzieren__c> neueBedarfeMap = Bedarfe_Reduzieren__c.getAll(); // key=ProductId, values maxQty neukunde, maxQty altkunde
    private Set<id> neueKundeIdSet = new Set<id>(); // contactId mit contact_status.Antrag_bewilligt_abgelehnt_am__c > thresholdDate
    private Set<id> alteKundeIdSet = new Set<id>(); // contactId mit contact_status.Antrag_bewilligt_abgelehnt_am__c <= thresholdDate
    private date thresholdDate = date.newInstance(2020, 3, 25); // Schwelledatum Kunde Alt / Neu
    private List<Delivery_Line__c> dlWithZeroQuantity = new List<Delivery_Line__c>();

    private List<Delivery_Line__c> tempProductDeliveryLinesList {get; set;}

    private map<string, map<id, LiefermengeReduzierung__c>> reduceQuantityMap = new map<string, map<id, LiefermengeReduzierung__c>>();
    private liefermengeReduzierenHelper.reduceDeliveryQuantityResult rdqr;
    private Map<id, string> dnMd5Map = new Map<id, string>(); 

    // constructor 1
    public delivery_xml() {     
        FirmenInfo = CompanyInfo__c.getValues('Default');
        kdnrBeiHartmann = FirmenInfo.KDNR_bei_Lieferant__c;  
        orgDetails = [SELECT Id, Name, Street, PostalCode, City, Country, State, Fax, Phone 
                        FROM Organization 
                        WHERE Id = :UserInfo.getOrganizationId()];  
        // Preisänderung 
        // try {
        //     Preisaenderung__c pe = Preisaenderung__c.getValues('tempZeitraum');
        //     tempPreisVon = pe.Datum_von__c;
        //     tempPreisBis = pe.Datum_bis__c;
        // }
        // catch (System.Exception e) {

        // }
        // temporäre Produkte
        tempProductDeliveryLinesList = listTempProduct();
        // map Menge Reduzieren
        // verschoben in createAndSaveXML Methode
        // reduceQuantityMap = liefermengeReduzierenHelper.makeRulsMap();
        try {
            LiefermengeReduzierungDatum__c lrd = LiefermengeReduzierungDatum__c.getValues('Schwellendatum');
            thresholdDate = lrd.Schwellendatum__c;
        }
        catch (System.Exception e) {

        }
    }

    // constructor 2
    public delivery_xml(boolean nurBedarf) {         
    }

    public void processBedarf(set<id> ctSet) {  
        // all contact Data
        system.debug('###########################alex1001 ctSet.size()=' + ctSet.size());
        contactMap = readContacts(ctSet);
        // system.debug('###########################alex1002 contactMap.size()=' + contactMap.size());
        if(!contactMap.isEmpty()) {
            // number of delivery notes:
            deliveryAddressMap = readDeliveryAddress(contactMap.values());
            system.debug('###########################alex1003 deliveryAddressMap.size()=' + deliveryAddressMap.size());
            if(!deliveryAddressMap.isEmpty()) {
                gpMap = makeGenehmigungMap(contactMap.values());
                // Bedarf reduzieren - füllen sets kundeAlt / Neu
                neueKundeIdSet = kundeAltNeu(contactMap.values(), false, thresholdDate);
                alteKundeIdSet = kundeAltNeu(contactMap.values(), true, thresholdDate);

                // dn.Contact__c, dn
                dnMap = createDeliveryNotes(deliveryAddressMap.keySet());
                if(!dnMap.isEmpty()) {

                    // fill junction map dnId -> ctId
                    for(id ctid : dnMap.keySet()) {
                        DnCtMap.put(dnMap.get(ctid).id, ctid);
                    }

                    // verscheiben Bedarf KUWV von heute vorwärds verschieben.
                    set<id> kuwvSet = bedarfKuwvVorwaertsVerschieben(deliveryAddressMap.keySet());
                    
                    // verschieben Bedarf KUWV im lauf. Monat auf Heute für alle Kunden mit deliveryAddress, aber nicht die, die wir bereits vorwärts verschoben haben.
                    boolean bedarfKuwvOK = bedarfKuwvZurueckVerschieben(deliveryAddressMap.keySet(), kuwvSet);
                    // insert temp delivery lines 
                    if((tempProductDeliveryLinesList != null) && (tempProductDeliveryLinesList.size() > 0)) {
                        insertTempDeliveryLines(deliveryAddressMap.keySet());
                    }                    

                    // lesen DL "Bedarf" <=Heute für alle Kunden mit deliveryAddress
                    LSpos = bedarfEinlesen(deliveryAddressMap.keySet());
                    if(!LSpos.isEmpty()) {

                        mapDnDl = makeDeliveryMap();
                        // may be planned delivery in a future (in this case we merge 2 deliverys)
                        // CtNextDeliveryDateMap = makeCtNextDeliveryDateMap(ctSet);

                        if(!MapDnDl.isEmpty()) { 

                            // füllen LiefemengeReduzierung Map für die LS aus MapDnDl
                            Set<String> md5Set = new Set<String>();
                            for(id dnid : MapDnDl.keySet()) {
                                String md5key = liefermengeReduzierenHelper.computeMd5Key(MapDnDl.get(dnid));
                                if(md5key != null) {
                                    md5Set.add(md5key);
                                }
                            }
                            reduceQuantityMap = liefermengeReduzierenHelper.makeRulsMap(md5Set);

                            set<id> dnWithXmlSet = createAndSaveXML();
                            if(!dnWithXmlSet.isEmpty()) {
                                bedarf = postProcessingDelivery(dnWithXmlSet);
                                if(!Bedarf.isEmpty()) {
                                    Database.SaveResult[]  srList = Database.insert(Bedarf, false); 
                                    for (Database.SaveResult sr : srList) {
                                        if (!sr.isSuccess()) {  
                                            // ToDo: DML error insert Bedarf
                                            for(Database.Error err : sr.getErrors()) {
                                                system.debug('############error:' + err.getMessage());
                                            }
                                        }
                                    }                                    
                                }
                            }
                        }
                    }
                    // clear not converted temp-delivery lines
                    if((tempProductDeliveryLinesList != null) && (tempProductDeliveryLinesList.size() > 0)) {
                        removeTempDeliveryLines(deliveryAddressMap.keySet());
                    }  
                }
            }
        }
    }

    @TestVisible private Map<id, list<Delivery_Line__c>> makeDeliveryMap() {
        Map<id, list<Delivery_Line__c>> MapDnDl = new Map<ID, list<Delivery_Line__c>> () ;
        id tempDnId = null;
        List<Delivery_Line__c> tempDlList = new List<Delivery_Line__c>();
        for(Delivery_Line__c dl : LSpos) {
            // bedarfe reduzieren (Alt)
            // dl.Quantity__c = reduceQuantyty(dl);

            dl.Delivery_note__c = dnMap.get(dl.Contact__c).id;
            if((dl.Delivery_note__c != tempDnID) && (tempDnID != null)) {
                MapDnDl.put(tempDnId, tempDlList);
                tempDlList = new List<Delivery_Line__c>();
                tempDlList.add(dl);
            }
            else {
                tempDlList.add(dl);
            }
            tempDnId = dl.Delivery_note__c;
            // and orederid set + max rythmus 
            currentOrdersIdSet.add(dl.Order_line__r.order__c);
            integer nextBedarf = translateDeliveryFrequency(dl.Order_line__r.order__r.Delivery_frequency__c);
            if(nextBedarf > maxFutureBedarf) {
                maxFutureBedarf = nextBedarf;
            }
        }
        MapDnDl.put(tempDnId, tempDlList);
        return MapDnDl;
    }

    @TestVisible private Map<id, contact> readContacts(set<id> ctSet) {  
        Map<id, contact> ctMap = new Map<id, contact>();
        List<contact> ctList = 
                [SELECT id, firstname, lastname, Salutation, Birthdate, Account.Familien_ID__c, Kranken_Pflegekasse__r.IK_Nummer__c, Versicherungsnummer__c, Liefererlaubnis__c,
                        (SELECT id, Contact__c, Status__c, Productgroup__c, Antrag_bewilligt_abgelehnt_am__c FROM contact_status__r) , 
                        (SELECT id, Name, Contact__c, type_of_address__c, Street__c, Postal_code__c, House_number__c, City__c, Shipping_provider__c FROM contact_address__r WHERE Standard_shipping_address__c = true),
                        (SELECT id, Contact__c, Nach_Paragraph__c, genehmigt_bis__c, unbefristet_genehmigt__c FROM Curabox_Genehmigungen__r WHERE Status__c = 'Bewilligung')
                    FROM contact
                    WHERE id IN : ctSet];
                if((ctList != null) && (ctList.size() > 0)) {
                    for(contact c : ctList) {
                        ctMap.put(c.id, c);
                    }
                }
        return ctMap;
    }

    @TestVisible private Map<id, contact_address__c> readDeliveryAddress(List<contact> ctList) {  
        map<id, contact_address__c> adMap = new Map<id, contact_address__c>();
        for(contact c : ctList){
            for(contact_address__c ca : c.contact_address__r) {
                if(validateAddress(ca)) {
                    adMap.put(c.id, ca);
                }
                else {
                    errorList.add('Address not valid. ' + ca.name);
                }
            }
        }
        return adMap; 
    }

    @TestVisible private boolean validateAddress(contact_address__c ca) {
        if( (String.isEmpty(ca.Street__c )) ||  (String.isEmpty(ca.Postal_code__c )) ||  (String.isEmpty(ca.City__c ))) {
            return false;
        }
        return true;
    }

    @TestVisible private Map<id, Map<id, Curabox_Genehmigungsposition__c>> makeGenehmigungMap(List<contact> ctList) {  
        // key:contactId, value: key:productgroup, value Gen.Position
        Map<id, Map<id, Curabox_Genehmigungsposition__c>> gnMap = new Map<id, Map<id, Curabox_Genehmigungsposition__c>>();
        set<id> genIdSet = new Set<id>();
        for(contact c : ctList){
            for(Curabox_Genehmigung__c gn : c.Curabox_Genehmigungen__r) {
                genIdSet.add(gn.id);
            }
            gnMap.put(c.id, new Map<id, Curabox_Genehmigungsposition__c>());
        }
        List<Curabox_Genehmigungsposition__c> gpList = [SELECT id, name, Genehmigung__c, 
                                                            Genehmigung__r.Contact__c,
                                                            Product_Group__c,
                                                            Product_Group__r.name, 
                                                            genehmigt_bis__c, 
                                                            unbefristet_genehmigt__c, 
                                                            Gen_Menge_Stk__c
                                                    FROM Curabox_Genehmigungsposition__c
                                                    WHERE Genehmigung__c IN: genIdSet];
        for(Curabox_Genehmigungsposition__c gp : gpList) {
            Map<id, Curabox_Genehmigungsposition__c> tempMap = gnMap.get(gp.Genehmigung__r.Contact__c);
            tempMap.put(gp.Product_Group__c, gp);
            gnMap.put(gp.Genehmigung__r.Contact__c, tempMap);
        }                                           
        return gnMap; 
    }

    public void makeGenehmigungMap(List<Curabox_Genehmigung__c> gnList) {  
        // key:contactId, value: key:productgroup, value Gen.Position
        //Map<id, Map<id, Curabox_Genehmigungsposition__c>> gnMap = new Map<id, Map<id, Curabox_Genehmigungsposition__c>>();
        set<id> genIdSet = new Set<id>();
        for(Curabox_Genehmigung__c gn : gnList) {
            genIdSet.add(gn.id);
            if(!gpMap.containsKey(gn.Contact__c)) {
                gpMap.put(gn.Contact__c, new Map<id, Curabox_Genehmigungsposition__c>());
            }
        }
        
        
        List<Curabox_Genehmigungsposition__c> gpList = [SELECT id, name, Genehmigung__c, 
                                                            Genehmigung__r.Contact__c,
                                                            Product_Group__c,
                                                            Product_Group__r.name, 
                                                            genehmigt_bis__c, 
                                                            unbefristet_genehmigt__c, 
                                                            Gen_Menge_Stk__c
                                                    FROM Curabox_Genehmigungsposition__c
                                                    WHERE Genehmigung__c IN: genIdSet];
        for(Curabox_Genehmigungsposition__c gp : gpList) {
            Map<id, Curabox_Genehmigungsposition__c> tempMap = gpMap.get(gp.Genehmigung__r.Contact__c);
            tempMap.put(gp.Product_Group__c, gp);
            gpMap.put(gp.Genehmigung__r.Contact__c, tempMap);
        }                                                 
    }

    @TestVisible private Map<id, Delivery_Note__c> createDeliveryNotes(set<id> ctSet) {  
        system.debug('####################alex1005 ctSet.size()=' + ctSet.size());
        map<id, Delivery_Note__c> dnMap = new Map<id, Delivery_Note__c>();
        List<Delivery_Note__c> dnToInsertList = new List<Delivery_Note__c>();
        Set<id> dnSet = new Set<id>();
        for(id ctid : ctSet) {
            Delivery_Note__c dn = new Delivery_Note__c(Contact__c = ctid, Status__c='nicht abgerechnet', Delivery_date__c=date.today());
            dn.DeliveryAddress__c = deliveryAddressMap.get(ctid).id;
            dnToInsertList.add(dn);
        }
        Database.SaveResult[]  srList = Database.insert(dnToInsertList, false); 
        // ToDo: DML error
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {  
                dnSet.add(sr.getId());
            }
        } 
        if(!dnSet.isEmpty()) {
            List<Delivery_Note__c> newDnList = [SELECT id, Name, Contact__c, DeliveryAddress__c, Delivery_text__c, Delivery_date__c, 
                                                        Contact__r.Zuzahlungsbefreit_Nein__c, MD5Key__c 
                                                    FROM Delivery_Note__c
                                                    WHERE id IN :dnSet];
            if((newDnList != null) && (newDnList.size() > 0)) {
                for(Delivery_Note__c dn : newDnList) {
                    dn.Kunde_Zuzahlung_befreit__c = !dn.Contact__r.Zuzahlungsbefreit_Nein__c;

                    dnMap.put(dn.Contact__c, dn);     
                }
            }

        }
        return dnMap; 
    }

    @TestVisible private set<id> bedarfKuwvVorwaertsVerschieben(set<id> ctSet) {  
        map<id, date> ctDateMap = new map<id, date>();
        set<id> dlSet = new set<id>();

        List<Delivery_Line__c> dlBed = [SELECT id, Delivery_date__c, contact__c
                                            FROM Delivery_Line__c 
                                            WHERE Delivery_status__c = 'Bedarf'      
                                            AND Product__r.Hilfsmittelgruppe__c = '54'                 
                                            AND Delivery_date__c > : date.today()
                                            AND CALENDAR_MONTH(Delivery_date__c) = : date.today().month()
                                            AND CALENDAR_YEAR(Delivery_date__c) = : date.today().year()
                                            AND Contact__c IN :ctSet
                                            ];
        system.debug('##### dlBed.size()=' + dlBed.size());
        if((dlBed != null) && (dlBed.size() > 0)) {
            for(Delivery_Line__c dl : dlBed) {
                ctDateMap.put(dl.contact__c, dl.Delivery_date__c);
            }
        }
        if(!ctDateMap.isEmpty()) {
            List<Delivery_Line__c> dlKuwvBed = [SELECT id, Delivery_date__c, contact__c
                                                FROM Delivery_Line__c 
                                                WHERE Delivery_status__c = 'Bedarf'      
                                                AND Product__r.Hilfsmittelgruppe__c = '51'                 
                                                AND Delivery_date__c <= : date.today()
                                                AND Contact__c IN :ctSet
                                                ];
            
            if((dlKuwvBed != null) && (dlKuwvBed.size() > 0)) {
                for(Delivery_Line__c dl : dlKuwvBed) {
                    if(ctDateMap.containsKey(dl.contact__c)) {
                        system.debug('####alex4701 ' + dl.id + ' '  + dl.delivery_date__c);
                        dl.Delivery_date__c = ctDateMap.get(dl.contact__c);
                        system.debug('####alex4702 ' + dl.id + ' '  + dl.delivery_date__c);
                    }
                }
            }
            Database.SaveResult[] srcList = Database.update(dlKuwvBed, false); 
            for(Database.SaveResult dr : srcList) {
                if (dr.isSuccess()) {
                    System.debug('Vorwärts - Successfully update Delivery_Line__c with ID: ' + dr.getId());
                    dlSet.add(dr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('DL fields that affected this error: ' + err.getFields());
                        errorList.add('Delivery_Line__c update error. fields that affected this error: ' + err.getFields() + ' Message: ' + err.getMessage());
                    }                    
                }  
            } 
        }
        return dlSet;
    }

    @TestVisible private boolean bedarfKuwvZurueckVerschieben(set<id> ctSet, set<id> dlSet) {  
        List<Delivery_Line__c> dlBed = [SELECT id, Delivery_date__c
                                            FROM Delivery_Line__c 
                                            WHERE Delivery_status__c = 'Bedarf'      
                                            AND Product__r.Hilfsmittelgruppe__c = '51'                 
                                            AND Delivery_date__c > : date.today()
                                            AND CALENDAR_MONTH(Delivery_date__c) = : date.today().month()
                                            AND CALENDAR_YEAR(Delivery_date__c) = : date.today().year()
                                            AND Contact__c IN :ctSet
                                            AND id NOT IN : dlSet
                                            ];
        if((dlBed != null) && (dlBed.size() > 0)) {
            for(Delivery_Line__c dl : dlBed) {
                dl.Delivery_date__c = date.today();
            }
            Database.SaveResult[] srcList = Database.update(dlBed, false); 
            for(Database.SaveResult dr : srcList) {
                if (dr.isSuccess()) {
                    System.debug('Zurück: Successfully update Delivery_Line__c with ID: ' + dr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : dr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('DL fields that affected this error: ' + err.getFields());
                        errorList.add('Delivery_Line__c update error. fields that affected this error: ' + err.getFields() + ' Message: ' + err.getMessage());
                    }                    
                }  
            } 
        } 
        return true;
    }

    @TestVisible private Set<id> kundeAltNeu(List<contact> ctList, boolean alt, date thresholdDate) {
        set<id> outSet = new Set<id>();
        for(contact c : ctList) {
            for(contact_status__c cs : c.contact_status__r) {
                if(cs.Productgroup__c == 'PG54') {
                    if(cs.Antrag_bewilligt_abgelehnt_am__c != null) {
                        if(thresholdDate > cs.Antrag_bewilligt_abgelehnt_am__c) {
                            // Alt 
                            if(alt) {
                                outSet.add(c.id);
                            }
                        }
                        else {
                            // Neu
                            if(!alt) {
                                outSet.add(c.id);
                            }
                        }
                    }                   
                }
            }
        }        
        return outSet;
    }

    @TestVisible private List<Delivery_Line__c> bedarfEinlesen(set<id> ctSet) {                
        List<Delivery_Line__c> LSbed = [SELECT id,
                            Delivery_status__c,
                            Quantity__c,
                            Delivery_note__c,
                            Contact__c,
                            Contact__r.Liefererlaubnis__c,
                            Contact__r.without_temp_product__c,
                            Delivery_date__c,
                            VZ_von__c,
                            VZ_bis__c,
                            Product__c,
                            Abrechnungsstatus_Krankenkasse__c,
                            Product__r.Hilfsmittelgruppe__c,
                            Product__r.Product_Group__c,
                            Product__r.Product_Group__r.keine_Genehmigungspflicht__c,
                            Product__r.Product_Group__r.name,
                            Product__r.EAN__c,
                            Product__r.Price__c,
                            Product__r.temp_product__c,
                            Order_line__c,
                            Order_line__r.order__c,
                            Order_line__r.order__r.Delivery_frequency__c,
                            Order_line__r.order__r.Description__c,
                            Order_line__r.Order__r.Liefertag__c,
                            Order_line__r.Order__r.Status__c,
                            Order_line__r.Order__r.Genehmigt_bis__c,
                            Order_line__r.Order__r.Name,
                            Order_line__r.Gen_Menge_Stk_Mon__c,
                            Order_line__r.order__r.createddate
                        FROM Delivery_Line__c 
                        WHERE Delivery_status__c = 'Bedarf'                       
                            AND Delivery_date__c <= : date.today()
                            AND Contact__c IN :ctSet
                            ORDER BY Contact__c, Product__r.Hilfsmittelgruppe__c 
                        ];          
        return LSbed;
    } 

    @TestVisible private set<id> createAndSaveXML() {
        set<id> dnOK = new Set<id>();
        List<Delivery_Note__c> dnWrong = new List<Delivery_Note__c>();
        for(id dnid : MapDnDl.keySet()) {
            id ctid = DnCtMap.get(dnid);
            contact ct = contactMap.get(ctid);
            Delivery_Note__c dn = dnMap.get(ctid);            
            contact_address__c ad = deliveryAddressMap.get(ctid);
            
            List<Delivery_Line__c> dlList = MapDnDl.get(dnid);

            // prüfen bedarf reduzierung
            List<Delivery_Line__c> dlListReduziert;

            system.debug('####alex4801 dlList.size()=' + dlList.size());
            
            rdqr = liefermengeReduzierenHelper.reduceDeliveryQuantity(dlList, reduceQuantityMap);
            
            if(!rdqr.error) {
                system.debug('####alex4802 rdqr.dlList.size()=' + rdqr.dlList.size());
                dnMd5map.put(dnid, rdqr.md5key);
                dlListReduziert = rdqr.dlList;
                List<Delivery_Line__c> dlListBereinigt = new List<Delivery_Line__c>();           
                for(Delivery_Line__c dl : dlListReduziert) {
                    if((dl.Quantity__c != null) && (dl.Quantity__c > 0)) {
                        dlListBereinigt.add(dl);
                    }
                }
                system.debug('####alex4803 dlListBereinigt.size()=' + dlListBereinigt.size());

                // String xmlString = createXML(ct, ad, dn, dlList);
                // ohne positionen mit Quontity__c = 0
                String xmlString = createXML(ct, ad, dn, dlListBereinigt);
                // system.debug('#############xmlString=' +xmlString);
                if(xmlString != null) {
                    ContentVersion cv = new ContentVersion(Title= dn.Name + '.XML');
                    cv.VersionData = blob.valueOf(xmlString);
                    cv.PathOnClient = dn.Name + '.XML';
                    cv.FirstPublishLocationId = dn.id;
                    cv.ContentLocation = 'S';
                    xmlList.add(cv);
                }
                else {
                    dnWrong.add(dn);
                }
            }
            else {    
                errorList.add(rdqr.message + ' Contact ' +ct.firstname + ' ' + ct.lastname);           
                dnWrong.add(dn);
            }
        }
        if(!xmlList.isEmpty()) {
            Database.SaveResult[]  srList = Database.insert(xmlList, false); 
            integer count = 0;
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {  
                    dnOK.add(xmlList[count].FirstPublishLocationId);
                }
                count++;
            }
        }
        if(!dnWrong.isEmpty()) {
            try {
                delete dnWrong;
            }
            catch(System.Exception e) {
                errorList.add('error on delete wrong DN. error=' + e.getLineNumber() + ' ' + e.getMessage());
            }
        }
        return dnOK;
    }

    // set Delivery_text__c bei DN (CBx, KUWV, or CB3 + KUWV) 
    // set MD5Key__c DN
    // update delivery_status (geliefert)
    // create Bedarf (check Genehmigung, order_bis date and future delivery) 
    @TestVisible private List<Delivery_Line__c> postProcessingDelivery(Set<id> dnIdSet) {
        List<Delivery_Line__c> Bedarf = new List<Delivery_Line__c>();
        List<Delivery_Line__c> dl2update = new List<Delivery_Line__c>();
        List<Delivery_Note__c> dn2update = new List<Delivery_Note__c>();
        for(id dnid : dnIdSet) {
            List<Delivery_Line__c> tempList = MapDnDl.get(dnid);
            id ctid = DnCtMap.get(dnid);
            // 1. Delivery note. Productgroup to Delivery_text__c
            Delivery_Note__c dn = dnMap.get(ctid);
            boolean has54 = false;
            boolean has51 = false;
            String cb = null;
            String kuwv = null;
            
            for(Delivery_Line__c dl : tempList) {
                if(dl.Order_line__r.order__r.Description__c != null) {
                    if(dl.Product__r.Hilfsmittelgruppe__c == '54') {
                        has54 = true;
                        cb = dl.Order_line__r.order__r.Description__c;
                    }
                    if(dl.Product__r.Hilfsmittelgruppe__c == '51') {
                        has51 = true;
                        kuwv = dl.Order_line__r.order__r.Description__c;
                    }
                }
                dl.Delivery_Note__c = dnid;
            }
            if((has51 == true) && (has54 == true)) {
                dn.Delivery_text__c = cb + ' + ' + kuwv; 
            } 
            else if ((has51 == false) && (has54 == true)) {
                dn.Delivery_text__c = cb;
            }   
            else if ((has51 == true) && (has54 == false)) {
                dn.Delivery_text__c = kuwv;
            } 
            // md5
            if(dnMd5Map.ContainsKey(dnid)) {
                dn.MD5Key__c = dnMd5Map.get(dnid);
            }
            dn2update.add(dn); 
            system.debug('####################alex1200 ' + dn.Delivery_text__c + ' ' + dn.name + ' ' + dnid);

            // 2.  Bedarf
            List<Delivery_Line__c> tempBedarf = createBedarf(dn.Contact__c, tempList);
            if((tempBedarf != null) && (tempBedarf.size() > 0)) {
                Bedarf.addAll(tempBedarf);
            }            
            dl2update.addAll(tempList);
        }

        // 3. update on current DP's 
        for(Delivery_Line__c dl : dl2update) {
            dl.Delivery_status__c = 'geliefert';
            // if(gpMap.containsKey(dl.Contact__c)) {
            //     dl.Abrechnungsstatus_Krankenkasse__c = 'abrechenbar';
            // }
            if((dl.Product__r.Price__c == null) || (dl.Product__r.Price__c == 0)) {
                dl.Abrechnungsstatus_Krankenkasse__c = 'Kostenfreie Lieferung';
            }
            dl.VZ_von__c = date.today().toStartOfMonth();
            dl.VZ_bis__c = dl.VZ_von__c.addMonths(1).addDays(-1);
        }
        Database.SaveResult[]  srList = Database.update(dl2update, false); 
        for (Database.SaveResult sr : srList) {
            if (!sr.isSuccess()) {  
                // ToDo: DML error
            }
        } 
        totalDN = dn2update.size();
        srList = Database.update(dn2update, false); 
        // 4. delete delivery lines with zero quantity
        Database.DeleteResult[] drList = Database.delete(dlWithZeroQuantity, false);

        return Bedarf;
    }

    @TestVisible private String createXML(contact c, contact_address__c ad, Delivery_Note__c dn, List<Delivery_Line__c> dlList) {
        try {
            String xmlString = null;
            String docName = dn.Name;
            integer posNo = 1;
                Datetime delDate = Datetime.now();
                if(dn.Delivery_Date__c != null) {         
                    delDate = datetime.newInstance(dn.Delivery_Date__c, Time.newInstance(0, 0, 0, 0));
                }  
                string lieferdatum = delDate.format('YYYYMMdd');
                string datumHeute = Datetime.now().format('YYYYMMdd');
                string zeitJetzt = Datetime.now().format('HHmmss');        

                Xmlstreamwriter xmlW = new Xmlstreamwriter();
                xmlW.writeStartDocument('utf-8','1.0');
                    xmlW.writeStartElement(null,'PHOrders', null);
                    xmlW.writeAttribute(null,null,'xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
                    // PHTransfer
                    xmlW.writeStartElement(null,'PHTransfer', null);
                        xmlW.writeStartElement(null,'SenderID', null);
                            xmlW.writeCharacters(kdnrBeiHartmann);
                        xmlW.writeEndElement();               
                        xmlW.writeStartElement(null,'ReceiverID', null);
                            xmlW.writeCharacters('4049500000000');
                        xmlW.writeEndElement();             
                        xmlW.writeStartElement(null,'Date', null);
                            xmlW.writeCharacters(datumHeute);
                        xmlW.writeEndElement();     
                        xmlW.writeStartElement(null,'Time', null);
                            xmlW.writeCharacters(zeitJetzt);
                        xmlW.writeEndElement(); 
                        xmlW.writeStartElement(null,'VersionID', null);
                            xmlW.writeCharacters('1.8.3');
                        xmlW.writeEndElement();                 
                    xmlW.writeEndElement();
                    // PHTransfer    
                    xmlW.writeStartElement(null,'Order', null);
                    xmlW.writeAttribute(null,null,'type','TA');     

                            xmlW.writeStartElement(null,'OrderHeader', null);
                                xmlW.writeStartElement(null,'ReferencedOrder', null);
                                    xmlW.writeStartElement(null,'BuyerOrderNumber', null);
                                        xmlW.writeCharacters(dn.Name + ' - ' + (string.valueOf(c.Account.Familien_ID__c)));
                                    xmlW.writeEndElement();
                                    xmlW.writeStartElement(null,'Date', null);
                                        xmlW.writeCharacters(lieferdatum);
                                    xmlW.writeEndElement();
                                    xmlW.writeStartElement(null,'ReferenceID', null);
                                        xmlW.writeCharacters(dn.Name);
                                    xmlW.writeEndElement();             
                                //ReferencedOrder 
                                xmlW.writeEndElement();

                            xmlW.writeStartElement(null,'BuyerParty', null);
                                    xmlW.writeStartElement(null,'PartnerID', null);
                                    xmlW.writeAttribute(null,null,'type','Distributor');
                                        xmlW.writeCharacters(kdnrBeiHartmann);
                                    xmlW.writeEndElement();
                                    xmlW.writeStartElement(null,'PartnerName1', null);
                                        xmlW.writeCharacters(orgDetails.Name);
                                    xmlW.writeEndElement(); 
                                    xmlW.writeStartElement(null,'PartnerAddress', null);
                                        xmlW.writeCharacters(orgDetails.Street );
                                    xmlW.writeEndElement();  
                                    xmlW.writeStartElement(null,'PartnerPostalCode', null);
                                        xmlW.writeCharacters(orgDetails.PostalCode);
                                    xmlW.writeEndElement();                         
                                    xmlW.writeStartElement(null,'PartnerCity', null);
                                        xmlW.writeCharacters(orgDetails.City );
                                    xmlW.writeEndElement();     
                                    xmlW.writeStartElement(null,'PartnerCountryCode', null);
                                        xmlW.writeCharacters('DE');
                                    xmlW.writeEndElement();                    
                                    xmlW.writeStartElement(null,'PartnerPhone', null);
                                        xmlW.writeCharacters(string.valueOf(FirmenInfo.Telefon__c));
                                    xmlW.writeEndElement(); 
                                    xmlW.writeStartElement(null,'PartnerFax', null);
                                        xmlW.writeCharacters(string.valueOf(FirmenInfo.Fax__c));
                                    xmlW.writeEndElement();                         
                                // BuyerParty
                                xmlW.writeEndElement();   

                                xmlW.writeStartElement(null,'DestinationParty', null);
                                    xmlW.writeStartElement(null,'PartnerID', null);
                                    xmlW.writeAttribute(null,null,'type','Distributor');
                                        xmlW.writeCharacters('99999951');
                                    xmlW.writeEndElement(); 
                                    xmlW.writeStartElement(null,'PartnerReferenceID', null);
                                    xmlW.writeAttribute(null,null,'type','Customer');
                                        xmlW.writeCharacters(string.valueOf(c.Account.Familien_ID__c));
                                    xmlW.writeEndElement(); 
                                    xmlW.writeStartElement(null,'PartnerName1', null);
                                        xmlW.writeCharacters(ad.Name);
                                    xmlW.writeEndElement();
                                    if(ad.type_of_address__c != 'customer address') {
                                        xmlW.writeStartElement(null,'PartnerName2', null);
                                            xmlW.writeCharacters(string.valueOf(c.firstname) + ' ' + c.lastname );
                                        xmlW.writeEndElement(); 
                                    } 
                                    xmlW.writeStartElement(null,'PartnerAddress', null);
                                    if(ad.Street__c.length() > 35) {
                                        xmlW.writeCharacters(ad.Street__c.substring(0, 35) );
                                    }
                                    else {
                                        xmlW.writeCharacters(ad.Street__c);
                                    }
                                    xmlW.writeEndElement();     
                                    xmlW.writeStartElement(null,'PartnerPostalCode', null);
                                        xmlW.writeCharacters(ad.Postal_Code__c);
                                    xmlW.writeEndElement();     
                                    xmlW.writeStartElement(null,'PartnerCity', null);
                                        xmlW.writeCharacters(ad.City__c );
                                    xmlW.writeEndElement(); 
                                    xmlW.writeStartElement(null,'PartnerCountryCode', null);
                                        xmlW.writeCharacters('DE');
                                    xmlW.writeEndElement();                                                 
                                // DestinationParty
                                xmlW.writeEndElement();

                                xmlW.writeStartElement(null,'SellerParty', null);
                                    xmlW.writeStartElement(null,'PartnerID', null);
                                    xmlW.writeAttribute(null,null,'type','EAN');
                                        xmlW.writeCharacters('4049500000000');
                                    xmlW.writeEndElement();
                                    xmlW.writeStartElement(null,'PartnerName1', null);
                                        xmlW.writeCharacters('Paul Hartmann AG');
                                    xmlW.writeEndElement();             
                                    //SellerParty
                                xmlW.writeEndElement();  
                                
                                // Versandpartner (nur DHL)
                                if(ad.Shipping_provider__c == 'DHL') {
                                    xmlW.writeStartElement(null,'OrderOptions', null);
                                        xmlW.writeStartElement(null,'Versandbedingung', null);
                                            xmlW.writeCharacters('30');
                                        xmlW.writeEndElement(); 
                                    xmlW.writeEndElement();  
                                }
                            // OrderHeader 
                            xmlW.writeEndElement(); 
                            
                            xmlW.writeStartElement(null,'OrderLines', null);
                            for(Delivery_Line__c dl : dlList) {
                                system.debug('####alex4901 dl.product__r.EAN__c=' + dl.product__r.EAN__c);
                                xmlW.writeStartElement(null,'OrderLine', null);
                                    xmlW.writeStartElement(null,'LineNumber', null);
                                    xmlW.writeAttribute(null,null,'type','TA');
                                        xmlW.writeCharacters(string.valueOf(posNo));
                                    xmlW.writeEndElement();
                                    xmlW.writeStartElement(null,'ProductNumber', null);
                                    xmlW.writeAttribute(null,null,'type','EAN');
                                    if(dl.product__r.EAN__c != null) {
                                        xmlW.writeCharacters(string.valueOf(dl.product__r.EAN__c));
                                    }
                                    else {
                                        xmlW.writeCharacters('hier EAN');
                                    }
                                    xmlW.writeEndElement();
                                    xmlW.writeStartElement(null,'Quantity', null);
                                        if(dl.Quantity__c == null) {
                                            xmlW.writeCharacters('0');
                                        }
                                        else {
                                            xmlW.writeCharacters(string.valueOf(dl.Quantity__c));
                                        }
                                    xmlW.writeEndElement();             
                                    // OrderLine
                                xmlW.writeEndElement(); 
                                posNo++;
                            }
                            xmlW.writeEndElement();

                    // Order
                    xmlW.writeEndElement();

                // PHXOrders    
                xmlW.writeEndElement(); 
                xmlW.writeEndDocument();
                xmlString = xmlW.getXmlString();
                xmlW.close();

            return xmlString;
        }
        catch (System.Exception e) {
            errorList.add('error on create XML. contact ' + c.Id + ' ' + c.lastname + ' DN:' + dn.Name + ' error=' + e.getLineNumber() + ' ' + e.getMessage());
            return null;
        }
    }    

    @TestVisible private integer translateDeliveryFrequency(String f) {
        integer i = 1;
        if (f == 'monatlich') {i = 1;}
        if (f == 'zweimonatlich') {i = 2;}
        if (f == 'vierteljährlich') {i = 3;}
        if (f == 'dritteljährlich') {i = 4;}
        if (f == 'halbjährlich') {i = 6;}
        if (f == 'jährlich') {i = 12;}        
        return i;
    }

    public List<Delivery_Line__c> createBedarf(id contId, List<Delivery_Line__c> dlList) {
        List<Delivery_Line__c> tempBedarf = new List<Delivery_Line__c>();
        List<Delivery_Line__c> tempBedarfCB = new List<Delivery_Line__c>();
        boolean oneLineHasNoDate = false;
        date nextDeliveryDate54 = null;
        date nextDeliveryDate51 = null;
        // 
        for(Delivery_Line__c dl : dlList) {
            if(dl.Order_line__r.order__r.Delivery_frequency__c != 'einmalig') {

                // if(dl.Product__r.temp_product__c == false) {
                // Für Alle in AU 
                if(dl.Order_Line__r.Order__c != null) {
                    if(dl.Product__r.Hilfsmittelgruppe__c == '51') {
                        nextDeliveryDate51 = calculateDateAndGenehmigung(contId, dl);

                        // hier nichts mehr prüfen
                        if(nextDeliveryDate51 != null) { 
                            Delivery_Line__c bdl = dl.clone();
                            bdl.Delivery_Note__c = null;
                            bdl.Delivery_date__c = nextDeliveryDate51;
                            bdl.VZ_von__c = nextDeliveryDate51.toStartOfMonth();
                            bdl.VZ_bis__c = bdl.VZ_von__c.addMonths(1).addDays(-1);
                            tempBedarf.add(bdl);
                        }
                    }
                    if(dl.Product__r.Hilfsmittelgruppe__c == '54') {
                        nextDeliveryDate54 = calculateDateAndGenehmigung(contId, dl);
                        system.debug('####### alex7000' + nextDeliveryDate54);
                        // bei CB sollen alle positionen stimmen
                        if(nextDeliveryDate54 != null) { 
                            Delivery_Line__c bdl = dl.clone();
                            bdl.Quantity__c = dl.Order_line__r.Gen_Menge_Stk_Mon__c;
                            bdl.Delivery_date__c = nextDeliveryDate54;
                            bdl.Delivery_Note__c = null;
                            bdl.VZ_von__c = nextDeliveryDate54.toStartOfMonth();
                            bdl.VZ_bis__c = bdl.VZ_von__c.addMonths(1).addDays(-1);
                            tempBedarfCB.add(bdl);
                        }
                        else {
                            oneLineHasNoDate = true;
                        }                
                    }
                    if((oneLineHasNoDate == false) && (!tempBedarfCB.isEmpty())) {
                        tempBedarf.addAll(tempBedarfCB);
                        tempBedarfCB = new List<Delivery_Line__c>();
                    }
                }
            }
        }

        return tempBedarf;
    }

    @TestVisible private date calculateDateAndGenehmigung(id contId, Delivery_Line__c dl) {
        // wenn order beendet brauchen wir nichts zu prüfen
        if(dl.Order_line__r.Order__r.Status__c == 'beendet') {
            errorList.add('Auftrag ' + dl.Order_line__r.Order__r.Name + ' beendet');
            return null;
        }
        if(dl.Order_line__r.Order__r.Status__c == 'pausiert') {
            errorList.add('Auftrag ' + dl.Order_line__r.Order__r.Name + ' pausiert');
            return null;
        }
        
        date nextDeliveryDate = null;
        date checkDeliveryDate = null;
        system.debug('####### alex7001');
        date tempDeliveryDate = date.today().addMonths(translateDeliveryFrequency(dl.Order_line__r.order__r.Delivery_frequency__c));
        system.debug('####### alex7002' + translateDeliveryFrequency(dl.Order_line__r.order__r.Delivery_frequency__c));
        // Liefertag aus Order
        if(dl.Order_line__r.Order__r.Liefertag__c != null) {
            checkDeliveryDate = date.newinstance(tempDeliveryDate.year(), tempDeliveryDate.month(), dl.Order_line__r.Order__r.Liefertag__c.day());
        }
        else {
            checkDeliveryDate = tempDeliveryDate;
        }


        integer delMonth = checkDeliveryDate.month();
        integer delYear = checkDeliveryDate.year();
        // Gibt es ev. geplannte Lieferungen im gleichen Monat und Jahr?
        // Dann setzen packen wir alles zusammen
        // if(CtNextDeliveryDateMap.containsKey(contId)) {
        //     date plannedDate = CtNextDeliveryDateMap.get(contId);
        //     if((plannedDate.month() == delMonth) && (plannedDate.year() == delYear)) {
        //         nextDeliveryDate = plannedDate;    
        //     }
        // } 
        // Wenn nicht - weiter
        if(nextDeliveryDate == null) {
            // Wochenende 
            tempDeliveryDate = checkDeliveryDate;
            
            string dayOfWeek = datetime.newInstance(checkDeliveryDate, Time.newInstance(0, 0, 0, 0)).format('E');
            // Zunächst auf kommenden Montag
            if(dayOfWeek == 'Sat') {
                checkDeliveryDate = checkDeliveryDate.addDays(2);
            }  
            if(dayOfWeek == 'Sun') {
                checkDeliveryDate = checkDeliveryDate.addDays(1);
            }
            // Wenn der Monat nicht passt dann zurück auf Freitag        
            if(delMonth != checkDeliveryDate.month()) {
                if(dayOfWeek == 'Sat') {
                    checkDeliveryDate = checkDeliveryDate.addDays(-1);
                }  
                if(dayOfWeek == 'Sun') {
                    checkDeliveryDate = checkDeliveryDate.addDays(-2);
                } 
            }
            nextDeliveryDate = checkDeliveryDate;
        }

        // Auftrag bis Datum
        if(dl.Order_line__r.Order__r.Genehmigt_bis__c < nextDeliveryDate) {
            errorList.add('Auftrag ' + dl.Order_line__r.Order__r.Name + ' abgelaufent');
            return null;
        }        
        return nextDeliveryDate;
    }

    public list<string> getErrorList() {
        return errorList;
    }
    
    public integer getErrorListSize() {
        if(errorList != null) {
            return errorList.size();
        }
        else return 0;
    }

    public integer getTotalDN() {
        return totalDN;
    }

    @TestVisible private List<Delivery_Line__c> listTempProduct() {
        List<Delivery_Line__c> tempProducts = new List<Delivery_Line__c>();
        Date selectedDate =  Date.today(); 
        Date firstDate = selectedDate.toStartOfMonth();
        List<Product__c> prList = [SELECT id , name, Price__c, temp_quantity__c 
                                    FROM Product__c
                                    WHERE temp_product__c = True 
                                    AND temp_date_from__c <= :date.today()
                                    AND temp_date_to__c >= :date.today()
                                    AND temp_quantity__c != null
                                    AND temp_quantity__c > 0];
        if((prList != null) && (prList.size() > 0)) {
            for(Product__c pr : prList) {
                
                Delivery_Line__c dl = new Delivery_Line__c();
                dl.Product__c = pr.id;
                dl.Delivery_date__c = date.today();
                dl.Quantity__c = pr.temp_quantity__c;
                dl.VZ_von__c = firstDate;
                dl.VZ_bis__c = firstDate.addDays(date.daysInMonth(selectedDate.year() , selectedDate.month())  - 1);
                dl.Delivery_status__c = 'Bedarf';
                dl.Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar';
                tempProducts.add(dl);
            }
        }
        return tempProducts;
    }

    @TestVisible private void insertTempDeliveryLines(set<id> ctSet) {
        List<Delivery_Line__c> tempDL2insert = new List<Delivery_Line__c>();
        List<Delivery_Line__c> dlList = [SELECT id,                                               
                                                Contact__c
                                            FROM Delivery_Line__c 
                                            WHERE Delivery_status__c = 'Bedarf'                       
                                                AND Delivery_date__c <= : date.today()
                                                AND Contact__c IN :ctSet
                                                AND Product__r.Hilfsmittelgruppe__c = '54'
                                                AND Contact__r.without_temp_product__c = false
                                                ORDER BY Contact__c, Product__r.Hilfsmittelgruppe__c 
                                            ];  
        // ermittel die contacts mit pg54 und without_temp_product__c = false
        set<id> contIdSet = new Set<id>();
        if((dlList != null) && (dlList.size() > 0)) {
            for(Delivery_Line__c dl : dlList) {           
                    if(!contIdSet.contains(dl.Contact__c)) {
                        contIdSet.add(dl.Contact__c);
                    }           
            }
        }
        system.debug('##### contIdSet.size()='+contIdSet.size() );

        // für alle passenden Kontakte die Temp  delivery lines 
        if(!contIdSet.isEmpty()) {
            for(id ctid : contIdSet) {
                for(Delivery_Line__c dl : tempProductDeliveryLinesList) {
                    Delivery_Line__c tdl = new Delivery_Line__c(Contact__c = ctid);
                    tdl.Contact__c = ctid;
                    tdl.Product__c = dl.Product__c;
                    tdl.Delivery_date__c = dl.Delivery_date__c;
                    tdl.Quantity__c = dl.Quantity__c;
                    tdl.VZ_von__c = dl.VZ_von__c;
                    tdl.VZ_bis__c = dl.VZ_bis__c;
                    tdl.Delivery_status__c = 'Bedarf';
                    tdl.Abrechnungsstatus_Krankenkasse__c = 'nicht abrechenbar';
                    tempDL2insert.add(tdl);
                    system.debug('#####' + tdl);
                }
            }
            if(!tempDL2insert.isEmpty()) {
                Database.SaveResult[] srList = Database.insert(tempDL2insert, false);
            }
        }
    }

    @TestVisible private void removeTempDeliveryLines(set<id> ctSet) {
        List<Delivery_Line__c> dlList = [SELECT id                                            
                                            FROM Delivery_Line__c 
                                            WHERE Delivery_status__c = 'Bedarf'  
                                            AND Delivery_date__c = :date.today()  
                                            AND order_line__c = null                   
                                        ];  
        if((dlList != null) && (dlList.size() > 0)) {
            Database.DeleteResult[] drList = Database.delete(dlList, false);
        }
        
    }
}