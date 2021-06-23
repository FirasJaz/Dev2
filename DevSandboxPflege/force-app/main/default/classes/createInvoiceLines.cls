/*/****************************************************************************************************************************
// Erstellt 17.06.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: set<id> - passende Delivery Notes 
// 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  Erstellen Invoice lines 
//  
//
//****************************************************************************************************************************
//Änderungen:   
// 06.05.2020   AM  #172578887 - Preisänderung    
// 28.08.2020   AM  00002564 - Preislisten
// 06.01.2021   AM  00002613 - dateTime.format('...') durch date.format();
// 27.05.2021   AM  00002634 - Anpassung wegen Eigenanteil. Einige Methoden sind in eine Helper-Klasse definiert 
//****************************************************************************************************************************
*/
public with sharing class createInvoiceLines {
    private List<String> errorList = new List<String>();
    private integer totalDN = 0;
    private Map<String, id> ivMap = new Map<String, id>();
    private id asbId = null;

    private date tempPreisVon = date.newInstance(4000, 12, 31);
    private date tempPreisBis = date.newInstance(4000, 12, 31);

    private Map<id, List<Preisliste__c>> plMap = new Map<id, List<Preisliste__c>>(); 

    

    // constructor
    public createInvoiceLines() {
        String abName;
        try {
            abName = AB_KK__c.getInstance('AB_KK_Einstellungen').Abrechnungsfirma__c;
        }
        catch(System.exception e) {
            abName = 'ASB';
        }
        try {
            Account asb = [SELECT id FROM account WHERE Name = : abName];
            asbId = asb.id;
        }
        catch(System.Exception e) {
            system.debug('####### Error: Abrechnungsstelle nicht gefunden.');
        }

        // Preislisten
        plMap = invoiceHelper.fillPreisliste();
    }

    // main call
    public void createLines(Set<id> dnIdSet, boolean medifox) {
        invoiceHelper.curaboxPriceResult curaboxPriceResult = new invoiceHelper.curaboxPriceResult();

        Map<id, String> csvMap = new Map<id, String>();
        Map<id, String> ivnMap = new Map<id, String>();
        Map<id, String> sonderRegelMap = new Map<id, string>();
        Map<id, Curabox_Genehmigung__c> gen54Map = new Map<id, Curabox_Genehmigung__c>();
        Map<id, Curabox_Genehmigung__c> gen51Map = new Map<id, Curabox_Genehmigung__c>();
        Map<id, Curabox_Genehmigung__c> gen5XMap = new Map<id, Curabox_Genehmigung__c>();
        Set<Id> dnOKidSet = new Set<id>();
        Set<id> dlOkidSet = new Set<id>();
        List<Invoice_Line__c> ilList = new List<Invoice_Line__c>();

        Map<id, invoiceHelper.deliveryNotePrepared> dnMap = new Map<id, invoiceHelper.deliveryNotePrepared>();
        

        List<Delivery_Note__c> dnList = [SELECT id, Name, Status__c, Contact__c, Delivery_date__c, 
                                                Contact__r.Zuzahlungsbefreit_Nein__c,
                                                Contact__r.Beihilfeberechtigt__c,
                                                Contact__r.Medifox_Kunde__c,
                                                Contact__r.Kranken_Pflegekasse__r.PG51_Abrechnungs_Methode__c,
                                                Contact__r.Kranken_Pflegekasse__r.Hilfsmittel_Kennzeichen__c,
                                                Contact__r.Kranken_Pflegekasse__r.TK__c,
                                                Contact__r.Kranken_Pflegekasse__r.AC__c,
                                                Contact__r.Kranken_Pflegekasse__r.Abrechnung_HM_Positionsnummer__c,
                                                (SELECT id, name, VZ_von__c, VZ_bis__c, Delivery_Status__c,
                                                Delivery_date__c,
                                                Quantity__c, 
                                                Product__c, 
                                                Product__r.Name,
                                                Product__r.Price__c,
                                                Product__r.tempPrice__c,
                                                Product__r.Hilfsmittelgruppe__c,
                                                Product__r.Hilfsmittelpositionsnummer__c,
                                                Product__r.abda_mwst_knz__c,
                                                Abrechnungsstatus_Krankenkasse__c
                                                FROM Delivery_Lines__r) 
                                            FROM Delivery_Note__c  
                                            WHERE id IN: dnIdSet ];
             
        if((dnList != null) && (dnList.size() > 0)) {
            // neu
            for(Delivery_Note__c dn : dnList) {
                List<Invoice_Line__c> tempilList = new List<Invoice_Line__c>();
                decimal cbMaxPrice = invoiceHelper.getMaxCuraboxPrice(dn.Delivery_date__c);
                curaboxPriceResult = invoiceHelper.computeAdditionalPrice(dn, cbMaxPrice, plMap);
                invoiceHelper.deliveryNotePrepared deliveryNotePrepared = invoiceHelper.prepareDeliveryNote(dn, curaboxPriceResult);
                // Invoice
                for(id dlid : deliveryNotePrepared.lineMap.keySet()) {
                    Invoice_Line__c il = new Invoice_Line__c(Contact__c =dn.Contact__c, Delivery_Line__c=dlid);                                
                    il.Beihilfeanteil__c = deliveryNotePrepared.lineMap.get(dlid).beihilfe;
                    il.Gesamtpreis_Brutto__c = deliveryNotePrepared.lineMap.get(dlid).posPrice;
                    il.Zuzahlung__c = deliveryNotePrepared.lineMap.get(dlid).zuzahlung * deliveryNotePrepared.lineMap.get(dlid).quantity;
                    il.Invoice__c = createReadInvoice(deliveryNotePrepared.lineMap.get(dlid).Productgroup, medifox);
                    if(il.Invoice__c == null) {
                        // break for all del. lines
                        tempilList.clear();
                        break;
                    }
                    tempilList.add(il);   

                    csvMap.put(dlid, deliveryNotePrepared.lineMap.get(dlid).CSV_Line);                
                } 

                // Summe + Sonderregeln
                dnMap.put(dn.id, deliveryNotePrepared);

                // invoice lines for insert
                if(!tempilList.isEmpty()) {
                    ilList.addAll(tempilList);
                }
            }
            // neu ende
        } // if dnList
        // insert newinvoice lines
        Database.SaveResult[] srList = Database.insert(ilList, false);
        Set<id> newIlIdSet = new Set<id>();
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {  
                newIlIdSet.add(sr.getId());
            }
        }    
        // update dl - csv_line, Abrechnungsstatus_Krankenkasse__c
        // update dn - Status, Billing_on, csv_block (VS, VO und ZZ Zeilen für CSV)  

        if(!newIlIdSet.isEmpty()) {
            List<Invoice_Line__c> ilOkList = [SELECT id, Delivery_Line__c, Delivery_Line__r.Delivery_Note__c, Invoice__r.Name 
                                                      FROM Invoice_Line__c
                                                      WHERE id IN : newIlIdSet];
            if((ilOkList != null) && (ilOkList.size() > 0)) {
                for(Invoice_line__c il : ilOkList) {
                    dnOKidSet.add(il.Delivery_Line__r.Delivery_Note__c);
                    dlOkidSet.add(il.Delivery_Line__c);
                    ivnMap.put(il.Delivery_Line__c, il.Invoice__r.Name);
                }
            }
            system.debug('######## ivnMap=' + ivnMap);
            // Delivery Lines update Abrechnungsstatus
            String genVon = '';
            String genNummer = '';

            if(!dlOKidSet.isEmpty()) {
                List<Delivery_Line__c> dl2updList = [SELECT id, CSV_Line__c, Abrechnungsstatus_Krankenkasse__c
                                                        FROM Delivery_Line__c WHERE id IN : dlOKidSet];
                if((dl2updList != null) && (dl2updList.size() > 0)) {
                    for(Delivery_Line__c dl : dl2updList) {
                        if(csvMap.containsKey(dl.id)) {
                            dl.CSV_Line__c = csvMap.get(dl.id);
                            dl.Abrechnungsstatus_Krankenkasse__c = 'Abgerechnet über AS-B';
                        }
                        else {
                            dl.Abrechnungsstatus_Krankenkasse__c = 'Kostenfreie Lieferung';
                        }
                    }
                    srList = Database.update(dl2updList, false);
                }                
            }            
            // Delivery note postprocessing
            if(!dnOKidSet.isEmpty()) {
                List<Delivery_Note__c> dn2updList = [SELECT id, Name, Billing_on__c, Status__c, csv_block__c, Delivery_text__c, Kunde_Zuzahlung_befreit__c,
                                                            Contact__c, Contact__r.firstname, Contact__r.lastname, Contact__r.Salutation,
                                                            Contact__r.Versicherungsnummer__c, Contact__r.Birthdate, Contact__r.Kranken_Pflegekasse__r.IK_Nummer__c,
                                                            Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_54__c, Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_51__c, 
                                                            Contact__r.Zuzahlungsbefreit_Nein__c,  CSV_Line_summe__c, invoice_numbers__c,
                                                            contact__r.MailingStreet, Contact__r.MailingCity, Contact__r.MailingPostalCode,
                                                            DeliveryAddress__c, DeliveryAddress__r.Street__c, DeliveryAddress__r.Postal_Code__c,  DeliveryAddress__r.City__c,
                                                            totalAdditionalPrice__c, Actual_Amount__c, 
                                                            (SELECT id, Abrechnungsstatus_Krankenkasse__c, Order_line__r.Order__r.Genehmigt_von__c, order_line__r.Order__r.Nach_Paragraph__c FROM Delivery_Lines__r)  
                                                        FROM Delivery_Note__c WHERE id IN : dnOKidSet];
                if((dn2updList != null) && (dn2updList.size() > 0)) {
                    // Genehmigung
                    set<id> ctSet = new set<id>();
                    for(Delivery_Note__c dn : dn2updList) {
                        ctSet.add(dn.Contact__c);
                    }
                    gen54Map = readGenMap(ctSet, '54');
                    gen51Map = readGenMap(ctSet, '51');
                    gen5xMap = readGenMap(ctSet, '5X');

                    for(Delivery_Note__c dn : dn2updList) {
                        if(dn.Delivery_text__c != null) {
                            invoiceHelper.deliveryNotePrepared deliveryNotePrepared = dnMap.get(dn.id);
                            dn.Actual_Amount__c = deliveryNotePrepared.totalPrice;
                            dn.totalAdditionalPrice__c = deliveryNotePrepared.totalAdditionalPrice;
                            genVon = '';
                            genNummer = '';
                            dn.Billing_on__c = date.today();
                            // gemischte LS
                            // if(dn.Delivery_text__c.Contains(' + ')) {
                                string invoiceNumbers = null;
                                boolean notAll = false;
                                for(Delivery_Line__c dl: dn.Delivery_Lines__r) {
                                    if(dl.Abrechnungsstatus_Krankenkasse__c.Contains('abrechenbar')) {
                                        notAll = true;
                                        system.debug('####### notAll=' + notAll + ' dlid=' + dl.id + ' ' + dl.Abrechnungsstatus_Krankenkasse__c);
                                    } 
                                    System.debug('#####alex500 dl.id=' + dl.id);
                                    if(ivnMap.ContainsKey(dl.id)) {
                                        System.debug('#####alex501 dl.id=' + dl.id);
                                        if(invoiceNumbers == null) {
                                            invoiceNumbers = ivnMap.get(dl.id);
                                            System.debug('#####alex502 invoiceNumbers=' + invoiceNumbers);
                                        }
                                        else {
                                            System.debug('#####alex503 invoiceNumbers=' + invoiceNumbers + ' ivnMap.get(dl.id)' + ivnMap.get(dl.id));
                                            if(!invoiceNumbers.contains(ivnMap.get(dl.id))) {
                                                invoiceNumbers += ' ' + ivnMap.get(dl.id);
                                            }
                                        }
                                    }
                                }
                                system.debug('###########alex505 dn=' + dn.name + ' invoiceNumbers='  + invoiceNumbers);
                                dn.invoice_numbers__c = invoiceNumbers;
                                if(notAll) {
                                    dn.Status__c = 'teilweise abgerechnet';
                                }
                                else {
                                    dn.Status__c = 'abgerechnet';
                                }
                            // sonderregel
                            if(deliveryNotePrepared.csvLineSumme != '') {
                                sonderRegelMap.put(dn.id, deliveryNotePrepared.csvLineSumme);
                            }  
                            dn.csv_SU__c = deliveryNotePrepared.csv_SU;
                            dn.csv_KUWV_SU__c = deliveryNotePrepared.csv_KUWV_SU;

                            if(dn.Delivery_text__c.containsIgnoreCase('CB')) {
                                Curabox_Genehmigung__c gn54 = gen54Map.get(dn.Contact__c); 
                                if(gn54 != null) {
                                    if(gn54.genehmigt_ab__c != null) {
                                        genVon = gn54.genehmigt_ab__c.format();
                                    }   
                                    if(gn54.Genehmigungsnummer__c != null) {
                                        genNummer = gn54.Genehmigungsnummer__c;
                                    }                               
                                }
                                else {
                                    Curabox_Genehmigung__c gn5X = gen5XMap.get(dn.Contact__c); 
                                    if(gn5X != null) {
                                        if(gn5X.genehmigt_ab__c != null) {
                                            genVon = gn5X.genehmigt_ab__c.format();
                                        }   
                                        if(gn5X.Genehmigungsnummer__c != null) {
                                            genNummer = gn5X.Genehmigungsnummer__c;
                                        }                               
                                    }                           
                                }
                                dn.CSV_block__c = makeCSVblock(dn, genVon, genNummer);
                            }
                            if(dn.Delivery_text__c.containsIgnoreCase('KUWV')) {
                                Curabox_Genehmigung__c gn51 = gen51Map.get(dn.Contact__c); 
                                if(gn51 != null) {
                                    if(gn51.genehmigt_ab__c != null) {
                                        genVon = gn51.genehmigt_ab__c.format();
                                    }   
                                    if(gn51.Genehmigungsnummer__c != null) {
                                        genNummer = gn51.Genehmigungsnummer__c;
                                    }                               
                                }  
                                else {
                                    Curabox_Genehmigung__c gn5XX = gen5XMap.get(dn.Contact__c); 
                                    if(gn5XX != null) {
                                        if(gn5XX.genehmigt_ab__c != null) {
                                            genVon = gn5XX.genehmigt_ab__c.format();
                                        }   
                                        if(gn5XX.Genehmigungsnummer__c != null) {
                                            genNummer = gn5XX.Genehmigungsnummer__c;
                                        }                               
                                    }                           
                                }                          
                                dn.csv_block_KUWV__c = makeCSVblock(dn, genVon, genNummer);
                            }

                        }
                        else {
                             errorList.add('Error ' + dn.name + ' Please check delivery text.');
                        }
                    }
                    totalDN = dn2updList.size();
                    srList = Database.update(dn2updList, false);
                }                
            }
        }
    }

    @testVisible private String makeCSVblock(Delivery_Note__c dn, String genVon, String genNummer) {
        // try {
            string anrede = ' ';
            if(dn.Contact__r.Salutation != null) {
                if((dn.Contact__r.Salutation.contains('Herr')) || (dn.Contact__r.Salutation.contains('Mr.'))) {
                    Anrede = 'h';
                }
                else {
                    Anrede = 'f';
                }
            }
            string gebDat = '01.01.2000';
            if(dn.Contact__r.Birthdate != null) {
                gebDat = dn.Contact__r.Birthdate.format();
            } 
            string versNummer = '';
            if(dn.Contact__r.Versicherungsnummer__c != null) {
                versNummer =  dn.Contact__r.Versicherungsnummer__c;
            }               
            else {
                if(dn.Contact__r.Birthdate != null) {
                    versNummer = datetime.newInstance(dn.Contact__r.Birthdate, Time.newInstance(0, 0, 0, 0)).format('ddMMYYYY');
                }
                else {
                    versNummer = dn.Contact__r.lastname;  
                }                   
            }
            // Sonderregelung 51 / 54
            if(dn.Delivery_text__c.containsIgnoreCase('KUWV')) {
                if(dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_51__c != null) {
                    if(dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_51__c.contains('Genemigungsnummer')) genNummer = '';
                    if(dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_51__c.contains('Genehmigt ab')) genVon = '';
                }
            } 
            else
            {
                if(dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_54__c != null) {
                    if(dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_54__c.contains('Genemigungsnummer')) genNummer = '';
                    if(dn.Contact__r.Kranken_Pflegekasse__r.Abrechnung_gen_daten_54__c.contains('Genehmigt ab')) genVon = '';
                }
            }
            String plz = dn.Contact__r.MailingPostalCode;
            if(plz != null) {
                if(plz.trim().length() < 5) {
                    plz = '0' + plz;
                }
            }
            else {
                plz = ' ';
            }

            String csvstring = '\tHILFSMITTEL\t' + dn.Name + '\t\t\t\r\n';
                    csvstring += 'VS\t' + dn.Contact__r.Kranken_Pflegekasse__r.IK_Nummer__c;
                    csvstring += '\t' + versNummer;
                    csvstring += '\t' + '50001';
                    csvstring += '\t' + dn.Contact__r.lastname;    
                    csvstring += '\t' + dn.Contact__r.firstname;    
                    csvstring += '\t' + dn.contact__r.MailingStreet;
                    csvstring += '\t' + plz;
                    csvstring += '\t' + dn.Contact__r.MailingCity;
                    csvstring += '\t' + anrede;
                    csvstring += '\t' + gebDat;
                    csvstring += + '\r\n';

                    csvstring += 'VO\t\t\t\t';
                    csvstring += genVon;
                    csvstring += '\t';
                    csvstring += genNummer  + '\r\n';
                    if(dn.Delivery_text__c.containsIgnoreCase('KUWV') && (dn.Contact__r.Zuzahlungsbefreit_Nein__c)) {
                        csvstring += 'ZZ\tJa\r\n';
                    }
                    else {
                        csvstring += 'ZZ\tNein\r\n';
                    }                   
            return csvstring;
        // }
        // catch (System.Exception e) {
        //     System.debug('############alex900' + e);
        //     return null;
        // }
    }

    // Invoice interface for batch
    public Map<String, id> getIvMap() {
        return ivMap;
    }

    public void setIvMap(Map<String, id> ivMap) {
        this.ivMap = ivMap;
    }

    @TestVisible private id createReadInvoice(String pg, boolean medifox) {
        id ivid = null;
        if(pg == '51') {
            if(ivMap.containsKey('KUWV')) {
                return ivMap.get('KUWV');
            }
            else {
                ivid = createNewInvoice(true, medifox);
                ivMap.put('KUWV', ivid);
            }
        }
        else {
            if(ivMap.containsKey('Curabox')) {
                return ivMap.get('Curabox');
            }
            else {
                ivid = createNewInvoice(false, medifox);
                ivMap.put('Curabox', ivid);
            }
        }
        return ivid;
    }

    @TestVisible private id createNewInvoice(boolean kuwv, boolean medifox) {
        Invoice__c iv = new Invoice__c(Account__c = asbId);
        if(medifox) {
            iv.Kostenstelle__c = '4001';
            iv.Erloeskonto__c =  '4401';
        }
        else {
            iv.Kostenstelle__c = '4000';
            iv.Erloeskonto__c =  '4400';
        }
        if(kuwv) {
            iv.Invoice_text__c = 'KUWV';
        }
        else {
            iv.Invoice_text__c = 'Curabox';
        }
        if(medifox) {
            iv.Invoice_text__c += ' Medifox';
        }
        else {
            iv.Invoice_text__c += ' Standard';
        }
        iv.Buchungstext__c = 'KK-Abrechnungsbeleg';
        Database.SaveResult sr = Database.insert(iv, false); 
        if(sr.isSuccess()) {
            return sr.getId();
        }    
        else {
            return null;
        }
    }

    public void recreateCSV(String Rechnungen) {
        string[] rgNamen = new list<string>();
        if(rechnungen.contains(',')) {
            rgNamen = rechnungen.split(',');
        }
        else {
            rgNamen.add(rechnungen); 
        }   
        for(string rechnung : rgNamen) {
            createCSVfiles(rechnung.Trim());
        }        
    }

    public void createCSVfiles(String rgName) {
        String csvGes, csvPrivat;
        string maNummerMedifox = '2183';
        string maNummerWebcare = '2182';
        String attachmentName = '';    
        string betreff = '';
        try {
            maNummerMedifox = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerMedifox__c;
            maNummerWebcare = AB_KK__c.getInstance('AB_KK_Einstellungen').maNummerWebcare__c;
        }
        catch (System.Exception e) {}  

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
    
        List<Messaging.Emailfileattachment> attmList = new List<Messaging.Emailfileattachment>();

        List<invoice__c> ivList = [SELECT id, Name, invoice_text__c, csv_created__c FROM invoice__c WHERE Name = :  rgName];
        if((ivList != null) && (ivList.size() >0 )) {
            string[] splits = ivList[0].invoice_text__c.split(' ');
            system.debug('#############alwx8801 ' + splits);
            system.debug('#############alwx8802 ' + rgName);
            system.debug('#############alwx8803 ' + maNummerWebcare);
            if(splits[1] == 'Standard') {
                csvGes = createCSVstring(rgName, maNummerWebcare, splits[0], false);
                csvPrivat = createCSVstring(rgName, maNummerWebcare,  splits[0], true);
            }
            else {
                csvGes = createCSVstring(rgName, maNummerMedifox, splits[0], false);
                csvPrivat = createCSVstring(rgName, maNummerMedifox, splits[0], true);
            }
            System.debug('########alex7000 csvGes=' + csvGes);
            System.debug('########alex7001 csvPrivat=' + csvPrivat);
            betreff = 'Abrechnung_' + rgName + '_' + splits[1] + '_' + date.today().format();
            if(csvGes != null) {
                Blob csvAtt = blob.valueOf(csvGes);
                attachmentName = 'Abrechnung_' + rgName + '_' + splits[0] + '_' + splits[1]  + '_Gesetzlich_' + date.today().format() + '.csv';
                Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                csvAttc.setFileName(attachmentName);
                csvAttc.setBody(csvAtt);
                attmList.add(csvAttc);                      
            }          
            if(csvPrivat != null) {
                Blob csvAttP = blob.valueOf(csvPrivat);
                attachmentName = 'Abrechnung_' + rgName + '_' + splits[0] + '_' + splits[1]  + '_Privat_' + date.today().format() + '.csv';
                Messaging.EmailFileAttachment csvAttcp = new Messaging.EmailFileAttachment();
                csvAttcp.setFileName(attachmentName);
                csvAttcp.setBody(csvAttP);
                attmList.add(csvAttcp);                      
            } 
            if(!attmList.isEmpty()) {
                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                String[] toAddress =  toAddr.split(','); 
                if(toCC != null) {                  
                    String[] toCcAddress =  toCC.split(',');  
                    mail.setCcAddresses(toCcAddress);
                }
                mail.setToAddresses(toAddress);

                mail.setSubject(betreff);
                
                mail.setFileAttachments(attmList);
                mail.setPlainTextBody(PlainTextBody); 
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });  
                ivList[0].csv_created__c = true;
                update ivList;
            }
        }
    }

    @testVisible private String createCSVstring(String rgName, string maNummer, String pg, boolean privat) {
        String rgSearchName = '%' + rgName + '%';
        set<String> unterpunkt = new set<String>();
        if(privat) {
            unterpunkt.add('privat');
        }
        else {
            unterpunkt.add('gesetzlich');
            unterpunkt.add('Sozialamt');
        }
        system.debug('#############alwx8804 ' + rgName);
        String csvString = 'VERSION\t1.2\r\nMA' + '\t' + maNummer + '\r\n';

        List<delivery_note__c> dnList = [SELECT id, name, csv_block__c, csv_block_KUWV__c, CSV_Line_summe__c, csv_SU__c, csv_KUWV_SU__c, delivery_text__c, 
                                                (SELECT id, CSV_Line__c, order_line__r.Order__r.Nach_Paragraph__c, order_line__r.Order__r.description__c FROM delivery_lines__r) 
                                            FROM Delivery_Note__c
                                            WHERE invoice_numbers__c LIKE : rgSearchName
                                            AND Contact__r.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c IN : unterpunkt
                                            ORDER BY Contact__r.Kranken_Pflegekasse__r.IK_Nummer__c, name];
        if((dnList != null) && (dnList.size() > 0)) {
            integer lineNumber = 1;
            for(Delivery_Note__c dn : dnList) {
                String csv_block = '';
                if(pg == 'KUWV') {
                    if(dn.csv_block_KUWV__c != null) {
                        csv_block = dn.csv_block_KUWV__c.replace(dn.Name, rgName);
                    }
                    else {
                        break;
                    }
                }
                else {
                    if(dn.csv_block__c != null) {
                        csv_block = dn.csv_block__c.replace(dn.Name, rgName);
                    }
                    else {
                        break;
                    }
                }
                csvString += 'BA\t' + string.valueOf(lineNumber) + '\t' + csv_block + '\r\n'; 
                // hier if (aber nur 54!!!)
                if((dn.CSV_Line_summe__c != null) && (pg != 'KUWV')) {
                    csvString += dn.CSV_Line_summe__c + '\r\n';
                }
                else {
                    for(Delivery_Line__c dl : dn.Delivery_Lines__r) {
                        // hier PG
                        if(pg == 'KUWV') {
                            if(dl.Order_line__r != null) {
                                if(dl.Order_line__r.Order__r.description__c == 'KUWV') {
                                    csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                            else {
                                if(dn.delivery_text__c.startsWith('KUWV') ) {
                                    csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                        }
                        else {
                            if(dl.Order_line__r != null) {
                                if(dl.Order_line__r.Order__r.description__c.startsWith('CB')) {
                                    csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                            else {
                                if(dn.delivery_text__c.startsWith('CB') ) {
                                    csvString += dl.CSV_Line__c + '\r\n';
                                }
                            }
                        }
                    }
                }
                // hir die summe
                if(pg == 'KUWV') {
                    csvString += dn.csv_KUWV_SU__c;
                }
                else {
                    csvString += dn.csv_SU__c;
                }
                csvString += '\r\n';
                lineNumber++;
            }
        }
        else {
            return null;
        }
        return csvString;
    }

    public Map<id, Curabox_Genehmigung__c> readGenMap(set<id> ctSet, string pg) {
        Map<id, Curabox_Genehmigung__c> gnMap = new Map<id, Curabox_Genehmigung__c>();
        List<Curabox_Genehmigung__c> gnList = [SELECT id, Contact__c, Genehmigungsnummer__c, genehmigt_ab__c
                                                            FROM Curabox_Genehmigung__c 
                                                            WHERE Contact__c IN : ctSet
                                                            AND Nach_Paragraph__c = : pg
                                                            AND Status__c = 'Bewilligung'
                                                            AND (genehmigt_ab__c <= today AND (genehmigt_bis__c >= today OR unbefristet_genehmigt__c = true))
                                                            ORDER BY createddate desc];
        if((gnList != null) && (gnList.size() > 0)) {
            for(Curabox_Genehmigung__c gn : gnList) {
                if(!gnMap.containsKey(gn.Contact__c)) {
                    gnMap.put(gn.Contact__c, gn);
                }
            }
        }
        return gnMap;
    }

    public list<string> getErrorList() {
        return errorList;
    }
    
    public integer getErrorListSize() {
        if(errorList != null) {
            return errorList.size();
        }
        else return 0;
    }

    public integer getTotalDN() {
        return totalDN;
    }

    // Diese Methoden werden nur aus kompartibilitätsgründe hier gelassen
    @TestVisible private decimal computeZuzahlung (decimal preis, decimal menge, string method) {
        try {
            decimal zz = 0.00;
            decimal minZZ = 0.00;
            if(method == null) {
                return zz;
            }
            if(method.Contains('mindestens')) {
                minZZ = 5.00;
            }
            if (method.Contains('pro Artikel')) {
                decimal proArtikel = (preis / 10).setScale(2, RoundingMode.HALF_UP);
                if(proArtikel > 10.0) {
                    proArtikel = 10.00;
                }
                if(proArtikel < minZZ) {
                    proArtikel = minZZ;
                } 
                zz = (proArtikel * menge).setScale(2, RoundingMode.HALF_UP); 
            }
            else {
                zz = ((preis * menge) / 10).setScale(2, RoundingMode.HALF_UP); 
                if(zz > 10) {
                    zz = 10.00;
                }
            }
            return zz;
        }
        catch(System.Exception e) {
            // ToDo: Errorhandling
            return 0.00;
        }
    }

}