@isTest
public with sharing class Data_For_Tests_Class {
    
    public static Rechnung__c createRechnung(){
        Rechnung__c R = new Rechnung__c();
        R.Kunde__c = Data_For_Tests_Class.createKunde(1).Id;
        insert R;
        return R;
    }
    public static Rechnungsposition__c createRP(Rechnung__c R, String MwSt){
        Rechnungsposition__c Rp = new Rechnungsposition__c();
        Rp.Gesamtpreis_Brutto__c = 20;
        if(R == null){
            R = Data_For_Tests_Class.createRechnung();
        }
        Rp.Rechnung__c = R.Id;
        Rp.Kunde__c = R.Kunde__c;
        if(MwSt != null){
            Rp.MWSt_Prozentsatz__c = MwSt;
        }
        insert Rp;
        return Rp;
    }
    
    public static Lager__c createLager(Integer i){
        Lager__c l = new Lager__c();
        l.Name = 'TestLager'+i;
        Standort__c s = new Standort__c();
        Mandant__c m = new Mandant__c();
        insert m;
        s.Mandant__c = m.Id;
        insert s;
        l.Standort__c = s.Id;
        l.Lagerplatz__c = 'TestLp'+i;
        insert l;
        return l;
    }
    
    public static Lagerartikel__c createLagerartikel(Integer i){
        Lagerartikel__c la = new Lagerartikel__c();
        la.Lager__c = Data_For_Tests_Class.createLager(i).Id;
        la.Artikel__c = Data_For_Tests_Class.createArtikel(i).Id;
        la.Bestand__c = i;
        insert la;
        return la;
    }
    
    public static Artikelgruppe__c[] createArtGrList(Integer i){
        List<Artikelgruppe__c> ArtGrList = new List<Artikelgruppe__c>{};
        for(Integer x = 1; x <= i; x++){
            ArtGrList.add(Data_For_Tests_Class.createArtGr(x));
        }
        return ArtGrList;
    }
    public static Artikelgruppe__c createArtGr(Integer i){
        Artikelgruppe__c ArtGr = new Artikelgruppe__c();
        ArtGr.Positionsnummer__c = string.valueof(i);
        Data_For_Tests_Class.createArtikel(i);
        insert ArtGr;
        system.debug('######## ArtGr'+ ArtGr);
        return ArtGr;
    }
    
    public static Artikel__c createArtikel(Integer i){
        Artikel__c a = new Artikel__c();
        a.v_art_Hm_Positionsnr_1__c = string.valueof(i);
        insert a;
        system.debug('######## A '+ a);
        return a;
    }
    
    public static Kunde__c createKunde(Integer i){
        AggregateResult AR = [select max(kundennummer__c)mkd from kunde__c];
        decimal newkd = integer.valueOf(AR.get('mkd'));
        if (newkd == null){newkd=0;}
        newkd += i;
        Kunde__c k = new Kunde__c(Name__c = 'Testkunde' + i, Kundennummer__c = newkd);
        insert k;
        return k;
    }
    
    public static List<Auftragsposition__c> createApoList(Integer i){
        List<Auftragsposition__c> apoList = new List<Auftragsposition__c>{};
        Integer x;
        for(x = 1;x <= i; x++){
            apoList.add(Data_For_Tests_Class.createApo(x));
        }
        system.debug('#########'+apoList);
        return apoList;
    }
    public static Auftragsposition__c createApo(Integer i){
        Auftragsposition__c apo = new Auftragsposition__c();
        apo.Genehmigungsstatus__c = null;
        if(math.mod(i,2) == 0){
            apo.Genehmigungsstatus__c = 'genehmigt';
        }
        if(math.mod(i,3) == 0){
            apo.Genehmigungsstatus__c = 'abgelaufen';
        }
        if(math.mod(i,4) == 0){
            apo.Genehmigungsstatus__c = 'abgelehnt';
        }
        apo.Auftrag__c = Data_For_Tests_Class.createAuftrag(i).Id;
        apo.Kunde__c = Data_For_Tests_Class.createKunde(i).Id;
        insert apo;
        return apo;
    }
    
    public static Auftrag__c createAuftrag(Integer i){
        Auftrag__c A = new Auftrag__c();
        A.Kunde__c = Data_For_Tests_Class.createKunde(1).Id;
        if(i == 2){
            A.Genehmigungsstatus__c = 'Vorablieferung ohne KVA';
        }
        insert A;
        return A;
    }
    
    public static void createMWstSetting(String n, String kennzeichen, integer p, decimal dezimal){
        Map<String, MWstListe__c> MwStSaetze = MWstListe__c.getall();
        MWstListe__c mwst = new MWstListe__c(setupownerid = null);
        mwst.Name = n;
        mwst.MWStKennzeichen__c = kennzeichen;
        mwst.MWSt_Prozentsatz__c = p;
        mwst.MWStDezimalzahl__c = dezimal;
        if(MwStSaetze.get(n) == null){
            insert mwst;
        }
    }
    public static void createFiBu_einstellungen(String n, String Kname, Decimal Knummer, Boolean Ak){
        Map<String, FiBu_Einstellungen__c> FiBuKonten = FiBu_einstellungen__c.getall();
        FiBu_einstellungen__c f = new FiBu_einstellungen__c();
        f.Automatikkonto__c = Ak;
        f.Name = n;
        f.Kontoname__c = Kname;
        f.Kontonummer__c = Knummer;
        if(FiBuKonten.get(n) == null){
            insert f;
        }
    }
    public static void createCustomSettings(){
        Data_For_Tests_Class.createMWstSetting('ABDA MWSt 0', '0', 0, 0);
        Data_For_Tests_Class.createMWstSetting('ABDA MWSt 1', '1', 19, 0.19);
        Data_For_Tests_Class.createMWstSetting('ABDA MWSt 2', '2', 7, 0.07);
        Data_For_Tests_Class.createMWstSetting('ABDA MWSt 3', '3', 0, 0);
    }
}