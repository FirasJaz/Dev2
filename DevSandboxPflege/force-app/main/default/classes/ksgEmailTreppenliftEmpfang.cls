/****************************************************************************************************************************
// Erstellt 01.07.2016 von AM
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04023882986
//  Fax.: 04023882989
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Messaging.InboundEmail
//
//****************************************************************************************************************************
//
// Beschreibung:
// Analysieren ankommende Email                    
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
*/
global class ksgEmailTreppenliftEmpfang implements Messaging.InboundEmailHandler {
    public ksgEmailTreppenliftBearbeiten ksgMail {get; set;}
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult resultData = new Messaging.InboundEmailresult();
        ksgMail = new ksgEmailTreppenliftBearbeiten(email);
        
        resultData.success = true;
        return resultData;
    }
}