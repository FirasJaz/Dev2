//****************************************************************************************************************************
// Created  23.01.2017     by MZ
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
//          Send Email to customer when the status of Nachtelefonie changes to "Auslandsanfrage" or "Job Anfrage"
//
//****************************************************************************************************************************
//Changes:
//    13.02.2017    MZ    remove the first name of email receiver in the email
//    16.11.2017    MZ    #152709934 specific template for PI added
//****************************************************************************************************************************

trigger sendEmailOnAbbruchgerundEdit on Opportunity (after update) {
    for (Opportunity opp: Trigger.new){
        if (!TriggerRunOnce.isAlreadyDone(opp.Id)) {
            // do your processing
            if( Trigger.oldMap.get(opp.Id) != null &&
                Trigger.oldMap.get(opp.Id).Abbruchgrund__c == null &&
                Trigger.oldMap.get(opp.Id).Abbruchgrund__c != opp.Abbruchgrund__c &&
                opp.Abbruchgrund__c != null &&
               (opp.Abbruchgrund__c == NachtelefonieAbbruch.abbruchgerundAuslandsanfrage ||
                opp.Abbruchgrund__c == NachtelefonieAbbruch.abbruchgerundJobAnfrage) ){
                Id recipientId;
                List<OpportunityContactRole> role_list = [SELECT ContactId from OpportunityContactRole where OpportunityId = :opp.Id and ( Role = 'ASP' or Role = 'PB = ASP')];
                if(role_list != null && role_list.size()>0){
                    recipientId = role_list[0].ContactId;
                }
                List<Contact> c_list = [select id, salutation,firstName, lastName, name, phone from contact where Id = :recipientId limit 1 ];
                Contact recipient;
                if( c_list!= null && c_list.size()>0 ){
                    recipient = c_list[0];
                }
                String templateName  = NachtelefonieAbbruch.defaultEmailTemplate ;
                if(opp.recordType.name == PLZTool_Basis.rtPflegeimmobilien){
                    templateName = NachtelefonieAbbruch.defaultEmailTemplate_PI;
                }
                if(opp.recordType.name == PLZTool_Basis.rtBadumbau){
                    templateName = NachtelefonieAbbruch.defaultEmailTemplate_Badumbau;
                }
                if(opp.Abbruchgrund__c == NachtelefonieAbbruch.abbruchgerundAuslandsanfrage){
                    templateName = NachtelefonieAbbruch.auslandAnfrageEmailTemplate;
                }
                if(opp.Abbruchgrund__c == NachtelefonieAbbruch.abbruchgerundJobAnfrage){
                    templateName = NachtelefonieAbbruch.jobAnfrageEmailTemplate ;
                }
                List<EmailTemplate> etList = [select Id, Name, DeveloperName, isActive, Subject, HtmlValue, Body  from EmailTemplate where DeveloperName = :templateName  limit 1];
                EmailTemplate et = new EmailTEmplate();
                if(etList != null && etList.size() > 0){
                    et = etList[0];
                    if(et.isActive){
                
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
                                          
                        String htmlValue = EmailTemplateHelper.setRecipientFields(et.HtmlValue, recipient.salutation, recipient.lastName, recipient.phone );
                        htmlValue = EmailTemplateHelper.setRegion(htmlValue, opp.Id);
                        htmlValue = EmailTemplateHelper.setUserfields(htmlValue, UserInfo.getUserId());
                                
                        mail.setHtmlBody(htmlValue);
                        mail.setPlainTextBody(et.body);
                        mail.setSubject(et.Subject);
                        mail.setTargetObjectId(recipient.id);
                        
                        if(opp.recordType.name == PLZTool_Basis.rtBadumbau){
                            mail.setHtmlBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, htmlValue, UserInfo.getUserId()));
                            mail.setPlainTextBody(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, et.body, UserInfo.getUserId()));
                            mail.setSubject(EmailMessageTagGenerator_Badumbau.resolveMergeFields(opp.Id, et.Subject, UserInfo.getUserId()));
                            mail.setWhatId(opp.Id);
                            List<OrgWideEmailAddress> orgWideAddresses = [select id, Address, DisplayName from OrgWideEmailAddress where DisplayName = 'Badumbau'];
                            if(orgWideAddresses != null && orgWideAddresses.size()>0){
                                mail.setOrgWideEmailAddressId(orgWideAddresses[0].Id);
                                mail.setReplyTo(orgWideAddresses[0].Address);
                            }
                        }

                        Messaging.SendEmailResult[] sendMailRes = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});  
                        if(! sendMailRes[0].success){
                            System.debug('Error : could not send email! ' + sendMailRes[0]);
                        }
                    }else{
                        System.debug('error in sendEmailOnAbbruchgerundEdit :: Mansi:::: template not found');
                        System.debug('error in sendEmailOnAbbruchgerundEdit :: Mansi:::: template is not active');
                    }
                }
            } 
            TriggerRunOnce.setAlreadyDone(opp.Id);
        }     
    }   
}