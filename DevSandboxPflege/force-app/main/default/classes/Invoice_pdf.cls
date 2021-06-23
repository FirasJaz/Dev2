//*****************************************************************************************************************************
// Erstellt 28.10.2015 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//Magento shop. Senden ScopeVisio request und eMali an Kunde
//
//
//****************************************************************************************************************************
//Änderungen:
//
//  27.10.2016  AM  Fehler - es fehlt die (callout=true) bei @future                             
//****************************************************************************************************************************

public class Invoice_pdf {

    private Rechnung__c rechnung;
    private id newID = null;
    private mail_template_holen mth {get; set;}
    
    
    // dummy constructor
    public Invoice_pdf(){
    }

    public Invoice_pdf(Rechnung__c r){
        rechnung = r;
    }
    
    public Invoice_pdf(ID  lieferschein_id){
        Invoice_generiren ig = new Invoice_generiren(lieferschein_id);
        List<Rechnung__c> RGlist = ig.getInsertedRgList();
        if(RGlist != null){
            rechnung = RGlist.get(0);
        }
        system.debug ('##################### Mansi:: Invoice_pdf::'+ rechnung); 
        try{        
          if(!rechnung.PDF_generiert__c){
              system.debug ('##################### Mansi:: if(!rechnung.PDF_generiert__c)::'+ rechnung.PDF_generiert__c);
              string rg_pdf_name = rechnung.Rechnungsnummer_shop__c;
              if(rg_pdf_name == null) rg_pdf_name = rechnung.name;
              createAttAndSend(lieferschein_id, rechnung.id, rg_pdf_name);
              system.debug ('##################### alex901 sendRequest()');
              if (!runningInASandbox()) {
                  sendRequest(rechnung.id);
                  system.debug ('##################### alex902 sendRequest() ende');
              }
              else {
                  system.debug ('##################### alex912 Sandbox daher kein sendRequest()');
              }
          }
        }catch (System.DmlException e) {                 
            system.debug ('##################### Mansi:: insert attachment error::'+ e);         
        }
    }
    
    public static void sendInvoiceEmail(ID lieferschein_id, ID rechnung_id, Attachment attach){
        try {
            Lieferschein__c tmpLs = [select Id, Kunde__c, Kunde__r.e_mail__c  from Lieferschein__c where Id = :lieferschein_id];
            id auid = null;
            list<Lieferscheinposition__c> lpList = [SELECT Auftragsposition__r.Auftrag__c FROM Lieferscheinposition__c WHERE Lieferschein__c = :lieferschein_id];
            if((lpList != null) && (lpList.size() > 0)) {
                for(Lieferscheinposition__c LP : lpList) {
                    if(LP.Auftragsposition__r.Auftrag__c != null) {
                        auid = LP.Auftragsposition__r.Auftrag__c;
                        break;
                    }
                }
            }
        
        
            list<EmailTemplate> etList = [SELECT id, Name FROM EmailTemplate WHERE name = 'Versand Shop Rechnung an Kunden'];
            id etid = null;
            if((etList != null) && (etList.size() > 0)) { 
                etid = etList[0].id;
            }
            ID owID = null;
            List<OrgWideEmailAddress> owa = [select id, Address, DisplayName from OrgWideEmailAddress WHERE DisplayName = 'Pflege.de Kundenservice' limit 1];
            owID = owa[0].id;       
            mail_template_holen mth = new mail_template_holen(auid, tmpLs.Kunde__c, etid); 
        
            
            String subject = 'Rechnung';
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
            
            //TODO change mailTo to for test 'ziaei@klosesrockepartner.de';
            String mailTo = tmpLs.Kunde__r.e_mail__c; 
            
            String[] toAddress = new String[] {mailTo};
            mail.setToAddresses(toAddress);
            
            String[] bCC = new String[] {'rechnung@pflege.de'};
            mail.setPlainTextBody(mth.getPlaintextBody());
            mail.setHTMLBody(mth.getHTMLbody());
            mail.setSubject(mth.getBetreff());
            mail.setOrgWideEmailAddressId(owID);
            mail.setBccAddresses(bCC);
            Messaging.EmailFileAttachment pdfAttach = new Messaging.EmailFileAttachment() ;
            pdfAttach.setFileName(attach.Name);
            pdfAttach.setBody(attach.Body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {pdfAttach});
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                addTask(subject +' per Email versandt', subject +' per Email versandt an Kunde (' +  mailTo + ')', tmpLs.Kunde__c);
            }
            catch(System.Exception e) {
                system.debug('######################### SendMail Error e=' + e);
            }
        }
        catch (Exception e) {
            system.debug('######################### Mansi Error e=' + e);
        }   
    }
    
    public static void addTask(String subject, String description, Id Kunde_id){ 
       RecordType rt = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'Shop' limit 1];
      task newTask = new Task(ActivityDate = Date.today(),
                                    Description = description,      
                                    Priority = 'Normal',
                                    Status = 'Geschlossen',
                                    Subject = subject,            
                                    WhatId = Kunde_id,
                                    RecordTypeId = rt.id,
                                    IsReminderSet = false);
         // Insert the new Task
         try {
             system.debug('######################### Mansi task=' + newTask);
            insert newTask;
         }
         catch (system.exception e) {
            system.debug('######################### Mansi insert task error=' + e);                
         }
    }
    
    @future(callout=true)
    public static void createAttAndSend(Id lieferschein_id, Id RGID, string RG_Name) {
        string ret = null;
        string rgAccount = null;
        string rgCustomer = 'c';
        string rgUser = null;
        string rgPass = null;
        string rgOrganisation = null;       
        Datetime curDate = Datetime.now();
        string datumHeute = curDate.format('dd.MM.yyyy');       
        CompanyInfo__c FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            rgAccount = FirmenInfo.svAccount__c;
            rgCustomer = FirmenInfo.svCustomer__c;
            rgUser = FirmenInfo.svUser__c;
            rgPass = FirmenInfo.svPass__c;
            rgOrganisation = FirmenInfo.svOrganisation__c;
        }       
        PageReference RG_PDF = new PageReference('/apex/SRG_nur_anzeigen?id=' + string.valueOf(RGId));
        Blob pdf_blob = RG_PDF.getContent(); 
        Attachment pdf_attach = new Attachment();              
        pdf_attach.body = pdf_blob;              
        pdf_attach.Name = 'Rechnung_' + RG_Name +'.pdf';              
        pdf_attach.ParentId = RGId; 
        try {
            insert pdf_attach;
            list<Rechnung__c> rgList = [SELECT id, PDF_generiert__c, svXML__c, 
                                                name, Gesamtpreis__c, Rechnung_text__c, 
                                                Kunde__r.komb_Name__c, Kunde__r.Name__c, Kunde__r.Vorname__c, 
                                                Lieferschein__r.name,
                                                CreatedDate, svResponse__c, svErfolg__c
                                        FROM Rechnung__c 
                                        WHERE id = :RGId];
            if((rgList != null) && (rgList.size() == 1)) {
                Rechnung__c RGu = rgList[0];
                RGu.PDF_generiert__c = true;                
                update RGu;
            }
            sendInvoiceEmail(lieferschein_id, RGID, pdf_attach);
        }
        catch (System.Exception e) {}        
    }
   

    @future(callout=true)
    public static void sendRequest(Id RGID) {
        system.debug ('##################### alex921 start send');
        string rgAccount = null;
        string rgCustomer = 'c';
        string rgUser = null;
        string rgPass = null;
        string rgOrganisation = null;   
        string rgSummaryAccount = null;
        string rgDebitor = null;        
        Datetime curDate = Datetime.now();
        string datumHeute = curDate.format('dd.MM.yyyy');       
        CompanyInfo__c FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            rgAccount = FirmenInfo.svAccount__c;
            rgCustomer = FirmenInfo.svCustomer__c;
            rgSummaryAccount = FirmenInfo.svSummaryAccount__c;
            rgDebitor = FirmenInfo.svDebitor__c;
            rgUser = FirmenInfo.svUser__c;
            rgPass = FirmenInfo.svPass__c;
            rgOrganisation = FirmenInfo.svOrganisation__c;
        }   
            list<Rechnung__c> rgList = [SELECT id, svXML__c, 
                                                name, Gesamtpreis__c, Rechnung_text__c, 
                                                Kunde__r.komb_Name__c, Kunde__r.Name__c, Kunde__r.Vorname__c, 
                                                Lieferschein__r.name,
                                                CreatedDate, svResponse__c, svErfolg__c,
                                                Rechnungsnummer_shop__c
                                        FROM Rechnung__c 
                                        WHERE id = :RGId];
            if((rgList != null) && (rgList.size() == 1)) {
                
                set<id> rgidSet = new set<id>();
                map<id, string> paymentMethodMap = new map<id, string>();
                for(Rechnung__c RG : rgList) {
                    rgidSet.add(RG.id); 
                }
                list<Rechnungsposition__c> rpList = [SELECT  Rechnung__c, 
                                                            Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_payment_method_c__c
                                                        FROM Rechnungsposition__c 
                                                        WHERE Rechnung__c IN :rgidSet];
                if((rpList != null) && (rpList.size() > 0)) {
                    for(Rechnungsposition__c RP : rpList) {
                        if(RP.Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_payment_method_c__c != null) paymentMethodMap.put(RP.Rechnung__c, RP.Lieferscheinposition__r.Auftragsposition__r.Auftrag__r.Magento_payment_method_c__c);
                    }
                }               
                
                
                Rechnung__c RGu = rgList[0];        

                    Xmlstreamwriter xmlW = new Xmlstreamwriter();
                    xmlW.writeStartDocument('utf-8','1.0');        
                    xmlW.writeStartElement('SOAP-ENV','Envelope', 'SOAP-ENV');
                    xmlW.writeAttribute(null,null,'xmlns:SOAP-ENV','http://schemas.xmlsoap.org/soap/envelope/');
                    xmlW.writeEmptyElement('SOAP-ENV','Header', 'SOAP-ENV');
                    xmlW.writeStartElement('SOAP-ENV','Body', 'SOAP-ENV');

                    xmlW.writeStartElement('ns1','Envelope', 'ns1');
                    xmlW.writeAttribute(null,null,'xmlns:ns1','http://www.scopevisio.com/');        
                    
                    xmlW.writeStartElement(null,'authn', null);
                        xmlW.writeStartElement(null,'customer', null);
                            xmlW.writeCharacters(rgCustomer);
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'user', null);
                            xmlW.writeCharacters(rgUser);
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'pass', null);
                            xmlW.writeCharacters('####################');
                        xmlW.writeEndElement(); 
                        xmlW.writeStartElement(null,'language', null);
                            xmlW.writeCharacters('de_DE');
                        xmlW.writeEndElement(); 
                        xmlW.writeStartElement(null,'organisation', null);
                            xmlW.writeCharacters(rgOrganisation);
                        xmlW.writeEndElement();             
                    xmlW.writeEndElement(); 
                    
                    xmlW.writeEmptyElement(null,'args', null);
                    
                    xmlW.writeStartElement(null,'data', null);
                        xmlW.writeStartElement(null,'config', null);
                            xmlW.writeStartElement(null,'adjustVatKey', null);
                                xmlW.writeCharacters('true');
                            xmlW.writeEndElement();                             
                            xmlW.writeStartElement(null,'autoCreateTax', null);
                                xmlW.writeCharacters('true');
                            xmlW.writeEndElement();                             
                            xmlW.writeStartElement(null,'skipDuplicateDocumentNumbers', null);
                                xmlW.writeCharacters('false');
                            xmlW.writeEndElement(); 
                        xmlW.writeEndElement();  // config                  
                    
                        xmlW.writeStartElement(null,'data', null);
                        for(integer i = 0 ; i < rgList.size(); i++ ) {
                            xmlW.writeStartElement(null,'record', null);
                                xmlW.writeStartElement(null,'postingdate', null);
                                    xmlW.writeCharacters(datumHeute);
                                xmlW.writeEndElement();                 
                                xmlW.writeStartElement(null,'documentdate', null);
                                    xmlW.writeCharacters(rgList[i].CreatedDate.format('dd.MM.yyyy'));
                                xmlW.writeEndElement();             
                                xmlW.writeStartElement(null,'documentnumber', null);
                                    xmlW.writeCharacters(string.valueOf(i));
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'externaldocumentnumber', null);
                                    xmlW.writeCharacters(rgList[i].Rechnungsnummer_shop__c);
                                xmlW.writeEndElement(); 

                                xmlW.writeStartElement(null,'account', null);
                                    xmlW.writeCharacters(rgDebitor);
                                xmlW.writeEndElement();     
                                xmlW.writeStartElement(null,'summaryaccount', null);
                                    xmlW.writeCharacters(rgSummaryAccount);
                                xmlW.writeEndElement();         
                                
                                xmlW.writeStartElement(null,'amount', null);
                                    xmlW.writeCharacters(ksgFunctions.formatCurrency(rgList[i].Gesamtpreis__c));
                                xmlW.writeEndElement(); 

                                xmlW.writeEmptyElement(null,'cancelDocument', null);
                                xmlW.writeEmptyElement(null,'foreigncurrencyamount', null);
                                xmlW.writeEmptyElement(null,'foreigncurrencycode', null);
                                xmlW.writeEmptyElement(null,'foreigncurrencyrate', null);
                                
                                xmlW.writeStartElement(null,'stext', null);
                                    xmlW.writeCharacters(rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c );
                                xmlW.writeEndElement();

                                xmlW.writeEmptyElement(null,'discountpercent1', null);
                                xmlW.writeEmptyElement(null,'discountperiod1', null);
                                xmlW.writeEmptyElement(null,'discountpercent2', null);
                                xmlW.writeEmptyElement(null,'discountperiod2', null);
                                xmlW.writeEmptyElement(null,'nettimelimit', null);
                                
                                xmlW.writeStartElement(null,'documentText', null);
                                    if(paymentMethodMap.containsKey(rgList[i].id)) {
                                        xmlW.writeCharacters(paymentMethodMap.get(rgList[i].id) + ' ' + rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c );
                                    }
                                    else {
                                        xmlW.writeCharacters(rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c );
                                    }
                                xmlW.writeEndElement(); 
                                    
                            xmlW.writeEndElement();
                            
                            // 2. Konto
                            xmlW.writeStartElement(null,'record', null);
                                xmlW.writeStartElement(null,'postingdate', null);
                                    xmlW.writeCharacters(datumHeute);
                                xmlW.writeEndElement();                 
                                xmlW.writeStartElement(null,'documentdate', null);
                                    xmlW.writeCharacters(rgList[i].CreatedDate.format('dd.MM.yyyy'));
                                xmlW.writeEndElement();             
                                xmlW.writeStartElement(null,'documentnumber', null);
                                    xmlW.writeCharacters(string.valueOf(i));
                                xmlW.writeEndElement();
                                xmlW.writeStartElement(null,'externaldocumentnumber', null);
                                    xmlW.writeCharacters(rgList[i].Rechnungsnummer_shop__c);
                                xmlW.writeEndElement(); 
                                xmlW.writeStartElement(null,'account', null);
                                    xmlW.writeCharacters(rgAccount);
                                xmlW.writeEndElement();     
                                
                                xmlW.writeStartElement(null,'amount', null);
                                    xmlW.writeCharacters('-' + ksgFunctions.formatCurrency(rgList[i].Gesamtpreis__c));
                                xmlW.writeEndElement(); 

                                xmlW.writeEmptyElement(null,'cancelDocument', null);
                                xmlW.writeEmptyElement(null,'foreigncurrencyamount', null);
                                xmlW.writeEmptyElement(null,'foreigncurrencycode', null);
                                xmlW.writeEmptyElement(null,'foreigncurrencyrate', null);
                                
                                xmlW.writeStartElement(null,'stext', null);
                                    xmlW.writeCharacters(rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c );
                                xmlW.writeEndElement();

                                xmlW.writeStartElement(null,'dimension_1', null);
                                    xmlW.writeCharacters('4200');
                                xmlW.writeEndElement();
                                
                                xmlW.writeEmptyElement(null,'discountpercent1', null);
                                xmlW.writeEmptyElement(null,'discountperiod1', null);
                                xmlW.writeEmptyElement(null,'discountpercent2', null);
                                xmlW.writeEmptyElement(null,'discountperiod2', null);
                                xmlW.writeEmptyElement(null,'nettimelimit', null);
                                
                                xmlW.writeStartElement(null,'documentText', null);
                                    if(paymentMethodMap.containsKey(rgList[i].id)) {
                                        xmlW.writeCharacters(paymentMethodMap.get(rgList[i].id) + ' ' + rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c );
                                    }
                                    else {
                                        xmlW.writeCharacters(rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c );
                                    }
                                xmlW.writeEndElement(); 
    
                            xmlW.writeEndElement();
                            
                        }                       
                        xmlW.writeEndElement(); // data 
                    
                    xmlW.writeEndElement(); // data 
                    
                    xmlW.writeEndElement(); 
                    
                    xmlW.writeEndElement(); 
                    xmlW.writeEndElement(); 
                    xmlW.writeEndDocument();        
                    RGu.svXML__c = xmlW.getXmlString(); 
                    RGu.Scope_visio__c = true;
                    xmlW.close();               
                // scopeVisio
                    string svXmlBody = RGu.svXML__c.replace('####################', rgPass);
                    HttpRequest req = new HttpRequest();
                    HttpResponse res = new HttpResponse();
                    Http http = new Http();             
                    req.setEndpoint('https://appload.scopevisio.com/api/soap/accounting/Journal.create');
                    req.setMethod('POST');
                    req.setCompressed(false);               
                    req.setHeader('Content-Type', 'text/xml;charset=UTF-8');  
                    req.setHeader('Content-length', string.valueOf(svXmlBody.length()));
                    req.setBody(svXmlBody);
                    try {
                        res = http.send(req);
                        System.debug('################res.getBody() =' + res.getBody());
                        RGu.svResponse__c = res.getBody();
                        if(RGu.svResponse__c.contains('<insertCount>1</insertCount>')) {
                            RGu.svErfolg__c = datetime.now();
                        }
                    } catch(System.CalloutException e) {
                        System.debug('################Callout error: '+ e);
                        RGu.svResponse__c = '################Callout error: '+ e;
                    }               
                
                update RGu;
                
            }
        system.debug ('##################### alex921 end send');
    }

    public Boolean runningInASandbox() {
        return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
   
     // wird nicht aufgerufen! Nur für Testabdeckung!!!  
        public class dummyZeile {
                
                        public String Rpos {get;set;}
                        public String Anzahl_Verpackungen {get;set;}
                        public String LsNr {get;set;}
                        public string th {get; set;}
                        public string thu {get; set;}
                        public string lDatum {get; set;}
                        public string stern {get; set;}
        }

// wird nicht aufgerufen! Nur für Testabdeckung!!!       
        public void setLeereZeilen() {
            List<dummyZeile> pZeilen = new List<dummyZeile>();
            dummyZeile dZeile = new dummyZeile();
            
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
            dZeile.Rpos = '. 1';
            dZeile.Anzahl_Verpackungen = '. ';
            dZeile.th = 'color:white;border:0px;';
            dZeile.thu = 'color:white;border:0px;';
            dZeile.lDatum = '1';  
            dZeile.stern = '1';  
            pZeilen.add(dZeile);  
        }  
}