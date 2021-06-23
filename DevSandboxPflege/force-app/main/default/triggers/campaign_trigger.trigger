//****************************************************************************************************************************
// Created 10.07.2018      by AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Nordkanalstraße 58
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.:  04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Description:
//                      
// The trigger will set the field Name_Index__c like this: 
//      cb_(Index_of_campaig_type).(number_of_campaigns_from_this_type)
//
// Case 00001596 (##158556019)
//****************************************************************************************************************************
// Test: 
//****************************************************************************************************************************
// Changes:
//****************************************************************************************************************************

trigger campaign_trigger on campaign (before insert){
    map<string, string> mainGroupMap = new map<string, string>();
    map<string, integer> secondGroupMap = new map<string, integer>();
    Schema.DescribeFieldResult fieldResult = campaign.type.getDescribe();
    List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
    integer ind = 1;
    for( Schema.PicklistEntry f : ple)
    {
        mainGroupMap.put(f.getValue(), string.valueOf(ind));
        // system.debug('#########' + string.valueOf(ind) + '=' + f.getLabel() + ' val=' + f.getValue());
        ind++;
    }       

    list<AggregateResult> secontList = [select count(id) cnt, type from campaign where type != null group by type order by type];
    if((secontList != null) && (secontList.size() > 0)) {
        for(AggregateResult ar : secontList) {
            secondGroupMap.put((string)ar.get('type'), (integer)ar.get('cnt'));    
            // system.debug('#########' + ar.get('type') + '=' + ar.get('cnt'));
        }
    }

    // OK 
    integer index = 0;
    for(campaign cmp: Trigger.new) {
        if(mainGroupMap.containsKey(cmp.type)) {
            cmp.Name_Index__c = 'cb_' + mainGroupMap.get(cmp.type) + '.';
            if(secondGroupMap.containsKey(cmp.type)) {
                index = secondGroupMap.get(cmp.type);
                index++;              
            }
            else {
                index = 1;          
            }
            cmp.Name_Index__c += string.valueOf(index);
            secondGroupMap.put(cmp.type, index);    
        }
    }
}