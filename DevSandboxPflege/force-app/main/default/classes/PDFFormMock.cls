/****************************************************************************************************************************
// Created on 26.05.2020 by BT
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
//                         Http Callout Mock for the apex class PDFForm
//
//****************************************************************************************************************************
// Changes:   
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global class PDFFormMock implements HttpCalloutMock {
    global HttpResponse respond(HttpRequest req){
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'text/plain');
        response.setStatusCode(200);
        response.setBody('JVBERi0xLjcKJeLjz9MKMS');
        return response;
    }
}