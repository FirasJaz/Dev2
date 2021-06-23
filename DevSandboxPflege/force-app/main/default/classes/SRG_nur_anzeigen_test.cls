@isTest
public class SRG_nur_anzeigen_test {
    public static testMethod void myUnitTest(){
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'PG54');
        k.Name = 'Testkunde';
        insert k;
        Rechnung__c r = new Rechnung__c();
        r.Kunde__c = k.id;
        insert r;
        Rechnungsposition__c rp = new Rechnungsposition__c();
        rp.Rechnung__c = r.Id;
        rp.Kunde__c = k.id;
        insert rp;
        Rechnungsposition__c rpv = new Rechnungsposition__c();
        rpv.Rechnung__c = r.Id;
        rpv.Kunde__c = k.id;
        rpv.Versandkosten__c = true;
        insert rpv;


        SRG_nur_anzeigen sa = new SRG_nur_anzeigen(r.Id);
        sa.getMagento_increment_id();
        sa.getMagento_payment_method();
        sa.getRG_Positionen();
        sa.getZeilen();
        sa.getRG();
        sa.getAnschrift();
        sa.getRetPage();
        sa.getKunde();
        sa.getNachname();
        sa.getVorname();
        PageReference tpageRef = Page.SRG_nur_anzeigen;
        Test.setCurrentPage(tpageRef);
        ApexPages.currentPage().getParameters().put('id', r.Id);
    }
}