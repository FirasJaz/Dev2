//****************************************************************************************************************************
// Erstellt 07.07.2015 von AM
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
// kdid
//
//****************************************************************************************************************************
//
// Beschreibung: 
//                      
// Zwischenschritt upload genehmigung -> gen. bearbeiten
//
//
//****************************************************************************************************************************
//Änderungen:
//                            
//****************************************************************************************************************************
global with sharing class Genehmigung_erhalten {    
    private Kunde__c kd;
    private list<Genehmigung__c> gnList = new list<Genehmigung__c>();
    private list<attachment> atList = new list<attachment>();
    private boolean is51 = false;
    private boolean is54 = false;
    private id genID = null;
    private id attID = null;
    
    global Genehmigung_erhalten(ApexPages.StandardController stdController) {
        this.kd = (Kunde__c)stdController.getRecord();  
    }
    
    public PageReference checkAttachment() {
        string atName = '';
        ID kdID = ApexPages.currentPage().getParameters().get('kdid');
        if(kdID == null) return null;
        atList = [SELECT id, Name 
                    FROM attachment 
                    WHERE ParentID = : kdID 
                    AND name LIKE 'Genehmigung%'
                    ORDER BY CreatedDate DESC 
                    LIMIT 1]; 
        if((atList != null) && (atList.size() == 1)) {
            attID = atList[0].id;
            if(atList[0].Name.containsIgnoreCase('54')) is54 = true;
            if(atList[0].Name.containsIgnoreCase('51')) is51 = true;
            atName = atList[0].Name;
        }   
        
        gnList = [SELECT id, Name, Nach_Paragraph__c, Name__c, Status__c, Antrag_versandt_am__c 
                    FROM Genehmigung__c 
                    WHERE Kunde__c = : kdID 
                    AND Status__c = 'Antragsversand'
                    ORDER BY LastModifiedDate DESC
                    LIMIT 2];
        if((gnList != null) && (gnList.size() > 0)) {
            for(Genehmigung__c gn : gnList) {
                if((is51) && ((gn.Nach_Paragraph__c == '51') || (gn.Nach_Paragraph__c == '5X'))) genID = gn.id;
                if((is54) && ((gn.Nach_Paragraph__c == '54') || (gn.Nach_Paragraph__c == '5X'))) genID = gn.id;
            }
        }
        if(genID != null) {
            // hie die nechste Seite
            PageReference pageRef = new PageReference('/apex/bearbeitePBGenehmigung?id=' + genID + '&stat=Bewilligung&attid=' + attID);
            pageRef.setRedirect(true);
            return pageRef;
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Die Datei ' + atName + ' kann nicht automatisch zugeordnet werden. Wählen Sie bitte die Genehmigung.'));
            return null;
        }
    }
    
    public PageReference manuelleAuswahl() {
        return null;
    }
    
    public list<attachment> getAtList() {
        return atList;
    }   
    
    public list<Genehmigung__c> getGnList() {
        return gnList;
    }
    
    public string getAttID() {
        return attID;
    }
}