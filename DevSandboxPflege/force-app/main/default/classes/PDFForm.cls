/****************************************************************************************************************************
// Created on 19.05.2020 by BT
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
//****************************************************************************************************************************
//
// Description: 
//                         fill pdf form with customer number             
//
//****************************************************************************************************************************
// Changes:   
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public class PDFForm {
    static String user = 'salesforce';
    static String password = 'Sebastian1';
    static String endpoint = 'https://api-dev-sandbox.pflege.de/curabox/pdf/number-stamp';
    static String originalDocumentName = 'Antragsformular';
    static String originalDocumentIds = '<ids original="243551168BAA407E9BFAB91A5A5B8C20" modified="B6557AA8707EE245B9211654D4EF2E0E"/>';
    public String pdfFormId;
    
    public void fillAntragFormular(){    
        String customerId = ApexPages.currentPage().getParameters().get('id');
        Contact c = [SELECT Account.Familien_ID__c FROM Contact WHERE ID = :customerId];
        pdfFormId = PDFForm.getFilledPdfForm('Antragsformular_Post', c.Account.Familien_ID__c, customerId);
    }    
    
    public static String getFilledPdfForm(String documentName, String customerNumber, Id customerId) {
        String docId = null;
        
        try {
            originalDocumentName = documentName;            
            HttpRequest req = createHttpRequest();
            req.setBody(getRequestBody(customerNumber, originalDocumentName));
            
            Http http = new Http();
            HttpResponse res = http.send(req);
            String pdfbody = res.getBody();
            String fileName = originalDocumentName.replace('_Post', '').replace('_Email', '');
            
            ContentVersion conVer = new ContentVersion();
            conVer.ContentLocation = 'S'; 
            conVer.PathOnClient = fileName + '.pdf'; 
            conVer.Title = fileName; 
            conVer.VersionData = EncodingUtil.base64Decode(pdfBody); 
            insert conVer;  
            
            Id conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id].ContentDocumentId;
            ContentDocumentLink conDocLink = New ContentDocumentLink();
            conDocLink.LinkedEntityId = customerId;
            conDocLink.ContentDocumentId = conDoc;  
            conDocLink.shareType = 'V';
            insert conDocLink; 
            
            docId = conVer.Id;
        }
        catch(System.Exception e) {
            System.debug('# Fill PDF Form - Following error occurs ' + e.getMessage());
        }
        
        return docId;             
    } 
    
    private static HttpRequest createHttpRequest(){
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint(getRequestEndpoint());    
        return req;
    }
    
    private static String getAuthorizationHeader(){
        String usr = getEndpointUser();
        String pwd = getEndpointUserPassword();        
        Blob headerValue = Blob.valueOf(usr + ':' + pwd);
        return 'BASIC ' + EncodingUtil.base64Encode(headerValue);
    }
    
    private static String getEndpointUser(){
        try{
            return PDF_Form_Settings__c.getValues(originalDocumentName).User__c;
        }
        catch(System.Exception e) {
            return user;
        }
    }
    
    private static String getEndpointUserPassword(){
        try{
            return PDF_Form_Settings__c.getValues(originalDocumentName).Password__c;
        }
        catch(System.Exception e) {
            return password;
        }
    }    
    
    private static String getRequestEndpoint(){
        try{
            return PDF_Form_Settings__c.getValues(originalDocumentName).Endpoint__c;
        }
        catch(System.Exception e) {
            return endpoint;
        }        
    }      
    
    private static String getRequestBody(String customerNumber, String docName){
        JSONGenerator gen = JSON.createGenerator(true);
        // Write data to the JSON string.
        gen.writeStartObject(); // start
        gen.writeStringField('filename', docName);
        gen.writeStringField('family_number', customerNumber);
        gen.writeEndObject();
        // Get the JSON string.
        String pretty = gen.getAsString();
        return pretty;
    }
    
    private static String getDocumentIDs(){
        try{
            return PDF_Form_Settings__c.getValues(originalDocumentName).PDF_IDs__c;
        }
        catch(System.Exception e) {
            return originalDocumentIds;
        }
    }   
    
    public String getPdfFormId(){
        return PdfFormId;
    }
}