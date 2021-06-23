/****************************************************************************************************************************
// Created 15.08.2020 von  AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstr. 29
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine, da Helper
//
//****************************************************************************************************************************
//
// Description:       
//  diverse static Methoden für LiefermengeReduzieren
//
//****************************************************************************************************************************
// Changes: 
// 02.04.2021 AM 00002637 - Es werden nur die ausgewählte LMR in einer Map geladen werden
// 11.04.2021 AM 00002639 - Falsche md5keys bei Temp. Produkte
//                          Wenn in einem LS die temp Positionen existieren hat die Routine 
//                          computeMd5Key als Fehler interpritiert und NULL zurückgegeben.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class liefermengeReduzierenHelper {

    public class reduceDeliveryQuantityResult {
        public List<delivery_line__c> dlList {get; set;}
        public string md5key {get; set;}
        public boolean error {get; set;}
        public String message {get; set;}
    }
    

    public static map<string, map<id, LiefermengeReduzierung__c>> makeRulsMap(Set<String> keys ) {
        map<string, map<id, LiefermengeReduzierung__c>> mainMap = new map<string, map<id, LiefermengeReduzierung__c>>();
        map<id, LiefermengeReduzierung__c> productIdLrMap;
        List<LiefermengeReduzierung__c> lrList = [SELECT key__c, Product__c, Liefermenge_alt__c, Liefermenge_neu__c 
                                                    FROM LiefermengeReduzierung__c
                                                    WHERE valid_from__c <= :date.today()
                                                    AND valid_to__c >= :date.today() 
                                                    AND key__c IN : keys
                                                    ORDER BY key__c];
        if((lrList != null) && (lrList.size() > 0)) {
            for(LiefermengeReduzierung__c lr : lrList) {
                if(mainMap.ContainsKey(lr.key__c)) {
                    productIdLrMap = mainMap.get(lr.key__c);
                    productIdLrMap.put(lr.Product__c, lr);
                    mainMap.put(lr.key__c, productIdLrMap);
                }
                else {
                    productIdLrMap = new map<id, LiefermengeReduzierung__c>();
                    productIdLrMap.put(lr.Product__c, lr);
                    mainMap.put(lr.key__c, productIdLrMap);
                }
            }
        }
        return mainMap;
    }

    public static String computeMd5Key(List<delivery_line__c> dlList) {
        if((dlList != null) && (dlList.size() > 0) ) {
            String md5key = null;
            String sKey = null;
            string curabox = null;
            List<string> keyList = new List<string>();
            for(delivery_line__c dl : dlList) {
                if ((dl.Order_line__c != null) && (dl.Order_line__r.order__c != null) && (dl.Order_line__r.order__r.Description__c != null) ) {
                    if (dl.Order_line__r.order__r.Description__c != 'KUWV') {
                        curabox = dl.Order_line__r.order__r.Description__c;
                        keyList.add(dl.Product__c + string.valueOf(dl.Quantity__c));
                    }
                }
            }
            keyList.sort();
            sKey = curabox;
            if(sKey != null) {
                for(string key : keyList) {
                    sKey += key;
                }
                md5Key = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(skey)));
                return md5key;
            }
            else {
                return null;
            }            
        }
        else {
            return null;
        }
    }

    // public static reduceDeliveryQuantityResult reduceDeliveryQuantity(List<delivery_line__c> dlList, map<string, map<id, LiefermengeReduzierung__c>> mainMap, Set<id> neueKundeIdSet, Set<id> alteKundeIdSet, date thresholdDate) {
    public static reduceDeliveryQuantityResult reduceDeliveryQuantity(List<delivery_line__c> dlList, map<string, map<id, LiefermengeReduzierung__c>> mainMap) {
        reduceDeliveryQuantityResult rdqr = new reduceDeliveryQuantityResult();
        rdqr.md5key = null;
        rdqr.error = false;

        List<delivery_line__c> reducedQuantityList = new List<delivery_line__c>();
        if((dlList != null) && (dlList.size() > 0) ) {
            String md5key = null;
            String sKey = null;
            string curabox = null;
            String orderName = ' ';
            List<string> keyList = new List<string>();
            for(delivery_line__c dl : dlList) {
                if ((dl.Order_line__c != null) && (dl.Order_line__r.order__c != null) && (dl.Order_line__r.order__r.Description__c != null) ) {
                    if (dl.Order_line__r.order__r.Description__c != 'KUWV') {
                        curabox = dl.Order_line__r.order__r.Description__c;
                        keyList.add(dl.Product__c + string.valueOf(dl.Quantity__c));
                        orderName = dl.Order_line__r.Order__r.Name;
                    }
                }
            }

            keyList.sort();

            sKey = curabox;

            if(sKey != null) {
                for(string key : keyList) {
                    sKey += key;
                }
            }

            system.debug('#####alex4702 sKey ' + sKey );
            if(sKey != null) {
                md5Key = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(skey)));
                
                system.debug('#####alex4703 md5Key ' + md5Key );
                system.debug('#####alex4704 mainMap.size() ' + mainMap.size());

                if(mainMap.ContainsKey(md5key)) {

                    rdqr.md5key = md5Key;
                    // gefunden. Neue Liste füllen
                    map<id, LiefermengeReduzierung__c> productIdLrMap = mainMap.get(md5key);


                    for(delivery_line__c dl : dlList) {
                        if ((dl.Order_line__c != null) && (dl.Order_line__r.order__c != null) && (dl.Order_line__r.order__r.Description__c != null) ) {
                            if (dl.Order_line__r.order__r.Description__c != 'KUWV') {
                                if(productIdLrMap.ContainsKey(dl.Product__c)) {
                                    if(dl.Order_Line__r.Order__c != null) {
                                        if(dl.Contact__r.without_temp_product__c) {
                                            dl.Quantity__c = productIdLrMap.get(dl.Product__c).Liefermenge_neu__c;
                                        }
                                        else {
                                            dl.Quantity__c = productIdLrMap.get(dl.Product__c).Liefermenge_alt__c;
                                        }
                                    }
                                }
                                // CB Positionen
                                reducedQuantityList.add(dl); 
                            }
                            else {
                                // KUWV Position
                                reducedQuantityList.add(dl); 
                            }
                        }
                        else {
                            // temp. Position
                            reducedQuantityList.add(dl); 
                        }
                    }
                    rdqr.dlList = reducedQuantityList;
                    return rdqr;
                }
                else {
                    // nicht gefunden, return error
                    rdqr.error = true;
                    rdqr.message = 'Key ' + md5key + ' not found. Curabox ' + curabox + ' Auftrag ' + orderName;
                    return rdqr;
                }
            }
            else {
                if(!reducedQuantityList.isEmpty()) {
                    rdqr.dlList = reducedQuantityList;
                }
                else {
                    if(dlList.size() > 0) {
                        rdqr.dlList = dlList;
                    }
                }
                return rdqr;
            }
        }
        else {
            rdqr.error = true;
            rdqr.message = 'No delivery lines';
            return rdqr;
        }
    }

    public static void createNewLiefermengeReduzierung(Map<id, Curabox_Product_Group__c> cpgMap) {

    }
}