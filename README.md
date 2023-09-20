# GtsSIDB (Custom)
GTS Custom Simplification DB
The JSON files 
1. GTSCustomSIDB2023000.json -> Contains Successor/deprecation related information
2. GtsSIDBDetails.json -> Contains Details about Data model/APi changes
were built by going through the "Conversion Guide for SAP Global Trade Services, edition for SAP HANA(Document version 2023 version 000 )
https://help.sap.com/doc/25831a740892478da87d3204dbbaf693/2023.000/en-US/loio49860f614e374155b143261fcb13782c_en.pdf

Prerequiste
1. Central ATC system/ System where CCM App is positioned must have certain infrastructure(cloudif DB check classes/Cloud Readiness ATC)
   hence make sure Note : https://me.sap.com/notes/3284711 is implemented as the current approach is copy of class "CL_CLS_CI_CHECK_E_ONPR_CLOUDIF" and its super class with some
   modification to connect this GtHub Repository for custom simplification DB for GTS
3. System must be on >= S/4HANA 2020

Pending Task
1. Currently working on making this class available on Git Hub(Just global class is posted here, changes can be checked by searching string "Begin of Change")
2. Creation of custom Zcheck class from scratch accesing Git(Future Scope)

   


