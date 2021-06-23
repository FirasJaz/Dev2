/****************************************************************************************************************************
// Erstellt 15.07.2019 von AM
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
//             Ersetzt bearbeitePBGenehmigungController
//
//****************************************************************************************************************************
// Test:  
//*****************************************************************************************************************************
// Änderungen:   
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public with sharing class processCBGenehmigung {
    //public variablen
    public ApexPages.standardController controller {get; set;}
    //private variablen
    private string retPage = ApexPages.currentPage().getParameters().get('retURL');
    private id GnID = ApexPages.currentPage().getParameters().get('id');
    private string gstatus = ApexPages.currentPage().getParameters().get('stat');
    private string attid = ApexPages.currentPage().getParameters().get('attid');
    private string currentStatus {get; set;}

    public Curabox_Genehmigung__c Genehmigung { get; set; }
    public Curabox_Genehmigungsposition__c BL { get; set; }
    public List<Curabox_Genehmigungsposition__c> positionen = new List<Curabox_Genehmigungsposition__c>();
    public map<id, date> gpMap = new map<id, date>();
    public List<Curabox_Genehmigungsposition__c> positionen51 { get; set; }

    public boolean show51 = false;
    public boolean show54 = true;    
    
    public processCBGenehmigung() {
    }

    public processCBGenehmigung(ApexPages.StandardController stdController) {
        controller = stdController;
        Genehmigung = [SELECT id,
                        Name,
                        genehmigt_ab__c,
                        genehmigt_bis__c,
                        Status__c,
                        Genehmigungsnummer__c,
                        unbefristet_genehmigt__c,
                        Antrag_beantwortet_am__c,
                        Antrag_eingegangen_am__c,
                        Antrag_versandt_am__c,
                        Nach_Paragraph__c,
                        kvnr_azh__c,
                        KV_status__c,
                        Contact__c,
                        Contact__r.Name
                    FROM Curabox_Genehmigung__c 
                    WHERE Id = : GnId]; 
        if(gstatus != null) {
            Genehmigung.Status__c = gstatus;
        }
        currentStatus = Genehmigung.Status__c;
        if(Genehmigung.Nach_Paragraph__c == null){
            Genehmigung.Nach_Paragraph__c = '54';
        }
        if(Genehmigung.Antrag_beantwortet_am__c == null) Genehmigung.Antrag_beantwortet_am__c = date.today();
        if(Genehmigung.Antrag_eingegangen_am__c == null) Genehmigung.Antrag_eingegangen_am__c = date.today();
        if(Genehmigung.genehmigt_ab__c == null) Genehmigung.genehmigt_ab__c = date.today();
      
        // this.positionen = new List<Curabox_Genehmigungsposition__c>();
        positionen = [SELECT id,
            Name,
            genehmigt_ab__c,
            genehmigt_bis__c,
            Gen_Menge_Stk__c,
            Product_Group__c,
            unbefristet_genehmigt__c,
            Product_Group__r.Name,
            Ant_Menge_Stk__c
            FROM Curabox_Genehmigungsposition__c 
                    WHERE Genehmigung__c = :Genehmigung.id 
                    ] ;    

            for(Curabox_Genehmigungsposition__c gp : positionen) {
                if(gp.Gen_Menge_Stk__c == null) {
                    gp.Gen_Menge_Stk__c = gp.Ant_Menge_Stk__c;
                }
                gpMap.put(gp.id, gp.genehmigt_bis__c);
            }            
       

        // ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,   'positionen =  ' + positionen.size()));   
    }

    public PageReference neueGenehmigungSichern() {
        Boolean error = False;                                       
        set<string> BewilligtStatus = new set<string>{'Bewilligung', 'Teilbewilligung'};
        Set<string> geschlosseneStatus = new set<string>{'Bewilligung', 'Teilbewilligung', 'Ablehnung'};        
        if (geschlosseneStatus.contains(Genehmigung.status__c)){
            if (genehmigung.Antrag_versandt_am__c == null || genehmigung.Antrag_beantwortet_am__c == null) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Entweder "Antrag versandt" oder "Antrag beantwortet am" nicht gefüllt. Bitte füllen! ' );
                ApexPages.addMessage(myMsg); 
                error = true;
            }
        }
        if (!error) {
            for (Curabox_Genehmigungsposition__c g : this.positionen) {
                if (BewilligtStatus.contains(Genehmigung.status__c)) {
                    if (g.Gen_Menge_Stk__c == null) {
                        g.Gen_Menge_Stk__c = g.Ant_Menge_Stk__c;
                    }
                    if((g.genehmigt_ab__c == null) && (Genehmigung.genehmigt_ab__c != null)) {
                        g.genehmigt_ab__c = Genehmigung.genehmigt_ab__c;
                    } 
                    if((g.genehmigt_bis__c == null) && (Genehmigung.genehmigt_bis__c != null)) {
                        g.genehmigt_bis__c = Genehmigung.genehmigt_bis__c;
                    } 
                    g.unbefristet_genehmigt__c = Genehmigung.unbefristet_genehmigt__c;
                }
                else if (Genehmigung.status__c == 'Ablehnung') {
                    g.Gen_Menge_Stk__c = 0;
                }
            }
            try {
                update positionen;
                update Genehmigung;
                PageReference returnPage = new PageReference('/'+Genehmigung.id);
                returnPage.setRedirect(true);
                return returnPage;
            }  
            catch (System.Exception e) {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 'Es gab einige Fehler. ' + e);
                ApexPages.addMessage(myMsg);                 
            }          
        }
        return null;
    }

    
    public PageReference neueGenehmigungZurueck() {
        PageReference returnPage = new PageReference('/'+Genehmigung.id);
        returnPage.setRedirect(true);
        return returnPage;
    }

    public string getRetPage(){
            return retPage;
    } 
    public boolean getShow51(){
            return show51;
    }   
    
    public boolean getShow54(){
            return show54;
    } 

    public List<Curabox_Genehmigungsposition__c> getpositionen() {
        return positionen;
    }

    public void seetpositionen(List<Curabox_Genehmigungsposition__c> positionen) {
        this.positionen = positionen;
    }

}