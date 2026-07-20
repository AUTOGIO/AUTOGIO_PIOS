-- PIOS UniFi Network Intelligence schema (SQLite)
PRAGMA journal_mode=WAL;

CREATE TABLE IF NOT EXISTS meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS samples (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts INTEGER NOT NULL,
  wan_uptime_pct REAL,
  wan_peak_down_pct REAL,
  wan_peak_up_pct REAL,
  wan_down_cap_mbps INTEGER,
  wan_up_cap_mbps INTEGER,
  client_count INTEGER,
  wireless_count INTEGER,
  ap_count INTEGER,
  gateway_cpu_pct REAL,
  gateway_mem_pct REAL,
  raw_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_samples_ts ON samples(ts);

CREATE TABLE IF NOT EXISTS clients (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sample_id INTEGER NOT NULL REFERENCES samples(id) ON DELETE CASCADE,
  ts INTEGER NOT NULL,
  mac TEXT,
  hostname TEXT,
  ip TEXT,
  essid TEXT,
  is_wired INTEGER,
  rssi INTEGER,
  rx_bytes INTEGER,
  tx_bytes INTEGER
);

CREATE INDEX IF NOT EXISTS idx_clients_ts ON clients(ts);
CREATE INDEX IF NOT EXISTS idx_clients_mac_ts ON clients(mac, ts);

CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ts INTEGER NOT NULL,
  kind TEXT NOT NULL,
  severity TEXT,
  message TEXT,
  payload_json TEXT
);

CREATE INDEX IF NOT EXISTS idx_events_ts ON events(ts);

INSERT OR IGNORE INTO meta(key, value) VALUES ('schema_version', '1');
