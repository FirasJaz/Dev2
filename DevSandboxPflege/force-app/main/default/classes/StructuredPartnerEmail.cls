/********************************************************************************************************************************************
// Erstellt 29.09.2016 von MZ
//  Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//  Mindelweg 11
//  22393 Hamburg 
//  Tel.:  04064917161
//  Fax.: 04064917162
//  Email: kontakt@klosesrockepartner.de
//
//********************************************************************************************************************************************
//
// Parameter: Strukturierte_Partner_Emails__c
//
//********************************************************************************************************************************************
//
// Beschreibung:             
//
//********************************************************************************************************************************************
//Änderungen:
// 05.12.2016    Mz    partner_ticket added as field type
// 10.05.2017   AM  build wildcards für date / time (now)
// 09.06.2017    MZ    'PB = ASP' is added
// 14.06.2017    MZ    'Kunden Interesse' has been added to Field type
//********************************************************************************************************************************************
*/
global class StructuredPartnerEmail{

    public static string opp_key = 'opp';
    public static string acc_key = 'acc';
    public static string pb_key  = 'pb' ;
    public static string asp_key = 'asp';
    public static string tkt_key = 'tkt'; 
    public static string usr_key = 'usr';
    public static string ki_key = 'ki';
    public static string cmnt_key = 'cmnt';
    public static string pbasp_key = 'pbasp';
    
    public static string date_key = 'date';
    public static string time_key = 'time';
    
    private static String CommentLabel = 'Kommentar zum Partner';
    private static String PbAspLabel = 'PB = ASP';
    
    private static String DateLabel = 'Datum';
    private static String TimeLabel = 'Zeit';
    
    private ApexPages.StandardController controller;
    public Strukturierte_Partner_Emails__c formObj{set;get;}
    public Id StructuredEmailId;
    public String selectedObj{set;get;}
    public String selectedField{set;get;}
    
    public String mergeFieldValue{set;get;}
    
    public map<String, String> objMapLabel = new map<String, String>();
    public map<String, String> objMapApiName = new map<String, String>();
    
    public map<String, customField> fieldMap;
    
    global StructuredPartnerEmail(ApexPages.StandardController stdController){
        this.controller = stdController;
        this.formObj = (Strukturierte_Partner_Emails__c) stdController.getRecord();
        setObjMap();
        selectedObj = opp_key;
        StructuredEmailId = ApexPages.currentPage().getParameters().get('id');
        if(StructuredEmailId != null){
            Strukturierte_Partner_Emails__c[] sList = [ select Id, Name, Email_Subject__c, Inhalt_der_Email__c from Strukturierte_Partner_Emails__c where Id = :StructuredEmailId limit 1];       
            if(sList!= null && sList .size()>0){
                formObj= sList[0];           
            }else{
                System.debug('error in StructuredPartnerEmail!!! ::: no StructuredPartnerEmailfound with Id: ' + this.StructuredEmailId );
            }
        }
    }
    
    private void setObjMap(){
        objMapLabel.put(opp_key, 'Opportunity');
        objMapLabel.put(acc_key, 'Account');
        objMapLabel.put(pb_key, 'Pflegebedürftigen');
        objMapLabel.put(asp_key, 'Ansprechpartner');
        objMapLabel.put(tkt_key, 'Partner-Ticket');
        objMapLabel.put(usr_key, 'User');
        objMapLabel.put(ki_key, 'Kunden Interesse');
        objMapLabel.put(cmnt_key, CommentLabel );
        objMapLabel.put(pbasp_key, PbAspLabel );
        objMapLabel.put(date_key, DateLabel );
        objMapLabel.put(time_key, TimeLabel );
        
        objMapApiName.put(opp_key, 'Opportunity');
        objMapApiName.put(acc_key, 'Account');
        objMapApiName.put(pb_key, 'Contact');
        objMapApiName.put(asp_key, 'Contact');
        objMapApiName.put(tkt_key, 'Partner_Ticket__c');
        objMapApiName.put(usr_key, 'User');
        objMapApiName.put(ki_key, 'Kunden_Interesse__c');
        
        // virtual Objects
        objMapApiName.put(cmnt_key, cmnt_key);
        objMapApiName.put(pbasp_key, pbasp_key);
        
        objMapApiName.put(date_key, date_key);
        objMapApiName.put(time_key, time_key);
    }

    public PageReference Speichern(){

        try{
            if(formObj.id != null){
                update formObj;
            }else{
                insert formObj;
            }
        
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm , 'The new changes applied successfully' ));
        }catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage() ));      
        }
        return controller.save();
    }    
   
    public List<SelectOption> getObjList() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(opp_key, objMapLabel.get(opp_key)));
        options.add(new SelectOption(acc_key, objMapLabel.get(acc_key)));
        options.add(new SelectOption(pb_key, objMapLabel.get(pb_key)));
        options.add(new SelectOption(asp_key, objMapLabel.get(asp_key)));
        options.add(new SelectOption(tkt_key, objMapLabel.get(tkt_key)));
        options.add(new SelectOption(usr_key, objMapLabel.get(usr_key)));
        options.add(new SelectOption(ki_key, objMapLabel.get(ki_key)));
        options.add(new SelectOption(cmnt_key, objMapLabel.get(cmnt_key)));
        options.add(new SelectOption(pbasp_key, objMapLabel.get(pbasp_key)));
        options.add(new SelectOption(date_key, objMapLabel.get(date_key)));
        options.add(new SelectOption(time_key, objMapLabel.get(time_key)));
        return options;
    }

    public List<SelectOption> getFieldList() {
        refreshFieldMap();
        List<SelectOption> options = new List<SelectOption>();
        for(String key: fieldMap.keyset()){
            options.add(new SelectOption(key, fieldMap.get(key).label));
        }
        return options;
    }
        
    public void refreshFieldMap (){
        fieldMap = new map<String, customField>();
        Boolean setSelectedField = True;
        String[] types = new String[]{ objMapApiName.get(selectedObj) };
        if(objMapApiName.get(selectedObj) == cmnt_key){
            customField newField = new customField(selectedObj, cmnt_key, cmnt_key, CommentLabel, null);
            fieldMap.put(cmnt_key, newField);
            if(setSelectedField){
                selectedField = cmnt_key;
                refreshMergeFieldValue();
                setSelectedField = False;
            }
        }
        else if(objMapApiName.get(selectedObj) == pbasp_key){
            customField newField = new customField(selectedObj, pbasp_key, pbasp_key, pbaspLabel, null);
            fieldMap.put(pbasp_key, newField);
            if(setSelectedField){
                selectedField = pbasp_key;
                refreshMergeFieldValue();
                setSelectedField = False;
            }
        }
        else if(objMapApiName.get(selectedObj) == date_key){
            customField newField = new customField(selectedObj, date_key, 'now', DateLabel, null);
            fieldMap.put(date_key, newField);
            if(setSelectedField){
                selectedField = date_key;
                refreshMergeFieldValue();
                setSelectedField = False;
            }
        }
        else if(objMapApiName.get(selectedObj) == time_key){
            customField newField = new customField(selectedObj, time_key, 'now', TimeLabel, null);
            fieldMap.put(time_key, newField);
            if(setSelectedField){
                selectedField = time_key;
                refreshMergeFieldValue();
                setSelectedField = False;
            }
        }       
        else{
            Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
            for(Schema.DescribeSobjectResult res : results) {
                         
                String controller = res.getName();
                map<String, Schema.SObjectField> lFieldMap = res.fields.getMap();
                for (String fieldName : lFieldMap .keySet()) {
                    SObjectField sfield = lFieldMap.get(fieldName);
                    schema.describefieldresult dfield = sfield.getDescribe();
                    //if(dfield.isAccessible() && dfield.isUpdateable() && dfield.getSoapType()!= Schema.SoapType.ID ){             
                    customField newField = new customField(selectedObj, controller, fieldName , dfield .getLabel(), dfield.getReferenceTo());
                    fieldMap.put(fieldName, newField);
                    //}
                    if(setSelectedField){
                        selectedField = fieldName;
                        refreshMergeFieldValue();
                        setSelectedField = False;
                    }
                }
            }
        }
    }
    
    public void refreshMergeFieldValue(){
        System.debug('mansi miad inja');
        mergeFieldValue = fieldMap.get(selectedField).mergeFieldValue;
        System.debug('mansi mergeFieldValue :::'+ mergeFieldValue );
    }

    private class customField{
        String selectedObj;
        String controller;
        String apiName;
        String label;
        String mergeFieldValue;
    
        public customField(String selectedObj, String controller, String apiName, String label, List<Schema.SObjectType> lookupObject){
            this.controller = controller;
            this.selectedObj = selectedObj;
            mergeFieldValue = '{{' + selectedObj;
            //mergeFieldValue += '.' + controller;
            
            if( lookupObject != null && lookupObject .size()> 0 ){
                mergeFieldValue += '.' + lookupObject[0].getDescribe().getName();
            }
        
            this.apiName = apiName;
            mergeFieldValue += '.' + apiName + '}}';
        
            this.label = label;
        }
    }
    
}