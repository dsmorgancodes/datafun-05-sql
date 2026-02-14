"""dsmorgancodes_sqlite_shelter.py - Project script (example).

Author: Drew Schaffner
Date: February 13, 2026

Purpose:
- Read csv files into a SQLite database.
- SQLite does NOT have a built-in COPY-from-CSV like DuckDB.
  We create tables using SQL, then load CSV data using Python.
- Use Python to automate SQL scripts (stored in files).
- Log the pipeline process.

Paths (relative to repo root):
   SQL:  sql/sqlite/*.sql
   CSV:  data/shelter/adoption.csv
   CSV:  data/shelter/shelter.csv
   DB:   artifacts/sqlite/shelter.sqlite
"""

# === DECLARE IMPORTS ===

import csv
import logging
from pathlib import Path
import sqlite3
from typing import Final

# External (must be listed in pyproject.toml)
from datafun_toolkit.logger import get_logger, log_header

# === CONFIGURE LOGGER ONCE PER MODULE (FILE) ===

LOG: logging.Logger = get_logger("P05", level="DEBUG")

# === DECLARE GLOBAL CONSTANTS ===

ROOT_DIR: Final[Path] = Path.cwd()

DATA_DIR: Final[Path] = ROOT_DIR / "data" / "shelter"
SQL_DIR: Final[Path] = ROOT_DIR / "sql" / "sqlite"
ARTIFACTS_DIR: Final[Path] = ROOT_DIR / "artifacts" / "sqlite"
DB_PATH: Final[Path] = ARTIFACTS_DIR / "shelter.sqlite"

ADOPTION_CSV: Final[Path] = DATA_DIR / "adoption.csv"
SHELTER_CSV: Final[Path] = DATA_DIR / "shelter.csv"

# === DECLARE HELPER FUNCTION:  READ SQL FROM PATH ===


def read_sql(sql_path: Path) -> str:
    """Read a SQL file from disk.

    Every pathlib Path object has a built-in read_text() method.
    We tell it to use UTF-8 encoding so that it works on all platforms.

    Args:
        sql_path (Path): Path to the SQL file.

    Returns:
        str: The contents of the SQL file as a string.
    """
    return sql_path.read_text(encoding="utf-8")


# === DECLARE HELPER FUNCTION:  RUN SQL ACTION (NO RESULTS) ===


def run_sql_script(con: sqlite3.Connection, sql_path: Path) -> None:
    """Execute a SQL action script file (DDL or cleanup).

    SQLite uses executescript() call.

    Args:
        con (sqlite3.Connection): SQLite connection object.
        sql_path (Path): Path to the SQL file to be executed.

    Returns:
        None
    """
    LOG.info(f"RUN SQL script: {sql_path}")
    sql_text = read_sql(sql_path)
    con.executescript(sql_text)
    LOG.info(f"DONE SQL script: {sql_path}")


# === DECLARE HELPER FUNCTION:  RUN SQL QUERY (LOG RESULTS) ===


def run_sql_query(con: sqlite3.Connection, sql_path: Path) -> None:
    """Execute a SQL query script file (SELECT or other queries that return results).

    Args:
        con (sqlite3.Connection): SQLite connection object.
        sql_path (Path): Path to the SQL file to be executed.

    Returns:
        str: The query results as a formatted string.
    """
    LOG.info("")
    LOG.info(f"RUN SQL query: {sql_path}")
    sql_text = read_sql(sql_path)

    result = con.execute(sql_text)
    rows = result.fetchall()
    columns = [col[0] for col in result.description]

    LOG.info("====================================")
    LOG.info(sql_path.name)
    LOG.info("====================================")
    LOG.info(", ".join(columns))

    for row in rows:
        LOG.info(", ".join(str(value) for value in row))


# ============================================================
# HELPER: LOAD CSV DATA INTO SQLITE TABLES
# ============================================================


def load_shelter_csv(con: sqlite3.Connection, csv_path: Path) -> None:
    """Load shelter.csv into the shelter table."""
    LOG.info("LOAD CSV -> table shelter: %s", csv_path)

    with csv_path.open(mode="r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)

        rows = []
        for r in reader:
            rows.append(
                (
                    r["shelter_id"],
                    r["shelter_name"],
                    r["city"],
                    int(r["capacity"]),
                )
            )

    con.executemany(
        """
        INSERT INTO shelter (shelter_id, shelter_name, city, capacity)
        VALUES (?, ?, ?, ?);
        """,
        rows,
    )

    LOG.info("DONE loading shelter rows: %d", len(rows))


def load_adoption_csv(con: sqlite3.Connection, csv_path: Path) -> None:
    """Load adoption.csv into the adoption table."""
    LOG.info("LOAD CSV -> table adoption: %s", csv_path)

    with csv_path.open(mode="r", encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)

        rows = []
        for r in reader:
            rows.append(
                (
                    r["adoption_id"],
                    r["shelter_id"],
                    r["animal_type"],
                    r["outcome"],
                    float(r["fee"]),
                    r["adopt_date"],
                )
            )

    con.executemany(
        """
        INSERT INTO adoption (adoption_id, shelter_id, animal_type, outcome, fee, adopt_date)
        VALUES (?, ?, ?, ?, ?, ?);
        """,
        rows,
    )

    LOG.info("DONE loading adoption rows: %d", len(rows))


def main() -> None:
    """Run the pipeline."""
    log_header(LOG, "P05 Pipeline Example (SQLite)")

    LOG.info("START main()")
    LOG.info(f"ROOT_DIR: {ROOT_DIR}")
    LOG.info(f"DATA_DIR: {DATA_DIR}")
    LOG.info(f"SQL_DIR: {SQL_DIR}")
    LOG.info(f"DB_PATH: {DB_PATH}")

    # Make sure the artifacts directory exists
    ARTIFACTS_DIR.mkdir(parents=True, exist_ok=True)

    # Open a SQLite connection
    con = sqlite3.connect(str(DB_PATH))

    try:
        # ----------------------------------------------------
        # STEP 0: Set up SQLite Settings/PRAGMAs (pragmas stands for "practical regulations")
        # ----------------------------------------------------
        # Enforce foreign keys in SQLite (off by default).
        con.execute("PRAGMA foreign_keys = ON;")

        # ----------------------------------------------------
        # STEP 1: CLEAN (optional, common practice during development)
        # ----------------------------------------------------
        run_sql_script(con, SQL_DIR / "dsmorgancodes_shelter_clean.sql")

        # ----------------------------------------------------
        # STEP 2: BOOTSTRAP (create tables, load CSV data)
        # ----------------------------------------------------
        run_sql_script(con, SQL_DIR / "dsmorgancodes_shelter_bootstrap.sql")
        load_shelter_csv(con, SHELTER_CSV)
        load_adoption_csv(con, ADOPTION_CSV)
        con.commit()
        LOG.info("COMMIT: data load complete")

        # ----------------------------------------------------
        # STEP 3: RUN BASIC QUERIES
        # ----------------------------------------------------
        run_sql_query(con, SQL_DIR / "dsmorgancodes_shelter_query_adoption_count.sql")
        run_sql_query(
            con, SQL_DIR / "dsmorgancodes_shelter_query_adoptions_aggregate.sql"
        )
        run_sql_query(
            con, SQL_DIR / "dsmorgancodes_shelter_query_adoptions_by_animal_type.sql"
        )
        run_sql_query(con, SQL_DIR / "dsmorgancodes_shelter_query_shelter_count.sql")

        # ----------------------------------------------------
        # STEP 4: RUN KPI QUERY (ACTION-DRIVEN)
        # ----------------------------------------------------
        run_sql_query(
            con, SQL_DIR / "dsmorgancodes_shelter_query_kpi_adoption_fees.sql"
        )

    finally:
        # Regardless of success or failure, always close the connection
        con.close()

    LOG.info("END main()")


# === CONDITIONAL EXECUTION GUARD ===

if __name__ == "__main__":
    main()
