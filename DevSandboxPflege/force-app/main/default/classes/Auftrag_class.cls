///////////////////////////////////////////////////////////////////////////////////////////////
//
//      erstellt am 23.10.2012 sorgt daf�r dass bei Fallpauschalen die H�kchen des Auftrags auf die
//                              Auftragspositionen �bernommen wird
//      deployed am 25.10.2012
//      geaendert am 20.12.2012 am 29.4.2012 deployed
//
///////////////////////////////////////////////////////////////////////////////////////////////

public with sharing class Auftrag_class {

//  im Fall einer FallPauschale werden alle Haekchen des Auftrags auf neue Apos uebertragen,
//  sonst uebertragen die neuen Apos ihre Haekchen auf den Auftrag
    public static boolean APos_insert(List <Auftragsposition__c> APL){
        map<Id, Auftragsposition__c>AposMap = new map<id, Auftragsposition__c>{};
        map<Id, Auftrag__c> AuMap = new map<Id, Auftrag__c>{};
        set<ID> AUSet = new set<ID>{};
        List<Auftragsposition__c> FPAPosL = new List<Auftragsposition__c>{};
        boolean errorFP = False;
        boolean errorAP = False;

//      erstmal aufteilen in eine Map f�r FallPauschalen AP und eine Liste f�r nicht FallPauschalen AP
        for (Auftragsposition__c ap : APL){
            if (ap.Positionsart__c.contains('FP')){
                FPAposL.add(ap);
                AuSet.add(ap.auftrag__c);
            }
            else{
                APosMap.put(ap.id, ap);
            }
        }           

//      fuer alle nicht FP Apos uebertragen wir die Laufzettelhaekchen von unten nach oben
        errorAP = Apos_update_Laufzettel(AposMap);
        if (errorAP){
            System.debug('############## insert Apos: beim Update auf die Auftraege ist was schiefgegangen ' + APosMap );
        }
        
//      Alle zugeh�rigen Auftraege in eine AuftragsMap lesen
        try{
            AuMap = new map<ID, Auftrag__c>([select Dokumentation__c, Rezept__c, R_ckantwort__c, Originalgenehmigung__c, FallPauschale__c
                                                from Auftrag__c where id in :AuSet]);
        }
        catch(System.queryexception qexc){
            System.debug('############## insert Apos: es konnten keine Auftraege f�r diese Auftragspositionen ' + APL +
                        ' gefunden werden! Fehler: ' + qexc);
            errorFP = True; 
        }
        Finally{
            errorFP = true;
        }
        
//      Loop �ber alle Auftragspositionen
        if (!errorFP){
            For (Auftragsposition__c ap : FPAPosL){
                if (AuMap.containsKey(ap.Auftrag__c)){

//                  Wenn der zugeh�rige Auftrag eine FallPauschale ist, holt sich die Apos, die H�kchen vom Auftrag
                    if (AuMap.get(ap.Auftrag__c).FallPauschale__c != null){
                        ap.Dokumentation__c = AUMap.get(ap.Auftrag__c).Dokumentation__c;
                        ap.R_ckantwort__c = AUMap.get(ap.Auftrag__c).R_ckantwort__c;
                        ap.Originalgenehmigung__c = AUMap.get(ap.Auftrag__c).Originalgenehmigung__c;
                        ap.Originalrezept__c = AUMap.get(ap.Auftrag__c).Rezept__c;
                    }
                }
                
//              Auftrag nich gefunden? Fehler melden
                else{
//                  ap.addError();
                }
            }
        }
        return (errorFP || errorAP);
    }

//  geht vom Auftrag falls Fallpauschale auf alle Apos und setzt die H�kchen wie im Auftrag
    public static boolean Auftrag_update_Laufzettel(map<Id, Auftrag__c> AUMap){
        boolean error = False;
        List<Auftragsposition__c> APL;
        Try{
            APL = [Select ID, Name, Dokumentation__c, R_ckantwort__c, 
                        Originalrezept__c, Originalgenehmigung__c, Auftrag__c 
                    from Auftragsposition__c 
                    Where Auftrag__c in: AUMap.keyset()];
        }
        catch (System.Listexception e){
            System.debug('############## update Apos LZ: es konnten keine Auftragspositionen f�r diese Auftraege ' + AUMap +
                        ' gefunden werden! Fehler: ' + e);
            error = True;   
        }
        if (!error){
            For (Auftragsposition__c AP : APL){
                ap.Dokumentation__c = AUMap.get(ap.Auftrag__c).Dokumentation__c;
                ap.R_ckantwort__c = AUMap.get(ap.Auftrag__c).R_ckantwort__c;
                ap.Originalgenehmigung__c = AUMap.get(ap.Auftrag__c).Originalgenehmigung__c;
                ap.Originalrezept__c = AUMap.get(ap.Auftrag__c).Rezept__c;
            }
        }
        Try{
            update APL;
        }
        catch (System.dmlexception d){
            System.debug('############## update Apos LZ: Auftragspositionen ' + APL +
                        ' konnten nicht upgedated werden! Fehler: ' + d);
            error = True;   
            
        }
        return error;
    }

//  geht von den Apos hoch zum Auftrag und �bertr�gt die H�kchen auf den Auftrag
    public static boolean APos_Update_Laufzettel(map<Id, Auftragsposition__c> AposMap){
        Boolean error = False;
        Boolean doku;
        Boolean rueck;
        Boolean rezept;
        Boolean orig;
        List<Auftrag__c> AuList = new List<Auftrag__c>{};
        map<ID, Auftrag__c> AuMap = new map<Id, Auftrag__c>{};
        map<Id, List<Auftragsposition__c>> AuAposMap = new map<Id, List<Auftragsposition__c>>{};
        List<Auftragsposition__c> tempList;
        List<Auftragsposition__c> APL;
        Auftrag__c tempAu;

//      hier erzeugen wir eine Map aus AuftragsID und allen zugeh�rigen APos
        For (id aktid : AposMap.keySet()){
            if (AuAposMap.containsKey(AposMap.get(aktid).Auftrag__c)){
                tempList = AuAposMap.get(AposMap.get(aktid).Auftrag__c);
            }
            else{
                tempList = new List<Auftragsposition__c>{};
            }
            tempList.add(AposMap.get(aktid));
            AuAposMap.put(APosMap.get(aktid).Auftrag__c, tempList);
        }

//      Alle Auftr�ge der APos lesen
        Try{
            AuMap = new map<id, Auftrag__c>([select Id, Dokumentation__c, Originalgenehmigung__c, Rezept__c,
                                                R_ckantwort__c from Auftrag__c where id in: AuAposMap.keySet()]);
        }
        Catch (system.Listexception e){
            System.debug('############## Apos update LZ: es konnten keine Auftraege f�r diese APos ' + APosMap +
                        ' gefunden werden! Fehler: ' + e);
            error = True;   
        }

//      hier muessen nochmal alle Auftragspositionen geholt werden, weil sonst eine Auftragsposition
        Try{
            APL = [select id, Dokumentation__c, Originalgenehmigung__c, Originalrezept__c, R_ckantwort__c, Auftrag__c
                                from Auftragsposition__c where AUftrag__c in :AuAposMap.keySet()];
        }
        Catch (system.Listexception le){
            System.debug('############## Apos update LZ: es konnten nicht alle Apos fuer die Auftraege der upgedateten APos ' + AuMap +
                        ' gefunden werden! Fehler: ' + le);
            error = True;   
        }
        

//      hier erweitern wir diese Map aus AuftragsID um alle zugeh�rigen APos
        For (Auftragsposition__c ap : APL){
            if (AuAposMap.containsKey(ap.Auftrag__c)){
                tempList = AuAposMap.get(ap.Auftrag__c);
            }
            else{
                tempList = new List<Auftragsposition__c>{};
            }
            tempList.add(ap);
            AuAposMap.put(ap.Auftrag__c, tempList);
        }

//      Loop �ber alle Auftr�ge, der upgedateten APos
        If (AuAposMap.size() != 0){
            for (Id aktid : AuAposMap.keyset()){
                doku = True;
                rueck = True;
                rezept = True;
                orig = True;
                tempList = AuAposMap.get(aktid);
                system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag diese Liste Apos ' + tempList);
                system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag vorher diese Doku ' + doku);
                system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag vorher diese rueck ' + rueck);
                system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag vorher diese rezept ' + rezept);
                system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag vorher diese orig ' + orig);
//              Auftragsh�kchen anhand der zugeh�rigen APos ermitteln
                for (Auftragsposition__c ap : tempList){
                    doku &= ap.Dokumentation__c;
                    rueck &= ap.R_ckantwort__c;
                    rezept &= ap.Originalrezept__c;
                    orig &= ap.Originalgenehmigung__c; 
                    system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag nach APos diese Doku ' + doku);
                    system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag nach APos diese rueck ' + rueck);
                    system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag nach APos diese rezept ' + rezept);
                    system.debug('####################### AposUpdateLaufzettel habe f�r einen Auftrag nach APos diese orig ' + orig);
                } 
                if (AuMap.containsKey(aktid)){
                    tempAu = AuMap.get(aktid);
//                  Auftragsh�kchen entsprechend der zugeh�rigen APos setzen, falls das angebracht ist
                    if (tempAu.Dokumentation__c != doku ||
                        tempAu.R_ckantwort__c != rueck ||
                        tempAu.Rezept__c != rezept ||
                        tempAu.Originalgenehmigung__c != orig){
                        tempAu.Dokumentation__c = doku;
                        tempAu.R_ckantwort__c = rueck;
                        tempAu.Rezept__c = rezept;
                        tempAu.Originalgenehmigung__c = orig;
                        AuList.add(tempAu);
                    }
                }
            }

//          wenn Auftraege zu updaten sind, dann machen wir das jetzt
            if (AuList.size() != 0){
                try{
                    update AuList;
                }
                Catch (system.dmlexception dexc){
                    System.debug('############## Apos update LZ: es konnten keine Auftraege f�r diese APos ' + APosMap +
                                    ' gefunden werden! Fehler: ' + dexc);
                    error = True;   
                }
            }
        }
        return error;
    }
    
    public static void Auftrag_Update_CheckAndRemoveBedarfe(Auftrag__c a){
        
        //Alles Quatsch
        
        
        //Hole die Auftragspositionen
        List<Auftragsposition__c> auftragsposition = [SELECT 
                Artikel__c, 
                Auftrag__c,
                Auftrag__r.Name,
                Auftragsposition_logik__c,
                Auftragsposition_text__c,
                Auftragsposition_zahl__c,
                Enddatum_letzte_Lieferung__c,
                Gen_Menge_ges__c,
                Gen_Menge_Stk_Mon__c,
                Gen_Menge_Stk_Tag__c,
                GenAnzVerp__c,
                Gesamtpreis__c,
                letzter_AZ_bis__c,
                Lieferstatus__c,
                Originalgenehmigung__c,
                Originalrezept__c,
                Positionsart__c,
                Positionsnummer_PZN__c,
                Preis__c,
                reicht_bis__c,
                Restmenge__c,
                zus_tzliche_Tage__c,
                genehmigt_bis__c,
                Dokumentation__c,
                Genehmigungsstatus__c,
                Kunde__c,
                Lieferzeitraum__c,
                R_ckantwort__c,
                genehmigt_ab__c,
                Artikel__r.Name,
                Artikel__r.Positionsnummer_PZN__c,
                Artikel__r.Menge_ABDA__c,
                Artikel__r.a_pgr2_apo_Einheit__c
                
                FROM Auftragsposition__c
                WHERE Auftrag__c = :a.Id ];
        
        //Hole alle Lieferscheine abh�ngig von den Auftragspositionen
        List<Lieferscheinposition__c> Bedarfe = new List<Lieferscheinposition__c>();
        for(Auftragsposition__c ap : auftragsposition){
            Bedarfe.addAll([Select 
                    Status__c,
                    VZ_von__c,
                    VZ_bis__c,
                    Auftragsposition__c
                    FROM Lieferscheinposition__c
                    WHERE Auftragsposition__c = :ap.Id ]);
        }
        
        //Pr�fe die Lieferscheine und entferne doppelte
        //for()
        
    }
}