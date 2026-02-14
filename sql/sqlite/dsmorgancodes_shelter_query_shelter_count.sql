-- sql/sqlite/dsmorgancodes_shelter_query_shelter_count.sql
-- ============================================================
-- PURPOSE
-- ============================================================
-- Count the total number of shelters in the shelter domain.
--
-- This query answers:
-- - "How many shelters are in the system?"
--
-- WHY:
-- - Provides a quick baseline for the parent table in the 1:M model.
-- - Helps validate expected row volume after bootstrap/clean steps.

SELECT
  COUNT(*) AS shelter_count
FROM shelter;
