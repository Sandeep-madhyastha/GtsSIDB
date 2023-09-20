# GtsSIDB (Custom)
GTS Custom Simplification DB technically consists of Successor/Deprecation/Data model or API Changes and its details in GTS system as json files in this Git Hub Repository
The JSON files 
1. GTSCustomSIDB2023000.json -> Contains Successor/Deprecation related information (based on json structure of Cloudification DB)
2. GtsSIDBDetails.json -> Contains Details about Data model/APi changes (Custom json structure built from scratch)

were built by going through the "Conversion Guide for SAP Global Trade Services, edition for SAP HANA(Document version 2023 version 000 )" :
https://help.sap.com/doc/25831a740892478da87d3204dbbaf693/2023.000/en-US/loio49860f614e374155b143261fcb13782c_en.pdf

Prerequisites
1. Central ATC system/ System where CCM App is positioned must have certain infrastructure(cloudif DB check classes/Cloud 
   Readiness ATC) hence make sure Note : https://me.sap.com/notes/3284711 is implemented as the current approach is copy of 
   class "CL_CLS_CI_CHECK_E_ONPR_CLOUDIF" and its super class with some modification to connect this GtHub Repository for custom 
   simplification DB for GTS.
   
   Note: Find string "** Begin of" in the ABAP Zcheck classes to see the modifications done
2. System must be on >= S/4HANA 2020

Pending Task
1. Currently working on making this classes "ZCL_CCM_CLS_CI_CHECK_ENV" and "ZCL_CCM_CLS_CI_CHK_E_OP_CLDIF" available on Git Hub(Just global class is posted here, changes can be checked by searching string "Begin of")
2. Creation of custom Zcheck class from scratch accesing Git(Future Scope)

   


