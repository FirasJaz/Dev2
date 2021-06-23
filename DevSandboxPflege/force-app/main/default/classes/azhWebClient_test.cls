/****************************************************************************************************************************
// Erstellt 25.05.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//****************************************************************************************************************************
//
// Beschreibung: test for azhWebClient
//                      
//****************************************************************************************************************************     
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
@isTest
public class azhWebClient_test {
      @testSetup static void dataForTest() {
        // custom settings
        CompanyInfo__c companyInfo = new CompanyInfo__c(name='Default', IK_Nummer__c='567894939');
        insert companyInfo;
        azhCredetials__c azh = new azhCredetials__c(name='Sandbox', Endpoint__c='test', User__c='test', password__c='test');
        insert azh;
        azh = new azhCredetials__c(name='Production', Endpoint__c='test', User__c='test', password__c='test');
        insert azh;

        // Product_group + products
        Product_Group__c pg54 = new Product_Group__c(Positionsnummer__c='54', name='Handschuhe');
        insert pg54;
        Product_Group__c pg54_2 = new Product_Group__c(Positionsnummer__c='54', name='Mundschutz');
        insert pg54_2;
        Product_Group__c pg51 = new Product_Group__c(Positionsnummer__c='51', name='KUWV');
        insert pg51;
        Product__c p1 = new Product__c(Product_Group__c=pg54.id, standard_article_for_curabox__c=true,volume_unit__c='110',
                                        Hilfsmittelpositionsnummer__c='540000001', price__c=10.0, description__c='Handschue', abda_mwst_knz__c='1');
        insert p1;
        Product__c p2 = new Product__c(Product_Group__c=pg54_2.id, standard_article_for_curabox__c=true,volume_unit__c='110',
                                        Hilfsmittelpositionsnummer__c='540000002', price__c=10.0, description__c='Mundschutz', abda_mwst_knz__c='1');
        insert p2;
        Product__c p3 = new Product__c(Product_Group__c=pg51.id, standard_article_for_curabox__c=true,volume_unit__c='10',
                                        Hilfsmittelpositionsnummer__c='510000000', price__c=10.0, description__c='KUWV', abda_mwst_knz__c='1');
        insert p3;      

        // Accounts
        list<RecordType> kk_rtList = [SELECT Id FROM RecordType WHERE Name = '03 Kostenträger']; 
        // Pflegekasse
        Account KK = new Account(name='Testpflegekasse', Industry = 'Krankenkassen', type = 'Test');
        KK.RecordTypeId = kk_rtList[0].id;
        KK.IK_Nummer__c = '12345678';
        KK.Kanal_Unterpunkt__c = 'gesetzlich';
        KK.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
        KK.Hilfsmittel_Kennzeichen__c = 'HM';     
        KK.AC__c = 'AC';
        KK.TK__c = 'TK';   
        KK.Medifox_Ausschluss__c = true;
        KK.BillingStreet = 'Teststrasse';
        KK.Billingcity = 'Testort';
        KK.BillingPostalCode = '12345';
        KK.Fax = '04012345678';
        KK.KV_51_Automatically_Approved__c = true;
        insert KK;

        // Familie
        list<RecordType> fam_rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien']; 
        
        Account testFamilie = new Account(RecordTypeId = fam_rtList[0].id,
                                          Name = 'testFamilie');
                                          
        insert testFamilie;

        // contact
        Contact testContact = new Contact( 
                                    lastname = 'test_lastname',
                                    firstname = 'test_firstname',
                                    AccountId = testFamilie.Id,
                                    Email = 'test@test.de',
                                    Phone = '0123456789',
                                    MailingStreet = 'contactstreet',
                                    MailingPostalCode='23456',
                                    MailingCity='contactcity',
                                    Kranken_Pflegekasse__c=KK.id,
                                    Versicherungsnummer__c='VERSNR01234567',
                                    Birthdate=date.today().addYears(-60)
                                    //Art_Von_Handschuhe__c=p1.id
                                    );
        insert testContact;
        
        // Genehmigung
        Curabox_Genehmigung__c gen = new Curabox_Genehmigung__c(contact__c=testContact.id, Nach_Paragraph__c='54', kvnr_azh__c='1234');
        insert gen;

        Curabox_Genehmigungsposition__c gp1 = new Curabox_Genehmigungsposition__c(Genehmigung__c=gen.id, Product_Group__c=pg54.id,
                                        Ant_Menge_Stk__c=10);
        insert gp1;
        Curabox_Genehmigungsposition__c gp2 = new Curabox_Genehmigungsposition__c(Genehmigung__c=gen.id, Product_Group__c=pg54_2.id,
                                        Ant_Menge_Stk__c=10);
        insert gp2;   

        // Document
        ContentVersion contentVersionInsert = new ContentVersion(
            Title = 'Antrag_PG54.pdf',
            PathOnClient = 'Antrag_PG54.pdf',
            VersionData = Blob.valueOf('Test Content Data'),
            IsMajorVersion = true
        );
        insert contentVersionInsert; 
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink(LinkedEntityId=testContact.id, ContentDocumentId=contentVersionSelect.ContentDocumentId, 
                                            ShareType='I');
        insert cdl;                
    }

    static testMethod void Test1() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new azhWebClientMock(testgen.id));
        azhWebClient client = new azhWebClient();
        Curabox_Genehmigung__c gen = client.readGenehmigung(testgen.id);
        String result = client.makeKVstring(gen, 'Antrag_PG54.pdf') ;
        HttpRequest req = client.makeSimpleHttpRequest('sendKostenvoranschlagData');
        req = client.makeMultipartHttpRequest('sendKostenvoranschlagData', result, gen.Id);
        boolean ok = client.sendKVCheckRequest(gen.Id, 'sendKostenvoranschlagData');
        ok = client.sendKVCheckRequest(gen.Id, 'retrieveKostenvoranschlagData');

        ok = client.sendKVCheckRequest(gen.Id, 'checkInfopool');
        Test.stopTest(); 
    }

    static testMethod void Test2() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];
        Account kk = [SELECT id, KV_Anhangsart__c, KV_PG51_HIMINR__c, KV_PG54_HIMINR__c, KV_Verordner__c, KV_Ansprechpartner_LE__c,
                            KV_Ansprechpartner_LE_Telefon__c, KV_Hilfsmittelkennzeichen__c  
                    FROM account WHERE name='Testpflegekasse'];
        kk.KV_Anhangsart__c = '10';
        kk.KV_PG51_HIMINR__c = '123';
        kk.KV_PG54_HIMINR__c = '123';
        kk.KV_Verordner__c = '90909';
        kk.KV_Ansprechpartner_LE__c = 'test';
        kk.KV_Ansprechpartner_LE_Telefon__c = '123';
        kk.KV_Hilfsmittelkennzeichen__c = '88';
        update kk;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new azhWebClientMock(testgen.id));
        azhWebClient client = new azhWebClient();
        Curabox_Genehmigung__c gen = client.readGenehmigung(testgen.id);
        String result = client.makeKVstring(gen, 'Antrag_PG54.pdf') ;
        HttpRequest req = client.makeSimpleHttpRequest('sendKostenvoranschlagData');
        req = client.makeMultipartHttpRequest('sendKostenvoranschlagData', result, gen.Id);
        boolean ok = client.sendKVCheckRequest(gen.Id, 'sendKostenvoranschlagData');
        ok = client.sendKVCheckRequest(gen.Id, 'retrieveKostenvoranschlagData');

        ok = client.sendKVCheckRequest(gen.Id, 'checkInfopool');
        Test.stopTest(); 
    }

    static testMethod void TestretrieveAnhang() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new azhWebClientMock(testgen.id));
        azhWebClient client = new azhWebClient();
        Curabox_Genehmigung__c gen = client.readGenehmigung(testgen.id);

        boolean ok = client.sendKVCheckRequest(gen.Id, 'retrieveAnhang');
        client.processResponceReturn('retrieveAnhang');

        Test.stopTest(); 

        List<Curabox_Genehmigung_AZH_responce__c> li = [SELECT Code__c FROM Curabox_Genehmigung_AZH_responce__c];
        system.debug('###'+li);
    }   


    static testMethod void TestretrieveAnhangEntscheidung() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new azhWebClientMock(testgen.id));
        azhWebClient client = new azhWebClient();
        Curabox_Genehmigung__c gen = client.readGenehmigung(testgen.id);
        blob pdf = blob.valueOf('test');
        client.pdf.add(pdf); 
        boolean ok = client.sendKVCheckRequest(gen.Id, 'retrieveAnhangEntscheidung');
        client.processResponceReturn('retrieveAnhangEntscheidung');

        Test.stopTest(); 

        List<Curabox_Genehmigung_AZH_responce__c> li = [SELECT Code__c FROM Curabox_Genehmigung_AZH_responce__c];
        system.debug('###'+li);
    }   

    static testMethod void TestretrieveNachricht() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new azhWebClientMock(testgen.id));
        azhWebClient client = new azhWebClient();
        Curabox_Genehmigung__c gen = client.readGenehmigung(testgen.id);

        boolean ok = client.sendKVCheckRequest(gen.Id, 'retrieveNachricht');
        client.processResponceReturn('retrieveNachricht');

        Test.stopTest(); 

        List<Curabox_Genehmigung_AZH_responce__c> li = [SELECT Code__c FROM Curabox_Genehmigung_AZH_responce__c];
        system.debug('###'+li);
    }   

    static testMethod void TestRetrieveKostenvoranschlagData() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];

        Test.startTest();
        azhWebClientMock azhMock = new azhWebClientMock(testgen.id);
        azhMock.setresponse_genId(String.valueOf(testgen.id));
        Test.setMock(HttpCalloutMock.class, azhMock);
        azhWebClient client = new azhWebClient();
        Curabox_Genehmigung__c gen = client.readGenehmigung(testgen.id);

        boolean ok = client.sendKVCheckRequest(gen.Id, 'retrieveKostenvoranschlagData');
        client.processResponceReturn('retrieveKostenvoranschlagData');
        String testid = client.getResponse_kvnr_bsw();
        system.debug('### testid='+testid);
        Test.stopTest(); 

        List<Curabox_Genehmigung_AZH_responce__c> li = [SELECT Code__c FROM Curabox_Genehmigung_AZH_responce__c];
        system.debug('###'+li);
    }   

    static testMethod void TestCheckInfopool() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];
        Test.startTest();
        azhWebClientMock azhMock = new azhWebClientMock(testgen.id);
        azhMock.setresponse_genId(String.valueOf(testgen.id));
        Test.setMock(HttpCalloutMock.class, azhMock);
        azhWebClient client = new azhWebClient();
        Curabox_Genehmigung__c gen = client.readGenehmigung(testgen.id);

        boolean ok = client.sendKVCheckRequest(testgen.id, 'checkInfopool');
        // client.processResponceReturn('retrieveKostenvoranschlagData');
        client.retrieveAnhangEntscheidung(testgen.id, false);
        String testid = client.getResponse_kvnr_bsw();
        system.debug('### testid='+testid);
        Test.stopTest(); 

        List<Curabox_Genehmigung_AZH_responce__c> li = [SELECT Code__c FROM Curabox_Genehmigung_AZH_responce__c];
        system.debug('### azh responce'+li);

        List<ContentVersion> cvList = [SELECT PathOnClient FROM ContentVersion WHERE FirstPublishLocationId = : testgen.id];
        system.debug('### attachments responce'+cvList);

    }

    static testMethod void testJobScedule() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];
        Test.startTest();     
        System.schedule('sendKostenvoranschlagData Fax ' + string.valueOf(testgen.id) , '0 0 * * * ?', new azhRetrieveData('1sendKostenvoranschlagData', 'abc'));
        System.schedule('sretrieveAnhangEntscheidung ' + string.valueOf(testgen.id) , '0 0 * * * ?', new azhRetrieveData('1retrieveAnhangEntscheidung', 'abc'));
        System.schedule('retrieveKostenvoranschlagData ' + string.valueOf(testgen.id) , '0 0 * * * ?', new azhRetrieveData('1retrieveKostenvoranschlagData', 'abc'));   
        Test.stopTest(); 
    }
    
    static testMethod void testPrivate() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];
        Account kk = [SELECT id, Kanal_Unterpunkt__c  
                    FROM account WHERE name='Testpflegekasse'];
        kk.Kanal_Unterpunkt__c = 'privat';
        update kk;
        Test.startTest();     
        azhWebClient client = new azhWebClient();
        client.isPrivat(testgen.id); 
        Test.stopTest(); 
    }
    
    static testMethod void testAutomaticaly() {
        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];
        Account kk = [SELECT id, Kanal_Unterpunkt__c  
                    FROM account WHERE name='Testpflegekasse'];
        kk.KV_54_Automatically_Approved__c = true;
        kk.KV_51_Automatically_Approved__c = true;
        update kk;
        Test.startTest();     
        azhWebClient client = new azhWebClient();
        client.isAutomaticallyApproved(testgen.id); 
        Test.stopTest(); 
    }

//    static testMethod void testStartCheckInfoPool() {
//        Test.startTest();
//        System.schedule('checkInfoPool 1 0', '0 0 0 * * ?', new azhCheckInfoPool());
//        Curabox_Genehmigung__c testgen = [SELECT id FROM Curabox_Genehmigung__c LIMIT 1];
//        azhWebClientMock azhMock = new azhWebClientMock(testgen.id);
//        azhMock.setresponse_genId(String.valueOf(testgen.id));
//        Test.setMock(HttpCalloutMock.class, azhMock);
//        azhStartCheckInfoPool j = new azhStartCheckInfoPool();
//        j.execute(null);
//        Test.stopTest();
//        List<CronTrigger> ctList = [SELECT id FROM CronTrigger WHERE CronJobDetailId IN (SELECT id FROM CronJobDetail WHERE name LIKE 'checkInfoPool%')];
//        system.debug('#### ' + ctList.size());
//        System.assertEquals(ctList.size() , 11);
//    }

}