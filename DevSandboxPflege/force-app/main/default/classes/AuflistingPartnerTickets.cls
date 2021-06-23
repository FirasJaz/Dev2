//****************************************************************************************************************************
// Erstellt 01.08.2016 von MZ
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
//	
//
//****************************************************************************************************************************
//Änderungen:
//    MZ    06.12.2016    Auswahl von Abrechnungszeitraum. 
//    MZ    25.10.2017    opportunity number replaced with partner ticket name
//    MZ    05.12.2017    #153354745 Monatsauflistung: Spalte Stornierung entfernen
//    AM    09.05.2019    #165908732 Error too many SOQL - query in for loop in generateTickets()
//    DZ    29.01.2020    PLZ und Ort wurden auskommentiert.
//    DZ    08.04.2020    "mail.setWhatId(currPartner.id)" hinzugefügt
//    PK 	10.02.2021	  Added index of ticekts
//****************************************************************************************************************************

global with sharing class AuflistingPartnerTickets{
    private String timePeriodValue;


    global AuflistingPartnerTickets(String tpv){
        timePeriodValue = tpv;
    }

    public ApexPages.message auflistung(Id partnerId)
        {
            ApexPages.message result = new ApexPages.message(ApexPages.severity.Error, 'Error in preparing the list of tickets! please try later.');
            Account currPartner = new Account();
            List<Account> partners= [select Id, ticket_email_address__c from Account where Id = :partnerId limit 1];
            if(partners != null && partners.size()>0){
                result = sendEmail(partners[0]);
            }
            return result;
        }

    private static String generateTickets(List<Partner_Ticket__c> tickets, Boolean isCPO){
        String tr = '<tr >';
        String trEnd = '</tr>';
        String td = '<td valign="top" width="125" style="-ms-text-size-adjust:100%;-webkit-text-size-adjust:100%;-webkit-font-smoothing:subpixel-antialiased;font-smooth:always">';
        String tdEnd = '</td>';
        // 09.05.2019 AM
        map<id, OpportunityContactRole> contactMap = new map<id, OpportunityContactRole>();
        set<id> ptSet = new set<id>();
        for(Partner_Ticket__c t: tickets){
            ptSet.add(t.opportunity__c);
        }
        List<OpportunityContactRole> contactList = [ select Contact.Name, OpportunityId from OpportunityContactRole where ( Role='ASP' or Role='PB = ASP') and IsDeleted = false and OpportunityId IN :ptSet];
        if((contactList != null) && (contactList.Size() > 0)) {
            for(OpportunityContactRole ocr : contactList) {
                contactMap.put(ocr.opportunityId, ocr);
            }
        }
        String tag = '';
        for(Partner_Ticket__c t: tickets){
            // List<OpportunityContactRole> contactList = [ select Contact.Name  from OpportunityContactRole where ( Role='ASP' or Role='PB = ASP') and IsDeleted = false and OpportunityId = :t.opportunity__c ];
            if( contactList != null && contactList.size()!= 0 ){
                tag += tr;

                tag += td;
                tag += tickets.indexOf(t) + 1;
                tag += tdEnd ;
                tag += td;
                tag += t.Name;
                tag += tdEnd ;

                tag += td;
                // if(!String.isEmpty(contactList[0].Contact.Name)){
                if(!String.isEmpty(contactMap.get(t.opportunity__c).Contact.Name)){
                    tag += contactMap.get(t.opportunity__c).Contact.Name;
                }else{
                    tag += '-';
                }
                tag += tdEnd ;

                /*
				  tag += td;
				  String plzCity = '-';
				  // if(!String.isEmpty(contactList[0].Contact.MailingPostalCode)){
				  if(!String.isEmpty(contactMap.get(t.opportunity__c).Contact.MailingPostalCode)){
					  plzCity = contactMap.get(t.opportunity__c).Contact.MailingPostalCode;
				  }
				  // if(!String.isEmpty(contactList[0].Contact.MailingCity)){
				  if(!String.isEmpty(contactMap.get(t.opportunity__c).Contact.MailingCity)){
					  plzCity += ' ' + contactMap.get(t.opportunity__c).Contact.MailingCity;
				  }
				  tag += plzCity;
				  tag += tdEnd ;

				   */
                tag += td;
                tag += t.createdDate.format('dd/MM/yyyy');
                tag += tdEnd ;


                if(isCPO){
                    tag += td;
                    tag += '<a href="https://service.pflege.de/leads/treppenlift/?ID='+ t.Id +'" > Bitte klicken </a>';
                    tag += tdEnd;
                }

                tag += trEnd;
            }
        }
        return tag ;
    }

    private ApexPages.Message sendEmail(Account currPartner){

        String cpo_status = 'Übermittelt';
        String cpl_status = 'Abrechenbar';

        String emailTemplateName = 'Auflistung_email';
        EmailTemplate et = new EmailTEmplate();
        List<EmailTemplate> etList = new List<EmailTemplate>();
        etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = :emailTemplateName limit 1];

        if(etList != null && etList.size() > 0){
            et = etList[0];
        }else{
            System.debug('error in sendEmail:: Mansi:::: template not found');
            return new ApexPages.message(ApexPages.severity.Error, 'Email template not found! Please check the availability of the email template where DeveloperName = ' + emailTemplateName);
        }
        if(! et.isActive){
            System.debug('error in sendEmailToCustomer:: Mansi:::: template is not active');
            return new ApexPages.message(ApexPages.severity.Error, 'Required email template is not active! Please check the availability of the email template where DeveloperName = ' + emailTemplateName);
        }
        String htmlValue = et.HtmlValue;

        Datetime today = Datetime.now();
        Integer iMonth = today.month()-1;
        Integer iYear = today.year();
        if( iMonth == 0 ){
            iMonth = 12;
            iYear -= 1;
        }
        String targetMonth = String.valueOf(iMonth);
        String targetYear = String.valueOf(iYear);

        String queryString = 'select Id, '+
        + 'Name, '+
        + 'Partner__c, '+
        + 'Status_CPL__c, '+
        + 'Status_CPO__c, '+
        + 'opportunity__c, '+
        + 'opportunity__r.Opportunity_Nummer__c, '+
        + 'createdDate from Partner_Ticket__c '+
        + 'where Partner__c = \'' + currPartner.Id + '\' '+
        + 'and Status_CPL__c = \'' + cpl_status + '\' ';


        if(timePeriodValue == IndividualPartnerInvoicing.letztenMonatKey){
            queryString += ' and createdDate = LAST_MONTH ';
        }
        else if(timePeriodValue == IndividualPartnerInvoicing.diesenMonatKey){
            queryString += ' and DAY_IN_MONTH(createdDate) >= 1 '+
                    ' and DAY_IN_MONTH(createdDate) <= 15 '+
                    ' and createdDate = THIS_MONTH ';
            targetMonth = String.valueOf(today.month());
            targetYear = String.valueOf(today.year());
        }
        else if(timePeriodValue == IndividualPartnerInvoicing.letztesQuartalKey){
            queryString += ' and createdDate = LAST_QUARTER ';
            if( today.month()>=1 && today.month()<=3 ){
                targetMonth = '10-12';
                targetYear = String.valueOf(today.year()-1);
            }else if( today.month()>=4 && today.month()<=6 ){
                targetMonth = '1-3';
                targetYear = String.valueOf(today.year());
            }else if( today.month()>=7 && today.month()<=9 ){
                targetMonth = '4-6';
                targetYear = String.valueOf(today.year());
            }else{
                targetMonth = '7-9';
                targetYear = String.valueOf(today.year());
            }
        }
        queryString += ' order by createdDate desc ';

        List<Partner_Ticket__c> cplTickets = Database.query(queryString);

        htmlValue = htmlValue.replace('<p id="pAuflistungMonth"/>', targetMonth + ' - ' + targetYear );
        String noTickets = '<tr> <td> - </td> <td> - </td> <td> - </td> <td> - </td> <td> - </td> </tr>';

        String cplTicketsTag = noTickets;
        if(cplTickets != null && cplTickets.size()>0){
            cplTicketsTag = generateTickets(cplTickets, false);
        }
        htmlValue = htmlValue.replace('<table id="tblCplTickets"/>', cplTicketsTag );

        List<Partner_Ticket__c> cpoTickets = [select Id, Name, Partner__c,Status_CPL__c, Status_CPO__c, opportunity__c, opportunity__r.Opportunity_Nummer__c, createdDate from Partner_Ticket__c where Partner__c = :currPartner.Id and Status_CPO__c = :cpo_status order by createdDate desc ];
        String cpoTicketsTag = noTickets;
        if(cpoTickets != null && cpoTickets.size()>0){
            cpoTicketsTag = generateTickets(cpoTickets, true);
        }
        htmlValue = htmlValue.replace('<table id="tblCpoTickets"/>', cpoTicketsTag );

        htmlValue = setUserfields(htmlValue);

        /* this block replaced by the conatct List of the partner
        String[] emailAddrresses = currPartner.ticket_email_address__c.split(',');
        mail.setToAddresses(new String[]{emailAddrresses [0]});
        emailAddrresses.remove(0);
        if(emailAddrresses.size()>0){
            mail.setCcAddresses (emailAddrresses);
        }*/

        List<Contact> contactList = [select id, name, salutation, email from Contact where accountId = :currPartner.id and Empf_nger_der_monatlichen_Auflistung__c = true];
        if(contactList != null && contactList.size() > 0 ){
            Boolean hasEmail = false;
            for( Contact c : contactList ){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String salutation= '';
                if ( c.salutation != null ){
                    salutation = c.salutation + ' ';
                }
                htmlValue = htmlValue.replace('<p id="recipient"/>', salutation + c.name);
                mail.setHtmlBody(htmlValue );
                mail.setPlainTextBody(et.body);
                mail.setSubject(et.Subject);
                mail.setTemplateId(et.Id);
                mail.setWhatId(currPartner.id);
                if( c.email != null && c.email != '' ){
                    hasEmail = true;
                    mail.setToAddresses(new String[]{c.email});
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                }
            }
            if(!hasEmail ){
                return new ApexPages.message(ApexPages.severity.Error, 'Contact has no email address! ');
            }
        }
        else{
            return new ApexPages.message(ApexPages.severity.Error, 'Email receiver not found! ');
        }

        Task tsk = new Task();
        tsk.status = 'Outbound Email';
        tsk.subject = 'Email: Monatsauflistung verschicken';
        tsk.whatId = currPartner.Id;
        tsk.status = 'Geschlossen';
        tsk.ActivityDate = DateTime.now().date();
        insert tsk;
        return new ApexPages.message(ApexPages.severity.Confirm, 'Email gesendet wird erfolgreich!');
    }

    private static String setUserfields(String str){
        List<User> uList = [select Id, Name, Title, phone, email from User where Id = :UserInfo.getUserId() limit 1];
        if(uList != null && uList .size()>0){
            if(UserInfo.getName()!= null) { str = str.replace('{!User.Name}', UserInfo.getName() ); }else{str = str.replace('{!User.Name}', ' ');}
            if(uList[0].Title!= null) { str = str.replace('{!User.Title}', uList[0].Title );}else{str = str.replace('{!User.Title}', ' ' );}
            if(uList[0].phone!= null) { str = str.replace('{!User.Phone}', uList[0].phone );}else{str = str.replace('{!User.Phone}', ' ');}
            if(UserInfo.getUserEmail()!= null) { str = str.replace('{!User.Email}', UserInfo.getUserEmail() );}else{str = str.replace('{!User.Email}', ' ' );}
        }
        return str;
    }

}