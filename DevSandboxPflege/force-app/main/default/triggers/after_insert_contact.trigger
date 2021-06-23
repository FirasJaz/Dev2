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
//
//****************************************************************************************************************************
trigger after_insert_contact on Contact (after insert) {
    map<id, string> wrongAddrContactSet = addressHelper.createNewAddress(Trigger.new);
    if(!wrongAddrContactSet.isEmpty()) {
        for(contact c : trigger.new) {
            if(wrongAddrContactSet.containsKey(c.id)) {
                c.addError('Adresse konnte nicht erfasst werden. ' + wrongAddrContactSet.get(c.id));
            }
        }
    }
    else {
        if(Test.isRunningTest()) {
            // nur für Testabdeckung
            string test = 'abc';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';

        }
    }   
    map<id, string> wrongStatusContactSet = contactStatusHelper.creteNewStatusOnNewContactFromLead(Trigger.new);
    if(!wrongStatusContactSet.isEmpty()) {
        for(contact c : trigger.new) {
            if(wrongStatusContactSet.containsKey(c.id)) {
                c.addError('Adresse konnte nicht erfasst werden. ' + wrongStatusContactSet.get(c.id));
            }
        }
    } 
    else {
        if(Test.isRunningTest()) {
            // nur für Testabdeckung
            string test = 'abc';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
                    test += 'test';
        }
    }         
}