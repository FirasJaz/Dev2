/****************************************************************************************************************************
// Created 29.07.2019 von  AD
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
// This class test generate contacts data from clients
//
//****************************************************************************************************************************
// Changes: 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

@isTest
private class Curabox_Generate_Contact_Client_Test {
            
    @testSetup 
    static void setup() {
        // create Test data
        create_test_product.createProducts();
        List<Contact> asp = new List<Contact>();
        List<Kunde__c> kundeList = new List<Kunde__c>();
        List<Auftrag__c> aufList = new List<Auftrag__c>();
        List<Auftragsposition__c> aufPosList = new List<Auftragsposition__c>();
        List<Genehmigung__c> geneList = new List<Genehmigung__c>();
        List<Genehmigungsposition__c> genePosList = new List<Genehmigungsposition__c>();
        List<Lieferscheinposition__c> lsPosList = new List<Lieferscheinposition__c>();
        Artikelgruppe__c ag = new Artikelgruppe__c(Name = 'Test Artikelgruppe');

        for (Integer i = 0; i < 4; i++) {
            Contact contact = new Contact(LastName ='Alex '+ i);
            asp.add(contact);
        }
        insert asp;

        if (asp != null && asp.size() > 0) {
            for (Contact con : asp){
                Kunde__c  kunde = new Kunde__c(Name__c = 'Stephane', Produktgruppe__c ='PG54', Betreuer__c = con.Id, Geburtsdatum_text__c = '12.10.2015');
                kundeList.add(kunde);
            }
            Kunde__c  abena = new Kunde__c(Name__c = 'Abena', Produktgruppe__c ='PG54', Geburtsdatum_text__c = '12.10.2015');
            kundeList.add(abena);
            insert kundeList;
        }

        if(kundeList != null && kundeList.size() > 0){
            for (Kunde__c client : kundeList) {
                Auftrag__c auftrag = new Auftrag__c(Lieferzeitraum__c ='monatlich', Bezeichnung__c = 'CB1', Kunde__c = client.Id);
                Genehmigung__c gene = new Genehmigung__c(Antrag_eingegangen_am__c = System.today(), Nach_Paragraph__c = '54', Status__c = 'Antragsversand', Kunde__c = client.Id);
                aufList.add(auftrag);
                geneList.add(gene);
            }
            insert aufList;
            insert geneList;
        }

        if (aufList != null && aufList.size() > 0) {
            for (Auftrag__c order : aufList) {
               Auftragsposition__c aPos1 = new Auftragsposition__c(Auftrag__c = order.Id, Gen_Menge_Stk_Mon__c = 1);
               Auftragsposition__c aPos2 = new Auftragsposition__c(Auftrag__c = order.Id, Gen_Menge_Stk_Mon__c = 2);
               aufPosList.add(aPos1);
               aufPosList.add(aPos2);
            }
           insert aufPosList;
        }

        if(aufPosList != null && aufPosList.size() > 0){
            for (Auftragsposition__c  pos : aufPosList) {
                Lieferscheinposition__c lspos = new Lieferscheinposition__c(Auftragsposition__c = pos.Id, Status__c = 'Bedarf', Kunde__c = kundeList[0].Id);
                lsPosList.add(lspos);
            }
            insert lsPosList;
        }
        // insert productgroup
        insert ag;
        // insert Genehmigungsposition
        if(geneList != null && geneList.size() > 0){
            for (Genehmigung__c g : geneList) {
                Genehmigungsposition__c  gPos = new Genehmigungsposition__c(Genehmigung__c = g.Id, Artikelgruppe__c = ag.Id);
                genePosList.add(gPos);
            }
            insert genePosList;
        }

    }

    static testmethod void test() {        
        Test.startTest();
        Curabox_Generate_Contact_From_Client uca = new Curabox_Generate_Contact_From_Client();
        Id batchId = Database.executeBatch(uca);
        Test.stopTest();
        // after the testing stops, assert records were updated properly
        System.assertEquals(5, [select count() from contact where Kunde_Id__c != null]);
    }
}