--1. 
--1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count) AS total_claims
FROM prescription
GROUP BY npi
ORDER BY total_claims DESC
LIMIT 5;
--1a RESULT: nbi 1881634483, total_claims 99707


--1b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
SELECT prescriber.npi, 
       prescriber.nppes_provider_first_name, 
       prescriber.nppes_provider_last_org_name, 
       prescriber.specialty_description, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
GROUP BY prescriber.npi, 
         prescriber.nppes_provider_first_name, 
         prescriber.nppes_provider_last_org_name, 
         prescriber.specialty_description
ORDER BY total_claims DESC
LIMIT 5;
--1b RESULT: npi 1881634483, BRUCE, PENDLEY, Family Practice, 99707 claims


--2. 
--2a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
GROUP BY specialty_description
ORDER BY total_claims DESC
LIMIT 5;
--2a RESULT: Family Practice, 9752347 claims


--2b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count) AS opioid_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY opioid_claims DESC
LIMIT 5;
--2b RESULT: Nurse Practitioner, 900845 claims


--2c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT specialty_description AS specialty_without_prescriptions
FROM prescriber
WHERE specialty_description NOT IN (
    SELECT DISTINCT specialty_description
    FROM prescriber
    JOIN prescription ON prescriber.npi = prescription.npi
    WHERE specialty_description IS NOT NULL
);
--2c RESULT: 15 specialty descriptions with no associated prescriptions


--2d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
WITH total_claims_per_specialty AS (
    SELECT specialty_description, 
           SUM(total_claim_count) AS total_claims
    FROM prescriber
    JOIN prescription ON prescriber.npi = prescription.npi
    GROUP BY specialty_description
),
opioid_claims_per_specialty AS (
    SELECT specialty_description, 
           SUM(total_claim_count) AS opioid_claims
    FROM prescriber
    JOIN prescription ON prescriber.npi = prescription.npi
    JOIN drug ON prescription.drug_name = drug.drug_name
    WHERE drug.opioid_drug_flag = 'Y'
    GROUP BY specialty_description
)
SELECT t.specialty_description, 
       t.total_claims, 
       COALESCE(o.opioid_claims, 0) AS opioid_claims, 
       ROUND(COALESCE(o.opioid_claims, 0) * 100.0 / t.total_claims, 2) AS opioid_percentage
FROM total_claims_per_specialty t
LEFT JOIN opioid_claims_per_specialty o 
ON t.specialty_description = o.specialty_description
ORDER BY opioid_percentage DESC;
--2d RESULT: 92 specialties with Case Manager/Care Coordinator having 72%


--3. 
--3a. Which drug (generic_name) had the highest total drug cost?
SELECT drug.generic_name, SUM(prescription.total_drug_cost) AS total_cost 
FROM prescription 
JOIN drug ON prescription.drug_name = drug.drug_name 
GROUP BY drug.generic_name 
ORDER BY total_cost DESC
LIMIT 5;
--3a RESULT INSULIN GLARGINE,HUM.REC.ANLOG at 104264066.35


--3b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT drug.generic_name, 
       ROUND(SUM(prescription.total_drug_cost) / NULLIF(SUM(prescription.total_day_supply), 0), 2) AS cost_per_day
FROM prescription
JOIN drug ON prescription.drug_name = drug.drug_name
GROUP BY drug.generic_name
ORDER BY cost_per_day DESC
LIMIT 5;
--3b RESULT: C1 ESTERASE INHIBITOR at 3495.22


--4. 
--4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT drug_name,
       CASE 
           WHEN opioid_drug_flag = 'Y' THEN 'opioid'
           WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
           ELSE 'neither'
       END AS drug_type
FROM drug
ORDER BY drug_type ASC, drug_name ASC;
--4a RESULT: 3425 rows


--4b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
    CASE 
        WHEN drug.opioid_drug_flag = 'Y' THEN 'opioid'
        WHEN drug.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
        ELSE 'neither'
    END AS drug_type, 
    SUM(prescription.total_drug_cost)::MONEY AS total_cost
FROM drug
JOIN prescription ON drug.drug_name = prescription.drug_name
WHERE drug.opioid_drug_flag = 'Y' OR drug.antibiotic_drug_flag = 'Y'
GROUP BY drug_type
ORDER BY total_cost DESC;
--4b RESULT More on opioids at $105,080,626.37


--5. 
--5a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
--Count of CBSAs
SELECT DISTINCT cbsa.cbsa, 
       cbsa.cbsaname AS cbsaname_in_TN
FROM cbsa
JOIN fips_county ON cbsa.fipscounty = fips_county.fipscounty
WHERE fips_county.state = 'TN';
--5a RESULTS: counted 10 CBSAs

--List of names:
SELECT DISTINCT cbsa.cbsa, 
       cbsa.cbsaname AS cbsaname_in_TN
FROM cbsa
JOIN fips_county ON cbsa.fipscounty = fips_county.fipscounty
WHERE fips_county.state = 'TN'
ORDER BY cbsa.cbsaname;
--5a RESULTS: 10 rows


--5b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
--Largest population
SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
JOIN population ON cbsa.fipscounty = population.fipscounty
JOIN fips_county ON cbsa.fipscounty = fips_county.fipscounty
WHERE fips_county.state = 'TN'
GROUP BY cbsa.cbsaname
ORDER BY total_population DESC
LIMIT 5;
--5b RESULT for largest: Nashville-Davidson-Murfreesboro-Franklin, TN with 1830410

--Smallest population
SELECT cbsa.cbsaname, SUM(population.population) AS total_population
FROM cbsa
JOIN population ON cbsa.fipscounty = population.fipscounty
JOIN fips_county ON cbsa.fipscounty = fips_county.fipscounty
WHERE fips_county.state = 'TN'
GROUP BY cbsa.cbsaname
ORDER BY total_population ASC
LIMIT 5;
--5b RESULT for smallest: Morristown, TN at 116352


--5c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT fips_county.county, 
       population.population
FROM population
LEFT JOIN cbsa ON population.fipscounty = cbsa.fipscounty
LEFT JOIN fips_county ON population.fipscounty = fips_county.fipscounty
WHERE cbsa.fipscounty IS NULL
ORDER BY population.population DESC
LIMIT 5;
--5c RESULT: SEVIER county with 95523


--6. 
--6a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, 
       total_claim_count AS total_claims_greater_than_3000
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;
--6a RESULT: 9 rows with 4538 bing the most claims


--6b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT prescription.drug_name, 
       prescription.total_claim_count, 
       CASE 
           WHEN drug.opioid_drug_flag = 'Y' THEN 'Yes'
           ELSE 'No'
       END AS is_opioid
FROM prescription
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE prescription.total_claim_count >= 3000
ORDER BY is_opioid DESC, prescription.total_claim_count DESC;
--6b RESULT: 9 rows, two results are opioids


--6c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT prescription.drug_name, 
       prescription.total_claim_count, 
       CASE 
           WHEN drug.opioid_drug_flag = 'Y' THEN 'Yes'
           ELSE 'No'
       END AS is_opioid,
       prescriber.nppes_provider_first_name, 
       prescriber.nppes_provider_last_org_name
FROM prescription
JOIN drug ON prescription.drug_name = drug.drug_name
JOIN prescriber ON prescription.npi = prescriber.npi
WHERE prescription.total_claim_count >= 3000
ORDER BY is_opioid DESC, prescription.total_claim_count DESC;
--6c RESULT: 9 rows with DAVID COFFEY being the only prescriper of opiods, appearing in two rows. 


--7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.
--7a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT prescriber.npi, drug.drug_name
FROM prescriber
JOIN drug ON TRUE 
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y'
ORDER BY prescriber.npi, drug.drug_name;
--7a RESULTS: 637 rows


--7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
SELECT prescriber.npi, 
       drug.drug_name, 
       prescription.total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription ON prescriber.npi = prescription.npi 
                      AND drug.drug_name = prescription.drug_name
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC NULLS LAST, prescriber.npi, drug.drug_name;
--7b RESULTS: 637 rows


--7c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
SELECT prescriber.npi, 
       drug.drug_name, 
       COALESCE(prescription.total_claim_count, 0) AS total_claim_count
FROM prescriber
CROSS JOIN drug
LEFT JOIN prescription ON prescriber.npi = prescription.npi 
                    AND drug.drug_name = prescription.drug_name
WHERE prescriber.specialty_description = 'Pain Management'
AND prescriber.nppes_provider_city = 'NASHVILLE'
AND drug.opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC, prescriber.npi, drug.drug_name;
--7c RESULTS: 637 rows



--***BONUS QUESTIONS***BONUS QUESTIONS***BONUS QUESTIONS***BONUS QUESTIONS***BONUS QUESTIONS***

--1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT COUNT(DISTINCT prescriber.npi) AS missing_npi_count
FROM prescriber
LEFT JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescription.npi IS NULL;
-- RESULT: 4458 missing from the prescription table


-- 2.
--     2a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT drug.generic_name AS top_five_generic_names,
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE prescriber.specialty_description = 'Family Practice'
GROUP BY drug.generic_name
ORDER BY total_claims DESC
LIMIT 5;
-- RESULT: Yep, it works


--     2b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.

SELECT drug.generic_name AS top_five_generic_names, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE prescriber.specialty_description = 'Cardiology'
GROUP BY drug.generic_name 
ORDER BY total_claims DESC
LIMIT 5;


--     2c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
WITH family_practice_top5 AS (
    SELECT drug.generic_name
    FROM prescriber
    JOIN prescription ON prescriber.npi = prescription.npi
    JOIN drug ON prescription.drug_name = drug.drug_name
    WHERE prescriber.specialty_description = 'Family Practice'
    GROUP BY drug.generic_name
    ORDER BY SUM(prescription.total_claim_count) DESC
    LIMIT 5
),
cardiology_top5 AS (
    SELECT drug.generic_name
    FROM prescriber
    JOIN prescription ON prescriber.npi = prescription.npi
    JOIN drug ON prescription.drug_name = drug.drug_name
    WHERE prescriber.specialty_description = 'Cardiology'
    GROUP BY drug.generic_name
    ORDER BY SUM(prescription.total_claim_count) DESC
    LIMIT 5
)
SELECT family_practice_top5.generic_name AS common_top_drugs
FROM family_practice_top5
INTERSECT
SELECT cardiology_top5.generic_name
FROM cardiology_top5
ORDER BY common_top_drugs;
-- 2c RESULTS: two drugs were returned


--3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--3a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT prescriber.npi, 
       prescriber.nppes_provider_city AS city, 
       SUM(prescription.total_claim_count) AS top_five_total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescriber.nppes_provider_city = 'NASHVILLE'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY top_five_total_claims DESC
LIMIT 5;

	
--3b. Now, report the same for Memphis.
SELECT prescriber.npi, 
       prescriber.nppes_provider_city AS city, 
       SUM(prescription.total_claim_count) AS top_five_total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescriber.nppes_provider_city = 'MEMPHIS'
GROUP BY prescriber.npi, prescriber.nppes_provider_city
ORDER BY top_five_total_claims DESC
LIMIT 5;


--3c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
WITH ranked_prescribers AS (
    SELECT prescriber.npi, 
           prescriber.nppes_provider_city AS city, 
           SUM(prescription.total_claim_count) AS top_five_total_claims_by_city,
           RANK() OVER (PARTITION BY prescriber.nppes_provider_city ORDER BY SUM(prescription.total_claim_count) DESC) AS rank
    FROM prescriber
    JOIN prescription ON prescriber.npi = prescription.npi
    WHERE prescriber.nppes_provider_city IN ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
    GROUP BY prescriber.npi, prescriber.nppes_provider_city
)
SELECT npi, city, top_five_total_claims_by_city
FROM ranked_prescribers
WHERE rank <= 5
ORDER BY city, rank;
--3c RESULTS: 20 rows


--4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
SELECT fips_county.county, 
       overdose_deaths.overdose_deaths AS above_avg_overdose_deaths
FROM overdose_deaths
JOIN fips_county 
    ON CAST(overdose_deaths.fipscounty AS TEXT) = CAST(fips_county.fipscounty AS TEXT)
WHERE overdose_deaths.overdose_deaths > (
    SELECT AVG(overdose_deaths) FROM overdose_deaths
)
ORDER BY above_avg_overdose_deaths DESC;
--4 RESULTS: 82 rows


--5.
--5a. Write a query that finds the total population of Tennessee.
SELECT SUM(population.population) AS total_population_tn
FROM population
JOIN fips_county 
    ON CAST(population.fipscounty AS TEXT) = CAST(fips_county.fipscounty AS TEXT)
WHERE fips_county.state = 'TN';
--5a RESULT: 6597381


--5b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
WITH tn_population AS (
    SELECT SUM(population.population) AS total_population_tn
    FROM population
    JOIN fips_county 
        ON CAST(population.fipscounty AS TEXT) = CAST(fips_county.fipscounty AS TEXT)
    WHERE fips_county.state = 'TN'
)
SELECT fips_county.county, 
       population.population, 
       ROUND((population.population * 100.0) / tn_population.total_population_tn, 2) AS population_percentage
FROM population
JOIN fips_county 
    ON CAST(population.fipscounty AS TEXT) = CAST(fips_county.fipscounty AS TEXT)
JOIN tn_population ON TRUE
ORDER BY population_percentage DESC;
-- 5b RESULTS: 95 rows with SHELBY county having the highest percent of population



--***GROUPING SETS***GROUPING SETS***GROUPING SETS***GROUPING SETS***GROUPING SETS***GROUPING SETS***
-- In this set of exercises you are going to explore additional ways to group and organize the output of a query when using postgres. 
-- For the first few exercises, we are going to compare the total number of claims from Interventional Pain Management Specialists compared to those from Pain Managment specialists.

--1. Write a query which returns the total number of claims for these two groups.
SELECT prescriber.specialty_description, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY prescriber.specialty_description
ORDER BY total_claims DESC;


--2. Now, let's say that we want our output to also include the total number of claims between these two groups. Combine two queries with the UNION keyword to accomplish this.
SELECT prescriber.specialty_description, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY prescriber.specialty_description

UNION

SELECT '' AS specialty_description, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
ORDER BY total_claims DESC;


--3. Now, instead of using UNION, make use of GROUPING SETS 
SELECT prescriber.specialty_description, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
    (prescriber.specialty_description),
    ()
)
ORDER BY total_claims DESC;


--4. In addition to comparing the total number of prescriptions by specialty, let's also bring in information about the number of opioid vs. non-opioid claims by these two specialties. Modify your query (still making use of GROUPING SETS so that your output also shows the total number of opioid claims vs. non-opioid claims by these two specialites:
SELECT prescriber.specialty_description, 
       drug.opioid_drug_flag, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY GROUPING SETS (
    (prescriber.specialty_description),
    (drug.opioid_drug_flag),
    (prescriber.specialty_description, drug.opioid_drug_flag),
    ()
)
ORDER BY specialty_description NULLS LAST, opioid_drug_flag NULLS LAST;


--5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, specialty_description). How is the result different from the output from the previous query?
SELECT prescriber.specialty_description, 
       drug.opioid_drug_flag, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(drug.opioid_drug_flag, prescriber.specialty_description)
ORDER BY specialty_description NULLS LAST, opioid_drug_flag NULLS LAST;


--6. Switch the order of the variables inside the ROLLUP. That is, use ROLLUP(specialty_description, opioid_drug_flag). How does this change the result?
SELECT prescriber.specialty_description, 
       drug.opioid_drug_flag, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY ROLLUP(prescriber.specialty_description, drug.opioid_drug_flag)
ORDER BY specialty_description NULLS LAST, opioid_drug_flag NULLS LAST;


--7. Finally, change your query to use the CUBE function instead of ROLLUP. How does this impact the output?
SELECT prescriber.specialty_description, 
       drug.opioid_drug_flag, 
       SUM(prescription.total_claim_count) AS total_claims
FROM prescriber
JOIN prescription ON prescriber.npi = prescription.npi
JOIN drug ON prescription.drug_name = drug.drug_name
WHERE prescriber.specialty_description IN ('Interventional Pain Management', 'Pain Management')
GROUP BY CUBE(prescriber.specialty_description, drug.opioid_drug_flag)
ORDER BY specialty_description NULLS LAST, opioid_drug_flag NULLS LAST;


--8. In this question, your goal is to create a pivot table showing for each of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), the total claim count for each of six common types of opioids: Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl.
SELECT * FROM crosstab(
    $$
    SELECT 
        CASE 
            WHEN LOWER(prescriber.nppes_provider_city) LIKE '%nashville%' THEN 'Nashville'
            WHEN LOWER(prescriber.nppes_provider_city) LIKE '%memphis%' THEN 'Memphis'
            WHEN LOWER(prescriber.nppes_provider_city) LIKE '%knoxville%' THEN 'Knoxville'
            WHEN LOWER(prescriber.nppes_provider_city) LIKE '%chattanooga%' THEN 'Chattanooga'
            ELSE 'Other'
        END AS city,
        CASE 
            WHEN drug.generic_name ILIKE '%Codeine%' THEN 'Codeine'
            WHEN drug.generic_name ILIKE '%Fentanyl%' THEN 'Fentanyl'
            WHEN drug.generic_name ILIKE '%Hydrocodone%' THEN 'Hydrocodone'
            WHEN drug.generic_name ILIKE '%Morph%' THEN 'Morphine'
            WHEN drug.generic_name ILIKE '%Oxycod%' THEN 'Oxycodone'
            WHEN drug.generic_name ILIKE '%Oxymor%' THEN 'Oxymorphone'
            ELSE 'Other'
        END AS opioid_category,
        SUM(prescription.total_claim_count) AS total_claims
    FROM prescriber
    JOIN prescription ON prescriber.npi = prescription.npi
    JOIN drug ON prescription.drug_name = drug.drug_name
    WHERE LOWER(prescriber.nppes_provider_city) SIMILAR TO '%(nashville|memphis|knoxville|chattanooga)%'
      AND LOWER(drug.opioid_drug_flag) IN ('y', 'yes', '1')
    GROUP BY city, opioid_category
    ORDER BY city, opioid_category
    $$,
    $$ SELECT unnest(ARRAY['Codeine', 'Fentanyl', 'Hydrocodone', 'Morphine', 'Oxycodone', 'Oxymorphone']) $$
) 
AS pivot_table (
    city TEXT,
    codeine INTEGER,
    fentanyl INTEGER,
    hydrocodone INTEGER,
    morphine INTEGER,
    oxycodone INTEGER,
    oxymorphone INTEGER
);
