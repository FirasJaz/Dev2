/****************************************************************************************************************************
// Created 13.06.2018 von  MZ
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
//
//****************************************************************************************************************************
//
// Description:       
//  copy of plzEmailTagsGenerator. But with static methods to be able to call it from lightning components.   
//
//****************************************************************************************************************************
// Changes: 
// 09.08.2018   MZ  KVAErrors() changed
// 10.01.2019   MZ  #163087312 Subtract_key and setSubtractedAmount changed
// 21.03.2019   AD  #164728602 check if offer rabat exists before to subtract this from the Gross Amount.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
public class EmailMessageTagGenerator_Badumbau {
    
    private static string opp_key = 'Opportunity';
    private static string offer_key = 'offer__c';
    //private static string acc_key = 'Account';
    private static string pb_key  = 'PB' ;
    private static string asp_key = 'ASP';
    private static string usr_key = 'User';
    
    private static string DateValue_key = 'DateValue';
    private static string TimeValue_key = 'TimeValue';
    private static string TimeValuePlus_key = 'TimeValuePlus';
    private static string FormatCurrency_Key = 'FormatCurrency'; 
    
    private static string OpportunityFieldHistory_key = 'OpportunityFieldHistory';
    
    private static string Subtract_key = '{!Subtract(offer__c.Gross_offer_value__c,offer__c.rebate__c,Opportunity.amount_sponsorship__c)}';
    private static string KVAErrors = '{!KVAErrors()}';
       
    
    public static String resolveMergeFields(Id opportunityId, String inputText, Id userId){
        String htmlTag = '' ;
        List<Opportunity> oList = [select Id, AccountId from Opportunity where Id = :opportunityId limit 1];
        if(oList != null && oList.size()>0){
            htmlTag = setOpportunityFields(opportunityId, inputText);
            htmlTag = setOpportunityDateAndTimeValue(opportunityId, htmlTag, DateValue_key);
            htmlTag = setOpportunityDateAndTimeValue(opportunityId, htmlTag, TimeValue_key);
            htmlTag = setOpportunityDateAndTimeValue(opportunityId, htmlTag, TimeValuePlus_key);
            
            htmlTag = setOpportunityCurrencyValues(opportunityId, htmlTag);
            
            htmlTag = setSubtractedAmount(opportunityId, htmlTag);
            htmlTag = setKvaErrors(opportunityId, htmlTag);
            
            htmlTag = setOpportunityFieldHistory(opportunityId, htmlTag);
            
            htmlTag = setUserFields(userId, htmlTag);
            
            // set contact fields
            Map<String, Id> contactIds = new Map<String, Id>();    
            getOpportunityContacts(opportunityId, contactIds);
            Id insuredPerson = null;
            Id contactPerson = null;
            if(contactIds.containsKey(PLZTool_Basis.contactRoleInsured)){
                insuredPerson = contactIds.get(PLZTool_Basis.contactRoleInsured);
                htmlTag = setContactFields(contactIds.get(PLZTool_Basis.contactRoleInsured), pb_key, htmlTag);
            }else{
                htmlTag = setContactFields(null, pb_key, htmlTag);
            }
            if(contactIds.containsKey(PLZTool_Basis.contactRoleContact)){
                contactPerson = contactIds.get(PLZTool_Basis.contactRoleContact);
                htmlTag = setContactFields(contactIds.get(PLZTool_Basis.contactRoleContact), asp_key, htmlTag);
            }else{
                htmlTag = setContactFields(null, asp_key, htmlTag);
            }
            
            htmlTag = setOfferFields(opportunityId, htmlTag);
            htmlTag = setOfferDateAndTimeValue(opportunityId, htmlTag, DateValue_key);
            htmlTag = setOfferCurrencyValues(opportunityId, htmlTag);
        }
        return htmlTag;
    }
    
    private static String setOpportunityFields(Id opportunityId, String htmlTag){
        Pattern oppPatern = Pattern.compile('\\{\\!'+opp_key+'.[a-zA-Z0-9_]+\\}');
        Matcher matcher = oppPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(3+opp_key.length(), fieldRef.length()-1);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
    
        String queryString = 'select Id ';
        Integer i = 0;
        for(String f : fieldRefMap.keySet()){
            if( i == 0){
                queryString = 'select ' + f;
            }else{
                queryString += ', ' + f;
            }
            i += 1;
        }   
        queryString += ' from Opportunity where Id = \''+opportunityId+'\' limit 1';
        sObject opp = Database.query(queryString); 
        fieldValueMap = opp.getPopulatedFieldsAsMap();
        
        //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
        for(String fieldName : fieldValueMap.keySet()){
            if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                String fieldValue = String.valueOf(fieldValueMap.get(fieldName));
                if(fieldValue == 'false' || fieldValue == 'False'){
                    fieldValue = 'Nein';
                }
                if(fieldValue == 'true' || fieldValue == 'True'){
                    fieldValue = 'Ja';
                }
                
                htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), fieldValue);
            }
        }
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        return htmlTag;    
    }
    
    private static String setOpportunityDateAndTimeValue(Id opportunityId, String htmlTag, String operator_key){
        Pattern oppPatern = Pattern.compile('\\{\\!'+operator_key+'\\('+opp_key+'.[a-zA-Z0-9_]+\\)\\}');
        Matcher matcher = oppPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(4+operator_key.length()+opp_key.length(), fieldRef.length()-2);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
    
        String queryString = 'select Id ';
        Integer i = 0;
        for(String f : fieldRefMap.keySet()){
            if( i == 0){
                queryString = 'select ' + f;
            }else{
                queryString += ', ' + f;
            }
            i += 1;
        }   
        queryString += ' from Opportunity where Id = \''+opportunityId+'\' limit 1';
        sObject opp = Database.query(queryString); 
        fieldValueMap = opp.getPopulatedFieldsAsMap();
        
        //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
        for(String fieldName : fieldValueMap.keySet()){
            if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                String fieldValue = String.valueOf(fieldValueMap.get(fieldName));
                Datetime dt = DateTime.valueOfGMT(fieldValue);
                if(operator_key == DateValue_key){
                    fieldValue = dt.format('dd.MM.yyyy', UserInfo.getTimeZone().getID());
                }
                if(operator_key == TimeValue_key){
                    fieldValue = dt.format('HH:mm', UserInfo.getTimeZone().getID());
                }
                if(operator_key == TimeValuePlus_key){
                    dt = dt.addHours(2);
                    fieldValue = dt.format('HH:mm', UserInfo.getTimeZone().getID());
                }
                htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), fieldValue);
            }
        }
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        return htmlTag;    
    }
    
    private static String setOpportunityCurrencyValues(Id opportunityId, String htmlTag){
        Pattern oppPatern = Pattern.compile('\\{\\!'+FormatCurrency_Key+'\\('+opp_key+'.[a-zA-Z0-9_]+\\)\\}');
        Matcher matcher = oppPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(4+FormatCurrency_Key.length()+opp_key.length(), fieldRef.length()-2);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
        system.debug('###mansi:::' + fieldRefMap);
    
        String queryString = 'select Id ';
        Integer i = 0;
        for(String f : fieldRefMap.keySet()){
            if( i == 0){
                queryString = 'select ' + f;
            }else{
                queryString += ', ' + f;
            }
            i += 1;
        }   
        queryString += ' from Opportunity where Id = \''+opportunityId+'\' limit 1';
        sObject opp = Database.query(queryString); 
        fieldValueMap = opp.getPopulatedFieldsAsMap();
        
        //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
        for(String fieldName : fieldValueMap.keySet()){
            if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                String fieldValue = String.valueOf(fieldValueMap.get(fieldName));
                try{
                    Decimal d = Decimal.valueOf(fieldValue);
                    htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), formatCurrency(d));
                }catch(Exception e){
                    htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), fieldValue);
                }
            }
        }
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        return htmlTag;    
    }
    
    private static String setSubtractedAmount(Id opportunityId, String htmlTag){
        List<Offer__c> offerList = [select id, Net_value_offer__c,Gross_offer_value__c, rebate__c from Offer__c where opportunity__c = :opportunityId and offer_active__c = True order by createdDate desc limit 1];
        List<Opportunity> oppList = [select Id, amount_sponsorship__c from Opportunity where Id = :opportunityId limit 1];
        if(offerList != null && offerList.size()>0 && oppList != null && oppList.size()>0 && oppList[0].amount_sponsorship__c != null){
            // check if offer rabat is null before to subtract
            if (offerList[0].rebate__c == null){
                htmlTag = htmlTag.replace(Subtract_key, formatCurrency(offerList[0].Gross_offer_value__c - oppList[0].amount_sponsorship__c));
            }
            else{
                htmlTag = htmlTag.replace(Subtract_key, formatCurrency(offerList[0].Gross_offer_value__c - offerList[0].rebate__c - oppList[0].amount_sponsorship__c));
            }
            
        }else{
            htmlTag = htmlTag.replace(Subtract_key, ' ');
        }
        return htmlTag;    
    }
    
    private static String formatCurrency(Decimal x){
        if(x <= 0){
            return '0,00';
        }
        String r = String.valueOf(x.format());
        if(r.contains(',')){
            if(r.indexOf(',') == r.length()-2) return r + '0';
            return r;
        }else{
            return r + ',00';
        }
    }

    private static String setContactFields(Id contactId, String contact_key, String htmlTag){
        Pattern conPatern = Pattern.compile('\\{\\!'+contact_key+'\\.[a-zA-Z0-9_]+\\}');
        Matcher matcher = conPatern.matcher(htmlTag);
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(3+contact_key.length(), fieldRef.length()-1);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
    
        if(contactId != null){
            String queryString = 'select Id ';
            Integer i = 0;
            for(String f : fieldRefMap.keySet()){
                if( i == 0){
                    queryString = 'select ' + f;
                }else{
                    queryString += ', ' + f;
                }
                i += 1;
            }   
            queryString += ' from Contact where Id = \''+contactId+'\' limit 1 ';
            System.debug('#####mansi##### contact query ### '+ queryString);
            sObject con = Database.query(queryString); 
            fieldValueMap = con.getPopulatedFieldsAsMap();
            
            //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
            for(String fieldName : fieldValueMap.keySet()){
                if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                    htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), String.valueOf(fieldValueMap.get(fieldName)));
                }
            }
        }
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        return htmlTag;    
    }
    
    private static String setUserFields(Id userId, String htmlTag){
        Pattern accPatern = Pattern.compile('\\{\\!'+usr_key+'.[a-zA-Z0-9_]+\\}');
        Matcher matcher = accPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldRefMap = new map<String, String>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(3+usr_key.length(), fieldRef.length()-1);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
        
        String queryString = 'select Id ';
        Integer i = 0;
        for(String f : fieldRefMap.keySet()){
            if( i == 0){
                queryString = 'select ' + f;
            }else{
                queryString += ', ' + f;
            }
            i += 1;
        }   
        if(userId != null){
        queryString += ' from User where Id = \''+userId+'\' limit 1';
        system.debug('mansi::: queryString:::' + queryString);
        sObject usr = Database.query(queryString); 
        map<String, Object> usrfieldValueMap = usr.getPopulatedFieldsAsMap();
        
        //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
        for(String fieldName : usrfieldValueMap.keySet()){
            if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), String.valueOf(usrfieldValueMap.get(fieldName)));
            }
        }
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        }
            
        return htmlTag;    
    }   
    
    private static String setOfferFields(Id opportunityId, String htmlTag){
        Pattern oppPatern = Pattern.compile('\\{\\!'+offer_key+'.[a-zA-Z0-9_]+\\}');
        Matcher matcher = oppPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(3+offer_key.length(), fieldRef.length()-1);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
    
        String queryString = 'select Id ';
        Integer i = 0;
        for(String f : fieldRefMap.keySet()){
            if( i == 0){
                queryString = 'select ' + f;
            }else{
                queryString += ', ' + f;
            }
            i += 1;
        }   
        queryString += ' from Offer__c where opportunity__c  = \''+opportunityId+'\' And offer_active__c = True order by createdDate desc limit 1';
        List<Offer__c> offerList =  Database.query(queryString); 
        if(offerList != null && offerList.size()>0){
            sObject opp = offerList[0];
            
            fieldValueMap = opp.getPopulatedFieldsAsMap();
            
            //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
            for(String fieldName : fieldValueMap.keySet()){
                if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                    String fieldValue = String.valueOf(fieldValueMap.get(fieldName));
                    if(fieldValue == 'false' || fieldValue == 'False'){
                        fieldValue = 'Nein';
                    }
                    if(fieldValue == 'true' || fieldValue == 'True'){
                        fieldValue = 'Ja';
                    }
                    htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), fieldValue);
                }
            }
        }
        
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        return htmlTag;    
    }
    
    private static void getOpportunityContacts(Id opportunityId, Map<String, Id> contactIds){
        List<OpportunityContactRole> contactRoles = [select ContactId, Role, IsPrimary  from OpportunityContactRole where opportunityId = :opportunityId and IsDeleted = false];
        if(contactRoles != null && contactRoles.size()>0){
            for( OpportunityContactRole cr : contactRoles  ){
                if(cr.IsPrimary){
                    contactIds.put(PLZTool_Basis.contactRolePrimary, cr.ContactId);
                }
                if(cr.Role == PLZTool_Basis.contactRoleInsured){
                    contactIds.put(PLZTool_Basis.contactRoleInsured, cr.ContactId);                  
                }               
                if(cr.Role == PLZTool_Basis.contactRoleContact){
                    contactIds.put(PLZTool_Basis.contactRoleContact, cr.ContactId);
                } 
                if(cr.Role == PLZTool_Basis.contactRoleSame){
                    contactIds.put(PLZTool_Basis.contactRoleInsured, cr.ContactId);
                    contactIds.put(PLZTool_Basis.contactRoleContact, cr.ContactId);
                }
            }
        }else{
            System.debug('error in setIntendedContacts:::: Mansi::: no contact role found !!!');
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'No contact role is defined for the opportunity! '));
        }
    }
    
    // used for filling body of Badumabu email 14
    private static String setKvaErrors(Id opportunityId, String htmlTag){
        String notReceivedStatus = 'Nicht erhalten';
        String result = '';
        List<Offer__c> offerList = [select id, 
                                    estimate_status__c,
                                    estimate_description__c,
                                    technical_document_status__c,
                                    technical_document_description__c,
                                    measurement_protocol_status__c,
                                    measurement_protocol_description__c,
                                    measurement_drawing_status__c,
                                    measurement_drawing_description__c,
                                    pictures_before_status__c,
                                    pictures_before_description__c,
                                    product_attachment_status__c,
                                    product_attachment_description__c
                                    from Offer__c 
                                    where opportunity__c = :opportunityId 
                                    And offer_active__c = True
                                    order by createdDate desc limit 1];
        
        if(offerList != null && offerList.size()>0){
            Offer__c offer = offerList[0];
            
            // estimate_status__c
            if(offer.estimate_status__c == null || offer.estimate_status__c.containsIgnoreCase(notReceivedStatus) ){
                result += '<br/> - KVA: ' + notReceivedStatus;
            }else if(offer.estimate_status__c.containsIgnoreCase('fehlerhaft')){
                result += '<br/> - KVA: ' + offer.estimate_description__c;
            }
            
            // technical_document_status__c
            if(offer.technical_document_status__c == null || offer.technical_document_status__c.containsIgnoreCase(notReceivedStatus) ){
                result += '<br/> - Technisches Schreiben: ' + notReceivedStatus;
            }else if(offer.technical_document_status__c.containsIgnoreCase('fehlerhaft')){
                result += '<br/> - Technisches Schreiben: ' + offer.technical_document_description__c;
            }
            
            // measurement_protocol_status__c
            if(offer.measurement_protocol_status__c == null || offer.measurement_protocol_status__c.containsIgnoreCase(notReceivedStatus) ){
                result += '<br/> - Aufmaßprotokoll: ' + notReceivedStatus;
            }else if(offer.measurement_protocol_status__c.containsIgnoreCase('fehlerhaft')){
                result += '<br/> - Aufmaßprotokoll: ' + offer.measurement_protocol_description__c;
            }
            
            // measurement_drawing_status__c
            if(offer.measurement_drawing_status__c == null || offer.measurement_drawing_status__c.containsIgnoreCase(notReceivedStatus) ){
                result += '<br/> - Aufmaßskizze: ' + notReceivedStatus;
            }else if(offer.measurement_drawing_status__c.containsIgnoreCase('fehlerhaft')){
                result += '<br/> - Aufmaßskizze: ' + offer.measurement_drawing_description__c;
            }
            
            // pictures_before_status__c
            if(offer.pictures_before_status__c == null || offer.pictures_before_status__c.containsIgnoreCase(notReceivedStatus) ){
                result += '<br/> - Vorherbilder: ' + notReceivedStatus;
            }else if(offer.pictures_before_status__c.containsIgnoreCase('fehlerhaft')){
                result += '<br/> - Vorherbilder: ' + offer.pictures_before_description__c;
            }
            
            // product_attachment_status__c
            if(offer.product_attachment_status__c == null || offer.product_attachment_status__c.containsIgnoreCase(notReceivedStatus) ){
                result += '<br/> - Produktanhänge: ' + notReceivedStatus;
            }else if(offer.product_attachment_status__c.containsIgnoreCase('fehlerhaft')){
                result += '<br/> - Produktanhänge: ' + offer.product_attachment_description__c;
            }
            
        }
        htmlTag = htmlTag.replace(KVAErrors, result);
        return htmlTag;
    }
    
    private static String setOpportunityFieldHistory(Id opportunityId, String htmlTag){
        Pattern oppPatern = Pattern.compile('\\{\\!'+OpportunityFieldHistory_key+'\\([a-zA-Z0-9_]+,[a-zA-Z0-9_]+\\)\\}');
        Matcher matcher = oppPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldConditionMap = new map<String, String>();
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(3+OpportunityFieldHistory_key.length(), fieldRef.indexOf(','));
            String fieldValue = fieldRef.substring(1+fieldRef.indexOf(','), fieldRef.length()-2);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
            if( !fieldConditionMap.containsKey(fieldName.toLowerCase()) ){
                fieldConditionMap.put(fieldName.toLowerCase(), fieldValue);
            }
        }
        if(fieldRefMap == null || fieldRefMap.size()== 0){
            // nothing to replace
            return htmlTag; 
        }
        
        String queryString = 'Select Id, Field, OldValue, NewValue, createdDate, opportunityId From OpportunityFieldHistory where opportunityId  = \''+opportunityId + '\' '; 
        Integer j = 0;
        for(String f : fieldRefMap.keySet()){
            if(j == 0){
                queryString += ' AND ( ';
            }
            else{
                queryString += ' OR ';
            }
            queryString += ' Field =\'' + f + '\' ';
            queryString += ' ) ';
        }   
        
        queryString += ' order by createdDate desc limit 1000';
        System.debug('######mansi#########queryString:::.'+ queryString);
        List<sObject> oppList = Database.query(queryString); 
        for(String f : fieldRefMap.keyset()){
            Boolean valueFound = false;
            for(Integer i = 0; (i<oppList.size() && !valueFound); i+=1){
                if(((OpportunityFieldHistory)oppList[i]).Field == f &&  ((OpportunityFieldHistory)oppList[i]).NewValue == fieldConditionMap.get(f) ){
                    String fieldValue = String.valueOf(((OpportunityFieldHistory)oppList[i]).createdDate);
                    Datetime dt = DateTime.valueOfGMT(fieldValue);
                    fieldValue = dt.format('dd/MM/yyyy', UserInfo.getTimeZone().getID());
                    htmlTag = htmlTag.replace(fieldRefMap.get(f), fieldValue);
                    valueFound = true;
                }
            }
            if(!valueFound){
                htmlTag = htmlTag.replace(fieldRefMap.get(f), ' ');
            }
        }
        return htmlTag;    
    }

    private static String setOfferDateAndTimeValue(Id opportunityId, String htmlTag, String operator_key){
        Pattern offerPatern = Pattern.compile('\\{\\!'+operator_key+'\\('+offer_key+'.[a-zA-Z0-9_]+\\)\\}');
        Matcher matcher = offerPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(4+operator_key.length()+offer_key.length(), fieldRef.length()-2);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
    
        String queryString = 'select Id ';
        Integer i = 0;
        for(String f : fieldRefMap.keySet()){
            if( i == 0){
                queryString = 'select ' + f;
            }else{
                queryString += ', ' + f;
            }
            i += 1;
        }   
        queryString += ' from Offer__c where opportunity__c  = \''+opportunityId+'\' And offer_active__c = True order by createdDate desc limit 1';
        List<Offer__c> offerList =  Database.query(queryString); 
        if(offerList != null && offerList.size()>0){
            sObject offer = offerList[0];
            
            fieldValueMap = offer.getPopulatedFieldsAsMap();
            
            //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
            for(String fieldName : fieldValueMap.keySet()){
                if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                    String fieldValue = String.valueOf(fieldValueMap.get(fieldName));
                    Datetime dt = DateTime.valueOfGMT(fieldValue);
                    if(operator_key == DateValue_key){
                        fieldValue = dt.format('dd.MM.yyyy', UserInfo.getTimeZone().getID());
                    }
                    if(operator_key == TimeValue_key){
                        fieldValue = dt.format('HH:mm', UserInfo.getTimeZone().getID());
                    }
                    if(operator_key == TimeValuePlus_key){
                        dt = dt.addHours(2);
                        fieldValue = dt.format('HH:mm', UserInfo.getTimeZone().getID());
                    }
                    htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), fieldValue);
                }
            }
        }
        
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        return htmlTag;    
    }        
    
    private static String setOfferCurrencyValues(Id opportunityId, String htmlTag){
        Pattern offerPatern = Pattern.compile('\\{\\!'+FormatCurrency_Key+'\\('+offer_key+'.[a-zA-Z0-9_]+\\)\\}');
        Matcher matcher = offerPatern.matcher(htmlTag);
        String[] fields = new String[]{};
        map<String, String> fieldRefMap = new map<String, String>();
        map<String, Object> fieldValueMap = new map<String, Object>();
        while(matcher.find()){
            Integer matcherStart = matcher.start();
            Integer matcherEnd = matcher.end();
            String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
            String fieldName = fieldRef.substring(4+FormatCurrency_Key.length()+offer_key.length(), fieldRef.length()-2);
            if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
                fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
            }
        }
    
        String queryString = 'select Id ';
        Integer i = 0;
        for(String f : fieldRefMap.keySet()){
            if( i == 0){
                queryString = 'select ' + f;
            }else{
                queryString += ', ' + f;
            }
            i += 1;
        }   
        queryString += ' from Offer__c where opportunity__c  = \''+opportunityId+'\' And offer_active__c = True order by createdDate desc limit 1';
        List<Offer__c> offerList =  Database.query(queryString); 
        if(offerList != null && offerList.size()>0){
            sObject offer = offerList[0];
            
            fieldValueMap = offer.getPopulatedFieldsAsMap();
            
            //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
            for(String fieldName : fieldValueMap.keySet()){
                if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                    String fieldValue = String.valueOf(fieldValueMap.get(fieldName));
                    try{
                        Decimal d = Decimal.valueOf(fieldValue);
                        htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), formatCurrency(d));
                    }catch(Exception e){
                        htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), fieldValue);
                    }
                }
            }
        }
        
        //!!! we need to replace the field names with space when there is no value  !!!
        for(String fieldName : fieldRefMap.keySet()){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
        }
        return htmlTag;    
    }
    
}