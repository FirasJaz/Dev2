/****************************************************************************************************************************
// Erstellt 24.07.2015 von BT
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: Lead
//
//****************************************************************************************************************************
//
// Beschreibung:
//                
//
//****************************************************************************************************************************
//Änderungen:
//
// 17.08.2015 von AM    Anpassung weg neues Objekt Kundenstatus__c
// 24.08.2015 von BT    Anpassung Kunde
// 26.08.2015 von BT    neue Methoden kundeErstellen, auftragErstellen, zuKunde
// 28.08.2015 von wds   #102237354  Kundennummer Suchfeld befüllen
// 03.09.2015 von BT    Klasse zeile 
// 04.09.2015 von BT    Einbau Task 'Nachtelefonie Inko-Muster'
// 07.09.2015 von BT    Anpassung Ursprungsanfrage
// 07.09.2015 von BT    Einbau inko Anschrift
// 09.09.2015 von BT    Anpassung Kunde
// 14.09.2015 von BT    Anpassung Versicherungsnummer
// 22.09.2015 von BT    Anpassung Produktgruppe "Shop"
// 30.09.2015 von BT    Anpassung Leadpositionen
// 09.10.2015 von WDS   #105175040, Vorname wird auf blank gesetzt, wenn "Null" drin stehen sollte
//                      und Magento_kundennummer hinzugefügt
// 14.10.2015 von AM    shipping_..name / billing_..name als Anscriftnamen für Magento (Shop)
// 28.10.2015 von AM    Änderungen weg der Umstellung Magento auf PUSH (nur Shop)
// 09.11.2015 von wds   #105175040 zusätzlich noch name in Zeile 5xx korrekt zusammengesetzt! Update k deaktiviert
// 24.11.2015 von AM     magento_kundennummer__c wurde beim besteheneden Kunde nicht überommen
// 02.12.2015 von AM    Hat ein Kunde Status 'Kandidat/Inko' und kauft über shop einen Inko-Artikel so wird er zum 'Kunde/Inko'
//                      und Datum_1_Lieferung_Hartmann__c = Heute gestzt  
// 04.12.2015 von AM    einbau Product_ID6__c Decimal!!!! (vorbelegt mit 9000008610646 im Object Lead)
// 11.12.2015 von AM    #107897754 Hartmann Fax - Erweiterung um 3 Fragen + Notizen
// 16.12.2015 von AM    #110164718 - INKO - Nachtelefonien abschalten
// 04.01.2016 von AM    #107897754 Hartmann Fax - Erweiterung um 3 Fragen + Notizen - auch für bestehenden Kunden
// 08.01.2016 von BT    #110959030 Kein Auftrag wird erstellt, wenn nächste Schritt 'Beratung' ist
// 29.01.2016 von BT    Das Feld 'Geburtsdatum__c' wird durch das Feld 'Geburtsdatum_text__c' erstetzt
// 30.03.2016 von BT    #115587759 Es wird nur die neuste Shop Lieferanschrift angekreuzt und diese im Lieferschein genutzt. 
// 13.05.2016 von AM    case 00001048 - Shop - Bestehende Kunden - Es wurde keine Anschrift angelegt. 
//                      Es war bei der Prüfufung auf Art_der_Anschrift__c nicht beachtet. 
// 25.10.2017 von MZ    case 00001306 - the lead is converted by SF standard lead convert. lead is not deleted any more.
// 29.07.2018 von SD    case 00001616 - das Feld Lead.Vorherige_Anfrage__c in das neue Feld Kunden__c.Vorherige_Anfrage__c 
//                          übernehmen (SD1616)
// 23.10.2018 von MZ    #161257706 wizard version added
//****************************************************************************************************************************
*/
global with sharing class Lead_zu_Kunde {
    public Kunde__c Kd {get; set;}
    public Lead l{get; set;}
    private String leadEmail;
    public boolean insert_kunde_error = false;
    public Id kId;
    public Id kdId {get; set;}
    public string message {get; set;}
    public string ergebnis {get; set;}
    public boolean Kdgefunden {get; set;}
    public boolean KdNichtgefunden {get; set;}
    public boolean keinAUgefunden {get; set;}
    public boolean contgefunden {get; set;}
    public boolean hatstatus {get; set;}
    public boolean gespeichert{get; set;}
    public boolean statusUpdate {get; set;}
    public boolean shop {get; set;}
    public set<decimal> eanSet;
    public Auftrag__c AU {get; set;}
    public boolean fertig {get; set;} 
    public List<zeile> zeilenlist = new List<Zeile>();
    public List<zeile> Neuzeilenlist = new List<Zeile>();
    public List<Kunde__c> Kdlist = new List<Kunde__c>();
 
    
    public List<zeile> getzeilenlist() {
        return zeilenlist;
    }   
    
    public List<zeile> getNeuZeilenlist() {
        return Neuzeilenlist;
    }   
    
    public List<Kunde__c> getKdlist() {
        return Kdlist;
    }      
    
    global Lead_zu_Kunde(ApexPages.StandardController stdController) {
        this.l = (Lead)stdController.getRecord();  
    }
    
    // Code we will invoke on page load.
    public PageReference konvertieren() {        
        String qID = ApexPages.currentPage().getParameters().get('id');
        List<Lead> lead = [SELECT Id, Company FROM Lead WHERE Id =: qID];

        if(lead[0].Company == 'curabox') {
                PageReference pageRef = Page.Curabox_zu_Kunde_Seite;
                pageRef.getParameters().put('ID', qID);
                pageRef.setRedirect(true);
                return PageRef;
        } 
        else {
                konvertieren_zu_Kunde(qID);
                return null;
        }
        
        /*
        if (qID == null) {
            // Display the Visualforce page's content if no Id is passed over 
            return null;
        }
        */
        //convert Lead to Custom 

        // go back to the original page
        //PageReference pageRef = new PageReference('/' + '00Q');
        //pageRef.setRedirect(true);
    }
    
    public void konvertieren_zu_Kunde(ID qID)
    {    
        fertig = false;    
        statusUpdate = false;        
        boolean insert_auftrag_error = false;
        eanSet = new set<decimal>();
        
        List<RecordType> reTyplist = [SELECT Id, Name FROM RecordType WHERE Name= :'Inkontinenz' LIMIT 1];
        Id ReTypId = reTyplist[0].id;
        l = [SELECT firstName, lastname, salutation, 
                    Email, Fax, MobilePhone, Phone, Company, magento_increment_id__c, magento_order_id__c, Magento_payment_method__c,
                    billing_city__c, billing_country__c, billing_postal_code__c, billing_street__c,
                    billing_name__c, billing_firstname__c, billing_lastname__c,
                    shipping_city__c, shipping_country__c, shipping_postal_code__c, shipping_street__c,
                    shipping_name__c, shipping_firstname__c, shipping_lastname__c,
                    Street, PostalCode, City, RecordTypeId, Mitarbeiter__c, Versicherungsnummer__c, Geburtsdatum__c, IK_Nummer_des_traegers__c,                     
                    inko_product_id1__c, inko_product_id2__c, inko_product_id3__c, inko_product_id4__c, inko_product_id5__c, Kostentr_ger__c, 
                    inko_gender__c, inko_own_use__c, inko_already_in_use__c, inko_product_type__c, inko_change_cycle__c,
                    inko_situation__c, inko_liquid_amount__c, inko_size__c, inko_Order_ID__c, inko_Partner_ID__c, 
                    inko_newsletter__c, inko_wizard_name__c, OM_Tracking_Order_ID__c, OM_Wizard_Version__c, OM_Wizzard_Name2__c, OM_Partner_ID__c,
                    OM_Newsletter__c, OM_Referrer__c, OM_created_at__c, next_Step__c, magento_kundennummer__c,
                    magento_payment_status__c, magent_payment_id__c, magento_total_amount__c, magento_discount_amount__c,
                    magento_shipping_amount__c, magento_grand_total__c, magento_tax_amount_01__c, magento_tax_amount_02__c,
                    Product_ID6__c, inko_recipe__c, inko_insurance__c, inko_support__c, 
                    Vorherige_Anfrage__c // SD1616
                    FROM Lead WHERE id= :qID ];
        
        leadEmail = l.Email;
        
        if(l.inko_product_id1__c != null) {
                    try {
                        decimal p1 = decimal.valueOf(l.inko_product_id1__c);
                        eanSet.add(p1);                        
                    }
                    catch (System.Exception e) {}
                }
                
                if(l.inko_product_id2__c != null) {
                    try {
                        decimal p2 = decimal.valueOf(l.inko_product_id2__c);
                        eanSet.add(p2);
                    }
                    catch (System.Exception e) {}
                }
                
                if(l.inko_product_id3__c != null) {
                    try {
                        decimal p3 = decimal.valueOf(l.inko_product_id3__c);
                        eanSet.add(p3);
                    }
                    catch (System.Exception e) {}
                }
                
                if(l.inko_product_id4__c != null) {
                    try {
                        decimal p4 = decimal.valueOf(l.inko_product_id4__c);
                        eanSet.add(p4);
                    }
                    catch (System.Exception e) {}
                }
                  
                if(l.inko_product_id5__c != null) {
                    try {
                        decimal p5 = decimal.valueOf(l.inko_product_id5__c);
                        eanSet.add(p5);
                    }
                    catch (System.Exception e) {} 
                 } 
// AM 04.12.2015 
                if(l.Product_ID6__c != null) {
                    try {
                        eanSet.add(l.Product_ID6__c);
                    }
                    catch (System.Exception e) {} 
                 } 
                system.debug ('##################################alex113 eanSet.size()=' + eanSet.size() );
       //if((kunde() == null) && (cont_Kdlist() == null)) {
            message = 'Es wurde kein Kunde gefunden, der dem Lead ' + ' "' + l.firstname+ ' ' + l.lastname + '" ' + ' entspricht.'; 
            KdNichtgefunden = false;            
        //}
        
       if(l.Company == 'Update') {
            shop = true;
            Id kdId = Id.valueOf(l.OM_Tracking_Order_ID__c);
            List<Kunde__c> klist = [SELECT Id, Vorname__c, Name__c, e_mail__c, Versichertennummer__c, Geburtsdatum_text__c, IK_Nummer_des_Tr_gers__c, Krankenkasse__c FROM Kunde__c WHERE Id = :kdId LIMIT 1];            
            
                             klist[0].Versichertennummer__c = l.Versicherungsnummer__c;    
                             if(l.Geburtsdatum__c != null) klist[0].Geburtsdatum_text__c = l.Geburtsdatum__c;     
                             try {                        
                                    klist[0].IK_Nummer_des_Tr_gers__c = Decimal.valueOf(l.IK_Nummer_des_traegers__c);     
                             }     
                                    catch (System.Exception e) 
                             {
                                    klist[0].IK_Nummer_des_Tr_gers__c = null;
                                    system.debug ('##################################BT Ungültige IK Nummer des Trägers');
                             }                        
                             List<Account> Accountlist = [SELECT Id, name FROM Account WHERE name = :l.Kostentr_ger__c LIMIT 1];  
                             if((Accountlist != null) && (Accountlist.size() > 0)) {
                                 klist[0].Krankenkasse__c = Accountlist[0].Id; 
                             }
                             else {
                                 klist[0].Krankenkasse__c = null;
                             }
            
            update klist[0];
            Kdlist.add(klist[0]);
            
            message = 'Das Lead enspricht folgendem Kunden'; 
            statusUpdate = true;  
            Kdgefunden = true;     
            gespeichert = false;    
       }
       else if((l.Company == 'Magento Shop') || (l.Company == 'Shop'))
       {
              if((kunde() != null) && (kunde().size() > 0)) {
                //Kdgefunden = true;
                shop = true; 
                message = 'Das Lead entspricht folgenden Kunden';
                for(kunde__c kd: kunde()) {    
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id);    
                    z.k = kd;
                    z.keinStatus = true;
                    zeilenlist.add(z);   
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    z.keinStatus = true;
                    zeilenlist.add(z);
                    }                    
                }
              }                                  
       }        
       else if((kunde() != null) && (cont_Kdlist() != null) && (kunde().size() > 0) && (cont_Kdlist().size() > 0)) {             
            Set<Id> kdIdset = new Set<Id>();
           
            for(Kunde__c Kd: kunde()) {
                kdIdset.add(Kd.id);
            }
            
            for(Kunde__c Kd: cont_Kdlist()) {
                kdIdset.add(Kd.id);
            }
                        
            List<Kundenstatus__c> KdStatuslist = [SELECT id, Produktgruppe__c, Kunde__c FROM Kundenstatus__c WHERE Kunde__c IN :kdIdset AND Produktgruppe__c LIKE '%Inko%'];
            
            if((KdStatuslist != null) && (KdStatuslist.size() > 0)) {
                message = 'Kunden und Angehöriger mit E-mail-Adresse ' + '"' + leadEmail + '"' + ' und Status ' + '"' + KdStatuslist[0].Produktgruppe__c + '"' + ' wurden gefunden.';
                hatstatus = true;
                Set<Id> ks_kdIdlist = new Set<Id>();
                 
                for(Kundenstatus__c ks: KdStatuslist) {
                    ks_kdIdlist.add(ks.Kunde__c);
                }
                
                List<Kunde__c> klist= [SELECT id, Vorname__c, Name__c, Kundennummer_abena__c, Produktgruppe__c FROM Kunde__c WHERE id IN :ks_kdIdlist];
                
                for(kunde__c kd: klist) {    
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id);
                    z.k = kd;    
                    zeilenlist.add(z);   
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    zeilenlist.add(z);
                    }                    
                }
                
                              List<Kundenstatus__c> Kdstlist = [SELECT id, Produktgruppe__c, Kunde__c FROM Kundenstatus__c WHERE Kunde__c IN :kdIdset AND Produktgruppe__c != 'Inko'];             
                              if((Kdstlist != null) && (Kdstlist.size() > 0)) {    
                                contgefunden = false;            
                                Set<Id> ks_kdIdlist1 = new Set<Id>();
                 
                                for(Kundenstatus__c ks: Kdstlist) {
                                        ks_kdIdlist1.add(ks.Kunde__c);
                                }
                
                                List<Kunde__c> klist1 = [SELECT id, Vorname__c, Name__c, Produktgruppe__c, Kundennummer_abena__c FROM Kunde__c WHERE id IN :ks_kdIdlist1 AND ( NOT Produktgruppe__c  INCLUDES ('Inko'))];
                
                                for(Kunde__c k: klist1) {
                                    Zeile z = new Zeile(k.Vorname__c + ',' + k.Name__c, k.id);
                                    z.k = k;
                                    z.keinStatus = true;
                                    NeuZeilenlist.add(z);
                                }
                            }
               
            }
            else {
                message = 'Kunden und Angehöriger mit der E-mail-Adresse ' + '"' + leadEmail + '" ' +' gefunden.';
                Kdgefunden = true;
                contgefunden = false;
                for(Kunde__c kd: kunde()) {
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id); 
                    z.k = kd; 
                    z.keinStatus = true;  
                    zeilenlist.add(z);   
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    z.keinStatus = true;
                    zeilenlist.add(z);
                    }
                }
                for(Kunde__c kd: cont_Kdlist()) {
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id); 
                    z.k = kd;
                    z.keinStatus = true;   
                    zeilenlist.add(z);   
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    z.keinStatus = true;
                    zeilenlist.add(z);
                    }
                }
            }
            
       
       }
       else if((kunde() != null) && (kunde().size() > 0)){
            Set<Id> kdIdset = new Set<Id>();
           
            for(Kunde__c Kd: kunde()) {
                kdIdset.add(Kd.id);
            }
                        
            List<Kundenstatus__c> KdStatuslist = [SELECT id, Produktgruppe__c, Kunde__c FROM Kundenstatus__c WHERE Kunde__c IN :kdIdset AND Produktgruppe__c LIKE '%Inko%'];
            
            if((KdStatuslist != null) && (KdStatuslist.size() > 0)) {
                message = 'Es wurden folgende Kunden mit E-mail-Adresse ' + '"' + leadEmail + '"' + ' und Status ' + '"' + KdStatuslist[0].Produktgruppe__c + '"' + ' gefunden.';
                if(leadEmail == null) message = 'Es wurden folgende Kunden ohne Email, mit gleichem Name und Status ' + '"' + KdStatuslist[0].Produktgruppe__c + '"' + ' gefunden.';
                hatstatus = true;
                
                Set<Id> ks_kdIdlist = new Set<Id>();
                 
                for(Kundenstatus__c ks: KdStatuslist) {
                    ks_kdIdlist.add(ks.Kunde__c);
                }
                
                List<Kunde__c> klist= [SELECT id, Vorname__c, Name__c, Produktgruppe__c, Kundennummer_abena__c FROM Kunde__c WHERE id IN :ks_kdIdlist];
                
                for(kunde__c kd: klist) {    
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id);    
                    z.k = kd;
                    zeilenlist.add(z);   
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    zeilenlist.add(z);
                    }
                    
               }
               
                           List<Kundenstatus__c> Kdstlist = [SELECT id, Produktgruppe__c, Kunde__c FROM Kundenstatus__c WHERE Kunde__c IN :kdIdset AND Produktgruppe__c != 'Inko'];
                            if((Kdstlist != null) && (Kdstlist.size() > 0)) {
                                contgefunden = false;
                                Set<Id> ks_kdIdlist1 = new Set<Id>();
                 
                                for(Kundenstatus__c ks: Kdstlist) {
                                        ks_kdIdlist1.add(ks.Kunde__c);
                                }
                
                                List<Kunde__c> klist1 = [SELECT id, Vorname__c, Name__c, Produktgruppe__c, Kundennummer_abena__c FROM Kunde__c WHERE id IN :ks_kdIdlist1 AND ( NOT Produktgruppe__c  INCLUDES ('Inko'))];
                
                                for(Kunde__c k: klist1) {
                                    Zeile z = new Zeile(k.Vorname__c + ',' + k.Name__c, k.id);
                                    z.k = k;
                                    z.keinStatus = true;
                                    NeuZeilenlist.add(z);
                                }
                            }
            }            
            else {                
                message = 'Es wurden folgende Kunden mit der E-mail-Adresse ' + '"' + leadEmail + '" ' +' gefunden.';
                if(leadEmail == null) message = 'Es wurden folgende Kunden ohne Email, mit gleichem Name gefunden.';
                //Kdgefunden = true;
                contgefunden = false;
                for(Kunde__c kd: kunde()) {
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id); 
                    z.k = kd;
                    z.keinStatus = true;   
                    zeilenlist.add(z);   
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    z.keinStatus = true;
                    zeilenlist.add(z);
                    }
                }
            }            
            
        }        
        else if((cont_Kdlist() != null) && (cont_Kdlist().size() > 0)){
            Set<Id> kdIdset = new Set<Id>();
           
            for(Kunde__c Kd: cont_Kdlist()) {
                kdIdset.add(Kd.id);
            }
            
            List<Kundenstatus__c> KdStatuslist = [SELECT id, Produktgruppe__c, Kunde__c FROM Kundenstatus__c WHERE Kunde__c IN :kdIdset AND Produktgruppe__c LIKE '%Inko%'];
            
            if((KdStatuslist != null) && (KdStatuslist.size() > 0)) {
                message = 'Angehöriger mit E-Mail-Adresse ' + '"' + leadEmail + '"' + ' wurden gefunden. Die zugehörigen Kunden haben den Status ' + KdStatuslist[0].Produktgruppe__c + '.';
                hatstatus = true; 
                
                Set<Id> ks_kdIdlist = new Set<Id>();
                 
                for(Kundenstatus__c ks: KdStatuslist) {
                    ks_kdIdlist.add(ks.Kunde__c);
                }
                
                List<Kunde__c> klist= [SELECT id, Vorname__c, Name__c, Produktgruppe__c, Kundennummer_abena__c FROM Kunde__c WHERE id IN :ks_kdIdlist];
                
                for(kunde__c kd: klist) {    
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id);   
                    z.k = kd; 
                    zeilenlist.add(z);   
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    zeilenlist.add(z);
                    }                    
               }  
               
                              List<Kundenstatus__c> Kdstlist = [SELECT id, Produktgruppe__c, Kunde__c FROM Kundenstatus__c WHERE Kunde__c IN :kdIdset AND Produktgruppe__c != 'Inko'];             
                              if((Kdstlist != null) && (Kdstlist.size() > 0)) {    
                                contgefunden = true;            
                                Set<Id> ks_kdIdlist1 = new Set<Id>();
                 
                                for(Kundenstatus__c ks: Kdstlist) {
                                        ks_kdIdlist1.add(ks.Kunde__c);
                                }
                
                                List<Kunde__c> klist1 = [SELECT id, Vorname__c, Name__c, Produktgruppe__c, Kundennummer_abena__c FROM Kunde__c WHERE id IN :ks_kdIdlist1 AND ( NOT Produktgruppe__c  INCLUDES ('Inko'))];
                
                                for(Kunde__c k: klist1) {
                                    Zeile z = new Zeile(k.Vorname__c + ',' + k.Name__c, k.id);
                                    z.k = k;
                                    z.keinStatus = true;
                                    NeuZeilenlist.add(z);
                                }
                            }
            }
            else {
                message = 'Angehöriger folgender Kunden haben die E-Mail-Adresse' + '"' + leadEmail + '"' + '.';
                Kdgefunden = true;
                contgefunden = true;  
                for(Kunde__c Kd: cont_Kdlist()) {    
                    List<Auftrag__c> AUlist = [SELECT id, Name, Kunde__c FROM Auftrag__c WHERE Kunde__c = :kd.id LIMIT 1];
                    if((AUlist != null) && (AUlist.size() > 0)) {    
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, AUlist[0].Name, kd.id, AUlist[0].id); 
                    z.k = kd;
                    z.keinStatus = true;
                    zeilenlist.add(z);      
                    }
                    else {
                    Zeile z = new Zeile(kd.Vorname__c + ',' + kd.Name__c, kd.id);
                    z.k = kd;
                    z.keinStatus = true;
                    zeilenlist.add(z);
                    }
                }           
            }
        }
               
         gespeichert = false;
    } 
          
    public void kundeMitAuftragErstellen() {
        Map<String, Id> LeadposMap = new Map<String, Id>();
        Map<Decimal, Artikel__c> ArtMap = new Map<Decimal, Artikel__c>();  
        gespeichert = false;
        boolean insert_auftrag_error = false;
        String qID = ApexPages.currentPage().getParameters().get('id');       
        
        Kunde__c k = new Kunde__c();

        k.Kundennummer__c = aktuellerKdNr()+ 1;
        k.suchfeld_kundennr__c='CB14-' + String.valueof( k.Kundennummer__c );
        k.magento_kundennummer__c = l.magento_kundennummer__c;
        
        if (l.firstname == null) 
        {k.vorname__c = ' ';
        k.name = l.lastname + ',' + ' ';}
        Else {
        k.name = l.lastname + ',' + l.firstname;
        k.vorname__c = l.firstName;}  
        k.name__c = l.lastName;
        k.Anrede__c = l.salutation; 
        k.e_mail__c = l.Email;    
        k.Fax__c = l.Fax;        
        k.Stra_e__c = l.Street;
                      system.debug ('################################## WDS k.name : ' + k.name);
                      system.debug ('################################## WDS k.vorname : ' +l.firstname);
                      system.debug ('################################## WDS k.nachname : ' + l.lastname);

        if(l.PostalCode != null) k.PLZ__c = Decimal.valueOf(l.PostalCode);
        k.Ort__c = l.City;
        
        if((l.Company == 'Shop') || (l.Company == 'Magento Shop'))
        {
            k.Stra_e__c = l.shipping_street__c;
            if(l.shipping_postal_code__c != null) k.PLZ__c = Decimal.valueOf(l.shipping_postal_code__c);
            k.Ort__c = l.shipping_city__c;
        }
        
        k.Telefon__c = l.Phone;
        k.Mobil__c = l.MobilePhone;
        
         
        k.Versichertennummer__c = l.Versicherungsnummer__c;    
        if(l.Geburtsdatum__c != null) k.Geburtsdatum_text__c = l.Geburtsdatum__c;
        try {                        
              k.IK_Nummer_des_Tr_gers__c = Decimal.valueOf(l.IK_Nummer_des_traegers__c);     
        }     
        catch (System.Exception e) {
              k.IK_Nummer_des_Tr_gers__c = null;
              system.debug ('##################################BT Ungültige IK Nummer des Trägers');
        }   
        k.Inko_Frage1__c = l.inko_gender__c;
        k.Inko_Frage2__c = l.inko_own_use__c;
        k.Inko_Frage3__c = l.inko_already_in_use__c;
        k.Inko_Frage4__c = l.inko_product_type__c;
        k.Inko_Frage5__c = l.inko_change_cycle__c;
        k.Inko_Frage6__c = l.inko_situation__c;
        k.Inko_Frage7__c = l.inko_liquid_amount__c;
        k.Inko_Frage8__c = l.inko_size__c; 
        // 04.12.2015
        k.inko_Frage9__c = l.inko_recipe__c;
        k.inko_Frage10__c = l.inko_insurance__c;
        k.inko_Frage11__c = l.inko_support__c; 
            
        k.Next_step__c = l.next_Step__c;
        
        List<Account> Acclist = [SELECT Id, name FROM Account WHERE name = :l.Kostentr_ger__c LIMIT 1];
        
        if((Acclist != null) && (Acclist.size() > 0)) k.Krankenkasse__c = Acclist[0].Id; 
        
        k.Interesse_an_Zusatzinfos__c = l.OM_Newsletter__c;  
        
        // SD1616
        k.Vorherige_Anfrage__c = l.Vorherige_Anfrage__c;
        
        if(l.Company != null) {
            if(l.Company == 'inko') {
                k.produktgruppe__c = 'Inko';
            }
            else if(l.Company == 'Shop')
            {
                k.Produktgruppe__c = 'Shop';
            }
            else if(l.Company == 'Magento Shop')
            {
                k.Produktgruppe__c = 'Shop';
            }
            else{
                k.produktgruppe__c = 'PG54';
            }
         }       
         
         if(k.produktgruppe__c == null) k.produktgruppe__c = 'PG54';
             system.debug ('### wds 2  (395) Zuzahlung_befreit_von__c ' + k.Zuzahlung_befreit_von__c);
      
             try {  
                  Database.DMLOptions dml = new Database.DMLOptions();
                  dml.DuplicateRuleHeader.AllowSave = true;  
                  Database.SaveResult sr = Database.insert(k, dml); 
                  if (sr.isSuccess()) {   
                  System.debug('Duplicate account has been inserted in Salesforce!'); 
                  }                         
                 //insert k;       
                 kId = k.id;    
                 Kd = k;                
             }
             catch (System.Exception e) 
             {
                 // delete k;
                 insert_kunde_error = true;
                 system.debug ('##################################alex102 id=' + 'Der Kunde konnte nicht erzeugt werden.');
             }
        
        if(k.id != null) {
            id ursp = null;
            id rtid = null;
            Kundenstatus__c ks = new Kundenstatus__c();
            ursp = l.OM_Wizzard_Name2__c;                  
            list<RecordType> rtList = [SELECT Id, Name FROM RecordType WHERE sObjectType='Kundenstatus__c' AND Name = :k.produktgruppe__c];
            if((rtList != null) && (rtList.size() > 0)) {
                rtid = rtList[0].id;
            } 
            
            list<Kundenstatus__c> ksList = [SELECT id, Kunde__c, Status__c, Produktgruppe__c, 
                                                    K_ndigungsgrund__c, K_ndigungsdatum__c, K_ndigungsbemerkung__c,
                                                    Antrag_eingegangen_am__c, Antrag_bewilligt_abgelehnt_am__c, Referrer__c, Created_at__c
                                            FROM Kundenstatus__c
                                            WHERE Kunde__c = :k.id
                                            AND Produktgruppe__c = :k.produktgruppe__c];
            if((ksList != null) && (ksList.size() > 0)) {
                ks = ksList[0];
            } else ks.Kunde__c = k.id;
            
                //   wds2808            if(k.produktgruppe__c == 'Inko') {
                //                ks.Status__c = 'Kunde';         
                //            }
                //            else ks.Status__c = 'Interessent';
            ks.Produktgruppe__c = k.produktgruppe__c;
            ks.Partner_ID__c = l.OM_Partner_ID__c;
            ks.Tracking_Order_ID__c = l.OM_Tracking_Order_ID__c;
            ks.Wizard_Version__c = l.OM_Wizard_Version__c;
            ks.Ursprungsanfrage__c = ursp;
            ks.Referrer__c = l.OM_Referrer__c;
            ks.Created_at__c = l.OM_created_at__c;
            ks.RecordTypeId = rtid;
            ks.Mitarbeiter__c = l.Mitarbeiter__c;
            ks.Ursprungsanfrage__c = ursp;
            try {
                upsert ks;
            }
            catch (System.Exception e) {
                system.debug ('################################## Der Kundenstatus konnte nicht erzeugt werden.' + e);
            }
        }
 //       update k;
        
        if(k.produktgruppe__c == 'Inko') {  
            system.debug ('##################################alex114 k.id=' + k.id );
            Anschrift__c inko_addr = new Anschrift__c();
            inko_addr.Name = l.lastname + ',' + l.firstname;
            inko_addr.Anrede__c = l.Salutation;
            inko_addr.Kunde__c = k.ID;
            inko_addr.Art_der_Anschrift__c = 'Inko';
            inko_addr.e_mail__c = l.Email;
            inko_addr.Fax__c = l.Fax;
            //inko_addr.Hausnummer__c = l.Hausnummer__c;
            inko_addr.Ort__c = l.City;
            if(l.PostalCode != null) inko_addr.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.PostalCode));
            inko_addr.Stra_e__c = l.Street;
            inko_addr.Telefon__c = l.Phone;    
            
            insert inko_addr;
            
            if(l.next_Step__c != 'Beratung' ) {              
            list<Auftragsposition__c> apList = new list<Auftragsposition__c>();                    
            AU = new Auftrag__c(Kunde__c = k.id, 
                                            Bezeichnung__c = 'Muster-Artikel', 
                                            Auftrag_text__c = 'Muster-Artikel', 
                                            Lieferzeitraum__c = 'Einmalig',
                                            genehmigt_ab__c = date.today(),
                                            Genehmigungsstatus__c = 'genehmigt');
             
                if(!eanSet.isEmpty()) {
                    keinAUgefunden = false;
                    list<Artikel__c> arList = [SELECT id, Anlage_4_Preis__c FROM Artikel__c WHERE a_pac_apo_EAN_UPC__c IN :eanSet];
                    system.debug ('##################################alex112a eanSet=' + eanSet );
                    // if((arList != null) && (arList.size() >0)) {
                    // 1 Artikel kommt immer (Beileger für Muster-Boxen), also min. 2 Positionen für Auftrag 
                    if((arList != null) && (arList.size() > 1)) {
                         system.debug ('##################################alex112 arList.size()=' + arList.size() );
                        for (Artikel__c AR : arList) {
                            Auftragsposition__c AP = new Auftragsposition__c(Kunde__c = k.id,
                                                                            Artikel__c = AR.id,
                                                                            Gen_Menge_Stk_Mon__c = 1,
                                                                            GenAnzVerp__c = 1,
                                                                            genehmigt_ab__c = date.today(),
                                                                            Preis__c = 0.00,
                                                                            VK_netto__c = 0.00);
                            
                            apList.add(AP);                        
                        }
                        
                        if((apList != null) && (apList.size() > 0) ) {
                            try {
                                inko_auftrag auftrag = new inko_auftrag(AU, apList);                                                 
                            }
                            catch(System.Exception e) {
                                insert_auftrag_error = true;
                                delete AU;
                                system.debug ('##################################alex102 id=' + 'Der Auftrag konnte nicht erzeugt werden.');
                            }
                        }
                    }
                 //}
                }
                else {
                    keinAUgefunden = true;
                }
            }
            else {
                keinAUgefunden = true;
            }
       }
            
      if(k.produktgruppe__c == 'Shop') {  
        
            Anschrift__c shop_addr1 = new Anschrift__c();
            // shop_addr1.Name = l.lastname + ',' + l.firstname;
            shop_addr1.Name = l.billing_lastname__c + ',' + l.billing_firstname__c;
            
            shop_addr1.Anrede__c = l.Salutation;
            shop_addr1.Kunde__c = k.ID;
            shop_addr1.Art_der_Anschrift__c = 'Shop';
            shop_addr1.e_mail__c = l.Email;
            shop_addr1.Fax__c = l.Fax;
            shop_addr1.Ort__c = l.billing_city__c;
            if(l.billing_postal_code__c != null) shop_addr1.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.billing_postal_code__c));
            shop_addr1.Stra_e__c = l.billing_street__c;
            shop_addr1.Telefon__c = l.Phone;
            shop_addr1.Shoprechnungsanschrift__c = True;
            
            Anschrift__c shop_addr2 = new Anschrift__c();
            shop_addr2.Name = l.shipping_lastname__c + ',' + l.shipping_firstname__c;
            
            shop_addr2.Anrede__c = l.Salutation;
            shop_addr2.Kunde__c = k.ID;
            shop_addr2.Art_der_Anschrift__c = 'Shop';
            shop_addr2.e_mail__c = l.Email;
            shop_addr2.Fax__c = l.Fax;
            shop_addr2.Ort__c = l.shipping_city__c;
            if(l.shipping_postal_code__c != null) shop_addr2.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.shipping_postal_code__c));
            shop_addr2.Stra_e__c = l.shipping_street__c;
            shop_addr2.Telefon__c = l.Phone;              
            shop_addr2.Shoplieferanschrift__c = true;
            
            string sadresse1 = shop_addr1.Name + shop_addr1.Ort__c + shop_addr1.Stra_e__c + shop_addr1.PLZ__c;
            string sadresse2 = shop_addr2.Name + shop_addr2.Ort__c + shop_addr2.Stra_e__c + shop_addr2.PLZ__c;
            
            
            if(sadresse1 == sadresse2){
                   shop_addr2.Shoprechnungsanschrift__c = True;
                   shop_addr2.Shoplieferanschrift__c = True;
                   insert shop_addr2;
                   
            }else{
                insert shop_addr1;
                insert shop_addr2;                   
            }
          
            
            List<Lead_Position__c>  LeadposList = [SELECT Id, EAN__c, Price__c, Lead__c, Qty_Ordered__c,
                                                            line_no__c, amount__c, discount_amount__c, discount_percent__c,
                                                            grand_amount__c, tax_amount__c
                                                    FROM Lead_Position__c 
                                                    WHERE Lead__c = :l.Id 
                                                    AND EAN__c != null]; 
            
            List<Decimal> EAN_list = new List<Decimal>();
            
            if((LeadposList != null) && (LeadposList.size() > 0)) {
                for(Lead_Position__c Leadpos : LeadposList) {
                     EAN_list.add(Decimal.valueOf(Leadpos.EAN__c));   
                }
            }
            
            list<Artikel__c> arList = [SELECT id, EVK__c, EVK_netto__c, a_pac_apo_EAN_UPC__c, Artikelgruppe__r.name 
                                        FROM Artikel__c 
                                        WHERE a_pac_apo_EAN_UPC__c IN :EAN_list];
            
            List<String> art_EAN_list = new List<String>();
            
            boolean isHartmannShop = false;
            if((arList != null) && (arList.size() > 0)) {
                for(Artikel__c art: arList)
                {                    
                    art_EAN_list.add(string.valueOf(art.a_pac_apo_EAN_UPC__c));
                    LeadposMap.put(string.valueOf(art.a_pac_apo_EAN_UPC__c), art.Id);
                    ArtMap.put(art.a_pac_apo_EAN_UPC__c, art);
                    if(art.Artikelgruppe__r.name == 'Shop Hartmann') isHartmannShop = true;
                }
            }
            
            if(isHartmannShop) {
                List<Kundenstatus__c> kskList = [SELECT id, Datum_1_Lieferung_Hartmann__c, Versorgungsart_des_Kunden__c, Status__c 
                                                    FROM Kundenstatus__c 
                                                    WHERE Produktgruppe__c = 'Inko' 
                                                    AND Status__c = 'Kandidat'
                                                    AND Kunde__c = :k.id];
                if((kskList != null) && (kskList.size() > 0)) {
                    kskList[0].Datum_1_Lieferung_Hartmann__c = date.today();
                    kskList[0].Status__c = 'Kunde';
                    kskList[0].Versorgungsart_des_Kunden__c = 'Privatkauf über pflege.de Shop';
                }
                
            }
            
            List<Lead_Position__c>  final_LeadposList = [SELECT Id, EAN__c, Price__c, Lead__c, Qty_Ordered__c,
                                                            line_no__c, amount__c, discount_amount__c, discount_percent__c,
                                                            grand_amount__c, tax_amount__c                                                              
                                                            FROM Lead_Position__c 
                                                            WHERE  Lead__c = :l.Id 
                                                                AND EAN__c IN :art_EAN_list];
            
                            
            list<Auftragsposition__c> apList = new list<Auftragsposition__c>();                    
            AU = new Auftrag__c(Kunde__c = k.id, 
                                            Bezeichnung__c = 'Shop', 
                                            Auftrag_text__c = 'Shop', 
                                            Lieferzeitraum__c = 'Einmalig',
                                            genehmigt_ab__c = date.today(),
                                            Genehmigungsstatus__c = 'genehmigt',
                                            Magento_increment_id__c = l.magento_increment_id__c,
                                            Magento_order_id_c__c = l.magento_order_id__c,
                                            Magento_payment_method_c__c = l.Magento_payment_method__c);
                try {
                    l.magento_total_amount__c = l.magento_total_amount__c.replace(',', '.');
                    AU.magento_total_amount__c = decimal.valueOf(l.magento_total_amount__c);
                }
                catch (System.Exception e) {
                    AU.magento_total_amount__c = 0.00;
                }
                try {
                    l.magento_discount_amount__c = l.magento_discount_amount__c.replace(',', '.');
                    AU.magento_discount_amount__c = decimal.valueOf(l.magento_discount_amount__c);
                }
                catch (System.Exception e) {
                    AU.magento_discount_amount__c = 0.00;
                }
                try {
                    l.magento_shipping_amount__c = l.magento_shipping_amount__c.replace(',', '.');
                    AU.magento_shipping_amount__c = decimal.valueOf(l.magento_shipping_amount__c);
                }
                catch (System.Exception e) {
                    AU.magento_shipping_amount__c = 0.00;
                }
                try {
                    l.magento_grand_total__c = l.magento_grand_total__c.replace(',', '.');
                    AU.magento_grand_total__c = decimal.valueOf(l.magento_grand_total__c); 
                }
                catch (System.Exception e) {
                    AU.magento_grand_total__c = 0.00;
                }
                try {
                    l.magento_tax_amount_01__c = l.magento_tax_amount_01__c.replace(',', '.');
                    AU.magento_tax_amount__c = decimal.valueOf(l.magento_tax_amount_01__c);
                }
                catch (System.Exception e) {
                    AU.magento_tax_amount__c = 0.00;
                }
                try {
                    l.magento_tax_amount_02__c = l.magento_tax_amount_02__c.replace(',', '.');
                    AU.magento_tax_amount02__c  = decimal.valueOf(l.magento_tax_amount_02__c);
                }
                catch (System.Exception e) {
                    AU.magento_tax_amount02__c  = 0.00;
                }
               if((final_LeadposList != null) && (final_LeadposList.size() > 0)) {
                    keinAUgefunden = false;
                                      
                        for (Lead_Position__c Leadpos : final_LeadposList) {
                            Auftragsposition__c AP = new Auftragsposition__c(Kunde__c = k.id,
                                                                            Artikel__c = LeadposMap.get(Leadpos.EAN__c),
                                                                            Gen_Menge_Stk_Mon__c = Decimal.ValueOf(Leadpos.Qty_Ordered__c),
                                                                            GenAnzVerp__c = Decimal.ValueOf(Leadpos.Qty_Ordered__c),
                                                                            genehmigt_ab__c = date.today(),
                                                                            Preis__c = ArtMap.get(Decimal.valueOf(Leadpos.EAN__c)).EVK__c,
                                                                            VK_netto__c = ArtMap.get(Decimal.valueOf(Leadpos.EAN__c)).EVK_netto__c);
                            
                                try {
                                    AP.line_no__c = decimal.valueOf(Leadpos.line_no__c);
                                }
                                catch (System.Exception e) {}
                                try {
                                    Leadpos.amount__c = Leadpos.amount__c.replace(',', '.'); 
                                    AP.amount__c = decimal.valueOf(Leadpos.amount__c);
                                }
                                catch (System.Exception e) {}
                                try {
                                    Leadpos.discount_amount__c = Leadpos.discount_amount__c.replace(',', '.');
                                    AP.discount_amount__c = decimal.valueOf(Leadpos.discount_amount__c);
                                }
                                catch (System.Exception e) {}
                                try {
                                    Leadpos.discount_percent__c = Leadpos.discount_percent__c.replace(',', '.');
                                    AP.discount_percent__c = decimal.valueOf(Leadpos.discount_percent__c);
                                }
                                catch (System.Exception e) {}
                                try {
                                    Leadpos.grand_amount__c = Leadpos.grand_amount__c.replace(',', '.');
                                    AP.grand_amount__c = decimal.valueOf(Leadpos.grand_amount__c);
                                }
                                catch (System.Exception e) {}
                                try {
                                    Leadpos.tax_amount__c = Leadpos.tax_amount__c.replace(',','.');
                                    AP.tax_amount__c = decimal.valueOf(Leadpos.tax_amount__c);
                                }
                                catch (System.Exception e) {}
                                try {
                                    Leadpos.Price__c = Leadpos.Price__c.replace(',','.');
                                    AP.Preis__c = decimal.valueOf(Leadpos.Price__c);
                                }
                                catch (System.Exception e) {}
                            apList.add(AP);                        
                        }
                        
                        if((apList != null) && (apList.size() > 0) ) {
                            try {
                                inko_auftrag auftrag = new inko_auftrag(AU, apList);                                                 
                            }
                            catch(System.Exception e) {
                                insert_auftrag_error = true;
                                delete AU;
                                system.debug ('##################################alex102 id=' + 'Der Auftrag konnte nicht erzeugt werden.');
                            }
                        }                   
                }
                else {
                    keinAUgefunden = true;
                }
            }     
      
       List<Attachment> Attachments = [SELECT Name, Body, ContentType, IsPrivate, ParentID FROM Attachment WHERE ParentId= :qID];
       
       if((Attachments != null) && (Attachments.size() > 0)) {
           for(Attachment Attch: Attachments)
           {
                Attachment k_Attch = new Attachment();
                k_Attch.Name = Attch.Name;
                k_Attch.Body = Attch.Body;
                k_Attch.ContentType = Attch.ContentType;
                k_Attch.IsPrivate = Attch.IsPrivate;
                k_Attch.ParentID = k.ID;
                
                try {
                    insert k_Attch;
                }
                catch (System.exception e) {
                    system.debug ('##################################alex102 id=' + 'Das Attachment konnte nicht erzeugt werden.');
                }
           }
       }
      
      // List<Auftrag__c> Auflist = new List<Auftrag__c>();
      // if(keinAUgefunden == false) Auflist = [SELECT id, Name FROM Auftrag__c WHERE id= :AU.id LIMIT 1];      
              
       //l.Status = 'Qualified';
       try {
          /* if (insert_kunde_error)  {
               update l;
           }
           else 
          */
           List<Auftrag__c> Auflist = new List<Auftrag__c>();
           if(keinAUgefunden == false) Auflist = [SELECT id, Name FROM Auftrag__c WHERE id= :AU.id LIMIT 1];      
           if((insert_auftrag_error == false) && (insert_kunde_error == false)) {
                                             
               zeilenlist.clear();
               NeuZeilenlist.clear();
               Kdlist.clear();
               
               List<Kunde__c> klist = [SELECT Id, Vorname__c, Name__c, e_mail__c, Versichertennummer__c, Produktgruppe__c, Kundennummer_abena__c FROM Kunde__c WHERE Id = :k.id LIMIT 1];
               
               if((l.Company != 'Magento Shop') && (l.Company != 'Shop')) {
                   ergebnis = 'Der Kunde ' + '"' + k.Vorname__c + ' ' + k.Name__c + '"' +' wird mit folgenden Daten erstellt.';
                   Kdlist.add(Kd); 
                   gespeichert = true; 
               }
               else {
                   shop = true;
                   if(keinAUgefunden == true){
                       ergebnis = 'Der Kunde ' + '"' + k.Vorname__c + ' ' + k.Name__c + '"' +' wurde ohne Auftrag erstellt.';   
                       Zeile z = new Zeile(k.Vorname__c + ',' + k.Name__c, k.id);
                       z.k = klist[0];
                       zeilenlist.add(z);                        
                   }
                   else {
                       //Kdlist.add(Kd);
                       ergebnis = 'Der Kunde ' + '"' + k.Vorname__c + ' ' + k.Name__c + '"' +' wurde mit dem Auftrag ' + '"' + Auflist[0].Name + '"' +' erstellt.';      
                       Zeile z = new Zeile(k.Vorname__c + ',' + k.Name__c, Auflist[0].Name, k.id, AU.id);
                       z.k = klist[0];
                       zeilenlist.add(z);  
                   } 
                   gespeichert = false;  
              }               
               
              //25.10.2017 von MZ
              Curabox_zu_Kunde.saveWithSatndardLeadConvert(l.Id);  
              //delete l;
                              
                                
              Kdgefunden = false;
              KdNichtgefunden = false;
              fertig = true;   
              hatstatus = false;   
                      
          }
       }
       catch (System.Exception e) {
       }   
        
    
    }
                  
    public void auftragErstellen() {
    Map<String, Id> LeadposMap = new Map<String, Id>();
    Map<Decimal, Artikel__c> ArtMap = new Map<Decimal, Artikel__c>();
    boolean insert_auftrag_error = false;
    String qID = ApexPages.currentPage().getParameters().get('id');    
    List<Anschrift__c> reAN = new List<Anschrift__c>();         
    List<Anschrift__c> shopAN = new List<Anschrift__c>();
             
    kId = kdId;  
    List<Kunde__c> klist = [SELECT id, Vorname__c, Name__c, Betreuer__r.firstname, Betreuer__r.lastname, 
                                    Produktgruppe__c, Kundennummer_abena__c, magento_kundennummer__c 
                                FROM Kunde__c 
                                WHERE  id= :kdId];  
  
    if(l.billing_postal_code__c != null){
        
        reAN = [select id, Name, Ort__c, Stra_e__c, PLZ__c, Shoprechnungsanschrift__c
                                from Anschrift__c
                                where Name =: l.billing_lastname__c + ',' + l.billing_firstname__c
                                and Ort__c =: l.billing_city__c
                                and Stra_e__c =: l.billing_street__c
                                and PLZ__c =: ksgFunctions.formatPLZ(Decimal.valueOf(l.billing_postal_code__c)) limit 1];                                
    
    }
    else {
        reAN = [select id, Name, Ort__c, Stra_e__c, PLZ__c, Shoprechnungsanschrift__c
                                from Anschrift__c
                                where Name =: l.billing_lastname__c + ',' + l.billing_firstname__c
                                and Ort__c =: l.billing_city__c
                                and Stra_e__c =: l.billing_street__c limit 1];     
    }    
    
    if(l.shipping_postal_code__c != null){
        
        shopAN = [select id, Name, Ort__c, Stra_e__c, PLZ__c, Shoplieferanschrift__c
                                from Anschrift__c
                                where Name =: l.shipping_lastname__c + ',' + l.shipping_firstname__c
                                AND Art_der_Anschrift__c = 'Shop'
                                and Ort__c =: l.shipping_city__c
                                and Stra_e__c =: l.shipping_street__c
                                and PLZ__c =: ksgFunctions.formatPLZ(Decimal.valueOf(l.shipping_postal_code__c)) limit 1];                                
    
    }
    else {
        shopAN = [select id, Name, Ort__c, Stra_e__c, PLZ__c, Shoplieferanschrift__c
                                from Anschrift__c
                                where Name =: l.shipping_lastname__c + ',' + l.shipping_firstname__c
                                AND Art_der_Anschrift__c = 'Shop'
                                and Ort__c =: l.shipping_city__c
                                and Stra_e__c =: l.shipping_street__c limit 1];     
    }  
    
    Anschrift__c shop_addr1; 
    Anschrift__c shop_addr2;
    
    if((l.Company == 'Shop') || (l.Company == 'Magento Shop')) {
            
            if(reAN != null && reAN.size() != 0) {
                
                if(reAN[0].shoprechnungsanschrift__c == true) {
                }
                else {    
                  
                  List<Anschrift__c> UpdateReAnList = [select id, Shoprechnungsanschrift__c, Kunde__c
                                                    from Anschrift__c
                                                    where Shoprechnungsanschrift__c = true
                                                    and Kunde__c =: kdId];
                
                    if(UpdateReAnList != null && UpdateReAnList.size() != 0) {
                        for(Anschrift__c AN: UpdateReAnList){
                            AN.Shoprechnungsanschrift__c = false;
                        }
                
                        try {
                            update UpdateReAnList;
                        }
                        catch(System.exception e){
                            System.debug('###################BT2016 : Update von Shoprechnungsanschrift hat nicht funktioniert');
                        }
                    }            
                   
                   reAN[0].shoprechnungsanschrift__c = true; 
                   update reAN[0];
                }
            }
            else {
            shop_addr1 = new Anschrift__c();
            // shop_addr1.Name = l.lastname + ',' + l.firstname;
            shop_addr1.Name = l.billing_lastname__c + ',' + l.billing_firstname__c;
            shop_addr1.Anrede__c = l.Salutation;
            shop_addr1.Kunde__c = kdId;
            shop_addr1.Art_der_Anschrift__c = 'Shop';
            shop_addr1.e_mail__c = l.Email;
            shop_addr1.Fax__c = l.Fax;
            //inko_addr.Hausnummer__c = l.Hausnummer__c;
            shop_addr1.Ort__c = l.billing_city__c;
            if(l.billing_postal_code__c != null) shop_addr1.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.billing_postal_code__c));
            shop_addr1.Stra_e__c = l.billing_street__c;
            shop_addr1.Telefon__c = l.Phone; 
            shop_addr1.Shoprechnungsanschrift__c = True;
            
            List<Anschrift__c> UpdateReAnList = [select id, Shoprechnungsanschrift__c, Kunde__c
                                                    from Anschrift__c
                                                    where Shoprechnungsanschrift__c = true
                                                    and Kunde__c =: kdId];
                
                if(UpdateReAnList != null && UpdateReAnList.size() != 0) {
                    for(Anschrift__c AN: UpdateReAnList){
                        AN.Shoprechnungsanschrift__c = false;
                    }
                
                    try {
                        update UpdateReAnList;
                    }
                    catch(System.exception e){
                        System.debug('###################BT2016 : Update von Shoprechnungsanschrift hat nicht funktioniert');
                    }
                }
            }
            
            if(shopAN != null && shopAN.size() != 0) {
            
                if(shopAN[0].shoplieferanschrift__c == true) {
                }
                else {
                    List<Anschrift__c> UpdateShopAnList = [select id, Shoprechnungsanschrift__c, Kunde__c
                                                    from Anschrift__c
                                                    where Shoplieferanschrift__c = true
                                                    and Kunde__c =: kdId];
               
                      if(UpdateShopAnList != null && UpdateShopAnList.size() != 0) { 
                            for(Anschrift__c AN: UpdateShopAnList) {
                                AN.Shoplieferanschrift__c = false;
                            }
                
                            try {
                                Update UpdateShopAnList;                    
                            }
                            catch(System.exception e){
                                System.debug('###################BT2016 : Update von Shoplieferanschrift hat nicht funktioniert');
                            }
                      }
                      
                      shopAN[0].shoplieferanschrift__c = true;
                      update shopAN[0];
                }
            }
            else {
            shop_addr2 = new Anschrift__c();
            // shop_addr2.Name = l.lastname + ',' + l.firstname;
            shop_addr2.Name = l.shipping_lastname__c + ',' + l.shipping_firstname__c;
            shop_addr2.Anrede__c = l.Salutation;
            shop_addr2.Kunde__c = kdId;
            shop_addr2.Art_der_Anschrift__c = 'Shop';
            shop_addr2.e_mail__c = l.Email;
            shop_addr2.Fax__c = l.Fax;
            //inko_addr.Hausnummer__c = l.Hausnummer__c;
            shop_addr2.Ort__c = l.shipping_city__c;
            if(l.shipping_postal_code__c != null) shop_addr2.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.shipping_postal_code__c));
            shop_addr2.Stra_e__c = l.shipping_street__c;
            shop_addr2.Telefon__c = l.Phone;   
            shop_addr2.Shoplieferanschrift__c = true;
            
            List<Anschrift__c> UpdateShopAnList = [select id, Shoprechnungsanschrift__c, Kunde__c
                                                    from Anschrift__c
                                                    where Shoplieferanschrift__c = true
                                                    and Kunde__c =: kdId];
               
              if(UpdateShopAnList != null && UpdateShopAnList.size() != 0) { 
                    for(Anschrift__c AN: UpdateShopAnList) {
                        AN.Shoplieferanschrift__c = false;
                    }
                
                    try {
                        Update UpdateShopAnList;                    
                    }
                    catch(System.exception e){
                        System.debug('###################BT2016 : Update von Shoplieferanschrift hat nicht funktioniert');
                    }
              }
            
            }
           
            if(shop_addr1 != null && shop_addr2 != null) {
                string adresse1 = shop_addr1.Name + shop_addr1.Ort__c + shop_addr1.Stra_e__c + shop_addr1.PLZ__c;
                string adresse2 = shop_addr2.Name + shop_addr2.Ort__c + shop_addr2.Stra_e__c + shop_addr2.PLZ__c;
            
            
                if(adresse1 == adresse2) {
                   shop_addr2.Shoprechnungsanschrift__c = true;
                   shop_addr2.Shoplieferanschrift__c = true;
                   insert shop_addr2;                   
                }
                else {
                    insert shop_addr1;
                    insert shop_addr2;                   
                }    
            } 
            else {
            
                if(shop_addr1 != null){
                    insert shop_addr1;
                }
                
                if(shop_addr2 != null){
                    insert shop_addr2;
                }
            }
    
            List<Lead_Position__c>  LeadposList = [SELECT Id, EAN__c, Price__c, Lead__c, Qty_Ordered__c FROM Lead_Position__c WHERE Lead__c = :l.Id AND EAN__c != null]; 
            
            List<Decimal> EAN_list = new List<Decimal>();
            
            if((LeadposList != null) && (LeadposList.size() > 0)) {
                for(Lead_Position__c Leadpos : LeadposList) {
                     EAN_list.add(Decimal.valueOf(Leadpos.EAN__c));   
                }
            }
            
            list<Artikel__c> arList = [SELECT id, EVK__c, EVK_netto__c, a_pac_apo_EAN_UPC__c FROM Artikel__c WHERE a_pac_apo_EAN_UPC__c IN :EAN_list];
            
            List<String> art_EAN_list = new List<String>();
            
            if((arList != null) && (arList.size() > 0)) {
                for(Artikel__c art: arList)
                {                    
                    art_EAN_list.add(string.valueOf(art.a_pac_apo_EAN_UPC__c));
                    LeadposMap.put(string.valueOf(art.a_pac_apo_EAN_UPC__c), art.Id);
                    ArtMap.put(art.a_pac_apo_EAN_UPC__c, art);
                }
            }
            
            List<Lead_Position__c>  final_LeadposList = [SELECT Id, EAN__c, Price__c, Lead__c, Qty_Ordered__c FROM Lead_Position__c WHERE  Lead__c = :l.Id AND EAN__c IN :art_EAN_list];
            
                            
            list<Auftragsposition__c> apList = new list<Auftragsposition__c>();                    
            AU = new Auftrag__c(Kunde__c = kdId, 
                                            Bezeichnung__c = 'Shop', 
                                            Auftrag_text__c = 'Shop', 
                                            Lieferzeitraum__c = 'Einmalig',
                                            genehmigt_ab__c = date.today(),
                                            Genehmigungsstatus__c = 'genehmigt',
                                            Magento_increment_id__c = l.magento_increment_id__c,
                                            Magento_order_id_c__c = l.magento_order_id__c,
                                            Magento_payment_method_c__c = l.Magento_payment_method__c);
             
            if((final_LeadposList != null) && (final_LeadposList.size() > 0)) {
                        keinAUgefunden = false;
                                      
                        for (Lead_Position__c Leadpos : final_LeadposList) {
                            Auftragsposition__c AP = new Auftragsposition__c(Kunde__c = kdId,
                                                                            Artikel__c = LeadposMap.get(Leadpos.EAN__c),
                                                                            Gen_Menge_Stk_Mon__c = Decimal.ValueOf(Leadpos.Qty_Ordered__c),
                                                                            GenAnzVerp__c = Decimal.ValueOf(Leadpos.Qty_Ordered__c),
                                                                            genehmigt_ab__c = date.today(),
                                                                            Preis__c = ArtMap.get(Decimal.valueOf(Leadpos.EAN__c)).EVK__c,
                                                                            VK_netto__c = ArtMap.get(Decimal.valueOf(Leadpos.EAN__c)).EVK_netto__c);
                            
                            apList.add(AP);                        
                        }
                        
                        if((apList != null) && (apList.size() > 0) ) {
                            try {
                                inko_auftrag auftrag = new inko_auftrag(AU, apList);                                                 
                            }
                            catch(System.Exception e) {
                                insert_auftrag_error = true;
                                delete AU;
                                system.debug ('##################################alex102 id=' + 'Der Auftrag konnte nicht erzeugt werden.');
                            }
                        }                   
                }
                else {
                    keinAUgefunden = true;
                }
           
           List<Auftrag__c> Auflist = new List<Auftrag__c>();
           if(keinAUgefunden == false) Auflist = [SELECT id, Name FROM Auftrag__c WHERE id= :AU.id LIMIT 1]; 
                
           try{
               if((insert_auftrag_error == false) && (insert_kunde_error == false)) {           
               
               //25.10.2017 von MZ
               Curabox_zu_Kunde.saveWithSatndardLeadConvert(l.Id);  
               //delete l;
              
               zeilenlist.clear();
               NeuZeilenlist.clear();
               Kdlist.clear();
               Kdgefunden = false;
               KdNichtgefunden = false;
               fertig = true;
               hatstatus = false;
               
               if(keinAUgefunden == true) {  
                 ergebnis = 'Für den Kunden ' + '"' + klist[0].Vorname__c + ' ' + klist[0].Name__c + '"' + ' kann kein Auftrag erstellt werden.';
                 
                 Zeile z = new Zeile(klist[0].Vorname__c + ',' + klist[0].Name__c, kdId);
                 z.k = klist[0];
                 zeilenlist.add(z);
               } 
               else {

                ergebnis = 'Für den Kunden ' + '"' + klist[0].Vorname__c + ' ' + klist[0].Name__c + '"' + ' wurde der Auftrag ' + '"' + Auflist[0].Name + '"' +' erstellt.';
               
                Zeile z = new Zeile(klist[0].Vorname__c + ',' + klist[0].Name__c, Auflist[0].Name, kdId, AU.id);
                z.k = klist[0];
                zeilenlist.add(z);
               }
               
               if(klist[0].Produktgruppe__c == null) {
                   klist[0].Produktgruppe__c = 'Shop';
               }
               else {
                   klist[0].Produktgruppe__c = klist[0].Produktgruppe__c + ';Shop';
               }
               klist[0].magento_kundennummer__c = l.magento_kundennummer__c;
               update klist[0];
               
             }
           }
           catch(System.Exception e){}  
           
    }   
    else {                      
            klist[0].Inko_Frage1__c = l.inko_gender__c;
            klist[0].Inko_Frage2__c = l.inko_own_use__c;
            klist[0].Inko_Frage3__c = l.inko_already_in_use__c;
            klist[0].Inko_Frage4__c = l.inko_product_type__c;
            klist[0].Inko_Frage5__c = l.inko_change_cycle__c;
            klist[0].Inko_Frage6__c = l.inko_situation__c;
            klist[0].Inko_Frage7__c = l.inko_liquid_amount__c;
            klist[0].Inko_Frage8__c = l.inko_size__c;    
            // 04.12.2015
            klist[0].inko_Frage9__c = l.inko_recipe__c;
            klist[0].inko_Frage10__c = l.inko_insurance__c;
            klist[0].inko_Frage11__c = l.inko_support__c;                         
             
            Anschrift__c inko_addr = new Anschrift__c();
            inko_addr.Name = l.lastname + ',' + l.firstname;
            inko_addr.Anrede__c = l.Salutation;
            inko_addr.Kunde__c = klist[0].ID;
            inko_addr.Art_der_Anschrift__c = 'Inko';
            inko_addr.e_mail__c = l.Email;
            inko_addr.Fax__c = l.Fax;
            //inko_addr.Hausnummer__c = l.Hausnummer__c;
            inko_addr.Ort__c = l.City;
            if(l.PostalCode != null) inko_addr.PLZ__c = ksgFunctions.formatPLZ(Decimal.valueOf(l.PostalCode));
            inko_addr.Stra_e__c = l.Street;
            inko_addr.Telefon__c = l.Phone;    
            
            insert inko_addr;
            
            update klist[0];
            
            if(l.next_step__c != 'Beratung') {                               
            list<Auftragsposition__c> apList = new list<Auftragsposition__c>();                    
            AU = new Auftrag__c(Kunde__c =  kdId, 
                                            Bezeichnung__c = 'Muster-Artikel', 
                                            Auftrag_text__c = 'Muster-Artikel', 
                                            Lieferzeitraum__c = 'Einmalig',
                                            genehmigt_ab__c = date.today(),
                                            Genehmigungsstatus__c = 'genehmigt');
           
                if(!eanSet.isEmpty()) {
                    keinAUgefunden = false;
                    list<Artikel__c> arList = [SELECT id, Anlage_4_Preis__c FROM Artikel__c WHERE a_pac_apo_EAN_UPC__c IN :eanSet];
                    if((arList != null) && (arList.size() >0)) {
                        for (Artikel__c AR : arList) {                           
                            Auftragsposition__c AP = new Auftragsposition__c(Kunde__c = kdId,
                                                                            Artikel__c = AR.id,
                                                                            Gen_Menge_Stk_Mon__c = 1,
                                                                            GenAnzVerp__c = 1,
                                                                            genehmigt_ab__c = date.today(),
                                                                            Preis__c = 0.00,
                                                                            VK_netto__c = 0.00);
                                                                            
                            apList.add(AP);                                        
                        }
                        
                        if((apList != null) && (apList.size() > 0) ) {
                            try {
                                inko_auftrag auftrag = new inko_auftrag(AU, apList);
                            }
                            catch(System.Exception e) {
                                insert_auftrag_error = true;
                                delete AU;
                                system.debug ('##################################alex102 id=' + 'Der Auftrag konnte nicht erzeugt werden.');
                            }
                        }
                    }
                }
                else {
                    keinAUgefunden = true;  
                }
          }    
          else {
              keinAUgefunden = true;  
          }                                                       
      
       List<Attachment> Attachments = [SELECT Name, Body, ContentType, IsPrivate, ParentID FROM Attachment WHERE ParentId= :qID];
       
       if((Attachments != null) && (Attachments.size() > 0)) {
           for(Attachment Attch: Attachments)
           {
                Attachment k_Attch = new Attachment();
                k_Attch.Name = Attch.Name;
                k_Attch.Body = Attch.Body;
                k_Attch.ContentType = Attch.ContentType;
                k_Attch.IsPrivate = Attch.IsPrivate;
                k_Attch.ParentID = kdId;
                
                try {
                    insert k_Attch;
                }
                catch (System.exception e) {
                    system.debug ('##################################alex102 id=' + 'Das Attachment konnte nicht erzeugt werden.');
                }
           }
       }
       
       List<Auftrag__c> Auflist = new List<Auftrag__c>();
       if(keinAUgefunden == false)  Auflist = [SELECT id, Name FROM Auftrag__c WHERE id= :AU.id LIMIT 1];
       
       
       //l.Status = 'Qualified';
       try {
           /*
            if (insert_kunde_error)  {
               update l;
           }
           else 
           */
            if((insert_auftrag_error == false) && (insert_kunde_error == false)) {           
               
               //25.10.2017 von MZ
               Curabox_zu_Kunde.saveWithSatndardLeadConvert(l.Id);  
               //delete l;
               
               zeilenlist.clear();
               NeuZeilenlist.clear();
               Kdlist.clear();
               Kdgefunden = false;
               KdNichtgefunden = false;
               fertig = true;
               hatstatus = false;
           
                if(keinAUgefunden == true) {  
                    if(contgefunden == false) { 
                        ergebnis = 'Für den Kunden ' + '"' + klist[0].Vorname__c + ' ' + klist[0].Name__c + '"' + ' kann kein Auftrag erstellt werden.';  
                    }                   
                    else{
                        ergebnis = 'Für den Kunden ' + '"' + klist[0].Vorname__c + ' ' + klist[0].Name__c + '"' + ' (Angehöriger: ' + klist[0].Betreuer__r.firstname + ' ' +
                                 klist[0].Betreuer__r.lastname + ')' + ' kann kein Auftrag erstellt werden.';
                    } 
                 
                    Zeile z = new Zeile(klist[0].Vorname__c + ',' + klist[0].Name__c, kdId);
                    z.k = klist[0];
                    zeilenlist.add(z);
                } 
                else {
                    if(contgefunden == false) {
                       ergebnis = 'Für den Kunden ' + '"' + klist[0].Vorname__c + ' ' + klist[0].Name__c + '"' + ' wurde der Auftrag ' + '"' + Auflist[0].Name + '"' +' erstellt.';
                    }
                    else {
                        ergebnis = 'Für den Kunden ' + '"' + klist[0].Vorname__c + ' ' + klist[0].Name__c + '"' + ' (Angehöriger: ' + klist[0].Betreuer__r.firstname + ' ' +
                               klist[0].Betreuer__r.lastname + ')' + ' wurde der Auftrag ' + '"' + Auflist[0].Name + '"' +' erstellt.';
                    }  
               
                    Zeile z = new Zeile(klist[0].Vorname__c + ',' + klist[0].Name__c, Auflist[0].Name, kdId, AU.id);
                    z.k = klist[0];
                    zeilenlist.add(z);
                }
           
           
                if(klist[0].Produktgruppe__c == null) {
                    klist[0].Produktgruppe__c = 'Inko';
                }
                else {
                   klist[0].Produktgruppe__c = klist[0].Produktgruppe__c + ';Inko';
                }
                update klist[0];
                    
                List<Kundenstatus__c> kslist = [SELECT id, Kunde__c, Produktgruppe__c, Status__c FROM Kundenstatus__c WHERE Produktgruppe__c = 'Inko' AND Kunde__c = :klist[0].id];
                kslist[0].status__c = l.next_Step__c;   
                kslist[0].Ursprungsanfrage__c = l.OM_Wizzard_Name2__c;                  
            
                update kslist[0];
           
                /*
                id grID = UserInfo.getUserId(); 
                list<Group> grList = [SELECT id FROM Group WHERE Name = 'Inko' LIMIT 1];
                if((grList != null) && (grList.size() > 0)) {   
                  grID = grList[0].id;
                }
                list<GroupMember> gmList = [SELECT id, UserOrGroupId 
                                          FROM GroupMember WHERE GroupId = : grID];
                list<task> tsList = new list<task>();
                if((gmList != null) && (gmList.size() > 0)) { 
            
                    for(GroupMember GM : gmList) {
                    id rtid = null;
                    list<RecordType> rtList = [SELECT Id, Name FROM RecordType WHERE sObjectType='Task' AND Name = :'Inko'];
                        if((rtList != null) && (rtList.size() > 0)) {
                            rtid = rtList[0].id;
                        } 
                      
                        if(l.next_step__c == 'Gratisprobe'){
                         
                            task newTaskM = new Task(ActivityDate = Date.today()+7,
                                                Recordtypeid = rtid,
                                                Description = 'xxx',
                                                Priority = 'Normal',
                                                Status = 'offen',
                                                Subject = 'Nachtelefonie Inko-Muster',            
                                                WhatId = klist[0].ID,
                                                OwnerId = GM.UserOrGroupId,
                                                IsReminderSet = false
                                                   );
                            insert newTaskM;             
                        }             
                           
                    } 
                }
                */
            }

       }
       catch (System.Exception e) {
       } 
       
     }        
   }
    
    public void KundendatenUpdaten() {
        boolean insert_auftrag_error = false;
        Id kdId = Id.valueOf(l.OM_Tracking_Order_ID__c);
                
        system.debug ('##################################alex102 KdId=' + kdId );
                
        List<Kunde__c> klist = [SELECT Id, Vorname__c, Name__c, e_mail__c, Versichertennummer__c, Produktgruppe__c, 
                                        Kundennummer_abena__c, Geburtsdatum_text__c, IK_Nummer_des_Tr_gers__c, Krankenkasse__c,
                                        magento_kundennummer__c
                                FROM Kunde__c 
                                WHERE Id = :KdId LIMIT 1];
                
        if((klist != null) && (klist.size() > 0))
        {
          try {
                kdlist[0].magento_kundennummer__c = l.magento_kundennummer__c;
              update Kdlist[0];
              ergebnis = 'Die Daten des Kunden ' + '"' + klist[0].Vorname__c + ' ' + klist[0].Name__c + '"' +' wurden erfolgreich upgedatet.';
              zeilenlist.clear();
              NeuZeilenlist.clear();
              Kdlist.clear();
              Zeile zeile = new Zeile(klist[0].Vorname__c + ',' + klist[0].Name__c, kdId);
              zeile.k = klist[0];
              zeilenlist.add(zeile);
              
              //25.10.2017 von MZ
              Curabox_zu_Kunde.saveWithSatndardLeadConvert(l.Id);  
              //delete l;
              
          }
          catch (System.Exception e) {
               system.debug ('##################################alex102 id=' + 'Die Daten konnten nicht upgedatet werden.');
          }
                        
        }
                 
                
        Kdgefunden = false;
        KdNichtgefunden = false;
        fertig = true;   
        hatstatus = false;
        gespeichert = false;
        statusUpdate = false;
    }
    
    public void aenderungenSpeichern() {
        try {
               update Kd;
               
               List<Auftrag__c> Auflist = [SELECT id, Name FROM Auftrag__c WHERE id= :AU.id LIMIT 1];  
               List<Kunde__c> klist = [SELECT Id, Vorname__c, Name__c, e_mail__c, Versichertennummer__c, Produktgruppe__c, Kundennummer_abena__c FROM Kunde__c WHERE Id = :Kd.id LIMIT 1];
        
               if(keinAUgefunden == true){
                   zeilenlist.clear();
                   NeuZeilenlist.clear();
                   Kdlist.clear(); 
                   ergebnis = 'Der Kunde ' + '"' + Kd.Vorname__c + ' ' + Kd.Name__c + '"' +' wurde ohne Auftrag erstellt.';    
                   Zeile z = new Zeile(Kd.Vorname__c + ',' + Kd.Name__c, Kd.id);
                   z.k = klist[0];
                   zeilenlist.add(z); 
               }
               else {
                   zeilenlist.clear();
                   NeuZeilenlist.clear();
                   Kdlist.clear();
                   ergebnis = 'Der Kunde ' + '"' + Kd.Vorname__c + ' ' + Kd.Name__c + '"' +' wurde mit dem Auftrag ' + '"' + Auflist[0].Name + '"' +' erstellt.';      
                   Zeile z = new Zeile(Kd.Vorname__c + ',' + Kd.Name__c, Auflist[0].Name, Kd.id, AU.id);
                   z.k = klist[0];
                   zeilenlist.add(z);  
                }
        }
        catch (System.Exception e) {
               system.debug ('##################################BT102 id=' + 'Die Änderungen konnten nicht gespeichert werden.');
        }
            
        Kdgefunden = false;
        KdNichtgefunden = false;
        fertig = true;   
        hatstatus = false;
        gespeichert = false;
    }
    
    public Decimal aktuellerKdNr() {
        Decimal KdNr = 0;
        // List<Kunde__c>  gesamtKdlist= [SELECT id, Kundennummer_abena__c FROM Kunde__c LIMIT 1000];        
        
        // if((gesamtKdlist != null )&& (gesamtKdlist.size() > 0)) {
            // for(Kunde__c kunde: gesamtKdlist) {
                // if(kunde.Kundennummer_abena__c >= KdNr) KdNr = kunde.Kundennummer_abena__c;
             // }
        // }   
        
        list<Kunde__c> agKdnr = [SELECT Kundennummer__c 
                                    FROM Kunde__c 
                                    ORDER BY Kundennummer__c DESC NULLS LAST
                                    LIMIT 1];
        if(agKdnr != null) {
            try {
                KdNr = (decimal)agKdnr[0].Kundennummer__c;
            }
            catch (System.Exception e) {
                system.debug ('################################## kdnr error ' + e);
            }   
        }
        
        return KdNr;
    }
  /*  
    public string formatPLZ(decimal plz) {
        string fplz = '00000';
        integer iplz = null;
        try { 
            if((plz != null) && (plz > 0)) {
                iplz = integer.valueOf(plz);
                fplz = string.valueOf(iplz);
                while (fplz.length() < 5) fplz = '0' + fplz;
            }
        }
        catch(System.exception e)
        {
        }
    
        return fplz;
    }*/
    
    public List<Kunde__c> kunde() {
        if(leadEmail == null) {
            List<Kunde__c> Kdlist= [SELECT id, e_mail__c, Vorname__c, Name__c, Betreuer__r.Email, Betreuer__r.firstname, Betreuer__r.lastname, Kundennummer_abena__c, Produktgruppe__c
                                       FROM Kunde__c 
                                       WHERE  Name__c = :l.lastname AND Vorname__c = :l.firstname];

            try {
                return Kdlist;
            }
            catch(System.exception e) {
                return null;
            }                                       
        }
        else {
            List<Kunde__c> Kdlist= [SELECT id, e_mail__c, Vorname__c, Name__c, Betreuer__r.Email, Betreuer__r.firstname, Betreuer__r.lastname, Kundennummer_abena__c, Produktgruppe__c
                                       FROM Kunde__c 
                                       WHERE  e_mail__c = :leadEmail];

            try {
                return Kdlist;
            }
            catch(System.exception e) {
                return null;
            }                                       
        }
        
    }    
    
    public List<Kunde__c> cont_Kdlist() {
        if(leadEmail != null) {
            List<Kunde__c> cont_Kdlist= [SELECT id, e_mail__c, Vorname__c, Name__c, Betreuer__r.Email, Betreuer__r.firstname, Betreuer__r.lastname, Produktgruppe__c, Kundennummer_abena__c
                                         FROM Kunde__c 
                                         WHERE Betreuer__r.Email = :leadEmail];
                                         
            try {
                return cont_Kdlist;
            }
            catch(System.exception e) {
                return null;
            }
        }
        else {
            return null;
        }
        

    }
    
    public Date setStringToDateFormat(String myDate) { 
       try {
           String myDateOnly = myDate.replace('.', '/');              
           String[] strDate = myDateOnly.split('/');
           Integer myIntDate = integer.valueOf(strDate[0]);
           Integer myIntMonth = integer.valueOf(strDate[1]);
           Integer myIntYear = integer.valueOf(strDate[2]);
           
           
           if (myIntYear < 1700){
               myintYear = 1700;}
           else{
               if (myintyear >4000){
                   myintyear = 4000;}
               }
           
           Date d = Date.newInstance(myIntYear, myIntMonth, myIntDate);
           
           
           system.debug ('################################# WDS 01  Datum' + d);
       
           return d;
       }
       catch(System.exception e) {
            system.debug ('##################################BT Ungültiges Datum');            
       
            return null;
        }
    }
    
    public PageReference zurueck() {
        PageReference pageRef = new PageReference('/' + '00Q');
        pageRef.setRedirect(true);
        return pageRef;
    }      
    
    public boolean getInsert_kunde_error() {
         return insert_kunde_error;
    }
        
    public class zeile {
    
        public string KdName {get; set;}
        public string AufName {get; set;}
        public Id KdId {get; set;}
        public Id AufId {get; set;}
        public Kunde__c k {get; set;}
        public boolean keinStatus {get; set;}
        public PageReference KdPage {set;}
        public PageReference AUPage {set;}
        public string status;
    
        public zeile(string KName, string AUname, Id Kid, Id AUid){
            KdName = KName;
            AufName = AUname;
            KdId = Kid;
            AufId = AUid;
            keinStatus = false;
            
        }
        
        public zeile(string KName, Id Kid) {
            KdName = KName;
            KdId = Kid;
            keinStatus = false;
        }
        
        public string getStatus() {
            if(keinStatus == true) {
                Status = 'Nein';
            }
            else {
                Status = 'Ja';
            }
            
            return Status;
        }
        
        public PageReference getKdPage() {
            PageReference KdPage = new PageReference('/' + KdId);
            KdPage.setRedirect(true);
            return KdPage;
        }
        
        public PageReference getAUPage() {
            PageReference AUPage = new PageReference('/' + AufId);
            AUPage.setRedirect(true);
            return AUPage;
        }
    }          
}