/****************************************************************************************************************************
// Erstellt 17.12.2019 von AM
//                         Klose und Srocke Gesellschaft für kreative Konfliktlösungen mbH
//                         Frankenstr. 29
//                         20097 Hamburg 
//                         Tel.:  04023882986
//                         Fax.: 04023882989
//                         Email: kontakt@klosesrockepartner.de
//
//****************************************************************************************************************************
//
// Parameter: 
//
//****************************************************************************************************************************
//
// Beschreibung: Helper. iterate csv string
//      Achtung! String.split(';') funktioniert nicht sauber. Besser for-loop für Splitting csv-row.
//  Beispiel batch:
//          public string CRLF = '\r\n';
//
//          public iterable<string>  start(Database.BatchableContext BC) {
//              return new CSVIterator(attachment_body.toString(), CRLF);
//          }  
//          
//          public void execute(Database.BatchableContext BC, List<String> csv_lines) {
//              list<string[]> csvTab = new list<string[]>();
//              for(string row : csv_lines) {
//                  string[] csvline = new string[50];
//                  integer cc = 0;
//                  integer si = 0;
//                  integer ci = line.indexOf(';');
//                  while((ci >= 0) && (cc < 50)) { 
//                      csvline[cc] = line.substring(si, ci);
//                      si = ci+1;
//                      ci = line.indexOf(';', si);
//                      cc++;
//                      if(line.length() > si) {
//                          csvline[cc] = line.substring(si);
//                      }
//                  }
//                  csvTab.add(csvline);                    
//              }
//              for(string[] csvline : csvTab) {
//                  ...
//              }          
//          }
//    
//****************************************************************************************************************************
//  Änderungen
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
*/
global with sharing class CSVIterator implements Iterator<string>, Iterable<string>
{
    private String m_CSVData;
    private String CRLF;
    public CSVIterator(String fileData, String introValue)
    {
        m_CSVData = fileData;
        CRLF = introValue;
    }
    global Boolean hasNext()
    {
        return m_CSVData.length() > 1 ? true : false;
    }
    global String next()
    {
        String row = '';
        try { 
                row = m_CSVData.subString(0, m_CSVData.indexOf(CRLF));
                m_CSVData = m_CSVData.subString(m_CSVData.indexOf(CRLF) + CRLF.length(), m_CSVData.length());
            } 
        catch (System.Exception e) {}
        return row;
    }
    global Iterator<string> Iterator()
    {
        return this;
    }
}