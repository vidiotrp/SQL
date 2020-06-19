SELECT
AgentName = (Person.LastName + ', ' + Person.FirstName),
Agent.SkillTargetID,
Agent.PeripheralNumber,
RecoveryKey,
Reason = (RC.ReasonText + '[' + CAST(RC.ReasonCode AS varchar) + ']'),
Duration = AED.Duration,
DateTime = DATEADD(Day, DATEDIFF(Day, 0 , AED.DateTime), 0),
Start = DATEADD(ss, -AED.Duration, AED.DateTime),
'Stop' = DateTime,
DbDateTime

into #CTE
FROM Agent_Event_Detail AED
  INNER JOIN Agent ON (AED.SkillTargetID = Agent.SkillTargetID)
  INNER JOIN Person ON (Agent.PersonID = Person.PersonID)
  INNER JOIN Reason_Code RC ON (AED.ReasonCode = RC.ReasonCode)
WHERE (DATEPART(dw, DATEADD(Day, DATEDIFF(Day, 0 , AED.DateTime), 0)) in(2,3,4,5,6,7,1) and DATEADD(Day, DATEDIFF(Day, 0 , AED.DateTime), 0) >= '2019-01-01 00:00:00' and convert([char], DATEADD(Day, DATEDIFF(Day, 0 , AED.DateTime), 0), 108) between '00:00:00' and '23:59:59') and AED.Event = 3;
--ORDER BY DATEADD(ss, -AED.Duration, AED.DateTime)

SELECT AgentName, SkillTargetID, PeripheralNumber, DateTime, RecoveryKey, MAX(Reason) Reason, MAX(Duration) Duration, MIN(Start) Start, MAX(Stop) Stop
into #CTE2
FROM (
	SELECT C.AgentName, C.SkillTargetID, C.PeripheralNumber, C.Reason, COALESCE(C2.RecoveryKey, C.RecoveryKey) RecoveryKey,  SUM(COALESCE(C.Duration,0)+COALESCE(C2.Duration,0)) Duration, (CASE WHEN C.Start < C2.Start OR C2.Start IS NULL THEN C.Start ELSE C2.Start END) Start, (CASE WHEN C.Stop > C2.Stop OR C2.Start IS NULL THEN C.Stop ELSE C2.Stop END) Stop, C.DateTime
	FROM #CTE C
	LEFT JOIN #CTE C2 ON C2.SkillTargetID = C.SkillTargetID AND C2.DateTime = C.DateTime AND C2.Reason = C.Reason AND (C2.Start BETWEEN C.Start AND C.Stop OR C.Stop BETWEEN C2.Start AND C2.Stop) AND C2.Stop <> C.Stop
	GROUP BY C.AgentName, C.SkillTargetID, C.PeripheralNumber, C.Reason, (CASE WHEN C.Start < C2.Start OR C2.Start IS NULL THEN C.Start ELSE C2.Start END) , (CASE WHEN C.Stop > C2.Stop OR C2.Start IS NULL THEN C.Stop ELSE C2.Stop END) , COALESCE(C2.RecoveryKey, C.RecoveryKey), C.DateTime
	--ORDER BY MIN(CASE WHEN C.Start < C2.Start THEN C.Start ELSE C2.Start END)
)s
GROUP BY AgentName, SkillTargetID, PeripheralNumber, DateTime, RecoveryKey


SELECT 
AgentName, 
PeripheralNumber, 
COUNT(distinct DateTime) as 'Days Breaked',
dateadd(day, ceiling(datediff(day,4, DATEADD(Day, DATEDIFF(Day, 0 , DateTime), 0)) / 14.0) * 14, 4) as 'DateTime', 
COUNT(Distinct RecoveryKey) as 'Breaks', 
SUM(Duration) as 'Duration' 
from #CTE2 
GROUP BY AgentName, 
PeripheralNumber, 
dateadd(day, ceiling(datediff(day,4, DATEADD(Day, DATEDIFF(Day, 0 , DateTime), 0)) / 14.0) * 14, 4)