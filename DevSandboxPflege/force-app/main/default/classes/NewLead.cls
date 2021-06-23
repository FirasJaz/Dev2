/****************************************************************************************************************************
// Erstellt 13.09.2016 von MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:
// New Lead
//
//****************************************************************************************************************************
//Änderungen:
//    15.06.2017    BT    Erweiterung um den neuen Recordtype "Notrufsysteme"
//    13.07.2017    BT    Erweiterung um die Recordtypen "Widerspruch" und "Pflegeimmobilien"
//    20.03.2018    MZ    #155510105 Erweiterung um die Recordtypen "Badumbau". new fields added.
//    24.04.2018    MZ    #155510105 Erweiterung um die Recordtypen "Badumbau". products changed.
//    26.04.2019    MZ    Curabox redesign - getHandschuheOptions and getCuraboxOptions changed to pick list
//****************************************************************************************************************************
*/
global with sharing class NewLead{
     
     public static String art_tl = 'Treppenlift';
     public static String art_bel  = 'Betreuungsleistungen';
     public static String art_hnr = 'Notrufsysteme';
     public static String art_cbx = 'Curabox';
     public static String art_ws = 'Widerspruch';
     public static String art_pi = 'Pflegeimmobilien';
     public static String art_bad = 'Badumbau';
     
     public Boolean disableSave {get; set;}
     
     public Boolean is_art_tl {get; set;}
     public Boolean is_art_bel {get; set;}
     public Boolean is_art_hnr {get; set;}
     public Boolean is_art_cbx {get; set;}
     public Boolean is_art_ws {get; set;}
     public Boolean is_art_pi {get; set;}
     public Boolean is_art_bad {get; set;}
         
     public string message {get; set;}
     public string message_layout;
     public string modalDialogLayout {get; set;}
     public Lead formObj {get; set;}
     public Contact contact;
     
     public List<SelectOption> productGroupOptions { get; set; }
     public List<SelectOption> locationOptions {get; set;}
     public List<SelectOption> betreuungOptions { get; set; }
     
     public String art{get; set;}
     public String art_layout{get; set;}
        
     global NewLead(ApexPages.StandardController controller) {
         initialForm();
     }
           
     global NewLead() {
         initialForm();
     }
     
     public void initialForm(){
         
         disableSave = false;
         art = art_tl;
         art_layout = 'initial';
         setArtFlag();
         formObj = new Lead();
         formObj .LastName = 'test';         
         List<Campaign> cl = [select id, name from Campaign limit 1];
         if(cl != null && cl.size() > 0){
             formObj .OM_Wizzard_Name2__c = cl[0].Id;
         }else{
             art_layout = 'None';
             disableSave = true;
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No campaign Found! please try again after inserting a campaign.'));
         }
         
         Id contactId = ApexPages.currentPage().getParameters().get('cnt_id');
         if(contactId != null){
             List<Contact> contact_list = [select 
                                             Id,
                                             Salutation,
                                             FirstName,
                                             LastName,
                                             MailingStreet,
                                             MailingCity,
                                             MailingState,
                                             MailingPostalCode,
                                             MailingCountry,
                                             Email,
                                             Phone,
                                             OtherPhone,
                                             Birthdate,
                                             Pflegegrad__c,
                                             Pflegestufe__c,
                                             Kranken_Pflegekasse__c,
                                             Versicherungsnummer__c
                                           from Contact
                                           where Id = : contactId 
                                           limit 1];
             if(contact_list != null && contact_list.size()>0){
                 contact = contact_list[0];
             }
         }
     }
    
     public List<SelectOption> getArtItems() {
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption(art_tl, art_tl)); 
         options.add(new SelectOption(art_bel, art_bel)); 
         options.add(new SelectOption(art_hnr, art_hnr));
         options.add(new SelectOption(art_pi, art_pi));
         options.add(new SelectOption(art_ws, art_ws));
         options.add(new SelectOption(art_bad, art_bad));
         options.add(new SelectOption(art_cbx, art_cbx));
         
         return options;
     }
     
     public void setArtFlag(){
         is_art_tl = false;
         is_art_bel = false;
         is_art_hnr = false;
         is_art_cbx = false;
         is_art_ws = false;
         is_art_pi = false;
         is_art_bad = false;
         
         if(art == art_tl){
             is_art_tl = true;
         }
         if(art == art_bel){
             is_art_bel = true;
         }
         if(art == art_hnr){
             is_art_hnr = true;
         }
         if(art == art_cbx){
             is_art_cbx = true;
         }
         if(art == art_ws) {
             is_art_ws = true;
         }
         if(art == art_pi) {
             is_art_pi = true;
         }
         if(art == art_bad) {
             is_art_bad = true;
         }
         
     }
     
     public void setContactFields(){
         formObj.Salutation = contact.Salutation;
         formObj.Email = contact.Email;
         formObj.FirstName = contact.FirstName;
         formObj.Phone = contact.Phone;
         formObj.LastName = contact.LastName;
         formObj.Phone2__c = contact.OtherPhone;
         formObj.Street = contact.MailingStreet;
         formObj.City = contact.MailingCity;
         formObj.State = contact.MailingState;
         formObj.PostalCode = contact.MailingPostalCode;
         formObj.Country = contact.MailingCountry;
         if(is_art_cbx){
             formObj.pflegegrad__c = contact.Pflegegrad__c;
             formObj.Pflegestufe__c = contact.Pflegestufe__c;
             formObj.Kostentr_ger__c = contact.Kranken_Pflegekasse__c;
             formObj.Versicherungsnummer__c = contact.Versicherungsnummer__c;
             formObj.Geburtsdatum__c = String.valueof(contact.Birthdate);
             
             if(contact.Kranken_Pflegekasse__c != null){
                 List<Account> al = [select id, name from Account where id = :contact.Kranken_Pflegekasse__c limit 1];
                 if(al != null && al.size()>0){
                     formObj.Kostentr_ger__c = al[0].name;
                 }
             }
         }
     }
     
     public void setOwner(){
         List<user> user_list = [select id, name from user where user.name = 'IT Support' limit 1];
        if(user_list != null && user_list.size()>0){
            formObj.ownerID = user_list[0].id;
        }
     }
     
     public pageReference setRecordType() {
         if(art != null ){
             formObj = new Lead();
             formObj.Company = art ;
             formObj.Status = 'Open';             
             
             List<RecordType> rtList = [select Id, Name, DeveloperName, SObjectType from RecordType where Name = :art and SobjectType = 'Lead' limit 1];
             if(rtList !=null && rtList.size() > 0){
                 formObj.RecordTypeId= rtList[0].Id;
             }else{
                 ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No recordtType "'+ art +'" found for SobjectType "Lead"!'));
             }
             art_layout = 'None';
             setArtFlag();
             if(is_art_pi) formObj.TL_Treppenliftart__c = 'Pflegeimmobilien';
             
             setMultiSelectListOptions();
             if(contact != null){
                 setContactFields();
             }
             setOwner();
         }
         return null;             
     }
     
     public void formatMultiSelectValues(){
        if(is_art_tl){
            formObj.TL_Treppenliftart__c = formatValue(formObj.TL_Treppenliftart__c);
        }
        if(is_art_bel){
            formObj.TL_Treppenliftart__c = formatValue(formObj.TL_Treppenliftart__c);
            formObj.Aktuelle_Betreuung__c = formatValue(formObj.Aktuelle_Betreuung__c);
         }
         if(is_art_hnr){
            formObj.TL_Treppenliftart__c = formatValue(formObj.TL_Treppenliftart__c);
         }
         if(is_art_ws){
            formObj.TL_Treppenliftart__c = formatValue(formObj.TL_Treppenliftart__c);
         }
         if(is_art_pi){
            formObj.TL_Treppenliftart__c = formatValue(formObj.TL_Treppenliftart__c);
            formObj.location_direction__c = formatValue(formObj.location_direction__c);
         }   
                     
    }
    
    public String formatValue(String inputStr){
        String outputStr = '';
        if(inputStr == null || inputStr == '[]' || inputStr == ''){
            return null;        
        }
        else{
            inputStr = inputStr.subString(1, inputStr.length()-1);
            System.debug('mansi:::'+ inputStr);
            String[] values = inputStr.split(', ');
            if(values.size()>1){
                for(String v : values){
                    outputStr += v + ';';
                }
                outputStr = outputStr.subString(0, outputStr.length()-1);
            }
            else{
                outputStr = inputStr;
            }
        }
        return outputStr;
    }
     
     public void setMultiSelectListOptions() {
         if(is_art_tl){
             productGroupOptions = getProductGroupTL();
         }
         if(is_art_bel){
             productGroupOptions = getProductGroupBEL();
             betreuungOptions = getBetreuung();
         }
         if(is_art_hnr){
             productGroupOptions = getProductGroupHNR();
         }
         if(is_art_ws) {
             productGroupOptions = getProductGroupWS();
         }
         if(is_art_pi) {
             productGroupOptions = getProductGroupPI();
             locationOptions = getlocations();
         }
         if(is_art_bad) {
             productGroupOptions = getProductGroupBAD();
         }
    } 
    
    public List<Selectoption> getProductGroupTL(){
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('Sitzlift', 'Sitzlift')); 
         options.add(new SelectOption('Plattformlift', 'Plattformlift')); 
         options.add(new SelectOption('Senkrechtlift', 'Senkrechtlift')); 
         options.add(new SelectOption('Hublift', 'Hublift')); 
         options.add(new SelectOption('Behindertenlift', 'Behindertenlift')); 
         options.add(new SelectOption('gebrauchter Lift', 'gebrauchter Lift'));
         options.add(new SelectOption('Noch unklar', 'Noch unklar'));
         return options;
    }
    
    public List<Selectoption> getProductGroupBEL(){
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('24h Betreuung', '24h Betreuung')); 
         options.add(new SelectOption('Stundenweise Betreuung', 'Stundenweise Betreuung')); 
         options.add(new SelectOption('Medizinische Pflege', 'Medizinische Pflege')); 
         options.add(new SelectOption('Leichte Pflege', 'Leichte Pflege')); 
         options.add(new SelectOption('Betreuung', 'Betreuung')); 
         options.add(new SelectOption('Hauswirtschaft', 'Hauswirtschaft')); 
         options.add(new SelectOption('Noch unklar', 'Noch unklar'));
         return options;
    }
    
    public List<Selectoption> getProductGroupHNR(){
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('Hausnotruf', 'Hausnotruf')); 
         options.add(new SelectOption('Mobile Notruflösung', 'Mobile Notruflösung'));
         options.add(new SelectOption('Zu Hause & mobil', 'Zu Hause & mobil'));
         options.add(new SelectOption('Hausnotruf Basis', 'Hausnotruf Basis'));
         options.add(new SelectOption('Hausnotruf Service', 'Hausnotruf Service'));
         options.add(new SelectOption('Mobiler Notruf', 'Mobiler Notruf'));
         options.add(new SelectOption('Notrufhandy', 'Notrufhandy'));
         return options;
    }  
    
    public List<Selectoption> getProductGroupWS(){
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('Widerspruch', 'Widerspruch')); 
         return options;
    }     
    
    public List<Selectoption> getProductGroupPI(){
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('Pflegeimmobilien', 'Pflegeimmobilien')); 
         return options;
    }  
    
    public List<Selectoption> getProductGroupBAD(){
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('Umbau zur Dusche', 'Umbau zur Dusche'));
         options.add(new SelectOption('Badewannentür', 'Badewannentür'));
         options.add(new SelectOption('Badewanneneinstieg', 'Badewanneneinstieg')); 
         options.add(new SelectOption('Sitzbadewanne', 'Sitzbadewanne'));
         options.add(new SelectOption('Noch unklar', 'Noch unklar'));
         return options;
    }  
    
    public List<Selectoption> getLocations(){
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('Norddeutschland', 'Norddeutschland')); 
         options.add(new SelectOption('Süddeutschland', 'Süddeutschland')); 
         options.add(new SelectOption('Westdeutschland', 'Westdeutschland')); 
         options.add(new SelectOption('Ostdeutschland', 'Ostdeutschland')); 
         return options;
    }             
    
    public List<Selectoption> getBetreuung(){
         List<SelectOption> options = new List<SelectOption>();
         Schema.DescribeFieldResult fieldResult = Lead.Aktuelle_Betreuung__c.getDescribe();
         List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
         for( Schema.PicklistEntry f : ple){
             options.add(new SelectOption(f.getValue(), f.getLabel()));
         }
         return options;
    }
     
     public void checkSelectedValue(){        
        system.debug('Selected value is: ' + art);        
    }  
     
     public string getMessage_layout(){
        if(message == null){
            return 'none';
        }
        else {
            return 'initial';
        }
    }
    
    public PageReference zuLeads(){
        //List<ListView> listViewList = [select Id, Name, SobjectType, DeveloperName from ListView where DeveloperName = 'Treppenlift_eingang' and SobjectType = 'Lead' limit 1 ];
        //if(listViewList != null && listViewList.size()>0){
            
            PageReference PageRef = new PageReference('/00Q/o');
            PageRef.setRedirect(true);
            return PageRef;
        //}
        //return null;
    } 
    
    public PageReference speichern(){ 
        formatMultiSelectValues();
        if(art == art_ws) formObj.TL_Treppenliftart__c = 'Widerspruch;'; 
        
        insert formObj;
        
        if(formObj.Id != null){
            PageReference PageRef = new PageReference('/' + formObj.Id);
            PageRef.setRedirect(true);
                      
            return PageRef;
        }
        return null;
    }

    // to get options of curabox pick list - CB_Box__c field
    public List<Selectoption> getCuraboxOptions(){
        List<SelectOption> options = new List<SelectOption>();
        
        List<curabox__c> curaboxList= [select id, Name from curabox__c limit 100];
        
        options.add(new SelectOption('', '- Ohne -')); 
        if(curaboxList != null && !curaboxList.isEmpty()){
            for(curabox__c cb : curaboxList){
                options.add(new SelectOption(cb.Name, cb.Name));
            }
        }
        return options;
    }
    
    // get list of handschuheOptions for pick list options - CB_Handschuh_Groesse__c field
    public List<Selectoption> getHandschuheOptions(){
        List<SelectOption> options = new List<SelectOption>();
        
        List<Product__c> HandschuheList = [select Id, Name, Product_Group__r.Name from Product__c where Product_Group__r.Name = 'Einmalhandschuhe' limit 100];
		
        options.add(new SelectOption('', '- Ohne -')); 
        if(HandschuheList != null && !HandschuheList.isEmpty()){
            for(Product__c prd : HandschuheList){
                options.add(new SelectOption(prd.Name, prd.Name));
            }
        }
        
        return options;
    }      
}