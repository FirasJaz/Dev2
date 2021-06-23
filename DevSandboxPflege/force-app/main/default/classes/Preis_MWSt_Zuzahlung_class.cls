/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  ge�ndert am 31.5.2011 am 10.06.2011 deployed!
//  wenn keine PosNr vorhanden muss er auch in der Artikelgruppe nach diesem Artikel suchen!!!! 
//  ge�ndert am 5.9.2011 am 7.9.2011 deployed !
//              -   F�r jeden angefangenen Monat wird die maximal gesetzliche Zuzahlung verlangt!
//  ge�ndert am 17.10.2011  am 22.1.2011 deployed
//              -   Preislisteneintr�ge der �bergeordneten Krankenkassen sollen ber�cksichtigt werden
//  ge�ndert am 14.11.2011  am 14.11.2011 deployed
//              -   Wenn kjein Preislisteneintrag vorhanden war, wurde der Fehler nicht sauber abgefangen
//              -   die neuen Felder abrechenbar, wirtschaftl_Zuzahlung und Preis/St�ck werden jetzt mit ausgelesen und ber�cksichtigt
//  ge�ndert am 3.1.2012 am 26.2.2012 deployed
//              -   Aenderung Fallpauschalen
//  ge�ndert am 12.4.2012 am 10.5.2012 deployed !!!!
//              -   nochmal Aenderung Fallpauschalen
//  ge�ndert am 18.5.2012 am 18.5.2012 deployed !!!!
//              - �nderung Fallpauschalen (Zuviel geliefert gibt's nicht mehr
//  ge�ndert am 26.6.2012 am 26.6.2012 deployed !!!!
//              - es konnte vorkommen, dass error = Null zur�ckgegeben wurde!
//  ge�ndert am 2.7.2012 am 26.07.2012 deployed !!!!
//              - Weiterentwicklung Anlage 4
//  ge�ndert am 6.8.2012 am ???? deploxed
//              - gesetzl Zuzahlung bei Fallpauschalen
//  ge�ndert am 28.08.2012 am ??? deployed
//              - System Null Pointer exception behoben bei betrag_zu_teuer in FP
//  geaendert am 12.09.2012 am 20.9.2012 deployed
//              - Aenderung fuer gesetzl Zuzahlung bei Fallpauschalen
//  geaendert am 26.9.2012 am 26.9.2012 deployed
//              - gesetzl Zuzahlung fue normale Genehmigungen war jetzt zuviel!
//  geaendert am 1.10.2012 am 6.10.2012 deployed
//              - gesetzl Zuzahlung fuer Fallpauschalen sollen nur noch f�r 1 Monat in den KVA!
//  geaendert am 5.10.2012 am 6.10.2012 deployed
//              - gesetzl Zuzahlung f�r Hilfsmittel zum Verbauch angepasst
//  geaendert am 8.10.2012 am 8.10.2012 deployed
//              - die gesetzl Zuzahlung ist auch bei mehreren Monaten auf den Zuzahlungsprozenth�chstsatz gedeckelt
//  geaendert am 16.01.2013 deployed 
//              - alle system.debugs entfernt (wds)
//  geaendert am 25.01.2013 deployed
//              - Deckelung bei FP auf max 10 EUR p.M. (wds)
//  geaendert am 29.1.2013 noch nicht deployed
//              - PLE Eintraege fuer implizite Artikelgruppen wurden nicht aus DB gelesen
//  geaendert am 11.03.2013 nur in der 46! 
//              - Korrektur Berechnung gesetzl. Zuzahlung!
//  geaendert am 12.03.2013 nur in der 46!
//              - Preisberechnung auf St�ck angepa�t --- TEST!
//  geaendert am 15.12.2013 ACR 198 Befreiung FP von Zuzahlung
//  geaendert am 21.12.2013 ACR 198 Nachbearbeitung
//              - gestzl_zuzahlung_preis_ermitteln_neu
//  geaendert am 21.12.2013 ACR 198 AM
//              - wir errechnen das tats�chliche Datum "ges. zuz von" nur in der "gesetzl_zuzahlung_ermitteln_neu".
//              Dieses Datum brauchen wir aber f�r den Rechnungspositiontext. Deshalb erstellen wir hier ein Feld
//              gzAbgerechnetVon (date) mit getter und setter um dieses aus der anderen Klassen zu lesen. 
// wds      am 27.01.2014   >= und <= in < und > ge�ndert bei Zeile 196 ohne ACR     
//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    public class Preis_MWSt_Zuzahlung_class { 
     
    private static Map<ID,List<Preislisteneintrag__c>> PLEs = new Map<ID,List<Preislisteneintrag__c>>{};    
    private static map<ID,Artikelgruppe__c> ArtGrp = new Map<ID,Artikelgruppe__c>{};
    private static Map<String, MWstListe__c> mwst = MWstListe__c.getall();
    private static decimal MWST1_proz = mwst.get('ABDA MWSt 1').MWstDezimalzahl__c;
    private static decimal MWST2_proz = mwst.get('ABDA MWSt 2').MWstDezimalzahl__c;
    private static Set<ID> ArtGrpSet = new Set<ID>{};
    private static KVA_position__c KVPSchmu;
    private static decimal fpMonate = 0.0;
    // 21.12.2013 am
    private static date gzAbgerechnetVon = null;
 
 // wird nicht aufgerufen! Nur f�r Testabdeckung!!!  
        public class Zeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
                        public String LsNr {get;set;}
                        public String Positionsnummer_PZN {get;set;}
                        public String Artikel {get;set;}
                        public String Menge {get;set;}
                        public String Me2 {get;set;}
                        public string ME {get;set;}
                        public string Brutto {get;set;}
                        public string seitenw {get;set;}
                        public string th {get; set;}
                        public string thu {get; set;}
                        public string trs {get; set;}
                        public string lDatum {get; set;}
                        public string stern {get; set;}
        }    
    
    private static boolean updateAU = true;
    private static boolean fpAZ = false;    

    public static Map<ID,List<Preislisteneintrag__c>> getPLEs(){
        return PLEs.clone(); 
    }
    public static Map<ID,Artikelgruppe__c> getArtGrp(){
        return ArtGrp.clone();
    }

    public static decimal gesetzl_zuzahlung_ermitteln(Date zuzbefvon, Date zuzbefbis, Boolean zuzbefP31, Date von, Date bis, 
                                Boolean unbefr, decimal Preis, Boolean FP, String HiMizVerb){
        decimal gesetzl_Zuzahlung;
        integer Monate = 0;
        date vergleich = von;
//      Zuzahlung auslesen
        Decimal max = Parameterlesenclass.read_decimal_param('Zuzahlung Maximum');
        Decimal min = Parameterlesenclass.read_decimal_param('Zuzahlung Minimum');
        Decimal Zu_proz = Parameterlesenclass.read_decimal_param('Zuzahlung %');
//      wenn es unbefritstet ist, machen wir die Zuzahlung erstmal f�r ein Jahr
//      if (unbefr){
//          bis = von.addYears(1).addDays(-1);
//      }
        Boolean HzV = False;
        if (HiMizVerb != null && HiMizVerb == 'ja'){
            HzV = True;
        } 
        do {
            //Aenderung am 21.12.2013 jetzt werden nur die Monate gez�hlt in denen nicht zuzahlung befreit ist. 
            if ( zuzbefvon == null ){
                monate++;
            }
            else {
                if ( ( zuzbefvon >= vergleich ) || ( vergleich >= zuzbefbis ) ){
                    monate++;
                }
            }
            vergleich = vergleich.addMonths(1);
        }
        While ( vergleich <= bis );
        system.debug('###############Preis MWST Zuz gesetzl Zuz zuzbefvon ' + zuzbefvon);
        system.debug('###############Preis MWST Zuz gesetzl Zuz zuzbefbis ' + zuzbefbis);
        system.debug('###############Preis MWST Zuz gesetzl Zuz monate ' + monate);
        //Aenderung am 21.12.2013 BIsher wurde nur gegen dateToday verglichen und dann gesagt gesetzl Zuz ja/nein
        // jetzt werden nur die Monate gez�hlt in denen nicht zuzahlung befreit ist. s.o.
         If (zuzbefP31){
            gesetzl_Zuzahlung = 0 ;
        }
        else{
        system.debug('############### Preis =  ' + Preis);
        system.debug('############### gesetzliche Zuz =  ' + gesetzl_Zuzahlung);
        system.debug('############### min =  ' + min);
        
            If (!HzV && ( Preis * Zu_proz < min)){
                gesetzl_Zuzahlung = min;
            }
            else{
                gesetzl_Zuzahlung = Preis * Zu_proz; 
            } 
            system.debug('############### 2 max = ' + max);
            system.debug('############### Preis =  ' + Preis);
            system.debug('############### gesetzliche Zuz =  ' + gesetzl_Zuzahlung);
            system.debug('############### min =  ' + min);
             
            If ( gesetzl_Zuzahlung > max * Monate){ 
                gesetzl_Zuzahlung = max * Monate; 
            }
            If (gesetzl_Zuzahlung > preis){
                gesetzl_Zuzahlung = Preis;
            }
            If (FP && (gesetzl_Zuzahlung < max)){
                gesetzl_Zuzahlung = Preis * Zu_proz * Monate;
            }
            else{
            system.debug('############### 3 max = ' + max);
            system.debug('############### Preis =  ' + Preis);
            system.debug('############### gesetzliche Zuz =  ' + gesetzl_Zuzahlung);
            system.debug('############### min =  ' + min);
                
            }
//           gesetzl_Zuzahlung = gesetzl_Zuzahlung * Monate;
//          wenn es keine Fallpauschale ist, wird der Zuzahlungsbetrag gedeckelt auf den Prozenth�chstsatz 
//           If (!FP && (gesetzl_Zuzahlung > preis * Zu_proz)){
//                gesetzl_Zuzahlung = Preis * Zu_proz;
//            }
        }
        return gesetzl_Zuzahlung;
    
    }
//
//     Diese habe ich erstellt um die Befreiung der Zuzahlung darzustellen. Es ist eine �bergangsl�sung!!!
//
    public static decimal gesetzl_zuzahlung_ermitteln_neu(Date zuzbefvon, Date zuzbefbis, Boolean zuzbefP31, Date von, Date bis, 
                                Boolean unbefr, decimal Preis, Boolean FP, String HiMizVerb, boolean FP_zuz){
        //  <-- 21.12.13
        gzAbgerechnetVon = von;
        system.debug('######### FP: '+ FP + ', FP_zuz: '+FP_zuz);
        system.debug('######### FP_date zuzbefvon: '+ zuzbefvon + ', zuzbefbis: '+zuzbefbis + ', von: '+von + ', bis: '+bis);
        // FP_zuz soll den Wert Fallpauschalen__c.Fallpauschale_Logik__c enhalten
        // ist FP_zuz true, soll keine Zuzahlung berechnet werden
        if(FP == true && FP_zuz == true){
            return 0;
        }
        // 21.12.13 //-->
        decimal gesetzl_Zuzahlung;
        integer Monate = 0;
        date vergleich = von;
//      Zuzahlung auslesen
        Decimal max = Parameterlesenclass.read_decimal_param('Zuzahlung Maximum');
        Decimal min = Parameterlesenclass.read_decimal_param('Zuzahlung Minimum');
        Decimal Zu_proz = Parameterlesenclass.read_decimal_param('Zuzahlung %');
//      wenn es unbefritstet ist, machen wir die Zuzahlung erstmal f�r ein Jahr
//      if (unbefr){
//          bis = von.addYears(1).addDays(-1);
//      }
        Boolean HzV = False;
        if (HiMizVerb != null && HiMizVerb == 'ja'){
            HzV = True;
        }
        do {
            //Aenderung am 21.12.2013 jetzt werden nur die Monate gez�hlt in denen nicht zuzahlung befreit ist. 
            if ( zuzbefvon == null ){
                monate++;
            }
            else {
                if ( ( zuzbefvon > vergleich ) || ( vergleich > zuzbefbis ) ){
                    monate++;
                }
            }
            vergleich = vergleich.addMonths(1);
        }
        While ( vergleich <= bis );
        gzAbgerechnetVon = vergleich.addMonths(-monate);
        system.debug('###############Preis MWST Zuz gesetzl Zuz zuzbefvon ' + zuzbefvon);
        system.debug('###############Preis MWST Zuz gesetzl Zuz zuzbefbis ' + zuzbefbis);
        system.debug('###############Preis MWST Zuz gesetzl Zuz monate ' + monate);
        system.debug('###############Preis MWST Zuz gesetzl gzAbgerechnetVon ' + gzAbgerechnetVon);
        //Aenderung am 21.12.2013 BIsher wurde nur gegen dateToday verglichen und dann gesagt gesetzl Zuz ja/nein
        // jetzt werden nur die Monate gez�hlt in denen nicht zuzahlung befreit ist. s.o.
        If ( zuzbefP31){
            gesetzl_Zuzahlung = 0 ;
        }
        else{
        system.debug('############### Preis =  ' + Preis);
        system.debug('############### gesetzliche Zuz =  ' + gesetzl_Zuzahlung);
        system.debug('############### min =  ' + min);
            if (Preis == null) Preis = 0.0;
            If (!HzV && ( Preis * Zu_proz < min)){
                gesetzl_Zuzahlung = min;
            }
            else{
                gesetzl_Zuzahlung = Preis * Zu_proz; 
            } 
            system.debug('############### 2 max = ' + max);
            system.debug('############### Preis =  ' + Preis);
            system.debug('############### gesetzliche Zuz =  ' + gesetzl_Zuzahlung);
            system.debug('############### min =  ' + min);
             
            If ( gesetzl_Zuzahlung > max * Monate){ 
                gesetzl_Zuzahlung = max * Monate; 
            }
            If (gesetzl_Zuzahlung > preis){
                gesetzl_Zuzahlung = Preis;
            }
            If (FP && (gesetzl_Zuzahlung < max)){
                gesetzl_Zuzahlung = Preis * Zu_proz * Monate;
                system.debug('############### Alex_Preis_MWST_0. Preis = ' + Preis + ' Zu_proz: ' + Zu_proz + ' Monate: ' + Monate);
            }
            else{
            system.debug('############### 3 max = ' + max);
            system.debug('############### Preis =  ' + Preis);
            system.debug('############### gesetzliche Zuz =  ' + gesetzl_Zuzahlung);
            system.debug('############### min =  ' + min);
                If (FP && FP_zuz != true){
                    gesetzl_Zuzahlung = max*Monate;}
                    system.debug('############### Alex_Preis_MWST_1. max = ' + max  + ' Monate: ' + Monate);
                }
//           gesetzl_Zuzahlung = gesetzl_Zuzahlung * Monate;
//          wenn es keine Fallpauschale ist, wird der Zuzahlungsbetrag gedeckelt auf den Prozenth�chstsatz 
//           If (!FP && (gesetzl_Zuzahlung > preis * Zu_proz)){
//                gesetzl_Zuzahlung = Preis * Zu_proz;
//            }
            system.debug('############### Alex_Preis_MWST_2. Monate: ' + Monate);
        }
        fpMonate = decimal.valueOf(Monate);
        system.debug('############### Alex_Preis_MWST_3. fpMonate: ' + fpMonate);
        return gesetzl_Zuzahlung;
    
    }
    
    public static decimal wirtschaft_zuzahlung_ermitteln(Boolean zuz, decimal VK, decimal KK){
        decimal wzuz;   
        if (zuz != NULL && zuz){
            wzuz = VK - KK ;
            If (wzuz < 0) { wzuz = 0; }
        }
        else{
            wzuz = 0;
        }
        return wzuz;
    }
    
    public static decimal wirtschaft_zuzahlungFP_ermitteln(Boolean zuz, decimal VK, decimal KK){
        decimal wzuz;   
        if (zuz != NULL && zuz){
            wzuz = VK - KK ;
            If (wzuz < 0) { wzuz = 0; }
        }
        else{
            wzuz = 0;
        }
        return wzuz;
    }
    
    public static Boolean MWSt_ermitteln(KVA_Position__c KVP, string MWKz, decimal Preis){
        Boolean error = False;
        decimal MWSt_proz = mwst.get('ABDA MWSt ' + MWKz).MWStDezimalzahl__c;
        string  MWSt_txt  = String.valueOf(mwst.get('ABDA MWSt ' + MWKz).MWSt_Prozentsatz__c);                  
        
        if ( MWKz == '1' ){
            KVP.MWSt_1__c = Preis/(1 + MWSt_proz)* MWSt_proz;
            KVP.MWSt_2__c = 0;
            KVP.MWSt_Betrag__c = KVP.MWSt_1__c;
            KVP.MWSt_Satz__c = MWSt_txt;
        }else if (MWKz == '2'){
            KVP.MWSt_1__c = 0;
            KVP.MWSt_2__c = Preis/(1 + MWSt_proz) * MWSt_proz;
            KVP.MWSt_Betrag__c = KVP.MWSt_2__c;
            KVP.MWSt_Satz__c = MWSt_txt;
        }else{
            KVP.MWSt_1__c = 0;
            KVP.MWSt_2__c = 0;
            KVP.MWSt_Betrag__c = 0;
            KVP.MWSt_Satz__c = MWSt_txt;
        }
        KVPSchmu = KVP;
        return error;
    }

private static Preislisteneintrag__c PLE_map_bearbeiten(map<ID,List<Preislisteneintrag__c>> PLE_map, 
                                                    List<Preislisteneintrag__c> PLE, ID KK, ID MasterKK){

    List<Preislisteneintrag__c> PLE_List;
    Preislisteneintrag__c MasterPL;
    Preislisteneintrag__c ChildPL;
        
    For (Preislisteneintrag__c P : PLE){
        if (P.Krankenkasse__c == KK){
            childPL = P;
        }
        if (P.Krankenkasse__c == MasterKK){
            MasterPL = P;
        }
    }
    If (childPL == null) {
        childPl = MasterPL;
    }
    If (PLE_map.containsKey(KK)){
        PLE_List = PLE_map.get(KK);
    }
    Else{
        PLE_list = new List<Preislisteneintrag__c>{};
    }

    PLE_List.add(childPL) ;
    PLE_map.put(KK,PLE_List);
    return childPL;
}

public static Boolean preis_ermitteln ( KVA_Position__c KVV, Artikel__c Art, 
                                        decimal Anzahl_Verp, date von, date bis, Kunde__c KD, String Posart){
    decimal VK_Preis = 0;
    decimal KK_Preis = 0;
    decimal gesetzl_Zuzahlung = 0;
    decimal wirtschaftl_Zuzahlung = 0;
    decimal MWSt_1 = 0;
    decimal MWSt_2 = 0;  
    decimal MWSt_Betrag = 0;
    String MWSt_txt = '';
    Preislisteneintrag__c PLE ;
    List<Preislisteneintrag__c> PLE_list;
    decimal pl_preis = 0; 
    decimal diff = 0;
    Boolean error = False;
    Boolean kein_evk = False; 
    Boolean kein_plpreis = False;
    Boolean PLE_lesen = True;
    Boolean Posvorh = False;
    string pos_7 ;
    decimal preis_brutto = 0;

 
//  Preis ermitteln

//  erstmal auf EVK pr�fen, das ist auf jeden Fall der Verkaufspreis
    If (Art == null){
    }
    else if (Art.EVK__c == null){
    }
    else if ( Art.EVK__c != 0){ 
        VK_Preis = art.EVK__c * Anzahl_Verp; 
    }else{
        kein_evk = True;
    } 

    
//  nun die schon gespeicherte Preisliste pr�fen
    If (Art != null){
        If ( Art.Pos_nr__c != null ){   
            Pos_7 = Art.Pos_Nr__c.substring(0,7);
            Posvorh = True;
        }
        else {
            Pos_7 = '';
        }

        if(PLEs.containsKey(KD.Krankenkasse__c)){
            PLE_List = PLEs.get(KD.Krankenkasse__c);
            For (Preislisteneintrag__c PL : PLE_List){
                If (PL.Artikel__c == Art.ID){
                    PLE = PL;
                    PLE_lesen = False;
                }
                Else {
                    If ( posvorh && Art.Pos_nr__c == PL.Artikelgruppe__r.Positionsnummer__c){
                        PLE = PL;
                        PLE_lesen = False;
                    }
                    Else {
                        If ( posvorh && Pos_7 == PL.Artikelgruppe__r.Positionsnummer__c){
                            PLE = PL;
                            PLE_lesen = False;
                        }
                    }
                }
            }
        }
    }
    
//  da nicht gefunden? dann in der DB die Preisliste pr�fen

        If (PLE_lesen) {
            kein_plpreis = True;
            PLE = new Preislisteneintrag__c();
            try{
                system.debug('################################# Preis Mwst Zuzahlung suche PLE fuer Artikel ' + Art.id + 
                        ' Account ' + Kd.Krankenkasse__c + ' uebergeordneter Account ' + KD.Krankenkasse__r.ParentID );           
                PLE_List = [select Krankenkasse__c, Artikel__c, Artikelgruppe__c, Artikelgruppe__r.Positionsnummer__c, preis_brutto__c, 
                    X300_302__c, Preis_St_ck__c, abrechenbar__c, wirtschaftl_Zuzahlung__c, preis_netto__c, Auslauf_datum__c
                    from Preislisteneintrag__c 
                    where artikel__c = :Art.Id 
                    and (Krankenkasse__c = :KD.Krankenkasse__c or Krankenkasse__c =: KD.Krankenkasse__r.ParentID)
                    and (Auslauf_datum__c = null or Auslauf_datum__c > :date.today())];

                if(PLE_List != null && PLE_list.size() != 0){
                    kein_plpreis = False;
                    PLE = PLE_map_bearbeiten(PLEs, PLE_List, Kd.Krankenkasse__c, KD.Krankenkasse__r.ParentID);
                }
                else{
                    If ( Art.Pos_Nr__c != null ){
                system.debug('################################# Preis Mwst Zuzahlung suche PLE fuer Pos10 ' + Art.Pos_Nr__c + 
                        ' Account ' + Kd.Krankenkasse__c + ' uebergeordneter Account ' + KD.Krankenkasse__r.ParentID );           
                        PLE_List = [select Krankenkasse__c, Artikel__c, Artikelgruppe__c, Artikelgruppe__r.Positionsnummer__c, 
                                    preis_brutto__c, X300_302__c, Preis_St_ck__c, abrechenbar__c, wirtschaftl_Zuzahlung__c, preis_netto__c 
                                    from Preislisteneintrag__c 
                                      Where Artikelgruppe__r.Positionsnummer__c = :Art.Pos_Nr__c 
                                      And (Krankenkasse__c = :KD.Krankenkasse__c or Krankenkasse__c =: KD.Krankenkasse__r.ParentID)
                                      and (Auslauf_datum__c = null or Auslauf_datum__c > :date.today())];
                        if(PLE_List != null && PLE_list.size() != 0){
                            kein_plpreis = False;
                            PLE = PLE_map_bearbeiten(PLEs, PLE_List, Kd.Krankenkasse__c, KD.Krankenkasse__r.ParentID);
                            ArtGrp.put(PLE.Artikelgruppe__c,PLE.Artikelgruppe__r);
                        }
                        else {
                system.debug('################################# Preis Mwst Zuzahlung suche PLE fuer Pos 7 ' + Pos_7 + 
                        ' Account ' + Kd.Krankenkasse__c + ' uebergeordneter Account ' + KD.Krankenkasse__r.ParentID );           
                            PLE_List = [select Krankenkasse__c, Artikel__c, Artikelgruppe__c, Artikelgruppe__r.Positionsnummer__c, 
                                        preis_brutto__c, X300_302__c, Preis_St_ck__c, abrechenbar__c, wirtschaftl_Zuzahlung__c, preis_netto__c
                                    from Preislisteneintrag__c 
                                    Where Artikelgruppe__r.Positionsnummer__c = :Pos_7 
                                    And (Krankenkasse__c = :KD.Krankenkasse__c or Krankenkasse__c =: KD.Krankenkasse__r.ParentID)
                                    and (Auslauf_datum__c = null or Auslauf_datum__c > :date.today())];
                                    
                            if(PLE_List != null && PLE_list.size() != 0){
                                kein_plpreis = False;
                                PLE = PLE_map_bearbeiten(PLEs, PLE_List, Kd.Krankenkasse__c, KD.Krankenkasse__r.ParentID);
                                ArtGrp.put(PLE.Artikelgruppe__c,PLE.Artikelgruppe__r);
                            }
                            else{
                system.debug('################################# Preis Mwst Zuzahlung suche PLE fuer Artikelgruppe ' + Art.Artikelgruppe__c + 
                        ' Account ' + Kd.Krankenkasse__c + ' uebergeordneter Account ' + KD.Krankenkasse__r.ParentID );           
                                PLE_List = [select Krankenkasse__c, Artikel__c, Artikelgruppe__c, Artikelgruppe__r.Positionsnummer__c, 
                                                preis_brutto__c, X300_302__c, Preis_St_ck__c, abrechenbar__c, wirtschaftl_Zuzahlung__c, preis_netto__c
                                                 from Preislisteneintrag__c 
                                                Where Artikelgruppe__c = :art.Artikelgruppe__c
                                                And (Krankenkasse__c = :KD.Krankenkasse__c or Krankenkasse__c =: KD.Krankenkasse__r.ParentID)
                                                and (Auslauf_datum__c = null or Auslauf_datum__c > :date.today())];
    
                                if(PLE_List != null && PLE_list.size() != 0){
                                    kein_plpreis = False;
                                    PLE = PLE_map_bearbeiten(PLEs, PLE_List, Kd.Krankenkasse__c, KD.Krankenkasse__r.ParentID);
                                    ArtGrp.put(PLE.Artikelgruppe__c,PLE.Artikelgruppe__r);
                                }
                          }
                    }
                }
            }
        }
        catch (system.Queryexception qe)  {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                'Fuer Auftragsposition ' + Art.Name + ' konnte kein Preislisteneintrag gefunden werden! Bitte zun�chst einen Preislisteneintrag pflegen');
            ApexPages.addMessage(myMsg);
            error = True;
            
        }   
    }
 
// Alte Struktur, Packungspreis zuerst
//   
//    If (!kein_plpreis){
//        if (PLE.Preis_brutto__c != Null){
//            KK_Preis = PLE.Preis_brutto__c * Anzahl_Verp;
//        }
//        else 
//            if (PLE.Preis_netto__c != Null){
//                if ( Art.a_pac_apo_Mwst__c == '1' ){
//                    KK_Preis = PLE.Preis_netto__c * (1 + MWSt1_proz) * Anzahl_Verp ;
//                }
//                else 
//                    if ( Art.a_pac_apo_Mwst__c == '2' ){
//                        KK_Preis = PLE.Preis_netto__c * (1 + MWSt2_proz) * Anzahl_Verp ;
//                    }
//                    else{
//                        KK_Preis = PLE.Preis_netto__c * Anzahl_Verp;
//                    }
//                }
//            else 
//               if (PLE.Preis_St_ck__c != Null){
//                    KK_Preis = PLE.Preis_St_ck__c * Anzahl_Verp * Art.Menge_in_Verpackung__c;
//                }
//                else{
//                    error = True;
//                }
//    }

// Neue Struktur, Einzelpreis zuerst!
           if (!kein_plpreis){
            if (PLE.Preis_St_ck__c != Null){
                    KK_Preis = PLE.Preis_St_ck__c * Anzahl_Verp * Art.Menge_in_Verpackung__c;
                }
            else
                if (PLE.Preis_brutto__c != Null){
                    KK_Preis = PLE.Preis_brutto__c * Anzahl_Verp;
                }
                else 
                    if (PLE.Preis_netto__c != Null){
                        if ( Art.a_pac_apo_Mwst__c == '1' ){
                            KK_Preis = PLE.Preis_netto__c * (1 + MWSt1_proz) * Anzahl_Verp ;
                        }
                        else 
                            if ( Art.a_pac_apo_Mwst__c == '2' ){
                                KK_Preis = PLE.Preis_netto__c * (1 + MWSt2_proz) * Anzahl_Verp ;
                            }
                            else{
                                KK_Preis = PLE.Preis_netto__c * Anzahl_Verp;
                            }
                }
            else 
                {
                    error = True;
                }
    }
    IF (kein_evk || kein_plpreis ){ 
        error = True;
    }
    
system.debug('########### FP gesetzliche Zuzahlung ermitteln_neu. error: '+error);         
    If (!error){

//      gesetzliche Zuzahlung ermitteln
        boolean FPdummy = false;
system.debug('########### FP gesetzliche Zuzahlung ermitteln_neu. KD.Zuzahlung_befreit_von__c: '+KD.Zuzahlung_befreit_von__c);  
system.debug('########### FP gesetzliche Zuzahlung ermitteln_neu. KD.Zuzahlung_befreit_bis__c: '+KD.Zuzahlung_befreit_bis__c);   
system.debug('########### FP gesetzliche Zuzahlung ermitteln_neu. von: '+von);
system.debug('########### FP gesetzliche Zuzahlung ermitteln_neu. bis: '+bis); 
system.debug('########### FP gesetzliche Zuzahlung ermitteln_neu. KK_Preis: '+KK_Preis);    
        
        gesetzl_zuzahlung = gesetzl_zuzahlung_ermitteln_neu(KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, 
                                    Art.Zuzahlungsbefreiung_nach_31_SGB_V__c == 'ja', von, bis, False, KK_Preis, False, Art.Hilfsmittel_zum_Verbrauch__c, FPdummy);
system.debug('########### FP gesetzliche Zuzahlung ermitteln_neu. gesetzl_zuzahlung: '+gesetzl_zuzahlung); 
//      wirtschaftliche Zuzahlung  ermitteln
        wirtschaftl_Zuzahlung = wirtschaft_zuzahlung_ermitteln(PLE.wirtschaftl_Zuzahlung__c, VK_Preis, KK_Preis);
        
//      MWSt ermitteln  
        error = MWSt_ermitteln( KVV, Art.a_pac_apo_Mwst__c, KK_Preis);

        KVV.Verkaufspreis__c = VK_Preis ;
        KVV.KVA_Preis__c = KK_Preis ;
        KVV.gesetzl_Zuzahlung__c = gesetzl_zuzahlung ;
        KVV.wirtschaftl_Zuzahlung__c = wirtschaftl_Zuzahlung ;
 
    } 
    return error;
}

public static Boolean preis_ermittelnFP_proforma ( ID FPID, KVA_Position__c KVV, Artikel__c Art, 
                                        decimal Anzahl_Verp, date von, date bis, Kunde__c KD, Auftragsposition__c Apos){
    boolean error = false;                                        
    
    updateAU = false; 
    error = preis_ermittelnFP(FPID, KVV, Art, Anzahl_Verp, von, bis, KD, Apos);
    return error;                                       
    }
    
public static Boolean preis_ermittelnFP_proforma_AB ( ID FPID, KVA_Position__c KVV, Artikel__c Art, 
                                        decimal Anzahl_Verp, date von, date bis, Kunde__c KD, Auftragsposition__c Apos){
    boolean error = false;                                        
    
    updateAU = false; 
    fpAZ = true;
    error = preis_ermittelnFP(FPID, KVV, Art, Anzahl_Verp, von, bis, KD, Apos);
    return error;                                       
    }

//  extra f�r Fallpauschalen eine andere Preismermittlung (hier geht alles anders)

public static Boolean preis_ermittelnFP ( ID FPID, KVA_Position__c KVV, Artikel__c Art, 
                                        decimal Anzahl_Verp, date von, date bis, Kunde__c KD, Auftragsposition__c Apos){ 
    Boolean kein_evk = False;
    Boolean error = False;
    Map <ID,ArtikelGruppe__c> ArtGrpMap = new Map<ID, Artikelgruppe__c>{};
    Map <ID,FallpauschalenArtikelGruppe__c> FPArtGrpMap = new Map<ID, FallpauschalenArtikelgruppe__c>{};
    Map <ID,FallPauschalenArtikelGruppe__c> FPArtGrpMapARTGRPID = new Map<ID, FallpauschalenArtikelgruppe__c>{};
    set<ID> FPArtGrpSet;
    Decimal istMengeStk;
    Decimal sollMengeStk;
    Decimal EVKproStk;
    Decimal zuviel;
    Decimal Betrag_zuviel_geliefert = 0;
    Decimal Betrag_zu_Teuer = 0;

//  erstmal auf EVK pr�fen, das ist auf jeden Fall der Verkaufspreis
    If (Art == null){
        
    }
    else if (Art.EVK__c == null){
        // am test
        kein_evk = True;
    }
    else if ( Art.EVK__c != 0){ 
        
//        VK_Preis = art.EVK__c * Anzahl_Verp; 
    }
    else{
        kein_evk = True;
    } 
    
//  jetzt k�mmern wir uns erstmal um die Fallpauschale
    
    Fallpauschale__c FP = [Select Pauschalpreis__c,  Fallpauschale_logik__c from Fallpauschale__c where id =: FPID];

    If ( !kein_EVK ){
        EVKproStk = Art.EVK__c / Art.Menge_in_Verpackung__c;
        system.debug('############### wds EVK pro Stck =  ' + EVKproStk);
        Try {
            FPArtGrpMap = new Map<ID, FallPauschalenArtikelgruppe__c>([SELECT Id, Name, Menge_Stk_Tag__c, Artikelgruppe__c, zuzahlungsfreier_H_chstpreis__c FROM FallPauschalenArtikelgruppe__c where Fallpauschale__c =: FPID]);
            FPArtGrpSet = FPArtGrpMap.keyset();
            ArtGrpSet = new Set<ID>{};
            For (ID FPAID : FPARTGrpSet){
                ArtGrpSet.add(FPArtGrpMap.get(FPAID).Artikelgruppe__c);
            }
            ArtGrpMap = new Map<ID, Artikelgruppe__c>([SELECT Id, Name FROM Artikelgruppe__c where ID in: ArtGrpSet]);
            ArtGrpSet = ArtGrpMap.keyset();

        }
        Catch (system.Listexception readFPexc){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                'Fuer Auftragsposition ' + Apos.Name + ' konnte Artikelgruppe gefunden werden!');
            ApexPages.addMessage(myMsg);
            error = True;

        }

//      wir gehen erstmal davon aus, dass bisher alles sauber abgerechnet wurde. Von daher brauchen wir uns die Vergangenheit nicht anzuschauen!
        
//      Menge = Lieferscheinclass.hole_gelieferte_Menge(Apos);
//      bisher_VZ_bis = Lieferscheinclass.getAZVZ('VZ', 'bis');

        Id IDAG;    
        For (ID AG : FPArtGrpSet){
            IDAG = FPArtGrpMap.get(AG).Artikelgruppe__c ;
            FPArtGrpMapARTGRPID.put(IDAG, FPArtGrpMap.get(AG));
        }
        
        ID ArtGrpId = Art.Artikelgruppe__c;
    
        Integer Anzahl_Tage = von.daysBetween(bis);
        istMengeStk = Art.Menge_in_Verpackung__c * Anzahl_Verp;
//      sollMengeStk = FPArtGrpMapARTGRPID.get(Art.Artikelgruppe__c).Menge_Stk_Tag__c * Anzahl_Tage;
//      zuviel = istMengeStk - SollMengeStk;
//      
//      If ( zuviel > 0 ){
//          betrag_zuviel_geliefert = zuviel * EVKproStk;   
//      }
//      if (Betrag_zuviel_geliefert < 0){
//          Betrag_zuviel_geliefert = 0;
//      }

        if ( Art.Standardartikel_fuer_Fallpauschalen__c == 'Standardartikel ohne Zuzahlung' ){
            betrag_zu_teuer = 0;
        }
        else{
            if (EVKproStk != null && FPArtGrpMapARTGRPID.containsKey(ArtGrpID) && FPArtGrpMapARTGRPID.get(ArtGrpID).Zuzahlungsfreier_H_chstpreis__c != null){
                betrag_zu_teuer = istMengeStk *  (EVKproStk - FPArtGrpMapARTGRPID.get(ArtGrpID).Zuzahlungsfreier_H_chstpreis__c) ;
            system.debug('###############wds Zuzahlung =  ' + betrag_zu_teuer);
            }
            else { betrag_zu_teuer = 0; }
        }
        if (betrag_zu_teuer < 0){
            betrag_zu_teuer = 0;
        } 
    }
    Auftrag__c au;  
    Try{
        au = [select ID, FP_gesetzl_Zuz_abgerechnet_bis__c, FP_gesetzl_Zuz_abgerechnet_ab__c,
                            Fallpauschale__c, Fallpauschale__r.Name, genehmigt_ab__c, genehmigt_bis__c
                            from Auftrag__c where ID =: APos.Auftrag__c Limit 1];
    }
    Catch (System.Listexception le){
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
            'Fuer Auftragsposition ' + Apos.Name + ' konnte kein Auftrag gefunden werden! Bitte benachrichtigen Sie die Supportorganisation!');
        ApexPages.addMessage(myMsg);
        error = True;
    }
    decimal gesetzl_Zuzahlung;
    if (!Error){
        date ab;
        date ultimo = bis.addmonths(1).toStartofMonth().addDays(-1);
        date abgerechnet_bis;
// am 15.01.2014 wegen AB_nur_anzeigen         
        if (!fpAZ) {
        system.debug('############### Preis_MWSt_Zuzahlung_class.preis_ermittelnFP. ultimo: ' + ultimo);
        if (au.FP_gesetzl_Zuz_abgerechnet_bis__c != null){
            abgerechnet_bis = au.FP_gesetzl_Zuz_abgerechnet_bis__c;
            system.debug('############### Preis_MWSt_Zuzahlung_class.preis_ermittelnFP. abgerechnet_bis: ' + abgerechnet_bis);
            if (abgerechnet_bis < ultimo) {
                ab = abgerechnet_bis.addDays(1);
                system.debug('############### Preis_MWSt_Zuzahlung_class.preis_ermittelnFP. ab: ' + ab);
                gesetzl_zuzahlung = gesetzl_zuzahlung_ermitteln_neu(KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, 
                                        False, ab, ultimo, False, FP.Pauschalpreis__c, True, 'ja', FP.Fallpauschale_logik__c);
            }
        }
        else {
            ab = AU.genehmigt_ab__c.toStartofMonth();
            gesetzl_zuzahlung = gesetzl_zuzahlung_ermitteln_neu(KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, 
                                        False, ab, ultimo, True, FP.Pauschalpreis__c, True, 'ja', FP.Fallpauschale_logik__c);
            au.FP_gesetzl_Zuz_abgerechnet_ab__c = ab;
        }
        
        }
// am 15.01.2014        
        else {
            ab = von.toStartofMonth();
            gesetzl_zuzahlung = gesetzl_zuzahlung_ermitteln_neu(KD.Zuzahlung_befreit_von__c, KD.Zuzahlung_befreit_bis__c, 
                                        False, ab, ultimo, True, FP.Pauschalpreis__c, True, 'ja', FP.Fallpauschale_logik__c);
            
        }
        KVV.gesetzl_Zuzahlung__c = gesetzl_zuzahlung;
        au.FP_gesetzl_Zuz_abgerechnet_bis__c = ultimo;
// 21.12.2013 AM 
// da wir keine Datum-Feld in KVV haben, speichern wir den Monat als integer->string in Text
        system.debug('###############Alex: gzAbgerechnetVon=' + gzAbgerechnetVon);
        if (gesetzl_zuzahlung > 0) {
            KVV.KVA_Position_text__c = string.valueOf(gzAbgerechnetVon.month());
            KVV.KVA_Position_zahl__c = fpMonate;    
            system.debug('###############Alex: KVV.KVA_Position_text__c=' + KVV.KVA_Position_text__c);
            system.debug('###############Alex: KVV.KVA_Position_text__c=' + KVV.KVA_Position_text__c);      
        }
// 21.12.2013 AM
        
        if (updateAU) {
        try{
            update au;
        }
        catch (System.Dmlexception updex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                'Fuer die Fallpauschale ' + au.Fallpauschale__r.Name + ' konnte die gesetzliche Zuzahlung nicht gespeichert werden! Bitte benachrichtigen Sie die Supportorganisation!');
            ApexPages.addMessage(myMsg);
            error = True;
        }
        }
    }
    KVV.wirtschaftl_Zuzahlung__c = betrag_zu_teuer;
    error = MWSt_ermitteln( KVV, Art.a_pac_apo_Mwst__c, KVV.wirtschaftl_Zuzahlung__c);
    if (error == Null){error = false;}
    return error;
    }

//  und auch die Aanlage 4 hat eine andere Preismermittlung

public static Boolean preis_ermitteln_A4 ( KVA_Position__c KVV, Artikel__c Art, 
                                        decimal Anzahl_Verp, date von, date bis, Kunde__c KD, String Posart){ 
    Boolean kein_evk = False;
    Boolean error = False;
    Decimal istMengeStk;
    Decimal sollMengeStk;
    Decimal EVKproStk;
    Decimal zuviel;
    Decimal Betrag_zuviel_geliefert = 0;
    Decimal Betrag_zu_Teuer = 0;
    if (KVV == null){KVV = new KVA_Position__c();}

//  erstmal auf EVK pr�fen, das ist auf jeden Fall der Verkaufspreis
    If (Art == null){
    }
    else if (Art.EVK__c == null){
    }
    else if ( Art.EVK__c != 0){ 
        KVV.Verkaufspreis__c = art.EVK__c * Anzahl_Verp; 
    }
    else{

        kein_evk = True;
    } 
    
//  jetzt k�mmern wir uns um die Anlage 4

    If ( !kein_EVK ){
        Integer Anzahl_Tage = von.daysBetween(bis);

        if ( Art.Standardartikel_Anlage_4__c ){
            KVV.wirtschaftl_Zuzahlung__c = 0;
        }
        else{
            if (Art.Anlage_4_Preis__c != null && Art.Anlage_4_Preis__c != 0){
                KVV.wirtschaftl_Zuzahlung__c = (Art.EVK__c - Art.Anlage_4_Preis__c) * Anzahl_Verp;
                KVV.gesetzl_Zuzahlung__c = 0;
                error = MWSt_ermitteln( KVV, Art.a_pac_apo_Mwst__c, KVV.wirtschaftl_Zuzahlung__c);
            }
            else{
                 ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                    'Anlage 4 Preis fuer Artikel ' + Art.Name + ' ist leer! Bitte pflegen Sie diesen Preis zunaechst!');
                 ApexPages.addMessage(myMsg);
                 error = True;
            }                       
        }
    }
    else{
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
            'Fuer den Artikel ' + Art.Name + ' ist kein EVK gepflegt! Pflegen Sie diesen und versuchen Sie es sp�ter erneut!  ');
        ApexPages.addMessage(myMsg);
        error = True;
    }
    if (error == Null){error = false;}
    return error;
    }
    
    public static date getGzAbgerechnetVon () {
        return gzAbgerechnetVon;    
    }
  
  // wird nicht aufgerufen! Nur f�r Testabdeckung!!!       
        public static void setLeereZeilen() {
            List<Zeile> pZeilen = new List<Zeile>();
            Zeile dZeile = new Zeile();
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);   
                            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);   
                            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);          
            
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
                    
            dZeile.Rpos = '. 2';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '2';  
            dZeile.stern = '2';  
            pZeilen.add(dZeile);   
               
            dZeile.Rpos = '. 3';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '3';  
            dZeile.stern = '4';  
            pZeilen.add(dZeile);      

            dZeile.Rpos = '. 4';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '13';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 31';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '31';  
            dZeile.stern = '31';  
            pZeilen.add(dZeile);      
            
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '41';  
            dZeile.stern = '41';  
            
            pZeilen.add(dZeile);      
            dZeile.Rpos = '. 41';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '51';  
            dZeile.stern = '61';  
            pZeilen.add(dZeile);
               
        }  

}