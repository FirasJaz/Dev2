//****************************************************************************************************************************
// Erstellt 06.11.2017 von BT
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
// xxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// xxx
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
global with sharing class libifyRequestMock implements HTTPCalloutMock{
    global HTTPResponse respond(HTTPRequest req){
        HttpResponse res = new HTTPResponse();
        res.setHeader('Content-Type', 'application/JSON');
        res.setBody('body');
        res.setStatusCode(201);
        return res;
    }
}