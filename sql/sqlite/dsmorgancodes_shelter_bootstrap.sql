-- sql/sqlite/dsmorgancodes_shelter_bootstrap.sql
-- ============================================================
-- PURPOSE
-- ============================================================
-- Creates shelter-domain tables for SQLite.
-- This bootstrap step builds the relational schema from scratch
-- for the shelter analytics workflow.
--
-- ASSUMPTION:
-- We always run all commands from the project root directory.
--
-- EXPECTED PROJECT PATHS (relative to repo root):
--   SQL:  sql/sqlite/dsmorgancodes_shelter_bootstrap.sql
--   CSV:  data/shelter/shelter.csv
--   CSV:  data/shelter/adoption.csv
--   DB:   artifacts/sqlite/shelter.sqlite
--
--
-- ============================================================
-- TOPIC DOMAIN + 1:M RELATIONSHIP
-- ============================================================
-- OUR DOMAIN: SHELTER
-- The two tables are related in a one-to-many relationship (1:M):
-- - shelter  (1): independent/parent table
-- - adoption (M): dependent/child table
--
-- FOREIGN KEY RELATIONSHIP:
-- - adoption.shelter_id references shelter.shelter_id
--
-- REQ: Create parent table first, then child table.
--
--
-- ============================================================
-- EXECUTION: ATOMIC BOOTSTRAP (ALL OR NOTHING)
-- ============================================================
-- Use a transaction so either all create steps succeed or none do.
BEGIN TRANSACTION;
--
--
-- ============================================================
-- STEP 1: CREATE TABLES (PARENT FIRST, THEN CHILD)
-- ============================================================
-- Create the independent/parent table first.
CREATE TABLE IF NOT EXISTS shelter (
  shelter_id TEXT PRIMARY KEY,
  shelter_name TEXT NOT NULL,
  city TEXT NOT NULL,
  capacity INTEGER NOT NULL
);

-- Create the dependent/child table second.
CREATE TABLE IF NOT EXISTS adoption (
  adoption_id TEXT PRIMARY KEY,
  shelter_id TEXT NOT NULL,
  animal_type TEXT NOT NULL,
  outcome TEXT NOT NULL,
  fee REAL NOT NULL,
  adopt_date TEXT NOT NULL,
  FOREIGN KEY (shelter_id) REFERENCES shelter (shelter_id)
);
--
--
-- ============================================================
-- STEP 2: OPTIONAL INDEXES (PERFORMANCE)
-- ============================================================
-- Index child foreign key for faster joins/grouping by shelter.
CREATE INDEX IF NOT EXISTS idx_adoption_shelter_id
  ON adoption (shelter_id);

-- Index frequently grouped/filter columns.
CREATE INDEX IF NOT EXISTS idx_adoption_animal_type
  ON adoption (animal_type);

CREATE INDEX IF NOT EXISTS idx_adoption_outcome
  ON adoption (outcome);

CREATE INDEX IF NOT EXISTS idx_adoption_adopt_date
  ON adoption (adopt_date);
--
--
-- ============================================================
-- FINISH EXECUTION: ATOMIC BOOTSTRAP (ALL OR NOTHING)
-- ============================================================
-- If we reach this point, all operations succeeded.
COMMIT;
--
--
-- ============================================================
-- NOTE ABOUT DATA LOADING
-- ============================================================
-- In SQLite CLI, CSV load is typically done with:
--   .mode csv
--   .import data/shelter/shelter.csv shelter
--   .import data/shelter/adoption.csv adoption
--
-- In Python scripts, data is often loaded via pandas and written using
-- sqlite3/SQLAlchemy into these same tables after bootstrap.
