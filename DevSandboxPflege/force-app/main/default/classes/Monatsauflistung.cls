//****************************************************************************************************************************
// Erstellt 01.08.2016 von MZ
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
//
//
//****************************************************************************************************************************
//Änderungen:
//    Mz    06.12.2016    Auswahl von Abrechnungszeitraum 
//****************************************************************************************************************************
global with sharing class Monatsauflistung{

Id partnerId;
Account n;
public String timePeriodValue{set;get;}
public string message_display {get; set;}
public string message {get; set;}


global Monatsauflistung(ApexPages.StandardController stdController){
    this.n = (Account)stdController.getRecord();  
    
    message_display = 'none';           
}

public PageReference startAuflistung(){
    partnerId = ApexPages.currentPage().getParameters().get('id');
    AuflistingPartnerTickets listung = new AuflistingPartnerTickets ( timePeriodValue );
    ApexPages.message result = listung .auflistung( partnerId );
    if(result.getSeverity() == ApexPages.severity.Confirm){
        // go back to the original page
        PageReference nextpage = new PageReference('/' + partnerId);
        nextPage.setRedirect(true);
        return nextpage;   
    }
    message = result.getSummary();
    message_display = 'initial';
    return null;    
}

public List<SelectOption> getTimePeriodItems() {
    return IndividualPartnerInvoicing.getTimePeriodItems();
}

public PageReference zurueck(){
        PageReference nextpage = new PageReference('/' + n.Id);
        nextPage.setRedirect(true);
        return nextpage;  
}

}