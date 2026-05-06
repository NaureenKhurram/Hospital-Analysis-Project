-- initial EDA of hospital dataset

-- HOW MANY PATIENTS ARE IN THE DATASET
SELECT COUNT(*) as total_patients
FROM patients;  -- 974


-- NUMBER OF HOSPITAL ENCOUNTERS
SELECT COUNT(*) as total_encounters
FROM encounters;  -- 27891

-- HOW MANY PROCEDURES WERE PERFORMED
SELECT COUNT(*) as total_procedures
FROM procedures;  -- 47701


-- time period of encounters 
SELECT MIN(start_time), MAX(end_time)
FROM encounters; --2011-01-02  to 2022-02-05 so a little over a decade


-- average encounters per patient
SELECT 
    COUNT(*) / COUNT(DISTINCT patient_id) 
    AS avg_encounters_per_patient
FROM encounters;   -- on average each patient had 28 encounters

-- average procedures per encounter
SELECT 
    COUNT(*) / COUNT(DISTINCT encounter_id) 
    AS avg_procedures_per_encounter
FROM procedures;   -- on average each encounter had 3 procedures 


-- distribution per encounterclass
SELECT encounterclass, 
	COUNT(*) AS encounter_total
from encounters
GROUP BY encounterclass
ORDER BY encounter_total DESC;  -- highest is ambulatory; lowest is inpatient

-- top 10 most common procedures

SELECT description, COUNT(*) as Total_count
from procedures
Group by description
order by Total_count DESC
limit 10;

-- total encounters by payer

SELECT p.id, p.name, count(e.id) as total_encounters
from 
	payers p
	left join encounters e 
	on p.id = e.payer_id
group by p.id, p.name
order by total_encounters DESC; -- most Medicare, then No_Insurance


/* Patient Behavior Analysis

Patient demographics:

Analyse:
gender
age
race / ethnicity
marital status
location


*/


/*  Patient demographics  */


-- total patients

SELECT count (distinct id)
FROM patients --974 patients

-- gender distribution

SELECT gender,
	   count(*) as Patient_Count,
	   ROUND(count(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage

FROM 
	patients
group by gender
order by percentage DESC;  

/*
	M: 494, 
	F: 480
	According to gender, patients are almost equally distributed
*/


-- race distribution
SELECT race,
	   count(*) as Patient_Count,
	   ROUND(count(*) * 100.0 / SUM(COUNT(*)) OVER (), 0) as percentage
FROM 
	patients
group by race
order by percentage DESC;  

/*
	race: white (70%), black (17%), asian(9%)
*/

-- ethnicity distribution
SELECT ethnicity,
	   count(*) as Patient_Count,
	   ROUND(count(*) * 100.0 / SUM(COUNT(*)) OVER (), 0) as percentage
FROM 
	patients
group by ethnicity
order by percentage DESC;  

/*
	ethnicity: non-hispanic (80%), hispanic (20%)
*/

-- marital status distribution
SELECT marital_status,
	count(*) as Patient_Count,
	ROUND(count(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM 
	patients
group by marital_status
order by percentage DESC;  

/*
	marital status: Married (M: 80%), Single (S:19%)
*/

-- location distribution
SELECT county,
	count(*) as Patient_Count,
	ROUND(count(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM 
	patients
group by county
order by percentage DESC;  

/*
	Highest patients (66.1%) are from Suffolk County
*/

-- prefix distribution
SELECT prefix,
	count(*) as Patient_Count,
	ROUND(count(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) as percentage
FROM 
	patients
group by prefix
order by percentage DESC;  

/*

	Highest prefix is Mr. (50.7%), Mrs. (39.6%), Ms. (9.7%)
*/
-- age analysis

-- creating age groups and counting number of patients in each

SELECT
    CASE
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, birthdate)) < 18 THEN 'Under 18'
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, birthdate)) BETWEEN 18 AND 35 THEN '18-35'
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, birthdate)) BETWEEN 36 AND 55 THEN '36-55'
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, birthdate)) BETWEEN 56 AND 75 THEN '56-75'
        ELSE '76+'
    END AS age_group,
    COUNT (DISTINCT p.id) AS patient_count,
	ROUND(COUNT (DISTINCT p.id) * 100.0 / SUM(COUNT (DISTINCT p.id)) OVER (), 1) as percentage
FROM patients p
JOIN encounters e on
	p.id = e.patient_id
GROUP BY age_group
ORDER BY percentage DESC;

/*  
	highest percentage of patients are over 76 (34%),
	over half the patients are in the 36-55 and 56-75 age group (26%, 28%)

*/


-- encounters by gender

SELECT
    p.gender,
    COUNT(e.id) AS encounter_count,
	ROUND(count(e.id) * 100.0 / SUM(COUNT(e.id)) OVER (), 0) as percentage
FROM patients p
JOIN encounters e
ON p.id = e.patient_id
GROUP BY p.gender
ORDER BY encounter_count DESC;

/*

	M: 12967 (46%),
	F: 14924 (54%)

	Female encounters formed a higher percentage
*/


-- encounters by age group


SELECT
    CASE
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, p.birthdate)) < 18 THEN 'Under 18'
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, p.birthdate)) BETWEEN 18 AND 35 THEN '18-35'
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, p.birthdate)) BETWEEN 36 AND 55 THEN '36-55'
        WHEN EXTRACT(YEAR FROM AGE(e.start_time, p.birthdate)) BETWEEN 56 AND 75 THEN '56-75'
        ELSE '76+'
    END AS age_group,
    COUNT(e.id) AS encounter_count,
	ROUND(count(e.id) * 100.0 / SUM(COUNT(e.id)) OVER (), 1) as percentage
FROM patients p
JOIN encounters e
ON p.id = e.patient_id
GROUP BY age_group 
ORDER BY encounter_count DESC;

/* 55.7% of encounters where for 76+ age group */

/*  


	Patient Utilization 
	
	1️ - Top 10 most visited and least 10 visited patients.
	2️ - Encounter count by patient visits
	3️ - Percentage of single vs repeat visits
	4️ - Average, min and max utilisation stats
	5 - top patients


*/

-- Creating a temp table for patient data

CREATE TEMP TABLE patient_visits as
SELECT
	patient_id,
	count(*) as encounter_count
FROM
	encounters
GROUP BY
	patient_id;

	
-- how frequently did each patient visit (top 10 and bottom 10)

WITH PATIENT_RANK AS (
	SELECT
		patient_id,
		encounter_count,
		--RANK() OVER (ORDER BY encounter_count) as bottom_10,
		RANK() OVER (ORDER BY encounter_count DESC) as top_10
	from 
		patient_visits
)
SELECT 
	*
FROM 
	PATIENT_RANK
WHERE
	top_10 <= 10
	--top_10 <=10 OR bottom_10 <=10
ORDER BY top_10 asc;

/*

	highest visits were 1381 and 887
	top visits were 1

*/

WITH PATIENT_RANK AS (
	SELECT
		patient_id,
		encounter_count,
		RANK() OVER (ORDER BY encounter_count DESC) as top_10
	from 
		patient_visits
)
SELECT 
	*
FROM PATIENT_RANK
ORDER BY top_10 asc
LIMIT 10;
--WHERE
	--top_10 <= 10
	--top_10 <=10 OR bottom_10 <=10
--

SELECT *
from patient_visits
order by encounter_count DESC
limit 10;

-- Patients to encounter distribution using sub query
SELECT 
	encounter_count,
	COUNT(*) AS number_of_patients
FROM
(
    SELECT patient_id, 
	COUNT(*) AS encounter_count
    FROM encounters
    GROUP BY patient_id
) t
GROUP BY encounter_count
ORDER BY encounter_count
LIMIT 10;

/*
	highest count is a single visit (120),
	falls dramatically to 50, and 40 
*/


-- checking distribution using temp table

SELECT 
    encounter_count,
    COUNT(*) AS number_of_patients
FROM patient_visits
GROUP BY encounter_count
ORDER BY encounter_count;

/*
	highest number of patients visited only once

*/


-- checking single or multiple visits and percentage that fall into both

SELECT
    COUNT(*) FILTER (WHERE encounter_count = 1) AS single_visit_patients,
    ROUND(
        COUNT(*) FILTER (WHERE encounter_count = 1) * 100.0 / COUNT(*),
        1
    ) AS single_visit_percentage,

    COUNT(*) FILTER (WHERE encounter_count > 1) AS repeat_patients,
    ROUND(
        COUNT(*) FILTER (WHERE encounter_count > 1) * 100.0 / COUNT(*),
        1
    ) AS repeat_percentage
FROM patient_visits;

/*

	120 patients visited only once which is 12.3% where as 854 patients visited more than once (87.7%)
*/

-- checking average utilisation

SELECT
    ROUND(AVG(encounter_count), 2) AS avg_encounters,
	MIN(encounter_count) AS min_encounters,
	MAX(encounter_count) AS max_encounters
FROM patient_visits;

/*
		on average patient visited 28.6 times 
*/


-- top patients
SELECT pv.*,
	   p.marital_status, p.race, p.ethnicity, p.gender, EXTRACT(YEAR FROM birthdate) AS birth_year
FROM patient_visits pv
JOIN patients p on
pv.patient_id = p.id
ORDER BY encounter_count DESC
LIMIT 10;

/* Encounters Analysis

1) overall encounters
2) overall encounters by year
3) encounters by year and encounterclass
4) encounters less than and over 24 hours

*/


-- 1 - overall encounters 

SELECT
    COUNT(*) AS total_encounters
FROM encounters

-- total encounters 27891

-- 2 - overall encounters by year

SELECT
    EXTRACT(YEAR FROM start_time) AS year,
    COUNT(*) AS total_encounters
FROM encounters
WHERE 
	start_time < '2022-01-01'
GROUP BY year
ORDER BY year;

-- data for 2022 was excluded because it wasn't the complete data (only up till Feb)


-- 3 - encounter by class


-- table pivot used to better layout the data
SELECT
    EXTRACT(YEAR FROM start_time) AS year,

    COUNT(*) FILTER (WHERE encounterclass = 'ambulatory') AS ambulatory,
    COUNT(*) FILTER (WHERE encounterclass = 'outpatient') AS outpatient,
    COUNT(*) FILTER (WHERE encounterclass = 'inpatient') AS inpatient,
    COUNT(*) FILTER (WHERE encounterclass = 'emergency') AS emergency,
    COUNT(*) FILTER (WHERE encounterclass = 'urgentcare') AS urgentcare,
    COUNT(*) FILTER (WHERE encounterclass = 'wellness') AS wellness

FROM encounters
GROUP BY year
ORDER BY year;

-- using a case statement
SELECT
    EXTRACT(YEAR FROM start_time) AS year,

	SUM(CASE WHEN encounterclass = 'ambulatory' then 1 else 0 end) as ambulatory,
	SUM(CASE WHEN encounterclass = 'outpatient' then 1 else 0 end) as outpatient,
	SUM(CASE WHEN encounterclass = 'inpatient' then 1 else 0 end) as inpatient,
	SUM(CASE WHEN encounterclass = 'wellness' then 1 else 0 end) as wellness,
	SUM(CASE WHEN encounterclass = 'urgentcare' then 1 else 0 end) as urgentcare,
	SUM(CASE WHEN encounterclass = 'emergency' then 1 else 0 end) as emergency

FROM encounters
GROUP BY year
ORDER BY year;

-- converting the above table into percentage
SELECT
    EXTRACT(YEAR FROM start_time) AS year,

    ROUND(COUNT(*) FILTER (WHERE encounterclass = 'ambulatory') * 100.0 / COUNT(*), 1) AS ambulatory,
	ROUND(COUNT(*) FILTER (WHERE encounterclass = 'outpatient') * 100.0 / COUNT(*), 1) AS outpatient,
	ROUND(COUNT(*) FILTER (WHERE encounterclass = 'inpatient') * 100.0 / COUNT(*), 1) AS inpatient,
   	ROUND(COUNT(*) FILTER (WHERE encounterclass = 'emergency') * 100.0 / COUNT(*), 1) AS emergency,
    ROUND(COUNT(*) FILTER (WHERE encounterclass = 'urgentcare') * 100.0 / COUNT(*), 1) AS urgentcare,
    ROUND(COUNT(*) FILTER (WHERE encounterclass = 'wellness') * 100.0 / COUNT(*), 1) AS wellness
   
FROM encounters
GROUP BY year
ORDER BY year;

/*

	highest percentage are of ambulatory class
*/


--- 4) encounters less than or more than 24 hours


SELECT
    CASE 
        WHEN (end_time - start_time) < INTERVAL '24 hours' THEN 'under_24'
        ELSE 'over_24'
    END AS duration_group,
    COUNT(*) AS total_encounters,
	ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
	
FROM encounters
GROUP BY duration_group;

/*

	95% of the encounters are under 24 hours, this means most cases are same day
	4% only are over 24 hours ()
*/

/*   COST AND COVERAGE ANALYSIS */


/*   1) ZERO PAYER COVERAGE


	How many encounters had zero payer coverage, and what % of total is that? 


*/

-- geting count of all records where payer_coverage is 0
SELECT COUNT(*)
FROM encounters
where payer_coverage = 0.00;  -- 13586

-- geting total count of encounters
SELECT COUNT(*)
FROM encounters;  -- 27891

-- payer coverage 0 to more than 0

SELECT
    COUNT(*) FILTER (WHERE payer_coverage = 0) AS zero_coverage, --13586
    COUNT(*) FILTER (WHERE payer_coverage > 0) AS covered   -- 14305
FROM encounters;

-- getting percentage of zero pay_coverage
SELECT 
	COUNT(*) AS ZERO_PERCENTAGE,
	ROUND(
		COUNT(*) * 100.0  / (SELECT COUNT(*) FROM encounters),
		2
		) as percentage_zero
FROM 
	encounters
where 
	payer_coverage = 0.00; --48.71 % of encounters have zero pay charge


-- checking which encounterclass has highest zero pay

SELECT
	encounterclass,
	COUNT(*) FILTER(WHERE payer_coverage = 0) as zero_payer,
	COUNT(*) AS TOTAL,
	ROUND (COUNT(*) FILTER(WHERE payer_coverage = 0) * 100.0 / count(*), 2) AS Percentage_zero_pay
from
	encounters
GROUP BY encounterclass
ORDER BY Percentage_zero_pay DESC;

/*

Zero payer coverage is consistently high across all encounter types, ranging from 32.7% in emergency encounters to over 50% 
in outpatient and ambulatory visits. This suggests that payer coverage in the dataset is either incomplete or that a significant 
portion of encounters are not associated with formal insurance claims.
*/


/*  */

-- GET TOTAL PROCEDURES 
SELECT 
	COUNT(*) as procedure_total
FROM
	procedures; -- 47701

-- SHOW THE TOP 10 PROCEDURES BY QUANTITY PERFORMED AND AVERAGE COST
SELECT 
	COUNT(*) as proced
	description,ure_total,
	ROUND(AVG(base_cost),2) as avg_cost
FROM
	procedures
GROUP BY description
ORDER BY procedure_total desc
LIMIT 10;

/* highest cost is ICU and coronary artery bypass grafting */
/* highest procedure is health and social care needs assessment followed by hospice care and depression screening */


-- SHOW THE TOP 10 PROCEDURES BY AVERAGE COST	
SELECT
    description,
    COUNT(*) AS procedure_count,
    ROUND(AVG(base_cost), 2) AS avg_cost
FROM procedures
GROUP BY description
ORDER BY avg_cost DESC
LIMIT 5;



-- SHOW TOTAL CLAIM 

SELECT
	p.name,
	ROUND(AVG(e.total_claim_cost), 2) as average_cost
FROM
	encounters e
	join payers p
	ON e.payer_id = p.id
GROUP BY p.name
ORDER BY average_cost DESC;


/* RE-ADMISSION ANALYSIS */


/*

	1. how many unique patients were admitted each year

*/

SELECT
	EXTRACT(YEAR FROM start_time) as Year,
	COUNT(distinct(patient_id)) Patient_Count
FROM encounters
group by Year;

/*

	2. how many unique patients were admitted each year by quarter

*/

SELECT
	CONCAT(EXTRACT(YEAR FROM start_time), ' - Q', EXTRACT(QUARTER FROM start_time)) as Year_Quarter,
	COUNT(distinct(patient_id)) Patient_Count
FROM encounters
group by Year_Quarter
--ORDER BY Year_Quarter
order by Year_Quarter
LIMIT 15;

/* 

	3. Patient re-admission data

*/

WITH pd as (
				SELECT patient_id, start_time, 
				LEAD(start_time) over (partition by patient_id order by start_time) as next_appointment
				from encounters
),

readmissions as (

					SELECT count(distinct patient_id) as readmin_patients
					from pd
					where next_appointment is not null AND next_appointment - start_time  < INTERVAL '30 days'

),

total_p as (

			SELECT COUNT(DISTINCT patient_id) as total_patients
			from encounters

)

SELECT readmin_patients, total_patients,
	   ROUND(readmin_patients * 100 / total_patients,2) as percentage_readmission
from readmissions, total_p;


/*  inpatient only re-admission */

WITH inpatient_visits AS (
    SELECT
        patient_id,
        start_time
    FROM encounters
    WHERE encounterclass = 'inpatient'
),

patient_visits AS (
    SELECT
        patient_id,
        start_time,
        LEAD(start_time) OVER (
            PARTITION BY patient_id
            ORDER BY start_time
        ) AS next_start_time
    FROM inpatient_visits
),

readmission_flags AS (
    SELECT
        patient_id,
        CASE
            WHEN next_start_time IS NOT NULL
             AND next_start_time - start_time  <= INTERVAL '30 days'
            THEN 1
            ELSE 0
        END AS is_readmission
    FROM patient_visits
),

patient_level AS (
    SELECT
        patient_id,
        MAX(is_readmission) AS had_readmission
    FROM readmission_flags
    GROUP BY patient_id
)

SELECT
    COUNT(*) AS total_inpatient_patients,
    SUM(had_readmission) AS patients_with_readmission,
    ROUND(
        SUM(had_readmission) * 100.0 / COUNT(*),
        2
    ) AS readmission_rate_percentage
FROM patient_level;
