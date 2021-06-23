//****************************************************************************************************************************
// Erstellt 01.03.2015 von MS
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
// Controller für CustomEmailTemplateSelect
// Eine Liste der E-Mail-Vorlagen wird erstellt. Der Name ist verlinkt und leitet zu der URL,
// die im Parameter returnURL gespeichert ist erweitert um den Parameter etid (EmailTemplate-ID)
// weiter.
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 01.03.2015 von ms: Erste Version erstellt
//                        
//****************************************************************************************************************************
public with sharing class CustomEmailTemplateSelect_Controller {
    
    public EmailTemplate[] EmailTemplates {get;set;}
    public string etid {get;set;}
    
    public CustomEmailTemplateSelect_Controller(){
        EmailTemplates = [SELECT Name, Description FROM EmailTemplate];
    }
    
    public PageReference PassTemplateIdToReturnURL()
    {
        PageReference pg = new PageReference(ApexPages.currentPage().getParameters().get('returnURL'));
    
        pg.getParameters().put('etid', etid);
        pg.setRedirect(true);
        return pg;
    }
}