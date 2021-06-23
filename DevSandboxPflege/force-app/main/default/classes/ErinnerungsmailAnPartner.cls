//****************************************************************************************************************************
// Erstellt 09.06.2017 von MZ
//     Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//     Nordkanalstrasse 58
//     20097 Hamburg 
//     Tel.:  04064917161
//     Fax.:  04064917162
//     Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: schickt eine Erinnerungsmail an Partner
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/

global with sharing class ErinnerungsmailAnPartner {  
    
    private EmailToPartner etp;
    
    global ErinnerungsmailAnPartner (ApexPages.StandardController stdController){
        
    }
    
    public PageReference sendEmail() {
        Id partnerTicketId = ApexPages.currentPage().getParameters().get('id');
        
        try{
            etp = new EmailToPartner(partnerTicketId,false, True);
            etp.sendEmail();
        }
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
            return null;
        }
        
        PageReference nextpage = new PageReference('/' + partnerTicketId);
        nextPage.setRedirect(true);
        return nextpage;
        
    }
    
}