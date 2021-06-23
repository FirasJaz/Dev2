//****************************************************************************************************************************
// Created 06.11.2017 von BT
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
// Partner-Ticket
//
//****************************************************************************************************************************
//
// Description:
//                                                                                                  
// sendet Http Request an Libify
//
//
//****************************************************************************************************************************
//Changes:
// 15.12.2017    MZ    unique leads added. the value of parameter "afilliate_code" changed.
// 02.03.2018    MZ    #155359250 interface to send Direktvertrieb (DV) data to Libify
// 13.03.2018    MZ    #155359250
// 05.04.2018    MZ    #156189887 get bank-data from opportunity. when empty then ASP bank-data is used.
// 23.08.2018    MZ    #159923232 Libify - Empfangsbestätigungen und Alert
// 29.08.2018    MZ    #159923232 Libify - Empfangsbestätigungen und Alert - sending email functionality added
// 22.06.2020	 BT	   00002454 - added '+49' to the contact phone number, retrieved access data from custom setting
// 22.06.2020	 BT	   00002454 - handling phone number
// 27.07.2020    BT	   00002454 - check if contact fields are empty
//****************************************************************************************************************************
public class libifyRequest {
    public static String libifyL='Libify Technologies GmbH <L>';// none-unique leads
    public static String libifyU='Libify Technologies GmbH <U>';// unique leads
    public static String libifyD='Libify Technologies GmbH <DA>';// Direktvertrieb leads
    
    public static String libifyL_NUL = 'NULPFLEGE'; // none-unique leads
    public static String libifyU_UL = 'ULPFLEGE'; // unique leads
    public static String libifyD_DA = 'DAPFLEGE';// Direktvertrieb leads
    
    public static String LibifyEndPoint = 'https://crm.stage.libify.com/api/rest/affiliates/leads';
    public static String LibifyEndPointDirekt = 'https://leadserver.geox.ws/Pflege.de.direkt.api';
    
    public static String LibifyUsername = 'pflegede';
    public static String LibifyToken = '48629b5714abc3bc6b683879076694bd8c7f1ac6';    
    
    public static boolean send_libifyRequest(Id pt_id, string afilliateCode) {
        
        boolean error = false;
        List<Contact> kontaktListe;
        Partner_Ticket__c pt = [select id, createdDate, Name, Opportunity__r.Alternative_Postleitzahl__c, opportunity__c,
                                Opportunity__r.Angefragter_Wohnort__c, Opportunity__r.Anmerkungen_f_r_den_Partner__c,
                                Opportunity__r.Produkt_Kategorie__c, Opportunity__r.AccountId from Partner_Ticket__c where id =: pt_id limit 1];
        try{
            Id contactId;
            List<OpportunityContactRole> role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId =: pt.opportunity__c and (Role =: PLZTool_Basis.contactRoleContact or Role =: PLZTool_Basis.contactRoleSame)];
            if(role_list != null && role_list.size()>0){
                contactId = role_list[0].ContactId;
            }
            if(contactId == null){
                role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId =: pt.opportunity__c and ( Role =: PLZTool_Basis.contactRoleInsured or Role =: PLZTool_Basis.contactRoleSame)];
                if(role_list != null && role_list.size()>0){
                    contactId = role_list[0].ContactId;
                }
            }
            
            if(contactId != null){
                kontaktListe = [select id, AccountId, Salutation, Lastname, Firstname, MailingStreet, MailingPostalcode, MailingCity,
                                Phone, Fax, MobilePhone, Email, RecordTypeId, house_number__c, street_name__c  from contact where Id =: contactId LIMIT 1];
            }
            
            if(kontaktListe != null && kontaktListe.size() > 0) { 
                HttpRequest req = new HttpRequest();
                HttpResponse res = new HttpResponse();
                Http http = new Http();                                                                                                                                                                                                                                                                                                                                         
                
                Contact cont = kontaktListe[0];                           
                
                //String jsonBody = '{';
                //jsonBody += '\"company\":\"Pflege.de\",'; 
                //jsonBody += '\"Datum\":\"' + pt.createdDate + '\",'; 
                //jsonBody += '\"lead_id\":\"' + pt.Name + '\",';
                //jsonBody += '\"salutation\":\"' + cont.salutation + '\",';
                //jsonBody += '\"surname\":\"' + cont.Lastname + '\",';
                //jsonBody += '\"firstname\":\"' + cont.Firstname + '\",';
                //jsonBody += '\"street\":\"' + cont.MailingStreet + '\",';
                //jsonBody += '\"zip_code\":\"' + cont.MailingPostalcode + '\",';
                //jsonBody += '\"city\":\"' + cont.MailingCity + '\",';
                //jsonBody += '\"phone\":\"' + cont.Phone + '\",';
                //jsonBody += '\"Telefax\":\"' + cont.Fax + '\",';
                //jsonBody += '\"mobile\":\"' + cont.MobilePhone + '\",';
                //jsonBody += '\"email\":\"' + cont.Email + '\",';
                //jsonBody += '\"Standort_Name\":\"\",';
                //jsonBody += '\"Standort_Strasse\":\"\",';                                                                                                         
                //jsonBody += '\"Standort_PLZ\":\"' + pt.Opportunity__r.Alternative_Postleitzahl__c + '\",';
                //jsonBody += '\"Standort_Ort\":\"' + pt.Opportunity__r.Angefragter_Wohnort__c + '\",';
                //jsonBody += '\"additional_custom_info\":\"' + pt.Opportunity__r.Anmerkungen_f_r_den_Partner__c + '\",';
                //jsonBody += '\"Produkt\":\"Notrufsystem\",';
                //jsonBody += '\"Interesse\":\"' + pt.Opportunity__r.Produkt_Kategorie__c + '\",';
                //jsonBody += '\"afilliate_code\":\"' + afilliateCode + '\"';
                //jsonBody += '} ';
                
                String contactSalutation = '';
                if(cont.salutation.contains('Herr')) {
                    contactSalutation = 'herr';                               
                }
                if(cont.salutation.contains('Frau')) {
                    contactSalutation = 'frau';                               
                }
                String jsonBody = '{\r\n';
                jsonBody += '\"lead\": {\r\n';
                jsonBody += '\"affiliate_code\": \"'+ afilliateCode +'\",\r\n';
                jsonBody += '\"lead_id\": \"'+ pt.Name +'\",\r\n';
                jsonBody += '\"advertising\": \"email;phone;mobile;\"\r\n';
                jsonBody += '},\r\n';
                jsonBody += '\"subscriber\": {\r\n';
                if(!String.isBlank(cont.Firstname)) {
                    jsonBody += '\"firstname\": \"'+ cont.Firstname +'\",\r\n';               
                }
                else {
                    jsonBody += '\"firstname\": \"\",\r\n';               
                }
                jsonBody += '\"surname\": \"'+ cont.Lastname +'\",\r\n';                            
                jsonBody += '\"salutation\": \"'+ contactSalutation +'\",\r\n';
                if(!String.isBlank(cont.street_name__c)) {
                    jsonBody += '\"street\": \"'+ cont.street_name__c +'\",\r\n';
                }
                else {
                    jsonBody += '\"street\": \"\",\r\n';
                }
                if(!String.isBlank(cont.house_number__c)) {
                    jsonBody += '\"street_number\": \"'+ cont.house_number__c +'\",\r\n';
                }
                else {
                    jsonBody += '\"street_number\": \"\",\r\n';
                }
                if(!String.isBlank(cont.MailingPostalcode)) {
                    jsonBody += '\"zip_code\": \"'+ cont.MailingPostalcode +'\",\r\n';
                }
                else {
                    jsonBody += '\"zip_code\": \"\",\r\n';
                }
                if(!String.isBlank(cont.MailingCity)) {
                    jsonBody += '\"city\": \"'+ cont.MailingCity +'\",\r\n';	
                }
                else {
                    jsonBody += '\"city\": \"\",\r\n';	
                }                		
                jsonBody += '\"country\": \"DE\",\r\n'; 
                if(!String.isBlank(cont.Phone)) {
                    String phone;
                    if(cont.Phone.startsWith('+49') || cont.Phone.startsWith('0049')) {
                        phone = cont.Phone.replaceAll(' ', '');
                        jsonBody += '\"phone\": \"'+ phone + '\",\r\n';     
                    }
                    else {
                        phone = cont.Phone.removeStart('0');
                        phone = phone.replaceAll(' ', '');
                        jsonBody += '\"phone\": \"'+ '+49' + phone + '\",\r\n'; 
                    }                              
                }     
                else {
                    jsonBody += '\"phone\": \"\",\r\n'; 
                }
                if(!String.isBlank(cont.Email)) {
                    jsonBody += '\"email\": \"'+ cont.Email +'\"\r\n';
                }
                else {
                    jsonBody += '\"email\": \"\"\r\n';
                }
                jsonBody += '}\r\n';
                jsonBody += '}';
                
                System.debug('################ Input Request:' + jsonBody);
                
                try {                                                                        
                    req.setEndpoint(getEndpoint());
                    req.setMethod('POST');                    
                    req.setCompressed(false);
                    req.setBody(jsonBody);
                    req.setHeader('Content-Type', 'application/json; charset=UTF-8');
                    req.setHeader('Content-Length', String.valueOf(jsonBody.length()));
                    // BT 14.05.2020 added new header attribute 
                    req.setHeader('Authorization', 'WSSE profile="UsernameToken"');                                
                    req.setHeader('X-WSSE',createHeader(getUsername(), getToken()));                                
                    res = http.send(req);
                    System.debug('########## res=' + res.toString());
                    System.debug('########## STATUS:' + res.getStatus());
                    System.debug('########## STATUS_CODE:' + res.getStatusCode());
                    
                    String responseXML = res.getBody();
                    System.debug('responseXML:' + responseXML);
                    
                    // insert a record in object Libify_Response__c
                    saveRequest(pt_id, req.getBody(), res.toString());
                    
                    // send email to pflege.de in case of error
                    if(res.getStatusCode() != 200 ){
                        sendEmailToTeamLead(pt_id, pt.Name, '\n failed to send ticket \''+ pt.Name +'\' to Libify. \n response:\n' + res.toString() + '\n response body:\n' + res.getBody() );
                    }
                    
                }
                catch(System.CalloutException e) {
                    error = true;
                    System.debug('############ Callout error: ' + e);
                    
                    // insert a record in object Libify_Response__c in case of error
                    saveRequest(pt_id, req.getBody(), res.toString() + '\n exception occured:\n Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage() );
                    
                    
                    sendEmailToTeamLead(pt_id, pt.Name, '\n failed to send ticket \''+ pt.Name +'\' to Libify. \n response:\n' + res.toString() + '\n response body:\n' + res.getBody() + '\n exception occured:\n' + ' Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage());
                }
            }
        }catch(exception e){
            error = true;
            saveRequest(pt_id, '', 'exception occured:\n Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage() );
            sendEmailToTeamLead(pt_id, pt.Name, '\n failed to send ticket \''+ pt.Name +'\' to Libify. \n exception occured:\n' + ' Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage());
        }
        return error;
        
    }
    
    
    public static boolean send_libifyRequest_DV(Id pt_id, string afilliateCode) {
        boolean error = false;
        List<Contact> kontaktListe;
        Partner_Ticket__c pt = [select id, 
                                createdDate,
                                createdbyId, 
                                Name, 
                                Opportunity__r.Alternative_Postleitzahl__c, 
                                opportunity__c,
                                Opportunity__r.Angefragter_Wohnort__c, 
                                Opportunity__r.Auftragsstatus__c,
                                Opportunity__r.Anmerkungen_f_r_den_Partner__c,
                                Opportunity__r.Produkt_Kategorie__c, 
                                Opportunity__r.AccountId,
                                Partner_Produkt__r.Libify_Artikelnummer__c,
                                Opportunity__r.Libify_Zubehoer__c,
                                Opportunity__r.Versandadresse_Anrede__c,
                                Opportunity__r.Versandadresse_Name__c,
                                Opportunity__r.Versandadresse_Ort__c,
                                Opportunity__r.Versandadresse_PLZ__c,
                                Opportunity__r.Versandadresse_Stra_e__c,
                                Opportunity__r.Versandadresse_Vorname__c,
                                Opportunity__r.Versandtdatum__c,
                                Opportunity__r.description,
                                Opportunity__r.Bezugsperson_1__c,
                                Opportunity__r.Bezugsperson_2__c,
                                Opportunity__r.Code_des_Schl_sseltresors_BP1__c,
                                Opportunity__r.Code_des_Schluesseltresors_BP2__c,
                                Opportunity__r.Entfernung_zum_Nutzer_BP1__c,
                                Opportunity__r.Entfernung_zum_Nutzer_BP2__c,
                                Opportunity__r.Hausschluessel_BP1__c,
                                Opportunity__r.Hausschl_ssel_BP2__c,
                                Opportunity__r.Montageort_des_Tresors_BP1__c,
                                Opportunity__r.Montageort_des_Tresors_BP2__c,
                                Opportunity__r.Schluesseltresor_BP1__c,
                                Opportunity__r.Schluesseltresor_BP2__c,
                                Opportunity__r.Bezugsperson_3__c,
                                Opportunity__r.Bezugsperson_4__c,
                                Opportunity__r.Code_des_Schl_sseltresors_BP3__c,
                                Opportunity__r.Code_des_Schl_sseltresors_BP4__c,
                                Opportunity__r.Entfernung_zum_Nutzer_BP3__c,
                                Opportunity__r.Entfernung_zum_Nutzer_BP4__c,
                                Opportunity__r.Hausschl_ssel_BP3__c,
                                Opportunity__r.Hausschl_ssel_BP4__c,
                                Opportunity__r.Montageort_des_Tresors_BP3__c,
                                Opportunity__r.Montageort_des_Tresors_BP4__c,
                                Opportunity__r.Schl_sseltresor_BP3__c,
                                Opportunity__r.Schl_sseltresor_BP4__c,
                                Opportunity__r.Kontoinhaber__c,
                                Opportunity__r.Kreditinstitut__c,
                                Opportunity__r.IBAN__c,
                                Opportunity__r.BIC__c
                                from Partner_Ticket__c 
                                where id =: pt_id limit 1];
        try{
            Id aspContactId, pbContactId, sameContactId;
            Contact aspContact, pbContact, sameContact, bp1Contact, bp2Contact, bp3Contact, bp4Contact;
            List<OpportunityContactRole> role_list = [SELECT ContactId, Role from OpportunityContactRole where OpportunityId =: pt.opportunity__c ];
            for(OpportunityContactRole cr : role_list){
                if(cr.Role == PLZTool_Basis.contactRoleInsured){
                    pbContactId = cr.ContactId;                    
                }               
                if(cr.Role == PLZTool_Basis.contactRoleContact){
                    aspContactId = cr.ContactId;
                } 
                if(cr.Role == PLZTool_Basis.contactRoleSame){
                    pbContactId = cr.ContactId; 
                    aspContactId = cr.ContactId;
                    sameContactId = cr.ContactId;
                }
            }
            Set<Id> contactIds = new Set<Id>();
            if(pbContactId != null){
                contactIds.add(pbContactId);
            }
            if(aspContactId != null){
                contactIds.add(aspContactId);
            }
            if(sameContactId != null){
                contactIds.add(sameContactId);
            }
            if(pt.Opportunity__r.Bezugsperson_1__c != null){
                contactIds.add(pt.Opportunity__r.Bezugsperson_1__c);
            }
            if(pt.Opportunity__r.Bezugsperson_2__c != null){
                contactIds.add(pt.Opportunity__r.Bezugsperson_2__c);
            }
            if(pt.Opportunity__r.Bezugsperson_3__c != null){
                contactIds.add(pt.Opportunity__r.Bezugsperson_3__c);
            }
            if(pt.Opportunity__r.Bezugsperson_4__c != null){
                contactIds.add(pt.Opportunity__r.Bezugsperson_4__c);
            }
            
            List<Contact> ContactList = [select id, 
                                         AccountId, 
                                         birthDate, 
                                         Salutation, 
                                         FirstName, 
                                         lastName, 
                                         House_Number__c, 
                                         Street_Name__c, 
                                         MailingStreet, 
                                         MailingCity, 
                                         MailingPostalCode, 
                                         MailingCountry, 
                                         phone, 
                                         MobilePhone, 
                                         Email, 
                                         Fax, 
                                         RecordTypeId,
                                         Familien_Zugeh_rigkeit__c,
                                         Kreditinstitut__c,
                                         IBAN__c,
                                         BIC__c,
                                         Bekannte_Krankheiten__c,
                                         Sonstige_Krankheiten__c,
                                         Medikamente__c,
                                         sonstige_Medikamente__c,
                                         Name_Hausarzt__c,
                                         Telefonnummer_Hausarzt__c
                                         from contact 
                                         where Id IN :contactIds ];
            
            
            for(Contact c : ContactList){
                if(pbContactId != null && pbContactId == c.Id ){
                    pbContact = c;
                }
                if(aspContactId != null && aspContactId == c.Id ){
                    aspContact = c;
                }
                if(sameContactId != null && sameContactId == c.Id ){
                    sameContact = c;
                }
                if(pt.Opportunity__r.Bezugsperson_1__c != null && pt.Opportunity__r.Bezugsperson_1__c == c.Id){
                    bp1Contact = c;
                }
                if(pt.Opportunity__r.Bezugsperson_2__c != null && pt.Opportunity__r.Bezugsperson_2__c == c.Id){
                    bp2Contact = c;
                }
                if(pt.Opportunity__r.Bezugsperson_3__c != null && pt.Opportunity__r.Bezugsperson_3__c == c.Id){
                    bp3Contact = c;
                }
                if(pt.Opportunity__r.Bezugsperson_3__c != null && pt.Opportunity__r.Bezugsperson_4__c == c.Id){
                    bp4Contact = c;
                }
            }
            
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse();
            Http http = new Http();  
            
            String jsonBody = '{'; 
            jsonBody += '\"CC_Name\":\"CC_pflege\",'; 
            jsonBody += '\"ID_Lead\":\"'+ pt.Name + '\",';
            jsonBody += '\"Lead_Status\":\"'+ pt.Opportunity__r.Auftragsstatus__c + '\",';
            jsonBody += '\"CC_Abschluss durch\":\"\",';
            jsonBody += '\"CC_Agent_ID\":\"'+ pt.createdbyId + '\",';
            jsonBody += '\"Lead_Zeitpunkt_Gen\":\"' + pt.createdDate + '\",'; 
            jsonBody += '\"CC_Abschluss Datum\":\"' + pt.createdDate + '\",'; 
            jsonBody += '\"CC_Kontaktzeitpunkt\":\"' + pt.createdDate + '\",'; 
            jsonBody += '\"Lead_Affiliatecode\":\"' + afilliateCode + '\",';
            jsonBody += '\"Besteller_ID\":\"\",';
            
            if(sameContact != null){
                jsonBody += '\"Besteller_Geb_Datum\":\"' + sameContact.birthDate + '\",'; 
                jsonBody += '\"Besteller_Anrede\":\"' + sameContact.Salutation + '\",';
                jsonBody += '\"Besteller_Name\":\"' + sameContact.lastName  + '\",';
                jsonBody += '\"Besteller_Vorname\":\"' + sameContact.FirstName + '\",';
                jsonBody += '\"Besteller_street\":\"' + sameContact.Street_Name__c + '\",';
                jsonBody += '\"Besteller_street_number\":\"' + sameContact.House_Number__c + '\",';
                jsonBody += '\"Besteller_Adresszusatz\":\"\",';
                jsonBody += '\"Besteller_PLZ\":\"' + sameContact.MailingPostalCode + '\",';
                jsonBody += '\"Besteller_Ort\":\"' + sameContact.MailingCity + '\",';
                jsonBody += '\"Besteller_Land\":\"' + sameContact.MailingCountry + '\",';
                jsonBody += '\"Besteller_Telefon\":\"' + sameContact.phone + '\",';
                jsonBody += '\"Besteller_Mobil\":\"' + sameContact.MobilePhone + '\",';
                jsonBody += '\"Besteller_Email\":\"' + sameContact.Email + '\",';
            }
            else if(aspContact!= null){
                jsonBody += '\"Besteller_Geb_Datum\":\"' + aspContact.birthDate + '\",'; 
                jsonBody += '\"Besteller_Anrede\":\"' + aspContact.Salutation + '\",';
                jsonBody += '\"Besteller_Name\":\"' + aspContact.lastName  + '\",';
                jsonBody += '\"Besteller_Vorname\":\"' + aspContact.FirstName + '\",';
                jsonBody += '\"Besteller_street\":\"' + aspContact.Street_Name__c + '\",';
                jsonBody += '\"Besteller_street_number\":\"' + aspContact.House_Number__c + '\",';
                jsonBody += '\"Besteller_Adresszusatz\":\"\",';
                jsonBody += '\"Besteller_PLZ\":\"' + aspContact.MailingPostalCode + '\",';
                jsonBody += '\"Besteller_Ort\":\"' + aspContact.MailingCity + '\",';
                jsonBody += '\"Besteller_Land\":\"' + aspContact.MailingCountry + '\",';
                jsonBody += '\"Besteller_Telefon\":\"' + aspContact.phone + '\",';
                jsonBody += '\"Besteller_Mobil\":\"' + aspContact.MobilePhone + '\",';
                jsonBody += '\"Besteller_Email\":\"' + aspContact.Email + '\",';
            }
            else{
                jsonBody += '\"Besteller_Geb_Datum\":\"\",';
                jsonBody += '\"Besteller_Anrede\":\"\",';
                jsonBody += '\"Besteller_Name\":\"\",';
                jsonBody += '\"Besteller_Vorname\":\"\",';
                jsonBody += '\"Besteller_street\":\"\",';
                jsonBody += '\"Besteller_street_number\":\"\",';
                jsonBody += '\"Besteller_Adresszusatz\":\"\",';
                jsonBody += '\"Besteller_PLZ\":\"\",';
                jsonBody += '\"Besteller_Ort\":\"\",';
                jsonBody += '\"Besteller_Land\":\"\",';
                jsonBody += '\"Besteller_Telefon\":\"\",';
                jsonBody += '\"Besteller_Mobil\":\"\",';
                jsonBody += '\"Besteller_Email\":\"\",';
            }
            if(aspContact != null){
                jsonBody += '\"Besteller_Verhaeltnis_Nutzer\":\"' + aspContact.Familien_Zugeh_rigkeit__c + '\",';
            }
            jsonBody += '\"Libify_Arktikel_Nr\":\"' + pt.Partner_Produkt__r.Libify_Artikelnummer__c + '\",';
            jsonBody += '\"Libify_Zubehoer\":\"' + pt.Opportunity__r.Libify_Zubehoer__c + '\",';
            
            if(pbContact != null){
                jsonBody += '\"Nutzer_Anrede\":\"' + pbContact.Salutation + '\",'; 
                jsonBody += '\"Nutzer_Name\":\"' + pbContact.lastName + '\",'; 
                jsonBody += '\"Nutzer_Vorname\":\"' + pbContact.FirstName + '\",'; 
                jsonBody += '\"Nutzer_Straße\":\"' + pbContact.Street_Name__c + '\",'; 
                jsonBody += '\"Nutzer_Hausnummer\":\"' + pbContact.House_Number__c + '\",'; 
                jsonBody += '\"Nutzer_Adresszusatz\":\"\",';
                jsonBody += '\"Nutzer_PLZ\":\"' + pbContact.MailingPostalCode + '\",'; 
                jsonBody += '\"Nutzer_Ort\":\"' + pbContact.MailingCity + '\",'; 
                jsonBody += '\"Nutzer_Land\":\"' + pbContact.MailingCountry + '\",'; 
                jsonBody += '\"Nutzer_Tel\":\"' + pbContact.phone + '\",'; 
                jsonBody += '\"Nutzer_Email\":\"' + pbContact.Email + '\",'; 
                jsonBody += '\"Nutzer_Mobil\":\"' + pbContact.MobilePhone + '\",';
                jsonBody += '\"Nutzer_Geb_Datum\":\"' + pbContact.birthDate + '\",';
            }
            else{
                jsonBody += '\"Nutzer_Anrede\":\"\",';
                jsonBody += '\"Nutzer_Name\":\"\",';
                jsonBody += '\"Nutzer_Vorname\":\"\",';
                jsonBody += '\"Nutzer_Straße\":\"\",';
                jsonBody += '\"Nutzer_Hausnummer\":\"\",';
                jsonBody += '\"Nutzer_Adresszusatz\":\"\",';
                jsonBody += '\"Nutzer_PLZ\":\"\",';
                jsonBody += '\"Nutzer_Ort\":\"\",';
                jsonBody += '\"Nutzer_Land\":\"\",';
                jsonBody += '\"Nutzer_Tel\":\"\",';
                jsonBody += '\"Nutzer_Email\":\"\",';
                jsonBody += '\"Nutzer_Mobil\":\"\",';
                jsonBody += '\"Nutzer_Geb_Datum\":\"\",';
            }        
            
            jsonBody += '\"Versand_Datum_soll\":\"' + pt.Opportunity__r.Versandtdatum__c + '\",';
            
            if(!String.isEmpty(pt.Opportunity__r.Versandadresse_Name__c) || !String.isEmpty(pt.Opportunity__r.Versandadresse_Stra_e__c)){
                jsonBody += '\"Versand_Anrede\":\"' + pt.Opportunity__r.Versandadresse_Anrede__c + '\",'; 
                jsonBody += '\"Versand_Name\":\"' + pt.Opportunity__r.Versandadresse_Name__c + '\",';
                jsonBody += '\"Versand_Vorname\":\"' + pt.Opportunity__r.Versandadresse_Vorname__c + '\",';
                jsonBody += '\"Versand_Strasse\":\"' + pt.Opportunity__r.Versandadresse_Stra_e__c + '\",';
                jsonBody += '\"Versand_Hausnummer\":\"\",';
                jsonBody += '\"Versand_Adresszusatz\":\"\",';
                jsonBody += '\"Versand_PLZ\":\"' + pt.Opportunity__r.Versandadresse_PLZ__c + '\",';
                jsonBody += '\"Versand_Ort\":\"' + pt.Opportunity__r.Versandadresse_Ort__c + '\",';
                jsonBody += '\"Versand_Land\":\"\",';
                jsonBody += '\"Versand_Bemerkung\":\"\",';
                jsonBody += '\"Versand_Tel\":\"\",';
                jsonBody += '\"Versand_mobil\":\"\",';
                jsonBody += '\"Versand_Email\":\"\",';
            }
            else if(aspContact != null){
                jsonBody += '\"Versand_Anrede\":\"' + aspContact.Salutation + '\",';
                jsonBody += '\"Versand_Name\":\"' + aspContact.lastName  + '\",';
                jsonBody += '\"Versand_Vorname\":\"' + aspContact.FirstName + '\",';
                jsonBody += '\"Versand_Strasse\":\"' + aspContact.Street_Name__c + '\",';
                jsonBody += '\"Versand_Hausnummer\":\"' + aspContact.House_Number__c + '\",';
                jsonBody += '\"Versand_Adresszusatz\":\"\",';
                jsonBody += '\"Versand_PLZ\":\"' + aspContact.MailingPostalCode + '\",';
                jsonBody += '\"Versand_Ort\":\"' + aspContact.MailingCity + '\",';
                jsonBody += '\"Versand_Land\":\"' + aspContact.MailingCountry + '\",';
                jsonBody += '\"Versand_Bemerkung\":\"\",';
                jsonBody += '\"Versand_Tel\":\"' + aspContact.phone + '\",';
                jsonBody += '\"Versand_mobil\":\"' + aspContact.MobilePhone + '\",';
                jsonBody += '\"Versand_Email\":\"' + aspContact.Email + '\",';
            }
            else{
                jsonBody += '\"Versand_Anrede\":\"\",';
                jsonBody += '\"Versand_Name\":\"\",';
                jsonBody += '\"Versand_Vorname\":\"\",';
                jsonBody += '\"Versand_Strasse\":\"\",';
                jsonBody += '\"Versand_Hausnummer\":\"\",';
                jsonBody += '\"Versand_Adresszusatz\":\"\",';
                jsonBody += '\"Versand_PLZ\":\"\",';
                jsonBody += '\"Versand_Ort\":\"\",';
                jsonBody += '\"Versand_Land\":\"\",';
                jsonBody += '\"Versand_Bemerkung\":\"\",';
                jsonBody += '\"Versand_Tel\":\"\",';
                jsonBody += '\"Versand_mobil\":\"\",';
                jsonBody += '\"Versand_Email\":\"\",';
            }
            
            if(!String.isEmpty(pt.Opportunity__r.IBAN__c) && !String.isEmpty(pt.Opportunity__r.Kontoinhaber__c)){
                jsonBody += '\"Lead_Kontoinhaber\":\"' + pt.Opportunity__r.Kontoinhaber__c  + '\",';
                jsonBody += '\"Lead_IBAN\":\"' + pt.Opportunity__r.IBAN__c + '\",';
                jsonBody += '\"Lead_BIC\":\"' + pt.Opportunity__r.BIC__c + '\",';
                jsonBody += '\"Lead_Bank\":\"' + pt.Opportunity__r.Kreditinstitut__c + '\",';
            }
            else{
                if(aspContact != null){
                    jsonBody += '\"Lead_Kontoinhaber\":\"' + aspContact.FirstName + ' ' + aspContact.lastName  + '\",';
                    jsonBody += '\"Lead_IBAN\":\"' + aspContact.IBAN__c + '\",';
                    jsonBody += '\"Lead_BIC\":\"' + aspContact.BIC__c + '\",';
                    jsonBody += '\"Lead_Bank\":\"' + aspContact.Kreditinstitut__c + '\",';
                }
                else{
                    jsonBody += '\"Lead_Kontoinhaber\":\"\",';
                    jsonBody += '\"Lead_IBAN\":\"\",';
                    jsonBody += '\"Lead_BIC\":\"\",';
                    jsonBody += '\"Lead_Bank\":\"\",';
                }
            }
            
            
            
            jsonBody += '\"CC_Bemerkungen\":\"' + pt.Opportunity__r.description + '\",';
            jsonBody += '\"Nutzer_Notfallplan_min\":\"JA\",';
            
            if(pbContact != null && !String.isEmpty(pbContact.Bekannte_Krankheiten__c) ){
                if(pbContact.Bekannte_Krankheiten__c.contains('Herzerkrankungen') || pbContact.Bekannte_Krankheiten__c.contains('Herzinfakt') || pbContact.Bekannte_Krankheiten__c.contains('KHK coronare') ){
                    jsonBody += '\"Nutzer_Herzerkrankungen\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Herzerkrankungen\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('Bluthochdruck') || pbContact.Bekannte_Krankheiten__c.contains('Hypotonie') ){
                    jsonBody += '\"Nutzer_Blutdruckprobleme\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Blutdruckprobleme\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('COPD') || pbContact.Bekannte_Krankheiten__c.contains('Asthma') || pbContact.Bekannte_Krankheiten__c.contains('Bronchitis / Lungenerkrankungen') ){
                    jsonBody += '\"Nutzer_Lunge_Atemwegserkrankung\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Lunge_Atemwegserkrankung\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('Stoffwechselerkrankungen') || pbContact.Bekannte_Krankheiten__c.contains('Diabetes') ){
                    jsonBody += '\"Nutzer_Diabetes\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Diabetes\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('Epilepsie') || pbContact.Bekannte_Krankheiten__c.contains('Alzheimer') || pbContact.Bekannte_Krankheiten__c.contains('Demenz') || pbContact.Bekannte_Krankheiten__c.contains('MS') || pbContact.Bekannte_Krankheiten__c.contains('Parkinson') ){
                    jsonBody += '\"Nutzer_Neurolog_Erkrankungen\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Neurolog_Erkrankungen\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('Herzschrittmacher') ){
                    jsonBody += '\"Nutzer_Herzschrittmacher\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Herzschrittmacher\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('Schlaganfall') ){
                    jsonBody += '\"Nutzer_Schlaganfall\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Schlaganfall\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('Schwerhörigkeit') ){
                    jsonBody += '\"Nutzer_Hoert_schlecht\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Hoert_schlecht\":\"\",';
                }
                
                if(pbContact.Bekannte_Krankheiten__c.contains('Augenleiden') ){
                    jsonBody += '\"Nutzer_Sieht_schlecht\":\"TRUE\",';
                }
                else{
                    jsonBody += '\"Nutzer_Sieht_schlecht\":\"\",';
                }
            }
            else{
                jsonBody += '\"Nutzer_Herzerkrankungen\":\"\",';
                jsonBody += '\"Nutzer_Blutdruckprobleme\":\"\",';
                jsonBody += '\"Nutzer_Lunge_Atemwegserkrankung\":\"\",';
                jsonBody += '\"Nutzer_Diabetes\":\"\",';
                jsonBody += '\"Nutzer_Neurolog_Erkrankungen\":\"\",';
                jsonBody += '\"Nutzer_Herzschrittmacher\":\"\",';
                jsonBody += '\"Nutzer_Schlaganfall\":\"\",';
                jsonBody += '\"Nutzer_Hoert_schlecht\":\"\",';
                jsonBody += '\"Nutzer_Sieht_schlecht\":\"\",';
            }
            
            if(pbContact != null){
                jsonBody += '\"Nutzer_Sonstige_Erkrankungen\":\"' + pbContact.Sonstige_Krankheiten__c + '\",';
                jsonBody += '\"Nutzer_Vorerkrankung\":\"' + pbContact.Sonstige_Krankheiten__c + '\",';
                
                if(pbContact.Medikamente__c != null){
                    if(pbContact.Medikamente__c.contains('Insulin') ){
                        jsonBody += '\"Nutzer_Insulin\":\"TRUE\",';
                    }
                    else{
                        jsonBody += '\"Nutzer_Insulin\":\"\",';
                    }
                    
                    if(pbContact.Medikamente__c.contains('Marcumar') || pbContact.Medikamente__c.contains('ASS') ){
                        jsonBody += '\"Nutzer_Blutverduennende_Medikamente\":\"TRUE\",';
                    }
                    else{
                        jsonBody += '\"Nutzer_Blutverduennende_Medikamente\":\"\",';
                    }
                    
                    if(pbContact.Medikamente__c.contains('Blutdruckmedikamente') ){
                        jsonBody += '\"Nutzer_Blutdruckmedikamente\":\"TRUE\",';
                    }
                    else{
                        jsonBody += '\"Nutzer_Blutdruckmedikamente\":\"\",';
                    }
                    
                    if(pbContact.Medikamente__c.contains('Epilepsie Mekidamente') ){
                        jsonBody += '\"Nutzer_Neuroleptika\":\"TRUE\",';
                    }
                    else{
                        jsonBody += '\"Nutzer_Neuroleptika\":\"\",';
                    }
                }
                else{
                    jsonBody += '\"Nutzer_Insulin\":\"\",';
                    jsonBody += '\"Nutzer_Blutverduennende_Medikamente\":\"\",';
                    jsonBody += '\"Nutzer_Blutdruckmedikamente\":\"\",';
                    jsonBody += '\"Nutzer_Neuroleptika\":\"\",';
                }
                
                jsonBody += '\"Nutzer_Sonstige_Medikamente\":\"' + pbContact.sonstige_Medikamente__c + '\",';
                jsonBody += '\"Nutzer_Hausarzt\":\"' + pbContact.Name_Hausarzt__c + '\",';
                jsonBody += '\"Nutzer_Tel_Hausarzt\":\"' + pbContact.Telefonnummer_Hausarzt__c + '\",';
            }
            else{
                jsonBody += '\"Nutzer_Sonstige_Erkrankungen\":\"\",';
                jsonBody += '\"Nutzer_Vorerkrankung\":\"\",';
                jsonBody += '\"Nutzer_Insulin\":\"\",';
                jsonBody += '\"Nutzer_Blutverduennende_Medikamente\":\"\",';
                jsonBody += '\"Nutzer_Blutdruckmedikamente\":\"\",';
                jsonBody += '\"Nutzer_Neuroleptika\":\"\",';
                jsonBody += '\"Nutzer_Sonstige_Medikamente\":\"\",';
                jsonBody += '\"Nutzer_Hausarzt\":\"\",';
                jsonBody += '\"Nutzer_Tel_Hausarzt\":\"\",';
            }
            
            if(bp1Contact != null){
                jsonBody += '\"Nutzer_BP_1_Vorname\":\"' + bp1Contact.firstName  + '\",';
                jsonBody += '\"Nutzer_BP_1_Name\":\"' + bp1Contact.lastName + '\",';
                jsonBody += '\"Nutzer_BP_1_Tel_Nr\":\"' + bp1Contact.phone + '\",';
                jsonBody += '\"Nutzer_BP_1_Bezug_Nutzer\":\"' + bp1Contact.Familien_Zugeh_rigkeit__c + '\",';
            }
            else{
                jsonBody += '\"Nutzer_BP_1_Vorname\":\"\",';
                jsonBody += '\"Nutzer_BP_1_Name\":\"\",';
                jsonBody += '\"Nutzer_BP_1_Tel_Nr\":\"\",';
                jsonBody += '\"Nutzer_BP_1_Bezug_Nutzer\":\"\",';
            }
            
            if(bp2Contact != null){
                jsonBody += '\"Nutzer_BP_2_Vorname\":\"' + bp2Contact.firstName  + '\",';
                jsonBody += '\"Nutzer_BP_2_Name\":\"' + bp2Contact.lastName + '\",';
                jsonBody += '\"Nutzer_BP_2_Tel_Nr\":\"' + bp2Contact.phone + '\",';
                jsonBody += '\"Nutzer_BP_2_Bezug_Nutzer\":\"' + bp2Contact.Familien_Zugeh_rigkeit__c + '\",';
            }
            else{
                jsonBody += '\"Nutzer_BP_2_Vorname\":\"\",';
                jsonBody += '\"Nutzer_BP_2_Name\":\"\",';
                jsonBody += '\"Nutzer_BP_2_Tel_Nr\":\"\",';
                jsonBody += '\"Nutzer_BP_2_Bezug_Nutzer\":\"\",';
            }
            
            if(bp3Contact != null){
                jsonBody += '\"Nutzer_BP_3_Vorname\":\"' + bp3Contact.firstName  + '\",';
                jsonBody += '\"Nutzer_BP_3_Name\":\"' + bp3Contact.lastName + '\",';
                jsonBody += '\"Nutzer_BP_3_Tel_Nr\":\"' + bp3Contact.phone + '\",';
                jsonBody += '\"Nutzer_BP_3_Bezug_Nutzer\":\"' + bp3Contact.Familien_Zugeh_rigkeit__c + '\",';
            }
            else{
                jsonBody += '\"Nutzer_BP_3_Vorname\":\"\",';
                jsonBody += '\"Nutzer_BP_3_Name\":\"\",';
                jsonBody += '\"Nutzer_BP_3_Tel_Nr\":\"\",';
                jsonBody += '\"Nutzer_BP_3_Bezug_Nutzer\":\"\",';
            }
            
            if(bp4Contact != null){
                jsonBody += '\"Nutzer_BP_4_Vorname\":\"' + bp4Contact.firstName  + '\",';
                jsonBody += '\"Nutzer_BP_4_Name\":\"' + bp4Contact.lastName + '\",';
                jsonBody += '\"Nutzer_BP_4_Tel_Nr\":\"' + bp4Contact.phone + '\",';
                jsonBody += '\"Nutzer_BP_4_Bezug_Nutzer\":\"' + bp4Contact.Familien_Zugeh_rigkeit__c + '\",';
            }
            else{
                jsonBody += '\"Nutzer_BP_4_Vorname\":\"\",';
                jsonBody += '\"Nutzer_BP_4_Name\":\"\",';
                jsonBody += '\"Nutzer_BP_4_Tel_Nr\":\"\",';
                jsonBody += '\"Nutzer_BP_4_Bezug_Nutzer\":\"\",';
            }
            
            jsonBody += '\"Nutzer_BP_1_Schluessel\":\"' + pt.Opportunity__r.Hausschluessel_BP1__c + '\",';
            jsonBody += '\"Nutzer_BP_1_Entfernung_Nutzer\":\"' + pt.Opportunity__r.Entfernung_zum_Nutzer_BP1__c + '\",';
            jsonBody += '\"Nutzer_BP_1_Schluesseltresor\":\"' + pt.Opportunity__r.Schluesseltresor_BP1__c + '\",';
            jsonBody += '\"Nutzer_BP_1_Schluesseltresor_Code\":\"' + pt.Opportunity__r.Code_des_Schl_sseltresors_BP1__c   + '\",';
            jsonBody += '\"Nutzer_BP_1_Schluesseltrsesor_Standort\":\"' + pt.Opportunity__r.Montageort_des_Tresors_BP1__c  + '\",';
            
            jsonBody += '\"Nutzer_BP_2_Schluessel\":\"' + pt.Opportunity__r.Hausschl_ssel_BP2__c + '\",';
            jsonBody += '\"Nutzer_BP_2_Entfernung_Nutzer\":\"' + pt.Opportunity__r.Entfernung_zum_Nutzer_BP2__c + '\",';
            jsonBody += '\"Nutzer_BP_2_Schluesseltresor\":\"' + pt.Opportunity__r.Code_des_Schluesseltresors_BP2__c + '\",';
            jsonBody += '\"Nutzer_BP_2_Schluesseltresor_Code\":\"' + pt.Opportunity__r.Schluesseltresor_BP2__c + '\",';
            jsonBody += '\"Nutzer_BP_2_Schluesseltrsesor_Standort\":\"' + pt.Opportunity__r.Montageort_des_Tresors_BP2__c + '\",';
            
            jsonBody += '\"Nutzer_BP_3_Schluessel\":\"' + pt.Opportunity__r.Hausschl_ssel_BP3__c + '\",';
            jsonBody += '\"Nutzer_BP_3_Entfernung_Nutzer\":\"' + pt.Opportunity__r.Entfernung_zum_Nutzer_BP3__c + '\",';
            jsonBody += '\"Nutzer_BP_3_Schluesseltresor\":\"' + pt.Opportunity__r.Code_des_Schl_sseltresors_BP3__c + '\",';
            jsonBody += '\"Nutzer_BP_3_Schluesseltresor_Code\":\"' + pt.Opportunity__r.Schl_sseltresor_BP3__c + '\",';
            jsonBody += '\"Nutzer_BP_3_Schluesseltrsesor_Standort\":\"' + pt.Opportunity__r.Montageort_des_Tresors_BP3__c + '\",';
            
            jsonBody += '\"Nutzer_BP_4_Schluessel\":\"' + pt.Opportunity__r.Hausschl_ssel_BP4__c + '\",';
            jsonBody += '\"Nutzer_BP_4_Entfernung_Nutzer\":\"' + pt.Opportunity__r.Entfernung_zum_Nutzer_BP4__c + '\",';
            jsonBody += '\"Nutzer_BP_4_Schluesseltresor\":\"' + pt.Opportunity__r.Code_des_Schl_sseltresors_BP4__c + '\",';
            jsonBody += '\"Nutzer_BP_4_Schluesseltresor_Code\":\"' + pt.Opportunity__r.Schl_sseltresor_BP4__c + '\",';
            jsonBody += '\"Nutzer_BP_4_Schluesseltrsesor_Standort\":\"' + pt.Opportunity__r.Montageort_des_Tresors_BP4__c + '\",';
            
            jsonBody += '\"Self_Mailing\":\"NEIN\"';
            jsonBody += '} ';
            
            System.debug('################ Input Request:' + jsonBody);
            
            String endpoint = LibifyEndPointDirekt;
            LibifyEndpoint__c ep = LibifyEndpoint__c.getValues('Default');
            if(ep != null && !String.isEmpty(ep.endpoint_direkt__c)){
                endpoint = ep.endpoint_direkt__c;
            }
            
            req.setEndpoint(endpoint);
            req.setMethod('POST');
            
            req.setCompressed(false);
            req.setBody(jsonBody);
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setHeader('Content-Length', String.valueOf(jsonBody.length()));
            
            try {
                res = http.send(req);
                System.debug('########## res=' + res.toString());
                System.debug('########## STATUS:' + res.getStatus());
                System.debug('########## STATUS_CODE:' + res.getStatusCode());
                
                String responseXML = res.getBody();
                System.debug('responseXML:' + responseXML);
                
                // insert a record in object Libify_Response__c
                saveRequest(pt_id, req.getBody(), res.toString());
                
                // send email to pflege.de in case of error
                if(res.getStatusCode() != 200 ){
                    sendEmailToTeamLead(pt_id, pt.Name, '\n failed to send ticket \''+ pt.Name +'\' to Libify. \n response:\n' + res.toString() + '\n response body:\n' + res.getBody() );
                }
            }
            catch(System.CalloutException e) {
                error = true;
                System.debug('############ Callout error: ' + e);
                
                // insert a record in object Libify_Response__c in case of error
                saveRequest(pt_id, req.getBody(), res.toString() + '\n exception occured:\n Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage() );
                
                // send email to pflege.de
                sendEmailToTeamLead(pt_id, pt.Name, '\n failed to send ticket \''+ pt.Name +'\' to Libify. \n response:\n' + res.toString() + '\n response body:\n' + res.getBody() + '\n exception occured:\n' + ' Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage());
            }
            
        }catch(exception e){
            error = true;
            saveRequest(pt_id, '', 'exception occured:\n Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage() );
            sendEmailToTeamLead(pt_id, pt.Name, '\n failed to send ticket \''+ pt.Name +'\' to Libify. \n exception occured:\n' + ' Line: '+e.getLineNumber() + ' Type: ' + e.getTypeName() + ' Message: ' + e.getMessage());
        }
        
        return error;
    }
    
    /*
* 159923232 >> for every request that is sent to Libify a new record should be created to save the response
* */
    private static void saveRequest(Id ticketId, String request, String response){
        try{
            Libify_Response__c lbfyRecord = new Libify_Response__c();
            lbfyRecord.Partner_Ticket_Id__c = ticketId;
            lbfyRecord.Request__c = request;
            lbfyRecord.Response__c = response;
            
            insert lbfyRecord;
        }catch(Exception e){
            System.debug('############ insert error: ' + e);
        }
        
    }
    
    /*
* 159923232 >> email should be sent in case of failiure
* */
    public static void sendEmailToTeamLead(Id ticketId, String ticketName, String textBody) 
    {   
        String mailtoPflege = 'dennis.zietkoff@pflege.de';
        String mailtoPflege2 = 'dennis.zietkoff@pflege.de';
        String subject = 'Libify - failed to send ticket ' + ticketName + ' ' + DateTime.now().format();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(textBody);
        mail.setPlainTextBody(textBody);
        mail.setSubject(subject);
        mail.setToAddresses(new String[] {mailtoPflege, mailtoPflege2});
        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail} );    
    }
    
    public static String createHeader(String userName, String key){
        String token = key;
        String chars = '0123456789abcdef';
        String nonce = '';
        String dt = System.now()+'Z';
        
        while (nonce.length() < 32) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            nonce += chars.substring(idx, idx+1);
        }
        
        String nonce64 = EncodingUtil.base64Encode(Blob.valueOf(nonce));
        
        Blob target = Blob.valueOf(nonce+dt+token); 
        Blob digestSha1 = Crypto.generateDigest('SHA1',target);
        String digest = EncodingUtil.base64Encode(digestSha1);
        
        String header = 'X-WSSE:UsernameToken Username="'+userName+'",PasswordDigest="'+digest+'",Nonce="'+nonce64+'",Created="'+dt+'"';       
        return header;
    }  
    
    public static String getEndpoint() {
        try {
            if(isSandbox() == true) {
                return Libify_Access_Data__c.getValues('Sandbox').Endpoint__c;
            }
            else {
                return Libify_Access_Data__c.getValues('Produktion').Endpoint__c;
            }
        }
        catch(System.Exception e) {
            return LibifyEndpoint;
        }
    }
    
    public static String getUsername() {
        try {
            if(isSandbox() == true) {
                return Libify_Access_Data__c.getValues('Sandbox').Username__c;
            }
            else {
                return Libify_Access_Data__c.getValues('Produktion').Username__c;
            }
        }
        catch(System.Exception e) {
            return LibifyUsername;
        }
    }
    
    public static String getToken() {
        try {
            if(isSandbox() == true) {
                return Libify_Access_Data__c.getValues('Sandbox').Token__c;
            }
            else {
                return Libify_Access_Data__c.getValues('Produktion').Token__c;
            }
        }
        catch(System.Exception e) {
            return LibifyToken;
        }
    }
    
    public static Boolean isSandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}