//*****************************************************************************************************************************
// Erstellt 25.11.2015 von AM
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
// Nachsenden ScopeVisio request und eMali an Kunde
//
//
//****************************************************************************************************************************
//Änderungen:
//
//                             
//****************************************************************************************************************************

public class ksgInvokeScopevisioRequest {
    private boolean Aufruf = true;
    private list<Rechnung__c> rgList = new list<Rechnung__c>();
    private string svXmlBody {get; set;}
    private string rspBody = null;
    public CompanyInfo__c FirmenInfo {get; set;}

    private string rgAccount = null;
    private string rgCustomer = 'c';
    private string rgUser = null;
    private string rgPass = null;
    private string rgOrganisation = null;   
    private string rgSummaryAccount = null;
    private string rgDebitor = null;    

    public Integer noOfRecords{get; set;}
    public Integer size{get;set;}
    public integer counter=0;  //keeps track of the offset
    public integer list_size=20; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list   
    
    private id rgid = null;
    
    public ksgInvokeScopevisioRequest() {
        Aufruf = true;
        rgList.clear();            
        //for(Rechnung__c RG : (List<Rechnung__c>)setCon.getRecords()) { 
            //rgList.add(RG);
        //}
        //rgList = (List<Rechnung__c>)setCon.getRecords();
                    
    } 
    
    

    public ApexPages.StandardSetController setCon {
        get{
            if(setCon == null){
                size = list_size;
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                   [SELECT id, name, Gesamtpreis__c, Rechnung_text__c, Kunde__c,
                        Kunde__r.komb_Name__c, Kunde__r.Name__c, Kunde__r.Vorname__c,
                        Lieferschein__c, Lieferschein__r.name,
                        CreatedDate, Rechnungsnummer_shop__c, svErfolg__c
                    FROM Rechnung__c
                    WHERE Rechnungsnummer_shop__c != null                
                        ORDER BY svErfolg__c DESC NULLS first
                    LIMIT 1000]));
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }
    
    public list<Rechnung__c> getRgList() {
        return (List<Rechnung__c>)setCon.getRecords();
    }
    
    public PageReference  createRequest() {
        Aufruf = true; 
        rgid = id.valueOf(svID);
        Rechnung__c RG = [SELECT id, svErfolg__c, svResponse__c, svXML__c, Scope_visio__c 
                            FROM Rechnung__c 
                            WHERE id = :rgid LIMIT 1];
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        RG.svXML__c = createXmlInvoice();   
        RG.Scope_visio__c = true;
        svXmlBody = RG.svXML__c.replace('####################', rgPass);  
        
        req.setEndpoint('https://appload.scopevisio.com/api/soap/accounting/Journal.create');
        req.setMethod('POST');
        req.setCompressed(false);
        
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');  
        req.setHeader('Content-length', string.valueOf(svXmlBody.length()));
        

        req.setBody(svXmlBody);
        try {
            res = http.send(req);
            RG.svResponse__c = res.getBody();
            if(RG.svResponse__c.contains('<insertCount>1</insertCount>')) {
                RG.svErfolg__c = datetime.now();
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Request OK. Response: OK')); 
            }   
            else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Request OK. Response: ' + RG.svResponse__c)); 
            }
            try {
                update RG;
            }
            catch(System.Exception e) {
                System.debug('##########################alex999: update RG error='+ e);
            }

            return null;
        } catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
            rspBody = string.valueOf(e);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Callout error')); 
            return null;
        }  
            
    }

    public PageReference goBack() {
        Aufruf = true;
    
        return null;
    }

    public PageReference sendSV() {
        createRequest();
        rgid = null;
        return null;
    }
    
    public PageReference sendMailAnKunde() {
        rgid = id.valueOf(svID);
        id auid = null;
        id kdid = null;
        string rgName = null;
        String mailTo = null;
        try {
            list<Rechnungsposition__c> rpList = [SELECT  Kunde__c, Kunde__r.e_mail__c,
                                            Lieferscheinposition__r.Auftragsposition__r.Auftrag__c,
                                            Rechnung__r.name, Rechnung__r.Rechnungsnummer_shop__c
                                        FROM Rechnungsposition__c 
                                        WHERE Rechnung__c = :rgid];
            if((rpList != null) && (rpList.size() > 0)) {
                for(Rechnungsposition__c RP : rpList) {
                    if(RP.Lieferscheinposition__r.Auftragsposition__r.Auftrag__c != null) {
                        auid = RP.Lieferscheinposition__r.Auftragsposition__r.Auftrag__c;
                        kdid = RP.Kunde__c;
                        mailTo = RP.Kunde__r.e_mail__c;
                        if(RP.Rechnung__r.Rechnungsnummer_shop__c != null) {
                            rgName = RP.Rechnung__r.Rechnungsnummer_shop__c;
                        }
                        else {
                            rgName = RP.Rechnung__r.name;
                        }
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
            mail_template_holen mth = new mail_template_holen(auid, kdid, etid); 
        
            
            String subject = 'Rechnung';
            Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();

            String[] toAddress = new String[] {mailTo};
            mail.setToAddresses(toAddress);
            
            String[] bCC = new String[] {'rechnung@pflege.de'};
            mail.setPlainTextBody(mth.getPlaintextBody());
            mail.setHTMLBody(mth.getHTMLbody());
            mail.setSubject(mth.getBetreff());
            mail.setOrgWideEmailAddressId(owID);
            mail.setBccAddresses(bCC);
            
            attachment att = new attachment();
            list<attachment> attList = [SELECT id, body, name, parentid, ContentType FROM attachment WHERE parentid = : rgid];
            if((attList != null) && (attList.size() >0)) {
                att.name = rgName + '.PDF';
                att.body = attList[0].body;
                att.ContentType = attList[0].ContentType;
            }   
            
            Messaging.EmailFileAttachment pdfAttach = new Messaging.EmailFileAttachment() ;
            pdfAttach.setFileName(att.Name);
            pdfAttach.setBody(att.Body);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] {pdfAttach});
            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Mail mit PDF-Anhang gesendet an ' + mailTo)); 
            }
            catch(System.Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Fehler beim Senden eMail')); 
            }
            // addTask(subject +' per Email versandt', subject +' per Email versandt an Kunde (' +  mailTo + ')', tmpLs.Kunde__c);
        }
        catch (Exception e) {
            system.debug('######################### Mansi Error e=' + e);
        }       
        return null;
    }
    
    public boolean getAufruf(){
        return Aufruf;
    }
    
    public string getsvXmlBody(){
        return svXmlBody;
    } 

    public string getRspBody(){
        return rspBody;
    }   
    
    private string createXmlInvoice() {
        string ret = null;  
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
        
            rgList = [SELECT id, name, Gesamtpreis__c, Rechnung_text__c, Kunde__c,
                        Kunde__r.komb_Name__c, Kunde__r.Name__c, Kunde__r.Vorname__c,
                        Lieferschein__c, Lieferschein__r.name,
                        CreatedDate, Rechnungsnummer_shop__c, svErfolg__c
                        FROM Rechnung__c
                        WHERE id = : rgid];


    
        if((rgList != null) && (rgList.size() > 0)) {
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
                        xmlW.writeCharacters(paymentMethodMap.get(rgList[i].id) + ' ' + rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c);
                    }
                    else {
                        xmlW.writeCharacters(rgList[i].Kunde__r.Vorname__c + ' ' + rgList[i].Kunde__r.Name__c );
                    }
                xmlW.writeEndElement(); 
                
                xmlW.writeEmptyElement(null,'clearingLabel', null);
                
            xmlW.writeEndElement();
            
            // das 2. Konto

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
                
                xmlW.writeEmptyElement(null,'clearingLabel', null);
                
            xmlW.writeEndElement();         
            
        }   
        xmlW.writeEndElement(); 
        xmlW.writeEndElement(); 
        
        xmlW.writeEndElement(); 
        
        xmlW.writeEndElement(); 
        xmlW.writeEndElement(); 
        xmlW.writeEndDocument();        
        ret = xmlW.getXmlString(); 
        xmlW.close();  
        }       
        return ret;
    }
    
    public string svID {
        get;
        set {
            svID = value;
        }
        
        
    }
    
    public Boolean hasNext {
        get {
            return setCon.getHasNext();
        }
        set;
    }
    public Boolean hasPrevious {
        get {
            return setCon.getHasPrevious();
        }
        set;
    }
  
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
    
    public void first() {        
        setCon.first();
    }
  
    public void last() {        
        setCon.last();
    }
  
    public void previous() {       
        setCon.previous();
    }
  
    public void next() {        
        setCon.next();
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