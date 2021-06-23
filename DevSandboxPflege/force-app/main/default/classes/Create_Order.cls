/****************************************************************************************************************************
// Created 18.04.2019 von  AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Create_Order {
    

    /**
    * set the order's attributes
    *  return a order
    */
    public static Order__C createNewOrder(String contactId, Date liefertag, String rythmus, String paragraph, String curabox, Date bisDatum){
        Order__c order = new Order__c();
        order.Opportunity__c = Curabox_Helper.getOpportunityByContact(contactId).OpportunityId;
        order.Contact__c = contactId;
        if(paragraph != '5X'){
            if(curabox.contains('CB')){
                order.Nach_Paragraph__c = '54';
            }
            else {
                order.Nach_Paragraph__c = '51';
            }
        }
        order.Status__c = 'aktiv';
        order.Delivery_frequency__c = rythmus;
        order.Liefertag__c = liefertag;
        order.Description__c = curabox;
        order.Genehmigt_von__c = liefertag;
        order.Genehmigt_bis__c = bisDatum;
        return order;
    }

    // set delivery day depending of working day.
    @AuraEnabled
    public static Date checkDeliveryDate(String contactId, String curabox){
        Date liefertag = System.today();
        Curabox_Genehmigung__c genehmigung = new  Curabox_Genehmigung__c ();
        if (curabox != 'KUWV') {
            genehmigung = Curabox_Helper.getGenehmigungByContact(contactId, '54');
        }
        else {
            genehmigung = Curabox_Helper.getGenehmigungByContact(contactId, '51');
        }
        // check Genehmigung
        if (genehmigung.Id != null && !String.isEmpty(genehmigung.Id)) {
            if (genehmigung.genehmigt_ab__c != null) {
                if (genehmigung.genehmigt_ab__c > liefertag) {
                    liefertag = Date.newInstance(genehmigung.genehmigt_ab__c.year(), genehmigung.genehmigt_ab__c.month(), genehmigung.genehmigt_ab__c.day());
                }
                else {
                    liefertag = liefertag;
                }
            }
            else {
                liefertag = liefertag;
            }
        }

        Delivery_Date__c delivery = Delivery_Date__c.getValues('default');
        if (liefertag.day() > delivery.Delivery__c) {
            liefertag = liefertag.addMonths(1).toStartOfMonth();
            datetime myDate = datetime.newInstance(liefertag.year(), liefertag.month(), liefertag.day());
            String day = myDate.format('EEEE');
            if (day == 'Saturday') {
                liefertag = liefertag.addDays(2);
            }
            else if (day == 'Sunday') {
                liefertag = liefertag.addDays(1);
            }
        }
        return liefertag;
    }

    /**
    *  call the insertOrder() function to insert order in the database
    *  and close the opportunity 
    */
    @AuraEnabled
    public static String insertNewOrder(String contactId, Date liefertag, String rythmus, String paragraph, String curabox, List<Product_List> pList, String glove1, Integer quantity1, String glove2, Integer quantity2, Date bisDatum, Product_List spruehkopf, Product_List pumpaufsatz){
        String returnString = '';
        if (contactId != null && !String.isEmpty(contactId)) {
            returnString = insertOrder(contactId, liefertag, rythmus, paragraph, curabox, pList, glove1, quantity1, glove2, quantity2, bisDatum, spruehkopf, pumpaufsatz);    
        }
        if (returnString == '' || returnString == null) {
            returnString = 'Der Auftrag konnte nicht generiert werden';
        }
        return returnString;
    }

    /**
    *  insert order and order lines in the database
    */
    public static String insertOrder(String contactId, Date liefertag, String rythmus, String paragraph, String curabox, List<Product_List> pList, String glove1, Integer quantity1, String glove2, Integer quantity2, Date bisDatum, Product_List spruehkopf, Product_List pumpaufsatz){
        Order__c order = createNewOrder(contactId, liefertag, rythmus, paragraph, curabox, bisDatum);
        Savepoint sp = Database.setSavepoint();
        try {
            insert order;
        } catch (Exception e) {
            System.debug('Beim Erstellen des Auftrags ist folgende Fehler aufgetreten: '+e);
        }
        // insert order Lines
        // Curabox flow
        list<Order_Line__c> lineList;
        if (pumpaufsatz == null) {
        lineList = Create_Order_Line.createOrderLines(order, curabox, pList, glove1, quantity1, glove2, quantity2, spruehkopf);
        }
        else {
            lineList = Create_Order_Line.createOrderLines(order, curabox, pList, glove1, quantity1, glove2, quantity2, spruehkopf, pumpaufsatz);
        }
        try {
            insert lineList;
        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('Beim Erstellen der Auftragspositionen ist folgende Fehler aufgetreten: '+e);
        }
        // create Delivery Note and Lines after insert Order and Order Lines
        if (order.Id != null && !String.isEmpty(order.Id)) {
            createDelivery(contactId, paragraph, order, lineList);
        }
        return order.Id;
    }

    // create Delivery Note and Lines for a order.
    public static void createDelivery(String contactId, String paragraph, Order__c order, List<Order_Line__c> orderLineList){
        Delivery_Note.createDeliveryByAntrag(contactId, paragraph, order, orderLineList);
    }

    /**
    *  This method close the related opportunity for a contact
    */
    public static void closeOpportunity(String contactId, String stage){
        Opportunity opportunity = Curabox_Helper.getOpportunityStage(contactId);
        if (opportunity.StageName != 'Closed Won') {
            opportunity.StageName = stage;
            opportunity.CloseDate = system.today();
            try {
                update opportunity;
            } catch (Exception e) {
                System.debug('close opportunity: ' + e);
            }
        }
    }

    // get all curabox to display
    @AuraEnabled
    public static List<curabox__c> getCuraboxes(){
        List<curabox__c> curaboxList = new List<curabox__c>();
        try{ 
            curaboxList = [select Id, Name from curabox__c];
        }
        catch(Exception e){
            System.debug(e);
        }
        return curaboxList;
    }

    // get all gloves to display
    @AuraEnabled
    public static List<Product__c> getGloves(){
        List<Product__c> productList = new List<Product__c>();
        try{ 
            productList = [select Id, Name,temp_product__c, Price__c from Product__c where Product_Group__r.Name ='Einmalhandschuhe'];
            for(Product__c product : productList){
                if(Product_List.mapProductValidPrice.containsKey(product.id)){
                 product.Price__c = Product_List.mapProductValidPrice.get(product.id);
                }
            }
        }
        catch(Exception e){
            System.debug(e);
        }
        return productList;
    }

    //
    @AuraEnabled
    public static List<Product_List> getProductList(String curabox, String contactId, Boolean isGenehmigung){
        return Product_List.productListWithGenehmigung(curabox, contactId, isGenehmigung);
    }

    // get sprühkopf product
    @AuraEnabled
    public static Product_List getSpruehkopf(){
        Product__c product = [SELECT Id, Name,temp_product__c, Product_Group__r.Name, Product_Group__r.keine_Genehmigungspflicht__c, Price__c FROM Product__c WHERE Product_Group__r.Name = 'Sprühkopf' LIMIT 1];
        if (product.Id != null && String.isNotEmpty(product.Id)) {
            return Product_List.createProductForFlexbox(product);
        }
        else {
            return null;
        }
    }
    
        // get pumpaufsatz product
    @AuraEnabled
    public static Product_List getPumpaufsatz(){
        Product__c product = [SELECT Id, Name,temp_product__c, Product_Group__r.Name, Product_Group__r.keine_Genehmigungspflicht__c, Price__c FROM Product__c WHERE Product_Group__r.Name = 'Pumpaufsatz' LIMIT 1];
        if (product.Id != null && String.isNotEmpty(product.Id)) {
            return Product_List.createProductForFlexbox(product);
        }
        else {
            return null;
        }
    }

    // 
    @AuraEnabled
    public static List<Product_List> getDefaultProducts(String contactId){
        return Product_List.getDefaultProductList(contactId);
    }

    //
    @AuraEnabled
    public static String getCuraboxByContact(String contactId){
        return Product_List.getWunschCurabox(contactId);
    }

    // get gloves informations to set as default by create orders (only for CB1-5)
    @AuraEnabled
    public static List<Product_List> getGlovesData(String contactId, String curabox){
        return Product_List.getCBGlovesData(contactId, curabox);
    }

    // check if activ order with same delivery day exists
    @AuraEnabled
    public static Boolean checkMonthCurrentOrder(String contactId, Date lieferdatum, String curabox){
        Boolean returnValue = false;
        List<Order__c> orderList = Curabox_Edit_Order.getOrders(contactId);
        if (orderList != null && orderList.size()>0) {
            for (Order__c order : orderList) {
               if (order.Status__c == 'aktiv' && order.Nach_Paragraph__c == checkParagraph(curabox)){
                   if (order.Liefertag__c.month() == lieferdatum.month()) {
                       returnValue = true;
                   }
               }
            }
        }
        return returnValue;
    }

    //
    public static String checkParagraph(String curabox){
        String paragraph = '';
        if (curabox.contains('CB')) {
            paragraph = '54';
        }
        else {
            paragraph = '51';
        }
        return paragraph;
    }

    @AuraEnabled
    public static Date setGenehmigungDateline(String contactId, String curabox){
        Date dateline = System.today();
        Curabox_Genehmigung__c genehmigung = new  Curabox_Genehmigung__c ();
        if (curabox != 'KUWV') {
            genehmigung = Curabox_Helper.getGenehmigungByContact(contactId, '54');
        }
        else {
            genehmigung = Curabox_Helper.getGenehmigungByContact(contactId, '51');
        }

        if (genehmigung.Id != null && !String.isEmpty(genehmigung.Id)) {
            if (genehmigung.unbefristet_genehmigt__c == true) {
                dateline = Date.newInstance(dateline.year()+100, dateline.month(), dateline.day());
            }
            else if (genehmigung.genehmigt_bis__c != null) {
                dateline = Date.newInstance(genehmigung.genehmigt_bis__c.year(), genehmigung.genehmigt_bis__c.month(), genehmigung.genehmigt_bis__c.day());
            }
            else {
                dateline = Date.newInstance(dateline.year()+100, dateline.month(), dateline.day());
            }
        }
        else {
            dateline = Date.newInstance(dateline.year()+100, dateline.month(), dateline.day());
        }
        return dateline;
    }


       @AuraEnabled
     public static Contact  getContact(String contactId){
        
        if (contactId != null && !String.isEmpty(contactId)) {
            return [select id,Status_PG51__c,Status_PG54__c,without_temp_product__c,Tempor_res_Produkt_Mundschutz__c from Contact where id=: contactId limit 1];
        }
        else return null ;
    }
        

}