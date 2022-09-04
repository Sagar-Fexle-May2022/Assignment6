/**
* Description   - Contact Trigger Handler
* Created by    - Sagar Nirwal
* Created Date  - 028/08/2022
* Revision log  -  V_1.0 - Created  - Sagar Nirwal - 28/08/2022
*                  V_1.1 - Modified - Sagar NIrwal - 28/08/2022 -  Details what you modified
**/
public with sharing class ContactTriggerHandler {
    /**   Description :   Method synchronize Record
    *     Created By  :   Sagar Nirwal
    *     Arguments   :   List<State__c>,List<State__c>
    *     Return      :   void
    *     Revision log:   V_1.0 - Created  - Sagar Nirwal - 28/08/2022
    *                     V_1.1 - Modified - Sagar Nirwal - 28/08/2022 - Details what you modified
    **/
    public static void synchronizeContactAccountPropertyRecord(List<Contact> newList) {
        Set<id> accountIdSet = new Set<id>();
        for(Contact con: newList){
            if(con.Status__c == null){
                accountIdSet.add(con.AccountId);   
                System.debug(accountIdSet);
            }
        } 
        Map<Id,Account> accMap = new Map<Id,Account>([SELECT Id,Status__c,Property__c,Property__r.Status__c,Property__r.Name 
                                                    FROM Account WHERE id IN: accountIdSet]);
        System.debug(accMap);                                                            
        for(Contact con: newList){
            Account acc = accMap.get(con.AccountId);
            if(acc.Status__c != null){
                con.Status__c = acc.Status__c; 
            }
            else if(acc.Property__r.Status__c!=null){
                con.Status__c = acc.Property__r.Status__c;
            }
        }
    }
}