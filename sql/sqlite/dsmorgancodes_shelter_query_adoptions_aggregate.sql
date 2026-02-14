-- sql/sqlite/dsmorgancodes_shelter_query_adoptions_aggregate.sql
-- ============================================================
-- PURPOSE
-- ============================================================
-- Summarize overall shelter adoption activity across ALL shelters.
--
-- This query answers:
-- - "How many adoption records do we have?"
-- - "How much total fee revenue was collected?"
-- - "What is the average adoption fee?"
--
-- WHY:
-- - Establishes system-wide performance for shelter operations
-- - Provides a baseline before breaking results down by shelter or animal type
-- - Helps answer: "Is overall adoption activity trending up or down?"

SELECT
  COUNT(*) AS adoption_count,
  ROUND(SUM(fee), 2) AS total_fee_revenue,
  ROUND(AVG(fee), 2) AS avg_adoption_fee
FROM adoption;
