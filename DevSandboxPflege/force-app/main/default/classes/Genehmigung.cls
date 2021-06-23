/**
* Klasse Genehmigung liefert Methoden für Treigger und Apex Klassen.
* - prüfung ob Genehmigungen für einen Artikel vorliegen
* - prüfung ob Genehmigungen für mehrere Artikel vorliegen
* ............
* Bearbeitung ist stehts Kunden bezogen?. Es werden immer die Genehmigungen eines Kunden 
* mit den von Ihm bestellten Artikeln verglichen. 
*/
global with sharing class Genehmigung{
    
    /*public static List<GenehmigungsStatus> checkCustomer(List<GenehmigungsStatus> status, Kunde__c kunde){
        //Get Orders
        List<OrderWrapper> orders = getOrdersOfCustomer(kunde);
        //Get Authorizations
        List<AuthorizationWrapper> authorizations = getGenehmigungenOfCustomer(kunde);
        //MonthlyCheck Prüft jeden Monat ob die Monatlichen Authorizationen stimmen
        return doMonthlyCheck(status, orders,authorizations);
        //Allgemeine Check, Prüft die allgemein genehmigten Stückzahlen eingehalten werden.
        
        //Prüft ob Allgemeine Stückzahlen fehlende Monatliche Stückzahlen ausgleichen k�nnen
    }*/
    


//  erstellt eine map aus KdID und Kd aus den übergebenen Genehmigungen
    public static map<id, Kunde__c> getKunden(map<id,Genehmigung__c> Gens){
        map<id, Kunde__c> Kunden;
        set<id> KundenSet = new set<id>{};
        for(id Gid : Gens.keySet()){
            if (!kundenset.contains(Gens.get(Gid).Kunde__c)){
                kundenset.add(Gens.get(Gid).Kunde__c);
            }
        }
        try{
            Kunden = new map<id,Kunde__c>([Select id, Name from Kunde__c where id in : Kundenset]);
        }
        catch (System.listexception le){
            for (id Gid : Gens.keySet()){
                Gens.get(Gid).addError(' Keine Kunden gefunden! ');
            }
        }   
        return Kunden;
    } 

//  erstellt eine Map aus AuftrtagsID und Auftrag aus den übergebenen Kunden        
    public static map<id, Auftrag__c> getAuftraege(map<id,Kunde__c> KD, map<id,Genehmigung__c> Gens){
        system.debug('############## getAuftraege KD Map ' + Kd);
        system.debug('############## getAuftraege Gen Map ' + gens);
        map<id, auftrag__c> Auftraege;
        try{
            Auftraege = new map<id,Auftrag__c>([Select id, Name, genehmigt_ab__c,
                    genehmigt_bis__c, unbefristet_genehmigt__c from Auftrag__c where Kunde__c in : KD.keyset()]);
        }
        catch (System.listexception le){
        }   
        return Auftraege;
    } 

// erstellt eine map aus APosId und APos aus den übergebenen Aufträgen          
    public static map<id, Auftragsposition__c> getAPos(map<id,Auftrag__c> AU, map<id,Genehmigung__c> Gens){
        map<id, auftragsposition__c> APos;
        try{
            APos = new map<id,Auftragsposition__c>([Select id, Name, genehmigt_ab__c, Artikel__c,
                    genehmigt_bis__c, Auftrag__c, Artikel__r.Artikelgruppe__c, Gen_Menge_Stk_Mon__c,
                    Artikel__r.Artikelgruppe__r.Name
                    from Auftragsposition__c where Auftrag__c in : AU.keyset()]);
        }
        catch (System.listexception le){
        }   
        return APos;
    } 

//  erstellt eine map mit der LPID und allen LPs aus den übergebenen AuftragsPos        
    public static List<Lieferscheinposition__c> getLiPosList(map<Id, Auftragsposition__c> APos, map<id,Genehmigung__c> Gens){
        List<LieferscheinPosition__c> LiPos;
        try{
            LiPos = [Select id, Name, Menge__c, Artikel__c,
                    Auftragsposition__c, Kunde__c, Kunde__r.status__c, Lieferdatum__c, status__c, unterschrift__c, 
                    lieferschein__c, Lieferschein__r.Lieferdatum__c
                    from Lieferscheinposition__c where (Auftragsposition__c in : APos.keyset() And
                                                        Status__c = 'geliefert' And
                                                        Unterschrift__c = true)];
        }
        catch (System.listexception le){
        }   
        return LiPos;
    } 
        
//  erstellt eine map mit der AUftragsID und der Liste der zugehörigen AuftragsPos        
    public static map<id, List<Auftragsposition__c>> getAufAPosMap(map<id,Auftrag__c> AU, map<id,Auftragsposition__c> APos){
        map<id, list<auftragsposition__c>> AufAPos = new map<id, list<Auftragsposition__c>>{};
        list<Auftragsposition__c> tempList = new List<Auftragsposition__c>{};
        for (id APid : APos.keySet()){
            if (AufApos.containskey(APos.get(APid).Auftrag__c)){
                tempList = new list<Auftragsposition__c>{};
            }
            tempList.add(Apos.get(APid));
            AufAPos.put(APos.get(APid).Auftrag__c, tempList);
        }
        return AufAPos;
    } 

//  macht ein Update auf alle LiPos wo die entsprechenden Genehmigungen auf Bewilligt gesetzt sind.
    public static void updAllLSPos(map<id,genehmigung__c> toProcessMap){
//      hole relevante Kunden
        map<id,Kunde__c> KundenMap = getKunden(toProcessMap);
        system.debug('################Gen Kunden: ' + KundenMap);
//      hole relevante Aufträge
        system.debug('################Gen vor get Aufträge ' + KundenMap);
        map<id,Auftrag__c> AuftragMap = getAuftraege(KundenMap, toProcessMap);
        system.debug('################Gen Aufträge: ' + AuftragMap);
//      hole relevante APos
        map<id,AuftragsPosition__c> APosMap = getAPos(AuftragMap, toProcessMap);
        system.debug('################Gen APos: ' + APosMap);
//      hole relevante LiPos
        List<LieferscheinPosition__c> LiPosList = getLiPosList(APosMap, toProcessMap);
        system.debug('################Gen LiPos: ' + LiPosList);
        Boolean error = false;
        if (LiPosList != null && LiPosList.size() != 0){  
            system.debug(logginglevel.error, '########## updAllLSPos ' + LiPosList);  
            error = Lieferscheinclass.updateKrankenkassenabrechnung(LiPosList);
            // system.debug('################# nach updateKrankenkassenabrechnung ' + LiPosList);
            // system.debug('################# nach updateKrankenkassenabrechnung ' + LiPosList[0].Abrechnungsstatus_Krankenkasse__c);
            try{
                update LiPosList;
                // system.debug('################# nach updateKrankenkassenabrechnung nach update ' + LiPosList);
                // system.debug('################# nach updateKrankenkassenabrechnung nach update ' + LiPosList[0].Abrechnungsstatus_Krankenkasse__c);
            }
            catch (system.dmlexception de){
                for (id Gid : toProcessMap.keySet()){
                    toProcessMap.get(Gid).addError(' Update auf LieferscheinPosition nicht erfolgreich! ');
                }
            }
        }
    }    
    
    public static List<GenehmigungsStatus> PflegeboxcheckCustomer(List<GenehmigungsStatus> status, Kunde__c kunde, Auftrag__c p_auftrag,List<Auftragsposition__c> aufposi){
        //Get Orders
        OrderWrapper auftrag = new OrderWrapper();
        auftrag.auftrag = p_auftrag;
        auftrag.positionen = new List<Auftragsposition__c>();
        auftrag.positionen.addAll(aufposi);

        //Get Authorizations
        List<AuthorizationWrapper> authorizations = getGenehmigungenOfCustomer(kunde);
        //Hole Rythmus
        Integer rythmus = 1;
        if(p_Auftrag.Lieferzeitraum__c == 'monatlich'){
            rythmus = 1;
        }else if(p_Auftrag.Lieferzeitraum__c == 'zweimonatlich'){
            rythmus = 2;
        }
        else if(p_Auftrag.Lieferzeitraum__c == 'viertelhährlich'){
            rythmus = 3;
        }
        else if(p_Auftrag.Lieferzeitraum__c == 'halbhährlich'){
            rythmus = 6;
        }
        else if(p_Auftrag.Lieferzeitraum__c == 'hährlich'){
            rythmus = 12;
        }
        //MonthlyCheck Prüft jeden Monat ob die Monatlichen Authorizationen stimmen
        system.debug('########################## Genehmigung vor checkStatus ' + status);
        checkStatus(status);
        system.debug('########################## Genehmigung nach checkStatus ' + status);
        system.debug('########################## Genehmigung vor doMonthlyCheck ');
        return doMonthlyCheck(status, auftrag, authorizations, rythmus);
    }

    public static integer PflegeboxcheckCustomerThisMonth(Kunde__c kunde, Auftrag__c p_auftrag,List<Auftragsposition__c> aufposi, date thisMonth, integer LPMenge){
        //Get Orders
        system.debug(logginglevel.error, '################ PflegeboxCheckCustomerThisMonth mit Mg ' + LPMenge);       
        OrderWrapper auftrag = new OrderWrapper();
        auftrag.auftrag = p_auftrag;
        auftrag.positionen = new List<Auftragsposition__c>();
        auftrag.positionen.addAll(aufposi);

        //Get Authorizations
        List<AuthorizationWrapper> authorizations = getClosedGenehmigungenOfCustomer(kunde);  
        system.debug(logginglevel.error, ' ############### GenClass: gef Auth ' + authorizations);
        //MonthlyCheck Prüft jeden Monat ob die Monatlichen Authorizationen stimmen
        system.debug(logginglevel.error, '##############PflegeboxcheckCustomerThisMonth ' + thismonth);
        integer Mg = doMonthlyCheckThisMonth(auftrag, authorizations, thismonth, LPMenge);
        system.debug(logginglevel.error, '################ PflegeboxCheckCustomerThisMonth nachDomonthlyCheck ' + Mg);       
        return Mg;
    }

    public static List<GenehmigungsStatus> RezeptcheckCustomer(List<GenehmigungsStatus> status, Kunde__c kunde, List<Auftragsposition__c> aufposi){
        //Get Orders
        OrderWrapper auftrag = new OrderWrapper();
        auftrag.auftrag = new Auftrag__c(Kunde__c = kunde.id );
        auftrag.positionen = new List<Auftragsposition__c>();
        auftrag.positionen.addAll(aufposi);

        //Get Authorizations
        List<AuthorizationWrapper> authorizations = getGenehmigungenOfCustomer(kunde);
        //Hole Rythmus
        Integer rythmus = 1;
/*        if(auftrag.auftrag.Lieferzeitraum__c == 'monatlich'){
            rythmus = 1;
        }else if(auftrag.auftrag.Lieferzeitraum__c == 'zweimonatlich'){
            rythmus = 2;
        }
        else if(p_Auftrag.Lieferzeitraum__c == 'viertelhährlich'){
            rythmus = 3;
        }
        else if(p_Auftrag.Lieferzeitraum__c == 'halbhährlich'){
            rythmus = 6;
        }
        else if(p_Auftrag.Lieferzeitraum__c == 'hährlich'){
            rythmus = 12;
        }
*/
        //MonthlyCheck Prüft jeden Monat ob die Monatlichen Authorizationen stimmen
        checkStatus(status);
        return doMonthlyCheck(status, auftrag, authorizations, rythmus);

        return new List<GenehmigungsStatus>{};
    }
    
    /**Prüft alle angelegten Kunden auf gültige Genehmigungen
    public static void checkAll(){
        List<Kunde__c> kunden = getCustomer();
        for(Kunde__c k : kunden){
            checkCustomer(k);
        }
    }**/
    
    /**Einmalige prüfung
    * Prüft ob es zu der Bestellung eine passende Genehmigung/Antrag gibt.
    * Gibt den Passenden Antrag als Return zur�ck.
    *  
    **/
    public static Genehmigung__c einfachePruefung(Auftrag__c p_auftrag, Kunde__c kunde){
        //Der Auftrag
        OrderWrapper auftrag = new OrderWrapper(p_auftrag);
        //Die Genehmigungen
        List<AuthorizationWrapper> authorizations = getGenehmigungenOfCustomer(kunde);
        //Weiter bestellungen (falls ben�tigt)
        List<OrderWrapper> orders = getOrdersOfCustomer(kunde);
        //Prüfe Genehmigungen
        for(AuthorizationWrapper a : authorizations){
            //Check Zeit des Auftrages
            if(auftrag.getMinDate() < a.getMinDate()){
                
            }
        }
        return null;
    }
    
    /**Monatliche prüfung**/
    public static List<GenehmigungsStatus> doMonthlyCheck(List<GenehmigungsStatus> status, OrderWrapper auftrag, List<AuthorizationWrapper> authorizations){
        //Prüfe eingabe
        if(auftrag==null){
            system.debug('########## Keine Aufträge');
            status.add(new GenehmigungsStatus(null,'Es liegt kein Auftrag vor. Bitte wenden sie sich an Ihren Systemadministrator!: ',null));
            return status;
        }else if(authorizations == null||authorizations.isEmpty()){
            status.add(new GenehmigungsStatus(null,'Es liegen keine Genehmigungen vor, Bitte erstellen sie in der Kundenansicht, die Genehmigung um fortzufahren!: ',null));
            return status;
        }
        //Ermittle den Zeitraum der Order
        debug('Start Monthly check');
        Date mindate = auftrag.getMinDate();
        Date maxdate = auftrag.getMaxDate();
        Boolean unbefristet = auftrag.getunbefristet();
        //Prüfe jeden Monat inneralb dieses Zeitraumes
        // - Wie wird mit halben Monaten vorgegangen?
        //Zuerste mindate auf ersten stellen
        mindate = mindate.toStartOfMonth();
        //Monate zwischen min und max
        Integer monthbetween = 240;
        if (!unbefristet){
            monthbetween = mindate.monthsBetween(maxdate);
        }
        //stati
        for(Integer i = 0; i <= monthbetween; i++){
            
            Date datetocheck = mindate.addMonths(i);
            checkDate(status, datetocheck, auftrag, authorizations);
        }
        checkStatus(status);
        return status;
    }
    
    public static void checkStatus(List<GenehmigungsStatus> status){
//        system.debug('#GS######################### START '+status);
        for(Genehmigung.GenehmigungsStatus g : status){
//            system.debug('#GSX######################### POS '+g);
        }
    }
    
    /**Monatliche prüfung mit Rythmus z.B. alle 3 Monate etc**/
    public static List<GenehmigungsStatus> doMonthlyCheck(List<GenehmigungsStatus> status, OrderWrapper auftrag, List<AuthorizationWrapper> authorizations, Integer rythmus){
        //Prüfe eingabe
        if(auftrag==null){
            status.add(new GenehmigungsStatus(null,'Es liegen keine Aufträge vor. Bitte wenden sie sich an Ihren Systemadministrator!: ',null));
            return status;
        }else if(authorizations == null||authorizations.isEmpty()){
            debug('Keine Genehmigungen');
            status.add(new GenehmigungsStatus(null,'Es liegen keine Genehmigungen vor, Bitte erstellen sie in der Kundenansicht, die Genehmigung um fortzufahren!: ',null));
            return status;
        }
        //Ermittle den Zeitraum der Order
        system.debug('################ Genehmigung Start Monthly check');
        Date mindate = auftrag.getMinDate();
        Date maxdate = auftrag.getMaxDate();
        Boolean unbefristet = auftrag.getunbefristet();
        //Prüfe jeden Monat inneralb dieses Zeitraumes
        // - Wie wird mit halben Monaten vorgegangen?
        //Zuerste mindate auf ersten stellen
        mindate = mindate.toStartOfMonth();
        //Monate zwischen min und max
        System.debug(logginglevel.error, '########### do monthly check mindate ' + mindate );
        System.debug(logginglevel.error, '########### do monthly check maxdate ' + maxdate );
        Integer monthbetweenminandmax = 240;     // 20 Jahre !!! mehr wird nicht gePrüft
        if (!unbefristet){
            if (maxdate == null){
                monthbetweenminandmax = 1;
            }
            else {
                monthbetweenminandmax = mindate.monthsBetween(maxdate);
            }
        }
        System.debug(logginglevel.error, '########### do monthly check Monate ' + monthbetweenminandmax );
        //stati
        Integer jumpcounter = rythmus-1;
        for(Integer i = 0; i <= monthbetweenminandmax; i++){
            jumpcounter++;
            Date datetocheck = mindate.addMonths(i);
            if(jumpcounter == rythmus){
                checkDate(status, datetocheck, auftrag, authorizations);
                jumpcounter = 0;
            }
        }
        checkStatus(status);
        return status;
    }

    /**Monatliche prüfung nur für diesen Monat**/
    public static integer doMonthlyCheckThisMonth(OrderWrapper auftrag, List<AuthorizationWrapper> authorizations, date thisMonth, Integer LPMenge){
        //Prüfe eingabe
        boolean status = false;
        //Ermittle den Zeitraum der Order
        debug('Start Monthly check for ' + thismonth);
        if(thisMonth == null) {
            thisMonth = date.Today();
        }
        Date dateToCheck = thisMonth.toStartOfMonth();
        System.debug(logginglevel.error, '########### do monthly check datetocheck ' + DateToCheck );
        System.debug(logginglevel.error, '########### do monthly check Menge ' + LpMenge );
        return CheckDateBooleanMg(datetocheck, auftrag, authorizations, LPMenge);
    }
    
    /**
    * Status welcher zum Benachrichtigten des Nutzers verwendet wird
    */
    public class GenehmigungsStatus{
        /* Der gePrüfte Monat */
        public Date monat{get;set;}
        /* Message */
        public String message{get;set;}
        /* Artikelgruppe */
        public String artikelgruppe{get;set;}
        
        public GenehmigungsStatus(Date p_monat,String p_message, String p_artikelgruppe){
            this.monat = p_monat;
            this.message = p_message;
            this.artikelgruppe = p_artikelgruppe;
        }
    }
    
    public static List<GenehmigungsStatus> checkDate(List<GenehmigungsStatus> status, Date datetocheck, OrderWrapper auftrag, List<AuthorizationWrapper> authorizations){
        //Kommuliere alle Genehmigungen vom datum ;datetocheck;
        system.debug('#### CheckDate Prüfe Datum '+datetocheck);
        AuthorizationWrapper auth = sumOfAuthorizationsAtDate(datetocheck, authorizations);
        debug('Genehmigungspositionen gefunden: '+auth.positionen.size());


        //Prüfe alle Auftragspositionen ...
        for(Auftragsposition__c ap : auftrag.positionen){
            system.debug(logginglevel.error, '#### checkDate Prüfe: Auftragsposition: '+ap);
            Boolean b = false;
            //... auf eine vorhandene Genehmigung
            for(AuthorizationWrapperPosition gp : auth.positionen){
                system.debug(logginglevel.error, '#### checkDate vor checkPosition gp : '+gp);
                if(ap.Artikel__r.Artikelgruppe__c == gp.genehmigungsposition.Artikelgruppe__c){
                    checkPosition(status, datetocheck,ap,gp,auth.genehmigung);
                    b = true;
                }
            }
            if(b == false){
                status.add(new GenehmigungsStatus(datetocheck,'Es liegt keine Genehmigung für den Artikel vor: ',ap.Artikel__r.Artikelgruppe__r.Name));
            }
        }

        checkStatus(status);
        return status;
    }

    public static boolean CheckDateBoolean(Date datetocheck, OrderWrapper auftrag, List<AuthorizationWrapper> authorizations){
        //Kommuliere alle Genehmigungen vom datum ;datetocheck;
        system.debug('####### CheckdateBoolean Prüfe Datum '+datetocheck);
        AuthorizationWrapper auth = sumOfAuthorizationsAtDate(datetocheck, authorizations);
        system.debug('####### CheckdateBoolean Genehmigungspositionen gefunden: '+auth.positionen.size());


        Boolean b = false;
        integer Menge = 0;
        //Prüfe alle Auftragspositionen ...
        for(Auftragsposition__c ap : auftrag.positionen){
            system.debug(logginglevel.error, '####### CheckdateBoolean Prüfe: Auftragsposition: '+ap);
            //... auf eine vorhandene Genehmigung
            list<Genehmigungsstatus> status = new list<Genehmigungsstatus>{};
            if (Authorizations != null && Authorizations.size() != 0){
                for(AuthorizationWrapperPosition gp : auth.positionen){
                    system.debug(logginglevel.error, '####### CheckdateBoolean vor checkPosition gp: : '+gp);
                    checkPosition(status, datetocheck,ap,gp,auth.genehmigung);
                }
                if (status.size() == 0){
                    b = true;
                }
            }
        }
        return b;
    }
    

    public static integer CheckDateBooleanMg(Date datetocheck, OrderWrapper auftrag, List<AuthorizationWrapper> authorizations, integer LPMenge){
        //Kommuliere alle Genehmigungen vom datum ;datetocheck;
        system.debug('####### CheckdateBoolean Prüfe Datum '+datetocheck);
        AuthorizationWrapper auth = sumOfAuthorizationsAtDate(datetocheck, authorizations);
        for (Integer i=0; i<auth.positionen.size(); i++){
            system.debug('####### CheckdateBoolean Genehmigungspositionen gefunden: '+auth.positionen[i]);
        }
        system.debug(logginglevel.error, '####### CheckdateBooleanMg : '+ LPMenge);
        

        Boolean b = false;
        integer Menge = 0;
        //Prüfe alle Auftragspositionen ...
        for(Auftragsposition__c ap : auftrag.positionen){
            system.debug(logginglevel.error, '####### CheckdateBoolean Prüfe: Auftragsposition: '+ap);
            //... auf eine vorhandene Genehmigung
            list<Genehmigungsstatus> status = new list<Genehmigungsstatus>{};
            if (Authorizations != null && Authorizations.size() != 0){
                for(AuthorizationWrapperPosition gp : auth.positionen){
                    system.debug(logginglevel.error, '####### CheckdateBoolean vor checkPosition gp: : '+gp);
                    Menge = checkPositionMg(status, datetocheck,ap,gp,auth.genehmigung, LPMenge);
                    system.debug(logginglevel.error, '####### CheckdateBoolean nach checkPosition Menge: '+ Menge );
                    if (Menge > 0){ break; }
                }
                if (status.size() == 0){
                    b = true;
                }
            }
        }
        return menge;
    }
    
    /**Vergleich Auftrags- und Genehmigungsposition*/
    public static List<GenehmigungsStatus> checkPosition(List<GenehmigungsStatus> status, Date datetocheck, Auftragsposition__c ap, AuthorizationWrapperPosition gp, Genehmigung__c g){
        
        system.debug('#### checkPosition Prüfe: mit Genehmigungsposition: '+ap.Artikel__r.Artikelgruppe__c+' vs '+gp.genehmigungsposition.Artikelgruppe__c);
        system.debug(logginglevel.error, '#### AP Artikelgruppe ' + ap.Artikel__r.Artikelgruppe__c);
        system.debug(logginglevel.error, '#### GP Artikelgruppe ' + gp.genehmigungsposition.Artikelgruppe__c);
        if(ap.Artikel__r.Artikelgruppe__c == gp.genehmigungsposition.Artikelgruppe__c){
            system.debug(logginglevel.error, '#### AP GenMenge ' + ap.Gen_Menge_Stk_Mon__c);
            system.debug(logginglevel.error, '#### AP GenMenge ' + gp.menge);
            //Es liegt eine Genehmigung für die Artikelgruppe vor, 
            //Prüfe die Anzahldebug('Vergleiche Gruppe: '+gp.Artikelgruppe__c+' GenMenge: '+gp.Gen_Menge_Stk_Mon__c+' AnMenge '+ap.Gen_Menge_Stk_Mon__c+'');
            if(ap.Gen_Menge_Stk_Mon__c <= gp.menge){
                //Genehmigte Menge ist gr��er als Auftragsposition
                //Ziehe die genutzte Menge von der Genehmigung ab
                gp.menge -= ap.Gen_Menge_Stk_Mon__c;
                //Im Positiv Fall wird kein Status erstellt
                system.debug(logginglevel.error, '######################################### MENGE LIEGT VOR' + ap.Artikel__c);
            }else{
                if (ap.Gen_Menge_Stk_Mon__c == gp.genehmigungsposition.Ant_Menge_Stk_Mon__c){
                    
                }
                //Genehmigte Menge ist kleiner, bedeutet das keine Genehmigung vorliegt
//                system.debug(logginglevel.error, '!!!!!!!!!!!! ap.Artikel__r.Artikelgruppe__r.Name ' + ap.Artikel__r.Artikelgruppe__r.Name);
                system.debug(logginglevel.error, '!!!!!!!!!!!! datetocheck ' + datetocheck);
                system.debug(logginglevel.error, '!!!!!!!!!!!! ap.Gen_Menge_Stk_Mon__c ' + ap.Gen_Menge_Stk_Mon__c);
                system.debug(logginglevel.error, '!!!!!!!!!!!! gp.menge ' + gp.menge);
                if (gp.menge == null){gp.menge = 0;}
                if (ap.Gen_Menge_Stk_Mon__c == null){ap.Gen_Menge_Stk_Mon__c = 0;}
                status.add(new GenehmigungsStatus(datetocheck,'Keine ausreichende Menge genehmigt. Es fehlen : '+(ap.Gen_Menge_Stk_Mon__c-gp.menge),ap.Artikel__r.Artikelgruppe__r.Name));
                
            }
        }
        checkStatus(status);
        return status;
    }
    /**Vergleich Auftrags- und Genehmigungsposition*/
    public static integer checkPositionMg(List<GenehmigungsStatus> status, Date datetocheck, Auftragsposition__c ap, AuthorizationWrapperPosition gp, Genehmigung__c g, integer Menge){
        Integer Mg=0;
        system.debug('#### checkPosition Prüfe: mit Genehmigungsposition: '+ap.Artikel__r.Artikelgruppe__c+' vs '+gp.genehmigungsposition.Artikelgruppe__c);
        system.debug(logginglevel.error, '#### AP Artikelgruppe ' + ap.Artikel__r.Artikelgruppe__c);
        system.debug(logginglevel.error, '#### GP Artikelgruppe ' + gp.genehmigungsposition.Artikelgruppe__c);
        system.debug(logginglevel.error, '#### checkPositionMg ' + Menge);
        if(ap.Artikel__r.Artikelgruppe__c == gp.genehmigungsposition.Artikelgruppe__c){
            system.debug(logginglevel.error, '#### AP GenMenge ' + ap.Gen_Menge_Stk_Mon__c);
            system.debug(logginglevel.error, '#### GP GenMenge ' + gp.menge);
            //Es liegt eine Genehmigung für die Artikelgruppe vor, 
            //Prüfe die Anzahldebug('Vergleiche Gruppe: '+gp.Artikelgruppe__c+' GenMenge: '+gp.Gen_Menge_Stk_Mon__c+' AnMenge '+ap.Gen_Menge_Stk_Mon__c+'');
            if(Menge <= gp.menge){
                //Genehmigte Menge ist gr��er als Auftragsposition
                //Ziehe die genutzte Menge von der Genehmigung ab
                gp.menge -= Menge;
                //Im Positiv Fall wird kein Status erstellt
                Mg = Menge;
                system.debug(logginglevel.error, '######################################### MENGE LIEGT VOR' + ap.Artikel__c);
            }else{
                //Genehmigte Menge ist kleiner, bedeutet das keine Genehmigung vorliegt
//                system.debug(logginglevel.error, '!!!!!!!!!!!! ap.Artikel__r.Artikelgruppe__r.Name ' + ap.Artikel__r.Artikelgruppe__r.Name);
                system.debug(logginglevel.error, '!!!!!!!!!!!! datetocheck ' + datetocheck);
                system.debug(logginglevel.error, '!!!!!!!!!!!! ap.Gen_Menge_Stk_Mon__c ' + ap.Gen_Menge_Stk_Mon__c);
                system.debug(logginglevel.error, '!!!!!!!!!!!! gp.menge ' + gp.menge);
                if (gp.menge == null){gp.menge = 0;}
                if (ap.Gen_Menge_Stk_Mon__c == null){ap.Gen_Menge_Stk_Mon__c = 0;}
                Mg = integer.valueOf(gp.menge);
            }
        }
        return Mg;
    }
    
    public static AuthorizationWrapper sumOfAuthorizationsAtDate(Date datetocheck, List<AuthorizationWrapper> authorizations){
        system.debug('Bilde Summe alle Gehemigungen');
        AuthorizationWrapper gholder = new AuthorizationWrapper();
        gholder.genehmigung.Status__c = 'Bewilligung';
        //Wenn die Genehmigung innerhalb des Datums f�llt //Zeitbegrenzte Genehmigung
        for(AuthorizationWrapper aw : authorizations){
            system.debug('Merge: '+aw.genehmigung+' checkdate '+datetocheck );
            if((aw.genehmigung.unbefristet_genehmigt__c == true || datetocheck <= aw.genehmigung.genehmigt_bis__c) && datetocheck >= aw.genehmigung.genehmigt_ab__c.toStartOfMonth()){
                //F�ge Genemigung der allgemeinen Genehmigung hinzu
                addAuthorizationToAuthorization(gholder, aw);
            }
        }
        return gholder;
    }
    
    public static AuthorizationWrapper addAuthorizationToAuthorization(AuthorizationWrapper holder, AuthorizationWrapper add){
        system.debug('Merge Genehmigungsposition');
        //für jede zu hinzuzuf�gende Genehmigunsposition
        for(AuthorizationWrapperPosition gpadd : add.positionen){
            //Prüfe ob Position im sumholder bereits vorhanden
            system.debug('Merge;add Position: '+gpadd);
            boolean addet = false;
            //Prüft ob ein passender eintrag bereits vorhanden ist,
            for(AuthorizationWrapperPosition gpholder : holder.positionen){
                system.debug('Merge;into Position: '+ gpholder);
                //wenn ja wird diese kommulativ erg�nzt. <??????? rechtlich ok ?
                if(gpholder.genehmigungsposition.Artikelgruppe__c == gpadd.genehmigungsposition.Artikelgruppe__c){
                    if(gpadd.menge == null) gpadd.menge = 0;
                    if(gpholder.menge == null) gpholder.menge = 0;
                    gpholder.menge += gpadd.menge;
                    
                    system.Debug('###Merge Authorisazions: Kommuliere' + gpholder + ' and ' + gpadd);
                    addet = true;
                }
            }
            if(!addet){
                //wenn nein wird dieserhinzugef�gt
                AuthorizationWrapperPosition nposition = new AuthorizationWrapperPosition(holder.genehmigung);
                nposition.genehmigungsposition.Artikelgruppe__c = gpadd.genehmigungsposition.Artikelgruppe__c;
                nposition.menge = gpadd.menge;
                system.Debug('###Merge Authorisazions: Adde' + gpadd);
                holder.positionen.add(nposition);
            }
        }
        return holder;
        
    }
    

    
    public static Date getMinDate(List<OrderWrapper> orders){
        Date mindate;
        for(OrderWrapper ow : orders){
            //debug('MinDate: tempmindate: '+mindate + ' checkdate: '+ow.getMinDate());
            if(mindate == null || mindate > ow.getMinDate()){
            
                mindate = ow.getMinDate();
            }
        }
        //Debug ausgabe
        if(mindate == null){
            debug('mindate: no Mindate found');
        }else{
            debug('mindate:' + mindate);
        }
        return mindate;
    }
    
    public static void debug(String message){
        system.debug ('###Genehmigung: ' + message);
    }
    
    public static Date getMaxDate(List<OrderWrapper> orders){
        Date maxdate;
        for(OrderWrapper ow : orders){
            //debug('MaxDate: tempmindate: '+maxdate+ ' checkdate: '+ow.getMaxDate());
            if(maxdate == null || maxdate < ow.getMaxDate()){
                maxdate = ow.getMaxDate();
            }
        }
        if(maxdate == null){
            debug('maxdate: no Maxdate found');
        }else{
            debug('maxdate:' + maxdate);
        }
        return maxdate;
    }

    public static Boolean getunbefristet(List<OrderWrapper> orders){
        Boolean unbefristet;
        for(OrderWrapper ow : orders){
            //debug('MaxDate: tempmindate: '+maxdate+ ' checkdate: '+ow.getMaxDate());
            if(unbefristet == null || unbefristet != ow.getunbefristet()){
                unbefristet = ow.getunbefristet();
            }
        }
        if(unbefristet == null){
            debug('unbefristet: not found');
        }else{
            debug('unbefristet:' + unbefristet);
        }
        return unbefristet;
    }
    
    public static List<AuthorizationWrapper> getGenehmigungenOfCustomer(Kunde__c kunde){
        List<Genehmigung__c> genehmigungen = [SELECT 
                        Name,
                        Dokumentation__c,
                        genehmigt_ab__c,
                        genehmigt_bis__c,
                        Genehmigungsstatus__c,
                        Originalgenehmigung__c,
                        Rezept__c,
                        unbefristet_genehmigt__c
                        FROM Genehmigung__c WHERE Kunde__c = :kunde.id];
        List<AuthorizationWrapper> auths = new List<AuthorizationWrapper>();
        for(Genehmigung__c g : genehmigungen){
            AuthorizationWrapper aw = new AuthorizationWrapper(g);
            auths.add(aw);
        }
        return auths;
    }
    
    public static List<AuthorizationWrapper> getclosedGenehmigungenOfCustomer(Kunde__c kunde){
        List<Genehmigung__c> genehmigungen = [SELECT 
                        Name,
                        Dokumentation__c,
                        genehmigt_ab__c,
                        genehmigt_bis__c,
                        Genehmigungsstatus__c,
                        Originalgenehmigung__c,
                        Rezept__c,
                        unbefristet_genehmigt__c
                        FROM Genehmigung__c WHERE Kunde__c = :kunde.id
                        and (status__c = 'Bewilligung' or status__c = 'Teilbewilligung')];
        system.debug('################ getclosedGenehmigungen ' + genehmigungen);
        List<AuthorizationWrapper> auths = new List<AuthorizationWrapper>();
        for(Genehmigung__c g : genehmigungen){
            AuthorizationWrapper aw = new AuthorizationWrapper(g);
            auths.add(aw);
        }
        return auths;
    }
    

    
    public static List<OrderWrapper> getOrdersOfCustomer(Kunde__c kunde){
        List<Auftrag__c> auftraege = [SELECT 
                        Name,
                        Dokumentation__c,
                        genehmigt_ab__c,
                        genehmigt_bis__c,
                        Originalgenehmigung__c
                        FROM Auftrag__c WHERE Kunde__c = :kunde.id];
        List<OrderWrapper> orders = new List<OrderWrapper>();
        for(Auftrag__c g : auftraege ){
            OrderWrapper aw = new OrderWrapper (g);
            orders.add(aw);
        }
        return orders;
    }
    
    public static List<Auftragsposition__c> getSubOrder(Auftrag__c auftrag){
        List<Auftragsposition__c> auftragspositionen = [SELECT 
                        Name,
                        Dokumentation__c,
                        genehmigt_ab__c,
                        genehmigt_bis__c,
                        Originalgenehmigung__c,
                        Artikel__r.Artikelgruppe__c,
                        Artikel__r.Artikelgruppe__r.Name,
                        Gen_Menge_Stk_Mon__c
                        FROM Auftragsposition__c WHERE Auftrag__c = :auftrag.id];
        return auftragspositionen ;
    }
    
    public static List<Kunde__c> getCustomer(){
        List<Kunde__c> kunden = [SELECT Anrede__c, 
                            Anrede_Alt__c, 
                            BIC__c, 
                            BLZ__c, 
                            Bankbezeichnung__c, 
                            Betreuer__c, 
                            CreatedById, 
                            CreatedDate, 
                            Datum_OP__c, 
                            IsDeleted, 
                            Einzugserm_chtigung__c, 
                            Fax__c, 
                            Geburtsdatum_text__c, 
                            Hausnummer__c, 
                            IBAN__c, 
                            komb_Name__c, 
                            KdNummerfreibis__c, 
                            Kennenlerndatum__c, 
                            Ansprechpartner_Kasse__c, 
                            Kontonummer__c, 
                            Krankenkasse__c, 
                            Name, Kunde_logik__c, Kunde_text__c, Kunde_zahl__c, Kundennummer__c, LastActivityDate, LastModifiedById, LastModifiedDate, Lieferstop__c, Mobil__c, Name__c, Notizen__c, Ort__c, OwnerId, PLZ__c, PLZA__c, Pflegedienst__c, Prognose__c, Id, Status__c, Sterbedatum__c, Stra_e__c, SystemModstamp, Telefon__c, Versichertennummer__c, Vorname__c, Willkommensschreiben__c, Zahlungsmodalit_t__c, Zahlungsziel__c, Zuzahlung_befreit__c, Zuzahlung_befreit_bis__c, Zuzahlung_befreit_von__c, ZuzahlungBefreit__c, aktueller_OP__c, e_mail__c, komb_Adresse__c FROM Kunde__c];
        return kunden;
    }
    
    public class OrderWrapper{
        public List<Auftragsposition__c> positionen{get;set;}
        public Auftrag__c auftrag{get;set;}
        public OrderWrapper(){
        }
        public OrderWrapper(Auftrag__c p_auftrag){
            this.auftrag = p_auftrag;
            this.positionen = getSubOrder(this.auftrag);
        }
        
        public Date getMinDate(){
            Date mindate = auftrag.genehmigt_ab__c;
            for(Auftragsposition__c ap : positionen){
                //debug('MinDate@Pos: tempmindate: '+mindate + ' checkdate: '+ap.genehmigt_ab__c);
                if(mindate == null || mindate > ap.genehmigt_ab__c){
                    mindate = ap.genehmigt_ab__c;
                }
            }
            return mindate;
        }
        
        public Date getMaxDate(){
            Date maxdate = auftrag.genehmigt_bis__c;
            for(Auftragsposition__c ap : positionen){
                //debug('MaxDate@Pos: tempmindate: '+maxdate + ' checkdate: '+ap.genehmigt_bis__c);
                if(maxdate == null || maxdate < ap.genehmigt_bis__c){
                    maxdate = ap.genehmigt_bis__c;
                }
            }
            return maxdate ;
        }

        public Boolean getunbefristet(){
            Boolean unbefristet = auftrag.unbefristet_genehmigt__c;
            for(Auftragsposition__c ap : positionen){
                //debug('unbefristet@Pos: tempmindate: '+unbefristet + ' checkdate: '+ap.genehmigt_bis__c);
                if(unbefristet == null || unbefristet != auftrag.unbefristet_genehmigt__c){
                    unbefristet = auftrag.unbefristet_genehmigt__c;
                }
            }
            return unbefristet ;
        }
    }
    
    public class AuthorizationWrapper{
        public List<AuthorizationWrapperPosition> positionen{get;set;}
        public Genehmigung__c genehmigung{get;set;}
        public AuthorizationWrapper(){
            this.genehmigung = new Genehmigung__c();
            this.positionen = new List<AuthorizationWrapperPosition>();
        }
        public Boolean isFree{get;set;} //True wenn Positionen frei sind
        public AuthorizationWrapper(Genehmigung__c p_genehmigung){
            //First Reinit Genehmigung and gain all Information
            this.genehmigung = [SELECT
                        Name,
                        Dokumentation__c,
                        genehmigt_ab__c,
                        genehmigt_bis__c,
                        Genehmigungsstatus__c,
                        Originalgenehmigung__c,
                        Rezept__c,
                        unbefristet_genehmigt__c,
                        Status__c,
                        Antrag_beantwortet_am__c,
                        Antrag_bewilligt_ab__c,
                        Antrag_eingegangen_am__c,
                        Antrag_versandt_am__c,
                        Nach_Paragraph__c,
                        Kunde__c
                        FROM Genehmigung__c WHERE Id = :p_genehmigung.Id];
            this.positionen = getGenehmigungsposition(this.genehmigung);
        }
        
        public AuthorizationWrapperPosition getPositionByName(String name){
            for(AuthorizationWrapperPosition g : this.positionen){
                if(g.genehmigungsposition.Artikelgruppe__r.Name == name){
                    return g;
                }
            }
            return null;
        }
        
        public Date getMinDate(){
            Date mindate = genehmigung.genehmigt_ab__c;
            for(AuthorizationWrapperPosition gp : positionen){
                if(mindate == null || mindate > gp.genehmigungsposition.genehmigt_ab__c){
                    mindate = gp.genehmigungsposition.genehmigt_ab__c;
                }
            }
            return mindate;
        }
        
        public Date getMaxDate(){
            Date maxdate = genehmigung.genehmigt_bis__c;
            for(AuthorizationWrapperPosition gp : positionen){
                if(maxdate == null || maxdate < gp.genehmigungsposition.genehmigt_bis__c){
                    maxdate = gp.genehmigungsposition.genehmigt_bis__c;
                }
            }
            return maxdate;
        }

        public Boolean getunbefristet(){
            Boolean unbefristet = genehmigung.unbefristet_genehmigt__c;
            for(AuthorizationWrapperPosition gp : positionen){
                if(unbefristet == null || unbefristet != gp.genehmigungsposition.unbefristet_genehmigt__c){
                    unbefristet = gp.genehmigungsposition.unbefristet_genehmigt__c;
                }
            }
            return unbefristet;
        }
    }
    
    public class AuthorizationWrapperPosition{
        public Genehmigungsposition__c genehmigungsposition{get;set;}
        public Genehmigung__c genehmigung{get;set;}
        public decimal menge{get;set;}
        
        public AuthorizationWrapperPosition(Genehmigung__c g, Genehmigungsposition__c gp){
            this.genehmigungsposition = gp;
            this.genehmigung = g;
            getMengeFromAuthorizationPosition();
        }
        
        public AuthorizationWrapperPosition(Genehmigung__c g){
            this.genehmigungsposition = new Genehmigungsposition__c();
            this.genehmigung = g;
            getMengeFromAuthorizationPosition();
        }
        
        private void getMengeFromAuthorizationPosition(){
            //Wenn es sich um einen Antrag handelt, soll die Antragsmenge anstellee
            //der Genehmigungsmenge ber�cksichtigt werden.
            if(this.genehmigung.Status__c != null){
                if(this.genehmigung.Status__c.equals('Antragsversand')){
                    this.menge = this.genehmigungsposition.Ant_Menge_Stk_Mon__c;
                }else if(this.genehmigung.Status__c.equals('Bewilligung')||this.genehmigung.Status__c.equals('Teilbewilligung')){
                    this.menge = this.genehmigungsposition.Gen_Menge_Stk_Mon__c;
                }else if(this.genehmigung.Status__c.equals('Ablehnung')){
                    this.menge = 0;
                }else{
                    this.menge = 0;
                }
            }else{
                this.menge = 0;
            }
        }
    }
    
    public static List<AuthorizationWrapperPosition> getGenehmigungsposition(Genehmigung__c genehmigung){
        List<Genehmigungsposition__c> genehmigungspositionen = [SELECT 
            Name,
            Gen_Menge_Stk_Mon__c,
            genehmigt_ab__c,
            genehmigt_bis__c,
            Gen_Menge_Stk__c,
            Gen_Menge_Stk_Tag__c,
            GenAnzVerp__c,
            Artikelgruppe__c,
            unbefristet_genehmigt__c,
            Artikelgruppe__r.Name,
            Ant_Menge_Stk_Mon__c,
            Ant_Menge_Stk__c
            FROM Genehmigungsposition__c WHERE Genehmigung__c = :genehmigung.id];
        List<AuthorizationWrapperPosition> positionen = new List<AuthorizationWrapperPosition>();
        for(Genehmigungsposition__c gp : genehmigungspositionen){
            positionen.add(new AuthorizationWrapperPosition(genehmigung, gp));
        }
        return positionen;
    }
    
    public static boolean reserviereFuerAuftrag(Auftrag__c auftrag){
        //Prüft für jede Auftragsposition ob ein entsprechender gegenpart vorhanden ist.
        //
        OrderWrapper ow = new OrderWrapper(auftrag);
        for(Auftragsposition__c a : ow.positionen){
            
        }
        
        return false;
    }
  
}