/*/****************************************************************************************************************************
// Erstellt 20.04.2021 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frohmestr. 49
//                         22457 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine - Helper
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  Statische Methoden zu Invoce-Prozess
//  
//
//****************************************************************************************************************************
// Änderungen:       
//****************************************************************************************************************************
*/
public with sharing class invoiceHelper {

    public class curaboxPriceResult {
        public decimal totalPrice {get; set;}
        public decimal lineAdditionalPrice {get; set;}
        public decimal totalAdditionalPrice {get; set;}        
        public map<id, decimal> linePrice {get; set; }
        public map<id, decimal> productPrice {get; set; }
        public decimal linePriceKUWV {get; set;}   
    }

    public class deliveryNotePrepared {
        public String CSV_Line_summe {get; set;}
        public String csv_SU {get; set;}
        public String csv_KUWV_SU {get; set;}
        public map<id, deliveryNoteLine> lineMap {get; set;}
        public decimal totalPrice {get; set;}
        public decimal totalAdditionalPrice {get; set;}
        public String csvLineSumme {get; set;}
        
        public deliveryNotePrepared() {
            CSV_Line_summe = '';
            csv_KUWV_SU = '';
            csv_SU = '';
            csvLineSumme = '';
            totalPrice = 0.0;
            totalAdditionalPrice = 0.0;
            lineMap = new map<id, deliveryNoteLine>();
        }
    }
    
    public class deliveryNoteLine {
        public String CSV_Line {get; set;}
        public decimal posPrice {get; set;}
        public decimal productPrice {get; set;}
        public decimal zuzahlung {get; set;}
        public decimal beihilfe {get; set;}
        public String Productgroup {get; set;}
        public decimal quantity {get; set;}    
        public deliveryNoteLine() {
            CSV_Line = '';
            posPrice = 0.0;
            productPrice = 0.0;
            zuzahlung = 0.0;
            beihilfe = 0.0;
            Productgroup = '';
            quantity = 0;
        }	
    }

    // Preslisten =============================================================================================
    // Preslisten -> Map füllen (key=productId, value=List<Preisliste__c>)
    public static map<id, List<Preisliste__c>> fillPreisliste() {
        Map<id, List<Preisliste__c>> plMap = new Map<id, List<Preisliste__c>>(); 
        List<Preisliste__c> plList = [SELECT product__c, valid_from__c, valid_to__c, preis__c FROM Preisliste__c];
        if((plList != null) && (plList.size() > 0)) {
            List<Preisliste__c> tmpList = new List<Preisliste__c>();
            for(Preisliste__c pl : plList) {
                if(plMap.ContainsKey(pl.product__c)) {
                    tmpList = plMap.get(pl.product__c);
                    tmpList.add(pl);
                    plMap.put(pl.product__c, tmpList);
                }
                else {
                    tmpList = new List<Preisliste__c>();
                    tmpList.add(pl);
                    plMap.put(pl.product__c, tmpList);
                }
            }
        }
        return plMap;
    }

    // aktulle Preis ermitteln
    public static decimal getCurrentPrice(Delivery_Line__c dl, date dd, map<id, List<Preisliste__c>> plMap) {
        decimal productPrice = 0.00;
        if(plMap.ContainsKey(dl.Product__c)) {
            if(dd == null) {
                dd = date.today();
            }
            productPrice = invoiceHelper.getValidPrice(dl.Product__c, dd, plMap);
            if(productPrice == null) {
                productPrice = dl.Product__r.Price__c;
            }
        }
        else {
            productPrice = dl.Product__r.Price__c;
        }
        return productPrice;
    }


    // Preislisten. Aktuell gültige Preis für den Produkt holen.
    public static decimal getValidPrice(id productId, date deliveryDate, map<id, List<Preisliste__c>> plMap) {
        decimal preis = null;
        List<Preisliste__c> tmpList = plMap.get(productId);
        if((tmpList != null) && (tmpList.size() > 0)) {
            for(Preisliste__c pl : tmpList) {
                if((pl.valid_from__c <= deliveryDate) && (pl.valid_to__c >= deliveryDate)) {
                    preis = pl.preis__c;
                    break;
                }
            }
        } 
        return preis;
    }
    // Preslisten =============================================================================================

    // Zusätzliche Preise ==================================================================================== 
    // Curabox Höchstpreis
    public static decimal getMaxCuraboxPrice() {
        return getMaxCuraboxPrice(date.today());
    }

    public static decimal getMaxCuraboxPrice(date deliveryDate) {
        decimal defaultPrice = 60.00;
        List<Curabox_Hoechstpreis__c> l = Curabox_Hoechstpreis__c.getAll().values();
        for(Curabox_Hoechstpreis__c p : l){
            if((p.Von__c <= deliveryDate) && (p.Bis__c >= deliveryDate)) {
                return p.MaxPrice__c;
            }
        }
        return defaultPrice;
    }

    public static curaboxPriceResult computeAdditionalPrice(Delivery_Note__c dn, decimal maxPrice, map<id, List<Preisliste__c>> plMap) {
        curaboxPriceResult res = new curaboxPriceResult();
        res.totalPrice = 0;
        res.totalAdditionalPrice = 0;
        res.lineAdditionalPrice = 0;
        res.linePrice = new map<id, decimal>();
        res.productPrice = new map<id, decimal>();
        res.linePriceKUWV = 0;
        integer menge = 0;
        for(Delivery_Line__c dl : dn.Delivery_Lines__r) {
            if((dl.Product__r.Price__c != null) && (dl.Product__r.Price__c > 0)) {
                if(dl.Abrechnungsstatus_Krankenkasse__c == 'abrechenbar') {
                    decimal productPrice = invoiceHelper.getCurrentPrice(dl, dn.Delivery_date__c, plMap);                    
                    decimal pospreis = (dl.Quantity__c * productPrice).setScale(2, RoundingMode.HALF_UP);
                    res.productPrice.put(dl.id, productPrice);
                    res.linePrice.put(dl.id, pospreis);
                    if(dl.Product__r.Hilfsmittelgruppe__c == '54') {
                        res.totalPrice += pospreis;
                        menge += integer.valueOf(dl.Quantity__c);
                    }
                    if(dl.Product__r.Hilfsmittelgruppe__c == '51') {
                        res.linePriceKUWV = pospreis;
                    }
                }
            }
        }
        
        // errechnen
        if((res.totalPrice > maxPrice) && (menge > 0)) {
            res.totalAdditionalPrice = res.totalPrice - maxPrice;
            res.lineAdditionalPrice = (res.totalAdditionalPrice / menge).setScale(2, RoundingMode.HALF_UP);
        }
        return res;
    }

    public static deliveryNotePrepared prepareDeliveryNote(Delivery_Note__c dn, invoiceHelper.curaboxPriceResult curaboxPriceResult) {
        deliveryNotePrepared res = new deliveryNotePrepared();
        String hkz = '';
        String tk = '';
        String ac = ''; 
        String lDat = '';
        decimal zuzahlung = 0;
        if(dn.Contact__r.Kranken_Pflegekasse__r.Hilfsmittel_Kennzeichen__c != null) {
            hkz = dn.Contact__r.Kranken_Pflegekasse__r.Hilfsmittel_Kennzeichen__c;
        }
        if(dn.Contact__r.Kranken_Pflegekasse__r.TK__c != null) {
            tk = dn.Contact__r.Kranken_Pflegekasse__r.TK__c;
        }
    
        if(dn.Contact__r.Kranken_Pflegekasse__r.AC__c != null) {
            ac = dn.Contact__r.Kranken_Pflegekasse__r.AC__c;
        } 
        if(dn.Delivery_date__c != null) {
            lDat = dn.Delivery_date__c.format();
        }   
        
        decimal totalEigenanteil = 0;
        String sonderabrechningstring 	= '';
        for(Delivery_Line__c dl : dn.Delivery_Lines__r) {
            if(curaboxPriceResult.linePrice.containsKey(dl.id) ) {
                deliveryNoteLine line = new deliveryNoteLine();
                String vzvDat = '01.01.2000';
                if(dl.VZ_von__c != null) {
                    vzvDat = dl.VZ_von__c.format();
                }                       
                String vzbDat = '01.01.2000';
                if(dl.VZ_bis__c != null) {
                    vzbDat = dl.VZ_bis__c.format();
                }
                line.quantity = dl.Quantity__c;
                String csvstring = 'PO\t' + dl.Product__r.Hilfsmittelpositionsnummer__c;
                        csvstring += '\t' + string.valueOf(dl.Quantity__c);
                        csvstring += '\t' + ksgFunctions.formatCurrency(curaboxPriceResult.productPrice.get(dl.id)); 
                        csvstring += '\t' + dl.Product__r.Name;
                        csvstring += '\t' + lDat;
                        csvstring += '\t' + hkz;
                        csvstring += '\t' + vzvDat; 
                        csvstring += '\t' + vzbDat; 
                        csvstring += '\t' + dl.Product__r.abda_mwst_knz__c; 
                        csvstring += '\t'; 
                        csvstring += '\t' + ac;
                        csvstring += '\t' + tk;
                        
                String eigenanteil = '';
                decimal beihilfe = 0.0;
                if(dl.Product__r.Hilfsmittelgruppe__c == '54') {
                    if(dn.Contact__r.Beihilfeberechtigt__c) {
                        beihilfe = computeEigenanteilBeihilfeberechtigt(curaboxPriceResult.productPrice.get(dl.id) , curaboxPriceResult.lineAdditionalPrice);
                        eigenanteil = ksgFunctions.formatCurrency(beihilfe);
                        if(dl.Quantity__c == null) {
                            dl.Quantity__c = 0;
                        }                       
                        beihilfe = beihilfe * dl.Quantity__c;
                        totalEigenanteil += beihilfe;                        
                    }
                    else {
                        totalEigenanteil = curaboxPriceResult.totalAdditionalPrice;
                        eigenanteil = ksgFunctions.formatCurrency(curaboxPriceResult.lineAdditionalPrice);
                    }
                }
                else {
                    eigenanteil = '0,00';
                    if(dn.Contact__r.Zuzahlungsbefreit_Nein__c) {
                        zuzahlung = computeZuzahlung(curaboxPriceResult.linePriceKUWV, dl.Quantity__c, dn.Contact__r.Kranken_Pflegekasse__r.PG51_Abrechnungs_Methode__c);
                    }

                }
                csvstring += '\t' + eigenanteil;			
                csvstring += '\r\n';
                
                
                line.CSV_Line = csvstring;
                line.posPrice = curaboxPriceResult.linePrice.get(dl.id);
                line.productPrice = curaboxPriceResult.productPrice.get(dl.id);
                if(beihilfe > 0) {
                    line.beihilfe = beihilfe;
                }
                else {
                    if(dl.Product__r.Hilfsmittelgruppe__c == '54') {
                        line.zuzahlung = curaboxPriceResult.lineAdditionalPrice;
                    }
                    else {
                        line.zuzahlung = zuzahlung;
                    }
                }
                line.Productgroup = dl.Product__r.Hilfsmittelgruppe__c;
                res.lineMap.put(dl.id, line);
                
                sonderabrechningstring 	= '\t' + 'CuraBox' 
                                                + '\t' + lDat 
                                                + '\t' + hkz
                                                + '\t' + vzvDat 
                                                + '\t' + vzbDat 
                                                + '\t' + dl.Product__r.abda_mwst_knz__c 
                                                + '\t' 
                                                + '\t' + ac
                                                + '\t' + tk
                                                + '\t'; 
            }
            
            decimal pospreisSumme = curaboxPriceResult.totalPrice - curaboxPriceResult.totalAdditionalPrice;
            if(dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_HM_Positionsnummer__c != null) {
                res.csvLineSumme = 'PO\t' + dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_HM_Positionsnummer__c + '\t1\t' +  ksgFunctions.formatCurrency(pospreisSumme);
                if(dn.Contact__r.Beihilfeberechtigt__c) {
                    res.csvLineSumme += sonderabrechningstring + ksgFunctions.formatCurrency(pospreisSumme / 2) + '\r\n';
                }
                else {
                    res.csvLineSumme += sonderabrechningstring + '\r\n';
                }
            }
            res.totalAdditionalPrice = totalEigenanteil;
            res.totalPrice = curaboxPriceResult.totalPrice;
            if(dl.Product__r.Hilfsmittelgruppe__c == '54') {
                res.csv_SU = 'SU\t' + ksgFunctions.formatCurrency(curaboxPriceResult.totalPrice)  
                            + '\t' + ksgFunctions.formatCurrency(totalEigenanteil) 
                            + '\t' + ksgFunctions.formatCurrency(curaboxPriceResult.totalPrice - totalEigenanteil);
            }
            if(dl.Product__r.Hilfsmittelgruppe__c == '51') { 
                
                res.csv_KUWV_SU = 'SU\t' + ksgFunctions.formatCurrency(curaboxPriceResult.linePriceKUWV)  
                    + '\t' + ksgFunctions.formatCurrency(zuzahlung) 
                    + '\t' + ksgFunctions.formatCurrency(curaboxPriceResult.linePriceKUWV - zuzahlung);
            }
            
        }
        
        return res;
    }
    
    public static decimal computeEigenanteilBeihilfeberechtigt(decimal posPrise, decimal lineAdditionalPrice) {
        if(lineAdditionalPrice == 0) {
            return (posPrise / 2).setScale(2, RoundingMode.HALF_UP);
        }
        else {
            return (((posPrise - lineAdditionalPrice) / 2) + lineAdditionalPrice).setScale(2, RoundingMode.HALF_UP);
        }
    }

    public static decimal computeZuzahlung (decimal preis, decimal menge, string method) {
        try {
            decimal zz = 0.00;
            decimal minZZ = 0.00;
            if(method == null) {
                return zz;
            }
            if(method.Contains('mindestens')) {
                minZZ = 5.00;
            }
            if (method.Contains('pro Artikel')) {
                decimal proArtikel = (preis / 10).setScale(2, RoundingMode.HALF_UP);
                if(proArtikel > 10.0) {
                    proArtikel = 10.00;
                }
                if(proArtikel < minZZ) {
                    proArtikel = minZZ;
                } 
                zz = (proArtikel * menge).setScale(2, RoundingMode.HALF_UP); 
            }
            else {
                zz = ((preis * menge) / 10).setScale(2, RoundingMode.HALF_UP); 
                if(zz > 10) {
                    zz = 10.00;
                }
            }
            return zz;
        }
        catch(System.Exception e) {
            // ToDo: Errorhandling
            return 0.00;
        }
    }
    // Zusätzliche Preise ==================================================================================== 
}