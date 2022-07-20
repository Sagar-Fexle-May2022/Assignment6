/**
* Description   - Dynamic Map of Country   
* Created by    - Sagar Nirwal
* Created Date  - 14/06/2022
* Revision log  -  V_1.0 - Created  - Sagar Nirwal - 14/06/2022
*                  V_1.1 - Modified - Sagar NIrwal - 14/06/2022 -  Details what you modified
**/
public with sharing class DynamicMapOfCountry {
    Static String JSONData;
    
    //Nested Map using Country with code to get the value countries,states,cites name 
    Static Map<String, Map<String, Map<String, List<String>>>> codeMap = 
                                                                    new Map<String, Map<String, Map<String, List<String>>>>();
    //Nested Map of Country using to get the states and District name
    Static Map<String, Map<String, List<String>>> countryMap =  new  Map<String, Map<String, List<String>>>();  
    Static Map<String ,List<String>> stateMap = new Map<String ,List<String>>();
    
    Static Decimal totalState;// Variable for Storing Total State for Wrapper Class
    Static Decimal totalDistrict;// Variable for Storing Total District for Wrapper Class

    /**   Description :   Constructor using Nested Map print all country 
    *     Created By  :   Sagar Nirwal
    *     Arguments   :   String,String,Integer
    *     Return      :   void
    *     Revision log:   V_1.0 - Created  - Sagar Nirwal - 14/06/2022
    *                     V_1.1 - Modified - Sagar Nirwal - 14/06/2022 - In Map Reduce the no of SOQL Qurey
                                                                        and Implement in a Single Qurey 
    **/
    public DynamicMapOfCountry(String countryCode,String startLetter,String name) {
        
        //this qurey working Parent(Country) to child(State) and child(District) to Parent(State) 
        List<State__c>  listofState = [SELECT Id,country__r.Country_Code__c,country__r.Name,Name,
                                            (SELECT state__r.Name,Name FROM Districts__r ) 
                                        FROM State__c 
                                        WHERE country__r.Country_Code__c = :countryCode];
        for(State__c state :listofState) {
            if(countryMap.size() == 0){
                codeMap.put(state.country__r.Country_Code__c,new Map<String, Map<String, List<String>>>());
                countryMap.put(state.country__r.Name,new Map<String, List<String>>());
            }
            stateMap.put(state.Name, new List<String>());
            for(District__c district : state.Districts__r){
                stateMap.get(district.state__r.Name).add(district.Name);
            }
        }
        countryMap.get(listofState[0].country__r.Name).putAll(stateMap);
        codeMap.get(listofState[0].country__r.Country_Code__c).putAll(countryMap);
        
        System.debug(codeMap.get(countryCode));
        
        List<String> listOfCombinations = new List<String>();
        for(String countryName : countryMap.keySet()){
            for(String stateName : countryMap.get(countryName).keySet()){
               	for(String districtName : countryMap.get(countryName).get(stateName) ){
                	if(countryName.startsWith(startLetter) && stateName.startswith(startLetter)
                       && districtName.startsWith(startLetter) ){
                        listOfCombinations.add(countryName+','+stateName+ ','+districtName);
                    }
             	}  	  
            }
        }
        if(!listOfCombinations.isEmpty()){
            System.debug('Combination of Country, State and District:'+listOfCombinations);
        }
        aggregateQurey();
        countryData(name);
    }

    /**   Description :   Method Update the Field of Country by using Aggregate Qurey  
    *     Created By  :   Sagar Nirwal
    *     Arguments   :   none
    *     Return      :   void
    *     Revision log:   V_1.0 - Created  - Sagar Nirwal - 14/06/2022
    *                     V_1.1 - Modified - Sagar Nirwal - 14/06/2022 - Aggregate Qurey
    **/
    public static void aggregateQurey(){

        //Aggregate Qurey------> Total District Of State   
        Map<Id, State__c> mapOfTotalDistricts = new Map<Id, State__c>();                                       
        for(AggregateResult aggre : [SELECT  State__c state, COUNT(Name) 
                                                      FROM District__c 
                                                      GROUP BY State__c]){
            mapOfTotalDistricts.put(String.valueOf(aggre.get('state')),new State__c(Id = (Id)aggre.get('state'),
                Total_District__c = (Decimal)aggre.get('expr0')));
        }
        if(!mapOfTotalDistricts.isEmpty()){
            update mapOfTotalDistricts.values();
        }
        //Aggregate Qurey------> Total Sate AND District Of Country
        Map<Id, Country__c> mapOfCountryField = new Map<Id, Country__c>();
        for (AggregateResult agg : [SELECT Country__c coun, COUNT(Name), SUM(Total_District__c)
                                                               FROM State__c 
                                                               GROUP BY Country__c]){   
            
            totalState = (Decimal)agg.get('expr0'); 
            totalDistrict = (Decimal)agg.get('expr1');
            mapOfCountryField.put(String.valueOf(agg.get('coun')),new Country__c(Id = (Id)agg.get('coun'),
                Total_States__c = (Decimal)agg.get('expr0'),
                Total_District__c = (Decimal)agg.get('expr1')));
        }
        if(!mapOfCountryField.isEmpty()){
            update mapOfCountryField.values();   
        }
    }
    /**   Description :   JSON Data
    *     Created By  :   Sagar Nirwal
    *     Arguments   :   String
    *     Return      :   void
    *     Revision log:   V_1.0 - Created  - Sagar Nirwal - 14/06/2022
    *                     V_1.1 - Modified - Sagar Nirwal - 14/06/2022 - Passing the argument 
    **/    
    public static void countryData(String conutryName){    
        // JSON Data
        
        CountryData counData = new CountryData();
        counData.country = new List<Country>();
        for(String code : codeMap.keySet()){
            Country countryWrapper = new Country();
            countryWrapper.countryName = conutryName;
            countryWrapper.countryCode = code;
            countryWrapper.totalStates = totalState;
            countryWrapper.totalDistricts =  totalDistrict;                                        
            countryWrapper.states = new List<State>();
            for(String sta : countryMap.get(conutryName).keySet()) {
                State stateWrapper = new State();
                stateWrapper.stateName = sta;
                stateWrapper.districts = new List<District>();
                
                for(String district : countryMap.get(conutryName).get(sta)) {
                    District districtWrapper = new District();
                    districtWrapper.districtName = district;
                    stateWrapper.districts.add(districtWrapper);
                }
                countryWrapper.states.add(stateWrapper);
            }
            counData.country.add(countryWrapper);
        }
        JSONData = System.JSON.serialize(counData);
        System.debug('===>>>'+JSONData);
        
        List<Country__c> listOfCountry = [SELECT Id,Name,Country_JASON__c 
                                          FROM Country__c Where Name IN :countryMap.keySet()];
        listOfCountry[0].Country_JASON__c = JSONData ;
        
        update listOfCountry;
        
    }
    //Wrapper Classes
    
    public class CountryData{
        public List<Country> country{get; set;}
    }
    public class Country {
        public String countryName{get; set;}
        public String countryCode{get; set;}
        public Decimal totalStates{get; set;}
        public Decimal totalDistricts{get; set;}
        public List<State> states{get; set;}
    }
    public class State {
        public String stateName{get; set;}
        public List<District> districts{get; set;}
    }
    public class District {
        public String districtName{get; set;}
    }
}