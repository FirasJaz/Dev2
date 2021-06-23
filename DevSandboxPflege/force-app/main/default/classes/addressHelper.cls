//****************************************************************************************************************************
// Erstellt 02.06.2019 von AM
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
// Sorgt für das Anlegen der Anschriften (contact_address)
//
//
//****************************************************************************************************************************
//Änderungen:
// 29.09.2020	BT	#2580 set standard delivery address based on contact field CB_Lieferung__c
// 04.05.2021  FJ @Cloud Monsters GmbH - Add method checkStandardShippingAddress
//****************************************************************************************************************************
public class addressHelper {

    public static id readRecordTypeID() {
        id rtid = null;
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='contact' AND developername = 'Familienangeh_rige'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtid = rtList[0].id;
        } 
        return rtid;
    }

    public static map<id, string>  createNewAddress(List<contact> ctList) {
        List<contact_address__c> newList = new List<contact_address__c>();
        // key=bereuerId, value=contactId
        Map<id, id> betrIdMap = new Map<id, id>();
        Map<id, id> pdIdMap = new Map<id, id>();
        id rtid = readRecordTypeID();
        Map<id, string> wrongAddrContactSet = new Map<id, string>();
        // nur Kundenadresse
        for(contact c : ctList) {
            if(c.RecordTypeId == rtid) {
                contact_address__c ca = new contact_address__c();
                if(c.FirstName != null) {
                    ca.Name= c.FirstName + ' ' + c.LastName;
                } 
                else {
                    ca.Name= c.LastName;
                }
                if(ca.Name.length() > 80) {
                    ca.Name = ca.Name.substring(0, 79);
                }
                ca.Contact__c = c.id;
                system.debug('#### c.Name='+c.Name);
                ca.Type_of_Address__c = 'customer address';
                ca.Email__c = c.email;
                ca.Fax__c = c.fax;
                ca.Phone__c = c.Phone;
                ca.Street__c = c.MailingStreet;
                ca.Postal_code__c = c.MailingPostalCode;
                if(ca.Postal_code__c != null) {
                    if(ca.Postal_code__c.length() >10) ca.Postal_code__c = ca.Postal_code__c.substring(0, 9);
                }
                ca.City__c = c.MailingCity;
                // ca.Salutation__c = c.Salutation;
                // ca.Title__c = c.title;
                if(c.House_Number__c != null) {
                    ca.House_number__c = c.House_Number__c;                   
                    if(ca.House_number__c.length() >10) ca.House_number__c = ca.House_number__c.substring(0, 9);
                }
                
                if(c.Betreuer__c == null) 
                    ca.Standard_shipping_address__c = true;     
                else if(String.isBlank(c.CB_Lieferung__c) || c.CB_Lieferung__c == 'insured_person')              
					ca.Standard_shipping_address__c = true;
                
                newList.Add(ca);
                // ev. Betreuer
                if(c.Betreuer__c != null) {
                    betrIdMap.put(c.Betreuer__c, c.id);
                }
                if(c.Pflegedienst__c != null) {
                    pdIdMap.put(c.Pflegedienst__c, c.id);
                }
            }

        }

        if(!betrIdMap.isEmpty()) {
            List<contact> bcList = [SELECT id, FirstName, LastName, Phone, MailingCity, MailingPostalCode, 
                                        Mailingstreet, Fax, Email, House_Number__c, CB_Lieferung__c
                                        FROM Contact 
                                        WHERE ID IN : betrIdMap.keySet()];
            if((bcList != null) && (bcList.size()>0)) {
                for(contact c : bcList) {
                    contact_address__c ca = new contact_address__c();
                    if(c.FirstName != null) {
                        ca.Name= c.FirstName + ' ' + c.LastName;
                    } 
                    else {
                        ca.Name= c.LastName;
                    }
                    if(ca.Name.length() > 80) {
                            ca.Name = ca.Name.substring(0, 79);
                    }
                    ca.Contact__c = betrIdMap.get(c.id);
                    ca.Type_of_Address__c = 'family member';
                    ca.Email__c = c.email;
                    ca.Fax__c = c.fax;
                    ca.Phone__c = c.Phone;
                    ca.Street__c = c.MailingStreet;
                    if(c.MailingPostalCode != null) {
                        ca.Postal_code__c = c.MailingPostalCode;
                        if(ca.Postal_code__c.length() >10) ca.Postal_code__c = ca.Postal_code__c.substring(0, 9);
                    }
                    ca.City__c = c.MailingCity;
                    // ca.Salutation__c = c.Salutation;
                    // ca.Title__c = c.title;
                    if(c.House_Number__c != null) {
                        ca.House_number__c = c.House_Number__c;
                        if(ca.House_number__c.length() >10) ca.House_number__c = ca.House_number__c.substring(0, 9);
                    }
                    if(c.CB_Lieferung__c == 'care_person') ca.Standard_shipping_address__c = true;
                    // ca.Standard_shipping_address__c = true;
                    newList.Add(ca);                    
                }
            }
        }

        if(!pdIdMap.isEmpty()) {
            List<account> acList = [SELECT id, Name, Phone, BillingCity, BillingPostalCode, 
                                        Billingstreet, Fax
                                        FROM account 
                                        WHERE ID IN : pdIdMap.keySet()];
            if((acList != null) && (acList.size()>0)) {
                for(account c : acList) {
                    contact_address__c ca = new contact_address__c();

                    ca.Name= c.Name;
                    if(ca.Name.length() > 80) {
                        ca.Name = ca.Name.substring(0, 79);
                    }
                    ca.Contact__c = pdIdMap.get(c.id);
                    ca.Type_of_Address__c = 'care service';
                    ca.Fax__c = c.fax;
                    ca.Phone__c = c.Phone;
                    ca.Street__c = c.BillingStreet;
                    ca.Postal_code__c = c.BillingPostalCode;
                    if(ca.Postal_code__c != null) {
                        if(ca.Postal_code__c.length() >10) ca.Postal_code__c = ca.Postal_code__c.substring(0, 9);
                    }
                    ca.City__c = c.BillingCity;
                    newList.Add(ca);                    
                }
            }
        }

        Database.SaveResult[] srList = Database.insert(newList, false);
        Integer i = 0;
        
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // alles ok
                system.debug('#### ok');
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    system.debug('#################alex7705 error=' + err.getMessage()); 
                    wrongAddrContactSet.put(newList[i].Contact__c, err.getMessage());    
                }
            }
            i++;
        }           
      
        return wrongAddrContactSet;
    }

    // wenn die contact Adresse/Name geändert soll auch die 'customer address' geändert werden
    public static map<id, string> onUpdateContact(List<contact> ctList, map<id, contact> oldMap) {
        List<contact_address__c> newList = new List<contact_address__c>();
        id rtid = readRecordTypeID(); 
        Map<id, id> betrIdMap = new Map<id, id>();
        Map<id, id> pdIdMap = new Map<id, id>();
        Map<id, string> wrongAddrContactSet = new Map<id, string>();
        Map<id, contact> wasChanged = new Map<id, contact>();       
        for(contact c : ctList) {
            // nur für Familienangehöriger
            if(c.RecordTypeId == rtid) {
                system.debug('### c=' + c);
                // felder aus adresse 
                if((c.MailingStreet != oldMap.get(c.id).MailingStreet)
                 || (c.MailingPostalCode != oldMap.get(c.id).MailingPostalCode)
                 || (c.MailingCity != oldMap.get(c.id).MailingCity)
                 || (c.House_Number__c != oldMap.get(c.id).House_Number__c)
                //  || (c.Salutation != oldMap.get(c.id).Salutation)
                //  || (c.title != oldMap.get(c.id).title)
                 || (c.FirstName != oldMap.get(c.id).FirstName)
                 || (c.LastName != oldMap.get(c.id).LastName)
                 ) {
                     wasChanged.put(c.id, c);
                     system.debug('### c.id=' + c.id);
                 }

                // ev. Betreuer
                if(((c.Betreuer__c != null) && (oldMap.get(c.id).Betreuer__c == null)) 
                || ((c.Betreuer__c != null) && (oldMap.get(c.id).Betreuer__c != null) && (c.Betreuer__c != oldMap.get(c.id).Betreuer__c))){

                    betrIdMap.put(c.Betreuer__c, c.id);
                }
                if(((c.Pflegedienst__c != null) && (oldMap.get(c.id).Pflegedienst__c == null)) 
                   || ((c.Pflegedienst__c != null) && (oldMap.get(c.id).Pflegedienst__c != null) && (c.Pflegedienst__c != oldMap.get(c.id).Pflegedienst__c)) )
                {
                    pdIdMap.put(c.Pflegedienst__c, c.id);
                }


            }
        }
        if(!wasChanged.isEmpty()) {
            system.debug('####### alex3300');
            List<contact_address__c> caList = [SELECT Name, id, Contact__c, Street__c, City__c, Postal_code__c, House_Number__c
                                                FROM contact_address__c
                                                WHERE Type_of_Address__c = 'customer address'
                                                AND Contact__c IN :wasChanged.keySet()];
            System.debug('##### lex 3301 ' + caList.size());
            if((caList != null) && (caList.size() > 0)) {
                for(contact_address__c ca : caList) {
                    if(wasChanged.get(ca.Contact__c).FirstName != null) {
                        ca.Name= wasChanged.get(ca.Contact__c).FirstName + ' ' + wasChanged.get(ca.Contact__c).LastName;
                    } 
                    else {
                        ca.Name= wasChanged.get(ca.Contact__c).LastName;
                    }
                    ca.Street__c = wasChanged.get(ca.Contact__c).MailingStreet;
                    ca.Postal_code__c = wasChanged.get(ca.Contact__c).MailingPostalCode;
                    ca.City__c = wasChanged.get(ca.Contact__c).MailingCity;
                    // ca.Salutation__c = wasChanged.get(ca.Contact__c).Salutation;
                    // ca.Title__c = wasChanged.get(ca.Contact__c).title;
                    ca.House_number__c = wasChanged.get(ca.Contact__c).House_Number__c;
                }
            }
            Database.SaveResult[] srList = Database.update(caList, false);
            Integer i = 0;
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // alles ok
                    system.debug('#### ok');
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        system.debug('#################alex7705 error=' + err.getMessage()); 
                        wrongAddrContactSet.put(caList[i].Contact__c, err.getMessage());    
                    }
                }
                i++;
            }           
        }
       if(!betrIdMap.isEmpty()) {
            List<contact> bcList = [SELECT id, FirstName, LastName, Phone, MailingCity, MailingPostalCode, 
                                        Mailingstreet, Fax, Email, House_Number__c
                                        FROM Contact 
                                        WHERE ID IN : betrIdMap.keySet()];
            if((bcList != null) && (bcList.size()>0)) {
                for(contact c : bcList) {
                    contact_address__c ca = new contact_address__c();
                    if(c.FirstName != null) {
                        ca.Name= c.FirstName + ' ' + c.LastName;
                    } 
                    else {
                        ca.Name= c.LastName;
                    }
                    ca.Contact__c = betrIdMap.get(c.id);
                    ca.Type_of_Address__c = 'family member';
                    ca.Email__c = c.email;
                    ca.Fax__c = c.fax;
                    ca.Phone__c = c.Phone;
                    ca.Street__c = c.MailingStreet;
                    ca.Postal_code__c = c.MailingPostalCode;
                    ca.City__c = c.MailingCity;
                    if(c.House_Number__c != null) {
                        ca.House_number__c = c.House_Number__c;
                    }
                    newList.Add(ca);                    
                }
            }
        }

        if(!pdIdMap.isEmpty()) {
            List<account> acList = [SELECT id, Name, Phone, BillingCity, BillingPostalCode, 
                                        Billingstreet, Fax
                                        FROM account 
                                        WHERE ID IN : pdIdMap.keySet()];
            if((acList != null) && (acList.size()>0)) {
                for(account c : acList) {
                    contact_address__c ca = new contact_address__c();

                    ca.Name= c.Name;

                    ca.Contact__c = pdIdMap.get(c.id);
                    ca.Type_of_Address__c = 'care service';
                    ca.Fax__c = c.fax;
                    ca.Phone__c = c.Phone;
                    ca.Street__c = c.BillingStreet;
                    ca.Postal_code__c = c.BillingPostalCode;
                    ca.City__c = c.BillingCity;
                    newList.Add(ca);                    
                }
            }
        }

        Database.SaveResult[] srList = Database.insert(newList, false);
        Integer i = 0;
        
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // alles ok
                system.debug('#### ok');
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    system.debug('#################alex7705 error=' + err.getMessage()); 
                    wrongAddrContactSet.put(newList[i].Contact__c, err.getMessage());    
                }
            }
            i++;
        } 
        return wrongAddrContactSet;
    }

    public static void insertNewAddress(List<contact_address__c> cList) {

        Set<id> parentSet = new set<id>();
        Set<id> caSet = new set<id>();
        for(contact_address__c ca : cList) {
            if(ca.Standard_shipping_address__c == true) {
                parentSet.add(ca.Contact__c);
                caSet.add(ca.id);
            }
        }
        if(!parentSet.isEmpty()) {
            List<contact_address__c> caList = [SELECT id, Contact__c, Standard_shipping_address__c
                                                FROM contact_address__c
                                                WHERE Contact__c IN :parentSet
                                                AND id NOT IN : caSet];
            if((caList != null) && (caList.size() > 0)) {
                for(contact_address__c ca : caList) {
                    // also alle andere Adressen sind nicht mehr standard
                    ca.Standard_shipping_address__c = false;
                }
            }
            Database.SaveResult[] srList = Database.update(caList, false);
            Integer i = 0;
            
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // alles ok
                    system.debug('#### ok');
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        system.debug('#################alex7705 error=' + err.getMessage()); 
                        caList[i].addError(' Adresse konnte nicht erfasst werden. ' + err.getMessage());    
                    }
                }
                i++;
            }                        
        }
    }

    // da prüfen wir ob eine 'customer address' bereits existiert
    // "Es kann nur einen geben"
    public static void checkBeforeinsertNewAddress(List<contact_address__c> cList) {
        Set<id> parentSet = new set<id>();
        Set<id> parentSubSet = new set<id>();
        for(contact_address__c ca : cList) {
            if(ca.Type_of_Address__c == 'customer address') {
                parentSet.add(ca.Contact__c);
            }
        }    
        if(!parentSet.isEmpty()) {
            List<contact_address__c> caList = [SELECT Contact__c FROM contact_address__c 
                                                WHERE Type_of_Address__c = 'customer address'
                                                AND Contact__c IN : parentSet];
            if((caList != null) && (caList.size() > 0)) {
                for(contact_address__c ca : caList) {
                    parentSubSet.add(ca.Contact__c);
                }
            }
            if(!parentSubSet.isEmpty()) {
                for(contact_address__c ca : cList) {
                    if(parentSubSet.contains(ca.Contact__c)) {
                        ca.addError('contact has already the "customer address". Please select other address type.');
                    }
                }                 
            }                
        }            
    }

    // da prüfen wir ob eine 'customer address' bereits existiert bei update
    public static void checkBeforeUpdateAddress(List<contact_address__c> cList, map<id, contact_address__c> oldMap) {
        
        Set<id> parentSet = new set<id>();
        Set<id> parentSubSet = new set<id>();
        for(contact_address__c ca : cList) {
            if((ca.Type_of_Address__c == 'customer address') && (oldMap.get(ca.id).Type_of_Address__c != 'customer address')) {
                parentSet.add(ca.Contact__c);
            }

        }    
        if(!parentSet.isEmpty()) {
            List<contact_address__c> caList = [SELECT Contact__c FROM contact_address__c 
                                                WHERE Type_of_Address__c = 'customer address'
                                                AND Contact__c IN : parentSet];
            if((caList != null) && (caList.size() > 0)) {
                for(contact_address__c ca : caList) {
                    parentSubSet.add(ca.Contact__c);
                }
            }
            if(!parentSubSet.isEmpty()) {
                for(contact_address__c ca : cList) {
                    if(parentSubSet.contains(ca.Contact__c)) {
                        ca.addError('contact has already the "customer address". Please select other address type.');
                    }
                }                 
            }                
        }            
    }

    public static void checkStandard(List<contact_address__c> cList, map<id, contact_address__c> oldMap) {
        Map<id, id> standardChanged = new Map<id, id>();
        for(contact_address__c ca : cList) {
            if((ca.Standard_shipping_address__c == true) && (oldMap.get(ca.id).Standard_shipping_address__c == false)) {
                standardChanged.put(ca.Contact__c, ca.id);
            }
        }  
        if(!standardChanged.isEmpty()) {   
            List<contact_address__c> caList = [SELECT id, Contact__c, Standard_shipping_address__c FROM contact_address__c WHERE Contact__c IN : standardChanged.keySet() ];
            for(contact_address__c ca : caList) {
                if(ca.id != standardChanged.get(ca.Contact__c)) {
                    ca.Standard_shipping_address__c = false;
                }
            }
            update caList;
        }     
    } 

    public static void checkBeforeDeleteAddress(List<contact_address__c> cList) {
        for(contact_address__c ca : cList) {
            if(ca.Standard_shipping_address__c == true) {
                ca.addError('Default delivery address can not be deleted.');
            }
        }               
    }

    /**
    * to be ensured that we do have exactly one standard shipping address 
    * @param newMap The newMap context variable of the trigger
    * @param oldMap The oldMap context variable of the trigger
    * @return  void
    */
    public static void checkStandardShippingAddress(Map<Id, contact_address__c> newMap, Map<Id, contact_address__c> oldMap){

       Set<Id> contactIdSet = new Set <Id>();
       List<contact_address__c> contactAddressList = new List<contact_address__c>();
       Map<String,List<contact_address__c>> contactIdToAddressMap = new Map<String,List<contact_address__c>>() ;
    
       //Iterate over all old values
       for (contact_address__c address : oldMap.values())
       {
           if(newMap.get(address.id).Standard_shipping_address__c == false &&  address.Standard_shipping_address__c == true) {
            contactIdSet.add(newMap.get(address.id).contact__c);
            contactAddressList.add(newMap.get(address.id));
           }
       }
        //Return if we have no case to handle
        if (contactAddressList.isEmpty())
        {
            return;
        }


        List<Contact> allRelevantAddresses = new List<Contact>([SELECT Id, (SELECT Id, contact__c, Standard_shipping_address__c FROM contact_address__r ) FROM Contact WHERE Id IN: contactIdSet]);
          //Iterate over each contact and prepare a map of contactId and  associated addresses
          for(Contact lObjContact : allRelevantAddresses)
          {
              if(lObjContact.contact_address__r.isEmpty())
                  continue;
  
                  contactIdToAddressMap.put(lObjContact.Id, lObjContact.contact_address__r);
          }
            
          // main loop, iterate over records and check if the size of associated addresses with Standard_shipping_address__c = true
         for (contact_address__c newAddress : contactAddressList){
            integer count =0 ;
            List<contact_address__c> addresseList = contactIdToAddressMap.get(newAddress.contact__c);
             for (contact_address__c address :addresseList ){
                if(newAddress.id != Address.id && address.Standard_shipping_address__c == true)
                  count ++ ;
             }
             if(count ==0) 
             newAddress.addError(System.Label.CONTACT_ADDRESS_ERR_ONLY_ONE_STANDARD_SHIPPING);   
          }

         
        }
      
    }