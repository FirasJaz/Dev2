/*/****************************************************************************************************************************
// Erstellt 06.04.2021 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frohmestr. 49
//                         22457 Hamburg 
//                         Tel.:  04064917161
//                         Fax.: 04064917162
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: keine
//            
//
//****************************************************************************************************************************
//
// Beschreibung:
//         Aufruf limitInfo.limitImage(limitInfo.getCurrentClassMethod());             
//  
//  
//
//****************************************************************************************************************************
//Änderungen:       
//****************************************************************************************************************************
*/
public with sharing class limitInfo {
    public static void limitImage(String jobMethod) {
        appLimitInformation__c li = new appLimitInformation__c(Class_Method__c = jobMethod);
        li.Maximum_CPU_time__c = String.valueOf(Limits.getCpuTime()) + ' out of ' + String.valueOf(Limits.getLimitCpuTime());
        li.Maximum_heap_size__c = String.valueOf(Limits.getHeapSize()) + ' out of ' + String.valueOf(Limits.getLimitHeapSize());
        li.Number_of_DML_rows__c = String.valueOf(Limits.getDMLRows()) + ' out of ' + String.valueOf(Limits.getLimitDMLRows());
        li.Number_of_DML_statements__c = String.valueOf(Limits.getDMLStatements()) + ' out of ' + String.valueOf(Limits.getLimitDMLStatements());
        li.Number_of_query_rows__c = String.valueOf(Limits.getQueryRows()) + ' out of ' + String.valueOf(Limits.getLimitQueryRows());
        li.Number_of_SOQL_queries__c = String.valueOf(Limits.getQueries()) + ' out of ' + String.valueOf(Limits.getLimitQueries());
        Database.insert(li, false);
    }

    public static String getCurrentClassMethod()
    {
        return new DmlException().getStackTraceString().substringAfter('\n');
    }
}