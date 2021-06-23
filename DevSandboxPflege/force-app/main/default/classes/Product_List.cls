/****************************************************************************************************************************
// Created 08.05.2019 von  AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//
//****************************************************************************************************************************
//
// Description:       
//
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Product_List {

    @AuraEnabled public String name {get; set;}
    @AuraEnabled public String groupe {get; set;}
    @AuraEnabled public Decimal price {get; set;}
    @AuraEnabled public Decimal menge{get; set;}
    @AuraEnabled public Decimal summe{get; set;}
    @AuraEnabled public Decimal genehmigteMenge{get; set;}
    @AuraEnabled public String genehmigungstatus{get; set;}
    @AuraEnabled public Boolean aproval{get; set;}
    @AuraEnabled public Boolean isTempProduct{get; set;}
    

public static Map<Id, Decimal> mapProductValidPrice{
        get{
            if (mapProductValidPrice == null){
                mapProductValidPrice = new Map<Id, Decimal>();
                for (Preisliste__c plist : [SELECT Id,Product__c,valid_from__c,valid_to__c,Preis__c
                                                FROM Preisliste__c WHERE valid_from__c <= TODAY and valid_to__c >=TODAY ]){
                    if(!mapProductValidPrice.containsKey(plist.Product__c))
                    mapProductValidPrice.put(plist.Product__c, plist.Preis__c);
                }
            }
            return mapProductValidPrice;
        }

        set;
    }

    public static Product_List createProduct(Product__c product, Curabox_Product_Group__c pg){
        Product_List returnObj = new Product_List();
        returnObj.name = product.Name;
        returnObj.price = mapProductValidPrice.containsKey(product.id)? mapProductValidPrice.get(product.id): product.Price__c;
        returnObj.groupe = product.Product_Group__r.Name;
        returnObj.aproval = product.Product_Group__r.keine_Genehmigungspflicht__c;
        returnObj.menge = pg.default_number__c;
        returnObj.summe = returnObj.price * pg.default_number__c;
        returnObj.isTempProduct = product.temp_product__c;
        return returnObj;
    }

    //
    public static Product_List createProductForFlexbox(Product__c product){
        Product_List returnObj = new Product_List();
        returnObj.name = product.Name;
        returnObj.price = mapProductValidPrice.containsKey(product.id)? mapProductValidPrice.get(product.id): product.Price__c;
        returnObj.groupe = product.Product_Group__r.Name;
        returnObj.aproval = product.Product_Group__r.keine_Genehmigungspflicht__c;
        returnObj.isTempProduct = product.temp_product__c;
        returnObj.menge = 0;
        returnObj.summe = 0;
        return returnObj;
    }

    // List of product to display by curabox change
    public static List<Product_List> getListOfProduct(String curabox, String contactId){
        List<Product_List> returnList = new List<Product_List>();
        List<Product_List> flexibelBoxList = convertWunschboxToProductList(getWunschboxByContact(contactId));
        if (!Curabox_Helper.isCB6Flexibel(curabox)) {
            List<Product__c> productList = getProductList(curabox);
            List<Curabox_Product_Group__c> productGroupList = getProductGroupList(curabox);
            if(productGroupList != null && productGroupList.size() > 0) {
                if (productList != null && productList.size() > 0){
                    for (Product__c product : productList) {
                        for (Curabox_Product_Group__c pg : productGroupList) {
                            if (product.Product_Group__c == pg.Product_Group__c) {
                                //if (product.Product_Group__r.Name != 'Einmalhandschuhe') {
                                    returnList.add(createProduct(product, pg));
                                //}
                            }
                        }
                    } 
                }  
            }
        }
        else {
            if (flexibelBoxList != null && flexibelBoxList.size()>0) {
                returnList.addAll(flexibelBoxList);
            }
            else {
                returnList.addAll(getAllProduct(contactId));
            }
        }
        return returnList; 
    }

    // contains the list of product with a aproval quantity for a specifical curabox 
    public static List<Product_List> productListWithGenehmigung(String curabox, String contactId, Boolean isGenehmigung){
        List<Product_List> returnList = new List<Product_List>();
        Curabox_Genehmigung__c genehmigung = new Curabox_Genehmigung__c();
        List<Product_List> productList = getListOfProduct(curabox, contactId);
        if (curabox != 'KUWV') {
            genehmigung = Curabox_Helper.getGenehmigungByContact(contactId, '54');
        }
        else {
            genehmigung = Curabox_Helper.getGenehmigungByContact(contactId, '51');
        }
        if (genehmigung.Id == null || String.isEmpty(genehmigung.Id)) {
            System.debug('############################################### Genehmigung nicht vorhanden #########################');
            if (isGenehmigung == true) {
                System.debug('############################################### Genehmigung nicht vorhanden true #########################');
                for (Product_List p : productList) {
                    p.genehmigteMenge = 10;
                    p.genehmigungstatus = 'Activ';
                    returnList.add(p);
                }
            }
            else {
                System.debug('############################################### Genehmigung nicht vorhanden false #########################');
                for (Product_List p : productList) {
                    p.genehmigteMenge = 0;
                    p.genehmigungstatus = 'Inactiv';
                    returnList.add(p);
                }
            }
        }
        else {
            List<Curabox_Genehmigungsposition__c> gPositions = getGenehmigungPositions(genehmigung.Id);
            if (genehmigung.Status__c == 'Antragsversand') {
                for (Product_List product : productList) {
                    product.genehmigteMenge = 10;
                    product.genehmigungstatus = 'Activ';
                    returnList.add(product);
                }
            }
            else if (genehmigung.Status__c == 'Bewilligung') {
                for (Product_List product : productList) {
                    for (Curabox_Genehmigungsposition__c position : gPositions) {
                        if (product.groupe == position.Product_Group__r.Name) {
                            if (position.Gen_Menge_Stk__c > 0) {
                                product.genehmigteMenge = position.Gen_Menge_Stk__c;
                                if (product.genehmigteMenge >= product.menge) {
                                    product.genehmigungstatus = 'Activ';
                                }
                                else {
                                    product.genehmigungstatus = 'Inactiv';
                                }
                            }
                            else {
                                product.genehmigteMenge = 0;
                                product.genehmigungstatus = 'Inactiv';
                            }
                            returnList.add(product);
                        }
                    }
                    if (product.aproval == true) {
                        product.genehmigungstatus = 'Activ';
                        product.genehmigteMenge = 10;
                        returnList.add(product);
                    }
                }
            }
        }
        return returnList;
    }

    //List of product to display for default curabox
    public static List<Product_List> getDefaultProductList(String contactId){
        return getListOfProduct(getWunschCurabox(contactId), contactId);
    }

    // List of all products for flexbox
    @AuraEnabled
    public static List<Product_List> getAllProduct(String contactId){
        List<Product_List> returnList = new List<Product_List>();
        List<Product__c> productList = getCB6ProductList();
        if (productList != null && productList.size() > 0){
            for (Product__c product : productList) {    
                if (product.Product_Group__r.Name != 'Einmalhandschuhe') {
                    returnList.add(createProductForFlexbox(product));
                }
            }
            Product__c prd = getProductByName(getHandschuheArt(contactId));
            if (prd.Id != null && !String.isEmpty(prd.Id)) {
                returnList.add(createProductForFlexbox(prd));
            }
            else {
                returnList.add(createProductForFlexbox(getProductByName('Peha-soft Vinyl Einmalhandschuhe (Größe M)')));
            }  
        }
       return returnList; 
    }

    //List of product that contains the flexbox
    public static List<Product__c> getCB6ProductList(){
        List<Product__c> productList = new List<Product__c>();
        List<Curabox_Product_Group__c> productGroupList = new List<Curabox_Product_Group__c>();
        List<Id> productGroup = new List<Id>();
        try{ 
            productGroupList = [SELECT Product_Group__c FROM Curabox_Product_Group__c WHERE Product_Group__r.Positionsnummer__c = '54'];
        }      
        catch(Exception e){
            System.debug(e);
        }
        productGroup = getProductGroupIds(productGroupList);
        try{ 
            productList = [Select Id, Name,temp_product__c, Product_Group__r.Name, Product_Group__r.keine_Genehmigungspflicht__c, Price__c from Product__c Where Product_Group__c IN: productGroup]; 
        }      
    
        catch(Exception e){
            System.debug(e);
        }
        return productList;
    } 

    /**
    *  return the list of products that are in a curabox
    */
    @AuraEnabled
    public static List<Product__c> getProductList(String curabox){
        List<Product__c> productList = new List<Product__c>();
        Product__c handschuhe = new Product__c();
        List<Id> productGroup = getProductGroupIds(getProductGroupList(curabox));
        try{ 
            productList = [SELECT Id, Name,temp_product__c, Product_Group__r.Name, Product_Group__r.keine_Genehmigungspflicht__c, Price__c FROM Product__c WHERE Product_Group__c IN: productGroup AND Product_Group__r.Name != 'Einmalhandschuhe' AND Product_Group__r.Name != 'Sprühkopf' AND Product_Group__r.Name != 'Pumpaufsatz']; 
        }      
        catch(Exception e){
            System.debug(e);
        }
        if (curabox != 'CB5' && curabox != 'KUWV') {
            handschuhe = [SELECT Id, Name,temp_product__c, Product_Group__r.Name, Product_Group__r.keine_Genehmigungspflicht__c, Price__c FROM Product__c Where Product_Group__c IN: productGroup AND Product_Group__r.Name = 'Einmalhandschuhe' LIMIT 1]; 
            productList.add(handschuhe);
        }
        return productList;
    }

    /**
    *  This method
    *  return the list of products group that are in a curabox
    */
    public static List<Curabox_Product_Group__c> getProductGroupList(String curabox){
        List<Curabox_Product_Group__c> productGroupList = new List<Curabox_Product_Group__c>();
        try{ 
            productGroupList = [Select Product_Group__c, Curabox__c, default_number__c from Curabox_Product_Group__c Where Curabox__r.Name =: curabox];
        }      
        catch(Exception e){
            System.debug(e);
        }
        return productGroupList;
    }

    /**
    *  This method
    *  return the list of products group ids that are in a curabox
    */
    public static List<Id> getProductGroupIds(List<Curabox_Product_Group__c> productGroupList){
        List<Id> returnList = new List<Id>();
        if(productGroupList != null && productGroupList.size()>0){
            for(Curabox_Product_Group__c pg : productGroupList){
                if(pg.Product_Group__c != null){
                    returnList.add(pg.Product_Group__c);
                }
            }
        }
        return returnList;
    }

    // get all gloves products
    @AuraEnabled
    public static List<Product__c> getGloveList(){
        return Create_Order.getGloves();
    }

    // get the selected glove from client
    public static String getHandschuheArt(String contactId){
       Contact contact = Curabox_Helper.getContactById(contactId);
       return contact.Art_Von_Handschuhe__r.Name;
    }

    // get the selectedcurabox from client
    public static String getWunschCurabox(String contactId){
        Contact contact = Curabox_Helper.getContactById(contactId);
        return contact.Wunschbox__r.Name;
    }

    public static Product__c getProductByName(String pName){
        List<Product__c> productList = new List<Product__c>();
        Product__c product = new Product__c();
        try {
            productList = [select Id, Name,temp_product__c, Price__c, Product_Group__r.Name, Product_Group__r.keine_Genehmigungspflicht__c from Product__c where Name =:pName];
            product = productList[0];
        } catch (Exception e) {
            System.debug(e);
        }
        return product;
    }

    // insert the wunschbox products.
    @AuraEnabled
    public static String insertWunschbox(String contactId, List<Product_List> productList, String glove1, String glove2, Integer quantity1, Integer quantity2){
        String str = '';
        List<Wunschbox__c> wunschList = getWunschboxByContact(contactId);
        if (wunschList != null && wunschList.size()> 0) {
            try {
                delete wunschList;
            } catch (Exception e) {
                System.debug('Fehler beim Update der Wunschbox Liste' + e);
            }
        }
        List<Wunschbox__c> wList = saveCBFlexibel(contactId, productList, glove1, glove2, quantity1, quantity2);
        try {
            insert wList;
        } catch (Exception e) {
            System.debug(e);
            str = null;
        }
        return str;
    }

    // set all products for a Wunschbox
    public static List<Wunschbox__c> saveCBFlexibel(String contactId, List<Product_List> productList, String glove1, String glove2, Integer quantity1, Integer quantity2){
        List<Wunschbox__c> wList = new List<Wunschbox__c>(); 
        if (productList != null && productList.size() > 0) {
            for (Product_List product : productList) {
                wList.add(newWunschbox(contactId, product));
            }
        }
        else {
            for (Product_List product : getAllProduct(contactId)) {
                if (product.groupe != 'Einmalhandschuhe') {
                    wList.add(newWunschbox(contactId, product));
                }
            }
        }
        if (quantity1 > 0) {
            wList.add(newWunschbox(contactId, createProductWithoutPG(getProductByName(glove1), quantity1)));
        }
        if (quantity2 > 0) {
           wList.add(newWunschbox(contactId, createProductWithoutPG(getProductByName(glove2), quantity2)));
        }
        return wList;
    }

    // initialize a Wunschbox
    public static Wunschbox__c newWunschbox(String contactId, Product_List product){
        Wunschbox__c box = new Wunschbox__c();
        box.Contact__c = contactId;
        box.Quantity__c = product.menge;
        box.Product__c = getProductByName(product.name).Id;
        return box;
    }

    // PG: Product group
    public static Product_List createProductWithoutPG(Product__c product, Integer quantity){
        Product_List returnObj = new Product_List();
        returnObj.name = product.Name;
        returnObj.menge = quantity;
        returnObj.price = mapProductValidPrice.containsKey(product.id)? mapProductValidPrice.get(product.id): product.Price__c;
        returnObj.summe = quantity * returnObj.price ; 
        returnObj.isTempProduct = product.temp_product__c;
        return returnObj;
    }

    // get wunschbox products to set as default by create order.
    public static List<Wunschbox__c> getWunschboxByContact(String contactId){
        List<Wunschbox__c> wList = new List<Wunschbox__c>();
        try {
            wList = [Select Id, Product__c, Product__r.temp_product__c, Product__r.Name, Product__r.Product_Group__r.Name, Product__r.Price__c, Quantity__c from Wunschbox__c where Contact__c =: contactId];
        } catch (Exception e) {
            System.debug(e);
        }
        return wList;
    }

    //
    public static List<Product_List> convertWunschboxToProductList(List<Wunschbox__c> wList){
        List<Product_List> productList = new List<Product_List>();
        if (wList != null && wList.size() > 0) {
            for (Wunschbox__c box : wList) {
                productList.add(createProductByWunschbox(box));
            }
        }
        return productList;
    }

    // 
    public static Product_List createProductByWunschbox(Wunschbox__c box){
        Product_List returnObj = new Product_List();
        returnObj.groupe = box.Product__r.Product_Group__r.Name;
        returnObj.name = box.Product__r.Name;
        returnObj.menge = box.Quantity__c;
        returnObj.price = mapProductValidPrice.containsKey(box.Product__r.id)? mapProductValidPrice.get(box.Product__r.id): box.Product__r.Price__c;
        returnObj.summe = returnObj.price*box.Quantity__c;
        returnObj.isTempProduct = box.Product__r.temp_product__c;
        return returnObj;
    }

    // get all product to display if wunschbox is CB6, else show only gloves picklist.
    @AuraEnabled
    public static List<Product_List> fillWunschboxComponent(String contactId){
        String curabox = getWunschCurabox(contactId);
        List<Product_List> flexibelBoxList = convertWunschboxToProductList(getWunschboxByContact(contactId));
        List<Product_List> productList = new List<Product_List>();
        if (!Curabox_Helper.isCB6Flexibel(curabox)){}
        else {
            if (flexibelBoxList != null && flexibelBoxList.size() > 0) {
                for (Product_List product : flexibelBoxList) {
                    if (product.groupe != 'Einmalhandschuhe') {
                        productList.add(product);
                    } 
                }
            }
            else {
                for (Product_List product : getAllProduct(contactId)) {
                    if (product.groupe != 'Einmalhandschuhe') {
                        productList.add(product);
                    } 
                }
            }
        }
       return productList;
    }

    // get gloves informations to set as default by create wunschbox
    @AuraEnabled
    public static Product_List getGloveDetails(String contactId){
        String glove = getHandschuheArt(contactId);
        String curabox = getWunschCurabox(contactId);
        Product_List productList = new Product_List();
        
        if (glove != null && !String.isEmpty(glove)) {
            Product__c product = getProductByName(glove);
            productList.name = product.Name;
            productList.price = product.Price__c;
            if (!Curabox_Helper.isCB6Flexibel(curabox)){
                productList.menge = Create_Order_Line.getQuantity(curabox, product.Product_Group__r.Name);
            }
            else {
                productList.menge = 0;
            }
            productList.summe = productList.menge*productList.price;
        }
        else {
            Product__c prd = getProductByName('Peha-soft Vinyl Einmalhandschuhe (Größe M)');
            if((curabox == 'CB1') || (curabox == 'CB5') || (curabox == 'KUWV')) {
                productList.name = prd.Name;
                productList.price = prd.Price__c;
                productList.menge = 1;
            }
            else if (Curabox_Helper.isCB6Flexibel(curabox)) {
                productList.name = prd.Name;
                productList.price = prd.Price__c;
                productList.menge = 0;
                productList.summe = 0;
            }
            else {
                productList.name = prd.Name;
                productList.price = prd.Price__c;
                productList.menge = 2;
                productList.summe = 2 * prd.Price__c;
            }
        }
        return productList;
    }

    // get gloves products to set as default by create order.
    public static List<Wunschbox__c> getGlovesByWunschbox(String contactId){
        List<Wunschbox__c> wList = new List<Wunschbox__c>();
        try {
            wList = [Select Id, Product__c,Product__r.temp_product__c, Product__r.Name, Product__r.Product_Group__r.Name, Product__r.Price__c, Quantity__c from Wunschbox__c where Contact__c =: contactId and Product__r.Product_Group__r.Name ='Einmalhandschuhe'];
        } catch (Exception e) {
            System.debug(e);
        }
        return wList;
    }

    // get gloves informations to set as default by create orders (only for CB1-5)
    public static List<Product_List> getCBGlovesData(String contactId, String curabox){
        List<Product_List> productList = new List<Product_List>();
        List<Wunschbox__c> wList = getGlovesByWunschbox(contactId);
        String glove = getHandschuheArt(contactId);
        if (wList != null &&  wList.size()>0) {
            productList.addAll(convertWunschboxToProductList(wList));
        }else {
            if(glove != null && !String.isEmpty(glove)){
                Product__c product = getProductByName(glove);
                productList.add(createProductWithoutPG(product, Integer.valueOf(Create_Order_Line.getQuantity(curabox, product.Product_Group__r.Name))));
            }
            else {
                Product__c product = getProductByName('Peha-soft Vinyl Einmalhandschuhe (Größe M)');
                if(curabox == 'CB1') {
                    productList.add(createProductWithoutPG(product, 1));
                }
                else if (Curabox_Helper.isCB6Flexibel(curabox)) {
                    productList.add(createProductWithoutPG(product, 0));
                }
                else {
                    productList.add(createProductWithoutPG(product, 2));
                }
            }
        }
        return productList;
    }

    // get all positions of a Genehmigung
    public static List<Curabox_Genehmigungsposition__c> getGenehmigungPositions(String genehmigungId){
        List<Curabox_Genehmigungsposition__c> positionList = new List<Curabox_Genehmigungsposition__c>();
        try {
            positionList = [Select Id, Name, Gen_Menge_Stk__c, genehmigt_ab__c, genehmigt_bis__c, unbefristet_genehmigt__c, Product_Group__r.Name from Curabox_Genehmigungsposition__c where Genehmigung__c =:genehmigungId];
        } catch (Exception e) {
            System.debug(e);
        }
        return positionList;
    }

}