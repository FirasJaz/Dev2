/****************************************************************************************************************************
// Erstellt 25.07.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: curabox_genehmiging__c
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//             Ersetzt neuePBGenehmigungController
//
//****************************************************************************************************************************
// Test:  
//*****************************************************************************************************************************
// Änderungen:   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class newCBGenehmigung {
    public ApexPages.standardController controller {get; set;}
    public map<string, string> param = ApexPages.currentPage().getParameters();
    public Curabox_Genehmigung__c Genehmigung { get; set; }
    public Curabox_Genehmigungsposition__c BL { get; set; }
    public List<Curabox_Genehmigungsposition__c> positionen = new List<Curabox_Genehmigungsposition__c>();
    public List<Curabox_Genehmigungsposition__c> positionen51 = new List<Curabox_Genehmigungsposition__c>();
    private contact ct {get; set;}
    private id contId = null;
    private string retPage = ApexPages.currentPage().getParameters().get('retURL');

    public string prGroup = ApexPages.currentPage().getParameters().get('prGroup');
    public string pr {get; set;}
    public boolean show51 = true;
    public boolean show54 = true;
    public newCBGenehmigung() {
    }

    public newCBGenehmigung(ApexPages.StandardController stdController) {
        controller = stdController;
        if(pr == null) pr = '5X';
        for(string key : param.keySet()) {
            if(key.Contains('_lkid')) {
                contId = ApexPages.currentPage().getParameters().get(key);
                break;                
            }
        }
        Genehmigung = new Curabox_Genehmigung__c();
        Genehmigung.Contact__c = contId;
        Genehmigung.Nach_Paragraph__c = pr;
        Genehmigung.Antrag_eingegangen_am__c = date.today();
        Genehmigung.genehmigt_ab__c = date.today();
        Genehmigung.KV_status__c = 'closed';
        readGenPos(Genehmigung.Nach_Paragraph__c); 
    }  

    public Pagereference reloadPage() {
        pr = Genehmigung.Nach_Paragraph__c;
        show54 = false;
        show51 = false;
        system.debug('#############alex001 Genehmigung.Nach_Paragraph__c='+Genehmigung.Nach_Paragraph__c  );
        if(Genehmigung.Nach_Paragraph__c == '54'){
            show54 = true;
        }
        if(Genehmigung.Nach_Paragraph__c == '51'){
            show51 = true;
        }
        if(Genehmigung.Nach_Paragraph__c == '5X'){
            show54 = true;
            show51 = true;
        }
        return null;
        
        // system.debug('#### pr='+pr);
        // PageReference returnPage = ApexPages.currentPage();
        // returnPage.setRedirect(true);
        // return returnPage;
    }

    public void readGenPos(string hm) {
        
        List<Product_Group__c> pgList = [SELECT id, Name FROM Product_Group__c 
                                                    WHERE keine_Genehmigungspflicht__c = false 
                                                    AND Positionsnummer__c = '54'];
        if((pgList != null) && (pgList.size() > 0) ) {
            for(Product_Group__c pg : pgList) {
                Curabox_Genehmigungsposition__c gp = new Curabox_Genehmigungsposition__c(Product_Group__r = pg, Product_Group__c = pg.id);
                gp.Ant_Menge_Stk__c = 10;
                positionen.add(gp);
            }
        }
        pgList = [SELECT id, Name FROM Product_Group__c 
                                                    WHERE keine_Genehmigungspflicht__c = false 
                                                    AND Positionsnummer__c = '51'];
        if((pgList != null) && (pgList.size() > 0) ) {
            for(Product_Group__c pg : pgList) {
                Curabox_Genehmigungsposition__c gp = new Curabox_Genehmigungsposition__c(Product_Group__r = pg, Product_Group__c = pg.id);
                gp.Ant_Menge_Stk__c = 10;
                positionen51.add(gp);
            }
        }       
    } 

    public PageReference neueGenehmigungZurueck() {
        PageReference returnPage = new PageReference(retPage);
        // returnPage.setRedirect(true);
        return returnPage;
    }

    public PageReference neueGenehmigungSichern() {

        if(Genehmigung.Nach_Paragraph__c == '5X') {
            save54();
            save51();
        }
        if(Genehmigung.Nach_Paragraph__c == '54') {
            save54();
        }
        if(Genehmigung.Nach_Paragraph__c == '51') {
            save51();
        }
        PageReference returnPage = new PageReference(retPage);
        // returnPage.setRedirect(true);
        return returnPage;
    }

    public void save54() {
        Curabox_Genehmigung__c g54 = Genehmigung.clone();
        g54.Nach_Paragraph__c = '54';
        Database.SaveResult dr = Database.insert(g54, false);
        if(dr.isSuccess()) {
            List<Curabox_Genehmigungsposition__c> gpList = new List<Curabox_Genehmigungsposition__c>();
            id genid = dr.getId();
            for(Curabox_Genehmigungsposition__c gp : positionen) {
                gp.Genehmigung__c = genid;
            }
            Database.SaveResult[] srList = Database.insert(positionen, false);         
        }
    }  

    public void save51() {
        Curabox_Genehmigung__c g51 = Genehmigung.clone();
        g51.Nach_Paragraph__c = '51';
        Database.SaveResult dr = Database.insert(g51, false);
        if(dr.isSuccess()) {
            id genid = dr.getId();
            for(Curabox_Genehmigungsposition__c gp : positionen51) {
                gp.Genehmigung__c = genid;
            }
            Database.SaveResult[] srList = Database.insert(positionen51, false);         
        }
    }  

    public List<Curabox_Genehmigungsposition__c> getPositionen() {
        return positionen;
    }

    public void setPositionen(List<Curabox_Genehmigungsposition__c> positionen) {
        this.positionen = positionen;
    }
    public List<Curabox_Genehmigungsposition__c> getPositionen51() {
        return positionen51;
    }

    public void setPositionen51(List<Curabox_Genehmigungsposition__c> positionen51) {
        this.positionen51 = positionen51;
    }
    public string getPr() {
        return pr;
    }

    public void setPr(string pr) {
        this.pr = pr;
    }

    public boolean getShow51(){
            return show51;
    }   
    
    public boolean getShow54(){
            return show54;
    }   
}