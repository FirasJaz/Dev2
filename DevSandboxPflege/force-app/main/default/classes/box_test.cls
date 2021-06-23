@isTest
public class box_test {
    
    static testMethod void boxMethodTest(){
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c = 'test_group');
        insert k;
        Kundenstatus__c ks = new Kundenstatus__c();
        ks.Kunde__c = k.Id;
        insert ks;
        box_method bt = new box_method(k.Id);
        Anl4_Stueckliste__c anl = new Anl4_Stueckliste__c(Name = 'Name', Bezeichnung__c = 'test_box_name');
        insert anl;
        PflegeboxSettings__c s = new PflegeboxSettings__c(Name='test', MaxPreis__c = 1000, MinPreis__c = 0);
        insert s;
        
        VPflegeboxArtikelgruppe__c pbl = new VPflegeboxArtikelgruppe__c(Name = 'test_VPflegeboxArtikelgruppe__c');
        Pflegebox__c pb = new Pflegebox__c(Name = 'test_Pflegebox');
        insert pb;
        Artikelgruppe__c  ag= new Artikelgruppe__c(name = 'test_Artikelgruppe');
        insert ag;
        pbl.Artikelgruppe__c = ag.id;
        pbl.Pflegebox__c = pb.id;
        //pb.pospreis__c = 500;
        //pbl.bmenge = 'test';
        insert pbl;
        Auftrag__c af = new Auftrag__c(Auftrag_text__c = pb.id); 
        af.kunde__c = k.id;
        insert af;
        Genehmigung__c g  = new Genehmigung__c();
        g.Kunde__c = k.id;
        g.Status__c = 'Bewilligung';
        g.Antrag_beantwortet_am__c = Date.today();
        insert g;
    Genehmigungsposition__c gp = new Genehmigungsposition__c();
        gp.Artikelgruppe__c = ag.id;
        gp.Genehmigung__c = g.Id;
        gp.genehmigt_bis__c= Date.today();
        gp.genehmigt_ab__c = Date.today();
        gp.unbefristet_genehmigt__c=true;
        insert gp;
        
        Artikel__c a = new Artikel__c(Name = 'test_Artikel', Anlage_4_Preis__c=50);
        a.Artikelgruppe__c = ag.id;
        insert a; 
        Auftragsposition__c ap = new Auftragsposition__c();
        ap.Artikel__c = a.Id;
        ap.Auftrag__c = af.Id;
        insert ap;            
        bt = new box_method(k.Id);  
        gp.unbefristet_genehmigt__c=false;
        update gp;
        bt = new box_method(k.Id);
        bt.checkAuftrag();
        bt.getNaU();
        af.genehmigt_bis__c = Date.today()-100;
        af.genehmigt_ab__c = Date.today();
        bt.checkAuftrag();
        af.genehmigt_bis__c = Date.today()+100;
        af.genehmigt_ab__c = Date.today()-100;
        update af;
        bt.setNaU(af);
        bt.auftragEinmalig(true);
        bt.checkAuftrag();  
        bt.checkEditAuftrag(af);
        ag.keine_Genehmigungspflicht__c = true;
        update ag;
        bt = new box_method(); 
        af = bt.makeAuftrag();
        list<Auftragsposition__c> APlist = bt.makeAP();
        bt.checkGenMenge();
        bt.auftragEditModeOn(af);
        bt.getGesamtPreis();
        bt.getGesamtPreisEdit();
        bt.makeMapAP(af);
        bt.getGesamtPreisFarbe();
        bt.getGesamtPreisFarbeEdit();
        bt.getGenID();
        bt.hasError();
        bt.getErrorMessage();
        bt.getEditierbar();
        bt.geteditierbar();
        try{bt.recreatePbAgGnList();}catch(Exception e ){}
        try{bt.recreatePbAgGnListEdit();}catch(Exception e){}
        try{bt.rechnenGesamtpreis();}catch(Exception e){}
        bt.getBoxSelect();
        bt.getFestBoxList();
        bt.getPbAgList();
        bt.getPbAgGnList();
        bt.getPbAgGnListEdit();
        bt.getSelectedBox();
        bt.getSelectedArtikel();
        bt.getSelectedBoxName();
        bt.getboxKeineGenehmigung();
        bt.getNur_einmalig_bestellbar();
        bt.getboxGenehmigtUnbefristet();
        bt.getboxGenehmigtAb();
        bt.getboxGenehmigtBis();
        bt.getRlieferung();
        bt.getMuTxt();
        bt.isKandidat();
        bt.isKandidat51();
        bt.auftragRlieferung(true);
        bt.setSelectedBoxName('test_box');
        bt.setSelectedBox(af.Id);
        bt.setSelectedArtikel(a.Id);
        bt.setSelectedGr(af.Id);       
 }

}