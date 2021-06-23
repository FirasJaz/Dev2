@RestResource(urlMapping='/curabox/*')
global class ksgCuraboxController {
        
    @HttpPost 
    global static string createNewLead( string next_step, 
                                        marketing marketing, 
                                        Box box, 
                                        Insured_person insured_person, 
                                        care_person care_person, 
                                        care_service care_service,
                                        pdf_form pdf_form) {
        
        id rtid = null;                                
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name= 'Curabox'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }   
        
        lead l = new lead(Company='curabox', Status='Open');
        l.RecordTypeId = rtid;
        
        l.next_Step__c = next_step;
        if(box != null) {
            try {
                l.CB_Box__c = box.box;
                l.CB_Handschuh_Groesse__c = box.glove_size;
                l.CB_Lieferung__c = box.delivery_address;
                // = box.bed_protection_underlays;  
            }
            catch (System.Exception e) {}
        }
        if(care_service != null) {
            try {
                l.CB_Pflegedienst_Name__c = care_service.cs_name;
                l.CB_Pflegedienst_PLZ__c = care_service.cs_zipcode;
                l.CB_Pflegedienst_Ort__c = care_service.cs_city;
                l.CB_Pflegedienst_Strasse__c = care_service.cs_street_nr;
            }
            catch (System.Exception e) {}
        }
        if(Insured_person != null) {
            try {
                l.LastName = Insured_person.ip_lname;
                l.FirstName = Insured_person.ip_fname;
                l.Salutation = Insured_person.ip_salutation;
                l.Email = Insured_person.ip_email;
                l.Street = Insured_person.ip_street_nr;
                l.PostalCode = Insured_person.ip_zipcode;
                l.City = Insured_person.ip_city;
                l.Phone = Insured_person.ip_phone;
                l.Geburtsdatum__c = Insured_person.ip_born_at;
                l.Pflegestufe__c = Insured_person.ip_care_level;
                l.Pflegegrad__c = Insured_person.ip_care_rank;
                l.Versicherungsnummer__c = Insured_person.ip_insurance_number;
                l.IK_Nummer_des_traegers__c = Insured_person.ip_identitynumber_carrier_a;
                l.Kostentr_ger__c = Insured_person.ip_identitynumber_carrier_b;
            }
            catch (System.Exception e) {}
        }
        if(care_person != null) {
            try {
                l.Angehoeriger_Anrede__c = care_person.cp_salutation;
                l.Angehoeriger_Vorname__c = care_person.cp_fname;
                l.Angehoeriger_Nachname__c = care_person.cp_lname;
                l.Angehoeriger_Email__c = care_person.cp_email;
                l.Angehoeriger_Telefon__c = care_person.cp_phone;
                l.Angehoeriger_Vollmacht__c = care_person.cp_authorized;
                l.Angehoeriger_Strasse__c = care_person.cp_street_nr;
                l.Angehoeriger_PLZ__c = care_person.cp_zipcode;
                l.Angehoeriger_Ort__c = care_person.cp_city;
            }
            catch (System.Exception e) {}
        }
        if(Marketing != null) {
            try {       
                l.OM_created_at__c = Marketing.created_at;
                l.OM_Tracking_Order_ID__c = Marketing.Order_ID;
                l.OM_Wizard_Version__c = Marketing.wizard_version;
                l.OM_Partner_ID__c = Marketing.Partner_ID;
                List<Campaign> cmplist = [select id, name from Campaign where name =: Marketing.wizard_name LIMIT 1];        
                if(cmplist != null && cmplist.size() != 0) l.OM_Wizzard_Name2__c = cmplist[0].Id;                
            }
            catch (System.Exception e) {}
        }   
        try {
            insert l;
        }
        catch (System.Exception e) {
            system.debug('#########################error ' + e);
        }
        
        if((l.id != null) && (pdf_form != null)) {
            attachment attach = new attachment();
            blob atbody ;
            atbody = System.EncodingUtil.base64Decode(pdf_form.file);
            attach.Body = atbody;
            attach.Name = pdf_form.file_name;
            attach.ContentType = pdf_form.content_type;
            attach.IsPrivate = false;
            attach.ParentId = l.Id;     
            insert attach;              
        }
        
        
        system.debug('#########################alex000 ' + box.box);

        return 'OK';
    }
   
    global class marketing {
        global String created_at {get;set;} 
        global String Order_ID {get;set;} 
        global String wizard_name {get;set;} 
        global String wizard_version {get;set;}
        global String Partner_ID {get;set;}
    }
    
    global class Box {
        global String box {get;set;} 
        global String glove_size {get;set;} 
        global String bed_protection_underlays {get;set;} 
        global String delivery_address {get;set;} 
    }
    
    global class Insured_person {
        global String ip_fname {get;set;} 
        global String ip_lname {get;set;} 
        global String ip_email {get;set;} 
        global String ip_salutation {get;set;} 
        global String ip_zipcode {get;set;} 
        global String ip_city {get;set;} 
        global String ip_phone {get;set;} 
        global String ip_born_at {get;set;} 
        global String ip_care_level {get;set;}
        global String ip_care_rank {get;set;}  
        global String ip_insurance_number {get;set;} 
        global String ip_street_nr {get;set;} 
        global String ip_identitynumber_carrier_a {get;set;} 
        global String ip_identitynumber_carrier_b {get;set;} 
    }

    global class care_person {
        global String cp_fname {get;set;} 
        global String cp_lname {get;set;} 
        global String cp_zipcode {get;set;} 
        global String cp_city {get;set;} 
        global String cp_email {get;set;} 
        global String cp_phone {get;set;} 
        global String cp_authorized {get;set;} 
        global String cp_salutation {get;set;} 
        global String cp_street_nr {get;set;} 
    }

    
    global class care_service {
        global String cs_name {get;set;} 
        global String cs_zipcode {get;set;} 
        global String cs_city {get;set;} 
        global String cs_street_nr {get;set;} 
    }   

    global class pdf_form {
        global String file_name {get;set;}
        global String content_type {get;set;} 
        global Integer file_size {get;set;} 
        global String file {get;set;} 
    }
    
}