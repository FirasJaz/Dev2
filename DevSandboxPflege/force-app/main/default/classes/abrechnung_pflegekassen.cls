//****************************************************************************************************************************
// Erstellt 15.08.2019 von AM
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
// Aufruf Abrechnung 
//
//
//****************************************************************************************************************************
//Änderungen:
//
//****************************************************************************************************************************
public with sharing class abrechnung_pflegekassen {
    public Integer noOfRecords{get; set;}
    public string kkName = '';  
    public string kkstr = '';
    public boolean Aufruf = true;
    public string errorMsg = null; 
    public string mfKunden = '';
    public string mfKundenTitel {get; set;}

    public abrechnung_pflegekassen() {
        kkName = ApexPages.CurrentPage().getParameters().get('kk');
        String los = ApexPages.CurrentPage().getParameters().get('call');
        mfKunden = ApexPages.CurrentPage().getParameters().get('mf');
        if(mfKunden != null) {
            mfKundenTitel = ' - ' + mfKunden;
        }
        else {
            mfKundenTitel = '';
        }
        if (los == 'los') {
            Aufruf = false;
            kkstr = ApexPages.CurrentPage().getParameters().get('kk').trim();
        }
        else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Geben Sie einen Namen oder ein Teil des Namens ein.<br>So z.B. \"AOK\" werden alle AOKs abgerechnet.<br>Beim Eingabe \"AOK HESSEN\" wird nur eine bestimmte Kasse abgerechnet.  '));    
        } 
    }
    
    public boolean getAufruf() {
        return Aufruf;
    }

    public string getKkName () {         
        return kkName;
    }

    public void setKkName (string kkName) {          
        this.kkName = kkName;
    }

    public PageReference createAndSend(){  
        ID batchprocessid;
        system.debug('### alex5000 ' + kkName + ' ' + kkstr);
        if(mfKunden == 'Medifox') {
            batchprocessid = Database.executeBatch(new invoice(true, kkName), 90);
        }
        else {
            batchprocessid = Database.executeBatch(new invoice(false, kkName), 90);
        }

        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.INFO,'Abrechnung ' + mfKunden + ' gestartet. Sie erhalten in Kürze eine e-Mail'));   
        PageReference pr = new PageReference('/apex/abrechnung_pflegekassen');
        // pr.setRedirect(true);

        return pr;
    }

    public PageReference goBack(){
        Aufruf = true;
        kkstr = '';
        kkName = null;
        return null;  
    }

    public PageReference startBatch() {
        Aufruf = false;
        noOfRecords = 0;
        kkstr = '%' + kkName + '%';
        boolean Medifox = false;
        if(mfKunden == 'Medifox') {
            Medifox = true;
        }
        List<AggregateResult> dnList = [SELECT COUNT(id) cnt FROM Delivery_Note__c 
                                            WHERE Status__c IN ('nicht abgerechnet', 'teilweise abgerechnet') 
                                                AND pod_recieved__c = true 
                                                AND Contact__r.Medifox_Kunde__c = : Medifox 
                                                AND Contact__r.Kranken_Pflegekasse__r.name like : kkstr
                                                AND id in (SELECT delivery_note__c FROM delivery_line__c WHERE Abrechnungsstatus_Krankenkasse__c = 'abrechenbar')]; 
        if((dnList != null) && (dnList.size() >0)) {
            noOfRecords = (integer)dnList[0].get('cnt');
        }
        PageReference curPage = ApexPages.currentPage();
        curPage.getParameters().put('call','los');
        curPage.getParameters().put('kk', kkName);
        curPage.getParameters().put('mf', mfKunden);
        // curPage.setRedirect(true);
        return curPage;  
    }

    public list<SelectOption> mfKundenSelect {
        set;
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('Standard', 'Standard')); 
            options.add(new SelectOption('Medifox', 'Medifox'));        
            return options;
        }
    }

    public integer getnoOfRecords() {
        return noOfRecords;
    }

    public void setMfKunden(string mfKunden) {
        this.mfKunden = mfKunden;
    }
    public string getMfKunden() {
        return mfKunden;
    }       
}