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
// Beschreibung: Test für Emails bearbeiten 
//                      
//
//
//****************************************************************************************************************************
// Änderungen:
//****************************************************************************************************************************/
@isTest
private class ksgEmailBearbeiten_test {
    public ksgEmailEmpfang emailEmpfang {get; set;}
    static testMethod void myUnitTest() {
        Account a = new Account(Name = 'Testaccount'); 
        insert a;
        contact c1 = new contact(AccountId = a.id, LastName = 'lastname', FirstName='firsname', Email='someaddress@email.com');
        insert c1;
        contact c2 = new contact(AccountId = a.id, LastName = 'lastname', FirstName='firsname', Email='emailto@email.com');
        insert c2;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();    
        
        email.subject = 'Test Job Applicant';
        email.fromname = 'FirstName LastName';
        email.fromAddress = 'someaddress@email.com';
        String[] toAddress = new String[] {'emailto@email.com'};
        
        email.toAddresses = toAddress;
        email.ccAddresses = toAddress;
        email.plainTextBody = 'Nächster Schritt: Curabox-Anfrage per Mail\n'
                                + 'Salutation: Herr\n'
                                + 'First Name: Ewald\n'
                                + 'Last Name: Dirks\n'
                                + 'Street:\n'
                                + 'Zip/Postal Code:\n'
                                + 'City:\n'
                                + 'Email:\n'
                                + 'Phone:\n'
                                + 'Angehöriger Anrede: Frau\n'
                                + 'Angehöriger Vorname: Imke\n'
                                + 'Angehöriger Nachname: Esser\n'
                                + 'Angehöriger Straße: Taubenweg 4\n'
                                + 'Angehöriger PLZ: 26427\n'
                                + 'Angehöriger Ort: Neuhalingersiehl\n'
                                + 'Angehöriger Telefon: +4949713423\n'
                                + 'Angehöriger Email: imkeesser@googlemail.com\n'
                                + 'Ursprungsanfrage: HNR\n'
                                + 'Mitarbeiter: Stefanie Krüger\n'
                                + 'Pflegestufe: PS beantragt\n'
                                + 'CRM Ticket ID: 243082';      
        email.htmlBody = email.plainTextBody; 
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';      
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
        
        Messaging.InboundEmail.TextAttachment tattachment = new Messaging.InboundEmail.TextAttachment();
        tattachment.body = 'my text attachment text';
        tattachment.fileName = 'textfile2.txt';
        tattachment.mimeTypeSubType = 'text/plain';     
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { tattachment };        
        
        env.fromAddress = 'someaddress@email.com';
        ksgEmailEmpfang emailEmpfang = new ksgEmailEmpfang();
        emailEmpfang.handleInboundEmail(email, env);        
        
    
    }
    
}