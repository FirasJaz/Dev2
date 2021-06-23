/*/****************************************************************************************************************************
// Erstellt 30.05.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine
// 
// 
//****************************************************************************************************************************
//
// Beschreibung:
//                      
//  Helper. Erstellen Artikel Daten für die Testklassen
//  
//
//****************************************************************************************************************************
//Änderungen:       
// 27.08.2020 - Anpassung an Liefermengereduzierung
//****************************************************************************************************************************
*/
public with sharing class create_test_product {
    public static void createProducts() {
        Product_Group__c pg1 = new Product_Group__c(Positionsnummer__c='54', name='Bettschutzeinlagen', Description__c='Bettschutzeinlagen'); 
        insert pg1;
        Product_Group__c pg2 = new Product_Group__c(Positionsnummer__c='51', name='Bettschutzeinlagen (Wiederverwendung)', Description__c='Bettschutzeinlagen (Wiederverwendung)'); 
        insert pg2;
        Product_Group__c pg3 = new Product_Group__c(Positionsnummer__c='54', name='Einmalhandschuhe', Description__c='Einmalhandschuhe'); 
        insert pg3;        
        Product_Group__c pg4 = new Product_Group__c(Positionsnummer__c='54', name='Fingerlinge', Description__c='Fingerlinge'); 
        insert pg4;
        Product_Group__c pg5 = new Product_Group__c(Positionsnummer__c='54', name='Flächendesinfektion', Description__c='Flächendesinfektion'); 
        insert pg5;
        Product_Group__c pg6 = new Product_Group__c(Positionsnummer__c='54', name='Händedesinfektion', Description__c='Händedesinfektion'); 
        insert pg6;
        Product_Group__c pg7 = new Product_Group__c(Positionsnummer__c='54', name='Mundschutz', Description__c='Mundschutz'); 
        insert pg7;
        Product_Group__c pg8 = new Product_Group__c(Positionsnummer__c='54', name='Schutzschürze', Description__c='Schutzschürze'); 
        insert pg8;
        Product_Group__c pg9 = new Product_Group__c(keine_Genehmigungspflicht__c=true, name='Sprühkopf', Description__c='Sprühkopf'); 
        insert pg9;
        Product_Group__c pg10 = new Product_Group__c(keine_Genehmigungspflicht__c=true, name='Pumpaufsatz', Description__c='Pumpaufsatz');
        insert pg10;

        // Products
        List<Product__c> prList = new List<Product__c>();
        Product__c pr = new Product__c(name='Bacillol AF Flächendesinfektionsmittel (500ml)', abda_mwst_knz__c='1', Product_Group__c=pg5.id, Hilfsmittelpositionsnummer__c='54000001', EAN__c='4031678014118', manufacturer_article_number__c='1000811', volume_unit__c='STCK', Price__c=6.16, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='Foliodress Mask Loop Mundschutz', abda_mwst_knz__c='1', Product_Group__c=pg7.id, Hilfsmittelpositionsnummer__c='54000002', EAN__c='4049500618748', manufacturer_article_number__c='9925371', volume_unit__c='PCKG', Price__c=7.16, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='MoliNea normal Bettschutzeinlagen', abda_mwst_knz__c='1', Product_Group__c=pg1.id, Hilfsmittelpositionsnummer__c='54000003', EAN__c='4052199204444', manufacturer_article_number__c='1618208', volume_unit__c='PCKG', Price__c=10.77, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='MoliNea textile Bettschutzeinlage', abda_mwst_knz__c='1', Product_Group__c=pg2.id, Hilfsmittelpositionsnummer__c='51000001', EAN__c='8698804651133', manufacturer_article_number__c='9334040', volume_unit__c='STCK', Price__c=26.16, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft nitrile white Einmalhandschuhe (Größe L)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000004', EAN__c='4052199000237', manufacturer_article_number__c='9422182', volume_unit__c='PCKG', Price__c=7.18, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft nitrile white Einmalhandschuhe (Größe M)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422172', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft nitrile white Einmalhandschuhe (Größe S)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft nitrile white Einmalhandschuhe (Größe XL)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000006', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft Vinyl Einmalhandschuhe (Größe S)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft Vinyl Einmalhandschuhe (Größe M)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft Vinyl Einmalhandschuhe (Größe L)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft Vinyl Einmalhandschuhe (Größe XL)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft-latex Einmalhandschuhe (Größe S)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft-latex Einmalhandschuhe (Größe M)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft-latex Einmalhandschuhe (Größe L)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Peha-soft-latex Einmalhandschuhe (Größe XL)', abda_mwst_knz__c='1', Product_Group__c=pg3.id, Hilfsmittelpositionsnummer__c='54000005', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=7.18);
        prList.add(pr);
        pr = new Product__c(name='Sterillium Hände-Desinfektionsmittel (500ml)', abda_mwst_knz__c='1', Product_Group__c=pg6.id, Hilfsmittelpositionsnummer__c='54000001', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='STCK', Price__c=8.21, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='ValaComfort apron Premium Einmal-Schutzschürze', abda_mwst_knz__c='1', Product_Group__c=pg8.id, Hilfsmittelpositionsnummer__c='54000001', EAN__c='4052199000213', manufacturer_article_number__c='9422162', volume_unit__c='PCKG', Price__c=13.34, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='Universalsprühkopf 500ml/1l', abda_mwst_knz__c='1', Product_Group__c=pg9.id, Hilfsmittelpositionsnummer__c='54000001', EAN__c='4052199000213', manufacturer_article_number__c='1000700', volume_unit__c='STCK', Price__c=0.0, standard_article_for_curabox__c=true);
        prList.add(pr);
        pr = new Product__c(name='Einmalpumpe langer Auslauf 350/500 ml', abda_mwst_knz__c='1', Product_Group__c=pg10.id, Hilfsmittelpositionsnummer__c='', EAN__c='4031678074242', manufacturer_article_number__c='1002370', volume_unit__c='STCK', Price__c=0.0, standard_article_for_curabox__c=true);
        prList.add(pr);

        insert prList;
        // Curabox
        curabox__c cb1 = new curabox__c(name='CB1', description__c='CB1');
        insert cb1;
        curabox__c cb2 = new curabox__c(name='CB2', description__c='CB2');
        insert cb2;
        curabox__c cb3 = new curabox__c(name='CB3', description__c='CB3');
        insert cb3;
        curabox__c cb4 = new curabox__c(name='CB4', description__c='CB4');
        insert cb4;
        curabox__c cb5 = new curabox__c(name='CB5', description__c='CB5');
        insert cb5;
        curabox__c cb6 = new curabox__c(name='CB6 - Flexibel', description__c='CB6 - Flexibel', editable__c=true);
        insert cb6;
        curabox__c cb7 = new curabox__c(name='KUWV', description__c='KUWV', editable__c=true);
        insert cb7;
        // junction
        List<Curabox_Product_Group__c> cbrList = new List<Curabox_Product_Group__c>();
        Curabox_Product_Group__c cbp = new Curabox_Product_Group__c(name='Curabox Variante 1 - Einmalhandschuhe', Curabox__c=cb1.id, Product_Group__c=pg3.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 1 - Händedesinfektion', Curabox__c=cb1.id, Product_Group__c=pg6.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 1 - Bettschutzeinlagen', Curabox__c=cb1.id, Product_Group__c=pg1.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 1 - Flächendesinfektion', Curabox__c=cb1.id, Product_Group__c=pg5.id, default_number__c=2);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 1 - Sprühkopf', Curabox__c=cb1.id, Product_Group__c=pg9.id, default_number__c=0, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 2 - Einmalhandschuhe', Curabox__c=cb2.id, Product_Group__c=pg3.id, default_number__c=2);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 2 - Händedesinfektion', Curabox__c=cb2.id, Product_Group__c=pg6.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 2 - Bettschutzeinlagen', Curabox__c=cb2.id, Product_Group__c=pg1.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 2 - Flächendesinfektion', Curabox__c=cb2.id, Product_Group__c=pg5.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 2 - Sprühkopf', Curabox__c=cb2.id, Product_Group__c=pg9.id, default_number__c=0, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 3 - Einmalhandschuhe', Curabox__c=cb3.id, Product_Group__c=pg3.id, default_number__c=2);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 3 - Händedesinfektion', Curabox__c=cb3.id, Product_Group__c=pg6.id, default_number__c=2);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 3 - Flächendesinfektion', Curabox__c=cb3.id, Product_Group__c=pg5.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 3 - Sprühkopf', Curabox__c=cb3.id, Product_Group__c=pg9.id, default_number__c=0, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 4 - Einmalhandschuhe', Curabox__c=cb4.id, Product_Group__c=pg3.id, default_number__c=2);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 4 - Händedesinfektion', Curabox__c=cb4.id, Product_Group__c=pg6.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 4 - Flächendesinfektion', Curabox__c=cb4.id, Product_Group__c=pg5.id, default_number__c=2);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 4 - Sprühkopf', Curabox__c=cb4.id, Product_Group__c=pg9.id, default_number__c=0, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 5 - Händedesinfektion', Curabox__c=cb5.id, Product_Group__c=pg6.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 5 - Bettschutzeinlagen', Curabox__c=cb5.id, Product_Group__c=pg1.id, default_number__c=2);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 5 - Flächendesinfektion', Curabox__c=cb5.id, Product_Group__c=pg5.id, default_number__c=1);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 5 - Sprühkopf', Curabox__c=cb5.id, Product_Group__c=pg9.id, default_number__c=0, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 6 - Einmalhandschuhe', Curabox__c=cb6.id, Product_Group__c=pg3.id, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 6 - Händedesinfektion', Curabox__c=cb6.id, Product_Group__c=pg6.id, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 6 - Bettschutzeinlagen', Curabox__c=cb6.id, Product_Group__c=pg1.id, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 6 - Flächendesinfektion', Curabox__c=cb6.id, Product_Group__c=pg5.id, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 6 - Mundschutz', Curabox__c=cb6.id, Product_Group__c=pg7.id, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 6 - Schutzschürze', Curabox__c=cb6.id, Product_Group__c=pg8.id, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='Curabox Variante 6 - Sprühkopf', Curabox__c=cb6.id, Product_Group__c=pg9.id, editable__c=true);
        cbrList.add(cbp);
        cbp = new Curabox_Product_Group__c(name='KUWV', Curabox__c=cb7.id, Product_Group__c=pg2.id, default_number__c=1, editable__c=true);
        cbrList.add(cbp);
        insert cbrList;
    }

    public static void createTestContacts() {
        createTestContacts(100);
    }

    public static void createTestContacts(integer contactcount) {
        // campaign
        List<campaign> ncList = new List<campaign>();
        campaign cpn = new campaign(name='Curabox Download', Medifox_b__c =false);
        ncList.add(cpn);
        campaign cpm = new campaign(name='Curabox Medifox', Medifox_b__c =true);
        ncList.add(cpm);
        insert ncList;
        List<campaign> cpList = [SELECT id, Name, Medifox_b__c FROM campaign];

        // curaboxes
        List<curabox__c> cbList = [SELECT id FROM curabox__c ORDER BY name];
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
        KK.Medifox_Ausschluss__c = false;
        KK.BillingStreet = 'Teststrasse';
        KK.Billingcity = 'Testort';
        KK.BillingPostalCode = '12345';
        KK.Fax = '04012345678';
        insert KK;

        // Pflegekasse privat
        Account KKP = new Account(name='Testpflegekasse Privat', Industry = 'Krankenkassen', type = 'Test');
        KKP.RecordTypeId = kk_rtList[0].id;
        KKP.IK_Nummer__c = '52345678';
        KKP.Kanal_Unterpunkt__c = 'privat';
        KKP.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
        KKP.Hilfsmittel_Kennzeichen__c = 'HM';     
        KKP.AC__c = 'AC';
        KKP.TK__c = 'TK';   
        KKP.Medifox_Ausschluss__c = true;
        KKP.BillingStreet = 'Teststrassep';
        KKP.Billingcity = 'Testortp';
        KKP.BillingPostalCode = '22345';
        KKP.Fax = '04012345678';
        insert KKP;

        // accounts Pflegedienst
        list<RecordType> pd_rtList = [SELECT Id FROM RecordType WHERE Name = '01 Pflegedienste']; 
        // Pflegekasse privat
        Account PD = new Account(name='Testpflegedienst', Industry = 'Pflegedienste', type = 'Test');
        PD.RecordTypeId = kk_rtList[0].id;
        PD.IK_Nummer__c = '82345678';
        PD.Kategorie__c = '01 Ambulante Pflegedienste';
        PD.Anzahl_der_Patienten__c = 'monatliche Anforderungsliste';
        PD.Kanal_Unterpunkt__c = 'gesetzlich';
        PD.PG51_Abrechnungs_Methode__c = '10% Zuzahlung';
        PD.Hilfsmittel_Kennzeichen__c = 'HM';     
        PD.AC__c = 'AC';
        PD.TK__c = 'TK';   
        PD.Medifox_Ausschluss__c = false;
        PD.BillingStreet = 'Teststrassep';
        PD.Billingcity = 'Testortp';
        PD.BillingPostalCode = '22345';
        PD.Fax = '04012345678';
        insert PD;


        List<account> familieList = new List<account>();
        List<contact> contactList = new List<contact>();
        list<RecordType> fam_rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
        for(integer i=0; i<contactcount; i++) {
            Account testFamilie = new Account(RecordTypeId = fam_rtList[0].id, Name = 'Mustermann' + String.valueOf(i) + ' - Familie');
            familieList.add(testFamilie); 
        }
        Database.SaveResult[]  srList = Database.insert(familieList, false); 
        integer count = 0;
        integer cb = 0;

        list<RecordType> con_rtList = [SELECT Id FROM RecordType WHERE Name = 'Familienangehörige'];
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {  
                id accId = sr.getId();
                    Contact testContact = new Contact( 
                                RecordTypeId = con_rtList[0].id,
                                lastname = 'Mustermann' + String.valueOf(count),
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
                                Wunschbox__c = cbList[cb].id,
                                Art_des_Kontakts__c = 'Pflegebedürftige',
                                Pflegedienst__c = PD.id
                                // Art_Von_Handschuhe__c=p1.id
                                );
                    if(math.mod(count, 2) > 0) {
                        // jeder 2. Medifox
                        testContact.Ursprungsanfrage__c = cpList[1].id;
                    }
                    else {
                        testContact.Ursprungsanfrage__c = cpList[0].id;
                    }
                    // if(math.mod(count, 5) == 0) {
                    //     //  Jeder 5. Beihilfeberechtigt__c
                    //     testContact.Beihilfeberechtigt__c = true;
                    // }
                    if(math.mod(count, 9) == 0) {
                        // jeder 9. privat
                        testContact.Kranken_Pflegekasse__c=KKP.id;
                    }
                    contactList.add(testContact);
                    count++;
                    cb++;
                    if(cb >= 6) cb=0;
            }
            else {
                System.debug('error insert account');
            }
        }  
        srList = Database.insert(contactList, false); 
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {     
                // ToDo: 
                // contact status   
            }   
            else {
                System.debug('error insert contact');
            }            
        }
    }

    public static void createGenehmigung() {
        List<Curabox_Genehmigung__c> gnList = new List<Curabox_Genehmigung__c>();
        List<Curabox_Genehmigungsposition__c> gpList = new List<Curabox_Genehmigungsposition__c>();
        List<Product_Group__c> pgList54 = [SELECT id, name, Positionsnummer__c FROM Product_Group__c WHERE Positionsnummer__c = '54'];
        List<Product_Group__c> pgList51 = [SELECT id, name, Positionsnummer__c FROM Product_Group__c WHERE Positionsnummer__c = '51'];
        List<contact> alleKunden = [SELECT id FROM contact LIMIT 200];
        if((alleKunden != null) && (alleKunden.size() > 0)) {
            for(contact c : alleKunden) {
                Curabox_Genehmigung__c gn = new Curabox_Genehmigung__c(Contact__c = c.id, Status__c = 'Bewilligung', genehmigt_bis__c = date.today().addYears(2), Nach_Paragraph__c='54');
                gnList.add(gn);
                gn = new Curabox_Genehmigung__c(Contact__c = c.id, Status__c = 'Bewilligung', genehmigt_bis__c = date.today().addYears(2), Nach_Paragraph__c='51');
                gnList.add(gn);
            }
        }

        integer i = 0;
        Database.SaveResult[]  srList = Database.insert(gnList, false); 
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                if(gnList[i].Nach_Paragraph__c == '51') {
                    for(Product_Group__c pg : pgList51) {
                        Curabox_Genehmigungsposition__c gp = new Curabox_Genehmigungsposition__c(Genehmigung__c = sr.getId(), Product_Group__c = pg.id, 
                                                                                                Gen_Menge_Stk__c=10, genehmigt_bis__c=gnList[i].genehmigt_bis__c);
                        gpList.add(gp);
                    }
                } 
                else if(gnList[i].Nach_Paragraph__c == '54') {
                    for(Product_Group__c pg : pgList54) {
                        Curabox_Genehmigungsposition__c gp = new Curabox_Genehmigungsposition__c(Genehmigung__c = sr.getId(), Product_Group__c = pg.id, 
                                                                                                Gen_Menge_Stk__c=10, genehmigt_bis__c=gnList[i].genehmigt_bis__c);
                        gpList.add(gp);
                    }
                }
                
            }
            i++;
        }          
        srList = Database.insert(gpList, false); 
    }

    public static void createOrders() {
        List<contact> alleKunden = [SELECT id, lastname, Wunschbox__c, Wunschbox__r.name, accountid FROM contact LIMIT 200];
        map<id,contact> ctMap = new Map<id, contact>();
        List<curabox__c> lsCB = [select Id, Name from curabox__c];
        map<id, curabox__c> cbMap = new Map<id, curabox__c>(lsCB);

        system.debug('#####' + alleKunden.size());
        map<id, product__c> prMap = new map<id, product__c>();
        List<Product__c> prList = [SELECT id, Price__c, Hilfsmittelpositionsnummer__c, Product_Group__c, volume_unit__c
                                    FROM Product__c
                                    WHERE standard_article_for_curabox__c = true
                                    // AND Hilfsmittelgruppe__c = '54'
                                    ];
        if((prList != null) && (prList.size() > 0)) {
            for(Product__c p : prList) {
                prMap.put(p.Product_Group__c, p);
            }
        }
        Map<String, List<Curabox_Product_Group__c>> apVorlage = new Map<String, List<Curabox_Product_Group__c>>();
        List<Curabox_Product_Group__c> cbpgList = [SELECT Curabox__c, Curabox__r.name, default_number__c, Product_Group__c 
                                                        FROM Curabox_Product_Group__c
                                                        ORDER BY Curabox__r.name];
        String tempCB = null;
        List<Curabox_Product_Group__c> listToInsert = new List<Curabox_Product_Group__c>();
        for(Curabox_Product_Group__c g : cbpgList) {

            if(g.Curabox__r.name != tempCB) {
                if(tempCB != null) {                   
                    apVorlage.put(tempCB, listToInsert);
                    listToInsert = new List<Curabox_Product_Group__c>();
                }               
            }
            listToInsert.add(g);
            tempCB = g.Curabox__r.name;
        }  
        // last curabox
        if(!listToInsert.isEmpty()) {
            apVorlage.put(tempCB, listToInsert);
        }                         
        

        List<recordType> rtList =[select id, name,sobjecttype from recordType where name ='Curabox' and sobjecttype  = 'Opportunity' limit 1];
        recordType rt = rtList [0];
        List<Opportunity> opList = new List<Opportunity>();
        // jeder 2. bekommt CB und KUWV
        integer ic = 0;
        for(contact c : alleKunden) {        
            opportunity opp = new opportunity();
            opp.name = 'Curabox';
            opp.accountid = c.accountid;
            opp.OM_Referrer__c ='Curabox';
            opp.RecordTypeId =rt.Id;
            opp.StageName = 'Closed Won';          
            opp.CloseDate = date.today();
            opList.add(opp);
           
            if(math.mod(ic, 2) > 0) {
                opp = new opportunity();
                opp.name = 'KUWV';
                opp.accountid = c.accountid;
                opp.OM_Referrer__c ='KUWV';
                opp.RecordTypeId =rt.Id;
                opp.StageName = 'Closed Won';          
                opp.CloseDate = date.today();
                opList.add(opp);                
            }
            ic++;
            ctMap.put(c.AccountId, c);
        }
        Database.SaveResult[]  srList = Database.insert(opList, false); 
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {  
                
            }
        }        
        List<Opportunity> opiList = [SELECT id, name, OM_Referrer__c, accountid FROM Opportunity LIMIT 200];
        system.debug('#####' + opiList.size());
        List<Order__c> odList = new List<Order__c>();
        for(Opportunity op : opiList) {
            Order__c order = new Order__c(Opportunity__c=op.id);
            order.Contact__c=ctMap.get(op.accountId).id;
            order.Status__c = 'aktiv';
            order.Liefertag__c = date.today();

            order.Description__c = cbMap.get(ctMap.get(op.accountId).Wunschbox__c).Name;
            system.debug('#######alex2002 ' + op.OM_Referrer__c);
            
            if(op.OM_Referrer__c == 'KUWV') {
                order.Nach_Paragraph__c = '51';
                order.Delivery_frequency__c = 'jährlich';
                order.Description__c = 'KUWV';
            }
            else {
                order.Nach_Paragraph__c = '54';
                order.Delivery_frequency__c = 'monatlich';
            }
            odList.add(order);
        }
        srList = Database.insert(odList, false); 
        integer odIndex = 0;
        List<Order_Line__c> olList = new List<Order_Line__c>();
        for (Database.SaveResult sr : srList) {
            
            if (sr.isSuccess()) {  
                id odid = sr.getId();
                try {
                    List<Curabox_Product_Group__c> apl = apVorlage.get(odList[odIndex].Description__c); 
                    system.debug('#############alex2000 odList[odIndex].Description__c=' +odList[odIndex].Description__c);
                    system.debug('#############alex2001 apl.size()=' + apl.size());
                    for(Curabox_Product_Group__c p : apl) {
                        Order_Line__c ol = new Order_Line__c(Order__c=odid);
                        ol.Product__c = prMap.get(p.Product_Group__c).id;
                        if(p.default_number__c == null) p.default_number__c = 1; 
                        ol.Gen_Menge_Stk_Mon__c =p.default_number__c;
                        ol.Price__c = ol.Gen_Menge_Stk_Mon__c * prMap.get(p.Product_Group__c).Price__c;
                        olList.add(ol);
                    }  
                }
                catch(System.Exception e) {
                    system.debug('##############alex1500 ' + odList[odIndex].Description__c);
                }              
            }
            odIndex++;
        } 
        srList = Database.insert(olList, false); 
        // Füe alle Orders leiefermengeReduzierung
        List<LiefermengeReduzierung__c> lmrList = new List<LiefermengeReduzierung__c>();String curaboxName = 'CB6 - Flexibel';
        List<Order__c> odlList = [select id, contact__c, Description__c, (SELECT id, product__c, Gen_Menge_Stk_Mon__c FROM Order_Lines__r) 
                            from order__c where status__c = 'aktiv'
                            AND Description__c != 'KUWV'];
        for(Order__c od : odlList) {
            List<string> sList = new List<String>();
            for(Order_Line__c ol : od.Order_Lines__r) {
                sList.add(ol.product__c + string.valueOf(ol.Gen_Menge_Stk_Mon__c));
            }
            sList.sort();
            String sKey = od.Description__c + String.join(sList, ''); 
            String MD5key = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(sKey)));
            // Erstellen Satz pro Produkt
            for(Order_Line__c ol : od.Order_Lines__r) {
                LiefermengeReduzierung__c lmr = new LiefermengeReduzierung__c();
                lmr.Product__c = ol.product__c;
                lmr.CuraboxName__c = od.Description__c;
                lmr.key__c = MD5key;
                lmr.Menge__c = ol.Gen_Menge_Stk_Mon__c;
                lmr.Liefermenge_alt__c = ol.Gen_Menge_Stk_Mon__c;
                lmr.Liefermenge_neu__c = ol.Gen_Menge_Stk_Mon__c;
                lmr.valid_from__c = date.today();
                lmr.valid_to__c = date.newInstance(4000,12,31);
                lmrList.add(lmr);               
            }
        }
        insert lmrList;
    }

    public static void createDeliverLinesBedarf() {
        List<Delivery_Line__c> dlList = new List<Delivery_Line__c>();
        List<Order_Line__c> oliList = [SELECT id, Product__c, Gen_Menge_Stk_Mon__c, Order__r.Contact__c
                                        FROM Order_Line__c
                                        LIMIT 1000];

        system.debug('##### oliList=' + oliList.size());
        for(Order_Line__c ol : oliList) {
            Delivery_Line__c dl = new Delivery_Line__c(Order_line__c=ol.id, Quantity__c=ol.Gen_Menge_Stk_Mon__c, Contact__c=ol.Order__r.Contact__c);
            dl.Product__c = ol.Product__c;
            dl.Delivery_date__c = date.today();
            dl.Delivery_status__c = 'Bedarf';
            dlList.add(dl);
        }

        Database.SaveResult[] srList = Database.insert(dlList, false);         
    }

    public static void createFamilyFromBetreuer() {
        list<RecordType> fam_rtList = [SELECT Id FROM RecordType WHERE Name = 'Pflege.de - Familien'];
        list<RecordType> con_rtList = [SELECT Id FROM RecordType WHERE Name = 'Familienangehörige'];
        Account testFamilie = new Account(RecordTypeId = fam_rtList[0].id, Name = 'Mustermann-Betreuer - Familie');   
        insert testFamilie;
        Contact testBetreuer = new Contact( 
                    RecordTypeId = con_rtList[0].id,
                    lastname = 'Mustermann-Betreuer',
                    firstname = 'test_firstname',
                    AccountId = testFamilie.Id,
                    Email = 'testbb@test.de',
                    Phone = '0123456789',
                    MailingStreet = 'contactstreet b',
                    MailingPostalCode='23456',
                    MailingCity='contactcity',
                    // Kranken_Pflegekasse__c=KK.id,
                    Versicherungsnummer__c='VERSNR01234567',
                    Birthdate=date.today().addYears(-60),
                    Art_des_Kontakts__c = 'Ansprechpartner'
                    );  
        insert testBetreuer;
        Contact testContact = new Contact( 
                    RecordTypeId = con_rtList[0].id,
                    lastname = 'Mustermann',
                    firstname = 'test_firstname',
                    AccountId = testFamilie.Id,
                    Email = 'testct@test.de',
                    Phone = '0123456789',
                    MailingStreet = 'contactstreet b',
                    MailingPostalCode='23456',
                    MailingCity='contactcity',
                    // Kranken_Pflegekasse__c=KK.id,
                    Versicherungsnummer__c='VERSNR01234567',
                    Birthdate=date.today().addYears(-60),
                    Art_des_Kontakts__c = 'Pflegebedürftige',
                    Betreuer__c = testBetreuer.id 
                    );  
        insert testContact;
    }
}