//****************************************************************************************************************************
// Created Juli 2016     by MZ
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
//                Tool, welches die Email Templates zum Versand einer Nachricht an Kunden "Nicht erreicht" mit der PLZ und
//                Anrede befüllt.
//
//****************************************************************************************************************************
//Changes:
//
// 13.10.2016    TK/WDS  Wenn keine PLZ in OPP enthalten ist, wird ', die uns derzeit leider noch nicht bekannt ist' eingesetzt.
// 17.08.2016    MZ    tipp added to 
//****************************************************************************************************************************



public class EmailTemplateHelper {


public static String setTipp(String str, Id oppId){
    List<opportunity> oppList =  [select Id, RecordType.Name from opportunity where id = : oppId limit 1];
    
    String tipp = '<br/>Mein persönlicher Tipp an Sie: Bei einer bestehenden Pflegestufe oder einem bestehenden Pflegegrad haben Sie Anspruch auf Pflegehilfsmittel im Wert von 480 € pro Jahr. Diese liefern wir Ihnen kostenlos nach Hause. Nutzen Sie Ihren Anspruch und kontaktieren Sie mich persönlich.<br/>';

    if(oppList != null && oppList.size()>0 && oppList[0].RecordType.Name == PLZTool_Basis.rtPflegeimmobilien){
        tipp = ' ';
    }
    str = str.replace('<p id="tipp"/>', tipp);            
    return str;
}

    
public static String setUserfields(String str, Id userId){
    User currentUser;
    List<User> uList = [select Id, Name, Title, phone, email from User where Id = :userId limit 1];
    if(uList != null && uList .size()>0){
        currentUser = uList [0];
        if(currentUser.Name!= null) { str = str.replace('{!User.Name}', currentUser.Name ); }else{str = str.replace('{!User.Name}', ' ');}
        if(currentUser.Title!= null) { str = str.replace('{!User.Title}', currentUser.Title );}else{str = str.replace('{!User.Title}', ' ' );}
        if(currentUser.phone!= null) { str = str.replace('{!User.Phone}', currentUser.phone );}else{str = str.replace('{!User.Phone}', ' ');}
        if(currentUser.email!= null) { str = str.replace('{!User.Email}', currentUser.email );}else{str = str.replace('{!User.Email}', ' ' );}
    }
    return str;
} 
  
         
public static String setRecipientFields(String str, String salutation, String name, String phone){
 
    String result = 'Liebe Frau /Lieber Herr ';
    if( salutation != null && salutation.contains ('Herr') ){
        result = 'Lieber ' + salutation + ' ';
    }
    if( salutation != null && salutation.contains ('Frau') ){
        result = 'Liebe ' + salutation + ' ';
    }
    result += name;
    str = str.replace('<p id="recipient"/>', result);
    
    if(phone != null && phone != '' ){
        str = str.replace('<p id="recipient_phone"/>', phone);  
    }      
    
    return str;
}
    
    public static String setRegion(String str, Id oppotunity_id){       
        Opportunity opp;
        opportunity[] opportunityList = [select RecordType.Name, Bezugspunkt_der_PLZ_Suche__c, Alternative_Postleitzahl__c  from opportunity where Id = :oppotunity_id limit 1];
        if(opportunityList != null && opportunityList.size()>0){
            opp = opportunityList[0]; 
            String result = '';
            if (opp.Alternative_Postleitzahl__c != Null){
                result = '<br/>Laut Ihren Angaben suchen Sie eine Liftlösung in der Region ' + opp.Alternative_Postleitzahl__c +'.<br/>';
                }
              
            OpportunityContactRole[] OpportunityContactRoleList;
            if(opp.Bezugspunkt_der_PLZ_Suche__c == PostleitzahlenTool.PlzTypes[0]){
                OpportunityContactRoleList = [select Contact.MailingPostalCode from OpportunityContactRole where OpportunityId = :oppotunity_id and (Role = :PostleitzahlenTool.OpportunityContactRoles[0] or Role = :PostleitzahlenTool.OpportunityContactRoles[2]) limit 1];
            }
            if(opp.Bezugspunkt_der_PLZ_Suche__c == PostleitzahlenTool.PlzTypes[1]){
                OpportunityContactRoleList = [select Contact.MailingPostalCode from OpportunityContactRole where OpportunityId = :oppotunity_id and (Role = :PostleitzahlenTool.OpportunityContactRoles[1] or Role = :PostleitzahlenTool.OpportunityContactRoles[2]) limit 1];
            }
            if(OpportunityContactRoleList != null && OpportunityContactRoleList.size()>0){
                result = OpportunityContactRoleList[0].Contact.MailingPostalCode;
            }
            if(result == null){
                result = '';
            }
            str = str.replace('<p id="recipient_plz"/>', result);  
                   
        }
        return str;
    }
    
    
}