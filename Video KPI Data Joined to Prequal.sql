SELECT 
R.Date,
R.Center,
NULL Account,
SUM(C.CallsHandled)+MAX(COALESCE(P.Handled,0))  PreQual
into #Temp
FROM RankingData R WITH (NOLOCK)
LEFT JOIN
(
       SELECT Date, EmpNum, Tier 
       FROM PIP.AgentPriority_All WITH (NOLOCK)
       JOIN ReportCalendar WITH (NOLOCK) ON WeekEnd = WeekEndDate
       
)PIP ON PIP.EmpNum = R.EmpNum AND PIP.Date = R.Date
LEFT JOIN (
       SELECT DateTime, PeripheralNumber, SUM(CallsHandled) CallsHandled
       FROM MorningProcess.CiscoSkillSummary  C WITH (NOLOCK)
       WHERE C.Skill_ID IN (5193, 5194)
       GROUP BY DateTime, PeripheralNumber
       )C     ON C.DateTime = R.Date AND C.PeripheralNumber = R.PhoneLogin 
/*LEFT JOIN (

       SELECT QUAL_DATE, UPPER, SUM(ATTEMPTS) Attempts, (SUM([Elite Credit Quals]) + SUM([Plus Credit Quals]) + SUM([Standard Credit Quals])) DHA_Quals
       FROM qualExport WITH (NOLOCK)
       WHERE LOB IN ('Video', 'Hybrid Sat', 'Hybrid Wire') AND [Channel Name] = 'Direct'
       GROUP BY QUAL_DATE, UPPER

)Q ON Q.UPPER = R.OPID AND Q.QUAL_DATE = R.Date*/
LEFT JOIN PrequalRepointCorrection P On P.PhoneLogin = C.PeripheralNumber AND P.Date = C.DateTime 
WHERE R.Date >= '1/1/2019' AND AgentCallType IN ('New Hire','IBS','Commercial')
AND R.Date NOT IN('4/11/2018','4/12/2018','4/13/2018') -- April PreQual TFNs not pointed to PreQual PQ fixed midday 4/13

GROUP BY R.Date, R.Center

UNION

SELECT DISTINCT
r.date,
'XX' Center,
NULL Account,
NULL Prequal
from rankingdata r
WHERE R.Date >= '1/1/2019' AND AgentCallType IN ('New Hire','IBS','Commercial')
AND R.Date NOT IN('4/11/2018','4/12/2018','4/13/2018') -- April PreQual TFNs not pointed to PreQual PQ fixed midday 4/13


SELECT T.date, T.Center, CAST(T.Account as varchar) Account, T.Prequal, S.Calls, S.Sales

FROM #Temp T
LEFT JOIN (
SELECT 
D.Date,
CASE WHEN D.Center is null then 'XX' ELSE D.Center END 'Center',
SUM(CASE WHEN D.[Sub Group] != 'Teleopti Answered Calls' then D.TotalCalls ELSE NULL END) as 'Calls',
SUM(CASE WHEN D.[Sub Group] != 'Historically-Reported Sales' /*and D.CallType != 'Chat'*/ and D.Agent != 'DISHCART_WSAPI' and D.OfferCode not in ('01ACCTTRANS','01BETA','01RECAUDIT','04OEFTR','23RETAFFIL','50COMM','50COMPCO')
THEN D.Sales ELSE NULL END) as 'Sales'
FROM [SalesPortal].[dbo].[DailyKPITableuTable] D WITH(NOLOCK)
where d.date >= '01/01/2019'
group by D.Date, D.Center) S
on S.Date = T.Date
AND S.Center = T.Center

UNION

SELECT 
R.Date,
R.Center,
CAST(Account# as varchar) Account,
0 PreQual,
0 Calls,
0 Sales
FROM RankingData R WITH (NOLOCK)
LEFT JOIN
(
       SELECT Date, EmpNum, Tier 
       FROM PIP.AgentPriority_All WITH (NOLOCK)
       JOIN ReportCalendar WITH (NOLOCK) ON WeekEnd = WeekEndDate
       
)PIP ON PIP.EmpNum = R.EmpNum AND PIP.Date = R.Date
LEFT JOIN MasterTable_adj M WITH (NOLOCK)ON R.Date = M.[Date Oppened] AND R.OPID = M.[OP ID]

WHERE R.Date >= '1/1/2019' AND AgentCallType IN ('New Hire','IBS','Commercial')
AND R.Date NOT IN('4/11/2018','4/12/2018','4/13/2018') -- April PreQual TFNs not pointed to PreQual PQ fixed midday 4/13
GROUP BY R.Date, R.Center,
Account#