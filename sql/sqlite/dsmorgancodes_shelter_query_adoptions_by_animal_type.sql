-- sql/sqlite/dsmorgancodes_shelter_query_adoptions_by_animal_type.sql
-- ============================================================
-- PURPOSE
-- ============================================================
-- Group shelter outcomes by animal type to understand volume and fees.
--
-- This query answers:
-- - How many outcome records do we have per animal type?
-- - How many are true adoptions vs other outcomes?
-- - What are total and average fees per animal type?
--
-- NOTE:
-- We treat "Adoption" as the adopted outcome and keep all outcomes
-- in the grouped view for context.

SELECT
  a.animal_type,
  COUNT(*) AS total_outcomes,
  SUM(CASE WHEN a.outcome = 'Adoption' THEN 1 ELSE 0 END) AS adoption_count,
  SUM(CASE WHEN a.outcome <> 'Adoption' THEN 1 ELSE 0 END) AS non_adoption_count,
  ROUND(SUM(a.fee), 2) AS total_fees,
  ROUND(
    AVG(CASE WHEN a.outcome = 'Adoption' THEN a.fee END),
    2
  ) AS avg_adoption_fee
FROM adoption AS a
GROUP BY
  a.animal_type
ORDER BY
  adoption_count DESC,
  total_fees DESC,
  a.animal_type ASC;
