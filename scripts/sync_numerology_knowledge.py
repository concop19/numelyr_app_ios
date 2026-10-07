#!/usr/bin/env python3
"""
Sync numerology_knowledge from Supabase to SQLite (cadao.db).
Downloads all 212 rows and inserts them into table `numerology_knowledge`.
"""
import json
import os
import sqlite3
import sys
import urllib.request

SUPABASE_URL = "https://irtppxiappokjazczdai.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImlydHBweGlhcHBva2phemN6ZGFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODczNTk2MjYsImV4cCI6MjEwMjkzNTYyNn0.NF2n5Dpd9ldG9rko09gpPmGotaaikC_waQqUNPB8BzE"

IOS_DB_PATH = "numelyra_app_ios/numelyra_app_ios/numelyra_app_ios/Resources/cadao.db"
RN_DB_PATH = "numelyra_app/assets/cadao.db"
JSON_CACHE_PATH = "numelyra_app/assets/numerology_knowledge.json"

def fetch_all_knowledge():
    print(f"Fetching rows from {SUPABASE_URL}...")
    url = f"{SUPABASE_URL}/rest/v1/numerology_knowledge?select=*&limit=1000"
    headers = {
        "apikey": SUPABASE_KEY,
        "Authorization": f"Bearer {SUPABASE_KEY}",
        "Content-Type": "application/json"
    }
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req) as resp:
        if resp.status != 200:
            raise RuntimeError(f"HTTP {resp.status}: {resp.read().decode('utf-8')}")
        data = json.loads(resp.read().decode('utf-8'))
        print(f"Fetched {len(data)} rows from Supabase.")
        return data

def save_to_sqlite(db_path: str, records: list):
    if not os.path.exists(db_path):
        print(f"Warning: {db_path} does not exist, skipping.")
        return

    print(f"Updating SQLite database at {db_path}...")
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # Create table numerology_knowledge
    cur.execute("""
    CREATE TABLE IF NOT EXISTS numerology_knowledge (
        id TEXT PRIMARY KEY,
        indicator_key TEXT NOT NULL,
        number_value TEXT NOT NULL,
        indicator_name TEXT,
        title TEXT,
        category TEXT,
        content TEXT NOT NULL,
        keywords TEXT,
        created_at TEXT
    );
    """)

    cur.execute("CREATE INDEX IF NOT EXISTS idx_nk_key_val ON numerology_knowledge(indicator_key, number_value);")
    cur.execute("CREATE INDEX IF NOT EXISTS idx_nk_key ON numerology_knowledge(indicator_key);")

    # Upsert rows
    for r in records:
        keywords_str = json.dumps(r.get("keywords", []), ensure_ascii=False) if isinstance(r.get("keywords"), list) else str(r.get("keywords") or "")
        cur.execute("""
        INSERT INTO numerology_knowledge (id, indicator_key, number_value, indicator_name, title, category, content, keywords, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(id) DO UPDATE SET
            indicator_key = excluded.indicator_key,
            number_value = excluded.number_value,
            indicator_name = excluded.indicator_name,
            title = excluded.title,
            category = excluded.category,
            content = excluded.content,
            keywords = excluded.keywords,
            created_at = excluded.created_at;
        """, (
            r.get("id"),
            r.get("indicator_key"),
            str(r.get("number_value")),
            r.get("indicator_name"),
            r.get("title"),
            r.get("category"),
            r.get("content"),
            keywords_str,
            r.get("created_at")
        ))

    conn.commit()
    cur.execute("SELECT count(*) FROM numerology_knowledge;")
    count = cur.fetchone()[0]
    print(f"Successfully saved {count} rows into {db_path}.")
    conn.close()

def main():
    records = fetch_all_knowledge()
    
    # Save a JSON backup
    os.makedirs(os.path.dirname(JSON_CACHE_PATH), exist_ok=True)
    with open(JSON_CACHE_PATH, "w", encoding="utf-8") as f:
        json.dump(records, f, ensure_ascii=False, indent=2)
    print(f"Saved backup to {JSON_CACHE_PATH}.")

    # Save to both cadao.db locations
    save_to_sqlite(IOS_DB_PATH, records)
    save_to_sqlite(RN_DB_PATH, records)

if __name__ == "__main__":
    main()
