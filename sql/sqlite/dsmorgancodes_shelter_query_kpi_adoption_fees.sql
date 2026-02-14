-- sql/sqlite/dsmorgancodes_shelter_query_kpi_adoption_fees.sql
-- ============================================================
-- PURPOSE
-- ============================================================
-- Calculate a shelter-domain KPI in SQLite:
-- Total adoption fees by shelter.
--
-- KPI DRIVES THE WORK:
-- We start with an actionable question:
-- "Which shelters are generating the most adoption-fee revenue?"
--
-- ACTIONABLE OUTCOMES:
-- - Identify shelters with strongest fee performance
-- - Compare fee patterns across locations
-- - Support budgeting, staffing, and outreach planning
--
-- ASSUMPTION:
-- We run SQL from the project root and query the SQLite database
-- that contains the shelter and adoption tables.
--
-- EXPECTED PROJECT PATHS (relative to repo root):
--   SQL: sql/sqlite/dsmorgancodes_shelter_query_kpi_adoption_fees.sql
--   DB:  artifacts/sqlite/shelter.sqlite
--
--
-- ============================================================
-- DOMAIN RELATIONSHIP (1:M)
-- ============================================================
-- shelter (1)  --->  adoption (M)
--
-- - shelter is the parent table (one shelter has many adoptions)
-- - adoption is the child table (each adoption belongs to one shelter)
-- - Relationship key: adoption.shelter_id = shelter.shelter_id
--
--
-- ============================================================
-- KPI DEFINITION
-- ============================================================
-- KPI NAME:
-- Adoption Fees by Shelter
--
-- KPI QUESTION:
-- "How much total adoption fee revenue did each shelter collect?"
--
-- MEASURES:
-- - adoption_count         = COUNT(adoption_id)
-- - total_adoption_fees    = SUM(fee)
-- - avg_adoption_fee       = AVG(fee)
--
-- GRAIN:
-- - one row per shelter
--
--
-- ============================================================
-- QUERY
-- ============================================================
SELECT
  s.shelter_id,
  s.shelter_name,
  s.city,
  s.capacity,
  COUNT(a.adoption_id) AS adoption_count,
  ROUND(SUM(a.fee), 2) AS total_adoption_fees,
  ROUND(AVG(a.fee), 2) AS avg_adoption_fee
FROM shelter AS s
JOIN adoption AS a
  ON a.shelter_id = s.shelter_id
GROUP BY
  s.shelter_id,
  s.shelter_name,
  s.city,
  s.capacity
ORDER BY
  total_adoption_fees DESC,
  adoption_count DESC,
  s.shelter_name ASC;
