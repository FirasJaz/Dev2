//****************************************************************************************************************************
// Erstellt 07.06.2017 von AM
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
// Beschreibung: upload CSV Monatsabrechnung PT
//                      
//
//
//****************************************************************************************************************************
//Änderungen:
//****************************************************************************************************************************
global with sharing class Upload_monatsabrechnung {
    Id partnerId;
    Account partner;
    public string nameFile;
    public Blob contentFile;
    public String[] filelines = new String[]{};
    public string message_display {get; set;}
    public string message {get; set;}
    public list<Partner_Ticket__c> ptList = new list<Partner_Ticket__c>();
    
    global Upload_monatsabrechnung(ApexPages.StandardController stdController){
        this.partner = (Account)stdController.getRecord();          
        message_display = 'none';           
    }   

    public PageReference upload() {
        string debugstr = ''; 
        map<string, string> ptnamenMap = new map<string, string>();
        try {
            nameFile = contentFile.toString();              
            //nameFile = nameFile.replace(';', ',');                                                                      
            system.debug('#############alex100  ');
            //Now sepatate every row of the excel file
            if(nameFile.contains('\r\n')){
                filelines = nameFile.split('\r\n');               
            }
            else if(nameFile.contains('\r') && !nameFile.contains('\n')){
                filelines = nameFile.split('\r');
            }
            else if(nameFile.contains('\n') && !nameFile.contains('\r')){
                filelines = nameFile.split('\n');
            } 
            for(string line : filelines) {
                system.debug('#############alex441 line=' + line);
                String[] inputvalues = new String[]{};
                line = line.replace('\r\n', '');
                line = line.replace('\n', '');
                line = line.replace('\r', '');  
                inputvalues = line.split(';');
                if((inputvalues[0] != null) && (inputvalues[0].contains('PT-')) ) {
                    debugstr = line;
                    if(inputvalues[2] != '') {
                        ptnamenMap.put(inputvalues[0], inputvalues[1] + ';' + inputvalues[2]);
                    }
                    else {
                        ptnamenMap.put(inputvalues[0], inputvalues[1] + ';0,00');
                    }
                }
            }
            system.debug('#############alex442 ptnamenMap.Keyset()=' + ptnamenMap.Keyset());
            if(!ptnamenMap.isEmpty()) {
                ptList = [SELECT id, name, Partner_Produkt__r.name, Status_CPL__c, Status_CPO__c, Wert_des_Partner_Tickets_Gesamt__c, createddate,
                                Ticket_vom_Partner_storniert__c, Wert_des_Partner_Tickets_CPL__c, Wert_des_Partner_Tickets_CPO__c
                            FROM Partner_Ticket__c 
                            WHERE name IN :ptnamenMap.Keyset()
                            AND Partner__c = :partner.id 
                            AND (Status_CPL__c = 'Abrechenbar' OR Status_CPO__c = 'Übermittelt')];
                if((ptList != null) && (ptList.size() > 0)) {
                    for(Partner_Ticket__c PT : ptList) {                        
                        string antwort = ptnamenMap.get(PT.name);
                        if(antwort.containsIgnoreCase('positiv')) {                         
                            string[] satz = antwort.split(';');                         
                            string awert = satz[1].replace(',', '.');   
                            if(PT.Status_CPO__c == 'Übermittelt') {
                                decimal neuwert = decimal.valueOf(awert);
                                PT.Wert_des_Partner_Tickets_CPO__c = neuwert;
                                PT.Status_CPO__c = 'Abrechenbar';
                            }
                        }
                        else {
                            // if(PT.Status_CPO__c == 'Übermittelt') {
                                // PT.Status_CPO__c = 'Storniert';
                                // PT.Wert_des_Partner_Tickets_CPO__c = 0.00;
                            // }
                            if(PT.Status_CPL__c == 'Abrechenbar') {
                                PT.Status_CPL__c = 'Storniert';
                                PT.Wert_des_Partner_Tickets_CPO__c = 0.00;
                            }
                        }
                    }
                }
            }
            
        }       
        catch (System.Exception e ) {
             ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured reading the CSV file. line: ' + debugstr + ' Error0: '+e.getMessage());
             ApexPages.addMessage(errormsg);
             return null;           
        }
        return null;
    }   
    
    public PageReference speichern() {
        try {
            update ptList;
        }
        catch (System.Exception e) {
             ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured update PT. Error: '+e.getMessage());
             ApexPages.addMessage(errormsg);
             return null;           
            
        }
        PageReference pageRef = new PageReference('/' + partner.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public PageReference zurueck(){
            PageReference nextpage = new PageReference('/' + partner.Id);
            nextPage.setRedirect(true);
            return nextpage;  
    }   
    
    public PageReference abbrechen(){
        PageReference pageRef = new PageReference('/' + partner.Id);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public String getNameFile(){
        return nameFile;
    }   
    
    public void setNameFile(String nFile){
        nameFile = nFile;
    }  
    
    public Blob getContentFile(){
        return contentFile;
    }
    
    public void setContentFile(Blob cFile){
        contentFile = cFile;
    }
    
    public list<Partner_Ticket__c> getptList() {
        return ptList;
    }

}