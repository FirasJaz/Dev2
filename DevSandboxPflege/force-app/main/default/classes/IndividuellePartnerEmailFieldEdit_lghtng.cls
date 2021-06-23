public class IndividuellePartnerEmailFieldEdit_lghtng{

private Id partnerEmailId;
private String referenceObjectContact = 'Contact';
private String referenceObjectOpportunity = 'Opportunity';
private String[] defaultContactFields = new String[]{'Name', 'mailingStreet', 'MailingPostalCode', 'MailingCity', 'Phone'};

public map<String, customField> opportunityFields;
public map<String, customField> contactFields;

public map<Id, String> recordTypesMap = new map<Id, String>();
public Id selectedRecordtype{set;get;}

public map<String, customField> getContactFields (){
    return contactFields;
} 
public map<String, customField> getOpportunityFields(){
    return opportunityFields;
} 

public IndividuellePartnerEmailFieldEdit_lghtng(){
    getItems();
    partnerEmailId = ApexPages.currentPage().getParameters().get('id');
   /* List<Individuelle_Partner_Email__c> individualEmailList = [select id, opportunity_record_type_id__c from Individuelle_Partner_Email__c where Id = :partnerEmailId limit 1];
    if(individualEmailList != null && individualEmailList .size()>0){
        selectedRecordtype = individualEmailList[0]. opportunity_record_type_id__c;
    }   
*/
    fetchOpportunityFields();
    fetchContactFields();
    markAlreadySelectedFields();
}

public void onRecordTypeChange(){
    fetchOpportunityFields();
}

public List<SelectOption> getItems() {
    List<SelectOption> options = new List<SelectOption>();
    List<RecordType> oppRecordTypes = [ SELECT Id,Name FROM RecordType WHERE SobjectType=:referenceObjectOpportunity and name != 'Standard'];
    if(oppRecordTypes != null && oppRecordTypes .size()>0){
        for(RecordType rt: oppRecordTypes ){
            options.add(new SelectOption(rt.Id, rt.name));
            recordTypesMap.put(rt.Id, rt.name);
            selectedRecordtype = rt.Id;
        } 
    }else{
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select one of the options'));
        return null;
    }
    return options;
}
/*
private void fetchOpportunityFieldsFromLayout(){
    Schema.DescribeLayoutResult[] results = Schema.describeLayout(referenceObjectOpportunity , null, new Id[]{selectedRecordtype }) ;
    System.debug('Mansi::: describeLayout :: ' );
}
*/
private void fetchOpportunityFields(){
    opportunityFields = new map<String, customField>();
    String[] types = new String[]{ referenceObjectOpportunity };
    Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
    for(Schema.DescribeSobjectResult res : results) {
                     
        String controller = res.getName();
        Map<Id, Schema.RecordTypeInfo> oppRecordTypes = res.getRecordTypeInfosById();
        Schema.RecordTypeInfo selectedRT = oppRecordTypes .get(selectedRecordtype );
        map<String, Schema.SObjectField> fieldMap = res.fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            SObjectField sfield = fieldMap.get(fieldName);
            schema.describefieldresult dfield = sfield.getDescribe();
            if(dfield.isAccessible() &&  dfield.isCustom() && dfield.isUpdateable() && dfield.getSoapType()!= Schema.SoapType.ID ){              
                customField newField = new customField(controller, fieldName , dfield .getLabel(), partnerEmailId, dfield.getReferenceTo());
                opportunityFields.put(fieldName, newField);
            }
        }
    }
}

private void fetchContactFields(){
    contactFields = new map<String, customField>();
    String[] types = new String[]{ referenceObjectContact };
    Schema.DescribeSobjectResult[] results = Schema.describeSObjects(types);
    for(Schema.DescribeSobjectResult res : results) {
        String controller = res.getName();
        map<String, Schema.SObjectField> fieldMap = res.fields.getMap();
        for (String fieldName : fieldMap.keySet()) {
            SObjectField sfield = fieldMap.get(fieldName);
            schema.describefieldresult dfield = sfield.getDescribe();
            if( dfield.isAccessible() && dfield.isUpdateable() &&   fieldName != 'firstname' && fieldName != 'lastname' ){           
                customField newField = new customField(controller, fieldName , dfield .getLabel(), partnerEmailId, dfield.getReferenceTo());
                contactFields.put(fieldName, newField);
            }
        }
    }
}

private void markAlreadySelectedFields(){
    //fetch IndividualEmailDaten Records
    List<Individuelle_Partner_Email_Daten__c> emailFileds = new List<Individuelle_Partner_Email_Daten__c>();
    emailFileds = [select Id, Name, Field_API_Name__c, Individuelle_Partner_Email__c, Reference_Object__c  from Individuelle_Partner_Email_Daten__c where Individuelle_Partner_Email__c = :partnerEmailId ];
    if (emailFileds != null && emailFileds.size()>0) {
        for(Individuelle_Partner_Email_Daten__c data : emailFileds ){    
            if(data.Reference_Object__c == referenceObjectOpportunity ){
                opportunityFields.remove(data.Field_API_Name__c);
                opportunityFields.put(data.Field_API_Name__c, new customField(data));
            }
            if(data.Reference_Object__c == referenceObjectContact){
                contactFields.remove(data.Field_API_Name__c);
                contactFields.put(data.Field_API_Name__c, new customField(data));
            }
            
        }       
    }
}

public PageReference Speichern(){
    try{
        List<Individuelle_Partner_Email_Daten__c> newFileds = new List<Individuelle_Partner_Email_Daten__c>();
        List<Individuelle_Partner_Email_Daten__c> deleteFileds = new List<Individuelle_Partner_Email_Daten__c>();
        List<customField> allFileds = opportunityFields.values();
        allFileds.addAll(contactFields.values());       
        
        for(customField item : allFileds){
            if(item.field.Id == null){
                if( item.selected ){
                    newFileds.add(item.field); 
                }
            }
            else{
                if( !item.selected ){
                    deleteFileds.add(item.field); 
                }
            }           
        }
        
        delete deleteFileds;
        insert newFileds;
        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm , 'The new changes applied successfully' ));
        return Abbruch();
    }catch(Exception e){
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage() ));      
    }
    return null;
}

private class customField{
    public Individuelle_Partner_Email_Daten__c field{set; get;}
    public Boolean selected{set; get;}
    public Boolean disabled{set; get;}  
    
    // shall be used as default constructor
    public customField(String refenceObject, String apiName, String label, Id parentId, List<Schema.SObjectType> lookupObject){
        field = new Individuelle_Partner_Email_Daten__c();
        field.Reference_Object__c = refenceObject;
        field.Field_API_Name__c = apiName;
        field.Name = label;
        field.Individuelle_Partner_Email__c = parentId;
        system.debug ( 'mansi:::: lookupObject ::::: ' +lookupObject);
        if( lookupObject != null && lookupObject .size()> 0 ){
            field.Lookup_Object__c = lookupObject[0].getDescribe().getName();
        }
        selected = false;
        disabled = false;
    }
    
    // shall be used onle when Individuelle_Partner_Email_Daten__c is already inserted (has Id)
    public customField(Individuelle_Partner_Email_Daten__c f){
        field = f;
        selected = true;
        disabled = false;
    }

}

public PageReference Abbruch(){
           PageReference PageRef = new PageReference('/' + partnerEmailId);
           PageRef.setRedirect(true);                     
           return PageRef;
    }

}