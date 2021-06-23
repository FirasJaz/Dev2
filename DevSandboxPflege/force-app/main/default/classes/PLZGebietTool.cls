// Erstellt 22.07.2016 von BT
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen GmbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Beschreibung:
// PLZ Gebiet Tool            
//
//****************************************************************************************************************************
// Änderungen:
//
// 08.09.2016     wds    Gültig_bis eingefügt, als option
// 31.03.2017   AM  Der Fall neuVon < von und newBis > bis beim ausschiessen war nicht abgedeckt
//****************************************************************************************************************************
public class PLZGebietTool {
    public String paId;
    public string nameFile;
    public date validfrom {get; set;}
    public date validto {get; set;}
    public Blob contentFile;
    public String[] filelines = new String[]{};
    public String naechsterSchritt {get; set;}
    public String plzStatus {get; set;}
    public String ppIdsStr {get; set;}
    public List<Ausloeser> AusloeserListe = new List<Ausloeser>();
    public List<Ausloeser> ausgwListe = new List<Ausloeser>();
   
    private Partner_PLZ_Gebiet__c tmpPPG = new Partner_PLZ_Gebiet__c();
    private map<integer, Partner_PLZ_Gebiet__c> tmpMap = new map<integer, Partner_PLZ_Gebiet__c>();
    
    private string Ursprung {get; set;}
    
    private static String noProductError = 'Bitte wählen Sie einen Produkt aus';
    private static String plzError = 'PLZ von muss kleiner oder gleich PLZ bis sein';
    private static String dateError = 'Das Datum Gültig von muss kleiner oder gleich das Datum Gültig bis sein';
    private static String date2Error = 'Das Datum Gültig von darf nicht kleiner als Heute sein';
    
    // AM 20.01.2017 
    public boolean franchise {get; set;}
    private map<string, account> facMap = new map<string, account>(); 
    private map<string, set<id>> pppMap = new map<string, set<id>>(); 
    private set<id> fpaSet = new set<id>(); 
    
    public PLZGebietTool(ApexPages.StandardController controller) {
        franchise = false;
        paId = System.currentPagereference().getParameters().get('ID'); 
        
        plzStatus = 'Inbegriffen';   
        
        // AM 20.01.2017 
        franchise = checkFranchise();   
        system.debug('############alex700 franchise=' + franchise);
        if(franchise) {
            leseProdukteFranchise();            
            naechsterSchritt = 'Bestehende Daten ersetzen';           
        }
        else {
            leseProdukte();
            naechsterSchritt = 'Neue PLZ hinzufügen';  
        }           
        
    }
    
    private boolean checkFranchise() {
        list<account> facList = [SELECT id, name, Franchise_Nummer__c
                                    FROM account
                                    WHERE ParentId = :paId];
                                    
        if( (facList != null) && (facList.size() > 0 ) ) {
            for(account AC : facList ) {
                facMap.put(AC.Franchise_Nummer__c, AC);
                fpaSet.add(AC.id);
            }
            return true;
        }
        else return false;
    }

    public void leseProdukteFranchise(){       
        List<Partner_Produkte__c> PPListe = [SELECT id, Name, Partner__c, Partner__r.Franchise_Nummer__c, Produktgruppe__c 
                                                FROM Partner_Produkte__c
                                                 WHERE Partner__c IN: fpaSet
                                                 AND Produktgruppe__c != null
                                                 ORDER BY Partner__c];
        system.debug('############alex701 ');
        if(PPListe != null && PPListe.size() != 0) {
            set<id> pppSet;
            set<id> allePP = new set<id>();
             for(Partner_Produkte__c PP: PPListe) {
                if(pppMap.containsKey(PP.Partner__r.Franchise_Nummer__c)) {
                    pppSet = pppMap.get(PP.Partner__r.Franchise_Nummer__c);
                }
                else {
                    pppSet = new set<id>();
                }
                pppSet.add(PP.id);
                pppMap.put(PP.Partner__r.Franchise_Nummer__c, pppSet);               
                 
                 if(!allePP.contains(PP.id)) {
                    allePP.add(PP.id);
                    Ausloeser aus = new Ausloeser(PP);
                    AusloeserListe.add(aus);                   
                    ausgwListe.add(aus);
                 }
             }
        }       
    } 
    
    public void leseProdukte(){       
        List<Partner_Produkte__c> PPListe = [select id, Name, Partner__c, Produktgruppe__c from Partner_Produkte__c
                                                 where Partner__c =: paId
                                                 and Produktgruppe__c != null];
        
        if(PPListe != null && PPListe.size() != 0){
             for(Partner_Produkte__c PP: PPListe){
                    Ausloeser aus = new Ausloeser(PP);
                    AusloeserListe.add(aus);                   
                    ausgwListe.add(aus);
             }
        }       
    }    
    
    private void computResultExclud(integer[] result, decimal NV, decimal NB, id ppId) {
        Partner_PLZ_Gebiet__c pplz0;
        Partner_PLZ_Gebiet__c pplz1;
        if ((result[0] >= 0) && (result[1] >= 0)) {
            if(result[0] == result[1]) {
                // Hier können 2 Fälle sein :  komplett löschen (NV = von und NB = bis) oder Teil ausschneiden 
                pplz0 = tmpMap.get(result[0]);
                system.debug('############alex599  pplz0=' + pplz0);
                
                if ((pplz0.von__c == NV) && (pplz0.bis__c == NB)) {
                    tmpMap.remove(result[0]); 
                }
                else {
                                
                    // V0=V0 B0=NV-1 upd0
                    // Vx=NB+1 Bx=B1 insert             
                    pplz1 = new Partner_PLZ_Gebiet__c(Partner_Produkte__c = ppId, von__c=NB+1, bis__c=pplz0.bis__c);
                    
                    pplz0.bis__c = NV - 1;
                    system.debug('############alex600  pplz0.von__c=' + pplz0.von__c + ' pplz0.bis__c=' + pplz0.bis__c);
                    system.debug('############alex600  pplz1.von__c=' + pplz1.von__c + ' pplz1.bis__c=' + pplz1.bis__c);                
                    tmpMap.put(result[0], pplz0);
                    tmpMap.put(tmpMap.size(), pplz1);
                }
                
                // neu anordnen
                listeBereinigen();
            }
            else {
                // V0=V0 B0=NV-1 upd0
                // V1=NB+1 B1=B1 upd1 delete all between 0 and 1
                pplz0 = tmpMap.get(result[0]);
                system.debug('############alex598  pplz0=' + pplz0);
                pplz1 = tmpMap.get(result[1]);
                system.debug('############alex597  pplz1=' + pplz1);
                pplz0.bis__c = NV - 1;
                pplz1.von__c = NB + 1;
                system.debug('############alex601  pplz0.von__c=' + pplz0.von__c + ' pplz0.bis__c=' + pplz0.bis__c);
                system.debug('############alex601  pplz1.von__c=' + pplz1.von__c + ' pplz1.bis__c=' + pplz1.bis__c);    
                tmpMap.put(result[0], pplz0);
                tmpMap.put(result[1], pplz1);
                for(integer i = result[0] + 1; i < result[1];i++) {
                    if(tmpMap.containsKey(i)) tmpMap.remove(i); 
                }                               
            }
            
        }
        else if ((result[0] < 0) && (result[1] >= 0)) {
            // V1=NV-1 B1=B1 upd1
            pplz0 = tmpMap.get(result[1]);
            pplz0.von__c = NB + 1;
            system.debug('############alex602  pplz0.von__c=' + pplz0.von__c + ' pplz0.bis__c=' + pplz0.bis__c);    
            tmpMap.put(result[1], pplz0);               
        }
        else if ((result[0] >=0) && (result[1] < 0)) {
            // V0=Nv-1 B0=B0 upd0
            pplz0 = tmpMap.get(result[0]);
            pplz0.bis__c = NV - 1;
            system.debug('############alex603  pplz0.von__c=' + pplz0.von__c + ' pplz0.bis__c=' + pplz0.bis__c);    
            tmpMap.put(result[0], pplz0);               
        }
        // AM 2017.03.31
        else {
            system.debug('############alex1101  tmpMap=' + tmpMap);    
            // eingekesselte entfernen
            for(integer i = 0; i < tmpMap.size();i++) {
                    Partner_PLZ_Gebiet__c pplztt = tmpMap.get(i);
                    
                    if((pplztt.von__c >= NV) && (pplztt.bis__c <= NB)) tmpMap.remove(i); 
                } 
             
            
             
             
            system.debug('############alex1102  tmpMap=' + tmpMap); 
        }
    }
    
    private void listeBereinigen() {
        map<decimal, Partner_PLZ_Gebiet__c> pgbMap = new Map<decimal, Partner_PLZ_Gebiet__c>();
        list<Partner_PLZ_Gebiet__c> pgbList = new list<Partner_PLZ_Gebiet__c>();
        for(Partner_PLZ_Gebiet__c pplz : tmpMap.values()) pgbMap.put(pplz.von__c, pplz);
        list<decimal> keys = new list<decimal>(pgbMap.keySet());
        if(!keys.isEmpty()) {
            keys.sort();
            decimal minKey = keys[0];
            Partner_PLZ_Gebiet__c ppMin = pgbMap.get(minKey);
            
            for(decimal key : keys) { 
                Partner_PLZ_Gebiet__c ppNew = pgbMap.get(key);
                if((ppNew.von__c > ppMin.von__c) && ((ppNew.bis__c < ppMin.bis__c)) ) {
                    
                }
                else pgbList.add(ppNew);                
            }
            tmpMap.clear();
            for(Partner_PLZ_Gebiet__c pplz : pgbList) tmpMap.put(tmpMap.size(), pplz);      
        }
    }
    
    private void computResultInclud(integer[] result, decimal NV, decimal NB, id ppId) {
        Partner_PLZ_Gebiet__c pplz0;
        Partner_PLZ_Gebiet__c pplz1;
        if ((result[0] < 0) && (result[1] < 0)) {
            if ((result[2] >= 0) && (result[3] >= 0)) {
                // V0=V0 B0=B1 update satz0 delete satz 1
                pplz0 = tmpMap.get(result[2]);
                pplz1 = tmpMap.get(result[3]);
                pplz0.bis__c = pplz1.bis__c;
                tmpMap.put(result[2], pplz0);
                for(integer i = result[2] + 1; i <= result[3];i++) {
                    if(tmpMap.containsKey(i)) tmpMap.remove(i); 
                }
            }
            if ((result[2] >= 0) && (result[3] < 0)) {
                // V0=V0 B0=NB update satz0
                pplz0 = tmpMap.get(result[2]);
                pplz0.bis__c = NB;
                tmpMap.put(result[2], pplz0);               
            }
            if ((result[2] < 0) && (result[3] >= 0)) {
                //  V0=NV B0=B0 update satz0
                pplz0 = tmpMap.get(result[3]);
                pplz0.von__c = NV;
                tmpMap.put(result[3], pplz0);           
            }
            if ((result[2] < 0) && (result[3] < 0)) {
                pplz0 = new Partner_PLZ_Gebiet__c(Partner_Produkte__c = ppId, von__c=NV, bis__c=NB);
                tmpMap.put(tmpMap.size(), pplz0);
                // neu anordnen
                listeBereinigen();
            }
            
        }
        else {

             if ((result[0] >= 0) && (result[1] >= 0)) {
                if(result[0] != result[1]) {
                    // V0=V0 B0=B1 upd0 del1
                    pplz0 = tmpMap.get(result[0]);
                    pplz1 = tmpMap.get(result[1]);
                    pplz0.bis__c = pplz1.bis__c;
                    tmpMap.put(result[0], pplz0);
                    for(integer i = result[0] + 1; i <= result[1];i++) {
                        if(tmpMap.containsKey(i)) tmpMap.remove(i); 
                    }                                       
                }   
                else {
                    if ((result[2] < 0) && (result[3] >= 0)) {
                        system.debug('############alex402  tmpMap.size()=' + tmpMap.size());    
                        // V0=V0 B0=B1 upd0 del1
                        pplz0 = tmpMap.get(result[0]);
                        pplz1 = tmpMap.get(result[3]);
                        pplz0.bis__c = pplz1.bis__c;
                        system.debug('############alex421  pplz0.von__c=' + pplz0.von__c + ' pplz0.bis__c=' + pplz0.bis__c);    
                        tmpMap.put(result[0], pplz0);
                        for(integer i = result[0] + 1; i <= result[3];i++) {
                            if(tmpMap.containsKey(i)) tmpMap.remove(i); 
                        }   
                        system.debug('############alex403  tmpMap.size()=' + tmpMap.size());    
                    }
                }
             }
             else if ((result[0] >= 0) && (result[1] < 0)) {
                 // V0=V0 B0=NB upd0
                pplz0 = tmpMap.get(result[0]);
                pplz0.bis__c = NB;
                tmpMap.put(result[0], pplz0);                    
             }
             else if ((result[0] < 0) && (result[1] >= 0)) {
                 //V0=NV B0=B0 upd0
                pplz0 = tmpMap.get(result[1]);
                pplz0.von__c = NV;
                tmpMap.put(result[1], pplz0);                    
             }
            
        }
        
        
        
        
    }
    
    private integer[] checkPlzPaar(decimal NV, decimal NB) {
        integer[] ret = new integer[4];
        ret[0] = isIncl(NV);
        ret[1] = isIncl(NB);
        ret[2] = isPrevG(NV);
        ret[3] = isNextG(NB);       
        return ret;
    }
        
    private integer isIncl(decimal plz) {       
        if(!tmpMap.isEmpty()) {
            set<integer> keys = tmpMap.keySet();
            for(integer key : keys) {
                Partner_PLZ_Gebiet__c geb = tmpMap.get(key);
                if((plz >= geb.von__c) && (plz <= geb.bis__c)) {
                    return key;
                }               
            }
        }
        return -1;
    }
    
    private integer isPrevG(decimal plz) {      
        if(!tmpMap.isEmpty()) {
            plz = plz - 1;
            set<integer> keys = tmpMap.keySet();
            
            for(integer k : keys) {
                Partner_PLZ_Gebiet__c geb = tmpMap.get(k);
                if(plz == geb.bis__c) {
                    return k;
                }               
            }
        }
        return -1;
    }
    
    private integer isNextG(decimal plz) {      
        if(!tmpMap.isEmpty()) {
            plz = plz + 1;
            set<integer> keys = tmpMap.keySet();
            for(integer key : keys) {
                Partner_PLZ_Gebiet__c geb = tmpMap.get(key);
                if(plz == geb.von__c) {
                    return key;
                }               
            }
        }
        return -1;
    }
    
    public PageReference speichern() {
        Savepoint sp = Database.setSavepoint();         
        boolean ok = false;
        List<Id> pIdListe = new List<Id>();
        List<Partner_PLZ_Gebiet__c> b_plzGebietListe = new List<Partner_PLZ_Gebiet__c>();
        validto = null;    

        List<Partner_PLZ_Gebiet__c> rawList = new List<Partner_PLZ_Gebiet__c>();
        List<Partner_PLZ_Gebiet__c> newList = new List<Partner_PLZ_Gebiet__c>();
        List<Partner_PLZ_Gebiet__c> pgToInsList = new List<Partner_PLZ_Gebiet__c>();        
        // AM 20.01.2017
        map<string, List<Partner_PLZ_Gebiet__c>> rawMap = new map<string, List<Partner_PLZ_Gebiet__c>>();
        
        system.debug('############alex569  tmpPPG.G_ltig_von__c=' + tmpPPG.G_ltig_von__c + ' tmpPPG.G_ltig_bis__c=' + tmpPPG.G_ltig_bis__c);
        // input date from/to
        if(tmpPPG.G_ltig_von__c == null) tmpPPG.G_ltig_von__c = date.today();
        if(tmpPPG.G_ltig_von__c < date.today()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, date2Error ));
            return null;            
        }
        if((tmpPPG.G_ltig_bis__c != null) && (tmpPPG.G_ltig_bis__c < tmpPPG.G_ltig_von__c)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, dateError ));
            return null;            
        }
        
        
        
        if(ausgwListe != null && ausgwListe.size() != 0){
            for(Ausloeser aw: ausgwListe){
                if(ppIdsStr.contains(aw.pp.Id)) pIdListe.add(aw.pp.Id);
            }
        }
        
        if(pIdListe.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, noProductError ));
            return null;
        }
        
        // fill rawList - input data
        if((tmpPPG.von__c != null) && (tmpPPG.bis__c != null)) {
            Ursprung = 'manuell';
            if(tmpPPG.bis__c < tmpPPG.von__c) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, plzError ));
                return null;            
            }   
            Partner_PLZ_Gebiet__c mppg = new Partner_PLZ_Gebiet__c(von__c=tmpPPG.von__c, bis__c=tmpPPG.bis__c, G_ltig_von__c=tmpPPG.G_ltig_von__c, G_ltig_bis__c=tmpPPG.G_ltig_bis__c, Include_exclude__c=plzStatus);
            rawList.add(mppg);          
        }
        else {
            // validate input file  
            Ursprung = 'csv';   
            
            // AM 20.01.2017
            if(franchise) {
                plzStatus = 'Inbegriffen';   
                string debugstr = ''; 
                try {
                    nameFile = contentFile.toString();              
                    nameFile = nameFile.replace(';', ',');                                                                      
                    
                    //Now sepatate every row of the excel file
                    if(nameFile.contains('\r\n')){
                        filelines = nameFile.split('\r\n');               
                    }
                    else if(nameFile.contains('\r') && !nameFile.contains('\n')){
                        filelines = nameFile.split('\r');
                    }
                    else if(nameFile.contains('\n') && !nameFile.contains('\r')){
                        filelines = nameFile.split('\n');
                    }               
                    //Iterate through every line
                    // we need a map with key=Partner.Franchise_Nummer__c and value=rawList
                    // but this csv has 5 columns => inputvalues[2] contains Franchise_Nummer
                    
                    for (Integer i=1;i<filelines.size(); i++)
                    {
                        String[] inputvalues = new String[]{};
                        string line = filelines[i].replace('\r\n', '');
                        line = line.replace('\n', '');
                        line = line.replace('\r', '');
                        
                        inputvalues = line.split(',');  
                        
                        if((inputvalues[0] != null) && (!inputvalues[0].contains('von'))) {
                            
                            debugstr = string.valueOf(i) + ' ' +  line;
                            if(rawMap.containsKey(inputvalues[2])) {
                                rawList = rawMap.get(inputvalues[2]);
                            }
                            else {
                                rawList = new List<Partner_PLZ_Gebiet__c>();
                            }
                            decimal von = decimal.valueOf(inputvalues[0]);
                            decimal bis;
                            try {
                                
                                if ((inputvalues[1] != null) && (inputvalues[1].trim() != ''))  {                           
                                    bis = decimal.valueOf(inputvalues[1].trim());
                                }
                                else {
                                    bis = von;
                                }
                            }
                            catch(Exception e) {
                                 ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Fehler0. line: ' + debugstr + ' Error: '+e.getMessage());
                                 ApexPages.addMessage(errormsg);
                                 return null;   
                            }
                            // Datum
                            date gVon = tmpPPG.G_ltig_von__c;
                            date gBis = tmpPPG.G_ltig_bis__c;

                            system.debug('#############alex440  line=' + debugstr + ' inputvalues.size='+inputvalues.size());
                            if(inputvalues.size() > 3) {
                                
                                try {                                
                                    if ((inputvalues[3] != null) && (inputvalues[3].trim() != ''))  {                           
                                        String[] arrayVon = inputvalues[3].split('\\.');        
                                        system.debug('#############alex410  inputvalues[3]=' + inputvalues[3] + ' arrayVon='+arrayVon);
                                        if(arrayVon.size() == 3) {
                                            gVon = date.newinstance(integer.valueOf(arrayVon[2]), integer.valueOf(arrayVon[1]), integer.valueOf(arrayVon[0]));
                                            system.debug('#############alex411  inputvalues[3]=' + inputvalues[3] + ' gVon='+gVon);
                                        }
                                        else {
                                            ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Fehler1. line: ' + debugstr + ' Fehler: ='+arrayVon.size() );
                                            ApexPages.addMessage(errormsg);
                                            return null;    
                                        }
                                    }
                                    if(inputvalues.size() > 4) {
                                        if ((inputvalues[4] != null) && (inputvalues[4].trim() != ''))  {                           
                                            String[] arrayBis = inputvalues[4].split('\\.');
                                            system.debug('#############alex412  inputvalues[4]=' + inputvalues[4] + ' arrayBis='+arrayBis);
                                            if(arrayBis.size() == 3) {
                                                gBis = date.newinstance(integer.valueOf(arrayBis[2]), integer.valueOf(arrayBis[1]), integer.valueOf(arrayBis[0]));
                                                system.debug('#############alex413  inputvalues[4]=' + inputvalues[4] + ' gBis='+gBis);
                                            }
                                        }
                                    }
                                }
                                catch(Exception e) {
                                     ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'Fehler2. line: ' + debugstr + ' Fehler: '+e.getMessage() );
                                     ApexPages.addMessage(errormsg);
                                     return null;   
                                }                           
                            
                            }
                            
                            
                            Partner_PLZ_Gebiet__c nppg = new Partner_PLZ_Gebiet__c(von__c=von, bis__c=bis, G_ltig_von__c=gVon, G_ltig_bis__c=gBis, Include_exclude__c=plzStatus);
                            rawList.add(nppg);
                            system.debug('#############alex330  inputvalues[2]=' + inputvalues[2] + ' nppg='+nppg);
                            rawMap.put(inputvalues[2], rawList);
                            system.debug('#############alex300  inputvalues[2]=' + inputvalues[2] + ' rawList.size()='+rawList.size());
                            debugstr = '';
                        }               
                    }
                }
                catch(Exception e) {
                         ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured reading the CSV file. line: ' + debugstr + ' Error0: '+e.getMessage());
                         ApexPages.addMessage(errormsg);
                         return null;   
                }               
            }
            else {
                try {
                    nameFile = contentFile.toString();              
                    nameFile = nameFile.replace(';', ',');                                                                      
                    
                    //Now sepatate every row of the excel file
                    if(nameFile.contains('\r\n')){
                        filelines = nameFile.split('\r\n');               
                    }
                    else if(nameFile.contains('\r') && !nameFile.contains('\n')){
                        filelines = nameFile.split('\r');
                    }
                    else if(nameFile.contains('\n') && !nameFile.contains('\r')){
                        filelines = nameFile.split('\n');
                    }               
                    //Iterate through every line
                    for (Integer i=1;i<filelines.size(); i++)
                    {
                        String[] inputvalues = new String[]{};
                        string line = filelines[i].replace('\r\n', '');
                        line = line.replace('\n', '');
                        line = line.replace('\r', '');
                        
                        inputvalues = line.split(',');  
                        if((inputvalues[0] != null) && (!inputvalues[0].contains('von'))) {
                            decimal von = decimal.valueOf(inputvalues[0]);
                            decimal bis;
                            if (inputvalues[1] != null) {                           
                                bis = decimal.valueOf(inputvalues[1].trim());
                            }
                            else {
                                bis = von;
                            }

                            Partner_PLZ_Gebiet__c nppg = new Partner_PLZ_Gebiet__c(von__c=von, bis__c=bis, G_ltig_von__c=tmpPPG.G_ltig_von__c, G_ltig_bis__c=tmpPPG.G_ltig_bis__c, Include_exclude__c=plzStatus);
                            rawList.add(nppg);                  
                        }               
                    }
                }
                catch(Exception e) {
                         ApexPages.Message errormsg = new ApexPages.Message(ApexPages.severity.ERROR,'An error has occured reading the CSV file'+e.getMessage());
                         ApexPages.addMessage(errormsg);
                         return null;   
                } 
            }
        }
        
        // AM 20.01.2017
        if(franchise) {
            Ursprung = 'csv';
            // for all Partner          
            for(string FN : rawMap.keySet()) {
                system.debug('#############alex4501 FN=' +FN);
                if((pppMap.containsKey(FN)) && (rawMap.containsKey(FN))) {
                    
                    set<id> expppSet = pppMap.get(FN);
                    
                    rawList = rawMap.get(FN);
                    
                    // for all selected Partner_Produkte__c
                    system.debug('#############alex450 pIdListe.size()=' + pIdListe.size() + ' expppSet.size()=' + expppSet.size());
                    for(id pprId : pIdListe) {
                        if(expppSet.contains(pprId)) {
                            tmpMap.clear(); 
                            pgToInsList.clear();    
                            newList.clear();                        
                            b_plzGebietListe = [SELECT id, von__c, bis__c, Include_exclude__c, Partner_Produkte__c, G_ltig_bis__c, G_ltig_von__c 
                                                    FROM Partner_PLZ_Gebiet__c 
                                                    WHERE Partner_Produkte__c =: pprId 
                                                    and ((G_ltig_von__c = null) OR (G_ltig_von__c <= :tmpPPG.G_ltig_von__c))
                                                    and ((G_ltig_bis__c = null) OR (G_ltig_bis__c >= :tmpPPG.G_ltig_von__c))
                                                    ORDER BY von__c ];                          
                            for(Partner_PLZ_Gebiet__c bppg : rawList) {
                                tmpMap.put(tmpMap.size(), bppg);  
                                system.debug('#############alex301  tmpMap.size()=' + tmpMap.size() + ' bppg='+bppg);
                            }
                            system.debug('#############alex302  tmpMap=' + tmpMap);
                            listeBereinigen();
                            system.debug('#############alex303  tmpMap=' + tmpMap); 
                            if(!tmpMap.isEmpty()) ok = true;

                            if(ok) {
                                ok = false;
                                
                                // save input table first
                                list<Partner_PLZ_Gebiet__c> inputList = new list<Partner_PLZ_Gebiet__c>();
                                // for(id pprId : pIdListe) {
                                    for( Partner_PLZ_Gebiet__c ipp: rawList) {
                                        ipp.G_ltig_bis__c = date.today().adddays(-1);
                                        ipp.G_ltig_von__c = date.today().adddays(-1);
                                        ipp.Partner_Produkte__c = pprId;
                                        ipp.Include_exclude__c = plzStatus;
                                        ipp.Ursprung__c = Ursprung;
                                        inputList.add(ipp);
                                    }
                                //}
                                system.debug('#############alex304  inputList=' + inputList);
                                try {insert inputList;} catch(System.Exception e) {}
                                                
                                // save existing plz subset 
                                if(b_plzGebietListe != null && b_plzGebietListe.size() != 0) {
                                    for (Partner_PLZ_Gebiet__c ppg : b_plzGebietListe) {
                                        ppg.G_ltig_bis__c = tmpPPG.G_ltig_von__c.adddays(-1);
                                        if(ppg.G_ltig_von__c > ppg.G_ltig_bis__c) ppg.G_ltig_von__c = ppg.G_ltig_bis__c; 
                                    }
                                    
                                    try {
                                         List<Database.SaveResult> sr = Database.update(b_plzGebietListe, false); 
                                    }
                                    catch(system.exception e){
                                        Database.rollback(sp); 
                                        system.debug('#############BT2016    Bestehende PLZ Gebiete konnten nicht archiviert werden');
                                        return null;   
                                    }
                                
                                
                                    // clone an existing subset if a new has to-date
                                    if(tmpPPG.G_ltig_bis__c != null) {
                                        list<Partner_PLZ_Gebiet__c> futureList = new list<Partner_PLZ_Gebiet__c>();
                                        for (Partner_PLZ_Gebiet__c ppg : b_plzGebietListe) {
                                            Partner_PLZ_Gebiet__c fppg = new Partner_PLZ_Gebiet__c();
                                            fppg.G_ltig_bis__c = null;
                                            fppg.G_ltig_von__c = tmpPPG.G_ltig_bis__c.adddays(1);
                                            fppg.Partner_Produkte__c = ppg.Partner_Produkte__c;
                                            fppg.Include_exclude__c = ppg.Include_exclude__c;   
                                            fppg.von__c = ppg.von__c;
                                            fppg.bis__c = ppg.bis__c;
                                            futureList.add(fppg);
                                        }
                                        try {
                                            insert futureList;
                                            system.debug('#############alex573');
                                        } 
                                        catch(system.exception e){
                                            Database.rollback(sp); 
                                            system.debug('############# Bestehende PLZ Gebiete konnten nicht archiviert werden');
                                            return null;   
                                        }                                       
                                    }                       
                                }
                                                        
                                if((rawList != null) && (rawList.size() > 0)) {
                                    id ppId = null;
                                    for(Partner_PLZ_Gebiet__c opg : rawList) {
                                        integer[] result = checkPlzPaar(opg.von__c, opg.bis__c);
                                        system.debug('############alex422  opg.von__c=' + opg.von__c + ' opg.bis__c' + opg.bis__c + ' result=' + result);   
                                        if(opg.Include_exclude__c == 'inbegriffen') {
                                            computResultInclud(result, opg.von__c, opg.bis__c, ppId);                       
                                        }
                                        else {
                                            computResultExclud(result, opg.von__c, opg.bis__c, ppId);
                                        }
                                    }
                                    system.debug('############alex401  tmpMap.size()=' + tmpMap.size());    
                                    newList = tmpMap.values();
                                    if((newList != null) && (newList.size() > 0)) {
                                        for(Partner_PLZ_Gebiet__c opg : newList) {
                                            Partner_PLZ_Gebiet__c npg = new Partner_PLZ_Gebiet__c(G_ltig_von__c = tmpPPG.G_ltig_von__c, G_ltig_bis__c = tmpPPG.G_ltig_bis__c, von__c=opg.von__c, bis__c=opg.bis__c, Include_exclude__c='inbegriffen', Partner_Produkte__c=opg.Partner_Produkte__c);
                                            system.debug('############alex422b  npg.von__c=' + npg.von__c + ' npg.bis__c' + npg.bis__c + ' npg.G_ltig_von__c' + npg.G_ltig_von__c + ' npg.G_ltig_bis__c='+npg.G_ltig_bis__c);    
                                            npg.Partner_Produkte__c = pprId;
                                            pgToInsList.add(npg);
                                        }
                                        try {
                                            // insert a new subset for each Partner_Produkte__c
                                            // for(id pprId : pIdListe) {
                                                //for(Partner_PLZ_Gebiet__c npg : pgToInsList) npg.Partner_Produkte__c = pprId;
                                                insert pgToInsList;
                                            //}                     
                                        }
                                        catch(System.Exception e) {
                                            Database.rollback(sp); 
                                            system.debug('############alex410  e=' + e);    
                                            return null;   
                                        }
                                    }               
                                } 

                                                 
                            }
                        }
                    }
                }
            }
        }
        else {
            // for all selected Partner_Produkte__c
            for(id pprId : pIdListe) {
            
                tmpMap.clear(); 
                pgToInsList.clear();    
                newList.clear();
                    
                 b_plzGebietListe = [SELECT id, von__c, bis__c, Include_exclude__c, Partner_Produkte__c, G_ltig_bis__c, G_ltig_von__c 
                                            FROM Partner_PLZ_Gebiet__c 
                                            WHERE Partner_Produkte__c =: pprId 
                                            and ((G_ltig_von__c = null) OR (G_ltig_von__c <= :tmpPPG.G_ltig_von__c))
                                            and ((G_ltig_bis__c = null) OR (G_ltig_bis__c >= :tmpPPG.G_ltig_von__c))
                                            ORDER BY von__c ];                        
            
                // Manuelle Eingabe
                if((tmpPPG.von__c != null) && (tmpPPG.bis__c != null)) {
            
                    Ursprung = 'manuell';
                    
                    // fill work map 
                    if(naechsterSchritt == 'Bestehende Daten ersetzen') {
                        tmpMap.put(0, rawList[0]);
                        system.debug('############alex570  tmpMap.size()=' + tmpMap.size());
                    }
                    else {
                        for(Partner_PLZ_Gebiet__c bppg : b_plzGebietListe) tmpMap.put(tmpMap.size(), bppg); 
                        listeBereinigen();
                        system.debug('############alex571  tmpMap.size()=' + tmpMap.size());
                        if(tmpMap.isEmpty()) {
                            // neuanlage
                            tmpMap.put(0, rawList[0]);
                            system.debug('############alex572  mppg=' + rawList[0]);
                        }
                    }
                    if(!tmpMap.isEmpty()) ok = true;            
                }
                else {
                    // validate input file  
                    Ursprung = 'csv';
                        
                        // fill work map 
                        if(naechsterSchritt == 'Bestehende Daten ersetzen') {
                            for(Partner_PLZ_Gebiet__c bppg : rawList) tmpMap.put(tmpMap.size(), bppg);  
                            listeBereinigen();
                            system.debug('############alex580  tmpMap.size()=' + tmpMap.size());
                        }
                        else {
                            for(Partner_PLZ_Gebiet__c bppg : b_plzGebietListe) tmpMap.put(tmpMap.size(), bppg); 
                            listeBereinigen();
                            system.debug('############alex581  tmpMap.size()=' + tmpMap.size());
                            // neuanlage
                            if(tmpMap.isEmpty()) {
                                for(Partner_PLZ_Gebiet__c bppg : rawList) tmpMap.put(tmpMap.size(), bppg);  
                                listeBereinigen();                      
                            }
                        }

                        if(!tmpMap.isEmpty()) ok = true;
                }
            

                // 1. verarbeiten
                if(ok) {
                    ok = false;
                    
                    // save input table first
                    list<Partner_PLZ_Gebiet__c> inputList = new list<Partner_PLZ_Gebiet__c>();
                    // for(id pprId : pIdListe) {
                        for( Partner_PLZ_Gebiet__c ipp: rawList) {
                            ipp.G_ltig_bis__c = date.today().adddays(-1);
                            ipp.G_ltig_von__c = date.today().adddays(-1);
                            ipp.Partner_Produkte__c = pprId;
                            ipp.Include_exclude__c = plzStatus;
                            ipp.Ursprung__c = Ursprung;
                            inputList.add(ipp);
                        }
                    //}
                    try {insert inputList;} catch(System.Exception e) {}
                                    
                    // save existing plz subset 
                    if(b_plzGebietListe != null && b_plzGebietListe.size() != 0) {
                        for (Partner_PLZ_Gebiet__c ppg : b_plzGebietListe) {
                            ppg.G_ltig_bis__c = tmpPPG.G_ltig_von__c.adddays(-1);
                            if(ppg.G_ltig_von__c > ppg.G_ltig_bis__c) ppg.G_ltig_von__c = ppg.G_ltig_bis__c; 
                        }
                        
                        try {
                             List<Database.SaveResult> sr = Database.update(b_plzGebietListe, false); 
                        }
                        catch(system.exception e){
                            Database.rollback(sp); 
                            system.debug('#############BT2016    Bestehende PLZ Gebiete konnten nicht archiviert werden');
                            return null;   
                        }
                    
                    
                        // clone an existing subset if a new has to-date
                        if(tmpPPG.G_ltig_bis__c != null) {
                            list<Partner_PLZ_Gebiet__c> futureList = new list<Partner_PLZ_Gebiet__c>();
                            for (Partner_PLZ_Gebiet__c ppg : b_plzGebietListe) {
                                Partner_PLZ_Gebiet__c fppg = new Partner_PLZ_Gebiet__c();
                                fppg.G_ltig_bis__c = null;
                                fppg.G_ltig_von__c = tmpPPG.G_ltig_bis__c.adddays(1);
                                fppg.Partner_Produkte__c = ppg.Partner_Produkte__c;
                                fppg.Include_exclude__c = ppg.Include_exclude__c;   
                                fppg.von__c = ppg.von__c;
                                fppg.bis__c = ppg.bis__c;
                                futureList.add(fppg);
                            }
                            try {
                                insert futureList;
                                system.debug('#############alex573');
                            } 
                            catch(system.exception e){
                                Database.rollback(sp); 
                                system.debug('############# Bestehende PLZ Gebiete konnten nicht archiviert werden');
                                return null;   
                            }                                       
                        }                       
                    }
                                            
                    if((rawList != null) && (rawList.size() > 0)) {
                        id ppId = null;
                        for(Partner_PLZ_Gebiet__c opg : rawList) {
                            integer[] result = checkPlzPaar(opg.von__c, opg.bis__c);
                            system.debug('############alex422c  opg.von__c=' + opg.von__c + ' opg.bis__c' + opg.bis__c + ' result=' + result);   
                            if(opg.Include_exclude__c == 'inbegriffen') {
                                computResultInclud(result, opg.von__c, opg.bis__c, ppId);                       
                            }
                            else {
                                computResultExclud(result, opg.von__c, opg.bis__c, ppId);
                            }
                        }
                        system.debug('############alex401  tmpMap.size()=' + tmpMap.size());    
                        newList = tmpMap.values();
                        if((newList != null) && (newList.size() > 0)) {
                            for(Partner_PLZ_Gebiet__c opg : newList) {
                                Partner_PLZ_Gebiet__c npg = new Partner_PLZ_Gebiet__c(G_ltig_von__c = tmpPPG.G_ltig_von__c, G_ltig_bis__c = tmpPPG.G_ltig_bis__c, von__c=opg.von__c, bis__c=opg.bis__c, Include_exclude__c='inbegriffen', Partner_Produkte__c=opg.Partner_Produkte__c);
                                system.debug('############alex422d  npg.von__c=' + npg.von__c + ' npg.bis__c' + npg.bis__c + ' npg.G_ltig_von__c' + npg.G_ltig_von__c + ' npg.G_ltig_bis__c='+npg.G_ltig_bis__c);    
                                npg.Partner_Produkte__c = pprId;
                                pgToInsList.add(npg);
                            }
                            try {
                                // insert a new subset for each Partner_Produkte__c
                                // for(id pprId : pIdListe) {
                                    //for(Partner_PLZ_Gebiet__c npg : pgToInsList) npg.Partner_Produkte__c = pprId;
                                    insert pgToInsList;
                                //}                     
                            }
                            catch(System.Exception e) {
                                Database.rollback(sp); 
                                system.debug('############alex410  e=' + e);    
                                return null;   
                            }
                        }               
                    } 
                }
            
            }
            // for all Partner_Produkte__c
        
        // franchise = false
        }
        
        PageReference pageRef = new PageReference('/' + paId);
        pageRef.setRedirect(true);
        return pageRef;        
    }
    
    public PageReference abbrechen(){
        PageReference pageRef = new PageReference('/' + paId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public List<Ausloeser> getAusloeserListe(){
        return AusloeserListe;
    }
    
    public void setAusloeserListe(List<Ausloeser> ausListe){
        AusloeserListe = ausListe;
    }
    
    public void setAusgwListe(List<Ausloeser> ausgListe){
        ausgwListe = ausgListe;
    }
    
    public List<Ausloeser> getAusgwListe(){
        return ausgwListe;
    }
    
    public date getvalidto(){
        return validto;
    }
    
    public date getvalidfrom(){
        return validfrom;
    }
    
    public Blob getContentFile(){
        return contentFile;
    }
    
    public void setContentFile(Blob cFile){
        contentFile = cFile;
    }
    
    public String getNameFile(){
        return nameFile;
    }   
    
    public void setNameFile(String nFile){
        nameFile = nFile;
    }   
    
    public Partner_PLZ_Gebiet__c gettmpPPG() {
        return tmpPPG;
    }
    
    public void settmpPPG(Partner_PLZ_Gebiet__c tmpPPG) {
        this.tmpPPG = tmpPPG;
    }
    
    public class Ausloeser{
        public String ppName {get; set;}
        public Partner_Produkte__c pp {get; set;}
        
        public Ausloeser(Partner_Produkte__c ppd){
            pp = ppd;
            ppName = pp.Name;       
        }
    }    

}