/****************************************************************************************************************************
// Erstellt 08.05.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//          Methods Included:   retrieveAnhangEntscheidung - retrieveAnhangEntscheidung(genId), 
//                              retrieveAnhang - retrieveAnhang(genId), 
//                              retrieveKostenvoranschlagData - retrieveKostenvoranschlagData(genId), 
//                              sendKostenvoranschlagData - sendKostenvoranschlagData(genid), 
//                              checkInfopool - checkInfopool(), 
//                              confirmInfopoolEntry, 
//                              retrieveNachricht - retrieveNachricht(genId)
//
//          Primary Port Class Name: BswSchnittstelleHttpSoap11Endpoint 
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//              main controller for Webservice azh KVCheck
//
//              call: azhWebClient.sendKostenvoranschlagData(string.valueOf(genId));
//****************************************************************************************************************************
// Test:  
//*****************************************************************************************************************************
// Änderungen: 26.06.2019 AM attachment auch "AntragPG5X"    
//             17.07.2019 AM Verordnungsdaten werden immer gefüllt  
//  07.11.2019 AM #169390524 Schreibgeschützte PDF´s - bei dem retrieveAnhangEntscheidungResponse werden manchmal 2 pdf angehängt
//                              die Originalgenehmigung und von AZH generierte pdf. Daher müssen wir die List<blob> pdf[] und List<string> dateiname[] 
//                              verwenden und lastBoundary prüfen.
//  06.12.2019 AM            Die KV's mit dem Versandart 20 (Fax) werden zunächst mit der Code 419 zurückgewiesen. Der gleiche Request muss erneut gesendet
//                              werden. 
    22.01.2020 DZ             Neue Variable netto_brutto eingeführt. 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public class azhWebClient {
    private string xmlKey = '';
    private CompanyInfo__c companyInfo = CompanyInfo__c.getValues('Default');
    private map<string, string> xmlMap = new map<string, string>();
    @testVisible private List<Blob> pdf = new List<Blob>();
    // private String pdfName = null;
    private String currentGenId = null;
    private String saveXmlString = null;
    private map<id, decimal> groupPrice = new map<id, Decimal>();

    private String response_kvnr_bsw = null;

    public class xmlRecord {
        public string key {get;set;}
        public string value {get;set;}
    }

    public class infopoolresponce {
        public string kvnr_azh {get;set;}
        public string kvnr_bsw  {get;set;}
        public string azh_id   {get;set;}
        public string leistungserbringerIk   {get;set;}
        public string kennzeichen   {get;set;}
        public string angelegt {get;set;}
    }

    @TestVisible private List<xmlRecord> xmlList = new List<xmlRecord>(); 

    @TestVisible private List<infopoolresponce> infopoolresponceList = new List<infopoolresponce>(); 

    // dummy constructor
    public azhWebClient() {
        groupPrice = makePrice();
    }

    // main method. create and send request. read responce
    public boolean sendKVCheckRequest(string genId, string requestname) {
        currentGenId = genId;
        boolean error = false;
        map<string, string> xmlMap = new map<string, string>();
        azhCredetials__c azhc = readAzhCredentials();
        Http http = new Http();
        HttpResponse res = new HttpResponse();
        HttpRequest req;
        String xmlRequest = makeSoapHeader(azhc.user__c, azhc.password__c);
        // hier request spezifische Daten
        if(requestname == 'checkInfopool') {
            xmlRequest += '<soap:Body>';
            req = makeSimpleHttpRequest(requestname);
            // bei dem Request sind keine weiter Daten erforderlich.
            xmlRequest += '<ws:checkInfopool><ws:identifikation><xsd:adresse/><xsd:adresseAnsprechpartner/><xsd:ik>' + companyInfo.IK_Nummer__c + '</xsd:ik></ws:identifikation></ws:checkInfopool>';              
            xmlRequest += '</soap:Body>';
            xmlRequest += '</soap:Envelope>';  
            req.setBody(xmlRequest);
            req.setHeader('Content-length', string.valueOf(xmlRequest.length()));        
        }
        else if (requestname == 'sendKostenvoranschlagData') {
            xmlRequest += '<soap:Body xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">';
            req = makeMultipartHttpRequest(requestname, xmlRequest, genId);
            if(req == null) {
                return true;
            }
        }
        else if (requestname == 'retrieveKostenvoranschlagData') {
            xmlRequest += '<soap:Body>';
            req = makeSimpleHttpRequest(requestname);
            xmlRequest += makeRetrieveKostenvoranschlagData(genId); 
            xmlRequest += '</soap:Body>';
            xmlRequest += '</soap:Envelope>';  
            req.setBody(xmlRequest);
            req.setHeader('Content-length', string.valueOf(xmlRequest.length()));             
        }
        else if (requestname == 'retrieveAnhang') {
            xmlRequest += '<soap:Body >';
            req = makeSimpleHttpRequest(requestname);
            xmlRequest += makeRetrieveAnhang(genId); 
            xmlRequest += '</soap:Body>';
            xmlRequest += '</soap:Envelope>';  
            req.setBody(xmlRequest);
            req.setHeader('Content-length', string.valueOf(xmlRequest.length()));             
        }
        else if (requestname == 'retrieveAnhangEntscheidung') {
            xmlRequest += '<soap:Body>';
            req = makeSimpleHttpRequest(requestname);
            xmlRequest += makeretrieveAnhangEntscheidung(genId); 
            xmlRequest += '</soap:Body>';
            xmlRequest += '</soap:Envelope>';  
            req.setBody(xmlRequest);
            req.setHeader('Content-length', string.valueOf(xmlRequest.length()));             
        }
        else if (requestname == 'retrieveNachricht') {
            xmlRequest += '<soap:Body>';
            req = makeSimpleHttpRequest(requestname);
            xmlRequest += makeRetrieveNachricht(genId); 
            xmlRequest += '</soap:Body>';
            xmlRequest += '</soap:Envelope>';  
            req.setBody(xmlRequest);
            req.setHeader('Content-length', string.valueOf(xmlRequest.length()));             
        }
        else {
            // TODO: Meldung Falscher Request Name
            return true;    
        }
        system.debug('##### header Content-Type: ' + req.getHeader('Content-Type'));
        system.debug('##### body:' + req.getBody());
        req.setEndpoint(azhc.Endpoint__c);
        // Request fertig. Senden:
        try {
            res = http.send(req);
            string respStatus = res.getStatus();
            integer respStatusCode = res.getStatusCode();
            if(respStatusCode == 200) {
                error = extractMultipartSoapData(res, requestname);
                if(error) {
                    error = extractXmlData(res.getBody());
                    if(error) {
                        // TODO: Errorhandling
                        return true;
                    }
                    else {
                        processResponceReturn(requestname);
                    }                    
                }

            }
            else {
                // TODO: Errorhandling
                boolean ok = extractXmlData(res.getBody());
                processResponce();
                return true;
            }
        }
        catch(System.CalloutException e) {
            // TODO: Errorhandling
            return true;
        }        
        return error;
    } 

    // this Method check Multipart SOAP-responce and extract the both parts (xml and pdf)
    @TestVisible private boolean extractMultipartSoapData(HttpResponse res, String requestname) {
        try {
            // read header
            String header = res.getHeader('Content-Type');
            // determine boundary
            if(!header.contains('boundary=')) {
                return true;
            }

            String boundary = header.split('boundary="')[1].split('"')[0];

            // convert boundary to HEX
            String boundaryHex = EncodingUtil.convertToHex(Blob.valueOf('--'+boundary));
            String lastBoundaryHex = EncodingUtil.convertToHex(Blob.valueOf('--'+boundary+'--'));
            String crlfHex = EncodingUtil.convertToHex(Blob.valueOf('\r\n\r\n'));

            // convert body to HEX
            String responseHex = EncodingUtil.convertToHex(res.getBodyAsBlob());
            // split body by boundary
            

            // String[] responseHexArray = responseHex.split(boundaryHex);
            // if only one part is responseHexArray.size = 3 (null, data, end)
            // else size > 3 (null, dataSoap, dataPdf, end)
            // system.debug('##### responseHexArray.size()=' + responseHexArray.size());  
            // soap-xml is allways [1]

            // String xmls = EncodingUtil.convertFromHex( responseHexArray[1] ).toString();
            // if(responseHexArray.size() > 3) {
            //     pdf = EncodingUtil.convertFromHex( responseHexArray[2] );
            // }  
            // new 
            integer i = responseHex.indexOf(boundaryHex, 1);
            system.debug('#### i=' + i);
            
            String t1h = responseHex.substring(0, i);
            // system.debug('#### t1h=' + t1h); 
            String xmls = EncodingUtil.convertFromHex( t1h ).toString();           
            system.debug('##### xmls=' + xmls);  
            if (requestname != 'sendKostenvoranschlagData') {
            // für sendKostenvoranschlagData nicht speichern - es kommt das originaldokument zurück
                if(responseHex.length() > (i + boundaryHex.length())) {
                    // has attachment
                    String t2h = responseHex.substring(i + boundaryHex.length());
                    // system.debug('####### t2h=' + t2h);
                    
                    i = t2h.indexOf(boundaryHex, 1);
                    system.debug('#### i=' + i); 
                    while(i > boundaryHex.length()) {
                        String pdfHex = t2h.substring(0, i + boundaryHex.length());
                        addPdf(pdfHex, crlfHex, boundaryHex, lastBoundaryHex);
                        t2h = t2h.substring(i + boundaryHex.length());
                        i = t2h.indexOf(boundaryHex, 1);
                    }
                    if(t2h.length() > 0) {      
                        addPdf(t2h, crlfHex, boundaryHex, lastBoundaryHex);  
                    }
                }
            }

            saveXmlString = xmls;
            system.debug('####### saveXmlString =' + xmls);
            boolean error = extractXmlData(xmls);
            
            if(error) {
                // TODO: Errorhandling
               
                return true;
            }
            else {
                processResponceReturn(requestname);
            }

                                   
        }
        catch(System.exception e) {
             system.debug('##### Error!!! ' + e); 
            // TODO: Errorhandling
            return true;
        }
        return false;
    }

    // bereinigen hex für pdf
    public void addPdf(String pdfh, string crlfHex, String boundaryHex, String lastBoundaryHex) {
        integer p = pdfH.indexOf(crlfHex); 
        if(p > 0) {
            String pdfhex = pdfh.substring(p + crlfHex.length());
            pdfhex = pdfhex.remove(lastBoundaryHex);
            pdfhex = pdfhex.remove(boundaryHex);
            // 15.11.2019 pdfhex = pdfhex.remove(crlfHex);      
            blob b = EncodingUtil.convertFromHex(pdfhex);
            system.debug('####### Blob OK');
            // pdf.add(EncodingUtil.base64Decode(b.toString()));
            pdf.add(b);
            system.debug('####### Add OK');
        }
    }   

    // extract and parse xml part from responce 
    // @TestVisible private boolean extractXmlData(string xmlPart) {
    public boolean extractXmlData(string xmlPart) {
        try {
            System.debug('#### xmlPart=' + xmlPart);
            String[] bodytab = xmlPart.split('\r\n'); 
            String xmlResponce;
            for(string z : bodytab){
                if(z.contains('<?xml')) {
                    xmlResponce = z;
                }
            }  
            System.debug('#### xmlresponce=' + xmlResponce);
            saveXmlString = xmlResponce;
            Dom.Document doc = new Dom.Document();
            doc.load(xmlResponce);
            Dom.XMLNode rootNode = doc.getRootElement();
            // die Methode wird rekursiv aufgerufen. Deshalb kein return 
            prepareXML(rootNode); 
            // Ergebniss von prepareXML:
            if(xmlMap.size() > 0) {
                return false;
            }
            else {
                // TODO: Meldung "Body ist Leer"
                return false;
            }
            
        }
        catch(System.exception e) {
            // TODO: Errorhandling
            return true;
        }       
    }

    // create SOAP request for kostenvoranschlag
    @TestVisible private string makeKVstring(Curabox_Genehmigung__c gen, String attachmentName) {
        string xmlString = '';
        try {
            set<id> pgSet = new set<id>();
            id contId = gen.Contact__c;
            contact kunde;
            account kk;
            // ProductGrous, contact und attid einlesen. 
            List<Curabox_Genehmigungsposition__c> gpList = [SELECT id, Product_Group__c, Product_Group__r.name, Ant_Menge_Stk__c                                                                
                                                            FROM Curabox_Genehmigungsposition__c
                                                            WHERE Genehmigung__c = : gen.Id];
            if((gpList != null) && (gpList.Size() > 0)) {
                for (Curabox_Genehmigungsposition__c gp : gpList) {
                    pgSet.add(gp.Product_Group__c);
                }



                // Pflege.de Daten
                Organization pflegede = [select id, Phone, postalcode, street, City, Fax,  name from Organization];

                try {
                // Kundendaten (contact)
                    kunde = [SELECT id, firstname, lastname, MailingStreet, MailingPostalCode, MailingCity,
                                Kranken_Pflegekasse__c, Versicherungsnummer__c, Art_Von_Handschuhe__c, Birthdate, Zuzahlungsbefreit_Nein__c
                                FROM contact WHERE id =: contId];
                }
                catch(System.Exception e ) {
                    writeSingleError('makeKVstring', gen.id, '703', 'no contact found', string.valueOf(e.getLineNumber()) + ' ' + e.getMessage());
                    return null;   
                }

                try {
                    // Krankenkasse
                    kk = [SELECT id, name, BillingStreet, Billingcity, BillingPostalCode, Fax, 
                                    IK_Nummer__c, IK_Kostenvoranschlag__c, IK_Verordner__c,
                                    KV_Anhangsart__c, KV_Verordner__c, KV_Ansprechpartner_LE__c, KV_Ansprechpartner_LE_Telefon__c, KV_LEGS__c,
                                    KV_PG51_HIMINR__c, KV_PG54_HIMINR__c, KV_Hilfsmittelkennzeichen__c, KV_Versichertenstatus__c, KV_PG_Getrennt__c,
                                    KV_Allways_verordnungsdaten__c, KV_per_Fax__c
                                    FROM account 
                                    WHERE id =: kunde.Kranken_Pflegekasse__c];
                }
                catch(System.Exception e ) {
                    writeSingleError('makeKVstring', gen.id, '703', 'no Kranken_Pflegekasse__c found', string.valueOf(e.getLineNumber()) + ' ' + e.getMessage());
                    return null;   
                }

                boolean verordnung = false;
                if((kk.KV_Anhangsart__c != null) && ((kk.KV_Anhangsart__c == '10') || (kk.KV_Allways_verordnungsdaten__c == true))) {
                    verordnung = true;
                }
                
                // Products
                map<id, product__c> standardProducts;
                if(gen.Nach_Paragraph__c == '54') {
                    standardProducts = readstandardProducts(kunde.Art_Von_Handschuhe__c);
                }
                else {
                    standardProducts = readstandardKUWV();
                }
                if(standardProducts.isEmpty()) {
                    writeSingleError('makeKVstring', gen.id, '705', 'no standard product found', null);
                    return null;   
                }
                String ik_kostenvoranschlag = kk.IK_Kostenvoranschlag__c;
                if(ik_kostenvoranschlag == null) {
                    ik_kostenvoranschlag = kk.IK_Nummer__c;
                }



                // so, jetzt alles zusammenbacken
                // wir verwenden string.valueOf(...) um xml ohne Abbruch zu erzeugen. Fehler werdendann von AZH gemeldet
                xmlString += '<ns2:sendKostenvoranschlagData xmlns:ns2="http://ws.bswsnt.vsa" xmlns="http://ws.bswsnt.vsa/xsd" xmlns:ns4="http://einlieferung.ws.bswsnt.vsa/xsd" xmlns:ns3="http://infopool.ws.bswsnt.vsa/xsd">';
                xmlString += '<ns2:kv>';
                xmlString += '<ns4:kostenvoranschlag>';
                // Adresse von Pflege.de
                xmlString += '<ns4:adresse>';
                    xmlString += '<bundesland_kz xsi:nil="true"/>';
                    xmlString += '<email xsi:nil="true"/>';
                    xmlString += '<fax xsi:nil="true"/>';
                    xmlString += '<hausnummer xsi:nil="true"/>';
                    xmlString += '<land_kz xsi:nil="true"/>';
                    xmlString += '<titel xsi:nil="true"/>';
                    xmlString += '<name>' + pflegede.name +'</name>';
                    xmlString += '<ort>' + pflegede.City +'</ort>';
                    xmlString += '<plz>' + pflegede.postalcode +'</plz>';
                    xmlString += '<strasse>' + pflegede.street +'</strasse>';
                    xmlString += '<telefonnr xsi:nil="true"/>';
                    xmlString += '<vorname xsi:nil="true"/>';
                xmlString += '</ns4:adresse>';
                if(kk.KV_Ansprechpartner_LE__c != null) {
                    xmlString += '<ns4:adresseAnsprechpartner>';
                        xmlString += '<bundesland_kz xsi:nil="true"/>';
                        xmlString += '<email xsi:nil="true"/>';
                        xmlString += '<fax xsi:nil="true"/>';
                        xmlString += '<hausnummer xsi:nil="true"/>';
                        xmlString += '<land_kz xsi:nil="true"/>';
                        xmlString += '<titel xsi:nil="true"/>';
                        xmlString += '<name>' + kk.KV_Ansprechpartner_LE__c +'</name>';
                        xmlString += '<ort xsi:nil="true"/>'; 
                        xmlString += '<plz xsi:nil="true"/>';
                        xmlString += '<strasse xsi:nil="true"/>';
                        if(kk.KV_Ansprechpartner_LE_Telefon__c != null) {
                            xmlString += '<telefonnr>' + kk.KV_Ansprechpartner_LE_Telefon__c + '</telefonnr>';
                        }
                        else {
                            xmlString += '<telefonnr xsi:nil="true"/>';
                        }
                        
                        xmlString += '<vorname xsi:nil="true"/>';                   
                    xmlString += '</ns4:adresseAnsprechpartner>';
                }
                else {
                    xmlString += '<ns4:adresseAnsprechpartner xsi:nil="true"/>';
                }
                // Anhang
                xmlString += '<ns4:anhang>';
                    xmlString += '<ns4:dateiname>' + attachmentName + '</ns4:dateiname>';
                    // kk-abhängig
                    if(kk.KV_Anhangsart__c == null) {
                        xmlString += '<ns4:anhangsart>20</ns4:anhangsart>';   
                    }   
                    else {
                        xmlString += '<ns4:anhangsart>' + kk.KV_Anhangsart__c + '</ns4:anhangsart>';
                    }           
                    xmlString += '<ns4:kvnr_azh xsi:nil="true"/>';
                    xmlString += '<ns4:kvnr_bsw>' + gen.Id + '</ns4:kvnr_bsw>';
                xmlString += '</ns4:anhang>';

                // Kostenträger
                xmlString += '<ns4:kostentraeger>';
                    xmlString += '<ns4:ik>' + ik_kostenvoranschlag + '</ns4:ik>';
                    // Adresse kostenträger
                    xmlString += '<ns4:adresse>';
                        xmlString += '<bundesland_kz xsi:nil="true"/>';
                        xmlString += '<email xsi:nil="true"/>';
                        xmlString += '<fax>' + string.valueOf(kk.fax) + '</fax>';
                        xmlString += '<hausnummer xsi:nil="true"/>';
                        xmlString += '<land_kz xsi:nil="true"/>';
                        xmlString += '<titel xsi:nil="true"/>';             
                        xmlString += '<name>' + maskString(string.valueOf(kk.name)) + '</name>';
                        xmlString += '<ort>' + string.valueOf(kk.Billingcity) +'</ort>';
                        xmlString += '<plz>' + string.valueOf(kk.BillingPostalCode) +'</plz>';
                        xmlString += '<strasse>' + string.valueOf(kk.BillingStreet)     +'</strasse>';   
                        xmlString += '<telefonnr xsi:nil="true"/>';
                        xmlString += '<vorname xsi:nil="true"/>';            
                    xmlString += '</ns4:adresse>';
                    xmlString += '<ns4:sachbearbeiter xsi:nil="true"/>';
                xmlString += '</ns4:kostentraeger>';

                // GenehmigungId
                xmlString += '<ns4:kvnr_bsw>' + gen.Id + '</ns4:kvnr_bsw>';
                xmlString += '<ns4:kvnr_azh xsi:nil="true"/>';
                // IK Pflege.De
                xmlString += '<ns4:ik>' + string.valueOf(companyInfo.IK_Nummer__c) + '</ns4:ik>';

                // Positionen 
                // Wenn KV_PG51_HIMINR__c gefüllt, senden wir nur 1 Position 
                if(kk.KV_PG51_HIMINR__c != null) {
                    xmlString += '<ns4:versorgungsgruppe>';
                        xmlString += '<ns4:versorgungsgruppepositionsnr>1</ns4:versorgungsgruppepositionsnr>';
                        xmlString += '<ns4:versorgungsgruppenname xsi:nil="true"/>';
                        xmlString += '<ns4:artikelnummer xsi:nil="true"/>';
                        xmlString += '<ns4:versorgungszeitraumvon xsi:nil="true"/>';
                        xmlString += '<ns4:versorgungszeitraumbis xsi:nil="true"/>';
                        xmlString += '<ns4:versorgungsperiode xsi:nil="true"/>';
                        xmlString += '<ns4:position>';
                        if(gen.Nach_Paragraph__c == '54') {
                            // Curabox    
                            xmlString += '<ns4:anfragenummer xsi:nil="true"/>';
                            xmlString += '<ns4:anzahl>1</ns4:anzahl>';
                            xmlString += '<ns4:bruttobetrag>40.00</ns4:bruttobetrag>';                           
                            xmlString += '<ns4:geraetenummer xsi:nil="true"/>';
                            xmlString += '<ns4:hersteller xsi:nil="true"/>';
                            xmlString += '<ns4:herstellungsjahr xsi:nil="true"/>';
                            if(kk.KV_Hilfsmittelkennzeichen__c != null) {
                                xmlString += '<ns4:hilfsmittelkz>' + kk.KV_Hilfsmittelkennzeichen__c +'</ns4:hilfsmittelkz>';
                            }
                            else {
                                xmlString += '<ns4:hilfsmittelkz>00</ns4:hilfsmittelkz>';
                            }
                            if(kk.KV_PG54_HIMINR__c != null) {
                                xmlString += '<ns4:hilfsmittelposnr>' + kk.KV_PG54_HIMINR__c.remove('.') + '</ns4:hilfsmittelposnr>';
                            }   
                            else {
                                xmlString += '<ns4:hilfsmittelposnr xsi:nil="true"/>';
                            }                                                    
                            xmlString += '<ns4:inventarnr xsi:nil="true"/>';
                            if(kk.KV_LEGS__c != null) {
                                xmlString += '<ns4:legs>' + kk.KV_LEGS__c + '</ns4:legs>';
                            }
                            else {
                                xmlString += '<ns4:legs xsi:nil="true"/>';
                            }
                            
                            xmlString += '<ns4:mengeneinheit>10</ns4:mengeneinheit>';
                            xmlString += '<ns4:mwstkz>1</ns4:mwstkz>'; 

                            xmlString += '<ns4:nettobetrag>33.61</ns4:nettobetrag>';
                            xmlString += '<ns4:positionsnr>1</ns4:positionsnr>';      
                            xmlString += '<ns4:produktbesonderheit/>';
                            xmlString += '<ns4:produktbezeichnung>PG 54 - Zum Verbrauch bestimmte Pflegehilfsmittel bis zu 40,00 EUR / p.m.</ns4:produktbezeichnung>';    

                        } 
                        else  if(gen.Nach_Paragraph__c == '51') {
                            xmlString += '<ns4:anfragenummer xsi:nil="true"/>';
                            xmlString += '<ns4:anzahl>4</ns4:anzahl>';
                            xmlString += '<ns4:bruttobetrag>26.16</ns4:bruttobetrag>';                           
                            xmlString += '<ns4:geraetenummer xsi:nil="true"/>';
                            xmlString += '<ns4:hersteller xsi:nil="true"/>';
                            xmlString += '<ns4:herstellungsjahr xsi:nil="true"/>';
                            xmlString += '<ns4:hilfsmittelkz>00</ns4:hilfsmittelkz>';
                            xmlString += '<ns4:hilfsmittelposnr>' + kk.KV_PG51_HIMINR__c.remove('.') + '</ns4:hilfsmittelposnr>';
                            xmlString += '<ns4:inventarnr xsi:nil="true"/>';
                            if(kk.KV_LEGS__c != null) {
                                xmlString += '<ns4:legs>' + kk.KV_LEGS__c + '</ns4:legs>';
                            }
                            else {
                                xmlString += '<ns4:legs xsi:nil="true"/>';
                            }
                            xmlString += '<ns4:mengeneinheit>10</ns4:mengeneinheit>';
                            xmlString += '<ns4:mwstkz>1</ns4:mwstkz>'; 

                            xmlString += '<ns4:nettobetrag>21.98</ns4:nettobetrag>';
                            xmlString += '<ns4:netto_brutto>1</ns4:netto_brutto>';
                            xmlString += '<ns4:positionsnr>1</ns4:positionsnr>';      
                            xmlString += '<ns4:produktbesonderheit/>';  
                            xmlString += '<ns4:produktbezeichnung>MoliNea textile Bettschutzeinlage</ns4:produktbezeichnung>';                                                                                      
                        }
                            xmlString += '<ns4:beschreibungpos xsi:nil="true"/>';
                            xmlString += '<ns4:pzn xsi:nil="true"/>';
                            xmlString += '<ns4:rabatt xsi:nil="true"/>';
                            xmlString += '<ns4:registernummer xsi:nil="true"/>';
                            xmlString += '<ns4:seriennummer xsi:nil="true"/>';
                            xmlString += '<ns4:vorbesitzer xsi:nil="true"/>';
                            xmlString += '<ns4:zeitwert xsi:nil="true"/>';
                            xmlString += '<ns4:zuschlag xsi:nil="true"/>';
                            xmlString += '<ns4:betrageigenanteil>0.0</ns4:betrageigenanteil>';
                            xmlString += '<ns4:zuzahlung>0.0</ns4:zuzahlung>';
                            xmlString += '<ns4:koerperhaelfte xsi:nil="true"/>';
                            xmlString += '<ns4:fallpauschale xsi:nil="true"/>';
                            xmlString += '<ns4:zhpdaten xsi:nil="true"/>';
                            xmlString += '<ns4:auslieferungsdatum xsi:nil="true"/>';
                            xmlString += '<ns4:betriebsstunden xsi:nil="true"/>';
                            xmlString += '<ns4:versorgungszeitraumvon>';
                                xmlString += datetime.now().format('yyyyMMdd');
                            xmlString += '</ns4:versorgungszeitraumvon>';
                            xmlString += '<ns4:versorgungszeitraumbis>29991231</ns4:versorgungszeitraumbis>';
                            xmlString += '<ns4:hilfsmittelzumverbrauch xsi:nil="true"/>';
                            xmlString += '<ns4:versicherungsart>1</ns4:versicherungsart>';                         
                        xmlString += '</ns4:position>';
                    xmlString += '<ns4:abweichendeLieferadresse xsi:nil="true"/>';    
                    xmlString += '</ns4:versorgungsgruppe>';
                }
                else {
                    integer lfnr = 1;
                    xmlString += '<ns4:versorgungsgruppe>';
                        xmlString += '<ns4:versorgungsgruppepositionsnr>1</ns4:versorgungsgruppepositionsnr>';
                        xmlString += '<ns4:versorgungsgruppenname xsi:nil="true"/>';
                        xmlString += '<ns4:artikelnummer xsi:nil="true"/>';
                        xmlString += '<ns4:versorgungszeitraumvon xsi:nil="true"/>';
                        xmlString += '<ns4:versorgungszeitraumbis xsi:nil="true"/>';
                        xmlString += '<ns4:versorgungsperiode xsi:nil="true"/>';
                        for(Curabox_Genehmigungsposition__c g : gpList) {
                            if(standardProducts.ContainsKey(g.Product_Group__c)) {
                                decimal brutto = 0.00;
                                decimal netto = 0.00;
                                try{
                                    decimal price = 0;
                                    if(groupPrice.containsKey(g.Product_Group__c)) {
                                        price = groupPrice.get(g.Product_Group__c);
                                    }
                                    brutto = g.Ant_Menge_Stk__c * price;
                                    decimal mwstSatz = ((brutto / 119) * 19).setScale(2, RoundingMode.HALF_UP);
                                    netto = brutto - mwstSatz;
                                }
                                catch (System.Exception e) {
                                    brutto = 0.00;
                                    netto = 0.00;
                                }
                                xmlString += '<ns4:position>';
                                    xmlString += '<ns4:anfragenummer xsi:nil="true"/>';
                                    xmlString += '<ns4:anzahl>' + string.valueOf(g.Ant_Menge_Stk__c) + '</ns4:anzahl>';
                                    xmlString += '<ns4:bruttobetrag>' + brutto.format().replace(',', '.') + '</ns4:bruttobetrag>';                           
                                    xmlString += '<ns4:geraetenummer xsi:nil="true"/>';
                                    xmlString += '<ns4:hersteller xsi:nil="true"/>';
                                    xmlString += '<ns4:herstellungsjahr xsi:nil="true"/>';
                                    xmlString += '<ns4:hilfsmittelkz>00</ns4:hilfsmittelkz>';
                                    xmlString += '<ns4:hilfsmittelposnr>' + string.valueOf(standardProducts.get(g.Product_Group__c).Hilfsmittelpositionsnummer__c) + '</ns4:hilfsmittelposnr>';
                                    xmlString += '<ns4:inventarnr xsi:nil="true"/>';
                                    xmlString += '<ns4:legs xsi:nil="true"/>';
                                    xmlString += '<ns4:mengeneinheit>' + mengeneinheitAZH(standardProducts.get(g.Product_Group__c).volume_unit__c) + '</ns4:mengeneinheit>';
                                    xmlString += '<ns4:mwstkz>1</ns4:mwstkz>'; 
                                    xmlString += '<ns4:nettobetrag>' + netto.format().replace(',', '.') + '</ns4:nettobetrag>';
                                    xmlString += '<ns4:positionsnr>' + string.valueOf(lfnr) + '</ns4:positionsnr>';      
                                    xmlString += '<ns4:produktbesonderheit/>';
                                    xmlString += '<ns4:produktbezeichnung>' + g.Product_Group__r.name + '</ns4:produktbezeichnung>';    
                                    xmlString += '<ns4:beschreibungpos xsi:nil="true"/>';
                                    xmlString += '<ns4:pzn xsi:nil="true"/>';
                                    xmlString += '<ns4:rabatt xsi:nil="true"/>';
                                    xmlString += '<ns4:registernummer xsi:nil="true"/>';
                                    xmlString += '<ns4:seriennummer xsi:nil="true"/>';
                                    xmlString += '<ns4:vorbesitzer xsi:nil="true"/>';
                                    xmlString += '<ns4:zeitwert xsi:nil="true"/>';
                                    xmlString += '<ns4:zuschlag xsi:nil="true"/>';
                                    xmlString += '<ns4:betrageigenanteil>0.0</ns4:betrageigenanteil>';
                                    xmlString += '<ns4:zuzahlung>0.0</ns4:zuzahlung>';
                                    xmlString += '<ns4:koerperhaelfte xsi:nil="true"/>';
                                    xmlString += '<ns4:fallpauschale xsi:nil="true"/>';
                                    xmlString += '<ns4:zhpdaten xsi:nil="true"/>';
                                    xmlString += '<ns4:auslieferungsdatum xsi:nil="true"/>';
                                    xmlString += '<ns4:betriebsstunden xsi:nil="true"/>';
                                    xmlString += '<ns4:versorgungszeitraumvon xsi:nil="true"/>';
                                    xmlString += '<ns4:versorgungszeitraumbis xsi:nil="true"/>';
                                    xmlString += '<ns4:hilfsmittelzumverbrauch xsi:nil="true"/>';
                                    xmlString += '<ns4:versicherungsart>1</ns4:versicherungsart>';   
                                xmlString += '</ns4:position>';
                                lfnr++;
                            }
                        }
                    xmlString += '<ns4:abweichendeLieferadresse xsi:nil="true"/>';    
                    xmlString += '</ns4:versorgungsgruppe>';
                }
                // ende versorgungsgruppe

                // test 
                if(!verordnung) {
                    xmlString += '<ns4:verordnungsdaten xsi:nil="true"/>';
                }
                else {
                    xmlString += '<ns4:verordnungsdaten>';
                        xmlString += '<ns4:abg xsi:nil="true"/>';
                        xmlString += '<ns4:adresseArzt xsi:nil="true"/>';
                        xmlString += '<ns4:arztnr>999999999</ns4:arztnr>';
                        xmlString += '<ns4:bsnr>999999999</ns4:bsnr>';
                        xmlString += '<ns4:diagnose><ns4:diagnoseschluessel/><ns4:diagnosetext xsi:nil="true"/></ns4:diagnose>';
                        xmlString += '<ns4:leistung xsi:nil="true"/>';
                        xmlString += '<ns4:bemerkung xsi:nil="true"/>';
                        xmlString += '<ns4:unfalldatum xsi:nil="true"/>';
                        if(kk.IK_Verordner__c != null) {
                            xmlString += '<ns4:verordnerIk>' + kk.IK_Verordner__c +  '</ns4:verordnerIk>';
                        } 
                        else {
                            xmlString += '<ns4:verordnerIk xsi:nil="true"/>';
                        }
                        xmlString += '<ns4:verordnungsdatum>';
                        if(gen.Antrag_eingegangen_am__c != null) {
                            xmlString += datetime.newInstance(gen.Antrag_eingegangen_am__c, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd');
                        }
                        else {
                            xmlString += datetime.now().format('yyyyMMdd');
                        }
                        xmlString += '</ns4:verordnungsdatum>';
                        xmlString += '<ns4:verordnungsnr xsi:nil="true"/>';
                        xmlString += '<ns4:verordnungskz xsi:nil="true"/>';
                        xmlString += '<ns4:opdatum xsi:nil="true"/>';
                        xmlString += '<ns4:versorgungkz xsi:nil="true"/>';
                    xmlString += '</ns4:verordnungsdaten>';
                }
                // 20 = Fax
                if(kk.KV_per_Fax__c) {
                    xmlString += '<ns4:versandart>20</ns4:versandart>';    
                }
                else {
                // 30 = elektronisch
                    xmlString += '<ns4:versandart>30</ns4:versandart>';
                }

                // Kunde
                xmlString += '<ns4:versichertendaten>';
                    xmlString += '<ns4:abweichendeLieferadresse xsi:nil="true"/>';
                    xmlString += '<ns4:adresse>';
                        xmlString += '<bundesland_kz xsi:nil="true"/>';
                        xmlString += '<email xsi:nil="true"/>';
                        xmlString += '<fax xsi:nil="true"/>';
                        xmlString += '<hausnummer xsi:nil="true"/>';
                        xmlString += '<land_kz xsi:nil="true"/>';
                        xmlString += '<titel xsi:nil="true"/>'; 
                        xmlString += '<name>' + string.valueOf(kunde.lastname) + '</name>';
                        xmlString += '<ort>' + string.valueOf(kunde.MailingCity) + '</ort>';
                        xmlString += '<plz>' + string.valueOf(kunde.MailingPostalCode) + '</plz>';
                        xmlString += '<strasse>' +  string.valueOf(kunde.MailingStreet) + '</strasse>';
                        xmlString += '<telefonnr xsi:nil="true"/>';                    
                        xmlString += '<vorname>' + string.valueOf(kunde.firstname) + '</vorname>';                        
                    xmlString += '</ns4:adresse>';
                    xmlString += '<ns4:befreiungbis xsi:nil="true"/>';
                    xmlString += '<ns4:befreiungseit xsi:nil="true"/>';
                    String geburtsdatum = '00000000';
                    if(kunde.Birthdate != null) {
                        geburtsdatum = datetime.newInstance(kunde.Birthdate, Time.newInstance(0, 0, 0, 0)).format('yyyyMMdd');
                    }
                    xmlString += '<ns4:geburtsdatum>' + geburtsdatum + '</ns4:geburtsdatum>';
                    xmlString += '<ns4:kartegueltigbis xsi:nil="true"/>';                   
                    xmlString += '<ns4:versichertennr>' + string.valueOf(kunde.Versicherungsnummer__c) + '</ns4:versichertennr>';
                    if(kk.KV_Versichertenstatus__c != null) {
                        xmlString += '<ns4:versichertenstatus>' + kk.KV_Versichertenstatus__c + '</ns4:versichertenstatus>'; 
                    }
                    else {
                        xmlString += '<ns4:versichertenstatus xsi:nil="true"/>'; 
                    }    
                    
                    xmlString += '<ns4:versicherungsart>1</ns4:versicherungsart>'; 
                    if(kunde.Zuzahlungsbefreit_Nein__c) {
                        xmlString += '<ns4:zuzahlungskz>0</ns4:zuzahlungskz>'; 
                    }
                    else {
                        xmlString += '<ns4:zuzahlungskz>1</ns4:zuzahlungskz>'; 
                    }
                    xmlString += '<ns4:versichertennrneu>' + string.valueOf(kunde.Versicherungsnummer__c) + '</ns4:versichertennrneu>';

                xmlString += '</ns4:versichertendaten>';
                xmlString += '<ns4:versorgungsart>1</ns4:versorgungsart>'; 
                xmlString += '<ns4:kostentraegerentscheidung xsi:nil="true"/>'; 
                xmlString += '</ns4:kostenvoranschlag>';
                xmlString += '</ns2:kv>';

                xmlString += '<ns2:identifikation/>';

                xmlString += '</ns2:sendKostenvoranschlagData>';
                xmlString += '</soap:Body>';
                xmlString += '</soap:Envelope>'; 
            } 
            else {               
                writeSingleError('makeKVstring', gen.id, '702', 'no genehmigung lines found', null );   
                return null;
            }
        }
        catch (System.exception e) {
            writeSingleError('makeKVstring', gen.id, '700', 'check system error', string.valueOf(e.getLineNumber()) + ' ' + e.getMessage()); 
            return null;
        }
        return xmlString;
    }

    // make map with curabox standard products. Key = CuraboxProductGroup 
    // Curabox
    @TestVisible private map<id, product__c> readstandardProducts(id hanschuheid) {
        map<id, product__c> prMap = new map<id, product__c>();
        List<Product__c> prList = [SELECT id, Price__c, Hilfsmittelpositionsnummer__c, Product_Group__c, volume_unit__c
                                    FROM Product__c
                                    WHERE standard_article_for_curabox__c = true
                                    AND Hilfsmittelgruppe__c = '54'];
        if((prList != null) && (prList.size() > 0)) {
            for(Product__c p : prList) {
                prMap.put(p.Product_Group__c, p);
            }
        }
        if(hanschuheId != null) {
        List<Product__c> hsList = [SELECT id, Price__c, Hilfsmittelpositionsnummer__c, Product_Group__c, volume_unit__c
                                    FROM Product__c
                                    WHERE id = : hanschuheid];   
            if((prList != null) && (prList.size() > 0)) {
                prMap.put(hsList[0].Product_Group__c, hsList[0]);
            }   
        }  
        return prMap;
    }
    // KUWV
    @TestVisible private map<id, product__c> readstandardKUWV() {
        map<id, product__c> prMap = new map<id, product__c>();
        List<Product__c> prList = [SELECT id, Price__c, Hilfsmittelpositionsnummer__c, Product_Group__c, volume_unit__c
                                    FROM Product__c
                                    WHERE standard_article_for_curabox__c = true
                                    AND Hilfsmittelgruppe__c = '51'];
        if((prList != null) && (prList.size() > 0)) {
            for(Product__c p : prList) {
                prMap.put(p.Product_Group__c, p);
            }
        }
        return prMap;
    }

    // create simple HTTP request (only header and SOAP-body)
    @TestVisible private HttpRequest makeSimpleHttpRequest(string soapAction) {                  
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setCompressed(false); 
        req.setHeader('SOAPAction', '"urn:' + soapAction + '"');
        req.setHeader('Content-Type', 'application/soap+xml;charset=UTF-8;action="urn:' + soapAction + '"');
        req.setHeader('Connection', 'Keep-Alive');
        req.setHeader('Accept-Encoding', 'gzip,deflate');
        req.setHeader('Host', 'www.azh-portal.de');
        req.setTimeout(120000);
        return req;
    }  

    // create multipart HTTP request (header, xml, attachment) boundary separated
    @TestVisible private HttpRequest makeMultipartHttpRequest(string soapAction, string xmlString, string genId) {                  
        HttpRequest req = new HttpRequest();
        String contentID = '<' + ksgFunctions.generateRandomString(22) + '>';
        String boundary = string.valueOf(UserInfo.getOrganizationId()) + '_' + ksgFunctions.generateRandomString(16) ;       
        String headerXml = '--' + boundary + '\r\nContent-Type: application/soap+xml; charset=UTF-8\r\nContent-Transfer-Encoding: binary\r\nContent-ID: '+ contentID + '\r\n\r\n';
        String footer = '\r\n--' + boundary + '--'; 
        if(soapAction == 'sendKostenvoranschlagData') {
            Curabox_Genehmigung__c gen = readGenehmigung(genid);

            ContentVersion doc = readDocumentBody(gen);
            if(doc == null) {
                writeSingleError('makeMultipartHttpRequest', genid, '701', 'document "Antrag_PG... not found', null );   
                return null;  
            }
            String documentID = doc.title;
            if(!documentID.containsIgnoreCase('.pdf')) {
                documentID =  doc.title + '.pdf';
            }
            // attachment att = readAttachment(gen);
            String headerAtt =  '\r\n\r\n--' + boundary + '\r\nContent-Type: application/octet-stream\r\nContent-Transfer-Encoding: base64\r\nContent-ID: ' + documentID + '\r\n\r\n';
            String bodyEncoded = EncodingUtil.base64Encode(doc.VersionData);
            String xmlData = makeKVstring(gen, documentID);
            if(xmlData == null) {
                return null;
            }
            xmlString += xmlData;

            req.setBody(headerXml + xmlString + headerAtt + bodyEncoded + footer);
        }
        // else {
        //     xmlString += makeRetrieveKostenvoranschlagData(genId); 
        //     xmlString += '</soap:Body>';
        //     xmlString += '</soap:Envelope>';  
        //     req.setBody(headerXml + xmlString + footer);
        //     req.setHeader('Content-length', string.valueOf(req.getBody().length()));
        // }
        req.setMethod('POST');
        req.setCompressed(true); 
        req.setHeader('SOAPAction', '"urn:' + soapAction + '"');
        req.setHeader('Connection', 'Keep-Alive');
        req.setHeader('Content-Type', 'multipart/related; boundary="' + boundary + '"; type="application/soap+xml"; start="' + contentID + '"');
        req.setTimeout(120000);
        return req;
    } 

    // read Genehmigung
    @TestVisible private Curabox_Genehmigung__c readGenehmigung(string genid) {
        Curabox_Genehmigung__c gen = [SELECT contact__c, Nach_Paragraph__c, kvnr_azh__c, KV_status__c, Antrag_eingegangen_am__c 
                                        FROM Curabox_Genehmigung__c WHERE id = : id.valueOf(genid)];
        return gen;
    }
    
    @TestVisible private String mengeneinheitAZH(String Einheit) {
        String me = '10';
        if(Einheit == 'STCK') return '10';
        if(Einheit == 'PCKG') return '110';
        return me;
    }

    // read Antrag as file 
    @TestVisible private ContentVersion readDocumentBody(Curabox_Genehmigung__c gen) {
        String dname = 'Antrag_PG' + gen.Nach_Paragraph__c;
        List<ContentVersion> docList;
        try {
                    docList = [SELECT Title, VersionData, FileExtension 
                                FROM ContentVersion 
                                WHERE FirstPublishLocationId = : gen.contact__c  
                                    // AND IsMajorVersion = true
                                    AND Title = :dname
                                    ORDER BY createddate desc
                                    LIMIT 1];
            if((docList != null) && (docList.size() > 0)) {
                return docList[0];
            }  
            else 
            {
                    dname = 'Antrag_PG5X';    
                        docList = [SELECT Title, VersionData, FileExtension 
                                    FROM ContentVersion 
                                    WHERE FirstPublishLocationId = : gen.contact__c  
                                        // AND IsMajorVersion = true
                                        AND Title = :dname
                                        ORDER BY createddate desc
                                        LIMIT 1];
                if((docList != null) && (docList.size() > 0)) {
                    return docList[0];
                }  
                else {
                    return null;
                } 
            }  
            
            
        }
        catch (System.Exception e) {
            System.debug('############# error' + e);
            return null;
        }
    }

    // fill map/List from XML
    @TestVisible private void prepareXML(Dom.XMLNode root) {
        try {
            for(Dom.XMLNode child : root.getChildElements()) {
                if(!string.isEmpty(child.getText()) ) {
                    xmlRecord rec = new xmlRecord();
                    xmlMap.put(xmlKey + ':' + child.getName(),  child.getText());
                    rec.key = xmlKey + ':' + child.getName();
                    rec.value = child.getText();
                    xmlList.add(rec);
                }
                else {
                    if(string.isEmpty(xmlKey )) {
                        xmlKey = root.getName();
                    }
                    else {
                        xmlKey += ':' + root.getName();
                    }
                    if(xmlKey.indexOf(':') == 0) {
                        xmlKey = xmlKey.substring(1);
                    }               
                    prepareXML(child);
                }
            }
            integer li = xmlKey.lastIndexOf(':');        
            if(li > 0) {
                xmlKey = xmlKey.substring(0, li);
            }
        }
        catch (System.Exception e) {
            //TODO: error handling
        }
    }

    // make retrieveKostenvoranschlagData xmlString
    @TestVisible private String makeRetrieveKostenvoranschlagData(string genid) {
        String xmlString = 'error';
        Curabox_Genehmigung__c gen = readGenehmigung(genid);
        if(!String.isEmpty(gen.kvnr_azh__c)) {
            xmlString = '<ws:retrieveKostenvoranschlagData>';
                xmlString += '<ws:ids>';
                    xmlString += '<xsd:kvnr_azh>' + gen.kvnr_azh__c + '</xsd:kvnr_azh>';
                    xmlString += '<xsd:kvnr_bsw>' + genid + '</xsd:kvnr_bsw>';
                    xmlString += '<xsd:leistungserbringerIk>' + companyInfo.IK_Nummer__c + '</xsd:leistungserbringerIk>';
                xmlString += '</ws:ids>'; 
                xmlString += '<ws:identifikation><xsd:adresse/><xsd:adresseAnsprechpartner/><xsd:ik>' + companyInfo.IK_Nummer__c + '</xsd:ik></ws:identifikation>'; 
            xmlString += '</ws:retrieveKostenvoranschlagData>';
        }
        return xmlString;
    }

    // make retrieveAnhang xmlString
    @TestVisible private String makeRetrieveAnhang(string genid) {
        String xmlString = 'error';
        Curabox_Genehmigung__c gen = readGenehmigung(genid);
        if(!String.isEmpty(gen.kvnr_azh__c)) {
            xmlString = '<ws:retrieveAnhang>';
                xmlString += '<ws:statusabfrage>';
                    xmlString += '<xsd:kvnr_azh>' + gen.kvnr_azh__c + '</xsd:kvnr_azh>';
                    xmlString += '<xsd:kvnr_bsw>' + genid + '</xsd:kvnr_bsw>';
                xmlString += '</ws:statusabfrage>'; 
            xmlString += '</ws:retrieveAnhang>';
        }
        return xmlString;
    }

    // make retrieveAnhangEntscheidung xmlString
    @TestVisible private String makeRetrieveAnhangEntscheidung(string genid) {
        String xmlString = 'error';
        Curabox_Genehmigung__c gen = readGenehmigung(genid);
        if(!String.isEmpty(gen.kvnr_azh__c)) {
            xmlString = '<ws:retrieveAnhangEntscheidung>';
                xmlString += '<ws:statusabfrage>';
                    xmlString += '<xsd:kvnr_azh>' + gen.kvnr_azh__c + '</xsd:kvnr_azh>';
                    xmlString += '<xsd:kvnr_bsw>' + genid + '</xsd:kvnr_bsw>';
                xmlString += '</ws:statusabfrage>'; 
            xmlString += '</ws:retrieveAnhangEntscheidung>';
        }
        return xmlString;
    }

    // make retrieveNachricht xmlString
    @TestVisible private String makeRetrieveNachricht(string genid) {
        String xmlString = 'error';
        Curabox_Genehmigung__c gen = readGenehmigung(genid);
        if(!String.isEmpty(gen.kvnr_azh__c)) {
            xmlString = '<ws:retrieveNachricht>';
                xmlString += '<ws:kvnr_azh>' + gen.kvnr_azh__c + '</ws:kvnr_azh>';
                xmlString += '<ws:kvnr_bsw>' + genid + '</ws:kvnr_bsw>';
            xmlString += '</ws:retrieveNachricht>';
        }
        return xmlString;
    }

    // process responce data
    @TestVisible private void processResponce() {
        for(String key : xmlMap.keySet()) {
            system.debug('### key=' + key + ' value=' + xmlMap.get(key));
        }
        for(xmlRecord xr : xmlList) {
            system.debug('### xkey=' + xr.key + ' xvalue=' + xr.value);
        }
    }

    // process responce Status/return data
    public void processResponceReturn(String requestname) {
        string code = null;
        string message = null;
        string genid = null;
        string kvnr_azh = null;
        String keyString = 'Envelope:Body:' + requestname + 'Response:';
        List<Curabox_Genehmigung_AZH_responce__c> answerList = new List<Curabox_Genehmigung_AZH_responce__c>();
        // String dateiname = null;
        List<String> dateiname = new List<String>();
        if(xmlList.size() == 0) {
            if(!String.isEmpty(currentGenId)) {
                Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                answer.Curabox_Genehmigung__c = id.valueOf(currentGenId);
                answer.code__c = '000';
                answer.Message__c = 'Empty answer';
                answer.request__c = requestname;
                answerList.add(answer);    
                try {
                    if(!answerList.isEmpty()) {
                        insert answerList;
                    }
                }
                catch(System.Exception e) {
                    // TODO: Errorhandling
                }           
            }
    // test
                if(pdf.size() > 0) {
                    if (requestname != 'sendKostenvoranschlagData') {
                        // für sendKostenvoranschlagData nicht speichern - es kommt das originaldokument zurück
                        List<ContentVersion> cv2insert = new List<ContentVersion>();
                        for(Integer i=0; i<pdf.size(); i++) {
                            String title = requestname + '_Responce';
                            if((dateiname.size() > i) && (dateiname[i] != null)) {
                                title = dateiname[i];
                            }
                            if(!title.ContainsIgnoreCase('.PDF')) {
                                title += '.PDF';
                            }
                            ContentVersion cv = new ContentVersion(Title= title);
                            cv.VersionData = pdf[i];
                            cv.PathOnClient = title;
                            cv.FirstPublishLocationId = id.valueOf(currentGenId);
                            cv.ContentLocation = 'S';
                            cv2insert.add(cv);
                        }
                        try{
                            insert cv2insert;
                            //Curabox_Genehmigung__c gen = readGenehmigung(genid);
                            //gen.KV_Status__c = 'closed';
                            //update gen;                        
                        }
                        catch(System.Exception e) {
                            writeSingleError('processResponceReturn', genid, '710', 'error write file (pdf)', string.valueOf(e.getLineNumber()) + ' ' + e.getMessage());               
                        }
                    }
                }
    // test

        }
        else {
            if  (requestname == 'checkInfopool') { 
                // kann mehrere KV's betreffen
                integer entryCounter = processInfopool();
                if(entryCounter > 0) {
                    processInfopoolEntry();
                }
            }
            else if (requestname == 'sendKostenvoranschlagData') {    
                String kvstatus = 'send';       
                for(xmlRecord r : xmlList) {
                    if(r.key.contains('code')) code = r.value;
                    if(r.key.contains('kvnr_azh')) kvnr_azh = r.value;
                    if(r.key.contains('kvnr_bsw')) genid = r.value;
                    response_kvnr_bsw = genid;
                    if(r.key.contains('message')) {
                        message = r.value;
                        Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                        answer.Curabox_Genehmigung__c = id.valueOf(genid);
                        answer.code__c = code;
                        answer.Message__c = message;
                        answer.request__c = requestname;
                        answerList.add(answer);
                        integer codei = integer.valueOf(code);
                        if((codei == 501) || (codei == 503)) {
                            kvstatus = 'pending';
                        }
                        else if((codei > 503) && (codei < 599)) {
                            kvstatus = 'closed';
                        }
                        else if(codei == 110) {
                            // send again ()
                            // mit jobscheduler, so:
                            System.schedule('sendKostenvoranschlagData Fax ' + string.valueOf(genid) , '0 5 * * * ?', new azhRetrieveData('sendKostenvoranschlagData', genid));
                        }
                        else if(codei == 419) {
                            // send again ()
                            System.schedule('sendKostenvoranschlagData Fax ' + string.valueOf(genid) , '0 5 * * * ?', new azhRetrieveData('sendKostenvoranschlagData', genid));
                        }
                        else {
                            kvstatus = 'error';
                        }
                        
                    }
                }
                try {
                    if(!answerList.isEmpty()) {
                        insert answerList;
                    }
                    if(!String.isEmpty(genid)) {
                        Curabox_Genehmigung__c gen = readGenehmigung(genid);
                        gen.kvnr_azh__c = kvnr_azh;
                        gen.KV_status__c = kvstatus;
                        update gen;
                    }
                }
                catch(System.Exception e) {
                    // TODO: Errorhandling

                }           
            }
            else if (requestname == 'retrieveKostenvoranschlagData') {
                genid = xmlMap.get(keyString + 'kostenvoranschlag:kostentraegerentscheidung:kvnr_bsw');
                response_kvnr_bsw = genid;
                kvnr_azh = xmlMap.get(keyString + 'kostenvoranschlag:kostentraegerentscheidung:kvnr_azh');
                String GenehmigungsNummer = xmlMap.get(keyString + 'kostenvoranschlag:genehmigungsnummer');
                code = xmlMap.get(keyString + 'kostenvoranschlag:kostentraegerentscheidung:code');
                message = xmlMap.get(keyString + 'kostenvoranschlag:kostentraegerentscheidung:message');

                Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                answer.Curabox_Genehmigung__c = id.valueOf(genid);
                answer.code__c = code;
                answer.Message__c = message;
                answer.request__c = requestname;
                answerList.add(answer);
                String status = null;
                if(code == '507') {
                    // status = 'Bewilligung';
                }
                else if(code == '509') {
                    status = 'Ablehnung';
                }
                 
                try {
                    if(!answerList.isEmpty()) {
                        insert answerList;
                        // Genehmigt / Abgelent
                        if(!String.isEmpty(kvnr_azh)) {
                            Curabox_Genehmigung__c gen = readGenehmigung(genid);
                            gen.kvnr_azh__c = kvnr_azh;
                            gen.Genehmigungsnummer__c = GenehmigungsNummer;
                            if(status != null) {
                                gen.Status__c = status;
                            }
                            update gen;
                        }
                    }
                }
                catch(System.Exception e) {
                    // TODO: Errorhandling
                }              
            }
            else if (requestname == 'retrieveNachricht') {
                genid = xmlMap.get(keyString + 'kvnr_bsw');
                response_kvnr_bsw = genid;
                kvnr_azh = xmlMap.get(keyString + 'kvnr_azh');
                for(xmlRecord r : xmlList) {
                    if(r.key.contains('code')) code = r.value;
                    if(r.key.contains('kvnr_azh')) kvnr_azh = r.value;
                    if(r.key.contains('kvnr_bsw')) genid = r.value;
                    if(r.key.contains('message')) {
                        message = r.value;
                        Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                        answer.Curabox_Genehmigung__c = id.valueOf(genid);
                        answer.code__c = code;
                        answer.Message__c = message;
                        answer.request__c = requestname;
                        answerList.add(answer);
                    }
                }
                try {
                    if(!answerList.isEmpty()) {
                        insert answerList;
                    }
                    if(!String.isEmpty(genid)) {
                        Curabox_Genehmigung__c gen = readGenehmigung(genid);
                        gen.kvnr_azh__c = kvnr_azh;
                        update gen;
                    }
                }
                catch(System.Exception e) {
                    // TODO: Errorhandling
                }            
            }
            else if (requestname == 'retrieveAnhangEntscheidung') {
                genid = xmlMap.get(keyString + 'kvnr_bsw');
                response_kvnr_bsw = genid;
                kvnr_azh = xmlMap.get(keyString + 'kvnr_azh');

                // dateiname = xmlMap.get(keyString + 'dateiname');
                for(xmlRecord x : xmlList) { 
                    if(x.key.contains('dateiname')) {
                        dateiname.add(x.value);
                    }
                }
                message = 'PDF Datei generiert bei AZH';
                Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                answer.Curabox_Genehmigung__c = id.valueOf(genid);
                answer.code__c = '200';
                answer.Message__c = message;
                answer.request__c = requestname;
                answerList.add(answer);    
                try {
                    if(!answerList.isEmpty()) {
                        insert answerList;
                    }
                }
                catch(System.Exception e) {
                    // TODO: Errorhandling
                }             
            }

            system.debug('#### handle attachment pdf=' + pdf);
            // if(pdf != null) {
            if(pdf.size() > 0) {
                if (requestname != 'sendKostenvoranschlagData') {
                    // für sendKostenvoranschlagData nicht speichern - es kommt das originaldokument zurück
                    List<ContentVersion> cv2insert = new List<ContentVersion>();
                    for(Integer i=0; i<pdf.size(); i++) {
                        String title = requestname + '_Responce';
                        if(dateiname[i] != null) {
                            title = dateiname[i];
                        }
                        ContentVersion cv = new ContentVersion(Title= title);
                        cv.VersionData = pdf[i];
                        cv.PathOnClient = title;
                        cv.FirstPublishLocationId = genid;
                        cv.ContentLocation = 'S';
                        cv2insert.add(cv);
                    }
                    try{
                        insert cv2insert;
                        Curabox_Genehmigung__c gen = readGenehmigung(genid);
                        gen.KV_Status__c = 'closed';
                        update gen;                        
                    }
                    catch(System.Exception e) {
                        writeSingleError('processResponceReturn', genid, '710', 'error write file (pdf)', string.valueOf(e.getLineNumber()) + ' ' + e.getMessage());               
                    }
                }
            }
            else {
                if (requestname == 'retrieveKostenvoranschlagData') {
                    system.debug('#### ohne pdf xmlString=' + saveXmlString);
                    ContentVersion cv = new ContentVersion(Title= 'Entscheidung.XML');
                    cv.VersionData = blob.valueOf(saveXmlString);
                    cv.PathOnClient = 'Entscheidung.XML';
                    cv.FirstPublishLocationId = genid;
                    cv.ContentLocation = 'S';
                    try{
                        // insert cv;
                    }
                    catch(System.Exception e) {
                        writeSingleError('processResponceReturn', genid, '710', 'error write file (pdf)', string.valueOf(e.getLineNumber()) + ' ' + e.getMessage());               
                    }                    
                    if(!test.isRunningTest()) {
                        System.schedule('retrieveAnhangEntscheidung ' + genid, '0 1 * * * ?', new azhRetrieveData('retrieveAnhangEntscheidung', genid));
                        // retrieveAnhangEntscheidung(genId, false);
                    }
                }
            }
        
            // debug
            for(String key : xmlMap.keySet()) {
                system.debug('### key=' + key + ' value=' + xmlMap.get(key));
            }
            for(xmlRecord xr : xmlList) {
                system.debug('### xkey=' + xr.key + ' xvalue=' + xr.value);
            }
        }
    }

    @TestVisible private integer processInfopool() {
        // kennzeichen 
        // 1 Direktauftrag von Kostenträger erhalten (*)
        // 2 Versorgungsanfragen von Kostenträger erhalten (*)
        // 3 Kostenvoranschlag vom Kostenträger geändert
        // 4 Kostenvoranschlag mit einer Fehlermeldung abgewiesen
        // 5 Entscheidung für einen Kostenvoranschlag eingegangen
        // (*) zunächst keine Bedeutung
        integer entryCounter = 0;
        String keyString = 'Envelope:Body:checkInfopoolResponse:';        
        string kennzeichen = null;
        string angelegt = null;
        string azh_id = null;
        string kvnr_azh = null;
        string kvnr_bsw = null;
        for(xmlRecord r : xmlList) {     
            String leistungserbringerIk = null;       
            if(r.key.contains('kvnr_azh')) kvnr_azh = r.value;
            if(r.key.contains('kvnr_bsw')) kvnr_bsw = r.value;
            if(r.key.contains('id')) azh_id = r.value;
            if(r.key.contains('leistungserbringerIk')) leistungserbringerIk = r.value;
            if(r.key.contains('kennzeichen')) kennzeichen = r.value;
            if(r.key.contains('angelegt')) {
                entryCounter++;
                angelegt  = r.value;
                infopoolresponce answer = new infopoolresponce();
                answer.kennzeichen = kennzeichen;
                answer.angelegt = angelegt;
                answer.azh_id = azh_id;
                answer.kvnr_azh = kvnr_azh;
                answer.kvnr_bsw = kvnr_bsw;
                answer.leistungserbringerIk = leistungserbringerIk;
                infopoolresponceList.add(answer);
                kennzeichen = null;
                angelegt = null;
                azh_id = null;
                kvnr_azh = null;
                kvnr_bsw = null;
            }
        }
        return entryCounter;
    }

    @TestVisible private void processInfopoolEntry() {
        // kennzeichen 
        // 1 Direktauftrag von Kostenträger erhalten (*)
        // 2 Versorgungsanfragen von Kostenträger erhalten (*)
        // 3 Kostenvoranschlag vom Kostenträger geändert
        // 4 Kostenvoranschlag mit einer Fehlermeldung abgewiesen
        // 5 Entscheidung für einen Kostenvoranschlag eingegangen
        // 6 Nachricht von Kostenträger eingegangen
        // (*) zunächst keine Bedeutung
        id genId;    
        List<Curabox_Genehmigung_AZH_responce__c> answerList = new List<Curabox_Genehmigung_AZH_responce__c>();
        Map<id, String> gen2updateMap = new Map<id, string>();
        for(infopoolresponce r : infopoolresponceList) {  
            if(r.kvnr_bsw != null) {
                genId = id.valueOf(r.kvnr_bsw);
            }
            else {
                genId = getGenIdFromAzhId(r.kvnr_azh);
            }
            if(genId != null) {
                gen2updateMap.put(genId, r.kennzeichen);
                Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                answer.Curabox_Genehmigung__c = genid;
                answer.code__c = r.kennzeichen;
                if(r.kennzeichen == '1') {
                    answer.Message__c = 'Direktauftrag von Kostenträger erhalten';    
                }
                if(r.kennzeichen == '2') {
                    answer.Message__c = 'Versorgungsanfragen von Kostenträger erhalten';    
                }
                if(r.kennzeichen == '3') {
                    answer.Message__c = 'Kostenvoranschlag vom Kostenträger geändert';    
                }
                if(r.kennzeichen == '4') {
                    answer.Message__c = 'Kostenvoranschlag mit einer Fehlermeldung abgewiesen';    
                }
                if(r.kennzeichen == '5') {
                    answer.Message__c = 'Entscheidung für einen Kostenvoranschlag eingegangen';    
                } 
                if(r.kennzeichen == '6') {
                    answer.Message__c = 'Nachricht von Kostenträger eingegangen';    
                }            
                answer.request__c = 'infopoolEntry';
                answerList.add(answer);
            }

        }
        if(!answerList.isEmpty()) {
            Database.SaveResult[]  srList = Database.insert(answerList, false); 
            for (Database.SaveResult sr : srList) {
                // ToDo: Errorhandling
            }
        }
        List<Curabox_Genehmigung__c> gen2updateList = [SELECT id, KV_Status__c FROM Curabox_Genehmigung__c WHERE id IN :gen2updateMap.keySet()];
        boolean rtvData = false;
        set<String> rtvSet = new Set<String>();
        if((gen2updateList != null) && (gen2updateList.size() > 0)) {
            for(Curabox_Genehmigung__c g : gen2updateList) {
                if(gen2updateMap.get(g.id) == '5') {
                    // g.KV_Status__c = 'closed';
                    rtvSet.add(String.valueOf(g.id));
                    rtvData = true;
                }
                else if(gen2updateMap.get(g.id) == '4') {
                    g.KV_Status__c = 'error';
                    rtvData = true;                    
                }
                else if(gen2updateMap.get(g.id) == '6') {
                    g.KV_Status__c = 'message received';
                    rtvData = true;                    
                }
                else {
                    g.KV_Status__c = 'error';
                }
            }
            Database.SaveResult[]  sruList = Database.update(gen2updateList, false); 
            for (Database.SaveResult sr : sruList) {
 
                // ToDo: Errorhandling
            }

            if(rtvData) {
                integer count = 1;
                for(String genids : rtvSet) {
                    // ????
                    // sendKVCheckRequest(genIds, 'retrieveKostenvoranschlagData');
                    // oder so:
                    // retrieveKostenvoranschlagData(genIds, false); 
                    // Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
                    // System.schedule('Scheduled retrieveKostenvoranschlagDat1 ' + string.valueOf(count), '0 1 * * * ?', new azhRetrieveInfoPool (genids));
                    // System.schedule('retrieveKostenvoranschlagData ' + string.valueOf(count), '0 ' + string.valueOf(count) + ' * * * ?', new azhRetrieveData('retrieveKostenvoranschlagData', genids));
                    
                    System.schedule('retrieveKostenvoranschlagData ' + genids, '0 ' + string.valueOf(count) + ' * * * ?', new azhRetrieveData('retrieveKostenvoranschlagData', genids));
                    count++;
                }
            }
        }
        
    }

    @testVisible private id getGenIdFromAzhId(String kvnr_azh) {
        if(kvnr_azh != null) {
            List<Curabox_Genehmigung__c> gnList = [SELECT id FROM Curabox_Genehmigung__c WHERE kvnr_azh__c = : kvnr_azh];
            if((gnList != null) && (gnList.size() > 0)) {
                return gnList[0].id;
            }
            else return null;
        }
        return null;
    }

    // read AZH credetials (custom setting)
    public azhCredetials__c readAzhCredentials() {
        try {
            azhCredetials__c azhc;
            if(isSandbox()) {
                azhc = azhCredetials__c.getValues('Sandbox');
            }
            else {
                azhc = azhCredetials__c.getValues('Production');
            }
            if((string.isEmpty(azhc.Endpoint__c)) || (string.isEmpty(azhc.User__c)) ||(string.isEmpty(azhc.password__c))) {
                // TODO: Errorhandling
                return null;
            }
            return azhc;
        }
        catch (System.Exception e) {
            // TODO: Errorhandling
            return null;
        }
    }

    // make SOAP header with azh credenitials
    public string makeSoapHeader(string user, string password) {
        string soapHeader = '<?xml version=\'1.0\' encoding=\'UTF-8\'?><soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:ws="http://ws.bswsnt.vsa" xmlns:xsd="http://ws.bswsnt.vsa/xsd">';
        soapHeader += '<soap:Header>';
        soapHeader += '<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd">';
        soapHeader += '<wsse:UsernameToken>';
        soapHeader += '<wsse:Username>' + user + '</wsse:Username>';
        soapHeader += '<wsse:Password>' + password + '</wsse:Password>';
        soapHeader += '</wsse:UsernameToken>';
        soapHeader += '</wsse:Security>';
        soapHeader += '</soap:Header>';
        return soapHeader;
    }

    @TestVisible private void writeSingleError(string function, string genid, string code, string message, string systemerror) {
        List<Curabox_Genehmigung_AZH_responce__c> answerList = new List<Curabox_Genehmigung_AZH_responce__c>();
        Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
        answer.Curabox_Genehmigung__c = id.valueOf(genid);
        if(code == null) code = '700';
        if(message == null) message = 'Programm error. check system message';
        answer.code__c = code;
        answer.Message__c = message;
        answer.request__c = function;
        answer.system_message__c = systemerror;
        answerList.add(answer);
        Database.SaveResult[]  srList = Database.insert(answerList, false); 
        List<Curabox_Genehmigung__c> gen2updateList = [SELECT id, KV_Status__c FROM Curabox_Genehmigung__c WHERE id = :id.valueOf(genid)];
        if((gen2updateList != null) && (gen2updateList.size() > 0)) {
            for(Curabox_Genehmigung__c g : gen2updateList) {
                g.KV_Status__c = 'error';
            }
            Database.SaveResult[]  sruList = Database.update(gen2updateList, false); 
            for (Database.SaveResult sr : sruList) {
                // ToDo: Errorhandling
            }
        }        
    }

    // KK privat => sofort bewilligt
    @TestVisible private boolean isPrivat(String genid) {
        
        List<Curabox_Genehmigung__c> gl = [SELECT id, KV_Status__c, Status__c
                                        FROM Curabox_Genehmigung__c WHERE id = : id.valueOf(genid)
                                        AND Contact__r.Kranken_Pflegekasse__r.Kanal_Unterpunkt__c = 'privat'];
        if((gl != null) && (gl.size() > 0)) {
            system.debug('############ privat');
            gl[0].KV_Status__c = 'closed';
            gl[0].Status__c= 'Bewilligung';
            Database.SaveResult[]  guList = Database.update(gl, false);
            for(Database.SaveResult dr : guList) { 
                if (dr.isSuccess()) {
                    Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                    answer.Curabox_Genehmigung__c = dr.getId();
                    answer.Message__c = 'Bewilligung. Private Kasse';
                    answer.request__c = 'sendKostenvoranschlagData';
                    answer.code__c = '507';
                    Database.SaveResult  sr = Database.insert(answer, false);   
                    return true;                                     
                }
            }
        }
        return false;
    } 

 // KK privat => sofort bewilligt
    @TestVisible private boolean isAutomaticallyApproved(String genid) {
        
        List<Curabox_Genehmigung__c> gl = [SELECT id, KV_Status__c, Status__c, Nach_Paragraph__c, 
                                                    Contact__r.Kranken_Pflegekasse__r.KV_54_Automatically_Approved__c, 
                                                    Contact__r.Kranken_Pflegekasse__r.KV_51_Automatically_Approved__c
                                        FROM Curabox_Genehmigung__c WHERE id = : id.valueOf(genid)
                                        AND (Contact__r.Kranken_Pflegekasse__r.KV_51_Automatically_Approved__c = true 
                                            OR Contact__r.Kranken_Pflegekasse__r.KV_54_Automatically_Approved__c = true)];
        if((gl != null) && (gl.size() > 0)) {
            system.debug('############ automat. approved');
            if((((gl[0].Nach_Paragraph__c == '51') || (gl[0].Nach_Paragraph__c == '5X')) && gl[0].Contact__r.Kranken_Pflegekasse__r.KV_51_Automatically_Approved__c == true) 
                || (((gl[0].Nach_Paragraph__c == '54') || (gl[0].Nach_Paragraph__c == '5X')) && gl[0].Contact__r.Kranken_Pflegekasse__r.KV_54_Automatically_Approved__c == true)) {

                
                gl[0].KV_Status__c = 'closed';
                gl[0].Status__c= 'Bewilligung';
                Database.SaveResult[]  guList = Database.update(gl, false);
                for(Database.SaveResult dr : guList) { 
                    if (dr.isSuccess()) {
                        Curabox_Genehmigung_AZH_responce__c answer = new Curabox_Genehmigung_AZH_responce__c();
                        answer.Curabox_Genehmigung__c = dr.getId();
                        answer.Message__c = 'Automatische Bewilligung. Sonderegelung Kasse';
                        answer.request__c = 'sendKostenvoranschlagData';
                        answer.code__c = '507';
                        Database.SaveResult  sr = Database.insert(answer, false);   
                        return true;                                     
                    }
                }
                }
        }
        return false;
    } 

    // check prod or sandbox
    public boolean isSandbox() {
        return [SELECT Id, IsSandbox FROM Organization LIMIT 1].IsSandbox;
    } 

    // public interface for sendKostenvoranschlagData
    @future(callout=true)
    public static void sendKostenvoranschlagData(string genId) {
        azhWebClient client = new azhWebClient();
        if((!client.isPrivat(genid)) && (!client.isAutomaticallyApproved(genid))) {
            client.sendKVCheckRequest(genId, 'sendKostenvoranschlagData');
        }
    }

    // public interface for checkInfopool
    @future(callout=true)
    public static void checkInfopool() {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(null, 'checkInfopool');
    }

    public static void checkInfoPoolAsync() {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(null, 'checkInfopool');        
    }

    // public interface for retrieveKostenvoranschlagData
    @future(callout=true)
    public static void retrieveKostenvoranschlagData(string genId) {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(genId, 'retrieveKostenvoranschlagData');
    }
    // call directly 
    public void retrieveKostenvoranschlagData(string genId, boolean dir) {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(genId, 'retrieveKostenvoranschlagData');
    }

    // public interface for retrieveAnhang
    @future(callout=true)
    public static void retrieveAnhang(string genId) {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(genId, 'retrieveAnhang');
    }

    public static void retrieveAnhang(string genId, boolean dir) {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(genId, 'retrieveAnhang');
    }

    // public interface for retrieveAnhangEntscheidung
    @future(callout=true)
    public static void retrieveAnhangEntscheidung(string genId) {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(genId, 'retrieveAnhangEntscheidung');
    }
    // call directly
    public void retrieveAnhangEntscheidung(string genId, boolean dir) {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(genId, 'retrieveAnhangEntscheidung');
    }

    // public interface for retrieveNachricht
    @future(callout=true)
    public static void retrieveNachricht(string genId) {
        azhWebClient client = new azhWebClient();
        client.sendKVCheckRequest(genId, 'retrieveNachricht');
    }


    public String getresponse_kvnr_bsw() {
        return response_kvnr_bsw;
    }

    private map<id, decimal> makePrice() {
        map<id, decimal> groupPrice = new map<id, Decimal>();
        List<Product__c> prList = [select Price__c, Product_Group__c FROM Product__c where price__c != null];
        if((prList != null) && (prList.size() > 0)) {
            for(Product__c pr : prList) {
                groupPrice.put(pr.Product_Group__c, pr.Price__c);
            }
        }

        return groupPrice;
    }

    private static String maskString(String input){
        String output;
        output = input.replace('&', '&amp;')
                .replace('<', '&lt;')
                .replace('>', '&gt;')
                .replace('"', '&quot;');
        return output;
    } 

}