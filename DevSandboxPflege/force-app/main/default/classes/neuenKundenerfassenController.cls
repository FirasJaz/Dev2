/*/****************************************************************************************************************************
// Erstellt 19.03.2015 von WDS
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
// erstellen einen neuen Kunde
//
//
//****************************************************************************************************************************
//Änderungen:   29.12.2015 AM   #110237326 - CRM_Ticket_ID__c hinzufügen
//
//
//****************************************************************************************************************************
*/
public with sharing class neuenKundenerfassenController {
//
//  2014-05-20 wds WSIG Bezug rausgenommen
//
    //public variablen
    public ApexPages.standardController controller {get; set;}
    //private variablen
    private string retPage = ApexPages.currentPage().getParameters().get('retURL');
    public Kundenstatus__c ks = new Kundenstatus__c();
    public Boolean error {get; set;}
    public LIst<Kunde__c> Kdlist = new List<Kunde__c>();   
    
//  ************************************
    public Kunde__c Kd { get; set; }
        
//      der constructor

    public neuenKundenerfassenController(ApexPages.StandardController stdController) {
        // constructor
        controller = stdController;
        this.Kd = (Kunde__c)stdController.getRecord();
        
    }
    
    public PageReference neuenKundensichern() {
                
                error = false;
                system.debug ('NIX');
                system.debug ('####################### retPage ' + retPage);
                Kunde__c Kunde = this.Kd;
                Kunde.Mitarbeiter__c = ks.Mitarbeiter__c;
                Kunde.CRM_Ticket__c = ks.CRM_Ticket_ID__c;
                if (Kunde.Lieferadresse__c == 'Adresse Pflegeperson' && Kunde.Betreuer__c == null){
                    ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL, 
                        ' Lieferadresse ist private Pflegeperson, diese wurde aber nicht angegeben. Bitte geben sie erst eine private Pflegepperson ein!' );
                        ApexPages.addMessage(myMsg);                                                    
                        error = True;
                }                
                if (!error){
                    error = neuen_kunden_sichern_class.neuen_kunden_sichern_func(Kunde);
                }
                PageReference returnPage = null;
                // nur wenn eine retUrl übergeben wird, wird mit dieser eine PageReference initialisiert
                // sonst mit der kundenummer, d.h. nach erstellen eines kunden wird man auf die detail-seite umgeleitet
                system.debug('########## '+Kunde.Id + ' kd '+ Kunde);
                returnPage = new PageReference('/'+Kunde.Id);
                
                if ( error ){
                    Database.SaveResult saveResult = Database.insert(Kunde, false);
                       
                    for (Database.Error error : saveResult.getErrors()) {         
                      
                        if (error instanceof Database.DuplicateError) {
                            Database.DuplicateError duplicateError = (Database.DuplicateError)error;
                            Datacloud.DuplicateResult duplicateResult = duplicateError.getDuplicateResult();                            

                            Datacloud.MatchResult[] matchResults = duplicateResult.getMatchResults();
                        
                            for(Datacloud.MatchResult matchResult: matchResults) {
                                Datacloud.MatchRecord[] matchRecords = matchResult.getMatchRecords();

                                for (Datacloud.MatchRecord matchRecord : matchRecords) {
                                    System.debug('MatchRecord: ' + matchRecord.getRecord());                                
                                    Kdlist.add((Kunde__c)matchRecord.getRecord());
                                }
                            }         
                         }
                  }
                     
                   returnPage = null;
                } else {
                    returnPage.setRedirect(true);
                }
        return returnPage;
    }
    
    public PageReference neuenKundenNachWarnungSichern() {
                error = false;
                Kunde__c Kunde = this.Kd;
                Kunde.Mitarbeiter__c = ks.Mitarbeiter__c;
                Kunde.CRM_Ticket__c = ks.CRM_Ticket_ID__c;
                error = neuen_kunden_sichern_class.neuen_kunden_sichern_nach_warnung(Kunde);
                PageReference returnPage = new PageReference('/'+Kunde.Id);
                
                return returnPage;
    }

    public PageReference neuerKundeZurueck() {
                PageReference returnPage = new PageReference(retPage);
                returnPage.setRedirect(true);
        return returnPage;
        
    }

    public string getRetPage(){
                return retPage;
    }    
        
    public List<Kunde__c> getKdlist() {
                return Kdlist;
    }    
        
    public PageReference changedZuzahlungBefreit(){
            if(kd.Zuzahlung_befreit__c){
                Kd.Zuzahlung_befreit_von__c = date.today();
            }else{
                Kd.Zuzahlung_befreit_von__c = null;
            }
            return null;
    }
    
    public Kundenstatus__c getKs() {
        return ks;
    }
        
}