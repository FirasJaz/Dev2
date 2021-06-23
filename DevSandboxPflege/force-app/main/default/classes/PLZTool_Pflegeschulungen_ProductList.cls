public with sharing class PLZTool_Pflegeschulungen_ProductList {
    private static String retPage_BelPflegedienst = '/apex/PLZTool_BelPflegedienstPage';
    private static String retPage_lead = '/apex/Notification_Leads_anzeigen';
    
    private Opportunity opp;
    private Contact contactPerson;
    private Contact insuredPerson;
    
    //private static String emailTemplateName = 'PlzToolAgents_PWE_Mail';
    
    private String tblEnd = plzEmailTagsGenerator.tblEnd ;
    private String tdEnd = plzEmailTagsGenerator.tdEnd ;
    private String tr = plzEmailTagsGenerator.tr ;
    private String trEnd = plzEmailTagsGenerator.trEnd ;
        
    private String tblCustomer = plzEmailTagsGenerator.tblCustomer ;
    private String tdCustomerTitle = plzEmailTagsGenerator.tdCustomerTitle ;
    private String tdCustomerValue = plzEmailTagsGenerator.tdCustomerValue ;

    private String tblOpp = plzEmailTagsGenerator.tblOpp ;
    private String tdOppTitle = plzEmailTagsGenerator.tdOppTitle ;
    private String tdOppValue = plzEmailTagsGenerator.tdOppValue ;

    public PLZTool_Pflegeschulungen_ProductList() {
         Id oppId = ApexPages.currentPage().getParameters().get('id');
         setOpportunity (oppId); 
    }

    public PLZTool_Pflegeschulungen_ProductList(id oppId) {
        setOpportunity (oppId); 
    }

    private void setOpportunity (Id opportunityId){
        List<Opportunity> oppList = [select Id,
                                        Name, 
                                        StageName,
                                        Pflegedienst__c,
                                        X24h_Betreuung__c,
                                        Stundenweise_Betreuung__c, 
                                        Hauswirtschaftsleistungen__c,
                                        Bezugspunkt_der_PLZ_Suche__c,
                                        Alternative_Postleitzahl__c,
                                        Description,
                                        Thema_der_Pflegeschulung__c 
                                        from Opportunity 
                                        where Id = :opportunityId limit 1];
        if(oppList != null && oppList.size()>0){
            opp = oppList [0];
        }
    }



}