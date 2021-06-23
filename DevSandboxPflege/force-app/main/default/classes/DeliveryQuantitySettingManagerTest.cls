/********************************************************************************************************************************************
// Created on 20.08.2020 von BT
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
//                       This is a test class for the class DeliveryQuantitySettingManagerController
//********************************************************************************************************************************************
//  Changes:
//  
//********************************************************************************************************************************************
*/
@isTest
private class DeliveryQuantitySettingManagerTest {
	@testSetup
    static void setup(){
        curabox__c c = new curabox__c(Name='CB98');
        insert c;
        
        Product__c p = new Product__c(Name='Test Product');
        p.abda_mwst_knz__c = '1';
        insert p;
        
        LiefermengeReduzierung__c deliveryQuantitySetting = new LiefermengeReduzierung__c();
        deliveryQuantitySetting.curabox__c = c.Id;
        deliveryQuantitySetting.Product__c = p.Id;
        deliveryQuantitySetting.Liefermenge_neu__c = 2;
        deliveryQuantitySetting.key__c = 'a399dhkiurr';
        deliveryQuantitySetting.Suchschluessel__c = '123456789';
        deliveryQuantitySetting.valid_to__c = Date.today().addMonths(4);
        deliveryQuantitySetting.valid_from__c = Date.today();
        insert deliveryQuantitySetting;
    }
    
    @isTest
    static void testGetCuraboxes(){
        List<String> curaboxes = DeliveryQuantityManagerController.getCuraboxes();
		System.assert(curaboxes.size() == 1);                
    }
    
    @isTest
    static void testGetDeliveryQuantitySettings(){
        List<LiefermengeReduzierung__c> deliveryQuantitySettings = DeliveryQuantityManagerController.getDeliveryQuantitySettings('CB98', '123456789');
        System.assert(deliveryQuantitySettings.size() == 1); 
    }
    
    @isTest
    static void testUpdateDeliveryQuantitySettings(){
        LiefermengeReduzierung__c deliveryQuantitySetting = [SELECT CuraboxName__c, curabox__c, Product__r.Name, valid_to__c, valid_from__c, key__c, Menge__c, 
                                                                Liefermenge_alt__c, Liefermenge_neu__c, Product__c, Suchschluessel__c
                                                             FROM LiefermengeReduzierung__c
                                                             WHERE Suchschluessel__c = '123456789' ];
        deliveryQuantitySetting.Liefermenge_neu__c = 10;
        DeliveryQuantityManagerController.updateDeliveryQuantitySettings(new List<LiefermengeReduzierung__c>{deliveryQuantitySetting});
        
		List<LiefermengeReduzierung__c> deliveryQuantitySettings = [SELECT CuraboxName__c, curabox__c, Product__r.Name, valid_to__c, valid_from__c, key__c, Menge__c, 
                                                                			Liefermenge_alt__c, Liefermenge_neu__c, Product__c, Suchschluessel__c
                                                                    FROM LiefermengeReduzierung__c
                                                             		WHERE Suchschluessel__c = '123456789' ]; 
        System.assert(deliveryQuantitySettings.size() == 2);
    }
    
    @isTest
    static void testGetNewDeliveryQuantitySetting() {
        LiefermengeReduzierung__c lr = DeliveryQuantityManagerController.getNewDeliveryQuantitySetting();
        System.assert(lr != null);
    }
    
    @isTest
    static void testiInsertDeliveryQuantitySettings() {
        Curabox__c cb = [SELECT Id, Name FROM Curabox__c WHERE Name = 'CB98'];
        Product__c pd = [SELECT Id FROM Product__c WHERE Name='Test Product'];
        List<LiefermengeReduzierung__c> lrList = new List<LiefermengeReduzierung__c>();
        lrList.add(new LiefermengeReduzierung__c(Product__c=pd.Id,
                                                 Menge__c=4,
                                                 liefermenge_alt__c=3,
                                                 liefermenge_neu__c=2,
                                                 valid_from__c=Date.today(),
                                                 valid_to__c=Date.today().addMonths(2)));
        String md5Key = DeliveryQuantityManagerController.insertDeliveryQuantitySettings(cb.Id, cb.Name, '345690', lrList);
        System.assert(md5Key != null);
    }
}