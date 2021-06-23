/********************************************************************************************************************************************
// Created on 17.08.2020 von BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstraße. 29
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:             
//                       This apex class contains methods for managing delivery quantity settings
//********************************************************************************************************************************************
//  Changes:
//  08.09.2020	BT		#2570 The "valid to" date is now set to 31.12.4000. Before the md5 key is created product ids are alphabetically sorted. 
//********************************************************************************************************************************************
*/
public class DeliveryQuantityManagerController {    
    /* return all curaboxes available in the org */
    @AuraEnabled
    public static List<String> getCuraboxes(){
        List<String> curaboxes = new List<String>();
        for(curabox__c curabox: [SELECT Name FROM curabox__c ORDER BY Name ASC]) {
            curaboxes.add(curabox.Name);
        }
        return curaboxes;
    }
    
    /* return all available delivery quantity settings based on the specified curabox */
    @AuraEnabled
    public static List<LiefermengeReduzierung__c> getDeliveryQuantitySettings(String curabox, String key) {
        List<LiefermengeReduzierung__c> deliveryQuantitySettings = new List<LiefermengeReduzierung__c>();
        String queryString = 'SELECT curabox__r.Name, CuraboxName__c, curabox__c, Product__c, Suchschluessel__c, Product__r.Name, valid_to__c, valid_from__c, key__c, Menge__c, Liefermenge_alt__c, Liefermenge_neu__c ';
        queryString += 'FROM LiefermengeReduzierung__c WHERE curabox__r.Name = :curabox AND (valid_to__c >= TODAY AND valid_from__c <= TODAY)';
        if(!String.isBlank(key)){
            queryString += ' AND Suchschluessel__c = :key';
        }
        queryString += ' ORDER BY key__c ASC';
        
        for(LiefermengeReduzierung__c deliveryQuantitySetting: Database.query(queryString))
        {            
            deliveryQuantitySettings.add(deliveryQuantitySetting);
     
        }                
        return deliveryQuantitySettings;
    }    
    
    @AuraEnabled
    public static LiefermengeReduzierung__c getNewDeliveryQuantitySetting(){
        return new LiefermengeReduzierung__c(Menge__c=0,
                                             Liefermenge_alt__c=0,
                                             Liefermenge_neu__c=0,
                                             valid_from__c=Date.today(),
                                             valid_to__c=Date.newInstance(4000, 12, 31));
    }
    
    @AuraEnabled
    public static String insertDeliveryQuantitySettings(String curaboxId, String curaboxName, String deliveryQuantitySettingKey, List<LiefermengeReduzierung__c> deliveryQuantitySettings){
        String key = curaboxName;
        String md5Key;
        List<String> productIds = new List<String>();
        Map<Id, String> productMap = new Map<Id, String>();
        
        for(LiefermengeReduzierung__c lr: deliveryQuantitySettings) {
            productIds.add(lr.Product__c);
            productMap.put(lr.Product__c, String.valueOf(lr.Menge__c));            
        }
        
        // sort product ids
        productIds.sort();
        
        // create md5 key
        for(Id productId: productIds) {
            key += productId + productMap.get(productId);
        }        
        md5Key = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(key)));
        
		for(LiefermengeReduzierung__c lr: deliveryQuantitySettings) {
            lr.CuraboxName__c = curaboxName;
            lr.curabox__c = curaboxId;
            lr.Suchschluessel__c = deliveryQuantitySettingKey;
            lr.key__c = md5Key;
        }        
        
        try {
            insert deliveryQuantitySettings;
            return md5Key;
        }
        catch(System.Exception e) {
            return null;
        }
    }
    
    /* save changes to delivery quantity settings */
    @AuraEnabled
    public static Boolean updateDeliveryQuantitySettings(List<LiefermengeReduzierung__c> deliveryQuantitySettings){
        Boolean success = true;
        Map<Id, LiefermengeReduzierung__c> deliveryQuantitySettingMap = new Map<Id, LiefermengeReduzierung__c>();
        List<LiefermengeReduzierung__c> toUpdateDeliveryQuantitySettings = new List<LiefermengeReduzierung__c>();
        List<LiefermengeReduzierung__c> toInsertDeliveryQuantitySettings = new List<LiefermengeReduzierung__c>();
        
        for(LiefermengeReduzierung__c deliveryQuantitySetting: deliveryQuantitySettings) {
        	deliveryQuantitySettingMap.put(deliveryQuantitySetting.Id, deliveryQuantitySetting);
        }
        
        for(LiefermengeReduzierung__c deliveryQuantitySetting: [SELECT CuraboxName__c, curabox__c, Product__r.Name, valid_to__c, valid_from__c, key__c, Menge__c, 
                                                                Liefermenge_alt__c, Liefermenge_neu__c, Product__c, Suchschluessel__c
                                                                FROM LiefermengeReduzierung__c WHERE Id IN :deliveryQuantitySettingMap.keySet()]) 
        {
            if(deliveryQuantitySetting.Liefermenge_neu__c != deliveryQuantitySettingMap.get(deliveryQuantitySetting.Id).Liefermenge_neu__c
              	|| deliveryQuantitySetting.Liefermenge_alt__c != deliveryQuantitySettingMap.get(deliveryQuantitySetting.Id).Liefermenge_alt__c) {
                LiefermengeReduzierung__c toInsertDeliveryQuantitySetting = deliveryQuantitySettingMap.get(deliveryQuantitySetting.Id).clone(false, true, false, false);                
                toInsertDeliveryQuantitySettings.add(toInsertDeliveryQuantitySetting);
                deliveryQuantitySetting.valid_to__c = toInsertDeliveryQuantitySetting.valid_from__c.addDays(-1);
                toUpdateDeliveryQuantitySettings.add(deliveryQuantitySetting);                
            }
        }
                
        Savepoint sp = Database.setSavepoint();
        try {            
            if(!toInsertDeliveryQuantitySettings.isEmpty()) insert toInsertDeliveryQuantitySettings;
            if(!toUpdateDeliveryQuantitySettings.isEmpty()) update toUpdateDeliveryQuantitySettings;
        }
        catch(System.Exception e) {
            Database.rollback(sp);
            success = false;
        }
        return success;
    }
}