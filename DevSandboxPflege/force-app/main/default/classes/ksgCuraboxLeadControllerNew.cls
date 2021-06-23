//****************************************************************************************************************************
// Erstellt 02.11.2020 von PK
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
//02.11.2020    PK New fields - Wizard v20
//****************************************************************************************************************************
@RestResource(urlMapping = '/curabox/lead/*')
global class ksgCuraboxLeadControllerNew {

    @HttpPost
    global static string createNewLead(string next_step,
                                       marketing marketing,
                                       Box box,
                                       packing_station packing_station,
                                       Insured_person insured_person,
                                       care_person care_person,
                                       care_service care_service,
                                       pdf_form pdf_form,
                                       antrag_1 Antrag_1,
                                       antrag_2 Antrag_2,
                                       Empfangsvollmacht empfangsvollmacht,
                                       Wechselerklaerung wechselerklaerung,
                                       mc_infos mc_infos) {

        id rtid = null;
        id ownid = UserInfo.getUserId();
        list<RecordType> rtList = [SELECT Id FROM RecordType WHERE sObjectType='lead' AND Name= 'Curabox'];
        if ((rtList != null) && (rtList.size() > 0)) {
            rtId = rtList[0].id;
        }

        list<user> usList = [SELECT id FROM user WHERE name = 'IT Support'];
        if ((usList != null) && (usList.size() > 0)) {
            ownid = usList[0].id;
        }

        lead l = new lead(Company = 'curabox', Status = 'Open');
        l.RecordTypeId = rtid;
        l.OwnerID = ownid;
        l.PDF_Bestellformular__c = false;
        l.PDF_Antrag_Kostenuebernahme__c = false;
        l.PDF_Empfaengnisvollmacht__c = false;
        l.PDF_Wechselerklaerung__c = false;

        l.next_Step__c = next_step;
        if (box != null) {
            try {
                l.CB_Box__c = box.box;
                l.CB_Handschuh_Groesse__c = box.glove_size;
                l.CB_Lieferung__c = box.delivery_address;
                // = box.bed_protection_underlays;


                // 13.10.2020
                l.Einmalhandschuhe_quantity__c = box.glove_amount;
                l.Haendedesinfektion_quantity__c = box.hand_disinfection_amount;
                l.Flaechendesinfektion_quantity__c = box.area_disinfection_amount;
                l.Bettschutzeinlagen_quantity__c = box.bed_protection_underlays_amount;
                l.Delivery_interval_bettschutzeinlagen__c = box.bed_protection_underlays_delivery_interval;
                l.Mundschutz_quantity__c = box.mouth_protection_amount;
                l.Schutzschuerzen_quantity__c = box.protective_apron_amount;
                l.Waschbare_Bettschutzeinlagen_quantity__c = box.washable_bed_underlays_amount;
                l.FFP2_Maske_quantity__c = box.mouth_protection_ffp2_amount;
                l.Delivery_interval__c = box.delivery_interval;
                l.Supplier_change__c = box.supplier_change;
                l.Supplier_change_startdate__c = box.supplier_change_date;
                l.Vinyl_Allergy__c = box.vinyl_allergy;
                l.Nitril_Allergy__c = box.nitril_allergy;
                l.Latex_Allergy__c = box.latex_allergy;
            } catch (System.Exception e) {
            }
        }
        if (care_service != null) {
            try {
                l.CB_Pflegedienst_Name__c = care_service.cs_name;
                l.CB_Pflegedienst_PLZ__c = care_service.cs_zipcode;
                l.CB_Pflegedienst_Ort__c = care_service.cs_city;
                l.CB_Pflegedienst_Strasse__c = care_service.cs_street_nr;
            } catch (System.Exception e) {
            }
        }
        if (Insured_person != null) {
            try {
                l.LastName = Insured_person.ip_lname;
                l.FirstName = Insured_person.ip_fname;
                l.Salutation = Insured_person.ip_salutation;
                l.Email = Insured_person.ip_email;
                l.Street = Insured_person.ip_street_nr;
                l.PostalCode = Insured_person.ip_zipcode;
                l.City = Insured_person.ip_city;
                l.Phone = Insured_person.ip_phone;
                l.MobilePhone = insured_person.ip_mobile;
                l.Geburtsdatum__c = Insured_person.ip_born_at;
                l.Pflegestufe__c = Insured_person.ip_care_level;
                l.Pflegegrad__c = Insured_person.ip_care_rank;
                l.Pflegegrad_seit__c = Insured_person.ip_care_rank_since;
                l.Versicherungsnummer__c = Insured_person.ip_insurance_number;
                l.IK_Nummer_des_traegers__c = Insured_person.ip_identitynumber_carrier_a;
                l.Kostentr_ger__c = Insured_person.ip_identitynumber_carrier_b;
                //DZ 14.10
                List<Account> acclist = [select id, name from Account where name =: Insured_person.ip_identitynumber_carrier_b LIMIT 1];
                    if (acclist != null && acclist.size() != 0) l.krankenkasse__c  = acclist[0].Id;
            } catch (System.Exception e) {
                return 'Error: ' + e;
            }
        }
        if (care_person != null) {
            try {
                l.Angehoeriger_Anrede__c = care_person.cp_salutation ;
                l.Angehoeriger_Vorname__c = care_person.cp_fname;
                l.Angehoeriger_Nachname__c = care_person.cp_lname;
                l.Angehoeriger_Email__c = care_person.cp_email;
                l.Angehoeriger_Telefon__c = care_person.cp_phone;
                l.Angehoeriger_Vollmacht__c = care_person.cp_authorized;
                l.Angehoeriger_Strasse__c = care_person.cp_street_nr;
                l.Angehoeriger_PLZ__c = care_person.cp_zipcode;
                l.Angehoeriger_Ort__c = care_person.cp_city;
                l.Angeh_riger_Mobile__c = care_person.cp_mobile;
            } catch (System.Exception e) {
                return 'Error: ' + e;
            }
        }
        // 13.10.2020
        if (packing_station != null) {
            try {
                l.Packstation_FirstName__c = packing_station.ps_fname;
                l.Packstation_LastName__c = packing_station.ps_lname;
                l.Packstation_Postnumber__c = packing_station.ps_post_number;
                l.Packstation_Number_DHLstation__c = packing_station.ps_dhl_number;
                l.Packstation_Postalcode__c = packing_station.ps_zipcode;
                l.Packstation_City__c = packing_station.ps_city;

            } catch (System.Exception e) {
                return 'Error: ' + e;
            }
        }
        if (Marketing != null) {
            try {
                l.OM_created_at__c = Marketing.created_at;
                l.OM_Tracking_Order_ID__c = Marketing.Order_ID;
                l.OM_Wizard_Version__c = Marketing.wizard_version;
                l.OM_Partner_ID__c = Marketing.Partner_ID;
                l.OM_Referrer__c = Marketing.referrer;
                List<Campaign> cmplist = [select id, name from Campaign where name =: Marketing.wizard_name LIMIT 1];
                if (cmplist != null && cmplist.size() != 0) l.OM_Wizzard_Name2__c = cmplist[0].Id;
            } catch (System.Exception e) {
            }
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
        } catch (System.Exception e) {
            system.debug('#########################error ' + e);
        }

        if ((l.id != null) && (pdf_form != null)) {
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
        if ((l.id != null) && (antrag_1 != null)) {
            l.PDF_Bestellformular__c = true;
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
        if ((l.id != null) && (antrag_2 != null)) {
            l.PDF_Antrag_Kostenuebernahme__c = true;
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
        if ((l.id != null) && (empfangsvollmacht != null)) {
            l.PDF_Empfaengnisvollmacht__c = true;
            ContentVersion attach = new ContentVersion();
            blob atbody ;
            atbody = System.EncodingUtil.base64Decode(empfangsvollmacht.file);
            attach.VersionData = atbody;
            attach.Title = empfangsvollmacht.file_name;
            attach.PathOnClient = empfangsvollmacht.file_name + '.pdf';
            //attach.IsPrivate = false;
            attach.FirstPublishLocationId = l.Id;
            attach.ContentLocation = 'S';
            insert attach;
        }
        if ((l.id != null) && (wechselerklaerung != null)) {
            l.PDF_Wechselerklaerung__c = true;
            ContentVersion attach = new ContentVersion();
            blob atbody ;
            atbody = System.EncodingUtil.base64Decode(wechselerklaerung.file);
            attach.VersionData = atbody;
            attach.Title = wechselerklaerung.file_name;
            attach.PathOnClient = wechselerklaerung.file_name + '.pdf';
            //attach.IsPrivate = false;
            attach.FirstPublishLocationId = l.Id;
            attach.ContentLocation = 'S';
            insert attach;
        }
        update l;
        system.debug('#########################alex000 ' + box.box);

        return 'OK';
    }

    global class marketing {
        global String created_at {
            get;set;
        }
        global String Order_ID {
            get;set;
        }
        global String wizard_name {
            get;set;
        }
        global String wizard_version {
            get;set;
        }
        global String Partner_ID {
            get;set;
        }
        global String referrer {
            get;set;
        }
    }

    global class Box {
        global String box {
            get;set;
        }
        global String glove_size {
            get;set;
        }
        global String bed_protection_underlays {
            get;set;
        }
        global String delivery_address {
            get;set;
        }
        // 13.10.2020
        global Decimal glove_amount {
            get;set;
        }
        global Decimal hand_disinfection_amount {
            get;set;
        }
        global Decimal area_disinfection_amount {
            get;set;
        }
        global Decimal bed_protection_underlays_amount {
            get;set;
        }
        global Decimal mouth_protection_amount {
            get;set;
        }
        global Decimal protective_apron_amount {
            get;set;
        }
        global Decimal washable_bed_underlays_amount {
            get;set;
        }
        
        global Decimal mouth_protection_ffp2_amount {
            get;set;
        }
        global String bed_protection_underlays_delivery_interval {
            get;set;
        }
        global String delivery_interval {
            get;set;
        }
        global Boolean supplier_change {
            get;set;
        }
        global Date supplier_change_date {
            get;set;
        }
        global Boolean vinyl_allergy {
            get;set;
        }
        global Boolean nitril_allergy {
            get;set;
        }
        global Boolean latex_allergy {
            get;set;
        }

    }

    global class Insured_person {
        global String ip_fname {
            get;set;
        }
        global String ip_lname {
            get;set;
        }
        global String ip_email {
            get;set;
        }
        global String ip_salutation {
            get;set;
        }
        global String ip_zipcode {
            get;set;
        }
        global String ip_city {
            get;set;
        }
        global String ip_phone {
            get;set;
        }
        global String ip_mobile {
            get;set;
        }
        global String ip_born_at {
            get;set;
        }
        global String ip_care_level {
            get;set;
        }
        global String ip_care_rank {
            get;set;
        }
        global String ip_care_rank_since {
            get;set;
        }
        global String ip_insurance_number {
            get;set;
        }
        global String ip_street_nr {
            get;set;
        }
        global String ip_identitynumber_carrier_a {
            get;set;
        }
        global String ip_identitynumber_carrier_b {
            get;set;
        }
    }

    global class care_person {
        global String cp_fname {
            get;set;
        }
        global String cp_lname {
            get;set;
        }
        global String cp_zipcode {
            get;set;
        }
        global String cp_city {
            get;set;
        }
        global String cp_email {
            get;set;
        }
        global String cp_phone {
            get;set;
        }
        global String cp_authorized {
            get;set;
        }
        global String cp_salutation {
            get;set;
        }
        global String cp_street_nr {
            get;set;
        }
        global String cp_mobile {
            get;set;
        }
    }

    global class packing_station {
        global String ps_fname {
            get;set;
        }
        global String ps_lname {
            get;set;
        }
        global String ps_post_number {
            get;set;
        }
        global String ps_dhl_number {
            get;set;
        }
        global String ps_zipcode {
            get;set;
        }
        global String ps_city {
            get;set;
        }

    }

    global class care_service {
        global String cs_name {
            get;set;
        }
        global String cs_zipcode {
            get;set;
        }
        global String cs_city {
            get;set;
        }
        global String cs_street_nr {
            get;set;
        }
    }

    global class pdf_form {
        global String file_name {
            get;set;
        }
        global String content_type {
            get;set;
        }
        global Integer file_size {
            get;set;
        }
        global String file {
            get;set;
        }
    }

    global class Antrag_1 {
        global String file_name {
            get;set;
        }
        global String content_type {
            get;set;
        }
        global Integer file_size {
            get;set;
        }
        global String file {
            get;set;
        }
    }

    global class Antrag_2 {
        global String file_name {
            get;set;
        }
        global String content_type {
            get;set;
        }
        global Integer file_size {
            get;set;
        }
        global String file {
            get;set;
        }
    }

    global class Empfangsvollmacht {
        global String file_name {
            get;set;
        }
        global String content_type {
            get;set;
        }
        global Integer file_size {
            get;set;
        }
        global String file {
            get;set;
        }
    }

    global class Wechselerklaerung {
        global String file_name {
            get;set;
        }
        global String content_type {
            get;set;
        }
        global Integer file_size {
            get;set;
        }
        global String file {
            get;set;
        }
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