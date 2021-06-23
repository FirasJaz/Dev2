/****************************************************************************************************************************
// Created 09.05.2019 von  AD
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstr. 58
//                         20097 Hamburg 
//                         Tel.: 04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//
//****************************************************************************************************************************
//
// Description:       
//
//
//****************************************************************************************************************************
// Changes:
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/

public with sharing class Create_Genehmigung_Positionen {
    
    // Initialisieren des Genehmigungsposition Objekts
    public static Curabox_Genehmigungsposition__c newPosition(Curabox_Genehmigung__c genehmigung, Product_Group__c productGroup){
        Curabox_Genehmigungsposition__c position = new Curabox_Genehmigungsposition__c();
        position.Genehmigung__c = genehmigung.Id;
        position.Product_Group__c = productGroup.Id;
        position.Ant_Menge_Stk__c = 10;
        return position;
    }

    public static List<Curabox_Genehmigungsposition__c> createPositions(Curabox_Genehmigung__c genehmigung, List<Product_Group__c> productGroupList){
        List<Curabox_Genehmigungsposition__c> gPositionList = new List<Curabox_Genehmigungsposition__c>();
        if (productGroupList != null && productGroupList.size() >0) {
            for (Product_Group__c pg : productGroupList) {
                gPositionList.add(newPosition(genehmigung, pg));
            }
        }
        return gPositionList;
    }

}