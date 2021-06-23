//****************************************************************************************************************************
// Erstellt 19.03.2015     von wds
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
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
// trigger 
//
//
//****************************************************************************************************************************
//Änderungen:
//
// 25.08.2015 von AM    #100636896 Kundenstatus als Object
// 04.09.2015 von wds              Schließen von Nachtelefonie Inko
// 21.09.2015 von BT    #102159728 PG51 auf Kandidat setzen
// 30.11.2015 von BT    #108960754 Unterscheidung zwischen "Nachtelefonie INKO-Formular" und "Nachtelefonie INKO-Muster"
// 29.12.2015 von AM    #109702494 LS-Feld Ausgeliefert_am füllen
// 26.05.2017   AM      Genehmigung_att überall anpassen
//                      GN.attachmentID__c, LS.Gen.id, LS.GenehmigungAttID__c, LB.genehmigung_att_id__c 
// 15.06.2017   AM      Schließen Task 'Ist PG51 gewünscht ?' beim Hochladen "Antrag_PG51"
// 07.01.2019   AM      #163017625 - start ASB_CSV on upload joblog
// 16.04.2019   MZ      00002014 after_insert_attachment: execution of AfterDelete. caused by: System.QueryException: Non-selective query against large object type (more than 200000 rows).   
//                      Trigger.after_insert_attachment: line 144, column 1. try-catch added.
//****************************************************************************************************************************
// Test: after_insert_attachment_test.cls
//****************************************************************************************************************************
trigger after_insert_attachment on Attachment (after delete, after insert) {
   
    ID pid;
    ID aid;
    map<ID, String> GenIdMap= new map<ID, string>();
    Set<ID> GenIDset = new Set<ID>();
    
    map<ID, Genehmigung__c> GenMap51= new map<ID, Genehmigung__c>();
    map<ID, Genehmigung__c> GenMap54= new map<ID, Genehmigung__c>();
    map<ID, ID> GenAtt51Map= new map<ID, ID>();
    map<ID, ID> GenAtt54Map= new map<ID, ID>();
    
    Set<ID> Kandidat54IDset = new Set<ID>();
    Set<ID> Kandidat51IDset = new Set<ID>();
    Set<ID> Kandidat5XIDset = new Set<ID>();
    Set<ID> Kunde54IDset = new Set<ID>();
    Set<ID> Kunde51IDset = new Set<ID>();
    Set<ID> InkoIDset = new Set<ID>();
    Set<ID> InkoFormIDset = new Set<ID>();
    set<id> lsIDSet = new set<id>();
    set<id> lsIDxmlSet = new set<id>();
    set<id> lsIDxmlSet2 = new set<id>();
    set<id> txtSet = new set<id>();
    map<id, id> abMap = new map<id, id>();
    map<id, id> lsMap = new map<id, id>();
    if(trigger.isInsert) {
        system.debug('#########################alex101 trigger.isInsert');   
        for(Attachment att: Trigger.new){
            pid = att.ParentID; 
            aid = att.id;
            if((pid != null) &&(aid != null)  ) {
                // deprecated 
                if (pid.getSObjectType().getDescribe().getName() == 'Genehmigung__c'){
                    system.debug('#########################alex102 trigger.isInsert pid=' + pid + ' aid=' + aid);
                    GenIdMap.put(pid, string.valueOf(aid));
                }

                if (pid.getSObjectType().getDescribe().getName() == 'ksgLoader__c'){
                    txtSet.add(aid);
                }
                
                if (pid.getSObjectType().getDescribe().getName() == 'Kunde__c'){
                    system.debug('#########################alex200 trigger.isInsert att.Name=' + att.Name);
                    if(att.Name.contains('Antrag')) {
                            if(att.Name.contains('PG54')){
                                Kandidat54IDset.add(pid);
                            } 
                            else if(att.Name.contains('PG51')){
                                Kandidat51IDset.add(pid);
                            }
                            else {
                                Kandidat5XIDset.add(pid);
                            }
                    }
                    if(att.Name.contains('Genehmigung')) {
                        if(att.Name.contains('51')) { 
                            Kunde51IDset.add(pid);
                            GenAtt51Map.put(pid, aid);
                        }
                        else {
                            Kunde54IDset.add(pid);  
                            GenAtt54Map.put(pid, aid);                          
                        }                           
                    }
                    if(att.Name.contains('Inkoformular')) {                    
                        InkoFormIDset.add(pid);
                    }  
                    if(att.Name.contains('Inko')&&!att.Name.contains('Inkoformular')) {
                        InkoIDset.add(pid);
                    } 
                }
                if (pid.getSObjectType().getDescribe().getName() == 'Lieferschein__c'){
                    if(!att.Name.toUpperCase().contains('.XML')) {
                        if(att.Name.toUpperCase().contains('ABLIEFERBELEG')) {
                            lsIDSet.add(pid);
                            abMap.put(pid, aid);
                        }
                        if(att.Name.toUpperCase().contains('LIEFERSCHEIN')) {
                            lsMap.put(pid, aid);                            
                        }
                    }
                    else {
                        if(lsIDxmlSet.size() > 9998) {
                            lsIDxmlSet2.add(pid);
                        }
                        else lsIDxmlSet.add(pid);
                    }
                }
            }
        }
    }
    
    if(trigger.isDelete) {   
        system.debug('#########################alex103 trigger.isDelete'); 
        boolean error = false;
        set<string> delAttGen = new set<string>();
        for(Attachment att: Trigger.old){
            pid = att.ParentID; 
            aid = att.id;
            if((pid != null) &&(aid != null) && (pid.getSObjectType().getDescribe().getName() == 'Kunde__c') ) {
                 if(att.Name.contains('Genehmigung')) delAttGen.add(string.valueOf(aid));              
            }
        }
        if(!delAttGen.isEmpty()) {
            // 00002014 - try-catch added
            try{
                // GN 
                list<Genehmigung__c> gnList = [SELECT id, attachmentID__c FROM Genehmigung__c WHERE attachmentID__c IN : delAttGen LIMIT 1000];
                // LS 
                list<Lieferschein__c> lseList = [SELECT id, GenehmigungAttID__c FROM Lieferschein__c WHERE GenehmigungAttID__c IN : delAttGen LIMIT 1000];
                if( ((gnList != null) && (gnList.size() > 0)) || ((gnList != null) && (gnList.size() > 0))) {
                    error = true;
                }
                if(error) {
                    for(Attachment att: Trigger.old) att.AddError('Der Anhang kann nicht gelöscht werden');
                }
            }catch(System.QueryException e){
                for(Attachment att: Trigger.old) att.AddError('Der Anhang kann nicht gelöscht werden');
            }
        }
    }
    
    // Genehmigingslist 
    // Passende Genehmigung finden
    if(!Kunde51IDset.isEmpty()) {
        
        list<Genehmigung__c> GNlist = [SELECT unbefristet_genehmigt__c, genehmigt_bis__c, genehmigt_ab__c, 
                    Name__c, Id, Kunde__c, Name, attachmentID__c 
                    FROM Genehmigung__c
                    WHERE (((genehmigt_ab__c <= TODAY) AND (genehmigt_bis__c >= TODAY)) OR (unbefristet_genehmigt__c = true))
                    AND Status__c IN ('Bewilligung', 'Teilbewilligung')
                    AND Name__c = 'PG51'
                    AND Kunde__c IN :Kunde51IDset
                    ORDER BY createddate DESC];   
        if((GNlist != null) && (GNlist.size() > 0)) {
            for(Genehmigung__c gn : GNlist) {
                if(!GenMap51.ContainsKey(gn.Kunde__c)) GenMap51.put(gn.Kunde__c, gn);                
            }
        }
        
        for(Genehmigung__c GN : GenMap51.Values()) {
            if(GenAtt51Map.containsKey(GN.Kunde__c)) GN.attachmentID__c = string.valueOf(GenAtt51Map.get(GN.Kunde__c));
        }
        
        try {
            update GNlist;
        }
        catch (System.Exception e) {
            system.debug(logginglevel.error, '#########################alex2202 update GNlist error=' + e);
        }   
        
        list<Lieferbest_tigung__c> lbList = [SELECT id, Lieferschein__c, Kunde__c, genehmigung_att_id__c
                                                FROM Lieferbest_tigung__c
                                                WHERE Kunde__c IN : Kunde51IDset
                                                AND Rechnung__c = null];
        if((lbList != null) && (lbList.size() > 0 )) {
            set<id> lslbset = new set<id>();
            for(Lieferbest_tigung__c LB : lbList) {
                if(GenAtt51Map.containsKey(LB.Kunde__c)) LB.genehmigung_att_id__c = string.valueOf(GenAtt51Map.get(LB.Kunde__c));
                lslbset.add(LB.Lieferschein__c);
            }
            try {
                update lbList;
            }
            catch (System.Exception e) {
                system.debug(logginglevel.error, '#########################alex2200 update lblist error=' + e);
            }
            if(!lslbset.isEmpty()) {
                list<Lieferschein__c> lsgnList = [SELECT id, Kunde__c, Genehmigung__c, GenehmigungAttID__c
                                                    FROM Lieferschein__c
                                                    WHERE id IN : lslbset];
                if((lsgnList != null) && (lsgnList.size() > 0 )) {
                    for(Lieferschein__c LS : lsgnList) {
                        if(GenMap51.ContainsKey(LS.Kunde__c)) LS.Genehmigung__c = GenMap51.get(LS.Kunde__c).id;
                        if(GenAtt51Map.containsKey(LS.Kunde__c)) LS.GenehmigungAttID__c = string.valueOf(GenAtt51Map.get(LS.Kunde__c));
                    }
                }
                try {
                    update lsgnList;
                }
                catch (System.Exception e) {
                    system.debug(logginglevel.error, '#########################alex2201 update lsgnList error=' + e);
                }               
            }   
        }       
    }
    
    if(!Kunde54IDset.isEmpty()) {   
        list<Genehmigung__c>  GNlist = [SELECT unbefristet_genehmigt__c, genehmigt_bis__c, genehmigt_ab__c, 
                    Name__c, Id, Kunde__c, Name, attachmentID__c 
                    FROM Genehmigung__c
                    WHERE (((genehmigt_ab__c <= TODAY) AND (genehmigt_bis__c >= TODAY)) OR (unbefristet_genehmigt__c = true))
                    AND Status__c IN ('Bewilligung', 'Teilbewilligung')
                    AND Name__c = 'PG54'
                    AND Kunde__c IN :Kunde54IDset
                    ORDER BY createddate DESC];   
        if((GNlist != null) && (GNlist.size() > 0)) {
            for(Genehmigung__c gn : GNlist) {
                if(!GenMap54.ContainsKey(gn.Kunde__c)) GenMap54.put(gn.Kunde__c, gn);
            }
        }
        for(Genehmigung__c GN : GenMap54.Values()) {
            if(GenAtt54Map.containsKey(GN.Kunde__c)) GN.attachmentID__c = string.valueOf(GenAtt54Map.get(GN.Kunde__c));
        }
        
        try {
            update GNlist;
        }
        catch (System.Exception e) {
            system.debug(logginglevel.error, '#########################alex2202 update GNlist error=' + e);
        }       
        
        
        
        list<Lieferbest_tigung__c> lbList = [SELECT id, Lieferschein__c, Kunde__c, genehmigung_att_id__c
                                                FROM Lieferbest_tigung__c
                                                WHERE Kunde__c IN : Kunde54IDset
                                                AND Rechnung__c = null];
        if((lbList != null) && (lbList.size() > 0 )) {
            set<id> lslbset = new set<id>();
            for(Lieferbest_tigung__c LB : lbList) {
                if(GenAtt54Map.containsKey(LB.Kunde__c)) LB.genehmigung_att_id__c = string.valueOf(GenAtt54Map.get(LB.Kunde__c));
                lslbset.add(LB.Lieferschein__c);
            }
            try {
                update lbList;
            }
            catch (System.Exception e) {
                system.debug(logginglevel.error, '#########################alex2200 update lblist error=' + e);
            }
            if(!lslbset.isEmpty()) {
                list<Lieferschein__c> lsgnList = [SELECT id, Kunde__c, Genehmigung__c, GenehmigungAttID__c
                                                    FROM Lieferschein__c
                                                    WHERE id IN : lslbset];
                if((lsgnList != null) && (lsgnList.size() > 0 )) {
                    for(Lieferschein__c LS : lsgnList) {
                        if(GenMap54.ContainsKey(LS.Kunde__c)) LS.Genehmigung__c = GenMap54.get(LS.Kunde__c).id;
                        if(GenAtt54Map.containsKey(LS.Kunde__c)) LS.GenehmigungAttID__c = string.valueOf(GenAtt54Map.get(LS.Kunde__c));
                    }
                }
                try {
                    update lsgnList;
                }
                catch (System.Exception e) {
                    system.debug(logginglevel.error, '#########################alex2201 update lsgnList error=' + e);
                }               
            }   
        }
        
    }   
    
    if(!GenIdMap.isEmpty()) {
        system.debug('#########################alex105 GenIdMap=' + GenIdMap);
        GenIdSet = GenIdMap.keySet();
        List<Lieferschein__c> LSlist = [SELECT id, GenehmigungAttID__c, Genehmigung__c
                                    FROM Lieferschein__c
                                    WHERE Genehmigung__c IN :GenIdSet ];
        if((LSlist != null) && (LSlist.size() > 0)) {
            for (Lieferschein__c LS : LSlist) {
                if(trigger.isInsert) {
                    LS.GenehmigungAttID__c = GenIdMap.get(LS.Genehmigung__c);                    
                }
                if(trigger.isDelete) {
                    LS.GenehmigungAttID__c = '';    
                }
            }
            
            try
            {
                update LSList;
            } 
            catch (system.Dmlexception Liefexc)
            {
                system.debug('#########################update LS Liefexc=' + Liefexc);   
            }               
        }
    }
    
    if(!Kandidat54IDset.isEmpty()) {
             system.debug('#########################BT2016 Kandidat54IDset.size()=' + Kandidat54IDset.size());
            Statusverwaltung_Kunde_class.updateKS(Kandidat54IDset,'Kandidat','PG54');
            
            list<task> tsList = [SELECT id, Status 
                                    FROM task 
                                    WHERE Subject = 'Nachtelefonie von Interessenten'
                                    AND isClosed = false 
                                    AND WhatId IN :Kandidat54IDset];
            if((tsList != null) && (tsList.size() > 0)) {
                for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            }                         
    }
    
    if(!Kandidat51IDset.isEmpty()) {
             system.debug('#########################BT2016 Kandidat51IDset.size()=' + Kandidat51IDset.size());
            Statusverwaltung_Kunde_class.updateKS(Kandidat51IDset,'Kandidat','PG51');
            
            list<task> tsList = [SELECT id, Status 
                                    FROM task 
                                    // WHERE Subject = 'Nachtelefonie von Interessenten'
                                     WHERE Subject IN ('Nachtelefonie von Interessenten', 'Ist PG51 gewünscht ?')
                                    AND isClosed = false 
                                    AND WhatId IN :Kandidat51IDset];
            if((tsList != null) && (tsList.size() > 0)) {
                for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            }                         
    }    
   
    if(!Kandidat5XIDset.isEmpty()) {
             system.debug('#########################BT2016 Kandidat5XIDset.size()=' + Kandidat5XIDset.size());
            Statusverwaltung_Kunde_class.attachmentUpload(Kandidat5XIDset,'Kandidat');
            
            list<task> tsList = [SELECT id, Status 
                                    FROM task 
                                    WHERE Subject = 'Nachtelefonie von Interessenten'
                                    AND isClosed = false 
                                    AND WhatId IN :Kandidat5XIDset];
            if((tsList != null) && (tsList.size() > 0)) {
                for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            }                         
    }
       
    if(!InkoIDset.isEmpty()) {
          
            id rtid = null;                                
            list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'Inko'];
            if((rtList != null) && (rtList.size() > 0)) {
                rtId = rtList[0].id;
            } 

                       
            list<task> tsList = [SELECT id, Status 
                                    FROM task 
                                    WHERE RecordTypeId =: rtid
                                    AND isClosed = false 
                                    AND Subject != 'Nachtelefonie INKO-Formular'
                                    AND WhatId IN :InkoIDset];
            if((tsList != null) && (tsList.size() > 0)) {
                for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            }                      
    }  
    
    if(!InkoFormIDset.isEmpty()) {          
            id rtid = null;                                
            list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='task' AND Name = 'Inko'];
            if((rtList != null) && (rtList.size() > 0)) {
                rtId = rtList[0].id;
            } 

                       
            list<task> tsList = [SELECT id, Status 
                                    FROM task 
                                    WHERE RecordTypeId =: rtid
                                    AND isClosed = false 
                                    AND Subject = 'Nachtelefonie INKO-Formular'
                                    AND WhatId IN :InkoFormIDset];
            if((tsList != null) && (tsList.size() > 0)) {
                for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            }                      
    } 
    
    if(!Kunde51IDset.isEmpty()) {
        Statusverwaltung_Kunde_class.attachmentUpload(Kunde51IDset, 'PG51', 'Kunde');
        list<task> tsList = [SELECT id, Status 
                                    FROM task 
                                    WHERE Subject = 'Nachfassen bei PK wg. offener KÜ'
                                    AND isClosed = false 
                                    AND WhatId IN :Kunde51IDset];
        if((tsList != null) && (tsList.size() > 0)) {
              for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            }           
    }
    
    if(!Kunde54IDset.isEmpty()) {
      Statusverwaltung_Kunde_class.attachmentUpload(Kunde54IDset,'PG54', 'Kunde');
        
        list<task> tsList = [SELECT id, Status 
                                    FROM task 
                                    WHERE Subject = 'Nachfassen bei PK wg. offener KÜ'
                                    AND isClosed = false 
                                    AND WhatId IN :Kunde54IDset];
        if((tsList != null) && (tsList.size() > 0)) {
              for(task ts : tsList) {
                    ts.Status = 'Geschlossen';
                }
                try {
                    update tsList;
                }
                catch(system.exception e) {
                    system.debug('######################### error update tsList ' + e);
                }               
            }           
              
    }
    
    if(!lsIDSet.isEmpty()) {
        list<Lieferschein__c> lsList = [SELECT Unterschrift__c FROM Lieferschein__c WHERE id IN :lsIDSet  ]; 
        if((lsList != null) && (lsList.size() > 0)) {
            for(Lieferschein__c ls : lsList) {
                ls.Unterschrift__c = true;
            }
            try {
                update lsList;
            }
            catch(system.exception e) {
                system.debug('######################### error update lsList ' + e);
            }
        }       
    }

    if(!lsIDxmlSet.isEmpty()) {
        list<Lieferschein__c> lsList = [SELECT Ausgeliefert_am__c FROM Lieferschein__c WHERE id IN :lsIDxmlSet  ]; 
        if((lsList != null) && (lsList.size() > 0)) {
            for(Lieferschein__c ls : lsList) {
                ls.Ausgeliefert_am__c = date.today();
            }
            try {
                update lsList;
            }
            catch(system.exception e) {
                system.debug('######################### error update lsList (Datum) e=' + e);
            }
        }       
    }
    
    if(!lsIDxmlSet2.isEmpty()) {
        list<Lieferschein__c> lsList = [SELECT Ausgeliefert_am__c FROM Lieferschein__c WHERE id IN :lsIDxmlSet2  ]; 
        if((lsList != null) && (lsList.size() > 0)) {
            for(Lieferschein__c ls : lsList) {
                ls.Ausgeliefert_am__c = date.today();
            }
            try {
                update lsList;
            }
            catch(system.exception e) {
                system.debug('######################### error update lsList2 (Datum) e=' + e);
            }
        }       
    }
    
    if(!abMap.isEmpty()) {
        list<Lieferbest_tigung__c> lbabList = [SELECT Lieferschein__c, ablieferbeleg_att_ID__c FROM Lieferbest_tigung__c WHERE Lieferschein__c IN : abMap.keySet()];
        if((lbabList != null) && (lbabList.size() > 0)) {
            for(Lieferbest_tigung__c LB : lbabList) LB.ablieferbeleg_att_ID__c = string.valueOf(abMap.get(LB.Lieferschein__c));
            try {
                update lbabList;
            }
            catch(system.exception e) {
                system.debug('######################### error update lbabList ' + e);
            }           
        }
    }

    if(!lsMap.isEmpty()) {
        list<Lieferbest_tigung__c> lblsList = [SELECT Lieferschein__c, lieferschein_att_id__c FROM Lieferbest_tigung__c WHERE Lieferschein__c IN : lsMap.keySet()];
        if((lblsList != null) && (lblsList.size() > 0)) {
            for(Lieferbest_tigung__c LB : lblsList) LB.lieferschein_att_id__c = string.valueOf(lsMap.get(LB.Lieferschein__c));
            try {
                update lblsList;
            }
            catch(system.exception e) {
                system.debug('######################### error update lblsList ' + e);
            }           
        }
    }

    // 04.01.2019
    if(!txtSet.isEmpty()) {
        ksgloader_joblog.sendCSV(txtSet);
    }
    
}