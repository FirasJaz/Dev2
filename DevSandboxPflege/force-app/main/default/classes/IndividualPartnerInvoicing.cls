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
//
// bt    15.09.2016    Auswahl von Partner-Produkten
// Mz    05.12.2016    Auswahl von Abrechnungszeitraum 
//****************************************************************************************************************************
global with sharing class IndividualPartnerInvoicing{

Id partnerId;
Account n;
public string scriptvar{get;set;}
public List<Partner_Produkte__c> plist = new List<Partner_Produkte__c>();
public String pIds {get; set;}
public Boolean button_disabled {get; set;}
public Boolean button_rendered {get; set;}
public String table_display {get; set;}
public string text_display {get; set;}
public string message_display {get; set;}
public string message {get; set;}
public Integer plist_size {get; set;}
public boolean allselected {get; set;}
public List<Id> pIdList = new List<Id>();
public Map<Id, Partner_Produkte__c> ppMap = new Map<Id, Partner_Produkte__c>();

public static String letztenMonatKey = '0';
public static String diesenMonatKey = '1';
public static String letztesQuartalKey = '2';

public String timePeriodValue{set;get;}

global IndividualPartnerInvoicing(ApexPages.StandardController stdController){
    this.n = (Account)stdController.getRecord();   
    List<Partner_Produkte__c> pplist = [select id, Name, Produktgruppe__c, Abrechnungsmethode__c, Partner__c 
                                        from Partner_Produkte__c 
                                        where Partner__c =: n.Id and Abrechnungsmethode__c != :PLZTool_Basis.ppStatusKeineAbrechnung];

    if(pplist != null && pplist.size() != 0){
        for(Partner_Produkte__c p: pplist){
            pIdList.add(p.Id);
            ppMap.put(p.Id, p);
        }
        
        for(Id pid: pIdList){
            List<Partner_Ticket__c> ptList = [select id, Partner_Produkt__c, Partner__c, Status_CPL__c, Status_CPO__c,
                                                     Wert_des_Partner_Tickets_CPL__c, Wert_des_Partner_Tickets_CPO__c 
                                                     from Partner_Ticket__c
                                                     where Partner_Produkt__c =: pid 
                                                     and Partner__c = :n.Id 
                                                     and ((Status_CPL__c = 'Abrechenbar' and Wert_des_Partner_Tickets_CPL__c != null) or (Status_CPO__c = 'Abrechenbar' and Wert_des_Partner_Tickets_CPO__c != null))   
                                                     LIMIT 1];
            
            if(ptList != null && ptList.size() != 0) plist.add(ppMap.get(pid)); 
        }
    }
                
    if(plist != null && plist.size() != 0){
        pIds = '';    
        for(Partner_Produkte__c pp: plist){
            pIds = pIds + pp.id + ' ';
        }
        
        button_disabled = false;
        button_rendered = true;
        table_display = 'table';
        message_display = 'none';
        text_display = 'initial';
        plist_size = plist.size();
        allselected = true;
    }
    else {
        button_disabled = true;
        button_rendered = false;
        table_display = 'none';
        message_display = 'initial';
        message = 'Es stehen keine abrechenbaren Partner-Tickets zur Verfügung !';
        text_display = 'none';
        plist_size = 0;
        allselected = false;
    }
}

public PageReference startInvoicing(){
    System.debug('mansi::: in startInvoicing:::timePeriodValue:::' + timePeriodValue);
    partnerId = ApexPages.currentPage().getParameters().get('id'); 
    String[] ppArray = pIds.split(' ');   
    PartnerTicketsInvoice invoicing = new PartnerTicketsInvoice (new List<Id>{partnerId }, ppArray, timePeriodValue);
    ApexPages.message result = invoicing.invoicingAndScopevisioRequest();
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

public PageReference zurueck(){
        PageReference nextpage = new PageReference('/' + n.Id);
        nextPage.setRedirect(true);
        return nextpage;  
}

public List<Partner_Produkte__c> getPlist(){
    return plist;
}

public static List<SelectOption> getTimePeriodItems() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption(letztenMonatKey ,'Letzten Monat'));
    options.add(new SelectOption(diesenMonatKey ,'Diesen Monat'));
    options.add(new SelectOption(letztesQuartalKey ,'Letztes Quartal')); 
    return options;
}

}