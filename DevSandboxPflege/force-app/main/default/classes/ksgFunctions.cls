/*/****************************************************************************************************************************
// Erstellt 06.05.2015 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04064917161
//                         Fax.:  04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: Diverse nützliche Funktionen
//
//****************************************************************************************************************************
//Änderungen:
// 10.02.2016 von AM einbau kdnachname und kdvorname weg. CC     
// 21.05.2019 AM  setScale(2, RoundingMode.HALF_UP)    
// 09.08.2019 AM  fill From Address with orgWideAddresses                      
//****************************************************************************************************************************
*/

public class ksgFunctions { 

    public static string formatCurrency(decimal d){
        string s = null;
        try {
            s = d.setScale(2, RoundingMode.HALF_UP).format();
            integer i =  s.lastIndexOf(',');
            if (i < 0) {
                s = s + ',00';
            }
            else if (i == s.length() - 2) {
                s = s + '0';
            } 
        }
        catch(System.Exception e) {

        }
        return s;
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }
    
    public static string getMonat() {
        string mon = null;
        integer m = date.today().month();
        if(m != null) {
            if((m > 0) && (m <= 12)) {
                if(m == 1) mon = 'Januar';
                if(m == 2) mon = 'Februar';
                if(m == 3) mon = 'März';
                if(m == 4) mon = 'April';
                if(m == 5) mon = 'Mai';
                if(m == 6) mon = 'Juni';
                if(m == 7) mon = 'Juli';
                if(m == 8) mon = 'August';
                if(m == 9) mon = 'September';
                if(m == 10) mon = 'Oktober';
                if(m == 11) mon = 'November';
                if(m == 12) mon = 'Dezember';
            }
        }
        return mon;     
    }
    
    public static string getMonat(integer m) {
        string mon = null;
        if(m != null) {
            if((m > 0) && (m <= 12)) {
                if(m == 1) mon = 'Januar';
                if(m == 2) mon = 'Februar';
                if(m == 3) mon = 'März';
                if(m == 4) mon = 'April';
                if(m == 5) mon = 'Mai';
                if(m == 6) mon = 'Juni';
                if(m == 7) mon = 'Juli';
                if(m == 8) mon = 'August';
                if(m == 9) mon = 'September';
                if(m == 10) mon = 'Oktober';
                if(m == 11) mon = 'November';
                if(m == 12) mon = 'Dezember';
            }
        }
        return mon;     
    }
    
    public static List<SelectOption> selectMonate() {
         List<SelectOption> options = new List<SelectOption>();
         options.add(new SelectOption('1', 'Januar'));
         options.add(new SelectOption('2', 'Februar'));
         options.add(new SelectOption('3', 'März'));
         options.add(new SelectOption('4', 'April'));
         options.add(new SelectOption('5', 'Mai'));
         options.add(new SelectOption('6', 'Juni'));
         options.add(new SelectOption('7', 'Juli'));
         options.add(new SelectOption('8', 'August'));
         options.add(new SelectOption('9', 'September'));
         options.add(new SelectOption('10', 'Oktober'));
         options.add(new SelectOption('11', 'November'));
         options.add(new SelectOption('12', 'Dezember'));
         return options;
    }
    
    public static string formatPLZ(decimal plz) {
        string fplz = '00000';
        integer iplz = null;
        try { 
            if((plz != null) && (plz > 0)) {
                iplz = integer.valueOf(plz);
                fplz = string.valueOf(iplz);
                while (fplz.length() < 5) fplz = '0' + fplz;
            }
            if(fplz.length() > 5) fplz = fplz.substring(0, 5);
        }
        catch(System.exception e){}
        return fplz;
    }

    public class addr {
        public string anrede {get; set;}
        public string vorname_name {get; set;}
        public string strasse {get; set;}
        public string plz_ort {get; set;}
        public string nachname {get; set;}
        public string kdnachname {get; set;}
        public string kdvorname {get; set;}

        // Beschreibung:
        // Setzt aus Name, Vorname und Anrede die korrekte Anredeformel zusammen für Briefe und emails     
        public string Anredeformelsetzen () {       
            string Anredeformel = 'Sehr geehrte Damen und Herren,';
            // EInfügung wegen Test upload wds
        
            if (anrede != null) {
                If (anrede.contains('Herr') ) {                 
                        Anredeformel = 'Sehr geehrter ' +(anrede + ' ' + nachname).trim() +',';                                                 
                }
                If (anrede.contains('Frau') ) { 
                        Anredeformel = 'Sehr geehrte ' +(anrede + ' ' + nachname).trim() +',';                                                   
                }         
            }        
            return anredeformel;
        }         
    }  

    public static List<SelectOption> getFromOptions() {
        List<SelectOption> options = new List<SelectOption>();
        // options.add(new SelectOption(userInfo.getUserId(), '"'+ userInfo.getName() + '" <'+ userInfo.getUserEmail() +'>' ));
        List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress];
        for(OrgWideEmailAddress owe: orgWideAddresses){
            options.add(new SelectOption(owe.Id, '"'+ owe.DisplayName + '" <'+ owe.Address +'>'));
        }
        return options;          
    }  

    public static id getEmailFromId(String recordTypeName) {
        id fromId = null;
        string orgWideAddressDisplayName = null;
        try {
            emailFromHandling__c efh = emailFromHandling__c.getValues(recordTypeName);
            orgWideAddressDisplayName = efh.orgWideAddressesDisplayName__c;
        }
        catch(System.Exception e) {
            system.debug('#### orgWideAddress für ' + recordTypeName + ' nicht gefunden. Setze Standard');
            try {
                emailFromHandling__c efh = emailFromHandling__c.getValues('Standard');
                orgWideAddressDisplayName = efh.orgWideAddressesDisplayName__c;
            }
            catch(System.Exception e2) {
                system.debug('#### orgWideAddress für Standard nicht gefunden. Setze UserID');  
                return userInfo.getUserId();              
            }   
        }
        if(orgWideAddressDisplayName != null) {
            List<OrgWideEmailAddress> orgWideAddresses = [select id from OrgWideEmailAddress WHERE DisplayName = : orgWideAddressDisplayName];
            if((orgWideAddresses != null) && (orgWideAddresses.size() > 0)) {
                fromId = orgWideAddresses[0].id;
            }
        }
        return fromId;
    }
    
}