//****************************************************************************************************************************
// Erstellt 02.09.2019 von AM
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
// Controller for creating leads fron Landing Page
//
//****************************************************************************************************************************
//Änderungen:
//22.04.2020    DZ "Referrer" hinzugefügt.
//****************************************************************************************************************************
@RestResource(urlMapping='/curaboxlead/*')
global class ksgCuraboxLeadController {

    @HttpPost
    global static string createNewLead( string next_step,
                                        marketing marketing,
                                        Box box,
                                        Insured_person insured_person,
                                        care_person care_person,
                                        care_service care_service,
                                        pdf_form pdf_form,
                                        antrag_1 Antrag_1,
                                        antrag_2 Antrag_2,
                                        mc_infos mc_infos) {

        id rtid = null;
        id ownid = UserInfo.getUserId();
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name= 'Curabox'];
        if((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }

        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }

        lead l = new lead(Company='curabox', Status='Open');
        l.RecordTypeId = rtid;
        l.OwnerID = ownid;

        l.next_Step__c = next_step;
        if(box != null) {
            try {
                l.CB_Box__c = box.box;
                l.CB_Handschuh_Groesse__c = box.glove_size;
                l.CB_Lieferung__c = box.delivery_address;
                // = box.bed_protection_underlays;
            }
            catch (System.Exception e) {}
        }
        if(care_service != null) {
            try {
                l.CB_Pflegedienst_Name__c = care_service.cs_name;
                l.CB_Pflegedienst_PLZ__c = care_service.cs_zipcode;
                l.CB_Pflegedienst_Ort__c = care_service.cs_city;
                l.CB_Pflegedienst_Strasse__c = care_service.cs_street_nr;
            }
            catch (System.Exception e) {}
        }
        if(Insured_person != null) {
            try {
                l.LastName = Insured_person.ip_lname;
                l.FirstName = Insured_person.ip_fname;
                l.Salutation = Insured_person.ip_salutation;
                l.Email = Insured_person.ip_email;
                l.Street = Insured_person.ip_street_nr;
                l.PostalCode = Insured_person.ip_zipcode;
                l.City = Insured_person.ip_city;
                l.Phone = Insured_person.ip_phone;
                l.Geburtsdatum__c = Insured_person.ip_born_at;
                l.Pflegestufe__c = Insured_person.ip_care_level;
                l.Pflegegrad__c = Insured_person.ip_care_rank;
                l.Versicherungsnummer__c = Insured_person.ip_insurance_number;
                l.IK_Nummer_des_traegers__c = Insured_person.ip_identitynumber_carrier_a;
                l.Kostentr_ger__c = Insured_person.ip_identitynumber_carrier_b;
            }
            catch (System.Exception e) {}
        }
        if(care_person != null) {
            try {
                l.Angehoeriger_Anrede__c = care_person.cp_salutation;
                l.Angehoeriger_Vorname__c = care_person.cp_fname;
                l.Angehoeriger_Nachname__c = care_person.cp_lname;
                l.Angehoeriger_Email__c = care_person.cp_email;
                l.Angehoeriger_Telefon__c = care_person.cp_phone;
                l.Angehoeriger_Vollmacht__c = care_person.cp_authorized;
                l.Angehoeriger_Strasse__c = care_person.cp_street_nr;
                l.Angehoeriger_PLZ__c = care_person.cp_zipcode;
                l.Angehoeriger_Ort__c = care_person.cp_city;
            }
            catch (System.Exception e) {}
        }
        if(Marketing != null) {
            try {
                l.OM_created_at__c = Marketing.created_at;
                l.OM_Tracking_Order_ID__c = Marketing.Order_ID;
                l.OM_Wizard_Version__c = Marketing.wizard_version;
                l.OM_Partner_ID__c = Marketing.Partner_ID;
                l.OM_Referrer__c = Marketing.referrer;
                List<Campaign> cmplist = [select id, name from Campaign where name =: Marketing.wizard_name LIMIT 1];
                if(cmplist != null && cmplist.size() != 0) l.OM_Wizzard_Name2__c = cmplist[0].Id;
            }
            catch (System.Exception e) {}
        }
        // MC connect - 29.04.2021
        if(mc_infos != null) {
            try {
                l.OM_CB_Digital_Signatur__c = mc_infos.digital_signature;
                l.OM_UserID__c = mc_infos.visitorID;
                l.OM_Visit_ID__c = mc_infos.visitID;
                l.OM_Timestamp__c = Datetime.now().format();
                l.OM_Subscriber_Key__c = mc_infos.email;
                l.OM_Order_ID__c = mc_infos.orderid;
                l.OM_CB_Digi_Signatur_Code__c = mc_infos.code;

                // Privat versicherte
                if (mc_infos.digital_signature == 'signatur_privat_flexbox') {
                    l.billing_name__c = mc_infos.billing_addr_name;
                    l.shipping_name__c = mc_infos.deliv_addr_name;
                    l.shipping_street__c = mc_infos.deliv_addr_street;
                    l.shipping_postal_code__c = mc_infos.deliv_addr_zip;
                    l.shipping_city__c = mc_infos.deliv_addr_city;
                    l.OM_Delivery_interval__c = mc_infos.deliv_interval_pg54;
                    l.OM_bed_protector_quantity__c = mc_infos.prod_bed_prot_quant;
                    l.OM_bed_protector_price__c = mc_infos.prod_bed_prot_price;
                    l.OM_Gloves_Quantity__c = mc_infos.prod_gloves_quant;
                    l.OM_Gloves_Price__c = mc_infos.prod_gloves_price;
                    l.OM_Hand_Disinfection_Quantity__c = mc_infos.prod_hand_dis_quant;
                    l.OM_Hand_Disinfection_Price__c = mc_infos.prod_hand_dis_price;
                    l.OM_Surface_Disinfection_Quantity__c = mc_infos.prod_surface_dis_quant;
                    l.OM_Surface_Disinfection_Price__c = mc_infos.prod_surface_dis_price;
                    l.OM_Masks_Quantity__c = mc_infos.prod_masks_quant;
                    l.OM_Masks_Price__c = mc_infos.prod_masks_price;
                    l.OM_ffp2_Mask_Quantity__c = mc_infos.prod_ffp2_masks_quant;
                    l.OM_ffp2_Mask_Price__c = mc_infos.prod_ffp2_masks_price;
                    l.OM_Apron_Quantity__c = mc_infos.prod_apron_quant;
                    l.OM_Apron_Price__c = mc_infos.prod_apron_price;
                    l.OM_Delivery_Interval_Bed_protection__c = mc_infos.deliv_interval_pg51;
                    l.OM_Reusable_Bed_Protection_Quantity__c = mc_infos.prod_reuse_bed_prot_quant;
                    l.OM_reusable_Bed_Protection_Price__c = mc_infos.prod_reuse_bed_prot_price;
                    l.OM_Price_pg54__c = mc_infos.price_pg54;
                    l.OM_Price_pg51__c = mc_infos.price_pg51;
                }
            } catch (Exception e) {
                System.debug(e);
            }
        }
        try {
            insert l;
        }
        catch (System.Exception e) {
            system.debug('#########################error ' + e);
        }

        if((l.id != null) && (pdf_form != null)) {
            ContentVersion attach = new ContentVersion();
            blob atbody ;
            atbody = System.EncodingUtil.base64Decode(pdf_form.file);
            attach.VersionData = atbody;
            attach.Title = pdf_form.file_name;
            attach.PathOnClient = pdf_form.file_name + '.pdf';
            //attach.IsPrivate = false;
            attach.FirstPublishLocationId = l.Id;
            attach.ContentLocation = 'S';
            insert attach;
        }
        if((l.id != null) && (antrag_1 != null)) {
            ContentVersion attach = new ContentVersion();
            blob atbody ;
            atbody = System.EncodingUtil.base64Decode(antrag_1.file);
            attach.VersionData = atbody;
            attach.Title = antrag_1.file_name;
            attach.PathOnClient = antrag_1.file_name + '.pdf';
            //attach.IsPrivate = false;
            attach.FirstPublishLocationId = l.Id;
            attach.ContentLocation = 'S';
            insert attach;
        }
        if((l.id != null) && (antrag_2 != null)) {
            ContentVersion attach = new ContentVersion();
            blob atbody ;
            atbody = System.EncodingUtil.base64Decode(antrag_2.file);
            attach.VersionData = atbody;
            attach.Title = antrag_2.file_name;
            attach.PathOnClient = antrag_2.file_name + '.pdf';
            //attach.IsPrivate = false;
            attach.FirstPublishLocationId = l.Id;
            attach.ContentLocation = 'S';
            insert attach;
        }

        system.debug('#########################alex000 ' + box.box);

        return 'OK';
    }

    global class marketing {
        global String created_at {get;set;}
        global String Order_ID {get;set;}
        global String wizard_name {get;set;}
        global String wizard_version {get;set;}
        global String Partner_ID {get;set;}
        global String referrer {get;set;}
    }

    global class Box {
        global String box {get;set;}
        global String glove_size {get;set;}
        global String bed_protection_underlays {get;set;}
        global String delivery_address {get;set;}
    }

    global class Insured_person {
        global String ip_fname {get;set;}
        global String ip_lname {get;set;}
        global String ip_email {get;set;}
        global String ip_salutation {get;set;}
        global String ip_zipcode {get;set;}
        global String ip_city {get;set;}
        global String ip_phone {get;set;}
        global String ip_born_at {get;set;}
        global String ip_care_level {get;set;}
        global String ip_care_rank {get;set;}
        global String ip_insurance_number {get;set;}
        global String ip_street_nr {get;set;}
        global String ip_identitynumber_carrier_a {get;set;}
        global String ip_identitynumber_carrier_b {get;set;}
    }

    global class care_person {
        global String cp_fname {get;set;}
        global String cp_lname {get;set;}
        global String cp_zipcode {get;set;}
        global String cp_city {get;set;}
        global String cp_email {get;set;}
        global String cp_phone {get;set;}
        global String cp_authorized {get;set;}
        global String cp_salutation {get;set;}
        global String cp_street_nr {get;set;}
    }


    global class care_service {
        global String cs_name {get;set;}
        global String cs_zipcode {get;set;}
        global String cs_city {get;set;}
        global String cs_street_nr {get;set;}
    }

    global class pdf_form {
        global String file_name {get;set;}
        global String content_type {get;set;}
        global Integer file_size {get;set;}
        global String file {get;set;}
    }
    global class Antrag_1 {
        global String file_name {get;set;}
        global String content_type {get;set;}
        global Integer file_size {get;set;}
        global String file {get;set;}
    }
    global class Antrag_2 {
        global String file_name {get;set;}
        global String content_type {get;set;}
        global Integer file_size {get;set;}
        global String file {get;set;}
    }
    global class mc_infos {
        global string salutation {get;set;}
        global string lastname {get;set;}
        global string email {get;set;}
        global string visitorid {get;set;}
        global string visitid {get;set;}
        global string code {get;set;}
        global string orderid {get;set;}
        global string digital_signature {get;set;}
        global string billing_addr_name {get;set;}
        global string billing_addr_street {get;set;}
        global string billing_addr_zip {get;set;}
        global string billing_addr_city {get;set;}
        global string deliv_addr_name {get;set;}
        global string deliv_addr_street {get;set;}
        global string deliv_addr_zip {get;set;}
        global string deliv_addr_city {get;set;}
        global string deliv_interval_pg54 {get;set;}
        global string prod_bed_prot_quant {get;set;}
        global string prod_bed_prot_price {get;set;}
        global string prod_gloves_quant {get;set;}
        global string prod_gloves_price {get;set;}
        global string prod_hand_dis_quant {get;set;}
        global string prod_hand_dis_price {get;set;}
        global string prod_surface_dis_quant {get;set;}
        global string prod_surface_dis_price {get;set;}
        global string prod_masks_quant {get;set;}
        global string prod_masks_price {get;set;}
        global string prod_ffp2_masks_quant {get;set;}
        global string prod_ffp2_masks_price {get;set;}
        global string prod_apron_quant {get;set;}
        global string prod_apron_price {get;set;}
        global string deliv_interval_pg51 {get;set;}
        global string prod_reuse_bed_prot_quant {get;set;}
        global string prod_reuse_bed_prot_price {get;set;}
        global string price_pg54 {get;set;}
        global string price_pg51 {get;set;}
    }

}