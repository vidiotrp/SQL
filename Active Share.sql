
SELECT 
                                AgentName AgentName,
                                Employee_Number EMPLOYEE_NUMBER,
                                Site Site,
                                SKILL_TYPE,
                                Router_CallKey_Date,
                                Router_CallKey,
                                MIN(cat_CallStartTime) cat_CallStartTime,
                               MAX(cat_CallEndTime) cat_CallEndTime,
                                MAX(NewConnectWorkOrderCreateTime) NewConnectWorkOrderCreateTime,
                                AccountNumber,
                                Coach_Manager COACH_MANAGER,
                                S.EVNT_SK,
                                CASE WHEN S.SMS >= 1 THEN 1 ELSE S.SMS END SMS,
				CASE WHEN S.EML >= 1 THEN 1 ELSE S.EML END EML,
                                COUNT(DISTINCT CASE WHEN DOC_NM_TXT LIKE '%Confirmation Card%' THEN Router_CallKey END) ConfCard,
                                COUNT(DISTINCT CASE WHEN DOC_NM_TXT LIKE '%Disclosure Card%' THEN Router_CallKey END) DisclosureCard,
                                COUNT(DISTINCT CASE WHEN DOC_NM_TXT LIKE '%Equipment Card%' THEN Router_CallKey END) EquipmentCard,
                                COUNT(DISTINCT CASE WHEN DOC_NM_TXT LIKE '%My Bill Card%' THEN Router_CallKey END) BillCard,
                                COUNT(DISTINCT CASE WHEN DOC_NM_TXT LIKE '%Programming Card%' THEN Router_CallKey END) ProgrammingCard

FROM (
                                                                                SELECT 
                                                                                                cat.FULL_NAME AgentName,
                                                                                                cat.EMPLOYEE_NUMBER,
                                                                                                LOCATION_NAME SITE,
                                                                                                Router_CallKey_Date,
                                                                                                Router_CallKey,
                                                                                                cat_CallStartTime, 
                                                                                                cat_CallEndTime,
                                                                                                ncwo_accts.ACNT_NBR AccountNumber,
                                                                                                (Cast(ncOrders.ORDR_OPN_DT AS TIMESTAMP (0)) + (ncOrders.ORDR_OPN_TM - TIME '00:00:00' HOUR TO SECOND)) - INTERVAL '2' HOUR as NewConnectWorkOrderCreateTime,
                                                                                                EVNT.EVNT_SK,
																								EVNT.SMS,
																								EVNT.EML,
                                                                                                SKILL_TYPE,
                                                                                                Cat.Coach_manager
                                                                                                --ROW_NUMBER() OVER (PARTITION BY EVNT.EVNT_SK ORDER BY cat_CallStartTime ASC, NewConnectWorkOrderCreateTime DESC)

                                                                                FROM (
                                                                                
                                                                                SELECT                  
                                                                                                FULL_NAME ,
                                                                                                empDetails.EMPLOYEE_NUMBER,
                                                                                                empDetails.LOCATION_NAME ,
                                                                                                empDetails.Department_Name,
                                                                                                XXHR_EMP_DTL_HIST_SID,
                                                                                                CSG_OP_ID,
                                                                                                cat.Router_CallKey_Date,
                                                                                                cat.Router_CallKey,
                                                                                                MIN(CAST(CMV.CALL_START_DATE AS TIMESTAMP(0))+((CMV.call_leg_start_time)-TIME'00:00:00' HOUR TO SECOND)) as cat_CallStartTime ,
                                                                                                MAX(CAST(CMV.CALL_LEG_END_DATE AS TIMESTAMP(0))+((CMV.call_leg_end_time)-TIME'00:00:00' HOUR TO SECOND)) as cat_CallEndTime ,
                                                                                                SKILL_TYPE,
                                                                                                cat.Coach_manager

                                                                FROM TD_CSC.CALL_RECRDING_CALL_FCT_VW cat --select top 10 * from 
                                                                                                                
                                                                                                                JOIN TD_CSC.CALL_LEG_DETAIL_VW CMV
                                                                                                                ON CMV.ROUTER_CALL_KEY = cat.Router_CallKey
                                                                                                                AND CMV.ROUTER_CALL_KEY_DATE = cat.Router_CallKey_Date
                                                                                                                AND cat.Phone_login = CMV.PHONE_LOGIN_ID
                                                                                                                
                                                                                                                INNER JOIN EDW_TABLE_VIEWS.XXHR_EMP_DTL_HIST empDetails ON cat.Employee_Number = empDetails.Employee_Number AND cat.CALL_DATE_TIME BETWEEN empDetails.PM_BEGIN_DATE AND empDetails.PM_END_DATE

                                                                                                                
                                                                WHERE  CMV.CALL_START_DATE >= '2019-06-01'
                                                                --Router_CallKey_Date = 152841 and Router_CallKey = 93286
                                                                --AND cat.PHONE_LOGIN = '77092'
                                                                                                                                
                                                                AND (cat.Router_CallKey_Date <> '152859' AND cat.Router_CallKey <> '147614')
                                                
                                                                
                                                                GROUP BY 1,2,3,4,5,6,7,8,11,12
                )cat

    LEFT JOIN (
        SELECT 
            CNTCT_EVNT.EMPLOYEE_SK,
            EVNT.EVNT_STRT_DTTM, 
            EVNT.EVNT_SK,
			CNTCT_EVNT.SMS_INVTS_SENT_CNT SMS,
			CNTCT_EVNT.EML_INVTS_SENT_CNT EML

        FROM EDW_TABLE_VIEWS.EVNT_VW EVNT                                                

        LEFT JOIN EDW_TABLE_VIEWS.CNTCT_EVNT_VW  CNTCT_EVNT ON 
                   EVNT.EVNT_SK=CNTCT_EVNT.EVNT_SK --select top 10 * from EDW_TABLE_VIEWS.EVNT_VW EVNT        
                                                                                                                                                                                                   
        LEFT JOIN EDW_TABLE_VIEWS.RCS_CD_VW RCS ON CNTCT_EVNT.EVNT_TRMNTN_TYP_SK=RCS.RCS_CD_SK
                        AND RCS.IS_ACTV_FLG='Y'  
                    
                        
        WHERE EVNT.etl_dat_src_sk=10192 --24[7] Active Share
        AND EVNT.EVNT_STRT_DTTM >= TIMESTAMP'2019-06-01 00:00:00'
    )EVNT
    
    ON  EVNT.EMPLOYEE_SK = cat.XXHR_EMP_DTL_HIST_SID
    AND EVNT_STRT_DTTM BETWEEN cat_CallStartTime AND cat_CallEndTime --select top 10 * from EDW_TABLE_VIEWS.EVNT_VW EVNT
                                                                                                                                                                                                                                                   
    
                                                                                                                                                                                                                

                                                                                                                                                                                                                                  
                                                LEFT JOIN EDW_APPS.ORDR_DIM_VW ncOrders ON ncOrders.CREAT_OPID = cat.CSG_OP_ID -- same agent, work order created during CAT call boundaries
                                                              AND (Cast(ncOrders.ORDR_OPN_DT AS TIMESTAMP (0)) + (ncOrders.ORDR_OPN_TM - TIME '00:00:00' HOUR TO SECOND)) - INTERVAL '2' HOUR >= cat_CallStartTime 
                                                               AND (Cast(ncOrders.ORDR_OPN_DT AS TIMESTAMP (0)) + (ncOrders.ORDR_OPN_TM - TIME '00:00:00' HOUR TO SECOND)) - INTERVAL '2' HOUR <= cat_CallEndTime  --+ interval '5' minute
                                                               AND ncOrders.ORDR_TYP_CD_TXT = 'NC' -- new connect

                        LEFT JOIN EDW_APPS.ORDR_ACNT_ORDR_TYP_XREF_VW ncWoAccounts on ncWoAccounts.ORDR_SK = ncOrders.ORDR_DIM_SK
                                                
                        LEFT JOIN EDW_APPS.ACNT_DIM_VW ncwo_accts ON ncWoAccounts.ACNT_SK = ncwo_accts.ACNT_SK
                                                                 AND ncwo_accts.IS_ACTV_FLG = 'Y'
                                                                                                                                                                                                                
                        LEFT JOIN
                        (
                            SELECT ACNT_NBR, MIN(BGN_EFF_DT) as AccountCreateDate FROM EDW_APPS.ACNT_DIM_VW GROUP BY ACNT_NBR
                        ) ncwo_AccountCreateDates on ncwo_accts.ACNT_NBR = ncwo_AccountCreateDates.ACNT_NBR
/*                   QUALIFY
                            -- The CAT call with the earliest start time is the correct one, and if there's multiple NC work orders set up on that call, use the latest one, since presumably
                            -- the earlier work orders had problems leading to the creation of the later one.
                            ROW_NUMBER() OVER (PARTITION BY EVNT.EVNT_SK ORDER BY cat_CallStartTime ASC, NewConnectWorkOrderCreateTime DESC) = 1*/
                                                                

                        WHERE cat.DEPARTMENT_NAME LIKE '%SALES%' AND (SKILL_TYPE LIKE '%SALES%' AND SKILL_TYPE NOT LIKE '%SLING%' AND Skill_type NOT LIKE '%BROADBAND%') 
                                                AND  cat_CallStartTime >= '2019-06-01 00:00:00' 
                                                --AND Router_CallKey_Date = 152841 and Router_CallKey = 93286
                                                
                )S
                    LEFT JOIN
        EDW_TABLE_VIEWS.EVNT_AGRMNT_VW cards ON S.EVNT_SK = cards.EVNT_SK --select top 10 * from EDW_TABLE_VIEWS.EVNT_AGRMNT_VW



GROUP BY 1,2,3,4,5,6,10,11,12,13,14          