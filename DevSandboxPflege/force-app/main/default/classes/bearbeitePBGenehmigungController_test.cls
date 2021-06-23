@isTest
public class bearbeitePBGenehmigungController_test {

    static testMethod void myUnitTest() {
    
    
        Account KK = new Account();
        KK.Industry = 'Krankenkassen';
        KK.Name = 'Krankenkasse';
        KK.type = 'TestKrK';
        insert KK;
        
        Kunde__c kd = new Kunde__c (Krankenkasse__c = kk.id, Name__c = 'Muster', Produktgruppe__c='PG54');
        kd.Versichertennummer__c = '1234567';
        insert kd;
         Artikelgruppe__c ag1 = new Artikelgruppe__c(Name = 'Einmalhandschuhe');
        insert ag1;
        Artikelgruppe__c ag2 = new Artikelgruppe__c(Name = 'Flächendesinfektion');
        insert ag2;
        Artikelgruppe__c ag3 = new Artikelgruppe__c(Name = 'Händedesinfektion');
        insert ag3;
        Artikelgruppe__c ag4 = new Artikelgruppe__c(Name = 'Schutzschürze');
        insert ag4;     
        Artikelgruppe__c ag5 = new Artikelgruppe__c(Name = 'Mundschutz');
        insert ag5;     
        Artikelgruppe__c ag6 = new Artikelgruppe__c(Name = 'Bettschutzeinlagen');
        insert ag6;     
        Artikelgruppe__c ag7 = new Artikelgruppe__c(Name = 'Bettschutzeinlagen (Wiederverwendung)');
        insert ag7;        
        Genehmigung__c ge = new Genehmigung__c(Kunde__c = kd.id);
        insert ge;
        

        
        PageReference pRef1 = Page.bearbeitePBGenehmigung;
        Test.setCurrentPage(pRef1);
        ApexPages.currentPage().getParameters().put('ID', ge.id);
        ApexPages.currentPage().getParameters().put('retURL', 'test');
        string retPage = ApexPages.currentPage().getParameters().get('retURL');
        
        ApexPages.StandardController con1 = new ApexPages.StandardController(ge);
        bearbeitePBGenehmigungController ext1 = new bearbeitePBGenehmigungController(con1); 
        
        ext1.Genehmigung = ge;
        //ext1.neuenGenehmigungSichern (ge);
        
        ext1.neueGenehmigungSichern();
        ext1.getRetPage();
        ext1.neueGenehmigungZurueck();
        ext1.setLeereZeilen();
        
    }
}