-- sql/sqlite/dsmorgancodes_shelter_query_adoption_count.sql
-- ============================================================
-- PURPOSE
-- ============================================================
-- Return the total number of adoption records in the shelter domain.
--
-- This provides a quick row-count check for the dependent/child table
-- and is useful for validating data load completeness.

SELECT
  COUNT(*) AS adoption_count
FROM adoption;
