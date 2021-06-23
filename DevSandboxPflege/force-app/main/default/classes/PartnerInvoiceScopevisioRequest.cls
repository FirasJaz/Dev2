//****************************************************************************************************************************
// Erstellt tt.mm.yyyy von MZ
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
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// the program is producing the xml-file for scopevisio 
//
//
//****************************************************************************************************************************
//Änderungen:
//
// wds 30.08.2016 Change netitemprice to zero in order to avoid that scopeviso takes this price to calulate the total!
// wds 01.09.2016 Einzelpreis in die Abrechnungsposition eingefügt 
// wds 13.09.2016 Zusätzlich Kostenstelle und Beschreibung gefüllt. Beschreibung = Bezeichnung und Kostenstelle kommt aus Abrechnungsposition
// mz  09.01.2017 #137261831, write svXML & svResponse even without Answer from SV
//
//****************************************************************************************************************************
public class PartnerInvoiceScopevisioRequest {  
    
    @Future(callout=true)
    public static void sendRequest(Id invoiceId){        
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        Http http = new Http();
        String svResponse;
        
        req.setEndpoint('https://appload.scopevisio.com/api/soap/accounting/OutgoingInvoice.create');
        req.setMethod('POST');
        req.setCompressed(false);
        
        String svXmlBody = getContent(invoiceId);
        System.debug('mansi:::: svXmlBody :::: '+ svXmlBody );
        
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8');  
        if(svXmlBody != null){
            req.setHeader('Content-length', string.valueOf(svXmlBody.length()));
            req.setBody(svXmlBody);
        }else{
            req.setHeader('Content-length', '0');
        }
        
        List<Abrechnung_Partner__c> toUpdateInvoiceList = [select Id, svErfolg__c, svResponse__c, svXML__c from Abrechnung_Partner__c WHERE Id = :invoiceId limit 1];
                        
        try {
            if (!Test.isRunningTest()){
                res = http.send(req);
                svResponse = res.getBody();
                System.debug('response from sendRequest for order.Id='+ invoiceId + ' res = ' + res.getBody());
            }
            System.debug('Call successful.');
        
        } catch(System.CalloutException e) {
            svResponse = 'Callout error: '+ e;
            System.debug( 'error in PartnerInvoiceScopevisioRequest.sendRequest:: ' + svResponse );
             
        }
        if( toUpdateInvoiceList != null && toUpdateInvoiceList .size() > 0) { 
            toUpdateInvoiceList[0].svErfolg__c = Datetime.now();
            toUpdateInvoiceList[0].svResponse__c = svResponse;
            toUpdateInvoiceList[0].svXML__c = svXmlBody;
            update toUpdateInvoiceList[0];
        }
         
    }
    
    private static String createData(Abrechnung_Partner__c invoice){
        //Datetime curDate = Datetime.now();
        //string datumHeute = curDate.format('dd.MM.yyyy');
        
        Date fdcm = System.today().toStartOfMonth();
        Date ldlm = fdcm.addDays(-1);
        //Integer numberOfDays = Date.daysInMonth(ldlm.year(), ldlm.month());
        //Date fdlm = ldlm.addDays(1-numberOfDays );
        
        Datetime lastDayLastMonth = Datetime.newInstance(ldlm.year(), ldlm.month(), ldlm.day());
        Datetime firstDayLastMonth = Datetime.newInstance(ldlm.year(), ldlm.month(), 1);
        
        String lt = '<';
        String gt = '>';
        String qu = '"';
        String content = lt + 'fakturaimport xmlns='+qu+'scopevisio.com/accounting/fakturaimport'+qu+' version='+qu+'2'+qu+''+ gt;
        string pos_account = invoice.Partner__r.name;
        String pos_accountName = invoice.Partner__r.name;
        if( invoice.Partner__r.Empf_nger_Adresse_Rechnungen__c == null || invoice.Partner__r.Empf_nger_Adresse_Rechnungen__c == 'Partner' ){
            if( invoice.Partner__r.Debitoren_Nummer_SV__c != null){
                pos_account = invoice.Partner__r.Debitoren_Nummer_SV__c;   
                pos_accountName = invoice.Partner__r.Name;
            }
        }else if( invoice.Partner__r.ParentId != null ){
            List<Account> parent = [select Id,Name, Debitoren_Nummer_SV__c from account where Id = :invoice.Partner__r.ParentId limit 1];    
            if(parent[0].Debitoren_Nummer_SV__c != null){
                pos_account = parent[0].Debitoren_Nummer_SV__c;
                pos_accountName = parent[0].Name;
            }
        }
        content += lt + 'order documentNumber='+qu+''+invoice.name+''+qu+' documentDate='+qu+''+lastDayLastMonth.format('dd.MM.yyyy')+''+qu+' customer='+qu+''+pos_account
                +''+qu+' grossBased='+qu+'false'+qu+' deliveryDateFrom='+qu+''+firstDayLastMonth.format('dd.MM.yyyy')+''+qu+' deliveryDateTo='+qu+''+lastDayLastMonth.format('dd.MM.yyyy')
                +''+qu+' language='+qu+'de'+qu+' documentText='+qu+'Auftrag '+invoice.name+''+qu+' endDiscount='+qu+'0.00'+qu+' isEndDiscountAbsolute='+qu+'false'+qu+'' + gt;
        // documentDate :: invoice.CreatedDate replaced by lastDayLastMonth
        // deliveryDateFrom :: datumHeute replaced by lastDayLastMonth
              
        content += lt + 'texts' + gt;
        content += lt + 'title' + gt;
        content += lt + 'text'+ gt + 'Auftrag' + lt +'/text' + gt;
        content += lt + '/title' + gt;
        content += lt + 'subtitle' + gt;
        content += lt + 'text'+ gt + invoice.name + lt +'/text' + gt;
        content += lt + '/subtitle' + gt;
        content += lt + 'intro' + gt;
        content += lt + 'text'+ gt + 'Anrede Kunde_Titel Kunde_Vorname Kunde_Nachname,wir erlauben uns, Ihnen wie folgt in Rechnung zu stellen:' + lt +'/text' + gt;
        content += lt + '/intro' + gt;
        content += lt + 'extro' + gt;
        content += lt + 'text'+ gt + 'Zahlungsbedingung: Zahlbar sofort per Rechnung_Faelligkeit, netto.' + lt +'/text' + gt;
        content += lt + '/extro' + gt;
        content += lt + '/texts' + gt;
        
        content += lt + 'address selectedAddress='+qu+'Adresse'+qu+'/' + gt;
        content += lt + 'payment paidOnExport='+qu+'false'+qu+' dueDate='+qu+''+lastDayLastMonth.format('dd.MM.yyyy')+''+qu+' explicitDiscount='+qu+'false'+qu+'/' + gt;
        // dueDate :: datumHeute replaced by lastDayLastMonth
        
        content += lt + 'delivery/' + gt;
        
        content += lt + 'lines' + gt;
        
        List<Abrechnungspositionen__c> poses = [select Id, 
                                                       name, 
                                                       Positions_Typ__c, 
                                                       AbrechnungspositionName__c, 
                                                       Einzelpreis__c, 
                                                       Gesamtwert_CPL__c, 
                                                       Gesamtwert_CPO__c,
                                                       Kostenstelle__c, 
                                                       Anzahl_der_Tickets_CPL__c, 
                                                       Anzahl_der_Tickets_CPO__c 
                                                       from Abrechnungspositionen__c 
                                                       where Abrechnung__c = :invoice.Id];       
         
        for(integer j = 0 ; j < poses.size(); j++ ) {
            content += lt + 'line positionType='+qu+'PRODUCT'+qu+' productName='+qu+''+ poses[j].AbrechnungspositionName__c +''+qu+' unit='+qu+'Stück'+qu+' discount='+qu+'0.00'+qu+' vatkey='+qu+'U19'+qu+' taxrate='+qu+''+ ksgFunctions.formatCurrency(invoice.MWSt__c).replace(',', '.') +''+qu+' ';           
            if(poses[j].Gesamtwert_CPL__c != null && poses[j].Gesamtwert_CPL__c != 0){

//                content += ' productNumber='+qu+'12'+qu+' netItemPrice='+qu+''+ksgFunctions.formatCurrency(poses[j].Gesamtwert_CPL__c).replace(',', '.')+''+qu+' quantity='+qu+''+ksgFunctions.formatCurrency(poses[j].Anzahl_der_Tickets_CPL__c).replace(',', '.')+''+qu+' ';
                content += ' productNumber='+qu+'12'+qu+' netItemPrice='+qu+''+poses[j].Einzelpreis__c+''+qu+' quantity='+qu+''+ksgFunctions.formatCurrency(poses[j].Anzahl_der_Tickets_CPL__c).replace(',', '.')+''+qu+' ';                
           }
            if(poses[j].Gesamtwert_CPO__c != null && poses[j].Gesamtwert_CPO__c != 0){
//                content += ' productNumber='+qu+'33'+qu+' netItemPrice='+qu+''+ksgFunctions.formatCurrency(poses[j].Gesamtwert_CPO__c).replace(',', '.')+''+qu+' quantity='+qu+''+ksgFunctions.formatCurrency(poses[j].Anzahl_der_Tickets_CPO__c).replace(',', '.')+''+qu+' ';
                content += ' productNumber='+qu+'33'+qu+' netItemPrice='+qu+''+poses[j].Einzelpreis__c+''+qu+' quantity='+qu+''+ksgFunctions.formatCurrency(poses[j].Anzahl_der_Tickets_CPO__c).replace(',', '.')+''+qu+' ';       
           }
            content += 'grossItemPrice='+qu+''+qu+' account='+qu+'8400'+qu+' dimension1='+qu+''+poses[j].Kostenstelle__c+''+qu+''+ gt;
            content += lt + 'text'+ gt + poses[j].Positions_Typ__c + lt +'/text' + gt;
            content += lt + 'description' + gt + poses[j].AbrechnungspositionName__c + lt + '/description' + gt;
            content += lt + '/line' + gt;
        }    
        
        
//        content += lt + 'totals netAmount='+qu+''+ ksgFunctions.formatCurrency(invoice.Rechnungswert_Netto__c).replace(',', '.') +''+qu+' grossAmount='+qu+''+ ksgFunctions.formatCurrency(invoice.Rechnungswert_Brutto__c).replace(',', '.') +''+qu+'' + gt;
        content += lt + 'totals netAmount='+qu+''+ invoice.Rechnungswert_Netto__c +''+qu+' grossAmount='+qu+''+ invoice.Rechnungswert_Brutto__c +''+qu+'' + gt;
//        content += lt + 'vat taxrate='+qu+''+ ksgFunctions.formatCurrency(invoice.MWSt__c).replace(',', '.') +''+qu+' taxamount='+qu+''+ ksgFunctions.formatCurrency(invoice.Enthaltene_MWSt__c).replace(',', '.') +''+qu+'/' + gt;
        content += lt + 'vat taxrate='+qu+''+ invoice.MWSt__c+''+qu+' taxamount='+qu+''+ invoice.Enthaltene_MWSt__c +''+qu+'/' + gt;
        content += lt + '/totals' + gt;
           
        content += lt + '/lines' + gt;
        content += lt + '/order' + gt;
        content += lt + '/fakturaimport' + gt;
        
        return content ;       
    }
/*
    private static String maskString(String input){
        String output;
        output = input.replace('&', '&amp;')
                .replace('<', '&lt;')
                .replace('>', '&gt;')
                .replace('"', '&quot;');
        return output;
    } 

    public static string formatCurrencywithDot(decimal d){
        string s = null;
        try {
            s = d.setScale(2).format();
            integer i =  s.lastIndexOf(',');
            if (i < 0) {
                s = s + ',00';
            }
            else if (i == s.length() - 2) {
                s = s + '0';
            } 
        }
        catch(System.Exception e) {

        }
        s = s.replace(',', '.');
        return s;
    }
*/
private static String getContent(Id invoiceId){
        String result = null;
        
        String orderAccount = '';
        String orderCustomer = '';
        String orderUser = '';
        String orderPass = '';
        String orderOrganisation = '';
        
        CompanyInfo__c FirmenInfo = CompanyInfo__c.getValues('Default');
        if (FirmenInfo != null) {
            orderAccount = FirmenInfo.svAccount__c;
            orderCustomer = FirmenInfo.svCustomer__c;
            orderUser = FirmenInfo.svUser__c;
            orderPass = FirmenInfo.svPass__c;
            orderOrganisation = FirmenInfo.svOrganisation__c;
        }
        List<Abrechnung_Partner__c> invoiceList = [select Id, Name, CreatedDate, Partner__c, Enthaltene_MWSt__c, MWSt__c, Rechnungswert_Brutto__c, Rechnungswert_CPL__c, Rechnungswert_CPO__c, Rechnungswert_Netto__c, svErfolg__c, svResponse__c, svXML__c, Partner__r.name, Partner__r.Debitoren_Nummer_SV__c, Partner__r.Empf_nger_Adresse_Rechnungen__c, Partner__r.ParentId from Abrechnung_Partner__c WHERE Id = :invoiceId limit 1];
        
        if( invoiceList != null && invoiceList.size() > 0) { 
        Abrechnung_Partner__c invoice = invoiceList[0];
        
        
        Xmlstreamwriter xmlW = new Xmlstreamwriter();
        xmlW.writeStartDocument('utf-8','1.0');        
        xmlW.writeStartElement('SOAP-ENV','Envelope', 'SOAP-ENV');
        xmlW.writeAttribute(null,null,'xmlns:SOAP-ENV','http://schemas.xmlsoap.org/soap/envelope/');
        xmlW.writeEmptyElement('SOAP-ENV','Header', 'SOAP-ENV');
        xmlW.writeStartElement('SOAP-ENV','Body', 'SOAP-ENV');

        //xmlW.writeStartElement('ns1','Envelope', 'ns1');
        
        xmlW.writeStartElement('ns1','req', 'ns1');
        xmlW.writeAttribute(null,null,'xmlns:ns1','http://www.scopevisio.com/'); 

                    xmlW.writeStartElement(null,'authn', null);
            xmlW.writeStartElement(null,'customer', null);
                xmlW.writeCharacters(orderCustomer);
            xmlW.writeEndElement();
            xmlW.writeStartElement(null,'user', null);
                xmlW.writeCharacters(orderUser);
            xmlW.writeEndElement();
            xmlW.writeStartElement(null,'pass', null);
                xmlW.writeCharacters(orderPass);
            xmlW.writeEndElement(); 
            xmlW.writeStartElement(null,'language', null);
                xmlW.writeCharacters('de_DE');
            xmlW.writeEndElement(); 
            xmlW.writeStartElement(null,'organisation', null);
                xmlW.writeCharacters(orderOrganisation);
            xmlW.writeEndElement();             
        xmlW.writeEndElement(); 
            
        xmlW.writeStartElement(null,'config', null);
            xmlW.writeStartElement(null,'generateDocumentNumbers', null);
                xmlW.writeCharacters('true');
            xmlW.writeEndElement();
            xmlW.writeStartElement(null,'doPost', null);
                xmlW.writeCharacters('false');
            xmlW.writeEndElement();
            xmlW.writeStartElement(null,'skipDuplicates', null);
                xmlW.writeCharacters('false');
            xmlW.writeEndElement();
        xmlW.writeEndElement();
            
        xmlW.writeStartElement(null,'data', null);
        
            //xmlW.writeCharacters(maskString(createData(invoice)));
        xmlW.writeCharacters(createData(invoice));
        xmlW.writeEndElement(); 
        
        xmlW.writeEndElement(); 
        xmlW.writeEndElement(); 
        xmlW.writeEndDocument(); 
        result = xmlW.getXmlString();
            xmlW.close();  
        
        }  
    return result; 
}
    
}