//     wds 16.01.2013 
@isTest
private class Preis_MWSt_Zuzahlung_test {

    static testMethod void myUnitTest() {
        KVA_Position__c KVV = new KVA_Position__c();
        KVA__c KVA = new KVA__c();
        Fallpauschale__c FP = New Fallpauschale__c();
        Kunde__c KD = new Kunde__c(Name__c = 'Testkunde', Produktgruppe__c='PG54');
        Account KK = new Account(Name = 'Test Hamburg');
        Auftragsposition__c AP = new Auftragsposition__c();
        Auftrag__c AU = new Auftrag__c();
        Artikelgruppe__c AGR = new Artikelgruppe__c();
        Fallpauschalenartikelgruppe__c FPAGR = new Fallpauschalenartikelgruppe__c();
        
        KK.Industry='Krankenkassen';
        insert KK;
        
        KD.Krankenkasse__c = KK.ID;
        KD.Zuzahlung_befreit_von__c = date.Today() - 10;
        KD.Zuzahlung_befreit_bis__c = date.Today() + 10; 
        insert KD;
        
        KVA.Kunde__c = KD.ID;
        insert KVA;
        
        KVV.KVA__c = KVA.ID;
        KVV.Kunde__c = KD.ID;
        insert KVV;
        
        Artikel__c Art = new Artikel__c(); 
        Art.v_art_Hilfsmittelkz__c='0';
        Art.a_pac_apo_PZN_Original__c=12345678;
        Art.Name='test-artikel';
        Art.EVK__c=10;
        Art.v_art_Hm_Positionsnr_1__c='12345';
        Art.a_pac_apo_Mwst__c='1';
        Art.Menge_Faktor_1__c=1;
        Art.Zuzfrei_31SGB__c=1;
        
        insert Art;
        decimal Anzahl_Verp = 2;
        
        art = [select Hilfsmittel_zum_verbrauch__C, EVK__c, Pos_Nr__c,
                                    name,
                                    a_pac_apo_mwst__C,
                                    menge_in_verpackung__c,
                                    zuzahlungsbefreiung_nach_31_SGB_V__c
                                 from Artikel__c
                                 where ID =: Art.ID];
                                
        try{
            Preis_MWSt_Zuzahlung_class.preis_ermitteln(KVV, Art, Anzahl_Verp, KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c,KD, 'FP');
            Preis_MWSt_Zuzahlung_class.preis_ermitteln(KVV, Art, Anzahl_Verp, KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c,KD, '');
        }catch(Exception e){}
        Art.EVK__c = 1;
        Art.v_art_Hm_Positionsnr_1__c = '1234567890'; 
        update Art;
        Preislisteneintrag__c PL = new Preislisteneintrag__c();
        PL.Artikel__c = Art.ID;
        PL.Krankenkasse__c = KK.ID; 
        PL.Preis_netto__c = 10.0;
        Artikelgruppe__c AG = new Artikelgruppe__c();
        Art = ([select  Name, 
                        a_pac_apo_Mwst__c, 
                        EVK__c, 
                        Hilfsmittel_zum_verbrauch__C,
                        Pos_Nr__c,
                        Zuzahlungsbefreiung_nach_31_SGB_V__c, 
                        v_art_Hm_Positionsnr_1__c
                From Artikel__c 
                Where ID =: Art.ID])[0];
        AG.Positionsnummer__c = Art.Pos_Nr__c;
        insert AG; 
        PL.Artikelgruppe__c = AG.ID;
        insert PL;
        Preis_MWSt_Zuzahlung_class.setLeereZeilen();
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermitteln(KVV, Art, Anzahl_Verp, KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, KD,'');
        } catch (exception e0) {}
        KD.Zuzahlung_befreit_von__c = date.Today() - 1;
        KD.Zuzahlung_befreit_bis__c = date.Today() - 1;
        KD.Zuzahlung_befreit__c=false;
        update KD;
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermitteln(KVV, Art, Anzahl_Verp, KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, KD,'');
        } catch (exception e0) {}
        Art.a_pac_apo_Mwst__c = '1';
        update Art;
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermitteln(KVV, Art, Anzahl_Verp, KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, KD,'');
        } catch (exception e0) {}
        Art.a_pac_apo_Mwst__c = '2';
        update Art;
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermitteln(KVV, Art, Anzahl_Verp, KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, KD,'');
        } catch (exception e0) {}
        Art.a_pac_apo_Mwst__c = '0';
        update Art;
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermitteln(KVV, Art, Anzahl_Verp, KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, KD,'');
        Preis_MWSt_Zuzahlung_class.getPLEs();
        } catch (exception e0) {}
        
        FP.Krankenkasse__c=KK.id;
        FP.Art_der_fallpauschale__c='Inko abl.';
        FP.Zuzahlungsfreier_H_chstpreis__c=1;
        FP.Pauschalpreis__c=35;
        insert FP;
        
        AGR.Name = 'Test-Artikelgruppe';
       
        insert AGR;
        
        Art.artikelgruppe__c = AGR.id;
        update art;
        
        FPAgr.Artikelgruppe__c=AGR.Id;
        FPAgr.Fallpauschale__c=FP.Id;
        FPAgr.Zuzahlungsfreier_H_chstpreis__c=2;
        FpAgr.Menge_Stk_Tag__c=10;
        insert FPAgr;

        AU.Kunde__c=KD.Id;
        AU.Fallpauschale__c=FP.Id;
        
        insert AU;
        
        AP.Auftrag__c=AU.ID;
        AP.Gen_Menge_ges__c=10;
        AP.Artikel__c=art.id;
        AP.Kunde__c=KD.Id;
        insert AP;
        
        art.Standardartikel_Anlage_4__c=True;
        art.Anlage_4_Preis__c=25;
         art = [select Hilfsmittel_zum_verbrauch__C, EVK__c, Pos_Nr__c,
                                    name,
                                    a_pac_apo_mwst__C,
                                    menge_in_verpackung__c,
                                    zuzahlungsbefreiung_nach_31_SGB_V__c,
                                    Artikelgruppe__c,
                                    Standardartikel_fuer_Fallpauschalen__c,
                                    Standardartikel_Anlage_4__c,
                                    Anlage_4_Preis__c
                                 from Artikel__c
                                 where ID =: Art.ID];
                                 
    
        
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermittelnFP(FP.id,KVV, Art, Anzahl_Verp, date.Today(), date.Today() + 360, KD,AP);
        } catch (exception e0) {}
        
        AU.FP_abgerechnet_bis__c=date.today();
        AU.FP_gesetzl_Zuz_abgerechnet_bis__c=date.today();
        update AU;
        
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermittelnFP(FP.id,KVV, Art, Anzahl_Verp, date.Today(), date.Today() + 360, KD,AP);
        } catch (exception e0) {}
        
        
        art.Standardartikel_Anlage_4__c=False;
        try{
        Preis_MWSt_Zuzahlung_class.preis_ermitteln_a4(KVV, Art, Anzahl_Verp, date.Today(), date.Today() + 360, KD,'Anl4');
        
        Preis_MWSt_Zuzahlung_class.wirtschaft_zuzahlungFP_ermitteln(True, 100, 90);
        Preis_MWSt_Zuzahlung_class.wirtschaft_zuzahlungFP_ermitteln(True, 100, 110);
        Preis_MWSt_Zuzahlung_class.wirtschaft_zuzahlungFP_ermitteln(False, 100, 90);
        } catch (exception e0) {}
        
        
    }
}