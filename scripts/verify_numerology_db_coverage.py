#!/usr/bin/env python3
"""
verify_numerology_db_coverage.py
Analyzes the coverage of numerology_knowledge in cadao.db against the 24 numerology indicators.
"""
import sqlite3
import os
import sys

DB_PATH = "numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Resources/cadao.db"

# Expected domain of possible values for each indicator according to NumerologyEngine
EXPECTED_INDICATOR_DOMAINS = {
    # 1. Core
    "walksOfLife": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "22", "22/4", "33/6"],
    "mission": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "11", "22", "33"],
    "soul": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "11", "22", "33"],
    "personality": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "11", "22", "33"],
    "dateOfBirth": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "22"],
    
    # 2. Potential
    "mature": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "11", "22", "33"],
    "balance": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
    "rationalThinking": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "11", "22"],
    "subconsciousPower": ["3", "4", "5", "6", "7", "8", "9"],
    "passion": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
    "attitude": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],

    # 3. Karmic
    "karmicDebts": ["13/4", "14/5", "16/7", "19/1"],
    "missingNumbers": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],

    # 4. Bridges
    "bridgeLifeMission": ["0", "1", "2", "3", "4", "5", "6", "7", "8"],
    "bridgeSoulPersonality": ["0", "1", "2", "3", "4", "5", "6", "7", "8"],
    "bridgeMaturityPassion": ["0", "1", "2", "3", "4", "5", "6", "7", "8"],

    # 5. Cycles
    "yearIndividual": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
    "monthIndividual": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
    "dayIndividual": ["1", "2", "3", "4", "5", "6", "7", "8", "9"],
    "way": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11"],
    "challenges": ["0", "1", "2", "3", "4", "5", "6", "7", "8"],

    # 6. Charts
    "arrows": ["1-2-3", "1-4-7", "1-5-9", "2-5-8", "3-5-7", "3-6-9", "4-5-6", "7-8-9"],
    "nameChart": ["matrix"],
    "birthChart": ["matrix"],
}

def verify_coverage(db_path: str):
    if not os.path.exists(db_path):
        print(f"Error: Database not found at {db_path}")
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Check tables
    cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = [t[0] for t in cur.fetchall()]
    print(f"Tables in {db_path}: {tables}")
    if "numerology_knowledge" not in tables:
        print("ERROR: numerology_knowledge table missing!")
        sys.exit(1)

    cur.execute("SELECT count(*) FROM numerology_knowledge;")
    total_records = cur.fetchone()[0]
    print(f"Total numerology_knowledge records: {total_records}")

    print("\n" + "="*80)
    print(f"{'Indicator Key':<24} | {'Expected':<8} | {'Covered':<8} | {'Rate':<7} | {'Status':<10} | {'Missing/Notes'}")
    print("="*80)

    total_expected = 0
    total_covered = 0

    for key, expected_vals in EXPECTED_INDICATOR_DOMAINS.items():
        cur.execute("SELECT number_value FROM numerology_knowledge WHERE indicator_key = ?;", (key,))
        db_vals = set(row[0] for row in cur.fetchall())

        covered = []
        missing = []

        for val in expected_vals:
            # Check direct match
            if val in db_vals:
                covered.append(val)
            elif key == "walksOfLife" and val == "22" and "22/4" in db_vals:
                covered.append("22 (as 22/4)")
            else:
                missing.append(val)

        count_exp = len(expected_vals)
        count_cov = len(covered)
        rate = (count_cov / count_exp * 100) if count_exp > 0 else 0
        status = "FULL" if count_cov == count_exp else f"PARTIAL ({count_cov}/{count_exp})"

        total_expected += count_exp
        total_covered += count_cov

        missing_str = ", ".join(missing) if missing else "None (100%)"
        print(f"{key:<24} | {count_exp:<8} | {count_cov:<8} | {rate:>5.1f}% | {status:<10} | {missing_str}")

    print("="*80)
    overall_rate = (total_covered / total_expected * 100) if total_expected > 0 else 0
    print(f"OVERALL COVERAGE: {total_covered}/{total_expected} ({overall_rate:.1f}%)\n")

    conn.close()
    return overall_rate

if __name__ == "__main__":
    verify_coverage(DB_PATH)
