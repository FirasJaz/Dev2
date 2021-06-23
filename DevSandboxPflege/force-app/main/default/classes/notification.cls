/********************************************************************************************************************************************
// Created 15.10.2016 by AM
//                      Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                      Nordkanalstraße 58
//                      20097  Hamburg 
//                      Tel.:  0423882986
//                      Fax.:  0423882986
//                      Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:    
//
//********************************************************************************************************************************************
// Changes:
// 03.04.2018    MZ    #155510105 link added to notification center
// 17.07.2018    MZ    add Emailmessage link for Badumbau inbound emails
// 17.06.2019    WDS   #xxxxxxxxx add curabox to notification center
// 13.05.2020    DZ    Multilead eingebaut
//********************************************************************************************************************************************
*/
public without sharing class notification {

    private integer totalOpps = 0;
    private integer totalLeads = 0;
    private integer totalLeadsBEL = 0;
    private integer totalLeadsTL = 0;        
    private integer totalLeadsHNR = 0;
    private integer totalleadsHNR_prio = 0;
    private integer totalLeadsPI = 0;
    private integer totalLeadsWS = 0;
    private integer totalLeadsBAD = 0;
    private integer totalLeadsCurabox = 0;
    private integer totalLeadsMultilead = 0; 
    private integer neueEmails = 0;
    private integer newEmailsBadumbau = 0;
    
    
    public notification() {
        neueEmails = ungeleseneEmails();
        totalOpps = OppsPruefen();
        totalleads = leadsPruefen();
        totalleadsBEL = leadsPruefenBEL();
        totalleadsTL = leadsPruefenTL();
        totalleadsHNR = leadsPruefenHNR();
        totalleadsHNR_prio = leadsPruefenHNR_prio();
        totalLeadsPI = leadsPruefenPI();
        totalLeadsWS = leadsPruefenWS();
        totalLeadsBAD = leadsPruefenBAD();
        totalLeadsCurabox = LeadsPruefenCurabox();
        totalLeadsMultilead = leadsPruefenMultilead ();
        newEmailsBadumbau = countNewBadumbauEmails();
    }

    public notification(ApexPages.StandardController controller) {
        totalOpps = OppsPruefen();
        totalleads = leadsPruefen();
        totalleadsBEL = leadsPruefenBEL();
        totalleadsTL = leadsPruefenTL();                
        totalleadsHNR = leadsPruefenHNR();
        totalleadsHNR_prio = leadsPruefenHNR_prio();
        neueEmails = ungeleseneEmails();
        totalLeadsPI = leadsPruefenPI();
        totalLeadsWS = leadsPruefenWS();
        totalLeadsBAD = leadsPruefenBAD();
        totalLeadsCurabox = LeadsPruefenCurabox();
        totalLeadsMultilead = leadsPruefenMultilead ();
        newEmailsBadumbau = countNewBadumbauEmails();
    }
    
        
    public PageReference countleads() {
         totalOpps = OppsPruefen();
         totalleads = leadsPruefen();
         totalleadsBEL = leadsPruefenBEL();
         totalleadsTL = leadsPruefenTL();    
         totalleadsHNR = leadsPruefenHNR();
         totalleadsHNR_prio = leadsPruefenHNR_prio();
         totalLeadsPI = leadsPruefenPI();
         totalLeadsWS = leadsPruefenWS();
         totalLeadsBAD = leadsPruefenBAD();
         totalLeadsCurabox = LeadsPruefenCurabox();
         totalLeadsMultilead = leadsPruefenMultilead ();
         newEmailsBadumbau = countNewBadumbauEmails();
         neueEmails = ungeleseneEmails();
         return null;  
    }
    
    public string getDatumZeit() {
        datetime dt = datetime.now();
        return dt.format('HH:MM:ss');
    }
    
    public integer OppsPruefen() {
        integer count= database.countQuery('select count() from Opportunity where owner.name = \'IT Support\' and stageName= \'Offen\' and recordtype.name IN ( \'Treppenlift\', \'Betreuungsleistungen\', \'Notrufsysteme\', \'Widerspruch\', \'Pflegeimmobilien\', \'Badumbau\') and Prio__c = true');
        return count;
    }
    
    public integer leadsPruefen() {
        //integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Treppenlift\' and status= \'Open\') or (owner.name = \'IT Support\' and recordtype.name =  \'Betreuungsleistungen\' and status= \'Open\') or (owner.name = \'IT Support\' and recordtype.name =  \'Hausnotruf\' and status= \'Open\')');
        integer count= database.countQuery('select count() from lead where owner.name = \'IT Support\' and status= \'Open\' and recordtype.name IN ( \'Treppenlift\', \'Betreuungsleistungen\', \'Notrufsysteme\', \'Widerspruch\', \'Pflegeimmobilien\', \'Badumbau\' , \'Curabox\')');
        return count;
    }
    
    public integer leadsPruefenBEL() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Betreuungsleistungen\' and status= \'Open\')');
        return count;
    }
    
    public integer leadsPruefenTL() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Treppenlift\' and status= \'Open\')');
        return count;
    }
    
    public integer leadsPruefenHNR() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Notrufsysteme\' and status= \'Open\')');
        return count;
    }   
    
    public integer leadsPruefenHNR_prio() {
        integer count= database.countQuery('select count() from Opportunity where (owner.name = \'IT Support\' and recordtype.name =  \'Notrufsysteme\' and stageName= \'Offen\' and Prio__c = true)');
        return count;
    }
    
    public integer leadsPruefenPI() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Pflegeimmobilien\' and status= \'Open\')');
        return count;
    }   
    
    public integer leadsPruefenWS() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Widerspruch\' and status= \'Open\')');
        return count;
    }   
    
    public integer leadsPruefenBAD() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Badumbau\' and status= \'Open\')');
        return count;
    } 
//
// 17.06.2019 wds
//    
    public integer leadsPruefenCurabox() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Curabox\' and status= \'Open\')');
        return count;
    } 
//      
    
// 13.05.2020 DZ
//    
    public integer leadsPruefenMultilead() {
        integer count= database.countQuery('select count() from lead where (owner.name = \'IT Support\' and recordtype.name =  \'Multilead\' and status= \'Open\')');
        return count;
    } 
//
    public integer countNewBadumbauEmails() {
        integer count = database.countQuery('select count() from EmailMessage where status = \'0\' and Incoming = true and Badumbau_inbound__c = true ');
        return count;
    }   
    
    
    public integer ungeleseneEmails() {
        integer count= database.countQuery('select count() from task where status = \'Ungelesen\' and recordtype.name = \'Email\'');
        return count;
    }
    
    public integer getTotalOpps(){
        return totalOpps;
    }
    
    public integer getTotalLeads() {
        return totalleads;
    }
    public integer getTotalLeadsBEL() {
        return totalleadsBEL;
    }
    public integer getTotalLeadsTL() {
        return totalleadsTL;
    }
    public integer getTotalLeadsHNR() {
        return totalleadsHNR;
    }
    public integer getTotalleadsHNR_prio() {
        return totalleadsHNR_prio;
    }
    public integer getTotalLeadsPI() {
        return totalleadsPI;
    }
    public integer getTotalLeadsWS() {
        return totalleadsWS;
    }
    public integer getTotalLeadsBAD() {
        return totalleadsBAD;
    }
    
    public integer getTotalLeadsCurabox() {
        return totalleadsCurabox;
    }        
    
    public integer getTotalLeadsMultilead() {
    return totalleadsMultilead;
    }
    
    public integer getNewEmailsBadumbau(){
        return newEmailsBadumbau;
    }
    
    public integer getneueEmails() {
        return neueEmails;
    }
    
    public string filterId {
        set;
        get {
            string ret = '';
            list<listview> listLV = [SELECT id FROM listview WHERE name = 'Treppenlift - EINGANG' and SobjectType = 'lead'];
            if((listLV != null) && (listLV.size() > 0)) ret = string.valueOf(listLV[0].id);
            return ret;
        }
    }
     public string filterIdEmail {
        set;
        get {
            string ret = '';
            list<listview> listLV = [SELECT id FROM listview WHERE name = 'Incoming Emails' and SobjectType = 'Report'];
            if((listLV != null) && (listLV.size() > 0)) ret = string.valueOf(listLV[0].id);
            return ret;
        }    
    }

}