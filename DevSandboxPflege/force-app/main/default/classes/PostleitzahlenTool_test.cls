@isTest
public class PostleitzahlenTool_test {

    static testMethod void postleitzahlenToolTest() {
        
        opportunity opp = new opportunity();
        opp.Name ='test';
        opp.StageName = 'Offen';
        opp.Produkt_Kategorie__c = 'Sitzlift';
        DateTime myDateTime = DateTime.newInstance(2016, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        opp.Preis_maximal__c = 200;
        opp.Belastbarkeit__c = '120';
        opp.Neu_und_oder_gebraucht__c = 'Neu';
        opp.Art_der_Finanzierung__c = 'Kauf';
        opp.Umgebung__c='test';
        opp.Treppenbauart__c='test';
        opp.Art_des_Geb_udes__c='test';
        opp.Anzahl_der_Etagen__c=2;
        opp.Grube__c=true;
        opp.Versand_von_Informationsmaterial__c = true;
        opp.Termin_vor_Ort__c = true;
        opp.Ausland__c = true;
        opp.F_rderh_he__c = 10;
        opp.Technik__c = '';
        opp.Beantragung_der_Pflegestufe__c = true;
        opp.Wartung_des_Produkts__c = true;
        opp.Notdienst__c = true;
        insert opp;
        
        Contact c = new Contact();
        c.FirstName = 'ksg_plz';
        c.LastName = 'test class';
        c.Email = 'ziaei@klosesrockepartner.de';
        c.MailingPostalCode = '22767';
        insert c;
        
        OpportunityContactRole cr = new OpportunityContactRole();
        cr.ContactId = c.Id;
        cr.OpportunityId = opp.Id;
        cr.IsPrimary = true;
        cr.Role = 'PB = ASP';
        insert cr;
        
        PostleitzahlenTool plzTool = new PostleitzahlenTool(opp.Id);
        plzTool.getBestPartners();
        
    }
}