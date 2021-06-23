//****************************************************************************************************************************
// Erstellt 11.06.2019 von AM
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
// xxxx
//
//****************************************************************************************************************************
//
// Beschreibung:
//                      
// Test for contactStatusHelper
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
@isTest
public class contactStatusHelper_test {
    @testSetup static void dataForTest() {
    
    }

    static testMethod void contactStatusTest() {
        Campaign cmp = new Campaign(name ='Curabox');
        insert cmp;

        list<lead> ldList = new List<lead>();
        Lead lead0 = new Lead();
        lead0.LastName ='TestContact0';
        lead0.Company='Curabox';
        lead0.OM_Wizzard_Name2__c = cmp.Id;
        lead0.OM_created_at__c = '11.06.2019';
        lead0.OM_Tracking_Order_ID__c = 'gt12345678';
        lead0.OM_Referrer__c = 'ref';
        lead0.CB_Box__c = 'CB1';
        lead0.CB_Lieferung__c = 'insured_person';
        lead0.OM_Wizard_Version__c = 'v2';
        lead0.Salutation = 'Herr';
        insert lead0;
        ldList.add(lead0);

        Lead lead1 = new Lead();
        lead1.LastName ='TestContact1';
        lead1.Company='Curabox';
        lead1.Salutation = 'Herr';
        lead1.OM_Wizzard_Name2__c = cmp.Id;
        lead1.OM_created_at__c = '11.06.2019';
        lead1.OM_Tracking_Order_ID__c = 'gt12345678';
        lead1.OM_Referrer__c = 'ref';
        lead1.CB_Box__c = 'CB6';
        lead1.CB_Lieferung__c = 'care_person';
        lead1.OM_Wizard_Version__c = 'v2';
        insert lead1;
        ldList.add(lead1);

        Lead lead2 = new Lead();
        lead2.LastName ='TestContact2';
        lead2.Company='Curabox';
        lead2.Salutation = 'Herr';
        lead2.OM_Wizzard_Name2__c = cmp.Id;
        lead2.OM_created_at__c = '11.06.2019';
        lead2.OM_Tracking_Order_ID__c = 'gt12345678';
        lead2.OM_Referrer__c = 'ref';
        lead2.CB_Box__c = 'CB6';
        lead2.CB_Lieferung__c = 'care_service';
        lead2.OM_Wizard_Version__c = 'v2';
        insert lead2;
        ldList.add(lead2);

        //=============================================
        // accounts Krankenkassen
        list<RecordType> kk_rtList = [SELECT Id FROM RecordType WHERE Name = '03 Kostenträger']; 
        // Pflegekasse gesetzlich
        Account KK = new Account(name='Testpflegekasse', Industry = 'Krankenkassen', type = 'Test');
        KK.RecordTypeId = kk_rtList[0].id;
        KK.IK_Nummer__c = '12345678';
        KK.Kanal_Unterpunkt__c = 'gesetzlich';
        KK.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
        KK.Hilfsmittel_Kennzeichen__c = 'HM';     
        KK.AC__c = 'AC';
        KK.TK__c = 'TK';   
        KK.Medifox_Ausschluss__c = true;
        KK.BillingStreet = 'Teststrasse';
        KK.Billingcity = 'Testort';
        KK.BillingPostalCode = '12345';
        KK.Fax = '04012345678';
        insert KK;

        List<RecordType> fam_rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
        list<RecordType> con_rtList = [SELECT Id FROM RecordType WHERE Name = 'Familienangehörige'];
        List<account> familieList = new List<account>();
        List<contact> contactList = new List<contact>();
        for(integer i=0; i<3; i++) {
            Account testFamilie = new Account(RecordTypeId = fam_rtList[0].id, Name = 'TestContact' + String.valueOf(i) + ' - Familie');
            familieList.add(testFamilie); 
        }
        Database.SaveResult[]  srList = Database.insert(familieList, false); 
        integer count = 0;
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {  
                id accId = sr.getId();
                    Contact con = new Contact( 
                        RecordTypeId = con_rtList[0].id,
                        lastname = 'TestContact' + String.valueOf(count),
                        firstname = 'test_firstname',
                        AccountId = accId,
                        Email = 'test' + string.valueOf(count) + '@test.de',
                        Phone = '0123456789',
                        MailingStreet = 'contactstreet',
                        MailingPostalCode='23456',
                        MailingCity='contactcity',
                        Kranken_Pflegekasse__c=KK.id,
                        Versicherungsnummer__c='VERSNR01234567',
                        Birthdate=date.today().addYears(-60),
                        Lead__c = ldList[count].id,
                        Ursprungsanfrage__c = cmp.Id,
                        Art_des_Kontakts__c = 'Pflegebedürftige'
                        // Wunschbox__c = cbList[cb].id
                        // Art_Von_Handschuhe__c=p1.id
                        );
                    contactList.add(con);
                    count++;
            }
            else {
                System.debug('error insert account');
            }
        }
        test.startTest();
        insert contactList;
        // test.stopTest();
        List<Curabox_Genehmigung__c> gnList= new List<Curabox_Genehmigung__c>();
        List<contact_status__c> csList = [SELECT id, Contact__c, Contact__r.lastname, Productgroup__c, delivery_address__c 
                                            FROM contact_status__c
                                            ORDER By Contact__r.lastname, Productgroup__c];
        for(contact_status__c cs : csList) {

            if(cs.Contact__r.lastname == 'TestContact0') {
                System.assertEquals(cs.delivery_address__c , 'customer address');
            }
            else if(cs.Contact__r.lastname == 'TestContact1') {
                System.assertEquals(cs.delivery_address__c , 'family member');
            }
            else if(cs.Contact__r.lastname == 'TestContact2') {
                System.assertEquals(cs.delivery_address__c , 'care service');
            }
            Curabox_Genehmigung__c gen = new Curabox_Genehmigung__c(Contact__c = cs.Contact__c, Nach_Paragraph__c = cs.Productgroup__c.replace('PG', ''));
            gnList.add(gen);   
        }

        insert gnList;
        List<recordType> rtList =[select id, name,sobjecttype from recordType where name ='Curabox' and sobjecttype  = 'Opportunity' limit 1];
        recordType rt = rtList [0];
        List<Opportunity> opList = new List<Opportunity>();
        map<id,id> ctMap = new Map<id, id>();

        List<Curabox_Genehmigung__c> gntList= [SELECT id, Nach_Paragraph__c, Contact__c, Contact__r.AccountId FROM Curabox_Genehmigung__c];
        boolean ok;
        // test.startTest();
        for(Curabox_Genehmigung__c gn : gntList) {
            if(gn.Nach_Paragraph__c == '54') {
                ok = contactStatusHelper.setAntragEingegangen(gn.id);
                opportunity opp = new opportunity();
                opp.accountid = gn.Contact__r.accountid;
                opp.Name ='from_test_class';
                opp.RecordTypeId =rt.Id;
                opp.StageName = 'Closed Won';          
                opp.CloseDate = date.today();
                opList.add(opp);
                ctMap.put(gn.Contact__r.AccountId, gn.Contact__c);
            }
            else {
                ok = contactStatusHelper.setAntragEingegangen(gn.Contact__c, 'PG' + gn.Nach_Paragraph__c);
            }
        }
        srList = Database.insert(opList, false); 
        List<Opportunity> opiList = [SELECT id, accountid FROM Opportunity LIMIT 100];
        List<Order__c> odList = new List<Order__c>();

        for(Opportunity op : opiList) {
            Order__c order = new Order__c(Opportunity__c=op.id);
            order.Contact__c=ctMap.get(op.accountId);
            order.Nach_Paragraph__c = '54';
            order.Status__c = 'aktiv';
            order.Description__c = 'CB1';
            order.Liefertag__c = date.today();
            order.Delivery_frequency__c = 'monatlich';
            odList.add(order);
        }
        srList = Database.insert(odList, false); 

        test.stopTest();
        csList = [SELECT id, Contact__c, Contact__r.lastname, Productgroup__c, Status__c, Antrag_eingegangen_am__c 
                                            FROM contact_status__c
                                            ORDER By Contact__r.lastname, Productgroup__c];  
        for(contact_status__c cs : csList) {
            System.assertEquals(cs.Status__c , 'Kandidat');
            System.assertEquals(cs.Antrag_eingegangen_am__c , date.today());
        }

        List<Order__c> odtList = [SELECT id, Contact__c, Contact__r.lastname, Nach_Paragraph__c FROM Order__c];
        for(Order__c od: odtList) {
            if(od.Contact__r.lastname == 'TestContact0') {
                ok = contactStatusHelper.setAntragGenehmigt(od.Contact__c, 'PG' + od.Nach_Paragraph__c);
            }
            else {
                ok = contactStatusHelper.setAntragGenehmigt(od.id);
            }

        }      

        csList = [SELECT id, Contact__c, Contact__r.lastname, Productgroup__c, Status__c, Antrag_bewilligt_abgelehnt_am__c 
                                            FROM contact_status__c
                                            ORDER By Contact__r.lastname, Productgroup__c];  
        for(contact_status__c cs : csList) {
            if(cs.Productgroup__c == 'PG54') {
                System.assertEquals(cs.Status__c , 'Kunde');
                System.assertEquals(cs.Antrag_bewilligt_abgelehnt_am__c , date.today());
            }
        }                                               
        
    }
}