//  geaendert am 08.08.2012 am 15.8.2012s deployed
//                  - Aenderung zur Vergabe einer neuen Kundennummer
//wds geändert am 24.10.2012
//                  - Kunden-name zusammensetzung geändert: ohne Anrede und erst Nachname, dann Vorname
//wds geändert am 21.01.2013 
//                  - neueKdNrsuchen auf public geändert wegen Test-Cases
//  geändert am 23.5.2013 am 24.5.2013 deployed
//                  - Es kam immer wieder vor, dass man zweimal speichern musste um einen Kunden zu sichern.
//                      (einige Zeilen bzgl. der kleinsten Kundennummer wurden auskommentiert. siehe Kommentar im Code)
//wds geändert am 15.08.2014 ABfrage auf Kundennummer NULL! Dann Kundennummer auf 1 setzen.
// wds am 19.03.2015 Modifikation damit die Anlage des ersten Kunden sauber läuft
// wds am 08.04.2015 Modifikation, damit die interne Kundennummer suchbar ist dafür neues Feld Suchfeld_Kundennr__c
// wds am 14.04.2015 Modifikation, dass bei Neuanlage Kunde als Medifox-Kunde gekennzeichnet wird oder auch nicht
// wds am 15.04.2015 Modifikationen bzgl Medifox wieder rückgängig gemacht.
// BT  am 10.09.2015 neue Methode neuen_kunden_sichern_nach_warnung.
// AM 22.09.2017 - remove "max(" from soql
//

public with sharing class neuen_kunden_sichern_class { 
    public static Boolean neuen_kunden_sichern_func (Kunde__c Kunde){
        Boolean error = False;

        if ( Kunde.Name__c == null) {
            Kunde.addError (' Sie müssenn mindestens den Namen angeben! ');
            error = True;
        }
            
        Kunde.Name = Kunde.Name__c + ', ' + Kunde.Vorname__c; 
        // AggregateResult[] ar = [select max(kundennummer__c) kdnr from kunde__c];
        list<Kunde__c> ar = [SELECT Kundennummer__c 
                                    FROM Kunde__c 
                                    ORDER BY Kundennummer__c DESC NULLS LAST
                                    LIMIT 1];

        integer newKdNr = 1;
        if (ar != NULL ) {
            integer lastkdnr = 0;
            if (ar[0].kundennummer__c != NULL) {
                lastkdnr =Integer.valueOf(ar[0].kundennummer__c);
            }
        newKdNr = lastkdnr + 1 ;}
        else {  
        }
        if (newKdNr > 999999){
            Kunde.addError ('Achtung: keine freie Kundennummer gefunden! Bitte rufen Sie den Support an!');
            error = true;
        }
        else{
            kunde.Kundennummer__c = newKdNr;
            integer ikd = integer.valueof(kunde.kundennummer__c);
            kunde.suchfeld_kundennr__c='CB14-' + String.valueof( ikd );
        }   
            
        system.debug(Kunde.Zuzahlung_befreit__c +' - ' + Kunde.Zuzahlung_befreit_von__c+' - '+error);
        if(Kunde.Zuzahlung_befreit__c && Kunde.Zuzahlung_befreit_von__c==null){
            Kunde.addError (' Sie müssenn ein Datum für die Befreiung von der Zuzahlung eingeben! ');
            error = True;
        }else if(!Kunde.Zuzahlung_befreit__c){
            Kunde.Zuzahlung_befreit_von__c = null;
            Kunde.Zuzahlung_befreit_bis__c = null;
        }
            system.debug(Kunde.Zuzahlung_befreit__c +' - ' + Kunde.Zuzahlung_befreit_von__c+' - '+error);
            system.debug ('####################### neuenKundensichernvoid nach setzen Kunde.Name ' + Kunde );
            try{
                insert Kunde;
            } 
            catch (system.dmlexception d){
                //Kunde.addError(' Kundendaten konnten nicht gespeichert werden! ');
                error = True;
            }
        return error;
    }
    
    public static Boolean neuen_kunden_sichern_nach_warnung(Kunde__c Kunde) {
        Boolean error = false;
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;  
        Database.SaveResult sr = Database.insert(Kunde, dml); 
        if (sr.isSuccess()) {   
         System.debug('Duplicate account has been inserted in Salesforce!'); 
        }
        
        return error;
    }
}