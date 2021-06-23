/********************************************************************************************************************************************
// Erstellt 23.11.2016 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
// Parameter: no
//
//********************************************************************************************************************************************
//
// Beschreibung:             
//
//********************************************************************************************************************************************
//Änderungen:
//********************************************************************************************************************************************
*/

@isTest(SeeAllData=false)
private class shippingcode_curabox_test {  
    static testMethod void myTest1() {
        Test.startTest();

        Account kk = New Account(Name = 'AOK', Industry = 'Krankenkassen');
        insert kk;

        Kunde__c kd = new Kunde__c (Anrede__c = 'Herr', Vorname__c = 'Test', Name__c = 'Kunde', Kundennummer__c = 10, Krankenkasse__c = kk.id, produktgruppe__c = 'PG54', e_mail__c='test@test.org');
        insert kd;

        Anschrift__c Ans1 = new Anschrift__c (Kunde__c = kd.Id, Name = 'Test Kunde', Stra_e__c = '', Ort__c = '', PLZ__c = '12345', Standardlieferanschrift__c = true, interne_notiz__c = '', Art_der_Anschrift__c = 'Kundenadresse', e_mail__c='test@test.org');        
        insert Ans1;

        Lieferschein__c LS = new Lieferschein__c(Kunde__c = kd.id, Liefertext__c='CB1', Lieferanschrift__c = Ans1.id);
        insert LS;
        
        Lieferbest_tigung__c LB = new Lieferbest_tigung__c(Kunde__c = kd.id, Lieferschein__c = LS.id, statusMsgId__c = '12345' );
        insert LB;

        Antragstext__c AT = new Antragstext__c(Textkey__c = 'DHL shipping code Curabox', Betreff__c='test', RichText__c='$anredeformel$ $dhlurl$ $dhlsnr$');
        insert AT;

        shippingcode_curabox scc = new shippingcode_curabox();
        Id batchId = Database.executeBatch(scc);
        
        list<Lieferbest_tigung__c> lbList = new list<Lieferbest_tigung__c>();
        lbList.add(LB);

        scc.execute(null, lbList);
        shippingcode_curabox_start mobject = new shippingcode_curabox_start();
        String sch = '0 0 5 * * ?';
        system.schedule('Schedule TEST', sch, mobject);

        Test.stopTest();
    }
}