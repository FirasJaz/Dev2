/*********************************************************************************************************************************************
// Created 04.07.2018 by MZ
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
//    #155510105 - Bad goes Salesforce.com
//    to handel incoming emails to Badumabu
//
//********************************************************************************************************************************************
//  Changes:
//********************************************************************************************************************************************
*/
global without sharing class EmailServiceBadumbau implements Messaging.InboundEmailHandler {
    public EmailServiceHandlerBadumbau badumbauMail {get; set;}
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        badumbauMail = new EmailServiceHandlerBadumbau(email);
        
        result.success = true;
        return result;
    }
    
}