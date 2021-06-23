public class Parameterlesenclass
{
	private static Map<String,Parameter__c> Parameters = 
	new Map<String,Parameter__c>{};
	
    private static Boolean parameterlesen (String Str) 
    {
    	Boolean ok = True; 
    	Try
    	{
			system.debug ('##################### Suche Parameter : ' + Str);	
			Parameter__c param = [Select Name, Text__c, Wert__c 
					from Parameter__c Where Name = :Str];
			if(param!=null){
				Parameters.put(Str,param);
			}
       	}
		catch (system.Queryexception q)
		{
			system.debug ('##################### keinen solchen Parameter gefunden! ' + Str);	
			ok = false;
		}
		return ok;
    }

	public static string read_string_param (String param_name)
	{
		system.debug ('##################### Suche Parameter : ' + param_name);	
		If (Param_name != null && !Parameters.containsKey(param_name) )
		{	
			parameterlesen(param_name);
		}
		return (Parameters.get(param_name)==null)?''
		:Parameters.get(param_name).Wert__c;
	}    

	public static decimal read_decimal_param (String param_name)
	{
		system.debug ('##################### Suche Parameter : ' + param_name);	
		If (Param_name != null && !Parameters.containsKey(param_name) )
		{	
			parameterlesen(param_name);
		}
		return (Parameters.get(param_name)==null)?0
		:decimal.valueof(Parameters.get(param_name).Wert__c);
	}

	public static string read_name_of_param (String param_name)	
	{
		system.debug ('##################### Suche Parameter : ' + param_name);	
		If (Param_name != null && !Parameters.containsKey(param_name) )
		{	
			parameterlesen(param_name);
		}
		return (Parameters.get(param_name)==null)?''
		:Parameters.get(param_name).Text__c;
	}
}