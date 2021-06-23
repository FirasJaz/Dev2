/*/****************************************************************************************************************************
// Erstellt 09.03.2016 von AM
//          Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//          Nordkanalstrasse 58
//          20097 Hamburg 
//          Tel.:  04064917161
//          Fax.:  04064917162
//          Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: Erstellen eine PDF aus der Rechnung
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/

global with sharing class ksgRecreatePDF {

    private Rechnung__c RG;
    global ksgRecreatePDF(ApexPages.StandardController stdController) {
        this.RG = (Rechnung__c)stdController.getRecord();   
    }
    
    // Code we will invoke on page load.
    public PageReference createInvoicePDF() {
        String rgID = ApexPages.currentPage().getParameters().get('id');
        if (rgID == null) {
            // Display the Visualforce page's content if no Id is passed over 
            return null;
        }
        // hidden call VF-page for crete PDF
        genPDF(rgID);
        // go back to the original page
        PageReference pageRef = new PageReference('/' + rgID);
        pageRef.setRedirect(true);
        return pageRef;     
    }
    
    public void genPDF(ID rgID) {
        Blob pdf;
        PageReference rgPDF = new PageReference('/apex/SRG_nur_anzeigen?id=' + string.valueOf(rgId));
        string idzuaufruf = string.valueOf(rgID).substring(0, 15);
        rgPDF.getParameters().put('Id', idzuaufruf);
        list<Rechnung__c> rgList = [SELECT id, name, PDF_generiert__c, svXML__c, Rechnungsnummer_shop__c FROM Rechnung__c WHERE id = :RGId];    
        if((rgList != null) && (rgList.size() == 1)) {      
            Rechnung__c RGu = rgList[0];
            
            string rgnameatt = RGu.name + '.pdf';
            if(RGu.Rechnungsnummer_shop__c != null) {
                rgnameatt = 'Rechnung_' + RGu.Rechnungsnummer_shop__c + '.pdf';
            }
        

            list<attachment> atList = [SELECT name FROM attachment WHERE ParentID = :rgID AND name = :rgnameatt];
            if((atList != null) && (atList.size() > 0)) {
                // maybe message?
            }
            else {          
                try {
                    
                    Attachment pdf_attach = new Attachment();              
                                  
                    pdf_attach.Name = rgnameatt;              
                    pdf_attach.ParentId = RGId; 
                    pdf = rgPDF.getContent();
                    pdf_attach.body = pdf;
                    insert pdf_attach;              
                    RGu.PDF_generiert__c = true;                
                    update RGu;             
                }
                catch (VisualforceException e) {
                    system.debug('#########################alex200 Error getContent e=' + e);
                } 
            }
        }                   
    }   
}