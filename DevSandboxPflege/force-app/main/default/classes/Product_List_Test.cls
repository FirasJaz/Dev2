@isTest
public class Product_List_Test {
    
    /* Hilfmethoden für die Test-Klasse */
    public static curabox__c createCurabox(String name){
        curabox__c cb = [SELECT Id, Name FROM curabox__c WHERE Name =: name LIMIT 1];
        return cb;
    }

    public static Contact createContact(String name, Account fa, Product__c hand, curabox__c cb, String s){
        List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name ='Familienangehörige' and sObjectType = 'Contact'];
        Contact con = new Contact();
        con.lastName = name;
        con.Salutation = s;
        con.firstname = 'Alex';
        con.AccountId = fa.Id;
        con.Wunschbox__c = cb.Id;
        con.Art_Von_Handschuhe__c = hand.Id;
        con.RecordTypeId = rtList[0].Id;
        return con;
    }

    public static Contact createSimpleContact(String name, Account fa, curabox__c cb, String s){
        List<RecordType> rtList = [SELECT Id, sObjectType FROM RecordType WHERE Name ='Familienangehörige' and sObjectType = 'Contact'];
        Contact con = new Contact();
        con.lastName = name;
        con.Salutation = s;
        con.firstname = 'Alex';
        con.AccountId = fa.Id;
        con.Wunschbox__c = cb.Id;
        con.RecordTypeId = rtList[0].Id;
        return con;
    }

    public static Account createFamily(String name){
        List<RecordType> rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
        Account acc = new Account(Name = name);
        acc.RecordTypeId = rtList[0].Id;
        return acc;
    }

    public static void createWunschbox(String contactId){
        List<Wunschbox__c> wbList = new List<Wunschbox__c>();
        List<Product_List> pList = Product_List.getAllProduct(contactId);
        for (Product_List product : pList) {
            wbList.add(Product_List.newWunschbox(contactId, product));
        }
        insert wbList;
    }

    /*** Test-Methoden ***/
    @isTest static void getListOfProduct() {
        // create products test data
        create_test_product.createProducts();
        // insert family
        Account fa = createFamily('Transwaggon');
        insert fa;
        curabox__c curabox = createCurabox('CB3');
        curabox__c flexbox = createCurabox('CB6 - Flexibel');

        Product__c handschuhe = [SELECT Id, Name FROM Product__c Where Product_Group__r.Name = 'Einmalhandschuhe' LIMIT 1];
        // create Test contacts
        Contact con = createContact('De Jong', fa, handschuhe, curabox, 'Herr');
        Contact flexCon = createContact('De Light', fa, handschuhe, flexbox, 'Herr');
        Contact wbCon = createContact('Roben', fa, handschuhe, flexbox, 'Herr');
        List<Contact> conList = new List<Contact>();
        conList.add(con);
        conList.add(flexCon);
        conList.add(wbCon);
        insert conList;
        String contId = con.Id;
        String flexConId = flexCon.Id;
        String wbConId = wbCon.Id;
        // create wunschbox für wbCon
        createWunschbox(wbConId);
        List<Product_List> pList = Product_List.getDefaultProductList(contId);
        List<Product_List> pFlexList = Product_List.getDefaultProductList(flexConId);
        List<Product_List> pWbList = Product_List.getDefaultProductList(wbConId);

        System.assertEquals(3, pList.size());
        System.assertEquals(6, pFlexList.size());
        System.assertEquals(6, pWbList.size());
    }

    @isTest static void getGloveList(){
        // create products test data
        create_test_product.createProducts();

        List<Product__c> gloveList = Product_List.getGloveList();
        System.assertEquals(12, gloveList.size());
    }

    @isTest static void insertWunschbox(){
        // create products test data
        create_test_product.createProducts();
        // insert family
        Account fa = createFamily('Transwaggon');
        insert fa;
        curabox__c curabox = createCurabox('CB1');

        Product__c handschuhe = [SELECT Id, Name FROM Product__c Where Product_Group__r.Name = 'Einmalhandschuhe' LIMIT 1];
        // create Test contacts
        Contact con = createContact('Mbappe', fa, handschuhe, curabox, 'Herr');
        Contact wbCon = createContact('Neymar', fa, handschuhe, curabox, 'Herr');
        Contact nullCon = createContact('Rami', fa, handschuhe, curabox, 'Herr');
        List<Contact> conList = new List<Contact>();
        conList.add(con);
        conList.add(wbCon);
        conList.add(nullCon);
        insert conList;
        String contId = con.Id;
        String wbConId = wbCon.Id;
        String nullConId = nullCon.Id;
        // create wunschbox für wbCon
        createWunschbox(wbConId);
        // List of product 
        List<Product_List> pList = Product_List.getDefaultProductList(contId);
        String resCon = Product_List.insertWunschbox(contId, pList, 'Peha-soft-latex Einmalhandschuhe (Größe L)', 'Peha-soft-latex Einmalhandschuhe (Größe S)', 1, 2);
        List<Product_List> pWbList = Product_List.getDefaultProductList(wbConId);
        String resWbCon = Product_List.insertWunschbox(wbConId, pWbList, 'Peha-soft-latex Einmalhandschuhe (Größe L)', 'Peha-soft-latex Einmalhandschuhe (Größe S)', 1, 1);
        // exception
        List<Product_List> emptyList = new List<Product_List>();
        String resNull = Product_List.insertWunschbox(nullConId, emptyList, 'Peha-soft-latex Einmalhandschuhe (Größe L)', 'Peha-soft-latex Einmalhandschuhe (Größe S)', 0, 1);

        System.assertEquals('', resCon);
        System.assertEquals('', resWbCon);
        System.assertEquals('', resNull);
    }

    @isTest static void fillWunschboxComponent(){
        // create products test data
        create_test_product.createProducts();
        // insert family
        Account fa = createFamily('Transwaggon');
        insert fa;
        curabox__c curabox = createCurabox('CB1');
        curabox__c flexbox = createCurabox('CB6 - Flexibel');
        curabox__c cb1 = createCurabox('CB1');
        curabox__c cb3 = createCurabox('CB3');

        Product__c handschuhe = [SELECT Id, Name FROM Product__c Where Product_Group__r.Name = 'Einmalhandschuhe' LIMIT 1];
        // create Test contacts
        Contact con = createContact('Mbappe', fa, handschuhe, flexbox, 'Herr');
        Contact wbCon = createContact('Neymar', fa, handschuhe, flexbox, 'Herr');
        Contact nullCon = createContact('Rami', fa, handschuhe, curabox, 'Herr');
        // contact without glove
        Contact con1 = createSimpleContact('Umtiti', fa, cb1, 'Herr');
        Contact con2 = createSimpleContact('Pogba', fa, cb3, 'Herr');
        Contact con3 = createSimpleContact('Kante', fa, flexbox, 'Herr');
        List<Contact> conList = new List<Contact>();
        conList.add(con);
        conList.add(wbCon);
        conList.add(nullCon);
        conList.add(con1);
        conList.add(con2);
        conList.add(con3);
        insert conList;
        String contId = con.Id;
        String wbConId = wbCon.Id;
        String nullConId = nullCon.Id;
        //
        String conId1 = con1.Id;
        String conId2 = con2.Id;
        String conId3 = con3.Id;
        // create wunschbox für wbCon
        createWunschbox(wbConId);
        // List of product 
        List<Product_List> pList = Product_List.fillWunschboxComponent(contId);
        List<Product_List> pWbList = Product_List.fillWunschboxComponent(wbConId);
        List<Product_List> nullList = Product_List.fillWunschboxComponent(nullConId);

        System.assertEquals(5, pList.size());
        System.assertEquals(5, pWbList.size());
        System.assertEquals(0, nullList.size());

        /** method getGloveDetails(String contactId) */
        Product_List prodWithglove1 = Product_List.getGloveDetails(nullConId);
        Product_List prodWithglove2 = Product_List.getGloveDetails(contId);
        System.assertEquals(1, prodWithglove1.menge);
        System.assertEquals(0, prodWithglove2.menge);
        
        Product_List prod1 = Product_List.getGloveDetails(conId1);
        Product_List prod2 = Product_List.getGloveDetails(conId2);
        Product_List prod3 = Product_List.getGloveDetails(conId3);
        System.assertEquals(1, prod1.menge);
        System.assertEquals(2, prod2.menge);
        System.assertEquals(0, prod3.menge);

        /** method getCBGlovesData(String contactId, String curabox) */
        List<Product_List> gData1 = Product_List.getCBGlovesData(wbConId, 'CB5');
        System.assertEquals(1, gData1.size());
        List<Product_List> gData2 = Product_List.getCBGlovesData(contId, 'CB3');
        System.assertEquals(1, gData2.size());

        List<Product_List> gloveList1 = Product_List.getCBGlovesData(conId1, 'CB1');
        List<Product_List> gloveList2 = Product_List.getCBGlovesData(conId2, 'CB6 - Flexibel');
        List<Product_List> gloveList3 = Product_List.getCBGlovesData(conId3, 'CB2');
        System.assertEquals(1, gloveList1.size());
        System.assertEquals(1, gloveList2.size());
        System.assertEquals(1, gloveList3.size());
    }

    @isTest static void productListWithGenehmigung(){
        // create product
        create_test_product.createProducts();
        // create family
        Account fa = createFamily('Transwaggon');
        insert fa;
        curabox__c curabox = createCurabox('CB3');
        curabox__c flexbox = createCurabox('CB6 - Flexibel');

        Product__c handschuhe = [SELECT Id, Name FROM Product__c Where Product_Group__r.Name = 'Einmalhandschuhe' LIMIT 1];
        // create Test contacts
        Contact con = createContact('De Jong', fa, handschuhe, curabox, 'Herr');
        Contact con2 = createContact('De Light', fa, handschuhe, flexbox, 'Herr');
        List<Contact> conList = new List<Contact>();
        conList.add(con);
        conList.add(con2);
        insert conList;
        // create Genehmigung
        create_test_product.createGenehmigung();
        String contId = con.Id;
        String conId2 = con2.Id;
        // contact without Genehmigung
        Contact con3 = createContact('Roben', fa, handschuhe, flexbox, 'Herr');
        String conId3 = con3.Id;

        List<Product_List> pList1 = Product_List.productListWithGenehmigung('KUWV', contId, true);
        List<Product_List> pList2 = Product_List.productListWithGenehmigung('CB1', conId2, true);
        List<Product_List> pList3 = Product_List.productListWithGenehmigung('CB3', conId3, false);

        System.assertEquals(1, pList1.size());
        System.assertEquals(4, pList2.size());
        System.assertEquals(3, pList3.size());
    }


}