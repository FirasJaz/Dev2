@isTest(seeAllData = true)
private class libifyRequest_test {
     static testMethod void libifyRequest_Test(){
         Account acc = new Account();
         acc.name = 'test libifyRequest Account';
         
         insert acc;
         
         RecordType rt = [SELECT Id, sObjectType FROM RecordType WHERE Name = 'Familienangehörige' and sObjectType = 'Contact'];           
         
         Contact cont = new Contact();
         cont.salutation = 'Herr';
         cont.lastname = 'test libifyRequest Name';
         cont.firstname = 'test Vorname';
         cont.Email = 'test@test.de';
         cont.MailingStreet = 'teststrasse 123';
         cont.MailingCity = 'test Ort';
         cont.MailingPostalcode = '11223';
         cont.Phone = '123456789';
         cont.MobilePhone = '123789456';
         cont.Fax = '456789123';
         cont.AccountId = acc.id;
         cont.RecordTypeId = rt.id;
         cont.Bekannte_Krankheiten__c = 'KHK coronare';
         cont.Medikamente__c = 'Blutdruckmedikamente';
         insert cont;
         
         Opportunity opp = new Opportunity();
         opp.Name = 'test opp';
         opp.StageName = 'Offen';
         opp.AccountId = acc.Id;
         opp.Produkt_Kategorie__c = '2';
         opp.closeDate = date.today() + 10;
         opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Angehörigen';
         opp.Angefragter_Wohnort__c = 'test Ort';
         opp.Anmerkungen_f_r_den_Partner__c = 'test Beschreibung';
         opp.Bezugsperson_1__c = cont.Id;
         opp.Bezugsperson_2__c = cont.Id;
         
         insert opp;
         
         OpportunityContactRole cr = new OpportunityContactRole();
         cr.ContactId = cont.Id;
         cr.OpportunityId = opp.Id;
         cr.IsPrimary = true;
         cr.Role = 'PB = ASP';
         insert cr;
         
         Partner_Ticket__c pt = new Partner_Ticket__c();
         pt.Opportunity__c = opp.id;
         
         insert pt;
         
         if (test.isRunningTest()) Test.setMock(HttpCalloutMock.class, new libifyRequestMock());
         libifyRequestMock mck = new libifyRequestMock();
         mck.respond(new HttpRequest());
         libifyRequest.send_libifyRequest(pt.id, 'test');      
         libifyRequest.send_libifyRequest_DV(pt.id, 'test');  
     }
     
     static testMethod void libifyRequest_DV_noPB_Test(){
         Account acc = new Account();
         acc.name = 'test libifyRequest Account';
         
         insert acc;
         
         RecordType rt = [SELECT Id, sObjectType FROM RecordType WHERE Name = 'Familienangehörige' and sObjectType = 'Contact'];           
         
         Contact cont = new Contact();
         cont.salutation = 'Herr';
         cont.lastname = 'test libifyRequest Name';
         cont.firstname = 'test Vorname';
         cont.Email = 'test@test.de';
         cont.MailingStreet = 'teststrasse 123';
         cont.MailingCity = 'test Ort';
         cont.MailingPostalcode = '11223';
         cont.Phone = '123456789';
         cont.MobilePhone = '123789456';
         cont.Fax = '456789123';
         cont.AccountId = acc.id;
         cont.RecordTypeId = rt.id;
         cont.Bekannte_Krankheiten__c = 'KHK coronare';
         cont.Medikamente__c = 'Blutdruckmedikamente';
         insert cont;
         
         Opportunity opp = new Opportunity();
         opp.Name = 'test opp';
         opp.StageName = 'Offen';
         opp.AccountId = acc.Id;
         opp.Produkt_Kategorie__c = '2';
         opp.closeDate = date.today() + 10;
         opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Angehörigen';
         opp.Angefragter_Wohnort__c = 'test Ort';
         opp.Anmerkungen_f_r_den_Partner__c = 'test Beschreibung';
         opp.Bezugsperson_1__c = cont.Id;
         opp.Bezugsperson_2__c = cont.Id;
         
         insert opp;
         
         OpportunityContactRole cr = new OpportunityContactRole();
         cr.ContactId = cont.Id;
         cr.OpportunityId = opp.Id;
         cr.IsPrimary = true;
         cr.Role = 'ASP';
         insert cr;
         
         Partner_Ticket__c pt = new Partner_Ticket__c();
         pt.Opportunity__c = opp.id;
         
         insert pt;
         
         if (test.isRunningTest()) Test.setMock(HttpCalloutMock.class, new libifyRequestMock());
         libifyRequestMock mck = new libifyRequestMock();
         mck.respond(new HttpRequest());
         libifyRequest.send_libifyRequest_DV(pt.id, 'test');  
     }
}