public class ksgScopevisioRequest {
    public boolean Aufruf = true;
    public string svXmlBody {get; set;}
    public CompanyInfo__c FirmenInfo {get; set;}
    private string rgAccount = null;
    private string rgCustomer = 'c';
    private string rgUser = null;
    private string rgPass = null;
    private string rgOrganisation = null;
    private id rgid = null;
    
    private list<Rechnung__c> rgList = new list<Rechnung__c>();
    
    public ksgScopevisioRequest() {
        FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            rgAccount = FirmenInfo.svAccount__c;
            rgCustomer = FirmenInfo.svCustomer__c;
            rgUser = FirmenInfo.svUser__c;
            rgPass = FirmenInfo.svPass__c;
            rgOrganisation = FirmenInfo.svOrganisation__c;
        }
        Aufruf = true;
    } 

    public ksgScopevisioRequest(id rgid) {
        this.rgid = rgid;
        FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            rgAccount = FirmenInfo.svAccount__c;
            rgCustomer = FirmenInfo.svCustomer__c;
            rgUser = FirmenInfo.svUser__c;
            rgPass = FirmenInfo.svPass__c;
            rgOrganisation = FirmenInfo.svOrganisation__c;
        }        
        Aufruf = false;
    }   
    
    public PageReference sendRequest() {
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        
        req.setEndpoint('https://appload.scopevisio.com/api/soap/accounting/Journal.create');
        req.setMethod('POST');
        req.setCompressed(true);
        
        req.setHeader('Content-Type', 'text/xml;charset=UTF-8');  

        system.debug('#######alex001 ' + FirmenInfo);
        svXmlBody = createXmlInvoice();
        req.setBody(svXmlBody);
        try {
            res = http.send(req);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO, 'Request OK')); 
            System.debug('################res.getBody() =' + res.getBody());
            return null;
        } catch(System.CalloutException e) {
            System.debug('Callout error: '+ e);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Callout error')); 
            return null;
        }  
    }
    
    public void createRequest() {
        Aufruf = false;
        svXmlBody = createXmlInvoice();
        
        
        
    }
    
    public PageReference goBack() {
        Aufruf = true;
    
        return null;
    }

    public boolean getAufruf(){
        return Aufruf;
    }

    public string getsvXmlBody(){
        return svXmlBody;
    }   
    
    private string createXmlInvoice() {
        string ret = null;
        rgList = [SELECT name, Gesamtpreis__c, Rechnung_text__c, 
                                            Kunde__r.komb_Name__c, Lieferschein__r.name,
                                            CreatedDate
                                        FROM Rechnung__c
                                        WHERE Scope_visio__c = false
                                        LIMIT 100];
        if((rgList != null) && (rgList.size() > 0)) { 
        
        Datetime curDate = Datetime.now();
        string datumHeute = curDate.format('dd.MM.yyyy');
        
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
                xmlW.writeCharacters(rgPass);
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
        for(integer i = 1 ; i < rgList.size(); i++ ) {
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
                    xmlW.writeCharacters(rgList[i].name);
                xmlW.writeEndElement(); 
                xmlW.writeStartElement(null,'account', null);
                    xmlW.writeCharacters(rgAccount);
                xmlW.writeEndElement();     

                xmlW.writeEmptyElement(null,'summaryaccount', null);
                
                xmlW.writeStartElement(null,'amount', null);
                    xmlW.writeCharacters(ksgFunctions.formatCurrency(rgList[i].Gesamtpreis__c));
                xmlW.writeEndElement(); 

                xmlW.writeEmptyElement(null,'cancelDocument', null);
                xmlW.writeEmptyElement(null,'foreigncurrencyamount', null);
                xmlW.writeEmptyElement(null,'foreigncurrencycode', null);
                xmlW.writeEmptyElement(null,'foreigncurrencyrate', null);
                
                xmlW.writeStartElement(null,'stext', null);
                    xmlW.writeCharacters(rgList[i].Kunde__r.komb_Name__c);
                xmlW.writeEndElement();
                
                for(integer d = 1; d < 11; d++) {
                    xmlW.writeEmptyElement(null,'dimension_' + string.valueOf(d), null);
                    //xmlW.writeStartElement(null,'dimension_' + string.valueOf(d), null);
                    //  xmlW.writeCharacters(string.valueOf(d));
                    //xmlW.writeEndElement();                   
                }
                
                xmlW.writeStartElement(null,'vatkey', null);
                    xmlW.writeCharacters('U19');
                xmlW.writeEndElement();

                xmlW.writeEmptyElement(null,'discountpercent1', null);
                xmlW.writeEmptyElement(null,'discountperiod1', null);
                xmlW.writeEmptyElement(null,'discountpercent2', null);
                xmlW.writeEmptyElement(null,'discountperiod2', null);
                xmlW.writeEmptyElement(null,'nettimelimit', null);
                
                xmlW.writeStartElement(null,'documentText', null);
                    xmlW.writeCharacters('Lieferschein: ' + rgList[i].Lieferschein__r.name);
                xmlW.writeEndElement(); 
                
                xmlW.writeEmptyElement(null,'clearingLabel', null);
                /*
                xmlW.writeStartElement(null,'clearingLabel', null);
                    xmlW.writeCharacters('xxx');
                xmlW.writeEndElement(); 
                */
                xmlW.writeStartElement(null,'internaldocumentnumber', null);
                    xmlW.writeCharacters('internaldocumentnumber');
                xmlW.writeEndElement();                 
                
                
            xmlW.writeEndElement();
        }   
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

}