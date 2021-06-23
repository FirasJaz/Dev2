/****************************************************************************************************************************
// Erstellt 23.04.2018 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  040 23882986
//                         Fax.:  040 23882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: no
//
//****************************************************************************************************************************
//
// Beschreibung: show LS/LB with delivery status
//
//****************************************************************************************************************************
// Test: LS_erzeugen_test
//****************************************************************************************************************************
//
//  Änderungen
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global with sharing class LS_erzeugen {
    public string retPage = ApexPages.currentPage().getParameters().get('retURL');
    public String query;
    public string qrySelect {get; set;}
    public List<Lieferbest_tigung__c> lbsList = new List<Lieferbest_tigung__c>();

    public Integer noOfRecords{get; set;}
    public Integer size {get;set;}
    public integer counter=0;  //keeps track of the offset
    public integer list_size=20; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list   

    public String sortDirection{get;set;}
    public String sortExpression{get;set;}

    public String sortFullExp {
        get {
            if(sortDirection == null || sortExpression == null) return ' Lieferschein__r.Lieferdatum__c ASC ';
            else return sortExpression  + ' ' + sortDirection;
        }
        set;
    }


    private String query1 = 'SELECT Lieferschein__c, Lieferschein__r.Name, Lieferschein__r.Lieferdatum__c, '
                            + ' Lieferschein__r.Liefertext__c, Kunde__r.Krankenkasse__c, Kunde__c, Kunde__r.Krankenkasse__r.name, Kunde__r.name '
                            + ' FROM Lieferbest_tigung__c WHERE an_abena_versendet__c = false';

    private String query2 = 'SELECT Lieferschein__c, Lieferschein__r.name, Lieferschein__r.Lieferdatum__c, '
                          + ' Lieferschein__r.Liefertext__c, Kunde__r.Krankenkasse__c, Kunde__c, Kunde__r.Krankenkasse__r.name, Kunde__r.name '
                          + 'FROM Lieferbest_tigung__c '
                          + ' WHERE Lieferschein__c != null '
                          + '  AND ABENA_EMPFANG__C = false AND an_abena_versendet__c = true ' 
                          + ' AND Lieferschein__r.Stornierung__c = false '
                          + '  AND Lieferschein__r.Lieferdatum__c >= 2018-01-01 ';

    private String query3 = 'SELECT Lieferschein__c, Lieferschein__r.name, Lieferschein__r.Lieferdatum__c, '
                            + ' Lieferschein__r.Liefertext__c, Kunde__r.Krankenkasse__c, Kunde__c, Kunde__r.Krankenkasse__r.name, Kunde__r.name '
                            + '   FROM Lieferbest_tigung__c '
                            + '    WHERE Lieferschein__c != null' 
                            + '    AND ABENA_EMPFANG__C = true' 
                            + '    AND Rechnung__c = null '
                            + '    AND Lieferschein__r.Lieferdatum__c >= 2018-01-01 '
                            + '    AND Lieferschein__c IN (SELECT Lieferschein__c FROM Lieferscheinposition__c '
                            + '        WHERE Abrechnungsstatus_Krankenkasse__c = \'abrechenbar\')';


    public List<Lieferbest_tigung__c> lbList = new List<Lieferbest_tigung__c>();

    public ApexPages.StandardSetController setCon {get; set;}

    public LS_erzeugen() {  
        if(String.isEmpty(sortDirection)) sortDirection = 'ASC';
        if(String.isEmpty(sortExpression)) sortExpression = 'Lieferschein__r.Lieferdatum__c';        
        qrySelect = ApexPages.currentPage().getParameters().get('qrySelect');
        if (qrySelect == null) qrySelect = '1';
        refresh();
    }   

    public void refresh() {
        query = query1;
                if(qrySelect == '1') {
                    query = query1;
                } 
                else if(qrySelect == '2') {
                    query = query2;
                } 
                else if(qrySelect == '3') {
                    query = query3;
                } 

        query += ' ORDER BY ' + sortFullExp;
        system.debug('#### alex001 query=' + query);

        size = list_size;
        lbsList = Database.query(query);
        setCon = new ApexPages.StandardSetController(lbsList);
        setCon.setPageSize(size);
        noOfRecords = setCon.getResultSize();
    }

    public List<Lieferbest_tigung__c> getlbList() {
        return (List<Lieferbest_tigung__c>)setCon.getRecords();
    }
    
    public PageReference initPage() {   
        lbList = (List<Lieferbest_tigung__c>)setCon.getRecords();
        PageReference curPage = ApexPages.currentPage();
        curPage.getParameters().put('qrySelect', qrySelect);
        curPage.setRedirect(true);
        return curPage;
    }

    public void SortToggle() {  

        String sortParam = Apexpages.currentPage().getParameters().get('sortToggleParam');
        if(String.isEmpty(sortParam)){
            sortExpression = 'Lieferschein__r.Lieferdatum__c';
            sortDirection = 'ASC';
        }else{
            if(!String.isEmpty(sortExpression) && sortExpression == sortParam){
                if(sortDirection == 'ASC'){
                    sortDirection = 'DESC';
                }else{
                    sortDirection = 'ASC';
                }
            }else{
                sortExpression = sortParam;
                sortDirection = 'ASC';
            }
        }
        refresh();
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
  
    public Integer pageNumber {
        get {
            return setCon.getPageNumber();
        }
        set;
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
    
    public PageReference LS_erzeugen_zurueck() {       
        PageReference returnPage = new PageReference('/');
        returnPage.setRedirect(true);
        return returnPage;
    }   
    
    public list<SelectOption> querySelect {
        set;
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('1', 'Zum Versand')); 
            options.add(new SelectOption('2', 'Pending bei Hartmann'));   
            options.add(new SelectOption('3', 'Zum Abrechnen'));      
            return options;
        }
    }   


}