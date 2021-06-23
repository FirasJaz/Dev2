/****************************************************************************************************************************
// Erstellt 25.09.2015 von AM
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
// kd.id [ et.id] 
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Verwenden Templates mit Platzhalter für eMails an Kunden 
//
//
//****************************************************************************************************************************
//Änderungen:
//
//
//****************************************************************************************************************************/

public with sharing class mail_template_holen {
    private string betreff {get;set;}
    private string plaintextbody {get;set;}
    private string htmlbody {get;set;}
    private id kdid = null;
    private id etid = null;
    private id auid = null;

    // constructor 1    
    public mail_template_holen(ID kdid) {
        this.kdid = kdid;
        processTemplate();
    }

    // constructor 2    
    public mail_template_holen(ID kdid, ID etid) {
        this.kdid = kdid;
        this.etid = etid;
        processTemplate();
    }
    
    // constructor 3    
    public mail_template_holen(ID auid, ID kdid, ID etid) {
        this.kdid = auid;
        this.etid = etid;
        this.auid = auid;
        processTemplate();
    }
    
    private void processTemplate() {
        boolean error = false;
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> tmpList= new List<Messaging.SingleEmailMessage>();
        if(etid != null) {
            msg.setTemplateId(etid);
        }
        else {
            list<EmailTemplate> etList = [SELECT id, Name FROM EmailTemplate WHERE name = 'pflege.de default'];
            if((etList != null) && (etList.size() > 0)) { 
                msg.setTemplateId(etList[0].id);
            }
            else {
                error = true;
            }
        }        
        if(!error) {
            Savepoint sp = Database.setSavepoint();
            Contact cn = new contact(email = 'testmail@testmail.com', lastname='mm');
            insert cn;
            msg.setTargetObjectId(cn.id); 
            String sObjectName = kdid.getSObjectType().getDescribe().getName();
            if(sObjectName != 'contact') {
                msg.setWhatId(kdid);
            }
            String[] toAdd =  new String[] {'alex.mischenko@freenet.de'}; 
            msg.setToAddresses(toAdd);
            tmpList.add(msg);
            Messaging.sendEmail(tmpList);
            Database.rollback(sp);  
            htmlbody = msg.getHTMLBody();
            plaintextbody = msg.getPlainTextBody();
            betreff = msg.getSubject();   
        }
        else {
            htmlbody = ' ';
            plaintextbody = ' ';
            betreff = ' ';          
        }
    }
    
    public string getBetreff() {
        return betreff;
    }
    
    public string getPlaintextBody() {
        return plaintextbody;
    }
    
    public string getHTMLbody() {
        return htmlbody;
    }

}