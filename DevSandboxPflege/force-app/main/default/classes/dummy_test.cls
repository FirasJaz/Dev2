@isTest
private class dummy_test {

    static testMethod void myUnitTest() {
        Lieferscheinupdateunterschrift.setLeereZeilen();
        Preislisteneintrag.setLeereZeilen();
        Update_PZN_suche_class.setLeereZeilen();
        // Statusverwaltung_Kunde_class.setLeereZeilen();
        
        shippingcode_senden testclass = new shippingcode_senden();
        testclass.setLeereZeilen();
        
        LS_CSV_versenden LS_CSV_versenden_cl = new LS_CSV_versenden();
        LS_CSV_versenden_cl.setLeereZeilen();
        
        LS_XML_generieren LS_XML_generieren_cl = new LS_XML_generieren();
        LS_XML_generieren_cl.setLeereZeilen();
        
        LS_XML_generieren_batch LS_XML_generieren_batch_cl = new LS_XML_generieren_batch('test');
        LS_XML_generieren_batch_cl.setLeereZeilen();
        
        LS_XML_nachbearbeiten_batch LS_XML_nachbearbeiten_batch_cl = new LS_XML_nachbearbeiten_batch();
        LS_XML_nachbearbeiten_batch_cl.setLeereZeilen();
        
        LS_erzeugen LS_erzeugen_c = new LS_erzeugen();
        //LS_erzeugen_c.setLeereZeilen();
        
        LS_generieren LS_generieren_c = new LS_generieren();
        LS_generieren_c.setLeereZeilen();
        
        LS_generieren_mnt LS_generieren_mnt_c = new LS_generieren_mnt();
        LS_generieren_mnt_c.setLeereZeilen();
        
        //Auftragsverwaltung Auftragsverwaltung_c = new Auftragsverwaltung();
        //Auftragsverwaltung_c.setLeereZeilen();
        
        //Bedarfsmeldung Bedarfsmeldung_c= new Bedarfsmeldung();
        //Bedarfsmeldung_c.setLeereZeilen();
        
        //Bedarfsmeldung_aufruf Bedarfsmeldung_aufruf_c = new Bedarfsmeldung_aufruf();
        //Bedarfsmeldung_aufruf_c.setLeereZeilen();
        
        string dummy = 'dummy';
        //Bedarfsmeldung_method Bedarfsmeldung_method = new Bedarfsmeldung_method(dummy);
        //Bedarfsmeldung_method.setLeereZeilen();
        
        box_auftrag box_auftrag_c = new box_auftrag ();
        box_auftrag_c.setLeereZeilen();
        
        inko_auftrag inko_auftrag_c = new inko_auftrag ();
        inko_auftrag_c.setLeereZeilen();
        
        //box_method box_method_c = new box_method(dummy);
        //box_method_c.setLeereZeilen();
        
        inko_method inko_method_c = new inko_method();
        inko_method_c.setLeereZeilen();
        
        //Brief_schreiben_controller_class Brief_schreiben_controller_class_c = new Brief_schreiben_controller_class();
        //Brief_schreiben_controller_class_c.setLeereZeilen();
        
        //Brief_schreiben_adresse Brief_schreiben_adresse_c = new Brief_schreiben_adresse();
        //Brief_schreiben_adresse_c.setLeereZeilen();
        
        //Formular_versenden Formular_versenden_c = new Formular_versenden();
        //Formular_versenden_c.setLeereZeilen();
        
        //sendenFaxAusKunde sendenFaxAusKunde_c = new sendenFaxAusKunde();
        //sendenFaxAusKunde_c.setLeereZeilen();
        
        neuePBGenehmigungController neuePBGenehmigungController_c = new neuePBGenehmigungController();
        neuePBGenehmigungController_c.setLeereZeilen();
        
        integer di = 0;
        RA_nur_anzeigen_ent_controller_class RA_nur_anzeigen_ent_controller_class_c = new RA_nur_anzeigen_ent_controller_class(di);
        //RA_nur_anzeigen_ent_controller_class_c.setLeereZeilen();
        
        RA_nur_anzeigen_sto_controller_class RA_nur_anzeigen_sto_controller_class_c = new RA_nur_anzeigen_sto_controller_class(di);
        RA_nur_anzeigen_sto_controller_class_c.setLeereZeilen();
        
        delivery_tracking delivery_tracking_c = new delivery_tracking();
        delivery_tracking_c.setLeereZeilen();
        
        AB_KK_nur_anzeigen_controller_class AB_KK_nur_anzeigen_controller_class_c = new AB_KK_nur_anzeigen_controller_class();
        AB_KK_nur_anzeigen_controller_class_c.setLeereZeilen();
        
        //shippingcode_senden scs = new shippingcode_senden(dummy);
        //scs.setLeereZeilen();
        
        sendefaxanPHAG_pdf sfph_pdf = new sendefaxanPHAG_pdf(di);
        sfph_pdf.setLeereZeilen();
        
        sendefaxanPHAG_pdf_Auswahl phpdf2 = new sendefaxanPHAG_pdf_Auswahl();
        phpdf2.setLeereZeilen();
        
        sendefaxanPHAG_pdf_mR pdfmr = new sendefaxanPHAG_pdf_mR(di);
        pdfmr.setLeereZeilen();
        
        sendefaxanPHAG_pdf_oR pdfor = new sendefaxanPHAG_pdf_oR(di);
        pdfor.setLeereZeilen();
        
        ID batchprocessid = Database.executeBatch(new Lieferungen_ausloesen());
        String CRON_EXP = '0 0 0 3 9 ? 2022';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP,  new Lieferungen_ausloesen_start());

        ID batchprocessid2 = Database.executeBatch(new shippingcode_pruefen());
        String jobId2 = System.schedule('testScheduledApex', CRON_EXP,  new shippingcode_pruefen_start());  
        
        
              
        
    }   
}