select 
CAST(P.PPend as date) as 'PPEnd',
CT.Spanish,
(SUM(CAST(P.RegularPay as dec(18,2)))
	+SUM(CAST(P.OTPay as dec(18,2)))
	+SUM(CAST(P.Commission as dec(18,2)))) as 'Total Pay',
SUM(D.Activations) as 'Activations',
CASE WHEN SUM(D.Activations) = 0 then 0 ELSE (SUM(CAST(P.RegularPay as dec(18,2)))
	+SUM(CAST(P.OTPay as dec(18,2)))
	+SUM(CAST(P.Commission as dec(18,2))))/ SUM(D.Activations) END as 'CPA',
	SUM(PP6.[Total Pay]) as 'Total 3 Pay PP',
	SUM(AP6.Activations) as 'Activations 3 Pay PP',
	SUM(PP6.[Total Pay]) / SUM(AP6.Activations) as 'CPA 3 Pay PP'

into #Thresholds
from tableau.agentpay P --select  * from tableau.agentpay P

LEFT JOIN( 
	SELECT
	D2.Empnum,
	RC.PPEnd,
	SUM(D2.TotalCalls) as 'TotalCalls',
	SUM(D2.ProdMinutes) as 'ProdMinutes',
	COUNT(CASE WHEN D2.Type = 0 THEN D2.AccountNumber ELSE NULL END) as 'Sales',
	COUNT(A.AccountNumber) 'ActivatedSales',
	COUNT(CASE WHEN D2.Type = 1 THEN D2.AccountNumber ELSE NULL END) as 'Activations'
	FROM DailyKPIAccount D2
	LEFT JOIN DAILYKPIACCOUNT A WITH(NOLOCK) --Join to DailyKPIAccount, this time with a condition on A.Type, to attach activation info onto the existing sale row
	ON D2.AccountNumber = A.AccountNumber
	AND A.Type = 1
    AND D2.Type = 0
	LEFT JOIN ReportCalendar RC
	on RC.Date = D2.Date 
	Where D2.Date >= '01/01/2019'
	GROUP BY D2.Empnum,
	RC.PPEnd) D
	ON P.OracleID = D.EmpNum
	AND P.PPEnd = D.PPEnd

LEFT JOIN(
select 
RC2.PPend,
R.Empnum,
MAX(R.AgentCallType) as 'AgentCallType',
MAX(CAST(R.Spanish as int)) as 'Spanish',
MAX(datediff(week,R.Hire_Date,R.Date)) as 'Tenure'
from RankingData R --select top 10 * from RankingData
LEFT JOIN ReportCalendar RC2
ON RC2.Date = R.Date
WHERE R.Date >= '01/01/2019'
GROUP BY 
RC2.PPend,
R.Empnum) CT
on CT.PPEnd = P.PPEnd
and CT.EmpNum = P.OracleID

LEFT JOIN ( --This is to find if the agent was under a different call type during the pay period
SELECT DISTINCT
r3.empnum as 'EmpNum',
RC2.PPEnd as 'PPEnd'
FROM SalesPortal..RankingData R3
LEFT JOIN ReportCalendar RC2 --select top 10 * from ReportCalendar RC where date > '01/01/2019'
	on RC2.Date = R3.Date
where R3.AgentCallType not in ('IBS','New Hire')) Change
on change.empnum = P.OracleID
and change.PPEnd = P.PPEnd

LEFT JOIN ReportCalendar Rc
on RC.Date = P.PPend

OUTER APPLY(
SELECT COUNT(CASE WHEN D3.Type = 1 THEN D3.AccountNumber ELSE NULL END) as 'Activations'
	FROM DailyKPIAccount D3
	where D3.Date between RC.PPEND - 41 and RC.PPEND
	AND D3.EmpNum = P.OracleID)
	AP6

OUTER APPLY(
SELECT SUM(CAST(AP.RegularPay as dec(18,2)))+SUM(CAST(AP.OTPay as dec(18,2)))+SUM(CAST(AP.Commission as dec(18,2))) as 'Total Pay'
	FROM tableau.AgentPay AP --select top 10 * from tableau.AgentPay AP
	where AP.PPEnd between RC.PPEND - 41 and RC.PPEND
	AND AP.OracleID = P.OracleID)
	PP6

Where p.PPEND >= '01/01/2020'
and CT.AgentCallType in ('IBS','New Hire')
and Change.Empnum is null
and CT.Tenure >= 9

group by
CT.Spanish,
P.PPend


SELECT
P.PPend,
P.OracleID, 
R.Agent,
R.EmpNum,
R.Center,
R.Spanish,
R.Coach as 'Team Manager',
R.CoachEmpNum as 'Team Manager Emp Num',
CS2.AnsweredCalls as '3 PP Answered Calls',
CS21.AnsweredCalls as 'Current PP Answered Calls',
(D.TotalCalls) as 'Calls from KPI',
PP3.TotalPay,
PP31.TotalPay as 'Current PP Total Pay',
AP3.Activations,
AP31.Activations as 'Current PP Activations',
CASE WHEN AP3.Activations = 0 then null ELSE PP3.TotalPay/AP3.Activations END as 'CPA',
CASE WHEN T.[CPA 3 Pay PP] * 1.3 
			<= 
CASE WHEN AP3.Activations = 0 then null ELSE PP3.TotalPay/AP3.Activations END --CPA
			THEN 1 ELSE 0 END as 'Outlier',
T.[CPA 3 Pay PP] as '3 PP Expected CPA',
T.CPA as 'Expected CPA',
DW.ProdMinutes,
DW1.ProdMinutes as 'Current PP Prod Minutes',
D.Sales,
D1.Sales as 'Current PP Sales',
D1.ActivatedSales as 'Current PP ActivatedSales',
DW.DaysWorked,
D.ActivatedSales,
Staff.Staff,
R.PhoneLogin,
datediff(week,R.Hire_Date,R.Date) as 'tenure',
CASE WHEN CAST((CASE WHEN PA.Tier = 0 then 3 when PA.Tier =12 then 2 when PA.Tier is null then 0 else PA.Tier END
			 + CASE WHEN PA2.Tier = 0 then 3 when PA2.Tier =12 then 2 when PA2.Tier is null then 0 else PA2.Tier END
			 + CASE WHEN PA3.Tier = 0 then 3 when PA3.Tier =12 then 2 when PA3.Tier is null then 0 else PA3.Tier END
			 + CASE WHEN PA4.Tier = 0 then 3 when PA4.Tier =12 then 2 when PA4.Tier is null then 0 else PA4.Tier END
			 + CASE WHEN PA5.Tier = 0 then 3 when PA5.Tier =12 then 2 when PA5.Tier is null then 0 else PA5.Tier END
			 + CASE WHEN PA6.Tier = 0 then 3 when PA6.Tier =12 then 2 when PA6.Tier is null then 0 else PA6.Tier END
			 + CASE WHEN PA7.Tier = 0 then 3 when PA7.Tier =12 then 2 when PA7.Tier is null then 0 else PA7.Tier END) as float) =0
			 then null else 
ROUND(CAST((CASE WHEN PA.Tier = 0 then 3 when PA.Tier =12 then 2 when PA.Tier is null then 0 else PA.Tier END
			 + CASE WHEN PA2.Tier = 0 then 3 when PA2.Tier =12 then 2 when PA2.Tier is null then 0 else PA2.Tier END
			 + CASE WHEN PA3.Tier = 0 then 3 when PA3.Tier =12 then 2 when PA3.Tier is null then 0 else PA3.Tier END
			 + CASE WHEN PA4.Tier = 0 then 3 when PA4.Tier =12 then 2 when PA4.Tier is null then 0 else PA4.Tier END
			 + CASE WHEN PA5.Tier = 0 then 3 when PA5.Tier =12 then 2 when PA5.Tier is null then 0 else PA5.Tier END
			 + CASE WHEN PA6.Tier = 0 then 3 when PA6.Tier =12 then 2 when PA6.Tier is null then 0 else PA6.Tier END
			 + CASE WHEN PA7.Tier = 0 then 3 when PA7.Tier =12 then 2 when PA7.Tier is null then 0 else PA7.Tier END) as float) / 
	CAST((CASE WHEN PA.Tier is null then 0 else 1 end + 
	CASE WHEN PA2.Tier is null then 0 else 1 end +
	CASE WHEN PA3.Tier is null then 0 else 1 end +
	CASE WHEN PA4.Tier is null then 0 else 1 end +
	CASE WHEN PA5.Tier is null then 0 else 1 end +
	CASE WHEN PA6.Tier is null then 0 else 1 end +
	CASE WHEN PA7.Tier is null then 0 else 1 end) as float), 0) end as 'Average PA'


FROM tableau.agentpay P --select * from tableau.agentpay P where OracleID = '806668'

LEFT JOIN PIP.AgentPriority_All PA --select top 10 * from PIP.AgentPriority_All PA where weekend = '04/17/2020' and empnum = '806668'
on PA.WeekEnd = CAST(P.PPEnd as DATE)
AND PA.EmpNum = P.OracleID

LEFT JOIN PIP.AgentPriority_All PA2 --This pulls the agents PA status in the middle of the PP
on PA2.WeekEnd = DATEADD(week,-1,CAST(P.PPEnd as DATE))
AND PA2.EmpNum = P.OracleID

LEFT JOIN PIP.AgentPriority_All PA3 --This pulls the agents PA status at the start of the PP
on PA3.WeekEnd = DATEADD(week,-2,CAST(P.PPEnd as DATE))
AND PA3.EmpNum = P.OracleID

LEFT JOIN PIP.AgentPriority_All PA4 --This pulls the agents PA status at the start of the PP
on PA4.WeekEnd = DATEADD(week,-3,CAST(P.PPEnd as DATE))
AND PA4.EmpNum = P.OracleID

LEFT JOIN PIP.AgentPriority_All PA5 --This pulls the agents PA status at the start of the PP
on PA5.WeekEnd = DATEADD(week,-4,CAST(P.PPEnd as DATE))
AND PA5.EmpNum = P.OracleID

LEFT JOIN PIP.AgentPriority_All PA6 --This pulls the agents PA status at the start of the PP
on PA6.WeekEnd = DATEADD(week,-5,CAST(P.PPEnd as DATE))
AND PA6.EmpNum = P.OracleID

LEFT JOIN PIP.AgentPriority_All PA7 --This pulls the agents PA status at the start of the PP
on PA7.WeekEnd = DATEADD(week,-6,CAST(P.PPEnd as DATE))
AND PA7.EmpNum = P.OracleID

LEFT JOIN RankingData R
on R.Empnum = P.OracleID
and R.Date = (SELECT MAX(R2.Date) From RankingData R2 where R2.Date Between DATEADD(dd,-14,CAST(P.PPEnd as date)) and CAST(P.PPend as date) and R2.Empnum = R.Empnum)

OUTER APPLY( 
	SELECT 
		CS.PeripheralNumber, 
		SUM(CS.HandledCallsTalkTime+CS.ACW) as 'HandleTime',
		SUM(CS.CallsHandled) as 'AnsweredCalls'
	FROM MorningProcess.CiscoSkillSummary CS ----select top 10 * from MorningProcess.CiscoReference CR 
	JOIN MorningProcess.CiscoReference CR WITH(NOLOCK) --Join to bring in info about the call queue --select top 10 * from MorningProcess.CiscoReference CR
	ON CS.Skill_ID = CR.Skill_ID
	AND CAST(CS.DateTime AS DATE) BETWEEN CR.StartDate AND CR.StopDate
	WHERE CS.DateTime >= '01/01/2019'
	AND	description like 'PQ_%'
	AND description like '%sale%'
	AND description not like '%Broadband%'
	AND description not like '%Cmrcl%'
	AND description not like '%outdoor%'
	AND CS.PeripheralNumber = R.Phonelogin
	AND CAST(CS.DateTime AS DATE) Between DATEADD(dd,-41,CAST(P.PPEND as Date)) and CAST(P.PPEnd as Date)
	GROUP BY
	CS.PeripheralNumber) CS2

OUTER APPLY( 
	SELECT 
		CS.PeripheralNumber, 
		SUM(CS.HandledCallsTalkTime+CS.ACW) as 'HandleTime',
		SUM(CS.CallsHandled) as 'AnsweredCalls'
	FROM MorningProcess.CiscoSkillSummary CS ----select top 10 * from MorningProcess.CiscoReference CR 
	JOIN MorningProcess.CiscoReference CR WITH(NOLOCK) --Join to bring in info about the call queue --select top 10 * from MorningProcess.CiscoReference CR
	ON CS.Skill_ID = CR.Skill_ID
	AND CAST(CS.DateTime AS DATE) BETWEEN CR.StartDate AND CR.StopDate
	WHERE CS.DateTime >= '01/01/2019'
	AND	description like 'PQ_%'
	AND description like '%sale%'
	AND description not like '%Broadband%'
	AND description not like '%Cmrcl%'
	AND description not like '%outdoor%'
	AND CS.PeripheralNumber = R.Phonelogin
	AND CAST(CS.DateTime AS DATE) Between DATEADD(dd,-13,CAST(P.PPEND as Date)) and CAST(P.PPEnd as Date)
	GROUP BY
	CS.PeripheralNumber) CS21

OUTER APPLY(
SELECT SUM(CAST(AP.RegularPay as dec(18,2)))+SUM(CAST(AP.OTPay as dec(18,2)))+SUM(CAST(AP.Commission as dec(18,2))) as 'TotalPay'
	FROM tableau.AgentPay AP --select top 10 * from tableau.AgentPay AP
	where AP.PPEnd between DATEADD(dd,-41,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND AP.OracleID = P.OracleID)
	PP3


OUTER APPLY(
SELECT SUM(CAST(AP.RegularPay as dec(18,2)))+SUM(CAST(AP.OTPay as dec(18,2)))+SUM(CAST(AP.Commission as dec(18,2))) as 'TotalPay'
	FROM tableau.AgentPay AP --select top 10 * from tableau.AgentPay AP
	where AP.PPEnd between DATEADD(dd,-13,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND AP.OracleID = P.OracleID)
	PP31

OUTER APPLY(
SELECT COUNT(CASE WHEN D3.Type = 1 THEN D3.AccountNumber ELSE NULL END) as 'Activations'
	FROM DailyKPIAccount D3
	where D3.Date between DATEADD(dd,-41,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND D3.Date >= '01/01/2019'
	AND D3.EmpNum = P.OracleID)
	AP3

	OUTER APPLY(
SELECT COUNT(CASE WHEN D3.Type = 1 THEN D3.AccountNumber ELSE NULL END) as 'Activations'
	FROM DailyKPIAccount D3
	where D3.Date between DATEADD(dd,-13,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND D3.Date >= '01/01/2019'
	AND D3.EmpNum = P.OracleID)
	AP31

OUTER APPLY(
SELECT SUM(A.StaffTime)/60 as 'Staff'
	FROM SalesPortal.MorningProcess.CiscoAgentSummary A
	where CAST(A.DateTime as date) between DATEADD(dd,-41,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND A.PeripheralNumber = R.PhoneLogin
	AND A.DateTime >= '01/01/2019')
	Staff


OUTER APPLY( 
	SELECT
	D2.Empnum,
	SUM(D2.TotalCalls) as 'TotalCalls',
	SUM(D2.ProdMinutes) as 'ProdMinutes',
	COUNT(CASE WHEN D2.Type = 0 THEN D2.AccountNumber ELSE NULL END) as 'Sales',
	COUNT(A.AccountNumber) 'ActivatedSales',
	COUNT(CASE WHEN D2.Type = 1 THEN D2.AccountNumber ELSE NULL END) as 'Activations',
	COUNT(DISTINCT D2.Date) as 'DaysWorked'
	FROM DailyKPIAccount D2
	LEFT JOIN DAILYKPIACCOUNT A WITH(NOLOCK) --Join to DailyKPIAccount, this time with a condition on A.Type, to attach activation info onto the existing sale row
	ON D2.AccountNumber = A.AccountNumber
	AND A.Type = 1
    AND D2.Type = 0
	WHERE D2.Empnum = P.OracleID
	and D2.Date between DATEADD(dd,-41,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND d2.Date >= '01/01/2019'
	GROUP BY D2.Empnum) D

OUTER APPLY( 
	SELECT
	D2.Empnum,
	SUM(D2.TotalCalls) as 'TotalCalls',
	SUM(D2.ProdMinutes) as 'ProdMinutes',
	COUNT(CASE WHEN D2.Type = 0 THEN D2.AccountNumber ELSE NULL END) as 'Sales',
	COUNT(A.AccountNumber) 'ActivatedSales',
	COUNT(CASE WHEN D2.Type = 1 THEN D2.AccountNumber ELSE NULL END) as 'Activations',
	COUNT(DISTINCT D2.Date) as 'DaysWorked'
	FROM DailyKPIAccount D2
	LEFT JOIN DAILYKPIACCOUNT A WITH(NOLOCK) --Join to DailyKPIAccount, this time with a condition on A.Type, to attach activation info onto the existing sale row
	ON D2.AccountNumber = A.AccountNumber
	AND A.Type = 1
    AND D2.Type = 0
	WHERE D2.Empnum = P.OracleID
	and D2.Date between DATEADD(dd,-13,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND d2.Date >= '01/01/2019'
	GROUP BY D2.Empnum) D1

OUTER APPLY( 
	SELECT
	R4.Empnum,
	SUM(R4.ProdMinutes) as 'ProdMinutes',
	COUNT(DISTINCT CASE WHEN R4.ProdMinutes > 0 then R4.Date ELSE NULL END) as 'DaysWorked'
	FROM RankingData R4 --select top 10 * from RankingData
	WHERE R4.Empnum = P.OracleID
	and R4.Date between DATEADD(dd,-41,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND R4.Date >= '01/01/2019'
	GROUP BY R4.Empnum) DW

OUTER APPLY( 
	SELECT
	R5.Empnum,
	SUM(R5.ProdMinutes) as 'ProdMinutes',
	COUNT(DISTINCT CASE WHEN R5.ProdMinutes > 0 then R5.Date ELSE NULL END) as 'DaysWorked'
	FROM RankingData R5 --select top 10 * from RankingData
	WHERE R5.Empnum = P.OracleID
	and R5.Date between DATEADD(dd,-13,CAST(P.PPEND as date)) and CAST(P.PPEnd as DATE)
	AND R5.Date >= '01/01/2019'
	GROUP BY R5.Empnum) DW1

LEFT JOIN #Thresholds T
on T.PPEnd = P.PPEnd
AND T.Spanish = R.Spanish

LEFT JOIN ( --This is to find if the agent was under a different call type during the pay period
SELECT DISTINCT
r3.empnum as 'EmpNum',
RC2.PPEnd as 'PPEnd'
FROM SalesPortal..RankingData R3
LEFT JOIN ReportCalendar RC2 --select top 10 * from ReportCalendar RC where date > '01/01/2019'
	on RC2.Date = R3.Date
where R3.AgentCallType not in ('IBS')
AND R3.Date >= '01/01/2019') Change
on change.empnum = P.OracleID
and change.PPEnd between DATEADD(dd,-41,CAST(P.PPEnd as date)) and CAST(P.PPEnd as date)

Where datediff(week,R.Hire_Date,R.Date) >= 9
AND CAST(P.RegularHours as float) >0
          and CAST(P.PPEnd as date) >= '01/01/2020'
            and R.AgentCallType in ('IBS','New Hire')
			and Change.EmpNum is null