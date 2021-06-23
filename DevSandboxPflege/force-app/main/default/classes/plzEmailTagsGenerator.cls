//****************************************************************************************************************************
// Created dd.mm.2016      by MZ
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Mindelweg 11
//                         22393 Hamburg 
//                         Tel.:  04023882986
//                         Fax.:  04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
// xxxx
//
//****************************************************************************************************************************
//
// Description:
//                      
// The programm generates the HTML-Tag for customer, and partner email for PLZ_tool
//
//
//****************************************************************************************************************************
//Changes:
//
//      23.08.2016     wds    Change the tag construktion for customer email
//      21.09.2016     TK     Change Wording "Plz Ort" to "PLZ Ort" 
//      13.10.2016     TK     "Suche im Umkreis von X Kilometern" ausgegrenzt
//      15.10.2016     TK     "Versorgungszeitraum" ausgegrenzt
//      24.01.2017     MZ     changes regarding BEL recordType applied. "generateOpportunity_BEL" and "addExtraField_BEL" methods added.
//      05.05.2017     AM     #144429537 build date.today() dd.mm.yyyy and date.now() HH:MM as wildcard {{date.now}} and {{time.now}}
//      08.05.2017     MZ     apply HNR email templates: generateOpportunity_HNR
//      09.06.2017     MZ     add PB = ASP to generateStructuredEmail
//      14.06.2017     MZ     add 'Kunden Interesse' to generateStructuredEmail
//      29.06.2017     MZ     remove the field "Zeitpunkt der Versorgung" from HNR
//      05.07.2017     MZ     the reference of two fields(partner darf telefonisch melden, Infomaterial senden) changed from KI to Opportunity  
//      25.10.2017     MZ     case 00001312 - method generatePartnerPlainText added
//      30.01.2018     MZ     #154758607 salutation added to generateCustomerTag 
//      27.02.2018     MZ     #155352779 website of the partner does not shpw up
//      07.06.2018     MZ     Badumbau email added
//      21.08.2018     MZ     Mobility field changed for Badumbau
//      25.08.2018     MZ     #160718862 Zusatzinformationen added
//      27.09.2018     MZ     #160167197 Badumbau - two other phone fields added
//      09.09.2020     DZ     Deleted "\" from website link
//      28.12.2020     DZ     Krankheiten entfernt
//****************************************************************************************************************************
public class plzEmailTagsGenerator{


public static String tblEnd = '</table>';
public static String tdEnd = '</td>';
public static String tr = '<tr align="left">';
public static String trEnd = '</tr>';

public static String tblPartner = '<table width="100%" cellpadding="2" cellspacing="2" id="tblPartners" >';
public static String tdImg = '<td width="200">';
public static String td = '<td>';
public static String tbl= '<table width="100%" cellpadding="0" cellspacing="0">';
public static String tdPartner = '<td valign="top" width="100">';
public static String tdPartnername = '<td valign="top" >';


public static String tblCustomer = '<table width="100%" cellspacing="0" cellpadding="2" style="font-family:lato,arial,verdana;border-spacing:0;border-color:#fff;" border="1"> ';
public static String tdCustomerTitle = '<td valign="top" width="200" style="-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;-webkit-font-smoothing:subpixel-antialiased;font-smooth:always"> ';
public static String tdCustomerValue = '<td valign="top" style="-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;-webkit-font-smoothing:subpixel-antialiased;font-smooth:always"> ';

public static String tblOpp = '<table width="100%" cellspacing="0" cellpadding="2" style="font-family:lato,arial,verdana;border-spacing:0;border-color:#fff;" border="1"> ';
public static String tdOppTitle = '<td valign="top" width="200" style="-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;-webkit-font-smoothing:subpixel-antialiased;font-smooth:always"> ';
public static String tdOppValue = '<td valign="top" style="-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;-webkit-font-smoothing:subpixel-antialiased;font-smooth:always"> ';

public plzEmailTagsGenerator(){
}

public String prepareHnrDVBody(String htmlValue, Partner_Produkte__c pp, ID opportunityId){
    List<Kunden_Interesse__c> ki_list = [select id, Kontoinhaber__c 
                                         from Kunden_Interesse__c
                                         where opportunity__r.Id = :opportunityId 
                                         order by CreatedDate desc
                                         limit 1];
    String kontoInhaberName = '';
    String bankName = '';
    String iban = '';
    String bic = '';
    if(ki_list != null && ki_list.size()>0){
        String role;
        if(ki_list[0].Kontoinhaber__c == AdditionalInfoController.Kontoinhaber_ASP){
            role = PLZTool_Basis.contactRoleContact;
        }
        if(ki_list[0].Kontoinhaber__c == AdditionalInfoController.Kontoinhaber_PB){
            role = PLZTool_Basis.contactRoleInsured;
        }
        List<OpportunityContactRole> contactRoleList = [select id,
                                                               ContactId, 
                                                               contact.Name, 
                                                               contact.iban__c, 
                                                               contact.bic__c, 
                                                               contact.kreditinstitut__c
                                                        from OpportunityContactRole 
                                                        where OpportunityId = :opportunityId
                                                        and IsDeleted = false
                                                        and (Role = :role
                                                        or Role = :PLZTool_Basis.contactRoleSame )
                                                        limit 1];
        if(contactRoleList!= null && contactRoleList.size()>0){
            kontoInhaberName = contactRoleList[0].contact.Name;
            bankName = contactRoleList[0].contact.kreditinstitut__c;
            iban = contactRoleList[0].contact.iban__c;
            bic = contactRoleList[0].contact.bic__c;
        }
    }
    
    if(bankName == null){
        bankName = '';
    }
    if(iban == null){
        iban = '';
    }
    if(bic == null){
        bic = '';
    }
     
    String kontoDaten = 'Kontoinhaber: ' + kontoInhaberName + '<br/>'+
        'Kreditinstitut: ' + bankName + '<br/>'+
        'IBAN: ' + iban + '<br/>'+
        'BIC: ' + bic + '<br/>';
    
    htmlValue = htmlValue.replace('{!Kontoadten}', KontoDaten);
    
    htmlValue = htmlValue.replace('{!PartnerProductName}' , pp.Name );
    
    htmlValue = htmlValue.replace('{!PartnerName}', pp.Partner__r.Name);
    
    String partnerDaten = pp.Partner__r.Name + '<br/>';
    if(!String.isEmpty(pp.Partner__r.BillingStreet)){
        partnerDaten = partnerDaten + pp.Partner__r.BillingStreet + '<br/>';
    }
    if(!String.isEmpty(pp.Partner__r.BillingPostalCode)){
        partnerDaten = partnerDaten + pp.Partner__r.BillingPostalCode + ' ';
    }
    if(!String.isEmpty(pp.Partner__r.BillingCity)){
        partnerDaten = partnerDaten + pp.Partner__r.BillingCity;
    }
    if(!String.isEmpty(pp.Partner__r.Phone)){
        partnerDaten = '<br/>' + partnerDaten + '<br/>' + pp.Partner__r.Phone + '<br/>';
    }
    
    htmlValue = htmlValue.replace('{!Partnerdaten}', partnerDaten);
    
    return htmlValue;
}
    
public String generatePartnerPlainText(List<Partner_Produkte__c> ppList){
    
    String newLine = '\n';
    String space = ': ';
    String htmlTag = '';
    
    
    for( Partner_Produkte__c item : ppList ){  
        htmlTag += newLine;
        htmlTag += 'Name' + space + item.Partner__r.Name ;
        htmlTag += newLine;
        
        htmlTag += newLine;
        if(item.Partner__r.BillingStreet != null)
            htmlTag += 'Strasse' + space + item.Partner__r.BillingStreet ;
        else
            htmlTag += 'Strasse' + space  + '-' ;
        htmlTag += newLine;        
        
        htmlTag += newLine;
        if(item.Partner__r.BillingPostalCode != null || item.Partner__r.BillingCity != null)
            htmlTag += 'PLZ Ort' + space + item.Partner__r.BillingPostalCode + ' ' + item.Partner__r.BillingCity;
        else
            htmlTag += 'PLZ Ort' + space + ' ';
        htmlTag += newLine;    

        htmlTag += newLine;
        if(item.Partner__r.Website != null)
            htmlTag += 'Website' + space + item.Partner__r.Website ;
        else
            htmlTag += 'Website' + space + '-';
        htmlTag += newLine;
          
    }
    
    return htmlTag;
}
    
public String generatePartnerListTag(List<Partner_Produkte__c> ppList){
    
    String htmlTag = tblPartner ;
    
    for( Partner_Produkte__c item : ppList ){  
        htmlTag += tr;
        htmlTag += tdImg + '<img src="'+ item.partner__r.Logo_Url__c +'" width="200" style="max-width:200;height: auto;" alt="Partnerlogo" >' + tdEnd ;
        
        htmlTag += td + tbl;
                
        htmlTag += tr;
        htmlTag += tdPartner + 'Name' + tdEnd + tdPartnername + item.Partner__r.Name + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(item.Partner__r.BillingStreet != null)
            htmlTag += tdPartner + 'Strasse' + tdEnd + tdPartnername + item.Partner__r.BillingStreet + tdEnd;
        else
            htmlTag += tdPartner + 'Strasse' + tdEnd + tdPartnername  + '-' + tdEnd;
        htmlTag += trEnd;        
        
        htmlTag += tr;
        if(item.Partner__r.BillingPostalCode != null || item.Partner__r.BillingCity != null)
            htmlTag += tdPartner + 'PLZ Ort' + tdEnd + tdPartnername + item.Partner__r.BillingPostalCode + ' ' + item.Partner__r.BillingCity + tdEnd;
        else
            htmlTag += tdPartner + 'PLZ Ort' + tdEnd + tdPartnername + ' ' + tdEnd;
        htmlTag += trEnd;    

//        htmlTag += tr;
//        if(item.Partner__r.Phone != null)
//            htmlTag += tdPartner + 'Telefon' + tdEnd + tdPartner + item.Partner__r.Phone + tdEnd;
//        else
//            htmlTag += tdPartner + 'Telefon' + tdEnd + tdPartner + '-' + tdEnd;
//        htmlTag += trEnd;

        htmlTag += tr;
        if(item.Partner__r.Website != null) //<apex:outputtext value="'+ item.Partner__r.Website +'" /> 
            htmlTag += tdPartner + 'Website' + tdEnd + tdPartnername + '<a href="'+item.Partner__r.Website +'"> &nbsp;'+ item.Partner__r.Website+ '</a>'+ tdEnd;
        else
            htmlTag += tdPartner + 'Website' + tdEnd + tdPartnername + '-'+ tdEnd;
        htmlTag += trEnd;
                            
        htmlTag += tblEnd + tdEnd + trEnd;
        htmlTag += tr + '<td colspan="2">&nbsp;<br/>' + tdEnd + trEnd ;
        
    }
    
    htmlTag += tblEnd;
    system.debug('######################### wds001 htmlTag= ' + htmlTag);
    return htmlTag;
}


public String generateOpportunityIndividualTag(Id opportunityId, Id individualEmailId){
    String htmlTag = tblOpp ;
    List<Individuelle_Partner_Email_Daten__c> fields = [select Id, Name, Field_API_Name__c, Individuelle_Partner_Email__c, Lookup_Object__c from Individuelle_Partner_Email_Daten__c where Individuelle_Partner_Email__c = :individualEmailId and  Reference_Object__c = 'Opportunity'];
    if(fields != null && fields.size()> 0){
        String queryString = 'select ';
        for(Individuelle_Partner_Email_Daten__c f : fields){
            queryString += f.Field_API_Name__c + ' , ';
        }
        queryString += ' Id from Opportunity where Id = \''+ opportunityId +'\' limit 1 ';
        List<SObject> oList =  Database.query(queryString);
        SObject op;
        if(oList != null && oList.size()>0){
            op = oList[0];
            for(Individuelle_Partner_Email_Daten__c f : fields){
                htmlTag += tr;
                if(op.get(f.Field_API_Name__c) != null)
                    if(f.Lookup_Object__c != null){
                        String lookupQueryString = 'select Id, name from ' + f.Lookup_Object__c + ' where Id = \''+ op.get(f.Field_API_Name__c) +'\' limit 1 ';
                        List<SObject> lookUpObjList =  Database.query(lookupQueryString);
                        if(lookUpObjList != null && lookUpObjList.size()>0){
                            htmlTag += tdOppTitle + f.Name + tdEnd + tdOppValue + lookUpObjList[0].get('name') + tdEnd;
                        }
                    }else{
                        htmlTag += tdOppTitle + f.Name + tdEnd + tdOppValue + op.get(f.Field_API_Name__c) + tdEnd;
                    }
                else
                    htmlTag += tdOppTitle + f.Name + tdEnd + tdOppValue + '-' + tdEnd;
                htmlTag += trEnd;
            }
        }
    }
    htmlTag += tblEnd;
    return htmlTag;
}

public String generateStructuredEmailText(Id ticketId, Id opportunityId, String inputText, Id userId, String comment){
    String htmlTag = '' ;
     
    List<Opportunity> oList = [select Id, AccountId from Opportunity where Id = :opportunityId limit 1];
    if(oList != null && oList.size()>0){
        htmlTag = setOpportunityFields(opportunityId, inputText);
        
        htmlTag = setAccountFields(oList[0].AccountId, htmlTag);
        
        htmlTag = setUserFields(userId, htmlTag);
        
        htmlTag = setPartnerTicketsFields(ticketId, htmlTag);
        
        htmlTag = setKundenInteresseFields(opportunityId, htmlTag);
        
        // set contact fields
        Map<String, Id> contactIds = new Map<String, Id>();    
        getOpportunityContacts(opportunityId, contactIds);
        Id insuredPerson = null;
        Id contactPerson = null;
        if(contactIds.containsKey(PLZTool_Basis.contactRoleInsured)){
            insuredPerson = contactIds.get(PLZTool_Basis.contactRoleInsured);
            htmlTag = setContactFields(contactIds.get(PLZTool_Basis.contactRoleInsured), StructuredPartnerEmail.pb_key, htmlTag);
        }else{
            htmlTag = setContactFields(null, StructuredPartnerEmail.pb_key, htmlTag);
        }
        if(contactIds.containsKey(PLZTool_Basis.contactRoleContact)){
            contactPerson = contactIds.get(PLZTool_Basis.contactRoleContact);
            htmlTag = setContactFields(contactIds.get(PLZTool_Basis.contactRoleContact), StructuredPartnerEmail.asp_key, htmlTag);
        }else{
            htmlTag = setContactFields(null, StructuredPartnerEmail.asp_key, htmlTag);
        }
        
        // set PB = ASP
        if(insuredPerson != null && contactPerson!= null && insuredPerson == contactPerson){
            htmlTag = htmlTag.replace('{{'+StructuredPartnerEmail.pbasp_key + '.' + StructuredPartnerEmail.pbasp_key +'}}', 'Ja');
        }else{
            htmlTag = htmlTag.replace('{{'+StructuredPartnerEmail.pbasp_key + '.' + StructuredPartnerEmail.pbasp_key +'}}', 'Nein');
        }
        
        // set date / time now
        htmlTag = htmlTag.replace('{{date.now}}', datetime.now().format('dd.MM.yyyy'));
        htmlTag = htmlTag.replace('{{time.now}}', datetime.now().format('HH:mm'));
        
        // set comment to partner
        htmlTag = htmlTag.replace('{{'+StructuredPartnerEmail.cmnt_key+ '.' + StructuredPartnerEmail.cmnt_key +'}}', comment);

        system.debug('mansi:::setContactFields::::'+ htmlTag);
    }
    
    return htmlTag;
}
    
private String setOpportunityFields(Id opportunityId, String htmlTag){
    Pattern oppPatern = Pattern.compile('\\{\\{'+StructuredPartnerEmail.opp_key+'.[a-zA-Z0-9_]+\\}\\}');
    Matcher matcher = oppPatern.matcher(htmlTag);
    String[] fields = new String[]{};
    map<String, String> fieldRefMap = new map<String, String>();
    map<String, Object> fieldValueMap = new map<String, Object>();
    while(matcher.find()){
        Integer matcherStart = matcher.start();
        Integer matcherEnd = matcher.end();
        String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
        String fieldName = fieldRef.substring(6, fieldRef.length()-2);
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
    
private String setAccountFields(Id accountId, String htmlTag){
    Pattern accPatern = Pattern.compile('\\{\\{'+StructuredPartnerEmail.acc_key+'.[a-zA-Z0-9_]+\\}\\}');
    Matcher matcher = accPatern.matcher(htmlTag);
    String[] fields = new String[]{};
    map<String, String> fieldRefMap = new map<String, String>();
    while(matcher.find()){
        Integer matcherStart = matcher.start();
        Integer matcherEnd = matcher.end();
        String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
        String fieldName = fieldRef.substring(6, fieldRef.length()-2);
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
    queryString += ' from Account where Id = \''+accountId+'\' limit 1';
    system.debug('mansi::: queryString:::' + queryString);
    sObject acc = Database.query(queryString); 
    map<String, Object> accfieldValueMap = acc.getPopulatedFieldsAsMap();
    
    //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
    for(String fieldName : accfieldValueMap.keySet()){
        if(fieldRefMap.containsKey(fieldName.toLowerCase())){
            htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), String.valueOf(accfieldValueMap.get(fieldName)));
        }
    }
    //!!! we need to replace the field names with space when there is no value  !!!
    for(String fieldName : fieldRefMap.keySet()){
        htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
    }
        
    return htmlTag;    
} 
    
private String setKundenInteresseFields(Id opportunityId, String htmlTag){
    Pattern kiPatern = Pattern.compile('\\{\\{'+StructuredPartnerEmail.ki_key+'.[a-zA-Z0-9_]+\\}\\}');
    Matcher matcher = kiPatern.matcher(htmlTag);
    String[] fields = new String[]{};
    map<String, String> fieldRefMap = new map<String, String>();
    map<String, Object> fieldValueMap = new map<String, Object>();
    while(matcher.find()){
        Integer matcherStart = matcher.start();
        Integer matcherEnd = matcher.end();
        String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
        String fieldName = fieldRef.substring(5, fieldRef.length()-2);
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
    queryString += ' from Kunden_Interesse__c where opportunity__r.Id = \''+opportunityId+'\' order by CreatedDate desc limit 1';
    system.debug('mansi:: before query');
    sObject ki;
    try{
        ki = Database.query(queryString);
    }
    catch(Exception e){
        system.debug('mansi:: no kunde interesse object found');
        return htmlTag;
    }
    
    fieldValueMap = ki.getPopulatedFieldsAsMap();
    
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
    
private String setUserFields(Id userId, String htmlTag){
    Pattern accPatern = Pattern.compile('\\{\\{'+StructuredPartnerEmail.usr_key+'.[a-zA-Z0-9_]+\\}\\}');
    Matcher matcher = accPatern.matcher(htmlTag);
    String[] fields = new String[]{};
    map<String, String> fieldRefMap = new map<String, String>();
    while(matcher.find()){
        Integer matcherStart = matcher.start();
        Integer matcherEnd = matcher.end();
        String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
        String fieldName = fieldRef.substring(6, fieldRef.length()-2);
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
  
private String setPartnerTicketsFields(Id ticketId, String htmlTag){
    Pattern tktPatern = Pattern.compile('\\{\\{'+StructuredPartnerEmail.tkt_key+'.[a-zA-Z0-9_]+\\}\\}');
    Matcher matcher = tktPatern.matcher(htmlTag);
    String[] fields = new String[]{};
    map<String, String> fieldRefMap = new map<String, String>();
    while(matcher.find()){
        Integer matcherStart = matcher.start();
        Integer matcherEnd = matcher.end();
        String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
        String fieldName = fieldRef.substring(6, fieldRef.length()-2);
        if( !fieldRefMap.containsKey(fieldName.toLowerCase()) ){
            fieldRefMap.put(fieldName.toLowerCase(), fieldRef);
        }
    }
    if(ticketId != null){
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
        queryString += ' from Partner_Ticket__c where Id = \''+ticketId+'\' limit 1';
        
        sObject tkt = Database.query(queryString); 
        map<String, Object> tktfieldValueMap = tkt.getPopulatedFieldsAsMap();
    
        //!!!! fieldValueMap :: the map contains the field only if the field has a value  !!!
        for(String fieldName : tktfieldValueMap.keySet()){
            if(fieldRefMap.containsKey(fieldName.toLowerCase())){
                htmlTag = htmlTag.replace(fieldRefMap.get(fieldName.toLowerCase()), String.valueOf(tktfieldValueMap.get(fieldName)));
            }
        }
    }
    //!!! we need to replace the field names with space when there is no value  !!!
    for(String fieldName : fieldRefMap.keySet()){
        htmlTag = htmlTag.replace(fieldRefMap.get(fieldName), ' ');
    }
        
    return htmlTag;    
}    

private String setContactFields(Id contactId, String contact_key, String htmlTag){
    Pattern conPatern = Pattern.compile('\\{\\{'+contact_key+'\\.[a-zA-Z0-9_]+\\}\\}');
    Matcher matcher = conPatern.matcher(htmlTag);
    map<String, String> fieldRefMap = new map<String, String>();
    map<String, Object> fieldValueMap = new map<String, Object>();
    while(matcher.find()){
        Integer matcherStart = matcher.start();
        Integer matcherEnd = matcher.end();
        String fieldRef = htmlTag.substring(matcherStart, matcherEnd);
        String fieldName = fieldRef.substring(3+contact_key.length(), fieldRef.length()-2);
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
    
private void getOpportunityContacts(Id opportunityId, Map<String, Id> contactIds){
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

public String generateOpportunity_TL(Id opportunityId ){
    String htmlTag = tblOpp ;
    Opportunity op;
    List<Opportunity> oList = [select Id, 
                                Produkt_Kategorie__c, 
                                Art_des_Geb_udes__c, 
                                Umgebung__c, 
                                Anzahl_der_Etagen__c, 
                                Treppenbauart__c , 
                                Belastbarkeit__c, 
                                Bezugspunkt_der_PLZ_Suche__c, 
                                Zeitpunkt_der_Versorgung__c, 
                                Alternative_Postleitzahl__c, 
                                Versorgungsdatum__c, 
                                Suche_im_Umkreis_von_X_Kilometern__c 
                                from Opportunity where Id = :opportunityId limit 1];    
    if(oList != null && oList.size()>0){
        op = oList[0];
        
        htmlTag += tr;
        if(op.Produkt_Kategorie__c != null)
            htmlTag += tdOppTitle + 'Produkt' + tdEnd + tdOppValue + op.Produkt_Kategorie__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Produkt' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;

        htmlTag += tr;
        if(op.Art_des_Geb_udes__c != null)
            htmlTag += tdOppTitle + 'Art des Gebäudes' + tdEnd + tdOppValue + op.Art_des_Geb_udes__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Art des Gebäudes' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Umgebung__c != null)
            htmlTag += tdOppTitle + 'Innen oder Außen' + tdEnd + tdOppValue + op.Umgebung__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Innen oder Außen' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;

        htmlTag += tr;
        if(op.Anzahl_der_Etagen__c != null)
            htmlTag += tdOppTitle + 'Anzahl der Etagen' + tdEnd + tdOppValue + op.Anzahl_der_Etagen__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Anzahl der Etagen' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Treppenbauart__c != null)
            htmlTag += tdOppTitle + 'Treppenbauart' + tdEnd + tdOppValue + op.Treppenbauart__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Treppenbauart' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;

        htmlTag += tr;
        if(op.Belastbarkeit__c != null)
            htmlTag += tdOppTitle + 'Belastbarkeit (in Kg)' + tdEnd + tdOppValue + op.Belastbarkeit__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Belastbarkeit (in Kg)' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Bezugspunkt_der_PLZ_Suche__c != null)
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ-Suche' + tdEnd + tdOppValue + op.Bezugspunkt_der_PLZ_Suche__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ-Suche' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
       
        htmlTag += tr;
        if(op.Zeitpunkt_der_Versorgung__c != null)
            htmlTag += tdOppTitle + 'Zeitpunkt der Versorgung' + tdEnd + tdOppValue + op.Zeitpunkt_der_Versorgung__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Zeitpunkt der Versorgung' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Alternative_Postleitzahl__c != null)
            htmlTag += tdOppTitle + 'Angefragte Postleitzahl' + tdEnd + tdOppValue + op.Alternative_Postleitzahl__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Angefragte Postleitzahl' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;

//        htmlTag += tr;
//        if(op.Versorgungsdatum__c != null)
//            htmlTag += tdOppTitle + 'Versorgungsdatum' + tdEnd + tdOppValue + op.Versorgungsdatum__c + tdEnd;
//        else
//            htmlTag += tdOppTitle + 'Versorgungsdatum' + tdEnd + tdOppValue + '-' + tdEnd;
//        htmlTag += trEnd;
        
//        htmlTag += tr;
//        if(op.Suche_im_Umkreis_von_X_Kilometern__c != null)
//            htmlTag += tdOppTitle + 'Suche im Umkreis von X Kilometern' + tdEnd + tdOppValue  + op.Suche_im_Umkreis_von_X_Kilometern__c + tdEnd;
//        else
//            htmlTag += tdOppTitle + 'Suche im Umkreis von X Kilometern' + tdEnd + tdOppValue + '-' + tdEnd;
//        htmlTag += trEnd;

    }
    htmlTag += tblEnd;
    return htmlTag;
}

public String generateOpportunity_BEL(Id opportunityId ){
    String htmlTag = tblOpp ;
    Opportunity op;
    List<Opportunity> oList = [select Id, 
                                Mobility__c, 
                                Aktuelle_Betreuung__c, 
                                Unterbringungsm_glichkeit__c, 
                                Alternative_Postleitzahl__c, 
                                Bezugspunkt_der_PLZ_Suche__c, 
                                Deutschkenntnisse_der_Betreuungskraft__c, 
                                Geschlecht_der_Betreuungskraft__c, 
                                Versorgungsdatum__c, 
                                Budget__c, 
                                Medizinische_Pflege__c, 
                                Leichte_Pflege__c,
                                Betreuung__c,
                                Hauswirtschaft__c 
                                from Opportunity where Id = :opportunityId limit 1];
    if(oList != null && oList.size()>0){
        op = oList[0];
        
        htmlTag += tr;
        if(op.Mobility__c != null)
            htmlTag += tdOppTitle + 'Mobilität' + tdEnd + tdOppValue + op.Mobility__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Mobilität' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Aktuelle_Betreuung__c != null)
            htmlTag += tdOppTitle + 'Aktuelle Betreuung' + tdEnd + tdOppValue + op.Aktuelle_Betreuung__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Aktuelle Betreuung' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Unterbringungsm_glichkeit__c != null)
            htmlTag += tdOppTitle + 'Unterbringungsmöglichkeit' + tdEnd + tdOppValue + op.Unterbringungsm_glichkeit__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Unterbringungsmöglichkeit' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Alternative_Postleitzahl__c != null)
            htmlTag += tdOppTitle + 'Angefragte PLZ' + tdEnd + tdOppValue + op.Alternative_Postleitzahl__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Angefragte PLZ' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Bezugspunkt_der_PLZ_Suche__c != null)
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ-Suche' + tdEnd + tdOppValue + op.Bezugspunkt_der_PLZ_Suche__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ-Suche' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Deutschkenntnisse_der_Betreuungskraft__c != null)
            htmlTag += tdOppTitle + 'Deutschkenntnisse' + tdEnd + tdOppValue + op.Deutschkenntnisse_der_Betreuungskraft__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Deutschkenntnisse' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Geschlecht_der_Betreuungskraft__c != null)
            htmlTag += tdOppTitle + 'Geschlecht' + tdEnd + tdOppValue + op.Geschlecht_der_Betreuungskraft__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Geschlecht' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Versorgungsdatum__c != null)
            htmlTag += tdOppTitle + 'Gewünschter Betreuungsbeginn' + tdEnd + tdOppValue + op.Versorgungsdatum__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Gewünschter Betreuungsbeginn' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Budget__c != null)
            htmlTag += tdOppTitle + 'Budget' + tdEnd + tdOppValue + op.Budget__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Budget' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Medizinische_Pflege__c != null)
            htmlTag += tdOppTitle + 'Medizinische Pflege' + tdEnd + tdOppValue + op.Medizinische_Pflege__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Medizinische Pflege' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Leichte_Pflege__c != null)
            htmlTag += tdOppTitle + 'Leichte Pflege' + tdEnd + tdOppValue + op.Leichte_Pflege__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Leichte Pflege' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Betreuung__c != null)
            htmlTag += tdOppTitle + 'Betreuung' + tdEnd + tdOppValue + op.Betreuung__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Betreuung' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Hauswirtschaft__c != null)
            htmlTag += tdOppTitle + 'Hauswirtschaft' + tdEnd + tdOppValue + op.Hauswirtschaft__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Hauswirtschaft' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
    }
    htmlTag += tblEnd;
    return htmlTag;
}       

public String generateOpportunity_PI(Id opportunityId){
    String htmlTag = tblOpp ;
    Opportunity op;
    List<Opportunity> oList = [select Id, 
                                D_weites_Invest__c, 
                                location_direction__c,
                                financing_model__c,
                                Interesse_an_einer_Kapitalanlage__c,
                                beste_Erreichbarkeit__c,
                                T_tigkeit__c,
                                own_use__c,
                                Anmerkungen_f_r_den_Partner__c 
                                from Opportunity where Id = :opportunityId limit 1];
    if(oList != null && oList.size()>0){
        op = oList[0];
        
        htmlTag += tr;  
        if(op.Interesse_an_einer_Kapitalanlage__c != null && op.Interesse_an_einer_Kapitalanlage__c )
            htmlTag += tdOppTitle + 'Interesse an einer Kapitalanlage' + tdEnd + tdOppValue + 'Ja' + tdEnd;
        else
            htmlTag += tdOppTitle + 'Interesse an einer Kapitalanlage' + tdEnd + tdOppValue + 'Nein' + tdEnd;  
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.location_direction__c != null)
            htmlTag += tdOppTitle + 'Standortvorgabe für Immobilie' + tdEnd + tdOppValue + op.location_direction__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Standortvorgabe für Immobilie' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.financing_model__c != null)
            htmlTag += tdOppTitle + 'Finanzierungsmodell' + tdEnd + tdOppValue + op.financing_model__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Finanzierungsmodell' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.own_use__c != null)
            htmlTag += tdOppTitle + 'Eigenbedarf für Immobilie vorhanden' + tdEnd + tdOppValue + op.own_use__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Eigenbedarf für Immobilie vorhanden' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.T_tigkeit__c != null)
            htmlTag += tdOppTitle + 'Tätigkeit' + tdEnd + tdOppValue + op.T_tigkeit__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Tätigkeit' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.beste_Erreichbarkeit__c != null)
            htmlTag += tdOppTitle + 'beste Erreichbarkeit' + tdEnd + tdOppValue + op.beste_Erreichbarkeit__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'beste Erreichbarkeit' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Anmerkungen_f_r_den_Partner__c != null )
            htmlTag += tdOppTitle + 'Bemerkungen' + tdEnd + tdOppValue + op.Anmerkungen_f_r_den_Partner__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Bemerkungen' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
    }
    
    htmlTag += tblEnd;
    
    return htmlTag;
} 

public String generateOpportunity_HNR(Id opportunityId, String plzToolListe){
    String htmlTag = tblOpp ;
    Opportunity op;
    List<Opportunity> oList = [select Id,
                               Person_des_Bedarfs__c,
                               Produkt_Kategorie__c,
                               Bezugspunkt_der_PLZ_Suche__c,
                               Alternative_Postleitzahl__c,
                               Zeitpunkt_der_Versorgung__c,
                               Anmerkungen_f_r_den_Partner__c,
                               Versandadresse_Anrede__c,
                               Versandadresse_Vorname__c,
                               Versandadresse_Name__c,
                               Versandadresse_Stra_e__c,
                               Versandadresse_Ort__c,
                               Versandadresse_PLZ__c,
                               Partner_darf_sich_telefonisch_melden__c,
                               Partner_darf_Infomaterial_senden__c
                               from Opportunity where Id = :opportunityId limit 1];
    if(oList != null && oList.size()>0){
        op = oList[0];
        
        List<Kunden_Interesse__c> ki_list = [select id, 
                                                    Produkte_sollen_versendet_werden_an__c
                                             from Kunden_Interesse__c 
                                             where opportunity__r.Id = :op.Id 
                                             order by CreatedDate desc 
                                             limit 1];
        Kunden_Interesse__c ki = new Kunden_Interesse__c();
        if(ki_list != null && ki_list.size()>0){
            ki = ki_list[0];
        }
        
        htmlTag += tr;
        if(op.Person_des_Bedarfs__c != null)
            htmlTag += tdOppTitle + 'Bedarf besteht für' + tdEnd + tdOppValue + op.Person_des_Bedarfs__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Bedarf besteht für' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(plzToolListe == PLZTool_Hausnotruf.direktVertriebKey ){
            htmlTag += tdOppTitle + 'Produkt' + tdEnd + tdOppValue + '<pp:produktgruppe>' + tdEnd;
        }else{
            if(op.Produkt_Kategorie__c != null)
                htmlTag += tdOppTitle + 'Produkt' + tdEnd + tdOppValue + op.Produkt_Kategorie__c + tdEnd;
            else
                htmlTag += tdOppTitle + 'Produkt' + tdEnd + tdOppValue + '-' + tdEnd;
        }
        htmlTag += trEnd;
        
        if( plzToolListe == PLZTool_Hausnotruf.direktVertriebKey ){
            if(ki.Produkte_sollen_versendet_werden_an__c != null ){
                htmlTag += tr;
                htmlTag += tdOppTitle + 'Versand an' + tdEnd + tdOppValue + ki.Produkte_sollen_versendet_werden_an__c + tdEnd;
                htmlTag += trEnd;
                
                
                if(ki.Produkte_sollen_versendet_werden_an__c == 'Alternative Versandadresse'){
                    htmlTag += tr;
                    htmlTag += tdOppTitle + 'Andere Adresse' + tdEnd + tdOppValue + op.Versandadresse_Anrede__c + ' ' +
                        op.Versandadresse_Vorname__c + ' ' + op.Versandadresse_Name__c + '\n' +
                        op.Versandadresse_Stra_e__c + ' ' + op.Versandadresse_PLZ__c + ' '+ op.Versandadresse_Ort__c + tdEnd;
                    htmlTag += trEnd;
                }else{
                    htmlTag += tr;
                    htmlTag += tdOppTitle + 'Andere Adresse' + tdEnd + tdOppValue + '-' + tdEnd;
                    htmlTag += trEnd;
                    
                    htmlTag += tr;
                    htmlTag += tdOppTitle + 'Kontodaten' + tdEnd + tdOppValue + getKontoDatenTag(op.id, ki.Produkte_sollen_versendet_werden_an__c) + tdEnd;
                    htmlTag += trEnd;
                }
            }
            else{
                htmlTag += tr;
                htmlTag += tdOppTitle + 'Versand an' + tdEnd + tdOppValue + '-' + tdEnd; 
                htmlTag += trEnd;
                
                htmlTag += tr;
                htmlTag += tdOppTitle + 'Andere Adresse' + tdEnd + tdOppValue + '-' + tdEnd;
                htmlTag += trEnd;
                
                htmlTag += tr;
                htmlTag += tdOppTitle + 'Kontodaten' + tdEnd + tdOppValue + '-' + tdEnd;
                htmlTag += trEnd;
            }
            
            htmlTag += tr;
            if(op.Anmerkungen_f_r_den_Partner__c != null )
                htmlTag += tdOppTitle + 'Bemerkungen' + tdEnd + tdOppValue + op.Anmerkungen_f_r_den_Partner__c + tdEnd;
            else
                htmlTag += tdOppTitle + 'Bemerkungen' + tdEnd + tdOppValue + '-' + tdEnd;
            htmlTag += trEnd;
            
            htmlTag += tblEnd;
            return htmlTag;
        }
        
        htmlTag += tr;
        if(op.Partner_darf_sich_telefonisch_melden__c != null && op.Partner_darf_sich_telefonisch_melden__c )
            htmlTag += tdOppTitle + 'Telefonisch melden' + tdEnd + tdOppValue + 'Ja' + tdEnd;
        else
            htmlTag += tdOppTitle + 'Telefonisch melden' + tdEnd + tdOppValue + 'Nein' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Partner_darf_Infomaterial_senden__c != null && op.Partner_darf_Infomaterial_senden__c)
            htmlTag += tdOppTitle + 'Infomaterial zusenden' + tdEnd + tdOppValue + 'Ja' + tdEnd;
        else
            htmlTag += tdOppTitle + 'Infomaterial zusenden' + tdEnd + tdOppValue + 'Nein' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        //if(op.Produkt_Kategorie__c != null)
        //    htmlTag += tdOppTitle + 'die Kontaktdaten dürfen weitergeleitet werden' + tdEnd + tdOppValue + op.Produkt_Kategorie__c + tdEnd;
        //else
            htmlTag += tdOppTitle + 'die Kontaktdaten dürfen weitergeleitet werden' + tdEnd + tdOppValue + 'Ja' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Bezugspunkt_der_PLZ_Suche__c != null)
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ suche' + tdEnd + tdOppValue + op.Bezugspunkt_der_PLZ_Suche__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Bezugspunkt der PLZ suche' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        /*
        htmlTag += tr;
        if(op.Zeitpunkt_der_Versorgung__c != null)
            htmlTag += tdOppTitle + 'Zeitpunkt der Versorgung' + tdEnd + tdOppValue + op.Zeitpunkt_der_Versorgung__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Zeitpunkt der Versorgung' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        */
        
        htmlTag += tr;
        if(op.Alternative_Postleitzahl__c != null)
            htmlTag += tdOppTitle + 'Angefragte Postleitzahl' + tdEnd + tdOppValue + op.Alternative_Postleitzahl__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Angefragte Postleitzahl' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
    }
    htmlTag += tblEnd;
    return htmlTag;
} 
    
// to generate opportunity information in partner email. method is called from plz-tool
public String generateOpportunity_BAD(Id opportunityId ){
    String htmlTag = tblOpp ;
    Opportunity op;
    List<Opportunity> oList = [select Id, 
                               HousingSituation__c,
                               floor__c,
                               Produkt_Kategorie__c,
                               TypeOfBathtub__c,
                               Mobility__c,
                               UsedTools__c,
                               DesiredConversionSolution__c,
                               PreferredUsage__c,
                               RevisionshaftAvailable__c,
                               DesiredAdditionalServices__c,
                               PrivateOrCaringCustomer__c,
                               PossibleBudget__c,
                               SavingsPotential__c,
                               LandlordApprovalAvailable__c,
                               NameOnTheBell__c,
                               additional_information__c
                                from Opportunity where Id = :opportunityId limit 1];    
    if(oList != null && oList.size()>0){
        op = oList[0];
        
        
        htmlTag += tr;
        if(op.HousingSituation__c  != null)
            htmlTag += tdOppTitle + 'Wohnsituation' + tdEnd + tdOppValue + op.HousingSituation__c  + tdEnd;
        else
            htmlTag += tdOppTitle + 'Wohnsituation' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;

        htmlTag += tr;
        if(op.floor__c != null)
            htmlTag += tdOppTitle + 'Stockwerk' + tdEnd + tdOppValue + op.floor__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Stockwerk' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Produkt_Kategorie__c != null)
            htmlTag += tdOppTitle + 'Umzubauende Sanitärobjekte' + tdEnd + tdOppValue + op.Produkt_Kategorie__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Umzubauende Sanitärobjekte' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;

        htmlTag += tr;
        if(op.TypeOfBathtub__c != null)
            htmlTag += tdOppTitle + 'Art der Badewanne' + tdEnd + tdOppValue + op.TypeOfBathtub__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Art der Badewanne' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.Mobility__c  != null)
            htmlTag += tdOppTitle + 'Mobilität' + tdEnd + tdOppValue + op.Mobility__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Mobilität' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;

        htmlTag += tr;
        if(op.UsedTools__c  != null)
            htmlTag += tdOppTitle + 'Genutzte Hilfsmittel' + tdEnd + tdOppValue + op.UsedTools__c  + tdEnd;
        else
            htmlTag += tdOppTitle + 'Genutzte Hilfsmittel' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.PreferredUsage__c != null)
            htmlTag += tdOppTitle + 'Bevorzugte Nutzungsart' + tdEnd + tdOppValue + op.PreferredUsage__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Bevorzugte Nutzungsart' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
       
        htmlTag += tr;
        if(op.DesiredConversionSolution__c  != null)
            htmlTag += tdOppTitle + 'Wunschlösung' + tdEnd + tdOppValue + op.DesiredConversionSolution__c  + tdEnd;
        else
            htmlTag += tdOppTitle + 'Wunschlösung' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        /*
        htmlTag += tr;
        if(op.  != null)
            htmlTag += tdOppTitle + 'Restschwelle akzeptabel' + tdEnd + tdOppValue + op.  + tdEnd;
        else
            htmlTag += tdOppTitle + 'Restschwelle akzeptabel' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        */
        htmlTag += tr;
        if(op.RevisionshaftAvailable__c != null)
            htmlTag += tdOppTitle + 'Revisionsschacht vorhanden' + tdEnd + tdOppValue + op.RevisionshaftAvailable__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Revisionsschacht vorhanden' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.DesiredAdditionalServices__c != null)
            htmlTag += tdOppTitle + 'Gewünschte Zusatzleistungen' + tdEnd + tdOppValue + op.DesiredAdditionalServices__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Gewünschte Zusatzleistungen' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.PrivateOrCaringCustomer__c != null)
            htmlTag += tdOppTitle + 'Privatzahler vs. Kassen-Kunde  Falls Kassen-Kunde -technisches Schreiben erforderlich' + tdEnd + tdOppValue + op.PrivateOrCaringCustomer__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Privatzahler vs. Kassen-Kunde  Falls Kassen-Kunde -technisches Schreiben erforderlich' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.PossibleBudget__c != null)
            htmlTag += tdOppTitle + 'Mögliches max. Gesamtbudget für Umbaumaßnahme' + tdEnd + tdOppValue + op.PossibleBudget__c  + tdEnd;
        else
            htmlTag += tdOppTitle + 'Mögliches max. Gesamtbudget für Umbaumaßnahme' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.SavingsPotential__c != null)
            htmlTag += tdOppTitle + 'Einsparpotentiale' + tdEnd + tdOppValue + op.SavingsPotential__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Einsparpotentiale' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.NameOnTheBell__c != null)
            htmlTag += tdOppTitle + 'Name auf der Klingel' + tdEnd + tdOppValue + op.NameOnTheBell__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Name auf der Klingel' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(op.LandlordApprovalAvailable__c != null)
            htmlTag += tdOppTitle + 'Vermietergenehmigung vorhanden' + tdEnd + tdOppValue + op.LandlordApprovalAvailable__c + tdEnd;
        else
            htmlTag += tdOppTitle + 'Vermietergenehmigung vorhanden' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        //Zusatzinformationen
        htmlTag += tr;
        if(op.additional_information__c != null)
            htmlTag += tdOppTitle + 'Zusatzinformation ' + tdEnd + tdOppValue + op.additional_information__c  + tdEnd;
        else
            htmlTag += tdOppTitle + 'Zusatzinformation ' + tdEnd + tdOppValue + '-' + tdEnd;
        htmlTag += trEnd; 

    }
    htmlTag += tblEnd;
    return htmlTag;
}


    
public String getKontoDatenTag(id oppId, String role){
    List<OpportunityContactRole> contactRoles = [select ContactId, 
                                                        Contact.Name, 
                                                        Contact.BIC__c,
                                                        Contact.IBAN__c,
                                                        Contact.Kreditinstitut__c 
                                                 from OpportunityContactRole 
                                                 where OpportunityId = :oppId 
                                                    and IsDeleted = false
                                                    and (Role = :role
                                                    or Role = :PLZTool_Basis.contactRoleSame)
                                                 limit 1];
    if(contactRoles != null && contactRoles.size()>0){
        return contactRoles[0].Contact.Name + '\n' + contactRoles[0].Contact.IBAN__c + '\n' +
            contactRoles[0].Contact.BIC__c + '\n' + contactRoles[0].Contact.Kreditinstitut__c;
            
    }
    else
        return '-';
}
    
public String generateCustomerTag(Contact prs, Id individualEmailId){
        String htmlTag = tblCustomer ;
                
        htmlTag += tr;
        if( !String.isEmpty(prs.salutation) ){
            htmlTag += tdCustomerTitle + 'Name' + tdEnd + tdCustomerValue + prs.salutation + ' ' + prs.Name + tdEnd;
        }else{
            htmlTag += tdCustomerTitle + 'Name' + tdEnd + tdCustomerValue + prs.Name + tdEnd;
        }
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(prs.mailingStreet != null)
            htmlTag += tdCustomerTitle + 'Strasse' + tdEnd + tdCustomerValue + prs.mailingStreet+ tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Strasse' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;        
        
        htmlTag += tr;
        if(prs.MailingPostalCode != null || prs.MailingCity != null)
            htmlTag += tdCustomerTitle + 'PLZ Ort' + tdEnd + tdCustomerValue + prs.MailingPostalCode + ' ' + prs.MailingCity + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'PLZ Ort' + tdEnd + tdCustomerValue + ' ' + tdEnd;
        htmlTag += trEnd;    

        htmlTag += tr;
        if(prs.Phone != null)
            htmlTag += tdCustomerTitle + 'Telefon' + tdEnd + tdCustomerValue + prs.Phone + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Telefon' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(prs.Email != null)
            htmlTag += tdCustomerTitle + 'Email' + tdEnd + tdCustomerValue + prs.Email+ tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Email' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
       
        
    if(individualEmailId != null){
        List<Individuelle_Partner_Email_Daten__c> fields = [select Id, Name, Field_API_Name__c, Individuelle_Partner_Email__c, Lookup_Object__c from Individuelle_Partner_Email_Daten__c where Individuelle_Partner_Email__c = :individualEmailId and  Reference_Object__c = 'Contact'];
        if(fields != null && fields.size()> 0){
            String queryString = 'select ';
            for(Individuelle_Partner_Email_Daten__c f : fields){
                queryString += f.Field_API_Name__c + ' , ';
            }
            queryString += ' Id from Contact where Id = \''+ prs.Id +'\' limit 1 ';
            List<SObject> oList =  Database.query(queryString);
            SObject obj;
            if(oList != null && oList.size()>0){
                obj = oList[0];
                for(Individuelle_Partner_Email_Daten__c f : fields){
                    htmlTag += tr;
                    if(obj.get(f.Field_API_Name__c) != null)
                        if(f.Lookup_Object__c != null){
                            String lookupQueryString = 'select Id, name from ' + f.Lookup_Object__c + ' where Id = \''+ obj.get(f.Field_API_Name__c) +'\' limit 1 ';
                            List<SObject> lookUpObjList =  Database.query(lookupQueryString);
                            if(lookUpObjList != null && lookUpObjList.size()>0){
                                htmlTag += tdCustomerTitle + f.Name + tdEnd + tdCustomerValue + lookUpObjList[0].get('name') + tdEnd;
                            }
                        }else{
                            htmlTag += tdCustomerTitle + f.Name + tdEnd + tdCustomerValue + obj.get(f.Field_API_Name__c) + tdEnd;
                        }     
                    else
                        htmlTag += tdCustomerTitle + f.Name + tdEnd + tdCustomerValue + '-' + tdEnd;
                    htmlTag += trEnd;
            }
        }
    }
    }
     
          
    return htmlTag;
}

public String addExtraField_BEL(Id contactId){
    String htmlTag = '';
    List<Contact> cList = [Select Id, Bekannte_Krankheiten__c, pflegestufe__c, pflegegrad__c from Contact where Id = : contactId limit 1];
    if(cList != null && cList.size()>0){
        Contact c = cList[0];
        
        htmlTag += tr;
        String pflegeValue = '-';
        if(c.pflegestufe__c != null)
            pflegeValue = c.pflegestufe__c;
        pflegeValue += ' / ';
        if(c.pflegegrad__c != null)
            pflegeValue += c.pflegegrad__c;
        else
            pflegeValue += '-';
        htmlTag += tdCustomerTitle + 'Pflegestufe / Pflegegrad' + tdEnd + tdCustomerValue + pflegeValue + tdEnd;
        htmlTag += trEnd;
        
   /*     htmlTag += tr;
        if(c.Bekannte_Krankheiten__c!= null)
            htmlTag += tdCustomerTitle + 'Krankheitsbild' + tdEnd + tdCustomerValue + c.Bekannte_Krankheiten__c + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Krankheitsbild' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd; */
    }
    return htmlTag;
}
 

public String addExtraField_HNR(Id contactId){
    String htmlTag = '';
    List<Contact> cList = [Select Id, Bekannte_Krankheiten__c, Sonstige_Krankheiten__c, pflegestufe__c, pflegegrad__c from Contact where Id = : contactId limit 1];
    if(cList != null && cList.size()>0){
        Contact c = cList[0];
        
        htmlTag += tr;
        String pflegeValue = '-';
        if(c.pflegestufe__c != null)
            pflegeValue = c.pflegestufe__c;
        pflegeValue += ' / ';
        if(c.pflegegrad__c != null)
            pflegeValue += c.pflegegrad__c;
        else
            pflegeValue += '-';
        htmlTag += tdCustomerTitle + 'Pflegestufe / Pflegegrad' + tdEnd + tdCustomerValue + pflegeValue + tdEnd;
        htmlTag += trEnd;
        
    /*    htmlTag += tr;
        if(c.Bekannte_Krankheiten__c!= null)
            htmlTag += tdCustomerTitle + 'Krankheitsbild' + tdEnd + tdCustomerValue + c.Bekannte_Krankheiten__c + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Krankheitsbild' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(c.Sonstige_Krankheiten__c!= null)
            htmlTag += tdCustomerTitle + ' ' + tdEnd + tdCustomerValue + c.Sonstige_Krankheiten__c + tdEnd;
        else
            htmlTag += tdCustomerTitle + ' ' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd; */
    }
    return htmlTag;
}
    
public String addExtraField_PI(Id contactId){
    String htmlTag = '';
    List<Contact> cList = [Select Id, Birthdate, Alter__c from Contact where Id = : contactId limit 1];
    if(cList != null && cList.size()>0){
        Contact c = cList[0];
        
        htmlTag += tr;
        if(c.Alter__c != null)
            htmlTag += tdCustomerTitle + 'Alter' + tdEnd + tdCustomerValue + c.Alter__c + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Alter' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
    }
    return htmlTag;
}

    /* #160167197 two other fields will be included in the email to partner
     * method is called from plzPartnerEmailBodyGenerator.prepareEmailbody
     * */
public String addExtraField_Badumbau(Id contactId){
    String htmlTag = '';
    List<Contact> cList = [Select Id, MobilePhone, OtherPhone  from Contact where Id = : contactId limit 1];
    if(cList != null && cList.size()>0){
        Contact c = cList[0];
        htmlTag += tr;
        if(c.OtherPhone != null)
            htmlTag += tdCustomerTitle + 'Weitere Tel-Nr.' + tdEnd + tdCustomerValue + c.OtherPhone + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Weitere Tel-Nr.' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
        
        htmlTag += tr;
        if(c.MobilePhone != null)
            htmlTag += tdCustomerTitle + 'Mobiltelefon' + tdEnd + tdCustomerValue + c.MobilePhone + tdEnd;
        else
            htmlTag += tdCustomerTitle + 'Mobiltelefon' + tdEnd + tdCustomerValue + '-' + tdEnd;
        htmlTag += trEnd;
    }
    return htmlTag;
}    
    

public String closeCustomerTable(){
    return tblEnd;
}

}