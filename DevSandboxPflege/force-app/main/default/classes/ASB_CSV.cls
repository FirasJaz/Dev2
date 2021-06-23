/*/****************************************************************************************************************************
// Erstellt 04.01.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//****************************************************************************************************************************
//
// Parameter: RG-Name comma separated
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// created CSV as string
//
//**************************************************************************************************************************** 
// Test 
//****************************************************************************************************************************
//Änderungen: 
// 17.01.2019 AM #163288504 - wieder getrennt KUWV und CB
// 28.03.2019 AM trennen 'privat' und alle andere Kanäle
// 13.06.2019 AM #166662265. CB - Beihilfeberechtigt. Beim Ausgabe nich ausgelistete Curabox soll Beihilfe auch in PO 
//                              als letzte Spalte gedruckt werden (50% von CB Preis)   
//****************************************************************************************************************************
/*/
public with sharing class ASB_CSV {
    public static string Medifox = null;
    
    public static void createAndSendBoth(String rgnamen) {
        createAndSendCsvFromInvoice (rgnamen, false);
        createAndSendCsvFromInvoice (rgnamen, true);
    } 
    
    // @future(callout=true)
    public static void createAndSendCsvFromInvoice (String rgnamen, boolean priv) {
        asMail__c asMail = asMail__c.getValues('asb');
        String subject, toAddr, toCC, PlainTextBody;
        try {
            subject = asMail.subject__c;
            toAddr = asMail.toAddr__c;
            toCC = asMail.toCC__c;
            PlainTextBody = asMail.body__c;
        }
        catch (System.Exception e) {
            subject = 'Abrechnung';
            toAddr = 'kontakt@klosesrockepartner.de';
            toCC = null;
            PlainTextBody =  ' ';
        }
        string betreff = '';
        List<Messaging.Emailfileattachment> attmList = new List<Messaging.Emailfileattachment>();

        String[] namen = rgnamen.split(',');
        for(integer i =0 ; i<namen.size();i++) namen[i] = namen[i].trim();
        String rgnamenstr = '';
        String attachmentName = '';     
        for(string s : namen) rgnamenstr += '_' + s;  

        // Curabox  
        String csvString = createCsvFromInvoice(rgnamen, priv, '54');        
        if(csvString != null) {
            Blob csvAtt = blob.valueOf(csvString);
            attachmentName = 'Abrechnung' + rgnamenstr + '_Curabox_' + date.today().format();
            if(Medifox != null) {
                attachmentName += '_' + Medifox;
            }
            if(priv) {
                attachmentName += '_Privat.csv';
                betreff = subject + ' ' + rgnamenstr + ' Privat';
            }
            else {
                attachmentName += '_Gesetzlich.csv';
                betreff = subject + ' ' + rgnamenstr + ' Gesetzlich';
            }
            if(Medifox != null) {
                betreff += ' ' + Medifox;
            }
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName(attachmentName);
            csvAttc.setBody(csvAtt);
            attmList.add(csvAttc);                      
        }  

        // KUWV  
        string betreffSave = betreff; 
        betreff = '';
        csvString = createCsvFromInvoice(rgnamen, priv, '51');        
        if(csvString != null) {
            Blob csvAtt = blob.valueOf(csvString);
            attachmentName = 'Abrechnung' + rgnamenstr + '_KUWV_' + date.today().format();
            if(Medifox != null) {
                attachmentName += '_' + Medifox;
            }
            if(priv) {
                attachmentName += '_Privat.csv';
                betreff = subject + ' ' + rgnamenstr + ' Privat';
            }
            else {
                attachmentName += '_Gesetzlich.csv';
                betreff = subject + ' ' + rgnamenstr + ' Gesetzlich';
            }
            if(Medifox != null) {
                betreff += ' ' + Medifox;
            }
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            csvAttc.setFileName(attachmentName);
            csvAttc.setBody(csvAtt);
            attmList.add(csvAttc);                      
        }  
        // send 
        if(!attmList.isEmpty()) {
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            String[] toAddress =  toAddr.split(','); 
            if(toCC != null) {                  
                String[] toCcAddress =  toCC.split(',');  
                mail.setCcAddresses(toCcAddress);
            }
            mail.setToAddresses(toAddress);
            if(betreff == '') betreff = betreffSave;
            mail.setSubject(betreff);
            
            mail.setFileAttachments(attmList);
            mail.setPlainTextBody(PlainTextBody); 
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });            
        }

    }
    
    
    public static String createCsvFromInvoice (String rgnamen, boolean priv, string pg) { 
        String csvString = null;
        String[] namen = rgnamen.split(',');
        for(integer i =0 ; i<namen.size();i++) namen[i] = namen[i].trim();
        
        set<string> kanal = new set<string>();
        if(priv) {
            kanal.add('privat');
        }
        else {
            Schema.DescribeFieldResult fieldResult = account.Kanal_Unterpunkt__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                if(pickListVal.getLabel() != 'privat') {
                    kanal.add(pickListVal.getLabel());
                }
            }            
        }
        system.debug('####### alex_test ' + kanal + ' ### ' +namen);
        List<Lieferschein__c> lsList = [
        SELECT name, Lieferadresse__c, Genehmigung__r.Genehmigungsnummer__c, Genehmigung__r.genehmigt_ab__c, Kunde_Zuzahlung_befreit__c, Lieferschein_text__c,
            Kunde__c,
            Kunde__r.Versichertennummer__c, Kunde__r.Medifox_2__c,
            Kunde__r.Name__c, Kunde__r.Vorname__c, Kunde__r.Anrede__c, 
            Kunde__r.Geburtsdatum_text__c, Kunde__r.Beihilfeberechtigt__c, Kunde__r.Abrechnung_direkt_mit_PPK__c, Kunde__r.Kundennummer_abena__c,
            Kunde__r.Krankenkasse__r.IK_Nummer__c, 
            Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c, 
            Kunde__r.Krankenkasse__r.TK__c, 
            Kunde__r.Krankenkasse__r.AC__c, 
            Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c,
            Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_54__c,
            Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_51__c,
        (SELECT id, name, Menge__c, Artikel__r.Name, Artikel__r.Pflege_Hilfsmittelnr__c, Lieferdatum__c, VZ_von__c, VZ_bis__c, Artikel__r.a_pac_apo_Mwst__c, Artikel__r.Anlage_4_Preis__c  
            FROM Lieferscheinpositionen__r)
        FROM Lieferschein__c where id IN
        (SELECT Lieferschein__c FROM Lieferbest_tigung__c
            WHERE Rechnung__r.name IN :namen
            AND Lieferschein__r.kunde__r.Krankenkasse__r.Kanal_Unterpunkt__c IN: kanal)
            AND Lieferschein_text__c =: pg
            ORDER BY Kunde__r.Krankenkasse__r.IK_Nummer__c, name
        ];

        if((lsList != null) && (lsList.size() > 0)) {
            csvString = createCsvFromDeliveryNoteList(lsList);
        }
        return csvString;
    }
    
    
    public static String createCsvFromDeliveryNoteList (List<Lieferschein__c> lsList) {
        string maNummer = '';
        string maNummerMedifox = '2183';
        string maNummerWebcare = '2182';
        String csvString = '';
        try {
            maNummerMedifox = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerMedifox__c;
            maNummerWebcare = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerWebcare__c;
        }
        catch (System.Exception e) {}

        set<id> lpSet = new Set<id>();
        set<id> kdSet = new Set<id>();
        // first run - set<id> Lieferscheinposition__c, set<id> Kunde__c, maNummer
        if((lsList != null) && (lsList.size() > 0)) {
            for(Lieferschein__c ls : lsList) {
                if(maNummer == '') {
                    if(ls.Kunde__r.Medifox_2__c) {
                        Medifox = 'M';
                        maNummer = maNummerMedifox;
                    }
                    else {
                        Medifox = 'W';
                        maNummer = maNummerWebcare;
                    }
                    csvString = 'VERSION\t1.2\r\nMA' + '\t' + maNummer + '\r\n';
                }
                kdSet.add(ls.Kunde__c);
                for(Lieferscheinposition__c lp : ls.Lieferscheinpositionen__r) {
                    lpSet.add(lp.id);
                }
            }
        }
        else {
            return null;
        }


        List<Rechnungsposition__c> rpList = [SELECT Lieferscheinposition__c, Lieferscheinposition__r.Lieferschein__r.name, Rechnung__r.name,
                                                    Gesamtpreis_Brutto__c, gesetzliche_Zuzahlung__c, Zur_Abrechnung_bergebene_Summe__c 
                                                FROM Rechnungsposition__c 
                                                WHERE Lieferscheinposition__c IN :lpSet];
        map<id, Rechnungsposition__c> rpmap = new map<id, Rechnungsposition__c>();
        map<String, String> lsrgMap = new map<String, String>();
        for(Rechnungsposition__c rp : rpList) {
            rpmap.put(rp.Lieferscheinposition__c, rp);
            lsrgMap.put(rp.Lieferscheinposition__r.Lieferschein__r.name, rp.Rechnung__r.name);
        }
        system.debug('#### alex6502 ' + lsrgMap.size());
        map<id, Anschrift__c> raMap = new map<id, Anschrift__c>();
        List<Anschrift__c> RaList = [SELECT Id, Kunde__c, komb_Adresse__c, Standardrechnungsanschrift__c,
                                                e_mail__c, Fax__c, Ort__c, PLZ__c, Stra_e__c, Telefon__c
                                                            FROM Anschrift__c 
                                                            WHERE Kunde__c IN :kdSet
                                                            AND Art_der_Anschrift__c = 'Kundenadresse'
                                                            AND komb_Adresse__c != null];
            if((RaList != null) && (RaList.size() > 0)) {
                for(Anschrift__c RA: RaList) {
                    raMap.put(RA.Kunde__c, RA);
                }                                                             
            }
                                                            
                                                            
        integer lfnr = 1;

        
        for(Lieferschein__c ls : lsList) {

            string hkz = '';
            string tk = '';
            string ac = '';
            string genName = '';
            string genVon = '';
            

            boolean beihilfe = ls.Kunde__r.Beihilfeberechtigt__c;
            if(ls.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c != null) {
                hkz = ls.Kunde__r.Krankenkasse__r.Hilfsmittel_Kennzeichen__c;
            }

            if(ls.Kunde__r.Krankenkasse__r.TK__c != null) {
                tk = ls.Kunde__r.Krankenkasse__r.TK__c;
            }

            if(ls.Kunde__r.Krankenkasse__r.AC__c != null) {
                ac = ls.Kunde__r.Krankenkasse__r.AC__c;
            }   

            string anrede = ' ';
            if(Ls.Kunde__r.Anrede__c != null) {
                if(Ls.Kunde__r.Anrede__c.contains('Herr')) {
                    Anrede = 'h';
                }
                else {
                    Anrede = 'f';
                }
            }
            string gebDat = '01.01.2000';
            if(ls.Kunde__r.Geburtsdatum_text__c != null) {
                gebDat = ls.Kunde__r.Geburtsdatum_text__c;
            }   
            string versNummer = '';
            if(Ls.Kunde__r.Versichertennummer__c != null) {
                versNummer = Ls.Kunde__r.Versichertennummer__c;
            }               
            else {
                if(ls.Kunde__r.Geburtsdatum_text__c != null) {
                    versNummer = ls.Kunde__r.Geburtsdatum_text__c.replace('.', '');
                }
                else {
                    versNummer = Ls.Kunde__r.Name__c;
                }                   
            }

            if(Ls.Genehmigung__r.Genehmigungsnummer__c != null) {
                genName = Ls.Genehmigung__r.Genehmigungsnummer__c; 
            }
            if(ls.Genehmigung__r.genehmigt_ab__c != null ) {
                genVon = datetime.newInstance(ls.Genehmigung__r.genehmigt_ab__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
            }

            // Sonderregelung 51 / 54
            if(ls.Lieferschein_text__c == '51') {
                if(ls.Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_51__c != null) {
                    if(ls.Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_51__c.contains('Genemigungsnummer')) genName = '';
                    if(ls.Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_51__c.contains('Genehmigt ab')) genVon = '';
                }
            }
            if(ls.Lieferschein_text__c == '54') {
                if(ls.Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_54__c != null) {
                    if(ls.Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_54__c.contains('Genemigungsnummer')) genName = '';
                    if(ls.Kunde__r.Krankenkasse__r.Abrechnung_gen_daten_54__c.contains('Genehmigt ab')) genVon = '';
                }
            }
          

            String einls =  'BA\t' + string.valueOf(lfnr) 
                                                + '\t' + 'HILFSMITTEL' 
                                                + '\t' + lsrgMap.get(ls.name)
                                                + '\t' 
                                                + '\t' 
                                                + '\t' 
                                                + '\t' 
                                                + '\r\n'
                                        + 'VS\t' + Ls.Kunde__r.Krankenkasse__r.IK_Nummer__c  
                                                + '\t' + versNummer
                                                + '\t' + '50001'                            
                                                + '\t' + ls.Kunde__r.Name__c 
                                                + '\t' + ls.Kunde__r.Vorname__c 
                                                + '\t' + raMap.get(Ls.Kunde__c).Stra_e__c
                                                + '\t' + raMap.get(Ls.Kunde__c).PLZ__c 
                                                + '\t' + raMap.get(Ls.Kunde__c).Ort__c
                                                + '\t' + anrede 
                                                + '\t' + gebDat 
                                                + '\r\n'
                                        +  'VO\t' 
                                                + '\t'   
                                                + '\t'                
                                                + '\t' 
                                                + genVon
                                                + '\t' 
                                                + genName 
                                                + '\r\n';  
                                if((ls.Lieferschein_text__c == '51') && (!ls.Kunde_Zuzahlung_befreit__c)) {
                                    einls += 'ZZ\tJa\r\n';
                                }
                                else {
                                    einls += 'ZZ\tNein\r\n';
                                }
            decimal su = 0.00;
            decimal zz = 0.00;
            decimal brutto = 0.00;    
            String sonderabrechnung = '';      
            for(Lieferscheinposition__c lp : ls.Lieferscheinpositionen__r) {
                string lDat = '';
                string vzvDat = '';
                string vzbDat = ''; 
                string eigenanteil = '';
                decimal betrag = 0.0;
                decimal preis = 0.0;
                if(Lp.Artikel__r.Anlage_4_Preis__c != null) {
                    preis = Lp.Artikel__r.Anlage_4_Preis__c;
                }
                if(beihilfe) {
                    eigenanteil = ksgFunctions.formatCurrency(preis / 2) ;
                }
                
                if(lp.Lieferdatum__c != null) {
                    lDat = datetime.newInstance(lp.Lieferdatum__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                }               
                
                if(lp.VZ_von__c != null) {
                    vzvDat = datetime.newInstance(lp.VZ_von__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                }
                
                if(lp.VZ_bis__c != null) {
                    vzbDat = datetime.newInstance(lp.VZ_bis__c, Time.newInstance(0, 0, 0, 0)).format('dd.MM.yyyy');
                } 
                
                // Sonderabrechnung HM - 'Curabox' und Summe
                // AM 13.06.2019
                if((ls.Lieferschein_text__c == '54') && (ls.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c != null)) {
                    sonderabrechnung = '\t' + 'CuraBox' 
                                    + '\t' + lDat 
                                    + '\t' + hkz
                                    + '\t' + vzvDat 
                                    + '\t' + vzbDat 
                                    + '\t' + lp.Artikel__r.a_pac_apo_Mwst__c 
                                    + '\t' 
                                    + '\t' + ac
                                    + '\t' + tk
                                    + '\t'; 
                                // AM13.06.2019
                                    // + '\r\n';    
                }
                else {
                    // Normale Abrechnung - jede Pos Drucken
                
                    einls += 'PO\t' + lp.Artikel__r.Pflege_Hilfsmittelnr__c 
                            + '\t' + string.valueOf(lp.Menge__c)
                            + '\t' + ksgFunctions.formatCurrency(preis) 
                            + '\t' + lp.Artikel__r.Name
                            + '\t' + lDat 
                            + '\t' + hkz
                            + '\t' + vzvDat 
                            + '\t' + vzbDat 
                            + '\t' + lp.Artikel__r.a_pac_apo_Mwst__c 
                            + '\t' 
                            + '\t' + ac
                            + '\t' + tk
                            + '\t' + eigenanteil
                            + '\r\n';
                }
                try {
                    su += rpmap.get(lp.id).Zur_Abrechnung_bergebene_Summe__c;
                }
                catch(Exception e) {
                    system.debug('##### alex 6501 ' + lp.id + ' ev. kostenlose Lieferung ');
                }
                try {zz += rpmap.get(lp.id).gesetzliche_Zuzahlung__c;} catch(system.Exception e) {}
                try {brutto += rpmap.get(lp.id).Gesamtpreis_Brutto__c;} catch(system.Exception e) {}
            }
            // Sonderabrechnung HM - 'Curabox' und Summe
            if((ls.Lieferschein_text__c == '54') && (ls.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c != null)) {
                einls += 'PO\t' + ls.Kunde__r.Krankenkasse__r.Abrechnung_HM_Positionsnummer__c
                        + '\t1'
                        + '\t' + ksgFunctions.formatCurrency(su); 
                    // AM 13.06.2019
                if(beihilfe) {
                    einls += sonderabrechnung + ksgFunctions.formatCurrency(su / 2) + '\r\n';
                }
                else {
                    einls += sonderabrechnung + '\r\n';
                }
            }            
            // Summe
            if(ls.Lieferschein_text__c == '51') {
                if (ls.Kunde_Zuzahlung_befreit__c) {
                    einls += 'SU\t'  + ksgFunctions.formatCurrency(su) + '\t0\t' + ksgFunctions.formatCurrency(su) + '\r\n'; 
                }
                else {
                    try {
                        einls += 'SU\t'  + ksgFunctions.formatCurrency(brutto) + '\t' + ksgFunctions.formatCurrency(zz) +'\t' + ksgFunctions.formatCurrency(su) + '\r\n'; 
                    }
                    catch(system.Exception e) {
                        einls += 'SU\t'  + ksgFunctions.formatCurrency(su) + '\t0\t' + ksgFunctions.formatCurrency(su) + '\r\n';   
                    }
                }
            }
            else {
                // 54 keine Zuzahlung
                einls += 'SU\t'  + ksgFunctions.formatCurrency(su) + '\t0\t' + ksgFunctions.formatCurrency(su) + '\r\n'; 
            }
            csvString += einls;  
            lfnr++;                                
        }

        // system.debug('###' + csvString);
        return csvString;
    }

}