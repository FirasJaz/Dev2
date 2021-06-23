/*/****************************************************************************************************************************
// Erstellt 10.03.2016 von AM
//          Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//          Nordkanalstrasse 58
//          20097 Hamburg 
//          Tel.:  04064917161
//          Fax.:  04064917162
//          Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: InboundEmailHandler interface
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/
global class ksgEmailEmpfang implements Messaging.InboundEmailHandler {
    ksgEmailBearbeiten ksgMail {get; set;}
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult resultData = new Messaging.InboundEmailresult();
        ksgMail = new ksgEmailBearbeiten(email);
        
        resultData.success = true;
        return resultData;
    }
}