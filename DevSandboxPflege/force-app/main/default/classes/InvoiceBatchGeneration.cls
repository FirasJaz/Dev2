global with sharing class InvoiceBatchGeneration {      
    private Rechnung__c[] RG_List;    
    private Rechnungsposition__c[] RG_Positionen_List;  
    
    private Map<ID, Anschrift__c> MapKdAnschr = new Map<ID, Anschrift__c>() ;     
    private Map<ID, Kunde__c> MapKunde = new Map<ID, Kunde__c>() ;     
    private Map<ID, List<Rechnungsposition__c>> MapRgPosition = new Map<ID, List<Rechnungsposition__c>>() ;          
    private List<Attachment> RG_attach_List = new list<Attachment>();    
    Set<ID> KundeIDSet = new Set<ID>();     
    Set<ID> RechnungIDSet = new Set<ID>();  

    //private CompanyInfo__c FirmenInfo {get; set;}
    //private string kdnrBeiHartmann{get; set;} 
    //private Organization orgDetails {get; set;}
    
    public Integer noOfRecords{get; set;}
    public Integer size{get;set;}
    public boolean ButtonGenerate = false;
    public integer list_size=20; //sets the page size or number of rows
    
    public InvoiceBatchGeneration (){
    }

    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
    }
    public boolean getButtonGenerate () {
        if(setCon != null && noOfRecords != 0){
            return true;
        } else return false;
    }
   
    public List<Rechnung__c> zumAbrechnen  
    {  
        get  
        {  
            if(setcon != null)  
                return (List<Rechnung__c>)setcon.getRecords();  
            else  
                return null ;  
        }  
        set;
    }
    
    public ApexPages.StandardSetController setCon {
        get{
            if(setCon == null){
                size = list_size;
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT r.Id, r.PDF_generiert__c, r.name, r.Gesamtpreis_Netto__c, r.MWSt1__c,                     
                       r.kunde__r.Stra_e__c, r.kunde__r.Hausnummer__c, r.kunde__r.PLZ__c, 
                       r.kunde__r.Ort__c, r.kunde__r.Kundennummer__c , r.Kunde__r.Vorname__c , r.Kunde__r.Name__c, r.Kunde__r.Name                
                       FROM Rechnung__c r where r.PDF_generiert__c = false
                       ORDER BY r.Name]));
                setCon.setPageSize(size);
                noOfRecords = setCon.getResultSize();
            }
            return setCon;
        }set;
    }
        
    public PageReference generatePdf() {         
        try{             
            RG_List = [SELECT r.Id, r.PDF_generiert__c, r.name, r.Gesamtpreis_Netto__c, r.MWSt1__c,                     
                       r.kunde__r.Stra_e__c, r.kunde__r.Hausnummer__c, r.kunde__r.PLZ__c, 
                       r.kunde__r.Ort__c, r.kunde__r.Kundennummer__c , r.Kunde__r.Vorname__c , r.Kunde__r.Name__c, r.Kunde__r.Name                
                       FROM Rechnung__c r where r.PDF_generiert__c = false
                       ORDER BY r.Name
                       limit 100]; 
            
            if((RG_List != null) && (RG_List .size() >0)) {
                for(Rechnung__c RG : RG_List){  
                    if(create_pdf_attach(RG)){
                    	//update PDF_generiert flag
                        RG.PDF_generiert__c = true;
                    }
                }            
            } 

            system.debug ('################################################# Mansi ::RG_attach_List.size()::' + RG_attach_List.size());
        }catch (System.Queryexception q) {                 
            system.debug ('################################################# No Rechnung found');         
        }
        
        try{
            insert RG_attach_List;
            update RG_List;
        }catch (System.DmlException e) {                 
            system.debug ('################################################# Mansi:: insert attachment error::'+ e);         
        } 
         
        PageReference pr = new PageReference('/apex/invoice_batch_generation');
        pr.setRedirect(true);
        return pr;            
     
    }
    
    public boolean create_pdf_attach(Rechnung__c rechnung){          
        try {
           Blob pdf_blob;   
           system.debug('######################### Mansi:: create_pdf_attach::' + string.valueOf(rechnung.Id));
           PageReference RG_PDF = new PageReference('/apex/SRG_nur_anzeigen?id=' + string.valueOf(rechnung.Id));
           pdf_blob = RG_PDF.getContent();              
           Attachment pdf_attach = new Attachment();              
           pdf_attach.body = pdf_blob;              
           pdf_attach.Name = rechnung.Name +'.pdf';              
           pdf_attach.ParentId = rechnung.Id;   
           RG_attach_List.add(pdf_attach);
           return true;          
        }catch (VisualforceException e) {               
           system.debug('######################### Mansi:: Error getContent e=' + e);          
        }          
        return false;      
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
    
  
    /*
    public void fillLists(){                    
        FirmenInfo = CompanyInfo__c.getValues('Default');
        kdnrBeiHartmann = FirmenInfo.KDNR_bei_Lieferant__c;     

        orgDetails = [SELECT Id, Name, Street, PostalCode, City, Country, State, Fax, Phone 
                                FROM Organization 
                                WHERE Id = :UserInfo.getOrganizationId()];
        
        for (Rechnung__c RG : RG_List) {              
            if(!RechnungIDSet.contains(RG.Id)){                  
                RechnungIDSet.add(RG.Id);              
            }              
            // Set mit Kunden ID              
            if(!KundeIDset.contains(RG.Kunde__c)) {                                                                                           
                KundeIDSet.add(RG.Kunde__c);
                //to support customers without address in Anschrift__c
                MapKdAnschr.put(RG.Kunde__c, new Anschrift__c(Stra_e__c = RG.kunde__r.Stra_e__c, Hausnummer__c = RG.kunde__r.Hausnummer__c, PLZ__c = string.ValueOf(RG.kunde__r.PLZ__c), Ort__c = RG.kunde__r.Ort__c));
            }          
        }                   
        // Anschrift finden              
        List<Anschrift__c> ListAn = [SELECT Name, Stra_e__c, PLZ__c, Ort__c, Hausnummer__c, Telefon__c,                   
                                     interne_Notiz__c, Liefernotiz__c, komb_Adresse__c, Kunde__c                  
                                     FROM Anschrift__c WHERE Standardlieferanschrift__c = true AND Kunde__c IN :KundeIDset ];              
        system.debug('######################### Mansi ListAn.size()=' + ListAn.size());                              
        if (ListAn != null && ListAn.size() != 0) {                    
            for (Anschrift__c An : ListAn){                            
                MapKdAnschr.put(An.Kunde__c, An);                       
            }              
        }         
                                                                          
        RG_Positionen_List = [SELECT SystemModstamp, Rechnung__c, Name, Einzelpreis__c,Gesamtpreis_Brutto__c, 
                              Gesamtpreis_Netto__c, MWSt1__c,Id,                                  
                              Lieferscheinposition__r.Artikel__r.Name,
                              Lieferscheinposition__r.Artikel__r.Menge_ABDA__c
                              FROM Rechnungsposition__c                           
                              WHERE Rechnung__c IN :RechnungIDSet];                                          
        if (RG_Positionen_List != null && RG_Positionen_List.size() != 0) {                    
            List<Rechnungsposition__c> tmpRpList = new List<Rechnungsposition__c>();                   
            for (Rechnungsposition__c RP : RG_Positionen_List){                                    
                if(!MapRgPosition.containsKey(RP.Rechnung__c)){                           
                    tmpRpList = new List<Rechnungsposition__c>();                       
                }                       
                tmpRpList.add(RP);                       
                MapRgPosition.put(RP.Rechnung__c, tmpRpList);                          
            }              
        }                        
    }            
    */
  
    /*               
    public boolean create_xml_attach(Rechnung__c  RG){   
        boolean error = false;
        try {
            system.debug('######################### Mansi:: create_xml_attach'); 
            Anschrift__c PdAnschr = MapKdAnschr.get(RG.Kunde__c);
            Datetime curDate = Datetime.now();
            string datumHeute = curDate.format('YYYYMMdd');
            string zeitJetzt = curDate.format('HHmmss');
            list<Rechnungsposition__c> rpl = MapRgPosition.get(RG.ID);
            
            Xmlstreamwriter xmlW = new Xmlstreamwriter();
            xmlW.writeStartDocument('utf-8','1.0');
            xmlW.writeStartElement(null,'PHRechnungs', null);
            xmlW.writeAttribute(null,null,'xmlns:xsi','http://www.w3.org/2001/XMLSchema-instance');
            
            // PHTransfer
            xmlW.writeStartElement(null,'PHTransfer', null);
                xmlW.writeStartElement(null,'SenderID', null);
                    xmlW.writeCharacters(kdnrBeiHartmann);
                xmlW.writeEndElement();               
                xmlW.writeStartElement(null,'ReceiverID', null);
                    xmlW.writeCharacters('4049500000000');
                xmlW.writeEndElement();            
                xmlW.writeStartElement(null,'Date', null);
                    xmlW.writeCharacters(datumHeute);
                xmlW.writeEndElement();     
                xmlW.writeStartElement(null,'Time', null);
                    xmlW.writeCharacters(zeitJetzt);
                xmlW.writeEndElement(); 
                //xmlW.writeStartElement(null,'VersionID', null);
                    //xmlW.writeCharacters('1.8.3');
                //xmlW.writeEndElement();                
            xmlW.writeEndElement();
            // PHTransfer            
            
            xmlW.writeStartElement(null,'Rechnung', null);
            //xmlW.writeAttribute(null,null,'type','TA');

                    xmlW.writeStartElement(null,'RechnungHeader', null);
                    xmlW.writeStartElement(null,'ReferencedRechnung', null);
                        xmlW.writeStartElement(null,'RechnungNumber', null);
                            xmlW.writeCharacters(RG.Name + ' - ' + RG.Kunde__r.Kundennummer__c);
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'Gesamtsumme', null);
                            xmlW.writeCharacters(string.valueOf(RG.Gesamtpreis_Netto__c));
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'Mehrwertsteuer', null);
                            xmlW.writeCharacters(string.valueOf(RG.MWSt1__c));
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'ReferenceID', null);
                            xmlW.writeCharacters(RG.Name);
                        xmlW.writeEndElement();             
                    //ReferencedRechnung 
                    xmlW.writeEndElement(); 
                    
                    xmlW.writeStartElement(null,'BuyerParty', null);
                        xmlW.writeStartElement(null,'PartnerID', null);
                        xmlW.writeAttribute(null,null,'type','Distributor');
                            xmlW.writeCharacters(kdnrBeiHartmann);
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'PartnerName1', null);
                            xmlW.writeCharacters(orgDetails.Name);
                        xmlW.writeEndElement(); 
                        xmlW.writeStartElement(null,'PartnerAddress', null);
                            xmlW.writeCharacters(orgDetails.Street );
                        xmlW.writeEndElement();  
                        xmlW.writeStartElement(null,'PartnerPostalCode', null);
                            xmlW.writeCharacters(orgDetails.PostalCode);
                        xmlW.writeEndElement();                         
                        xmlW.writeStartElement(null,'PartnerCity', null);
                            xmlW.writeCharacters(orgDetails.City );
                        xmlW.writeEndElement();     
                        xmlW.writeStartElement(null,'PartnerCountryCode', null);
                            xmlW.writeCharacters('DE');
                        xmlW.writeEndElement();                         
                        xmlW.writeStartElement(null,'PartnerPhone', null);
                            xmlW.writeCharacters(FirmenInfo.Telefon__c);
                        xmlW.writeEndElement(); 
                        xmlW.writeStartElement(null,'PartnerFax', null);
                            xmlW.writeCharacters(FirmenInfo.Fax__c);
                        xmlW.writeEndElement();                         
                    // BuyerParty
                    xmlW.writeEndElement();  

                    xmlW.writeStartElement(null,'DestinationParty', null);
                        xmlW.writeStartElement(null,'PartnerID', null);
                        //xmlW.writeAttribute(null,null,'type','Distributor');
                             xmlW.writeCharacters(string.valueOf(RG.Kunde__r.Kundennummer__c));
                            //xmlW.writeCharacters('99999951');
                        xmlW.writeEndElement(); 
                        xmlW.writeStartElement(null,'RechnungsAddressName', null);
                            xmlW.writeCharacters(PdAnschr.Name);
                        xmlW.writeEndElement();      
                        xmlW.writeStartElement(null,'PartnerAddress', null);
                            xmlW.writeCharacters(PdAnschr.Stra_e__c );
                        xmlW.writeEndElement();     
                        xmlW.writeStartElement(null,'PartnerPostalCode', null);
                            xmlW.writeCharacters(PdAnschr.PLZ__c);
                        xmlW.writeEndElement();     
                        xmlW.writeStartElement(null,'PartnerCity', null);
                            xmlW.writeCharacters(PdAnschr.Ort__c );
                        xmlW.writeEndElement(); 
                        xmlW.writeStartElement(null,'PartnerCountryCode', null);
                            xmlW.writeCharacters('DE');
                        xmlW.writeEndElement();                                                 
                    // DestinationParty
                    xmlW.writeEndElement();

                    xmlW.writeStartElement(null,'SellerParty', null);
                        xmlW.writeStartElement(null,'PartnerID', null);
                        xmlW.writeAttribute(null,null,'type','EAN');
                            xmlW.writeCharacters('4049500000000');
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'PartnerName1', null);
                            xmlW.writeCharacters('Paul Hartmann AG');
                        xmlW.writeEndElement();             
                        //SellerParty
                    xmlW.writeEndElement();    
            
                // RechnungHeader 
                xmlW.writeEndElement();
            
                xmlW.writeStartElement(null,'RechnungsPositions', null);
                for(Rechnungsposition__c rp : rpl) {
                    xmlW.writeStartElement(null,'RechnungsPosition', null);
                        xmlW.writeStartElement(null,'Productbeschreibung', null);
                        xmlW.writeCharacters(rp.Lieferscheinposition__r.Artikel__r.Name);
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'Menge', null);
                            xmlW.writeCharacters(string.valueOf(rp.Lieferscheinposition__r.Artikel__r.Menge_ABDA__c));
                        xmlW.writeEndElement();    
                        xmlW.writeStartElement(null,'Einzelpreis', null);
                        xmlW.writeCharacters(string.valueOf(rp.Einzelpreis__c));
                        xmlW.writeEndElement();
                        xmlW.writeStartElement(null,'Gesamtpreis', null);
                        xmlW.writeCharacters(string.valueOf(rp.Gesamtpreis_Brutto__c));
                        xmlW.writeEndElement();

                        // RechnungsPosition
                    xmlW.writeEndElement();
                }                                   
                // RechnungsPositions
                xmlW.writeEndElement();
                
            // Rechnung
            xmlW.writeEndElement();
            // =============================================
        // PHRechnungs    
        xmlW.writeEndElement(); 
        xmlW.writeEndDocument();
            
        string xmlString = xmlW.getXmlString();
        System.debug('################### Mansi The XML ::'+xmlString); 
        xmlW.close();
        
        Attachment xml_attach = new Attachment();
        xml_attach.Body = blob.valueOf(xmlString);
        xml_attach.Name = RG.Name + '.xml';
        xml_attach.ParentId = RG.ID;
            
        // add attachment to list;
        RG_attach_List.add(xml_attach);
            
        }catch (System.Exception e) {
            error = true;
            System.debug('###################create XML error :'+e); 
            system.debug('######################### Mansi::Create XML error. Rechnung::' + RG.Name);       
        }
        return error;     
    } 
*/
}