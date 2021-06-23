/*/****************************************************************************************************************************
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Erstellung von Testdaten
// 
//****************************************************************************************************************************
//Änderungen:    
// 12.11.2018	MS	Auslagerung der Erstellung von Test-Daten  
// 06.12.2018	MZ  methods added: createPartnerAccount, createPartnerProduct, createProductPrice, createOpportunity
//****************************************************************************************************************************
*/
@isTest
public class TestDataFactory {
	// creates Kunde__c and Kundenstatus__c records with the given parameters
    public static Kunde__c createKundeAndKundenstatus(String s, String status, Integer AnzahlEmails, Date Creation){
        Kunde__c kd = new Kunde__c();
        kd.Name__c = 'Kunde'+s;    
        kd.Anrede__c = 'Herr';   
        kd.e_mail__c = s+'test@test.de'; 
        kd.Produktgruppe__c = 'PG54';
        kd.Email_Opt_Out__c = false;
        insert kd;
        
        Test.setCreatedDate(kd.id, Creation);
        Kundenstatus__c ks = [SELECT  id, Kunde__c, Produktgruppe__c, Anzahl_Erinnerung_Email__c, Status__c
                                        FROM Kundenstatus__c
                                        WHERE Kunde__c =: kd.Id LIMIT 1];
        ks.Anzahl_Erinnerung_Email__c = AnzahlEmails;
        ks.Status__c = status;
        Test.setCreatedDate(ks.id, Creation);
        update ks;
        
        return kd;
    }
    
    
    // create partner Account
    public static Account createPartnerAccount(String name){
        List<RecordType> a_rtList =[select id, name,sobjecttype from recordType where name ='Pflege.de - Partner' and sobjecttype  = 'Account' limit 1];
        RecordType a_rt = a_rtList [0];
        
        Account a = new Account();
        a.RecordTypeId = a_rt.Id;
        a.Name = name + 'P_plzTool';
        a.ticket_email_address__c = name+'test@test.de'; 
        insert a;
        
        return a;
    }
    
    // create a product for the specified partner.
    // parameter recordTypeName : record type of the created product
    public static Partner_Produkte__c createPartnerProduct(String recordTypeName, Id parnerId){
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name =: recordTypeName and sobjecttype  = 'Partner_Produkte__c' limit 1];
        RecordType rt = rtList [0];
        
        Partner_Produkte__c pp = new Partner_Produkte__c();
        pp.RecordTypeId = rt.Id;
        if(recordTypeName.equalsIgnoreCase('Treppenlift')){
            pp.Produktgruppe__c = 'Sitzlift';
        }
        // add other product record types if required
        pp.Deutschlandweit_verf_gbar__c = true;
        pp.Partner__c = parnerId;
        insert pp;
        
        return pp;
    }
    
    // create sample price for the soecified product
    public static Partner_Preise__c createProductPrice(Id productId){
        Partner_Preise__c pp_price = new Partner_Preise__c();
        pp_price.Partner_Produkt__c = productId;
        pp_price.CPL_Kat_1__c = 15;
        pp_price.CPL_Exklusiv__c = 10;
        insert pp_price;
        return pp_price;
    } 
    
    
    // create opportunity of the mentioned recordType
    public static opportunity createOpportunity(String recordTypeName, String name){
        List<RecordType> rtList =[select id, name,sobjecttype from recordType where name = :recordTypeName and sobjecttype  = 'Opportunity' limit 1];
        RecordType rt = rtList [0];
        
        opportunity opp = new opportunity();
        opp.Name =name+'test_class';
        opp.RecordTypeId =rt.Id;
        opp.StageName = 'Offen';
        if(recordTypeName.equalsIgnoreCase('Treppenlift')){
            opp.Produkt_Kategorie__c = 'Sitzlift';
        }
        
        DateTime myDateTime = DateTime.newInstance(2019, 1, 31, 7, 8, 16);
        opp.CloseDate = myDateTime.date();
        opp.Bezugspunkt_der_PLZ_Suche__c = 'Ort des Pflegebedürftigen';
        
        insert opp;
        return opp;
    }
}