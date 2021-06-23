//****************************************************************************************************************************
// Erstellt tt.mm.yyyy von YY
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
// Sorgt für das Anlegen der Anschriften
//
//
//****************************************************************************************************************************
//Änderungen:
//
// wds  6.11.2012 Zuzahlung befreit wird automatisch in Abhängigkeit des Datums gesetzt!deployed!
// wds 28.09.2013 ACR 153 Plegedienst und Betreuer lassen sich nicht löschen!
// wds 03.03.2015 Adresse "Betreuer" auf standard Adresse gesetzt (ab zeile 340) statt Other Adress!
// wds 05.03.2015 Haken für Standardlieferanschrift wurde bei Änderungennicht mehr gesetzt! Abfrage geändert siehes Eintrag wds1
//                zusätzlich Änderungen auf Telefon etc rausgenommen!
//
// AM  02.04.2015 Status__c wird auf 'Kündigung' gesetzt, wenn Abbestellungsdatum__c != null
//
// wds 22.04.2015 #106 Auch neue Adresse, wenn Name sich ändert
//
// wds 27.04.2015 #106 Es sollen die Anschriften aktualisiert werden (Kunde) und nicht neu angelegt werden
//
//
// am 12.05.2015 #135
// wds 23.06.2015 #153 eingefügt!
// BT 25.08.2015 #100636896. Anpassung Kundenstatus
// AM 30.06.2016 case 00001091 Standardlieferanschrift soll nicht geändert werden ( in update_kunden) 
//****************************************************************************************************************************
public with sharing class Adressverwaltung_class {
   
//  hier werden für jeden Kunden die Heimatadresse in die Anschriften übernommen und als Standardadresse gesetzt, ausserdem werden Betreuer- und Pflegedienst-
//  adressen in die Anschriften übernommen
//    private static list<freie_Kundennummer__c> freeNumbers;
    private static Boolean enableKN = false;
    // static var für trigger, damit die Adressen, die aus den funktionen hier
    // bearbeitet werden nicht nochmal vom trigger betroffen sind
    public static Boolean AdressenUpdated = false;

    public static void insert_neue_kunden(List<Kunde__c> Kunden) {
        try {
            set<id> betrSet = new Set<id>();    
            set<id> vertSet = new Set<id>();    
            set<id> pdSet = new Set<id>();    
            Map<id, contact> betrMap = new Map<id, contact>();
            Map<id, contact> vertMap = new Map<id, contact>();
            Map<id, account> pdMap = new Map<id, account>();
            For (Kunde__c kd : Kunden) {
                if(kd.Betreuer__c != null) betrSet.add(kd.Betreuer__c);
                if(kd.ges_Vertreter__c != null) vertSet.add(kd.ges_Vertreter__c);
                if(kd.Pflegedienst__c != null) pdSet.add(kd.Pflegedienst__c);
            }
            if(!betrSet.isEmpty()) {
                List<Contact> bcL = [select Phone, MailingCity, MailingPostalCode, MailingCountry,
                                Mailingstreet, OtherStreet, OtherPostalCode, OtherCountry, 
                                OtherCity, Id, Fax, Email, Name 
                                from Contact 
                                where ID IN: betrSet];
                if((bcl != null) && (bcl.size() > 0)) {
                    for(contact c : bcl) {
                        betrMap.put(c.id, c);
                    }
                }
                
            }
            if(!vertSet.isEmpty()) {
                List<Contact> vcL = [select Phone, MailingCity, MailingPostalCode, MailingCountry,
                                Mailingstreet, OtherStreet, OtherPostalCode, OtherCountry, 
                                OtherCity, Id, Fax, Email, Name 
                                from Contact 
                                where ID IN: vertSet];
                if((vcl != null) && (vcl.size() > 0)) {
                    for(contact c : vcl) {
                        vertMap.put(c.id, c);
                    }
                }
            }
            if(!pdSet.isEmpty()) {
                list<Account> aList = [select Phone, BillingStreet, BillingPostalCode, 
                                BillingCountry, BillingCity, ShippingStreet, ShippingPostalCode, 
                                ShippingCountry, ShippingCity, Id, Fax, Zugang_letzter_Kunde__c, Name 
                                from Account 
                                where id IN: pdSet];
                if((aList != null) && (aList.size() > 0)) {
                    for(account a : aList) {
                        pdMap.put(a.id, a);
                    }
                }
            }

            List<Anschrift__c> Anschriften = new List<Anschrift__c>{}; 
            Anschrift__c AnVorl;
    //      für alle Kunden        
            For (Kunde__c kd : Kunden) {
    //                
    //          Kundenadresse als Standardfieferanschrift eintragen
                AnVorl = new Anschrift__c();
                AnVorl.Name = kd.Name;
                AnVorl.Kunde__c = kd.ID;
                AnVorl.Art_der_Anschrift__c = 'Kundenadresse';
                AnVorl.e_mail__c = kd.e_mail__c;
                AnVorl.Fax__c = kd.Fax__c;
                AnVorl.Hausnummer__c = kd.Hausnummer__c;
                AnVorl.Ort__c = kd.Ort__c;
                // AnVorl.PLZ__c = string.valueOf(kd.PLZ__c);
                AnVorl.PLZ__c = ksgFunctions.formatPLZ(kd.PLZ__c);
                AnVorl.Stra_e__c = kd.Stra_e__c;
                AnVorl.Telefon__c = kd.Telefon__c;
                if (kd.Lieferadresse__c == 'Adresse Patient' || kd.Lieferadresse__c == null){
                    AnVorl.Standardlieferanschrift__c = true;
                }
                else
                {
                    AnVorl.Standardlieferanschrift__c = false;
                }
                AnVorl.Standardrechnungsanschrift__c = True;
                Anschriften.add(AnVorl);
    //          falls Betreuer nicht null, dann BetreuerAdresse eintragen
                If (kd.Betreuer__c != null) {
                    // Contact c = [select Phone, MailingCity, MailingPostalCode, MailingCountry,
                    //             Mailingstreet, OtherStreet, OtherPostalCode, OtherCountry, 
                    //             OtherCity, Id, Fax, Email, Name from Contact 
                    //             where ID =: kd.Betreuer__c];
                    Contact c = betrMap.get(kd.Betreuer__c);
                    if(c != null){
                        AnVorl = new Anschrift__c();
                        AnVorl.Kunde__c = kd.ID;
                        AnVorl.Name = c.Name;
                        AnVorl.Art_der_Anschrift__c = 'Betreuer';
                        AnVorl.e_mail__c = c.Email;
                        AnVorl.Fax__c = c.Fax;
                        AnVorl.Ort__c = c.MailingCity;
                        AnVorl.PLZ__c = c.MailingPostalCode;
                        AnVorl.Stra_e__c = c.MailingStreet;
                        AnVorl.Telefon__c = c.Phone;
                        if (kd.Lieferadresse__c == 'Adresse Pflegeperson'){
                            AnVorl.Standardlieferanschrift__c = true;
                        }
                        else
                        {
                            AnVorl.Standardlieferanschrift__c = false;
                        }
                        AnVorl.Standardrechnungsanschrift__c = false;
                        Anschriften.add(AnVorl);
                        if ( c.otherCity != null || c.otherStreet != null || c.otherPostalCode != null){
                            AnVorl = new Anschrift__c();
                            AnVorl.Kunde__c = kd.ID;
                            AnVorl.Name = c.Name + ' weitere Adresse ';
                            AnVorl.Art_der_Anschrift__c = 'Betreuer';
                            AnVorl.e_mail__c = c.Email;
                            AnVorl.Fax__c = c.Fax;
                            AnVorl.Ort__c = c.OtherCity;
                            AnVorl.PLZ__c = c.OtherPostalCode;
                            AnVorl.Stra_e__c = c.OtherStreet;
                            AnVorl.Telefon__c = c.Phone;
                            AnVorl.Standardlieferanschrift__c = false;
                            AnVorl.Standardrechnungsanschrift__c = false;
                            Anschriften.add(AnVorl);
                        }
                    }
                }   
                
                If (kd.ges_Vertreter__c != null && kd.ges_Vertreter__c != kd.Betreuer__c) {
                    // Contact c = [select Phone, MailingCity, MailingPostalCode, MailingCountry,
                    //             Mailingstreet, OtherStreet, OtherPostalCode, OtherCountry, 
                    //             OtherCity, Id, Fax, Email, Name from Contact 
                    //             where ID =: kd.ges_Vertreter__c];
                    Contact c = vertMap.get(kd.ges_Vertreter__c);
                    if(c != null){
                        AnVorl = new Anschrift__c();
                        AnVorl.Kunde__c = kd.ID;
                        AnVorl.Name = c.Name;
                        AnVorl.Art_der_Anschrift__c = 'gesetzl. Vertreter';
                        AnVorl.e_mail__c = c.Email;
                        AnVorl.Fax__c = c.Fax;
                        AnVorl.Ort__c = c.MailingCity;
                        AnVorl.PLZ__c = c.MailingPostalCode;
                        AnVorl.Stra_e__c = c.MailingStreet;
                        AnVorl.Telefon__c = c.Phone;
                        AnVorl.Standardlieferanschrift__c = false;
                        AnVorl.Standardrechnungsanschrift__c = false;
                        Anschriften.add(AnVorl);
                        if ( c.otherCity != null || c.otherStreet != null || c.otherPostalCode != null){
                            AnVorl = new Anschrift__c();
                            AnVorl.Kunde__c = kd.ID;
                            AnVorl.Name = c.Name + ' weitere Adresse ';
                            AnVorl.Art_der_Anschrift__c = 'gesetzl. Vertreter';
                            AnVorl.e_mail__c = c.Email;
                            AnVorl.Fax__c = c.Fax;
                            AnVorl.Ort__c = c.OtherCity;
                            AnVorl.PLZ__c = c.OtherPostalCode;
                            AnVorl.Stra_e__c = c.OtherStreet;
                            AnVorl.Telefon__c = c.Phone;
                            AnVorl.Standardlieferanschrift__c = false;
                            AnVorl.Standardrechnungsanschrift__c = false;
                            Anschriften.add(AnVorl);
                        }
                    }
                }   
    //          falls Pflegedienst nicht null, dann PflegedienstAdresse eintragen   
                If (kd.Pflegedienst__c != null) {
                system.debug('##wds Pflege.de  Pflegedienst'  +kd.pflegedienst__c);
                    // list<Account> aList = [select Phone, BillingStreet, BillingPostalCode, 
                    //             BillingCountry, BillingCity, ShippingStreet, ShippingPostalCode, 
                    //             ShippingCountry, ShippingCity, Id, Fax, Zugang_letzter_Kunde__c, Name from Account 
                    //             where id =: kd.Pflegedienst__c LIMIT 1];
                    // if((aList != null) && (aList.size() == 1)) {
                    
                        // Account a = aList[0];

                        Account a = pdMap.get(kd.Pflegedienst__c);
                        system.debug('#######lex5000 ' + a);
                        a.Zugang_letzter_Kunde__c = date.today();
                        update a;            
                        if(a != null) {
                            AnVorl = new Anschrift__c();
                            AnVorl.Kunde__c = kd.ID;
                            AnVorl.Name = a.Name;
                            AnVorl.Art_der_Anschrift__c = 'Pflegedienst';
                            AnVorl.Fax__c = a.Fax;
                            AnVorl.Telefon__c = a.Phone;
                            AnVorl.Ort__c = a.BillingCity;
                            AnVorl.PLZ__c = a.BillingPostalCode;
                            AnVorl.Stra_e__c = a.BillingStreet;
                            AnVorl.Standardlieferanschrift__c = false;
                            AnVorl.Standardrechnungsanschrift__c = false;
                            Anschriften.add(AnVorl);
                            if (a.shippingCity != null || a.shippingStreet != null || a.ShippingPostalcode != null){
                                AnVorl = new Anschrift__c();
                                AnVorl.Kunde__c = kd.ID;
                                AnVorl.Name = a.Name + ' weitere Adresse ';
                                AnVorl.Art_der_Anschrift__c = 'Pflegedienst';
                                AnVorl.Fax__c = a.Fax;
                                AnVorl.Ort__c = a.ShippingCity;
                                AnVorl.PLZ__c = a.ShippingPostalCode;
                                AnVorl.Stra_e__c = a.ShippingStreet;
                                AnVorl.Telefon__c = a.Phone;
                                AnVorl.Standardlieferanschrift__c = false;
                                AnVorl.Standardrechnungsanschrift__c = false;
                                Anschriften.add(AnVorl);
                            }
                        }
                    // }   
                    
                }
            }
    //          insert der Adressen
            Try {
                insert Anschriften;
            }catch (system.Dmlexception d){
                system.debug('#######################Adressverwaltung Anschriften insert hat nicht geklappt\n'+d);
            } 

        }
        catch (system.Exception e){
            system.debug(LoggingLevel.ERROR, '####################### e='+e);
        } 
    }
    
    public static void neueKundennummer(List<Kunde__c> Kunden){
        
/*        list<freie_Kundennummer__c> numbersToRemove = 
                                new list<freie_Kundennummer__c>{};
        freie_Kundennummer__c fkn;
        For (Kunde__c kd : Kunden) {
            if(enableKN){
                if(freeNumbers==null || freeNumbers.size()==0){
                    freeNumbers = [Select Kundennummer__c, Id 
                        From freie_Kundennummer__c LIMIT 100];
                }
                if(freeNumbers==null || freeNumbers.size()==0){
                    freeNumbers = new List<freie_Kundennummer__c>{};
                    List<Kunde__c> kun;
                    if(kun==null){
                        kun = [select ID, Kundennummer__c from Kunde__c LIMIT 89000];
                    }
                    Set<Decimal> existNumbers = new Set<Decimal>{};
                    system.debug('Anzahl der Kunden: '+kun.size());               
                    for(Kunde__c k : kun){
                        existNumbers.add(k.Kundennummer__c);
                    }
                    for(Decimal i=10000;i<=99000;i++){
                        if(!existNumbers.contains(i)){
                            fkn = new freie_Kundennummer__c(Kundennummer__c = i);
                            freeNumbers.add(fkn);
                        }
                        if(freeNumbers.size()==100 || i==99000){
                            //system.debug('Jumped at: '+i);
                            try{
                              insert freeNumbers;
                            }catch(Exception e){
                                system.debug('Insert freeNumbers fail!: '+e);
                            }
                            break;
                        }
                    }
                    //system.debug('KunNum: '+existNumbers);
                }
                fkn = freeNumbers.get(0);
                numbersToRemove.add(fkn);
                freeNumbers.remove(0);
                //system.debug('KunNumToRemove: '+numbersToRemove);
            }
//          KundenNummer vergeben
         if(fkn!=null){
            kd.Kundennummer__c = fkn.Kundennummer__c;
         }
         }
         Try {
           if(enableKN){
            delete numbersToRemove;
           }
        }catch (system.Dmlexception d){
            system.debug('#######################Adressverwaltung Anschriften insert hat nicht geklappt\n'+d);
        }*/
    }
    
    public static void update_kunden(List<Kunde__c> KundenOld, 
                                       List<Kunde__c> KundenNew) {

    try {                                       
        List<Anschrift__c> AnschToCreate = new List<Anschrift__c>{};
        List<Anschrift__c> AnschToUpdate = new List<Anschrift__c>{};
        Anschrift__c AnVorl;
        for(Integer i = 0; i<KundenOld.size(); i++) {
                // befreit bis überprüfen /wds
                datetime Tagesdatum = datetime.now();
                system.debug('##wds Zuzahlung befreit bis'+KundenNew.get(i).Zuzahlung_befreit_bis__c);
                system.debug('##wds i:'+i);
                system.debug('##wds Zuhzahlung befreit ' +KundenNew.get(i).Zuzahlung_befreit__c);
                if(Tagesdatum<KundenNew.get(i).Zuzahlung_befreit_bis__c)
                    {KundenNew.get(i).Zuzahlung_befreit__c=true;}
                else
                    {KundenNew.get(i).Zuzahlung_befreit__c=false;}
                KundenNew.get(i).name=KundenNew.get(i).Name__c+', ' + KundenNew.get(i).Vorname__c;
                //Kundenadresse wurde geändert
                Boolean b = KundenOld.get(i).e_mail__c     != KundenNew.get(i).e_mail__c ||
                            KundenOld.get(i).name__c       != KundenNew.get(i).name__c ||
                            KundenOld.get(i).vorname__c    != KundenNew.get(i).vorname__c ||
                            KundenOld.get(i).Hausnummer__c != KundenNew.get(i).Hausnummer__c ||
                            KundenOld.get(i).Ort__c        != KundenNew.get(i).Ort__c ||
                            KundenOld.get(i).PLZ__c        != KundenNew.get(i).PLZ__c ||
                            KundenOld.get(i).Stra_e__c     != KundenNew.get(i).Stra_e__c;
                boolean changed_LA =
                KundenOld.get(i).Lieferadresse__c != KundenNew.get(i).Lieferadresse__c;
                system.debug('#######HK changed_LA ' + Changed_LA);
                system.debug('#######HK b ' + b);
                if(b || changed_LA) {
                    List<Anschrift__c> userAns = [select ID,Standardlieferanschrift__c, Art_der_Anschrift__c  
                                    from Anschrift__c where Kunde__c =:  KundenOld.get(i).ID];
                    for(Anschrift__c ans: userAns) {
                        //wds1 hier !b auf b geändert!
                        if (b) {
                            system.debug('#######HK not b ');
                            system.debug('#######HK Lieferadresse ' + KundenNew.get(i).Lieferadresse__c);
                            system.debug('#######HK Art der Anschrift ' + ans.Art_der_Anschrift__c);
                            if ( KundenNew.get(i).Lieferadresse__c == 'Adresse Patient' ||
                                 KundenNew.get(i).Lieferadresse__c == null){
                                 if (ans.Art_der_Anschrift__c == 'Kundenadresse'){
                                    // ans.Standardlieferanschrift__c = true;
                                 }
                                 else {
                                    // ans.Standardlieferanschrift__c = false;
                                 }
                            }
                            if ( KundenNew.get(i).Lieferadresse__c == 'Adresse Pflegeperson'){
                                if ( KundenNew.get(i).Betreuer__c != null){
                                    if (ans.Art_der_Anschrift__c == 'Betreuer'){
                                        // ans.Standardlieferanschrift__c = true;
                                    }
                                    else {
                                        // ans.Standardlieferanschrift__c = false;
                                    }
                                }
                                else{
                                    kundenNew.get(i).addError(' Es ist keine private Pflegeperson angegeben, bitte geben sie zunächst eine private Pflegeperson ein! ');
                                }                               
                            }                           
                            system.debug('#######HK Update Anschrift bei not b ' + ans);
                        }
                        else{
                            // ans.Standardlieferanschrift__c = false;
                            system.debug('#######HK Update Anschrift bei b ' + ans);
                        }
                        // ans.Standardrechnungsanschrift__c = false;
                        system.debug('#######HK Update Anschrift ' + ans);
                        //wds                        AnschToUpdate.add(ans);
                    }
                    if (!Changed_LA) {
                        AnVorl = new Anschrift__c();
                        // AnVorl.Name = 'Neue Kundenadresse';
                        list<Anschrift__c> anList = [select Id from Anschrift__c 
                                WHERE name =: KundenOld.get(i).name
                                AND Kunde__c =:  KundenOld.get(i).ID
                                LIMIT 1];
                        if((anList != null) && (anList.size() > 0)) {   
                            Anschrift__c a = anList[0];
                            //                        Anschrift__c a = [select Id from Anschrift__c 
                            //                                WHERE name =: KundenOld.get(i).name
                            //                                AND Kunde__c =:  KundenOld.get(i).ID
                            //                                LIMIT 1];
                            //                        if(a != null) {
                            AnVorl.id = a.id;
                            AnVorl.Name = KundenNew.get(i).name;
                            //                       AnVorl.Kunde__c = KundenNew.get(i).ID;
                            AnVorl.Art_der_Anschrift__c = 'Kundenadresse';
                            AnVorl.e_mail__c = KundenNew.get(i).e_mail__c;
                            AnVorl.Fax__c = KundenNew.get(i).Fax__c;
                            AnVorl.Hausnummer__c = KundenNew.get(i).Hausnummer__c;
                            AnVorl.Ort__c = KundenNew.get(i).Ort__c;
                            // AnVorl.PLZ__c = string.valueOf(KundenNew.get(i).PLZ__c);
                            AnVorl.PLZ__c = ksgFunctions.formatPLZ(KundenNew.get(i).PLZ__c);
                            AnVorl.Stra_e__c = KundenNew.get(i).Stra_e__c;
                            AnVorl.Telefon__c = KundenNew.get(i).Telefon__c;
                            if (KundenNew.get(i).Lieferadresse__c == 'Adresse Kunde' || KundenNew.get(i).Lieferadresse__c == null){
                                // AnVorl.Standardlieferanschrift__c = true;
                            }
                            else
                            {
                                // AnVorl.Standardlieferanschrift__c = false;
                            }
                            // AnVorl.Standardrechnungsanschrift__c = true;
                            AnschtoUpdate.add(AnVorl);
                                //                        AnschToCreate.add(AnVorl);
                        }
                    }
                }    
                //Betreuer wurde geaendert
                if(KundenOld.get(i).Betreuer__c != KundenNew.get(i).Betreuer__c && KundenNew.get(i).Betreuer__c != Null){
                    Contact c = [select Phone, MailingCity, MailingPostalCode, MailingCountry,
                                Mailingstreet, OtherStreet, OtherPostalCode, OtherCountry, 
                                OtherCity, Id, Fax, Email, Salutation, Name from Contact 
                                where ID =: KundenNew.get(i).Betreuer__c];
                   
                                
                    if(c != null){
                        AnVorl = new Anschrift__c();
                        AnVorl.Kunde__c = KundenNew.get(i).ID;
                        AnVorl.Name = c.Name;
                        AnVorl.Art_der_Anschrift__c = 'Betreuer';
                        AnVorl.e_mail__c = c.Email;
                        AnVorl.Fax__c = c.Fax;
                        AnVorl.Ort__c = c.MailingCity;
                        AnVorl.PLZ__c = c.MailingPostalCode;
                        AnVorl.Stra_e__c = c.MailingStreet;
                        AnVorl.Telefon__c = c.Phone;
                        AnVorl.Anrede__c = c.Salutation;
                        if (KundenNew.get(i).Lieferadresse__c == 'Adresse Pflegeperson'){
                            // AnVorl.Standardlieferanschrift__c = true;
                        }
                        else
                        {
                            // AnVorl.Standardlieferanschrift__c = false;
                        }
                        // AnVorl.Standardrechnungsanschrift__c = false;
                        AnschToCreate.add(AnVorl);
                    }
                }
                //Pflegedienst wurde geaendert
                if(KundenOld.get(i).Pflegedienst__c != KundenNew.get(i).Pflegedienst__c &&  KundenNew.get(i).Pflegedienst__c != Null ){
                    Account a = [select Phone, BillingStreet, BillingPostalCode, 
                                BillingCountry, BillingCity, Id, Fax, zugang_letzter_Kunde__c, Name from Account 
                                where ID =: KundenNew.get(i).Pflegedienst__c];
                                a.Zugang_letzter_Kunde__c = date.today();
                    update a; 
                    if(a != null){
                        AnVorl = new Anschrift__c();
                        AnVorl.Kunde__c = KundenNew.get(i).ID;
                        AnVorl.Name = a.Name;
                        AnVorl.Art_der_Anschrift__c = 'Pflegedienst';
                        AnVorl.Fax__c = a.Fax;
                        AnVorl.Ort__c = a.BillingCity;
                        AnVorl.PLZ__c = a.BillingPostalCode;
                        AnVorl.Stra_e__c = a.BillingStreet;
                        AnVorl.Telefon__c = a.Phone;
                        // AnVorl.Standardlieferanschrift__c = false;
                        AnVorl.Standardrechnungsanschrift__c = false;
                        AnschToCreate.add(AnVorl);
                    }
                }
                if(KundenNew.get(i).Abbestellungsdatum__c != null) {
                    try {
                        Kundenstatus__c ks = [SELECT id, Status__c, Produktgruppe__c 
                                            FROM Kundenstatus__c 
                                            WHERE Kunde__c = :KundenNew.get(i).id AND Produktgruppe__c = :KundenNew.get(i).Produktgruppe__c];
                        ks.Status__c = 'Kündigung';                    
                        //KundenNew.get(i).Status__c = 'Kündigung';
                    }
                    catch (System.Exception e) {}
                }
            
            }
        try {
            insert AnschToCreate;
            AdressenUpdated = true;
             system.debug('#######################Adressverwaltung   wds'+AdressenUpdated);
            update AnschToUpdate;
            
             system.debug('#######################Adressverwaltung   wds'+AdressenUpdated);
        }catch (system.Dmlexception d){
            system.debug('#######################Adressverwaltung Anschriften update hat nicht geklappt\n'+d);
        }
       
            }
        catch (system.Exception e){
            system.debug(LoggingLevel.ERROR, '####################### e='+e);
        }             
                
    }
    
    public static void insert_neue_adressen(List<Anschrift__c> adr) {
        try {

            List<Anschrift__c> AnschToUpdate = new List<Anschrift__c>{};
            Anschrift__c AnVorl;
            for(Anschrift__c adrNew : adr){
                if(adrNew.Standardlieferanschrift__c == true && adrNew.Standardrechnungsanschrift__c == true){
                List<Anschrift__c> userAns = [select ID,Standardlieferanschrift__c, Standardrechnungsanschrift__c, Kunde__c 
                                    from Anschrift__c where Kunde__c =:  adrNew.Kunde__c];
                    for(Anschrift__c an : userAns){
                        an.Standardlieferanschrift__c = false;
                        an.Standardrechnungsanschrift__c = false;
                        AnschToUpdate.add(an);
                    } 
                }
                else
                {
                    if(adrNew.Standardlieferanschrift__c == true && adrNew.Standardrechnungsanschrift__c == false){
                    List<Anschrift__c> userAns = [select ID,Standardlieferanschrift__c, Kunde__c 
                                        from Anschrift__c where Kunde__c =:  adrNew.Kunde__c];
                    for(Anschrift__c an : userAns){
                        an.Standardlieferanschrift__c = false;
                        AnschToUpdate.add(an);
                }
                    }
                        else
                            {if(adrNew.Standardlieferanschrift__c == false && adrNew.Standardrechnungsanschrift__c == true){
                            List<Anschrift__c> userAns = [select ID,Standardrechnungsanschrift__c, Kunde__c 
                                                from Anschrift__c where Kunde__c =:  adrNew.Kunde__c];
                            for(Anschrift__c an : userAns){
                                an.Standardrechnungsanschrift__c = false;
                                AnschToUpdate.add(an);
                            }
                            }
                            }
                    }
                }
            Try {
                update AnschToUpdate;
            }catch (system.Dmlexception d){
                system.debug('#######################Adressverwaltung Anschriften update hat nicht geklappt\n'+d);
            }
        }       
        catch (system.Exception e){
            system.debug(LoggingLevel.ERROR, '####################### e='+e);
        } 
    }
    
    // After Update trigger für Anschriften!!!!
    // wds 20.9.12
    
    public static void update_adressen(List<Anschrift__c> adrOld, 
                                       List<Anschrift__c> adrNew) {
        try {

        Map<Id, Anschrift__c> AnschToUpdate = new Map<Id, Anschrift__c>{};
        Anschrift__c AnVorl;
        for(Integer i = 0; i<AdrOld.size(); i++){
            system.debug('#####wds'+adrNew.get(i).Standardrechnungsanschrift__c);
            if(adrNew.get(i).Standardrechnungsanschrift__c == true){
              List<Anschrift__c> userAns = [select ID,Standardrechnungsanschrift__c, Kunde__c 
                                from Anschrift__c where Kunde__c =:  adrNew.get(i).Kunde__c  and ID != :adrNew.get(i).id];
                                
              for(Anschrift__c an : userAns){
                an.Standardrechnungsanschrift__c = false;
                AnschToUpdate.put(an.Id,an);
              }
            }
            if(adrNew.get(i).Standardlieferanschrift__c == true){
                  List<Anschrift__c> userAns = [select ID,Standardlieferanschrift__c, Kunde__c 
                                    from Anschrift__c where Kunde__c =:  adrNew.get(i).Kunde__c and ID != :adrNew.get(i).id];
                  for(Anschrift__c an : userAns){
                    if(AnschToUpdate.get(an.Id) != null){
                        an = AnschToUpdate.get(an.Id);
                    }
                    an.Standardlieferanschrift__c = false;
                    AnschToUpdate.put(an.Id,an);
                    }
            }
        }
        List<Anschrift__c> AnschToUpdateList = new List<Anschrift__c>();
        AnschToUpdateList = AnschToUpdate.values();
        AdressenUpdated = true;
        Try {
            update AnschToUpdateList;
        }catch (system.Dmlexception d){
            system.debug('#######################Adressverwaltung Anschriften update hat nicht geklappt\n'+d);
        }     
        }
        catch (System.Exception e) {
             system.debug(LoggingLevel.ERROR, '####################### e='+e);
        }

    }
    
    public static void delete_adressen(List<Anschrift__c> adr) {
        try {
        List<Anschrift__c> AnschToUpdate = new List<Anschrift__c>{};
        Anschrift__c AnVorl;
        Anschrift__c adrnew;
        Boolean found = false;
        list<anschrift__c> templist;
        list<anschrift__c> todellist;
        set<id> usridset = new set<id>{};
        map<id, list<anschrift__c>> usransmap = new map<id, list<anschrift__c>>{};
        map<id, list<anschrift__c>> todelmap = new map<id, list<Anschrift__c>>{};
        
        for(Anschrift__c a : adr){
            templist = new list<anschrift__c>{};
            if(a.Standardlieferanschrift__c == true || a.Standardrechnungsanschrift__c == true){
                if (todelmap.containskey(a.kunde__c)){
                    templist = todelmap.get(a.Kunde__c);
                }
                templist.add(a);
                todelmap.put(a.Kunde__c, templist);
                if (!usridset.contains(a.Kunde__c)){
                    usridset.add(a.Kunde__c);
                }
            }
        }
        system.debug('############## delete anschr. usridset ' + usridset);

        List<Anschrift__c> userAns = [select ID,Standardlieferanschrift__c,Standardrechnungsanschrift__c, Kunde__c,
                Art_der_Anschrift__c from Anschrift__c where Kunde__c in: usridset];
        system.debug('############## delete anschr. anz Ansch ' + userans.size());
        system.debug('############## delete anschr. Ansch ' + userans);

        for(Anschrift__c an : userAns){
            templist = new list<Anschrift__c>{};
            if (usransmap.containskey(an.Kunde__c)){
                templist = usransmap.get(an.Kunde__c);
            }
            templist.add(an);
            usransmap.put(an.Kunde__c, templist);
        }
        system.debug('############## delete anschr. Anz usransmap ' + usransmap.size());
        system.debug('############## delete anschr. usransmap ' + usransmap);
        
        for (id uid : usransmap.keyset()){
            templist = usransmap.get(uid);
            todellist = todelmap.get(uid);
            system.debug('############## delete anschr. vergleiche usransmap ' + usransmap.get(uid));
            system.debug('############## delete anschr. mit todelmap ' + todelmap.get(uid));
            for (anschrift__c an : templist){
                if(an.Art_der_Anschrift__c == 'Kundenadresse'){
                    system.debug('############## delete anschr. Kundenadresse ' + usransmap.size());
                    for (anschrift__c a : todellist){
                        if(a.Standardlieferanschrift__c == true){
                            an.Standardlieferanschrift__c = true;
                        }
                        if(a.Standardrechnungsanschrift__c == true){
                            an.Standardrechnungsanschrift__c = true;
                        }
                        if (a.id == an.id){
                            a.addError ('Kundenadresse kann nicht gelöscht werrden!');
                        }
                    }
                }
                
                found = false;
                for (anschrift__c a : todellist){
                    if(an.ID==a.ID){
                        found = true;
                    }
                }
                
                if (!found){
                    AnschToUpdate.add(an);
                }
            }
        }
        AdressenUpdated = true;
        Try {
            update AnschToUpdate;
        }catch (system.Dmlexception d){
            system.debug('#######################Adressverwaltung Anschriften delete hat nicht geklappt\n'+d);
        } 
        }
        catch (system.Exception e){
            system.debug(LoggingLevel.ERROR, '####################### e='+e);
        }               
    }
        
    public static void setenableKN(Boolean b){
        enableKN = (b!=null)?b:enableKN;
    }
    public static Boolean getenableKN(){
        return enableKN;
    }
    
}