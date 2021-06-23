/********************************************************************************************************************************************
// Created on 17.07.2020 von BT
//                         Klose und Srocke Gesellschaft f?r kreative Konfliktl?sungen mbH
//                         Frankenstra?e. 29
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
//  Parameter:
//
//********************************************************************************************************************************************
//
//  Description:             
//                  Create and send a new request to Promedica
//********************************************************************************************************************************************
//  Changes:
//  21.07.2020  BT  set timeout limit to 120 secondes
//  23.07.2020  BT  set user informations and date in request body
//  28.07.2020  BT  added new parameter sourceIdOP
//  24.08.2020  BT  formatted mobile and phone number, added new row in request body
//********************************************************************************************************************************************
*/
public class PromedicaRequest {
    private static Contact con {get; set;}
    private static Opportunity opp {get; set;}    
    private static String currentUserFirstName {get; set;}
    private static String currentUserLastName {get; set;}
    private static String envelopeNS = 'http://schemas.xmlsoap.org/soap/envelope/';
    private static String createContactNS = 'http://www.intersys.pl/';
    private static String apiKey = '4DEB05A1-1612-4C7A-83F1-754DE77F9999';
    private static String leadType = '717700001';
    private static String targetCountry = '717700000';
    private static String fpCode = '';
    private static String source = 'www.pflege.de';
    private static String sourceIdKlient = '0f696795-a798-e911-80d1-00155d140163';
    private static String sourceIdOP = '01707F1C-A1A7-E811-80CA-00155D13F31A';
    private static String knowledgeOfLanguage = '717700000';
    private static String consent_id = '4d942bc9-aaa1-ea11-80d8-00155d2d0c70';
    private static String endpoint = 'https://leadapi.promedica24.pl/Endpoints/ContactEndpoint.asmx';
    private static String inputChannelId = '0F696795-A798-E911-80D1-00155D140163';    
    
    public PromedicaRequest() {}
    
    @future(callout=true)
    public static void sendRequest(Id opportunityId, Id contactId, String userFirstName, String userLastName){
       con = [SELECT FirstName, LastName, Email, Phone, MobilePhone, MailingStreet, MailingCity
                       FROM Contact
                       WHERE Id = :contactId];
        
       opp = [SELECT deutschkenntnisse_der_betreuungskraft__c, geschlecht_der_betreuungskraft__c,
                           zeitpunkt_der_versorgung__c, Alternative_Postleitzahl__c, anmerkungen_f_r_den_partner__c,
                           Promedica_Request__c, Promedica_Response__c
                           FROM Opportunity
                           WHERE Id = :opportunityId];  
        
        currentUserFirstName = userFirstName;
        currentUserLastName = userLastName;
        setPromedicaSettings();        
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type', 'text/xml;charset=UTF-8');        
        req.setMethod('POST');         
        req.setTimeout(120000);
        DOM.Document body = getSoapRequestBody();
        req.setBodyDocument(body);
        req.setEndpoint(endpoint);
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);  
            opp.Promedica_Response__c = res.getBody(); 
        }
        catch(System.Exception e)  {
            opp.Promedica_Response__c = e.getMessage(); 
        }                  
        opp.Promedica_Request__c = body.toXmlString();
        try {
            update opp;
        }
        catch(System.Exception e) {
            System.debug('PromedicaRequest Error: ' + e.getMessage());
        }
    }
        
    public static DOM.Document getSoapRequestBody(){
        DOM.Document requestBody = new DOM.Document();
        
        // envelope
        DOM.XmlNode envelope = requestBody.createRootElement('Envelope', envelopeNS, '');        
        
        // body
        DOM.XmlNode body = envelope.addChildElement('Body', null, null);
        
        // createContact
        DOM.XmlNode createContact = body.addChildElement('CreateContact', createContactNS, '');
        
        // request
        DOM.XmlNode request = createContact.addChildElement('request', null, null);
        
        // inApiKey
        DOM.XmlNode inApiKey = request.addChildElement('inApiKey', null, null);
        inApiKey.addTextNode(apiKey);
        
        // inLeadType
        DOM.XmlNode inLeadType = request.addChildElement('inLeadType', null, null);
        inLeadType.addTextNode(leadType);
        
        // inTargetCountry
        DOM.XmlNode inTargetCountry = request.addChildElement('inTargetCountry', null, null);
        inTargetCountry.addTextNode(targetCountry);
        
        // inFPCode
        DOM.XmlNode inFPCode = request.addChildElement('inFPCode', null, null);
        inFPCode.addTextNode(fpCode);
        
        // inName
        DOM.XmlNode inName = request.addChildElement('inName', null, null);
        if(!String.isBlank(con.FirstName)) {
            inName.addTextNode(con.FirstName);
        }
        else {
            inName.addTextNode('');
        }
        
        // inSurName
        DOM.XmlNode inSurName = request.addChildElement('inSurName', null, null);
        if(!String.isBlank(con.LastName)) {
            inSurName.addTextNode(con.LastName);
        }
        else {
            inSurName.addTextNode('');
        }
        
        // inCity_region
        DOM.XmlNode inCity_region = request.addChildElement('inCity_region', null, null);
        if(!String.isBlank(con.MailingCity)) {
            inCity_region.addTextNode(con.MailingCity);
        }
        else {
            inCity_region.addTextNode('');
        }        
        
        // inStreet
        DOM.XmlNode inStreet = request.addChildElement('inStreet', null, null);
        if(!String.isBlank(con.MailingStreet)) {
            inStreet.addTextNode(con.MailingStreet);
        }
        else {
            inStreet.addTextNode('');
        }
        
        // inEmail
        DOM.XmlNode inEmail = request.addChildElement('inEmail', null, null);
        if(!String.isBlank(con.Email)) {
            inEmail.addTextNode(con.Email);
        }
        else {
            inEmail.addTextNode('');
        }
        
        // inPostalCode_OP_FP_Klient
        DOM.XmlNode inPostalCode_OP_FP_Klient = request.addChildElement('inPostalCode_OP_FP_Klient', null, null);
        if(!String.isBlank(opp.Alternative_Postleitzahl__c)) {
            inPostalCode_OP_FP_Klient.addTextNode(opp.Alternative_Postleitzahl__c);
        }
        else {
            inPostalCode_OP_FP_Klient.addTextNode('');
        }
        
        // inPostalCode_Pacjent
        DOM.XmlNode inPostalCode_Pacjent = request.addChildElement('inPostalCode_Pacjent', null, null);
        if(!String.isBlank(opp.Alternative_Postleitzahl__c)){
            inPostalCode_Pacjent.addTextNode(opp.Alternative_Postleitzahl__c);
        }
        else {
            inPostalCode_Pacjent.addTextNode('');
        }
        
        // inSource
        DOM.XmlNode inSource = request.addChildElement('inSource', null, null);
        inSource.addTextNode(source);
        
        // inLeadexlusivePM24
        DOM.XmlNode inLeadexlusivePM24 = request.addChildElement('inLeadexlusivePM24', null, null);
        inLeadexlusivePM24.addTextNode('false');
        
        // inMarketingSourceId_Klient_FP
        DOM.XmlNode inMarketingSourceId_Klient_FP = request.addChildElement('inMarketingSourceId_Klient_FP', null, null);
        inMarketingSourceId_Klient_FP.addTextNode(sourceIdKlient);
        
        // inMarketingSourceId_OP
        DOM.XmlNode inMarketingSourceId_OP = request.addChildElement('inMarketingSourceId_OP', null, null);
        inMarketingSourceId_OP.addTextNode(sourceIdOP);
        
        // inInterestedserviceDE
        DOM.XmlNode inInterestedserviceDE = request.addChildElement('inInterestedserviceDE', null, null);
        inInterestedserviceDE.addTextNode('true');
        
        // inInterestedserviceGB
        DOM.XmlNode inInterestedserviceGB = request.addChildElement('inInterestedserviceGB', null, null);
        inInterestedserviceGB.addTextNode('false');
        
        // inInterestedservicePL
        DOM.XmlNode inInterestedservicePL = request.addChildElement('inInterestedservicePL', null, null);
        inInterestedservicePL.addTextNode('false');
        
        // inknowledge_of_the_language_candidate
        DOM.XmlNode inknowledge_of_the_language_candidate = request.addChildElement('inknowledge_of_the_language_candidate', null, null);
        inknowledge_of_the_language_candidate.addTextNode(knowledgeOfLanguage);
        
        // consents
        DOM.XmlNode consents = request.addChildElement('Consents', null, null);
        
        // consentInfo
        DOM.XmlNode consentInfo = consents.addChildElement('ConsentInfo', null, null);
        
        // consentId
        DOM.XmlNode consentId = consentInfo.addChildElement('ConsentId', null, null);
        consentId.addTextNode(consent_id);
        
        // acceptance
        DOM.XmlNode acceptance = consentInfo.addChildElement('Acceptance', null, null);
        acceptance.addTextNode('true');
        
        // inTelephone
        DOM.XmlNode inTelephone = request.addChildElement('inTelephone', null, null);
        if(!String.isBlank(con.Phone)) {
            String formattedPhoneNumber = con.Phone.remove('-').remove('/').remove(' ');
            if(!formattedPhoneNumber.startsWith('+49')) {
                formattedPhoneNumber = formattedPhoneNumber.removeStart('0');
                formattedPhoneNumber = '+49' + formattedPhoneNumber;               
            }
            inTelephone.addTextNode(formattedPhoneNumber);
        }
        else {
            inTelephone.addTextNode('');
        }
        
        // inMobilePhone
        DOM.XmlNode inMobilePhone = request.addChildElement('inMobilePhone', null, null);
        if(!String.isBlank(con.MobilePhone)) {
            String formattedMobilePhoneNumber = con.MobilePhone.remove('-').remove('/').remove(' ');
            if(!formattedMobilePhoneNumber.startsWith('+49')) {
                formattedMobilePhoneNumber = formattedMobilePhoneNumber.removeStart('0');
                formattedMobilePhoneNumber = '+49' + formattedMobilePhoneNumber;               
            }
            inMobilePhone.addTextNode(formattedMobilePhoneNumber);            
        }
        else {
            inMobilePhone.addTextNode('');            
        }
        
        // inLeadpartnername
        DOM.XmlNode inLeadpartnername = request.addChildElement('inLeadpartnername', null, null);
        inLeadpartnername.addTextNode(currentUserFirstName);
        
        // inLeadpartnersurname
        DOM.XmlNode inLeadpartnersurname = request.addChildElement('inLeadpartnersurname', null, null);
        inLeadpartnersurname.addTextNode(currentUserLastName);           
        
        // inContactDate
        DOM.XmlNode inContactDate = request.addChildElement('inContactDate', null, null);        
        inContactDate.addTextNode(DateTime.now().format('yyyy-MM-dd'));
        
        // inMessage
        DOM.XmlNode inMessage = request.addChildElement('inMessage', null, null);
        if(!String.isBlank(opp.Anmerkungen_f_r_den_Partner__c)) {
            inMessage.addTextNode(opp.Anmerkungen_f_r_den_Partner__c);
        }
        else {
            inMessage.addTextNode('');
        }
        
        // inSourceInfo
        DOM.XmlNode inSourceInfo = request.addChildElement('inSourceInfo', null, null);
        String sourceInfo = '';
        if(!String.isBlank(opp.Deutschkenntnisse_der_Betreuungskraft__c)) {
            sourceInfo = opp.Deutschkenntnisse_der_Betreuungskraft__c + ', ';
        }
        if(!String.isBlank(opp.Geschlecht_der_Betreuungskraft__c)) {
            sourceInfo += opp.Geschlecht_der_Betreuungskraft__c + ', ';
        }
        if(!String.isBlank(opp.Zeitpunkt_der_Versorgung__c)) {
            sourceInfo += opp.Zeitpunkt_der_Versorgung__c;
        }
        inSourceInfo.addTextNode(sourceInfo);
        
        // inputChannel
        DOM.XmlNode inputChannel = request.addChildElement('inputChannel', null, null);
        inputChannel.addTextNode(inputChannelId);
                
        return requestBody;
    }
    
    private static void setPromedicaSettings(){
        try {
            Promedica_Settings__c settings = Promedica_Settings__c.getValues('Default');
            if(settings.Endpoint__c != null) endpoint = settings.Endpoint__c;
            if(settings.SourceId_Klient__c != null) sourceIdKlient = settings.SourceId_Klient__c;
            if(settings.SourceId_OP__c != null) sourceIdOP = settings.SourceId_OP__c;
        }
        catch(System.Exception e) {
            System.debug('PromedicaRequest Error: ' + e.getMessage());
        }        
    }
}