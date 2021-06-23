/********************************************************************************************************************************************
// Created on 23.07.2020 von BT
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstraße. 29
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
//                   		HTTP Callout Mock for the class PromedicaRequest
//********************************************************************************************************************************************
//  Changes:
//  
//********************************************************************************************************************************************
*/
global with sharing class PromedicaRequestMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest request){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'text/xml;charset=UTF-8');        
        response.setStatusCode(201);
        response.setBody(getResponseBody());
        return response;
    }
    
    private String getResponseBody(){
		DOM.Document responseBody = new DOM.Document();    
        DOM.XmlNode envelope = responseBody.createRootElement('Envelope', 'http://schemas.xmlsoap.org/soap/envelope/', 'soap');
        envelope.setNamespace('xsd', 'http://www.w3.org/2001/XMLSchema');
        envelope.setNamespace('xsi', 'http://www.w3.org/2001/XMLSchema-instance');
        DOM.XmlNode body = envelope.addChildElement('Body', '', 'soap');
        DOM.XmlNode createContactResponse = body.addChildElement('CreateContactResponse', 'http://www.intersys.pl/', '');
        DOM.XmlNode createContactResult = createContactResponse.addChildElement('CreateContactResult', null, null);
        return responseBody.toXmlString();
    }
}