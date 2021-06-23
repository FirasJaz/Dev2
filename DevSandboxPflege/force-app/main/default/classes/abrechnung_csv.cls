//****************************************************************************************************************************
// Erstellt 15.08.2019 von AM
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
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Aufruf CSV nachträglich erzeugen
//
// Test: abrechnung_csv_test
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
public with sharing class abrechnung_csv {
    public string kkName = '';  
    public string kkstr = '';
    public boolean Aufruf = true;
    public string errorMsg = null; 

    public abrechnung_csv() {
        kkName = ApexPages.CurrentPage().getParameters().get('kk');
        String los = ApexPages.CurrentPage().getParameters().get('call');
        if (los == 'los') {
            Aufruf = false;
            kkstr = ApexPages.CurrentPage().getParameters().get('kk').trim();
        }
        else {
            if(errorMsg == null)
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Geben Sie die Rechnungsnummern ein.<br>Durch Komma getrennt<br>Die CSV-Dateien werd per E-Mail gesendet.  '));    
        }   
    }

    public boolean getAufruf(){
            return Aufruf;
    }
    
   
    public string getKkName () {         
            return kkName;
   }
  
    public void setKkName (string kkName) {          
            this.kkName = kkName;
   }

    public PageReference goSend() {
        if((kkName != null) && (!String.isBlank(kkName))) {
            createInvoiceLines invoice = new createInvoiceLines();
            invoice.recreateCSV(kkName);
            Aufruf = true;
            kkstr = '';
            kkName = null;
        }
        return null;  
    }
}