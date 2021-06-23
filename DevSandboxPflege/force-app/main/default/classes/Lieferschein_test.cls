/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class Lieferschein_test {

    static testMethod void myUnitTest() {
        Account KrK = new Account();
        KrK.Industry = 'Krankenkassen';
        KrK.Name = 'Krankenkasse';
        KrK.BillingCity = 'Hamburg';
        KrK.BillingState = 'DE';
        KrK.BillingStreet = 'Reeperbahn';
        KrK.BillingPostalCode = '20301';
        
        insert KrK;
        
        Account KK = new Account();
        KK.Industry = 'Spediteure/Logistikdienstleister';
        KK.Name = 'Spediteure';
        KK.BillingCity = 'Hamburg';
        KK.BillingState = 'DE';
        KK.BillingStreet = 'Reeperbahn';
        KK.BillingPostalCode = '20301';
        
        insert KK;
        
        Parameter__c pa = new Parameter__c();
        pa.Name = 'Standard Versandpartner';
        pa.Text__c = 'Spediteure';
        pa.Wert__c = 'Spediteure';
        insert pa;
        
        Kunde__c kd = new Kunde__c (Anrede__c = 'Herr', Vorname__c = 'Test', Name__c = 'Kunde', 
                                    Kundennummer__c = 10, Krankenkasse__c = KrK.id,
                                    Produktgruppe__c = 'PG51');
        insert kd;
        
        
        Anschrift__c an1 = new Anschrift__c(Kunde__c = kd.id);
        insert an1;
        Anschrift__c an2 = new Anschrift__c(Kunde__c = kd.id);
        insert an2;
        
        Auftrag__c Au = new Auftrag__c (Kunde__c = kd.id);
        insert AU;
        Auftragsposition__c Apos = new Auftragsposition__c (Kunde__c = kd.id, Auftrag__c = Au.ID,
                                                            Restmenge__c = 100,
                                                            reicht_bis__c = date.today().addDays(60),
                                                            letzter_AZ_Bis__c = date.today().addDays(60),
                                                            Enddatum_letzte_lieferung__c = date.today().addDays(30));
        insert Apos;
        Artikel__c Art = new Artikel__c (Name = 'TestArt');
        insert Art;
        Lieferscheinposition__c alt = new Lieferscheinposition__c(Auftragsposition__c = Apos.id,
                                                                Kunde__c = kd.id,
                                                                Artikel__c = Art.id,
                                                                VZ_von__c = date.Today().addDays(-30),
                                                                VZ_Bis__c = date.Today(),
                                                                AZ_von__c = date.Today().addDays(-30),
                                                                AZ_Bis__c = date.Today(),
                                                                Lieferdatum__c = date.Today(),
                                                                Menge__c = 10,
                                                                Status__c = 'geliefert');
        Lieferscheinposition__c Bed = new Lieferscheinposition__c(Auftragsposition__c = Apos.id,
                                                                Kunde__c = kd.id,
                                                                Artikel__c = Art.id,
                                                                VZ_von__c = date.Today().addDays(60),
                                                                VZ_Bis__c = date.Today().addDays(90),
                                                                AZ_von__c = date.Today().addDays(60),
                                                                AZ_Bis__c = date.Today().addDays(90),
                                                                Lieferdatum__c = date.Today().addDays(60),
                                                                Menge__c = 10,
                                                                Status__c = 'Bedarf');
        Lieferscheinposition__c gel = new Lieferscheinposition__c(Auftragsposition__c = Apos.id,
                                                                Kunde__c = kd.id,
                                                                Artikel__c = Art.id,
                                                                VZ_von__c = date.Today().addDays(30),
                                                                VZ_Bis__c = date.Today().addDays(60),
                                                                AZ_von__c = date.Today().addDays(30),
                                                                AZ_Bis__c = date.Today().addDays(60),
                                                                Lieferdatum__c = date.Today().addDays(30),
                                                                Menge__c = 20,
                                                                Status__c = 'geliefert');
        Lieferscheinposition__c jet = new Lieferscheinposition__c(Auftragsposition__c = Apos.id,
                                                                Kunde__c = kd.id,
                                                                Artikel__c = Art.id,
                                                                VZ_von__c = date.Today().addDays(30),
                                                                VZ_Bis__c = date.Today().addDays(60),
                                                                AZ_von__c = date.Today().addDays(30),
                                                                AZ_Bis__c = date.Today().addDays(60),
                                                                Lieferdatum__c = date.Today().addDays(30),
                                                                Menge__c = 20,
                                                                Status__c = 'jetzt liefern');
        Lieferscheinposition__c sto = new Lieferscheinposition__c(Auftragsposition__c = Apos.id,
                                                                Kunde__c = kd.id,
                                                                Artikel__c = Art.id,
                                                                VZ_von__c = date.Today().addDays(30),
                                                                VZ_Bis__c = date.Today().addDays(60),
                                                                AZ_von__c = date.Today().addDays(30),
                                                                AZ_Bis__c = date.Today().addDays(60),
                                                                Lieferdatum__c = date.Today().addDays(30),
                                                                Menge__c = 20,
                                                                Status__c = 'storniert');
        Lieferscheinposition__c tei = new Lieferscheinposition__c(Auftragsposition__c = Apos.id,
                                                                Kunde__c = kd.id,
                                                                Artikel__c = Art.id,
                                                                VZ_von__c = date.Today(),
                                                                VZ_Bis__c = date.Today().addDays(30),
                                                                AZ_von__c = date.Today(),
                                                                AZ_Bis__c = date.Today().addDays(30),
                                                                Lieferdatum__c = date.Today(),
                                                                Menge__c = 30,
                                                                Status__c = 'teilgeliefert');
        insert alt;
        insert bed;
        insert gel;
        insert sto;
        insert tei;
        insert jet;
        Lieferschein__c ls1 = new Lieferschein__c(Kunde__c = kd.id);
        insert ls1;
        Lieferschein__c ls2 = new Lieferschein__c(Kunde__c = kd.id);
        insert ls2;     
        List<Lieferscheinposition__c> LPList = new List<Lieferscheinposition__c>();
        LPList.add(jet);
        List<Lieferscheinposition__c> LPList2 = new List<Lieferscheinposition__c>();
        LPList2.add(bed);
        List<Lieferschein__c> LSList = new List<Lieferschein__c>();
        LSList.add(ls1);
        List<Lieferschein__c> LSList2 = new List<Lieferschein__c>();
        LSList2.add(ls2);
        ls1.Unterschrift__c = true;
        update ls1;
        Lieferscheinclass.hole_gelieferte_Menge(Apos);
        Lieferscheinclass.Abrechnugszeiten_anpassen(APos.ID);
        Lieferscheinclass.getAdressen();
        Lieferscheinclass.getStandard_Anschrift();
       
        Lieferscheinclass.hole_gelieferte_Menge(Apos);
        
        Lieferscheinclass.StandardVPName = 'Spediteure';
        Lieferscheinclass.lieferschein_erzeugen(Kd.id, 'test');
        
        Lieferscheinclass.getAZVZ('von', 'bis');
        Lieferscheinclass.updateKrankenkassenabrechnung(LPList);
        Lieferscheinclass.updateabrechenbareLPs(LPList);
        // Lieferscheinclass.updateUnterschriftenLiPos(LSList, LSList2);
        try{
        KK.Name = 'Standard Versandpartner';
        update kk;
        Lieferscheinclass.StandardVPName = null;
        Lieferscheinclass.getStandard_Versender();
        }catch(Exception e){}
        Lieferscheinclass.setLeereZeilen();
        
    }

    private static testMethod void  Lieferscheinupdateunterschrift_test(){
        Kunde__c kd = new Kunde__c (Anrede__c = 'Herr', Vorname__c = 'Test2', Name__c = 'Kunde2', 
                                    Kundennummer__c = 10, Produktgruppe__c = 'PG51');
        insert kd;

        Lieferschein__c ls1 = new Lieferschein__c(Kunde__c = kd.id);
        insert ls1;
        Lieferschein__c ls2 = new Lieferschein__c(Kunde__c = kd.id);
        ls2.Status_DHL__c = 'Zustellung an test';
        insert ls2;     
        List<Lieferschein__c> LSList = new List<Lieferschein__c>();
        LSList.add(ls1);
        List<Lieferschein__c> LSList2 = new List<Lieferschein__c>();
        LSList2.add(ls2);
        Lieferscheinupdateunterschrift.updateLS(LSList, LSList2);
    }         
    
    

}