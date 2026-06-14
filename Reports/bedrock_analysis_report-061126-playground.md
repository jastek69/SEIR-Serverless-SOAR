User: You are a SOC analyst assistant.

Analyze this event:
- User authenticated successfully
- JWT token issued
- Token never used within 15 minutes

Provide:
1. Severity
2. Possible explanations
3. Recommended analyst actions
4. Short executive summary

Model: # SOC Event Analysis

## 🔍 Event Summary
**Authentication succeeded → JWT issued → Token unused for 15+ minutes**

---

## 1. 🟡 Severity: **LOW to MEDIUM**
*(Warrants investigation but not immediate escalation alone)*

| Factor | Assessment |
|---|---|
| Standalone event | LOW |
| Combined with other anomalies | MEDIUM–HIGH |
| Repeated pattern across accounts | HIGH |

---

## 2. 💡 Possible Explanations

### ✅ Benign
- User authenticated but was interrupted or distracted before use
- Automated script or service obtained a token but failed/was paused before execution
- User tested login functionality without proceeding further
- Session timeout or browser closure immediately after login
- Misconfigured application fetching tokens preemptively

### ⚠️ Suspicious
- **Credential stuffing/validation** — Attacker testing stolen credentials to confirm validity without triggering further alerts
- **Token harvesting** — Token obtained for later use or exfiltration to another system
- **Reconnaissance phase** — Attacker confirming access exists before a planned attack window
- **Compromised automation** — A bot or script acquired a token but C2 communication was interrupted
- **Insider threat** — Deliberate access confirmation while avoiding detectable activity

---

## 3. 🛡️ Recommended Analyst Actions

### Immediate
```
□ Correlate with user's historical login patterns
  (Time of day, location, device, IP address)
□ Check if source IP is flagged in threat intelligence feeds
□ Verify geolocation and ASN of the authenticating IP
□ Confirm whether MFA was satisfied or bypassed
```

### Investigative
```
□ Search for other accounts authenticating from the same IP/device
□ Review prior 24–48 hours of activity for the user account
□ Check if token appeared in any downstream service logs
□ Look for lateral movement or API calls using this identity
□ Inspect user agent string for anomalies (scripted clients, etc.)
```

### If Suspicious Indicators Found
```
□ Force token revocation and session termination
□ Require re-authentication with MFA challenge
□ Temporarily lock account pending user verification
□ Escalate to Tier 2 / Threat Hunting team
□ Preserve logs for forensic chain of custody
```

---

## 4. 📋 Executive Summary

> A user account successfully authenticated and received a JWT access token, but the token was **never used during the subsequent 15-minute window**. While this may reflect normal interrupted user behavior, it is also a **recognized pattern in credential validation attacks**, where adversaries confirm that stolen credentials are active without performing visible actions. The risk is **low in isolation** but should be cross-referenced against login origin, user behavior baselines, and concurrent events across the environment. **No immediate business impact is confirmed**, but prompt investigation is advised to rule out credential compromise or pre-attack reconnaissance.

---

> ⚡ **Key Watchword:** One instance = curious. Multiple instances across accounts = active threat. Correlate broadly.
User: 5. recommended remediation explanations
Model: # Recommended Remediation Steps

## 🔧 Detailed Remediation Explanations

---

### 1. 🔑 Implement Short JWT Expiration Windows

**What:**
Reduce JWT token Time-To-Live (TTL) to the minimum operationally acceptable duration (e.g., 5–15 minutes for access tokens).

**Why:**
A token that is never used but has a long expiration window represents an **extended attack surface**. If harvested, it remains exploitable for its full lifetime.

**How:**
```yaml
# Example JWT configuration
access_token_ttl: 5m
refresh_token_ttl: 24h
token_rotation: enabled
```
> Pair short-lived access tokens with **refresh token rotation** to balance security and user experience.

---

### 2. 🚫 Token Binding & Usage Validation

**What:**
Implement server-side tracking to **flag or invalidate tokens that remain unused** beyond a defined threshold.

**Why:**
Standard JWT implementations are stateless — the server issues a token and has no native mechanism to detect non-use. Adding a usage-check layer closes this blind spot.

**How:**
```
□ Maintain a lightweight token registry (Redis/cache layer)
□ Record: issued_at, first_used_at, issuing_IP, user_agent
□ Trigger alert or auto-revoke if first_used_at = NULL after threshold
□ Compare issuing IP vs first-use IP for anomaly detection
```

> ⚠️ **Trade-off:** Introduces statefulness into a stateless architecture. Evaluate performance impact carefully.

---

### 3. 🌍 Contextual Authentication Controls

**What:**
Enforce **risk-based authentication** that evaluates context at login time before issuing tokens.

**Why:**
If the authentication event itself originates from a suspicious context (new IP, unusual location, odd hours), the token should never be issued freely in the first place.

**How:**
```
Risk Signals to Evaluate:
├── IP Reputation (threat intel feed match)
├── Geolocation anomaly (impossible travel)
├── Device fingerprint (new/unrecognized device)
├── Time-of-day deviation from baseline
├── Failed attempt history on account
└── ASN/Hosting provider (datacenter IP = higher risk)

Risk Score → Action Mapping:
├── LOW    → Issue token normally
├── MEDIUM → Require MFA step-up challenge
└── HIGH   → Block + alert + require manual review
```

---

### 4. 🔒 Enforce Multi-Factor Authentication (MFA)

**What:**
Mandate MFA for **all authentication flows** that result in JWT issuance, especially for privileged or sensitive accounts.

**Why:**
If credentials were obtained through phishing or credential stuffing, MFA acts as a **critical second barrier**. An attacker validating stolen credentials would fail at the MFA step, preventing token issuance entirely.

**How:**
```
Priority tiers for MFA enforcement:
├── Tier 1 (Immediate): Admin, privileged, service accounts
├── Tier 2 (Short-term): All external-facing user accounts
└── Tier 3 (Full rollout): All internal user accounts

Recommended MFA methods (strongest → weakest):
├── Hardware security keys (FIDO2/WebAuthn) ✅ Best
├── Authenticator app (TOTP)               ✅ Good
├── Push notification approval             ⚠️ Moderate
└── SMS OTP                                ❌ Avoid if possible
```

---

### 5. 📊 Behavioral Baseline & Anomaly Detection

**What:**
Build and continuously update **User and Entity Behavior Analytics (UEBA)** profiles to detect deviations from normal authentication and token usage patterns.

**Why:**
A single unused token may be noise. A pattern of unused tokens — or a user whose tokens are **always** used except this one time — is a meaningful signal. Baselines make the difference visible.

**How:**
```
Baseline Metrics to Track Per User:
├── Average time-to-first-token-use
├── Typical login hours and days
├── Common source IPs and locations
├── Usual device/user-agent signatures
└── Normal session duration and activity volume

Alert Conditions:
├── Token unused > X minutes (tunable threshold)
├── Login from new country/ASN
├── Login outside established hours window
├── Multiple accounts logging in from same IP
└── Sudden spike in authentication events
```

---

### 6. 🔐 Credential Hygiene & Breach Monitoring

**What:**
Proactively check if user credentials have been **exposed in known data breaches** and enforce password resets where applicable.

**Why:**
Unused tokens following successful authentication are a hallmark of **credential stuffing attacks**. If the credentials are already circulating in breach databases, the authentication event itself is suspect.

**How:**
```
□ Integrate with HaveIBeenPwned API or similar breach feed
□ Check credentials at:
   ├── Registration
   ├── Password change
   └── Periodic background sweep
□ Force password reset if breach match detected
□ Block commonly used or breached password patterns
□ Implement account lockout after N failed attempts
   (with CAPTCHA to slow automated attacks)
```

---

### 7. 📡 Enhanced Logging & SIEM Correlation Rules

**What:**
Ensure authentication and token lifecycle events are **fully logged** and that SIEM correlation rules are in place to surface this specific pattern automatically.

**Why:**
You cannot remediate what you cannot detect consistently. Manual review is not scalable — automated detection rules ensure this pattern is caught every time.

**How:**
```
Required Log Fields for JWT Events:
├── user_id / account identifier
├── token_id (jti claim)
├── issued_at timestamp
├── issuing_IP and geolocation
├── user_agent string
├── first_used_at timestamp (or NULL)
├── MFA satisfied (boolean)
└── risk_score at issuance

SIEM Rule Logic (Pseudocode):
IF token_issued
AND first_used_at = NULL
AND (now - issued_at) > 15 minutes
THEN trigger alert → assign to analyst queue

Enrich alert with:
└── IP reputation, user risk score, recent auth history
```

---

### 8. 🧪 Regular Red Team / Penetration Testing

**What:**
Periodically simulate **credential stuffing, token harvesting, and authentication abuse** scenarios against your environment.

**Why:**
Remediations that look good on paper may have gaps in practice. Red team exercises validate that controls are **actually working** and that detection rules fire as expected.

**How:**
```
Test Scenarios to Include:
├── Credential stuffing simulation (known breach list)
├── Token issuance without subsequent use
├── Token replay from different IP than issuance
├── High-volume authentication attempts
├── MFA bypass techniques (SIM swap, push fatigue)
└── JWT manipulation (algorithm confusion, claim tampering)

Cadence:
├── Full red team exercise: Annually
├── Focused auth testing: Quarterly
└── Automated scanner checks: Continuously
```

---

## 📋 Remediation Priority Matrix

| Remediation | Effort | Impact | Priority |
|---|---|---|---|
| Short JWT TTL | 🟢 Low | 🔴 High | **P1 — Immediate** |
| Enforce MFA | 🟡 Medium | 🔴 High | **P1 — Immediate** |
| SIEM Correlation Rules | 🟢 Low | 🔴 High | **P1 — Immediate** |
| Breach Credential Monitoring | 🟢 Low | 🟡 Medium | **P2 — Short-term** |
| Risk-Based Authentication | 🔴 High | 🔴 High | **P2 — Short-term** |
| Token Usage Validation | 🔴 High | 🟡 Medium | **P3 — Medium-term** |
| UEBA Behavioral Baselines | 🔴 High | 🔴 High | **P3 — Medium-term** |
| Red Team Exercises | 🟡 Medium | 🟡 Medium | **P4 — Ongoing** |

---

> 💡 **Key Principle:** No single control is sufficient. These remediations work as **layered defense-in-depth** — each layer catches what the previous one may miss. Prioritize quick wins (TTL, MFA, SIEM rules) immediately while building toward behavioral analytics over time.
User: Please provide possible code snippets and walkthroughs for number 5
Model: # UEBA Behavioral Baseline & Anomaly Detection
## Code Snippets & Walkthroughs

---

## 🏗️ Architecture Overview

```
Authentication Event
        ↓
  Event Collector
        ↓
  Feature Extractor
        ↓
  Baseline Engine ←→ Historical Data Store (Redis/DB)
        ↓
  Anomaly Scorer
        ↓
  Alert Engine → SIEM / SOC Dashboard
```

---

## 📦 Tech Stack Used in Examples
```
Language:     Python 3.10+
Cache/Store:  Redis
Database:     PostgreSQL
ML Library:   scikit-learn
Messaging:    Apache Kafka (optional)
Dashboard:    Grafana (optional)
```

---

## 1. 📊 Data Models & Schema

### Database Schema (PostgreSQL)
```sql
-- User authentication events table
CREATE TABLE auth_events (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             VARCHAR(255) NOT NULL,
    token_id            VARCHAR(255) NOT NULL,       -- JWT jti claim
    issued_at           TIMESTAMP NOT NULL,
    first_used_at       TIMESTAMP,                   -- NULL if unused
    issuing_ip          INET NOT NULL,
    issuing_country     VARCHAR(100),
    issuing_asn         VARCHAR(100),
    user_agent          TEXT,
    mfa_satisfied       BOOLEAN DEFAULT FALSE,
    risk_score          FLOAT DEFAULT 0.0,
    is_anomalous        BOOLEAN DEFAULT FALSE,
    created_at          TIMESTAMP DEFAULT NOW()
);

-- User behavioral baseline table
CREATE TABLE user_baselines (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             VARCHAR(255) NOT NULL UNIQUE,
    avg_token_use_time  FLOAT,           -- seconds to first use
    typical_hours       INTEGER[],       -- array of typical login hours [9,10,11...]
    typical_countries   TEXT[],          -- ['US', 'GB']
    known_ips           INET[],          -- known good IPs
    known_asns          TEXT[],
    known_user_agents   TEXT[],
    avg_session_count   FLOAT,           -- avg sessions per day
    last_updated        TIMESTAMP DEFAULT NOW()
);

-- Anomaly alerts table
CREATE TABLE anomaly_alerts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             VARCHAR(255) NOT NULL,
    auth_event_id       UUID REFERENCES auth_events(id),
    alert_type          VARCHAR(100),
    risk_score          FLOAT,
    details             JSONB,
    status              VARCHAR(50) DEFAULT 'open',  -- open/investigating/closed
    created_at          TIMESTAMP DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_auth_events_user_id ON auth_events(user_id);
CREATE INDEX idx_auth_events_issued_at ON auth_events(issued_at);
CREATE INDEX idx_auth_events_token_id ON auth_events(token_id);
CREATE INDEX idx_anomaly_alerts_status ON anomaly_alerts(status);
```

---

## 2. 🔧 Event Collector & Feature Extractor

```python
# event_collector.py
import hashlib
import ipaddress
from datetime import datetime
from dataclasses import dataclass, field
from typing import Optional
import geoip2.database                    # pip install geoip2
import user_agents                        # pip install user-agents

@dataclass
class AuthEvent:
    """
    Represents a single authentication event with
    extracted features for baseline analysis.
    """
    user_id:          str
    token_id:         str
    issued_at:        datetime
    issuing_ip:       str
    user_agent:       str
    mfa_satisfied:    bool
    first_used_at:    Optional[datetime] = None

    # Derived/enriched fields
    issuing_country:  Optional[str]       = None
    issuing_asn:      Optional[str]       = None
    hour_of_day:      Optional[int]       = None
    day_of_week:      Optional[int]       = None
    is_mobile:        Optional[bool]      = None
    is_bot:           Optional[bool]      = None
    ip_is_datacenter: Optional[bool]      = None
    token_use_delay:  Optional[float]     = None   # seconds to first use


class FeatureExtractor:
    """
    Enriches raw auth events with derived features
    needed for behavioral baseline comparison.
    """

    def __init__(self, geoip_db_path: str, asn_db_path: str):
        self.geo_reader = geoip2.database.Reader(geoip_db_path)
        self.asn_reader = geoip2.database.Reader(asn_db_path)

        # Known datacenter/hosting ASNs (expand as needed)
        self.datacenter_asns = {
            'AS16509',   # Amazon AWS
            'AS15169',   # Google Cloud
            'AS8075',    # Microsoft Azure
            'AS13335',   # Cloudflare
            'AS14061',   # DigitalOcean
            'AS20473',   # Vultr
        }

    def extract(self, raw_event: dict) -> AuthEvent:
        """
        Takes raw event dictionary from auth system
        and returns enriched AuthEvent object.
        """
        event = AuthEvent(
            user_id       = raw_event['user_id'],
            token_id      = raw_event['token_id'],
            issued_at     = raw_event['issued_at'],
            issuing_ip    = raw_event['issuing_ip'],
            user_agent    = raw_event['user_agent'],
            mfa_satisfied = raw_event.get('mfa_satisfied', False),
            first_used_at = raw_event.get('first_used_at'),
        )

        # ── Temporal Features ──────────────────────────────────────
        event.hour_of_day  = event.issued_at.hour
        event.day_of_week  = event.issued_at.weekday()  # 0=Mon, 6=Sun

        # ── Token Usage Delay ──────────────────────────────────────
        if event.first_used_at:
            delta = event.first_used_at - event.issued_at
            event.token_use_delay = delta.total_seconds()
        else:
            event.token_use_delay = None  # Never used

        # ── Geo Enrichment ─────────────────────────────────────────
        try:
            geo = self.geo_reader.city(event.issuing_ip)
            event.issuing_country = geo.country.iso_code
        except Exception:
            event.issuing_country = 'UNKNOWN'

        # ── ASN Enrichment ─────────────────────────────────────────
        try:
            asn = self.asn_reader.asn(event.issuing_ip)
            event.issuing_asn     = f"AS{asn.autonomous_system_number}"
            event.ip_is_datacenter = event.issuing_asn in self.datacenter_asns
        except Exception:
            event.issuing_asn      = 'UNKNOWN'
            event.ip_is_datacenter = False

        # ── User Agent Parsing ─────────────────────────────────────
        ua = user_agents.parse(event.user_agent)
        event.is_mobile = ua.is_mobile
        event.is_bot    = ua.is_bot

        return event


# ── Usage Example ──────────────────────────────────────────────────
if __name__ == "__main__":
    extractor = FeatureExtractor(
        geoip_db_path = "/path/to/GeoLite2-City.mmdb",
        asn_db_path   = "/path/to/GeoLite2-ASN.mmdb"
    )

    raw = {
        "user_id":       "user_abc123",
        "token_id":      "jwt_xyz789",
        "issued_at":     datetime(2024, 1, 15, 2, 30, 0),  # 2:30 AM
        "issuing_ip":    "198.51.100.42",
        "user_agent":    "Mozilla/5.0 ...",
        "mfa_satisfied": True,
        "first_used_at": None  # Token never used
    }

    enriched = extractor.extract(raw)
    print(f"Country:       {enriched.issuing_country}")
    print(f"ASN:           {enriched.issuing_asn}")
    print(f"Datacenter IP: {enriched.ip_is_datacenter}")
    print(f"Hour:          {enriched.hour_of_day}")
    print(f"Token unused:  {enriched.token_use_delay is None}")
```

---

## 3. 📈 Baseline Builder

```python
# baseline_engine.py
import json
import numpy as np
from datetime import datetime, timedelta
from collections import Counter
from typing import List, Optional
import psycopg2                   # pip install psycopg2-binary
import redis                      # pip install redis

class BaselineEngine:
    """
    Builds and maintains per-user behavioral baselines
    from historical authentication events.

    Baseline is recalculated on a rolling window to
    adapt to legitimate changes in user behavior.
    """

    def __init__(self, db_conn, redis_client, window_days: int = 30):
        self.db          = db_conn
        self.redis       = redis_client
        self.window_days = window_days
        self.cache_ttl   = 3600  # Cache baselines for 1 hour

    # ──────────────────────────────────────────────────────────────
    # PUBLIC: Build or refresh a user's baseline
    # ──────────────────────────────────────────────────────────────
    def build_baseline(self, user_id: str) -> dict:
        """
        Queries historical events for a user and computes
        statistical baseline across all tracked dimensions.
        Returns baseline dict and persists to DB + cache.
        """
        events = self._fetch_historical_events(user_id)

        if len(events) < 10:
            # Not enough data — return a permissive default baseline
            return self._default_baseline(user_id)

        baseline = {
            "user_id":             user_id,
            "sample_size":         len(events),
            "last_updated":        datetime.utcnow().isoformat(),

            # ── Token Usage Timing ─────────────────────────────────
            "token_use": {
                "mean_delay_seconds":   self._mean_token_delay(events),
                "std_delay_seconds":    self._std_token_delay(events),
                "unused_rate":          self._unused_token_rate(events),
            },

            # ── Temporal Patterns ──────────────────────────────────
            "temporal": {
                "typical_hours":     self._typical_hours(events),
                "typical_weekdays":  self._typical_weekdays(events),
            },

            # ── Geographic Patterns ────────────────────────────────
            "geo": {
                "known_countries":   self._known_values(events, 'issuing_country'),
                "known_asns":        self._known_values(events, 'issuing_asn'),
            },

            # ── Device / Client Patterns ───────────────────────────
            "device": {
                "known_ips":         self._known_values(events, 'issuing_ip'),
                "known_ua_hashes":   self._ua_hashes(events),
                "mobile_rate":       self._rate(events, 'is_mobile'),
            },

            # ── Session Volume ─────────────────────────────────────
            "volume": {
                "avg_daily_sessions": self._avg_daily_sessions(events),
                "std_daily_sessions": self._std_daily_sessions(events),
            }
        }

        self._persist_baseline(user_id, baseline)
        self._cache_baseline(user_id, baseline)
        return baseline

    # ──────────────────────────────────────────────────────────────
    # PUBLIC: Retrieve cached or freshly built baseline
    # ──────────────────────────────────────────────────────────────
    def get_baseline(self, user_id: str) -> dict:
        """
        Returns baseline from cache if available,
        otherwise builds fresh from database.
        """
        cached = self.redis.get(f"baseline:{user_id}")
        if cached:
            return json.loads(cached)
        return self.build_baseline(user_id)

    # ──────────────────────────────────────────────────────────────
    # PRIVATE: Data fetching
    # ──────────────────────────────────────────────────────────────
    def _fetch_historical_events(self, user_id: str) -> List[dict]:
        cutoff = datetime.utcnow() - timedelta(days=self.window_days)
        cursor = self.db.cursor()
        cursor.execute("""
            SELECT
                user_id, token_id, issued_at, first_used_at,
                issuing_ip, issuing_country, issuing_asn,
                user_agent, is_anomalous,
                EXTRACT(EPOCH FROM (first_used_at - issued_at))
                    AS token_use_delay_seconds
            FROM auth_events
            WHERE user_id = %s
              AND issued_at >= %s
              AND is_anomalous = FALSE    -- exclude known bad events
            ORDER BY issued_at DESC
        """, (user_id, cutoff))

        columns = [desc[0] for desc in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]

    # ──────────────────────────────────────────────────────────────
    # PRIVATE: Statistical calculations
    # ──────────────────────────────────────────────────────────────
    def _mean_token_delay(self, events: List[dict]) -> float:
        delays = [
            e['token_use_delay_seconds']
            for e in events
            if e['token_use_delay_seconds'] is not None
        ]
        return float(np.mean(delays)) if delays else 0.0

    def _std_token_delay(self, events: List[dict]) -> float:
        delays = [
            e['token_use_delay_seconds']
            for e in events
            if e['token_use_delay_seconds'] is not None
        ]
        return float(np.std(delays)) if delays else 0.0

    def _unused_token_rate(self, events: List[dict]) -> float:
        """What % of tokens does this user typically leave unused?"""
        unused = sum(1 for e in events if e['first_used_at'] is None)
        return unused / len(events) if events else 0.0

    def _typical_hours(self, events: List[dict]) -> List[int]:
        """Returns hours that account for 90% of this user's logins."""
        hours = [e['issued_at'].hour for e in events]
        counter = Counter(hours)
        total = len(hours)
        cumulative, typical = 0, []
        for hour, count in counter.most_common():
            typical.append(hour)
            cumulative += count
            if cumulative / total >= 0.90:
                break
        return sorted(typical)

    def _typical_weekdays(self, events: List[dict]) -> List[int]:
        days = [e['issued_at'].weekday() for e in events]
        return list(set(days))

    def _known_values(self, events: List[dict], field: str) -> List[str]:
        """Returns distinct known values for a given field."""
        return list({
            str(e[field]) for e in events
            if e.get(field) is not None
        })

    def _ua_hashes(self, events: List[dict]) -> List[str]:
        """Store hashed UA strings (privacy-preserving)."""
        import hashlib
        return list({
            hashlib.md5(
                str(e.get('user_agent', '')).encode()
            ).hexdigest()
            for e in events
        })

    def _rate(self, events: List[dict], field: str) -> float:
        values = [e.get(field) for e in events if e.get(field) is not None]
        return sum(values) / len(values) if values else 0.0

    def _avg_daily_sessions(self, events: List[dict]) -> float:
        if not events:
            return 0.0
        dates = Counter(e['issued_at'].date() for e in events)
        return float(np.mean(list(dates.values())))

    def _std_daily_sessions(self, events: List[dict]) -> float:
        if not events:
            return 0.0
        dates = Counter(e['issued_at'].date() for e in events)
        return float(np.std(list(dates.values())))

    # ──────────────────────────────────────────────────────────────
    # PRIVATE: Persistence helpers
    # ──────────────────────────────────────────────────────────────
    def _persist_baseline(self, user_id: str, baseline: dict):
        cursor = self.db.cursor()
        cursor.execute("""
            INSERT INTO user_baselines (
                user_id, avg_token_use_time, typical_hours,
                typical_countries, known_ips, known_asns, last_updated
            ) VALUES (%s, %s, %s, %s, %s, %s, NOW())
            ON CONFLICT (user_id) DO UPDATE SET
                avg_token_use_time = EXCLUDED.avg_token_use_time,
                typical_hours      = EXCLUDED.typical_hours,
                typical_countries  = EXCLUDED.typical_countries,
                known_ips          = EXCLUDED.known_ips,
                known_asns         = EXCLUDED.known_asns,
                last_updated       = NOW()
        """, (
            user_id,
            baseline['token_use']['mean_delay_seconds'],
            baseline['temporal']['typical_hours'],
            baseline['geo']['known_countries'],
            baseline['geo']['known_countries'],  # placeholder
            baseline['geo']['known_asns'],
        ))
        self.db.commit()

    def _cache_baseline(self, user_id: str, baseline: dict):
        self.redis.setex(
            f"baseline:{user_id}",
            self.cache_ttl,
            json.dumps(baseline)
        )

    def _default_baseline(self, user_id: str) -> dict:
        """
        Permissive baseline for new users with insufficient history.
        Flags less aggressively until enough data is collected.
        """
        return {
            "user_id":      user_id,
            "sample_size":  0,
            "insufficient_data": True,
            "token_use":    {"mean_delay_seconds": 300, "std_delay_seconds": 300, "unused_rate": 0.5},
            "temporal":     {"typical_hours": list(range(24)), "typical_weekdays": list(range(7))},
            "geo":          {"known_countries": [], "known_asns": []},
            "device":       {"known_ips": [], "known_ua_hashes": [], "mobile_rate": 0.5},
            "volume":       {"avg_daily_sessions": 5.0, "std_daily_sessions": 5.0},
        }
```

---

## 4. 🚨 Anomaly Scorer

```python
# anomaly_scorer.py
from dataclasses import dataclass, field
from typing import List, Tuple
import hashlib

@dataclass
class AnomalyResult:
    """
    Encapsulates the full anomaly scoring result
    for a single authentication event.
    """
    user_id:       str
    token_id:      str
    total_score:   float                       = 0.0
    risk_level:    str                         = "LOW"
    flags:         List[str]                   = field(default_factory=list)
    details:       dict                        = field(default_factory=dict)
    recommended_action: str                    = "monitor"


class AnomalyScorer:
    """
    Compares a live auth event against a user's behavioral
    baseline and produces a weighted risk score.

    Score Components (max 100 points total):
    ┌─────────────────────────────────┬────────┐
    │ Check                           │ Points │
    ├─────────────────────────────────┼────────┤
    │ Token never used                │   20   │
    │ Unusual login hour              │   15   │
    │ New country                     │   25   │
    │ New ASN / datacenter IP         │   15   │
    │ New device / user agent         │   10   │
    │ Unusual session volume          │   10   │
    │ MFA not satisfied               │   +5   │
    │ Bot-like user agent             │   +10  │
    └─────────────────────────────────┴────────┘

    Risk Levels:
    ├── LOW:      0–30
    ├── MEDIUM:  31–60
    ├── HIGH:    61–80
    └── CRITICAL: 81+
    """

    THRESHOLDS = {
        "LOW":      (0,  30),
        "MEDIUM":   (31, 60),
        "HIGH":     (61, 80),
        "CRITICAL": (81, float('inf')),
    }

    def score(self, event: 'AuthEvent', baseline: dict) -> AnomalyResult:
        result = AnomalyResult(
            user_id  = event.user_id,
            token_id = event.token_id
        )

        # Run all checks, accumulate score
        checks = [
            self._check_token_unused,
            self._check_login_hour,
            self._check_country,
            self._check_asn,
            self._check_user_agent,
            self._check_session_volume,
            self._check_mfa,
            self._check_bot_ua,
        ]

        for check in checks:
            score, flag, detail = check(event, baseline)
            if score > 0:
                result.total_score += score
                result.flags.append(flag)
                result.details[flag] = detail

        # Determine risk level
        result.risk_level = self._classify_risk(result.total_score)

        # Recommend action
        result.recommended_action = self._recommend_action(
            result.risk_level,
            result.flags
        )

        return result

    # ──────────────────────────────────────────────────────────────
    # Individual Checks
    # ──────────────────────────────────────────────────────────────

    def _check_token_unused(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """
        Core check for this use case.
        Scores higher if this user rarely leaves tokens unused.
        """
        if event.token_use_delay is not None:
            return (0, "", {})  # Token was used, no issue

        # How unusual is an unused token for this user?
        typical_unused_rate = baseline['token_use'].get('unused_rate', 0.5)

        if typical_unused_rate < 0.05:
            # User almost always uses tokens → very suspicious
            score = 20
            severity = "HIGH"
        elif typical_unused_rate < 0.20:
            # User occasionally misses → somewhat suspicious
            score = 10
            severity = "MEDIUM"
        else:
            # User often leaves tokens unused → low signal
            score = 5
            severity = "LOW"

        return (score, "TOKEN_UNUSED", {
            "severity":            severity,
            "user_typical_unused_rate": typical_unused_rate,
            "message": f"Token unused. User typically unused rate: {typical_unused_rate:.1%}"
        })

    def _check_login_hour(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """Flags logins outside the user's typical hours."""
        typical_hours = baseline['temporal'].get('typical_hours', list(range(24)))
        current_hour  = event.hour_of_day

        if current_hour in typical_hours:
            return (0, "", {})

        return (15, "UNUSUAL_LOGIN_HOUR", {
            "current_hour":  current_hour,
            "typical_hours": typical_hours,
            "message": f"Login at {current_hour}:00 — outside typical window {typical_hours}"
        })

    def _check_country(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """Flags authentication from a new country."""
        known_countries = baseline['geo'].get('known_countries', [])
        current_country = event.issuing_country

        # New user with no baseline — lower score
        if not known_countries:
            return (0, "", {})

        if current_country in known_countries:
            return (0, "", {})

        return (25, "NEW_COUNTRY", {
            "current_country": current_country,
            "known_countries": known_countries,
            "message": f"Login from new country: {current_country}"
        })

    def _check_asn(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """Flags datacenter IPs or new ASNs."""
        known_asns     = baseline['geo'].get('known_asns', [])
        current_asn    = event.issuing_asn
        score          = 0
        flags          = []

        if event.ip_is_datacenter:
            score += 10
            flags.append("datacenter_ip")

        if known_asns and current_asn not in known_asns:
            score += 5
            flags.append("new_asn")

        if score == 0:
            return (0, "", {})

        return (score, "SUSPICIOUS_ASN", {
            "current_asn":  current_asn,
            "known_asns":   known_asns,
            "flags":        flags,
            "message": f"ASN anomaly: {', '.join(flags)}"
        })

    def _check_user_agent(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """Flags unrecognized device/browser fingerprints."""
        known_ua_hashes = baseline['device'].get('known_ua_hashes', [])
        current_hash    = hashlib.md5(
            str(event.user_agent).encode()
        ).hexdigest()

        if not known_ua_hashes or current_hash in known_ua_hashes:
            return (0, "", {})

        return (10, "NEW_USER_AGENT", {
            "ua_hash":       current_hash,
            "message": "Authentication from unrecognized device/browser"
        })

    def _check_session_volume(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """
        Flags if today's session count is abnormally high.
        Requires passing today's session count in event context.
        """
        avg  = baseline['volume'].get('avg_daily_sessions', 5.0)
        std  = baseline['volume'].get('std_daily_sessions', 2.0)
        today_count = getattr(event, 'todays_session_count', None)

        if today_count is None or std == 0:
            return (0, "", {})

        z_score = (today_count - avg) / std

        if z_score > 3:
            return (10, "ABNORMAL_SESSION_VOLUME", {
                "today_count": today_count,
                "avg":         avg,
                "z_score":     round(z_score, 2),
                "message": f"Session volume {today_count} is {z_score:.1f} std devs above normal"
            })

        return (0, "", {})

    def _check_mfa(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """Adds bonus risk if MFA was not satisfied."""
        if not event.mfa_satisfied:
            return (5, "MFA_NOT_SATISFIED", {
                "message": "Token issued without MFA verification"
            })
        return (0, "", {})

    def _check_bot_ua(
        self, event, baseline
    ) -> Tuple[float, str, dict]:
        """Flags bot-like user agent strings."""
        if event.is_bot:
            return (10, "BOT_USER_AGENT", {
                "user_agent": event.user_agent,
                "message":    "User agent identified as automated/bot client"
            })
        return (0, "", {})

    # ──────────────────────────────────────────────────────────────
    # Classification & Recommendation
    # ──────────────────────────────────────────────────────────────

    def _classify_risk(self, score: float) -> str:
        for level, (low, high) in self.THRESHOLDS.items():
            if low <= score <= high:
                return level
        return "CRITICAL"

    def _recommend_action(self, risk_level: str, flags: List[str]) -> str:
        actions = {
            "LOW":      "monitor",
            "MEDIUM":   "investigate",
            "HIGH":     "alert_analyst",
            "CRITICAL": "block_and_escalate",
        }
        action = actions.get(risk_level, "monitor")

        # Override: always escalate if new country + token unused
        if "NEW_COUNTRY" in flags and "TOKEN_UNUSED" in flags:
            action = "block_and_escalate"

        return action
```

---

## 5. 📡 Alert Engine

```python
# alert_engine.py
import json
import smtplib
import logging
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

logger = logging.getLogger(__name__)


class AlertEngine:
    """
    Consumes AnomalyResult objects and routes alerts
    to appropriate channels based on risk level.

    Routing Matrix:
    ┌──────────┬──────────┬───────────┬──────────┬─────────────┐
    │ Level    │ DB Log   │ SIEM      │ Email    │ Auto-action │
    ├──────────┼──────────┼───────────┼──────────┼─────────────┤
    │ LOW      │   ✅     │   ❌      │   ❌     │ None        │
    │ MEDIUM   │   ✅     │   ✅      │   ❌     │ None        │
    │ HIGH     │   ✅     │   ✅      │   ✅     │ Flag acct   │
    │ CRITICAL │   ✅     │   ✅      │   ✅     │ Block token │
    └──────────┴──────────┴───────────┴──────────┴─────────────┘
    """

    def __init__(self, db_conn, redis_client, config: dict):
        self.db     = db_conn
        self.redis  = redis_client
        self.config = config

    def process(self, result: 'AnomalyResult', auth_event_id: str):
        """Main entry point — routes based on risk level."""

        # Always log to database
        self._log_to_db(result, auth_event_id)

        if result.risk_level in ("MEDIUM", "HIGH", "CRITICAL"):
            self._send_to_siem(result)

        if result.risk_level in ("HIGH", "CRITICAL"):
            self._send_email_alert(result)

        if result.risk_level == "CRITICAL":
            self._auto_revoke_token(result)
            self._flag_account(result)

        elif result.risk_level == "HIGH":
            self._flag_account(result)

        logger.info(
            f"Alert processed | user={result.user_id} "
            f"risk={result.risk_level} score={result.total_score:.1f} "
            f"flags={result.flags}"
        )

    # ──────────────────────────────────────────────────────────────
    # Logging & SIEM
    # ──────────────────────────────────────────────────────────────

    def _log_to_db(self, result: 'AnomalyResult', auth_event_id: str):
        cursor = self.db.cursor()
        cursor.execute("""
            INSERT INTO anomaly_alerts (
                user_id, auth_event_id, alert_type,
                risk_score, details, status
            ) VALUES (%s, %s, %s, %s, %s, 'open')
        """, (
            result.user_id,
            auth_event_id,
            result.risk_level,
            result.total_score,
            json.dumps(result.details),
        ))
        self.db.commit()

    def _send_to_siem(self, result: 'AnomalyResult'):
        """
        Sends structured CEF/JSON event to SIEM.
        Adapt endpoint/format for your SIEM (Splunk, QRadar, Sentinel).
        """
        siem_event = {
            "timestamp":   datetime.utcnow().isoformat(),
            "event_type":  "AUTH_ANOMALY",
            "user_id":     result.user_id,
            "token_id":    result.token_id,
            "risk_level":  result.risk_level,
            "risk_score":  result.total_score,
            "flags":       result.flags,
            "details":     result.details,
            "action":      result.recommended_action,
        }

        # Example: push to Redis stream (SIEM can consume)
        self.redis.xadd(
            "siem:auth_anomalies",
            {"event": json.dumps(siem_event)}
        )

        # Example: push to Splunk HEC (uncomment to use)
        # import requests
        # requests.post(
        #     self.config['splunk_hec_url'],
        #     headers={"Authorization": f"Splunk {self.config['splunk_token']}"},
        #     json={"event": siem_event}
        # )

    # ──────────────────────────────────────────────────────────────
    # Notifications
    # ──────────────────────────────────────────────────────────────

    def _send_email_alert(self, result: 'AnomalyResult'):
        msg            = MIMEMultipart('alternative')
        msg['Subject'] = f"[{result.risk_level}] Auth Anomaly — {result.user_id}"
        msg['From']    = self.config['email_from']
        msg['To']      = self.config['soc_email']

        html = f"""
        <html><body>
        <h2 style="color: {'red' if result.risk_level == 'CRITICAL' else 'orange'}">
            🚨 Authentication Anomaly Detected
        </h2>
        <table border="1" cellpadding="6">
            <tr><td><b>User</b></td><td>{result.user_id}</td></tr>
            <tr><td><b>Risk Level</b></td><td>{result.risk_level}</td></tr>
            <tr><td><b>Score</b></td><td>{result.total_score:.1f}</td></tr>
            <tr><td><b>Flags</b></td><td>{', '.join(result.flags)}</td></tr>
            <tr><td><b>Action Taken</b></td><td>{result.recommended_action}</td></tr>
        </table>
        <h3>Details</h3>
        <pre>{json.dumps(result.details, indent=2)}</pre>
        </body></html>
        """

        msg.attach(MIMEText(html, 'html'))

        with smtplib.SMTP(self.config['smtp_host'], self.config['smtp_port']) as server:
            server.sendmail(
                self.config['email_from'],
                self.config['soc_email'],
                msg.as_string()
            )

    # ──────────────────────────────────────────────────────────────
    # Automated Response Actions
    # ──────────────────────────────────────────────────────────────

    def _auto_revoke_token(self, result: 'AnomalyResult'):
        """
        Adds token to a Redis denylist.
        Auth middleware must check this list on every request.
        """
        self.redis.setex(
            f"token:revoked:{result.token_id}",
            86400,       # Keep denylist entry for 24 hours
            "revoked"
        )
        logger.warning(
            f"AUTO-REVOKED token {result.token_id} "
            f"for user {result.user_id} (score={result.total_score})"
        )

    def _flag_account(self, result: 'AnomalyResult'):
        """
        Sets an account flag in Redis.
        Login service can check this to enforce step-up auth.
        """
        self.redis.setex(
            f"account:flagged:{result.user_id}",
            3600,        # Flag lasts 1 hour — then auto-clears
            json.dumps({
                "reason":    result.flags,
                "score":     result.total_score,
                "flagged_at": datetime.utcnow().isoformat()
            })
        )
```

---

## 6. 🔄 Main Pipeline Orchestrator

```python
# pipeline.py — Ties everything together
import psycopg2
import redis
from event_collector  import FeatureExtractor
from baseline_engine  import BaselineEngine
from anomaly_scorer   import AnomalyScorer
from alert_engine     import AlertEngine

class UEBAPipeline:
    """
    Full UEBA pipeline orchestrator.
    Call process_event() for every incoming auth event.
    """

    def __init__(self, config: dict):
        # Infrastructure connections
        self.db    = psycopg2.connect(config['postgres_dsn'])
        self.redis = redis.Redis(
            host     = config['redis_host'],
            port     = config['redis_port'],
            decode_responses = True
        )

        # Pipeline components
        self.extractor = FeatureExtractor(
            geoip_db_path = config['geoip_db'],
            asn_db_path   = config['asn_db']
        )
        self.baseline  = BaselineEngine(self.db, self.redis)
        self.scorer    = AnomalyScorer()
        self.alerts    = AlertEngine(self.db, self.redis, config)

    def process_event(self, raw_event: dict) -> dict:
        """
        End-to-end processing for a single auth event.

        Flow:
        raw_event → extract features → get baseline
                 → score anomaly    → trigger alerts
                 → return result
        """

        # Step 1: Extract & enrich features
        event = self.extractor.extract(raw_event)

        # Step 2: Get user's behavioral baseline
        baseline = self.baseline.get_baseline(event.user_id)

        # Step 3: Score for anomalies
        result = self.scorer.score(event, baseline)

        # Step 4: Route alerts based on risk
        self.alerts.process(result, raw_event.get('event_id'))

        # Step 5: Periodically refresh baseline (every 50 events)
        self._maybe_refresh_baseline(event.user_id)

        return {
            "user_id":    result.user_id,
            "risk_level": result.risk_level,
            "score":      result.total_score,
            "flags":      result.flags,
            "action":     result.recommended_action,
        }

    def _maybe_refresh_baseline(self, user_id: str):
        """Refresh baseline every ~50 events per user."""
        count_key = f"event_count:{user_id}"
        count     = self.redis.incr(count_key)
        self.redis.expire(count_key, 86400)

        if count % 50 == 0:
            self.baseline.build_baseline(user_id)


# ── Entry Point / Usage Example ────────────────────────────────────
if __name__ == "__main__":
    from datetime import datetime

    config = {
        "postgres_dsn": "postgresql://user:pass@localhost:5432/ueba_db",
        "redis_host":   "localhost",
        "redis_port":   6379,
        "geoip_db":     "/path/to/GeoLite2-City.mmdb",
        "asn_db":       "/path/to/GeoLite2-ASN.mmdb",
        "email_from":   "soc-alerts@company.com",
        "soc_email":    "soc-team@company.com",
        "smtp_host":    "smtp.company.com",
        "smtp_port":    587,
    }

    pipeline = UEBAPipeline(config)

    # Simulate the exact scenario from our SOC analysis:
    # Successful auth → JWT issued → Never used
    suspicious_event = {
        "event_id":      "evt_001",
        "user_id":       "user_abc123",
        "token_id":      "jwt_xyz789",
        "issued_at":     datetime(2024, 1, 15, 2, 30, 0),   # 2:30 AM
        "first_used_at": None,                               # Never used ❗
        "issuing_ip":    "198.51.100.42",                    # Unknown IP
        "user_agent":    "python-requests/2.28.0",           # Script-like UA
        "mfa_satisfied": False,                              # No MFA ❗
    }

    result = pipeline.process_event(suspicious_event)

    print("\n" + "="*50)
    print("   UEBA PIPELINE RESULT")
    print("="*50)
    print(f"  User:        {result['user_id']}")
    print(f"  Risk Level:  {result['risk_level']}")
    print(f"  Score:       {result['score']}")
    print(f"  Flags:       {', '.join(result['flags'])}")
    print(f"  Action:      {result['action']}")
    print("="*50)

    # Expected output for this scenario:
    # ══════════════════════════════════════════════
    #    UEBA PIPELINE RESULT
    # ══════════════════════════════════════════════
    #   User:        user_abc123
    #   Risk Level:  CRITICAL
    #   Score:       65.0+
    #   Flags:       TOKEN_UNUSED, UNUSUAL_LOGIN_HOUR, NEW_COUNTRY,
    #                SUSPICIOUS_ASN, NEW_USER_AGENT, MFA_NOT_SATISFIED,
    #                BOT_USER_AGENT
    #   Action:      block_and_escalate
    # ══════════════════════════════════════════════
```

---

## 7. 🧪 Unit Tests

```python
# test_anomaly_scorer.py
import unittest
from unittest.mock import MagicMock
from datetime import datetime
from anomaly_scorer import AnomalyScorer
from event_collector import AuthEvent

class TestAnomalyScorer(unittest.TestCase):

    def setUp(self):
        self.scorer = AnomalyScorer()

        # Standard baseline for a known user
        self.baseline = {
            "token_use": {
                "mean_delay_seconds": 45.0,
                "std_delay_seconds":  20.0,
                "unused_rate":        0.02,   # User almost always uses tokens
            },
            "temporal": {
                "typical_hours":    [8,9,10,11,12,13,14,15,16,17],
                "typical_weekdays": [0,1,2,3,4],
            },
            "geo": {
                "known_countries": ["US"],
                "known_asns":      ["AS7922"],
            },
            "device": {
                "known_ips":       ["192.168.1.1"],
                "known_ua_hashes": ["abc123hash"],
                "mobile_rate":     0.1,
            },
            "volume": {
                "avg_daily_sessions": 3.0,
                "std_daily_sessions": 1.0,
            }
        }

    def _make_event(self, **kwargs) -> AuthEvent:
        """Helper to create test AuthEvent objects."""
        defaults = {
            "user_id":          "test_user",
            "token_id":         "test_token",
            "issued_at":        datetime(2024, 1, 15, 10, 0, 0),  # 10 AM weekday
            "issuing_ip":       "192.168.1.1",
            "user_agent":       "Mozilla/5.0 Normal Browser",
            "mfa_satisfied":    True,
            "token_use_delay":  30.0,
            "hour_of_day":      10,
            "day_of_week":      0,
            "issuing_country":  "US",
            "issuing_asn":      "AS7922",
            "ip_is_datacenter": False,
            "is_bot":           False,
            "is_mobile":        False,
        }
        defaults.update(kwargs)
        event = MagicMock(spec=AuthEvent)
        for k, v in defaults.items():
            setattr(event, k, v)
        return event

    def test_normal_event_low_risk(self):
        """Normal event should score LOW."""
        event  = self._make_event()
        result = self.scorer.score(event, self.baseline)
        self.assertEqual(result.risk_level, "LOW")
        self.assertEqual(result.total_score, 0)
        self.assertEqual(result.flags, [])

    def test_unused_token_scores_correctly(self):
        """Unused token for a user who always uses tokens = high score."""
        event  = self._make_event(token_use_delay=None)
        result = self.scorer.score(event, self.baseline)
        self.assertIn("TOKEN_UNUSED", result.flags)
        self.assertEqual(
            result.details["TOKEN_UNUSED"]["severity"], "HIGH"
        )

    def test_new_country_scores_25(self):
        """Authentication from new country should add 25 points."""
        event  = self._make_event(issuing_country="RU")
        result = self.scorer.score(event, self.baseline)
        self.assertIn("NEW_COUNTRY", result.flags)
        self.assertGreaterEqual(result.total_score, 25)

    def test_critical_scenario(self):
        """
        Unused token + 2AM login + new country + bot UA + no MFA
        should trigger CRITICAL risk and block action.
        """
        event = self._make_event(
            token_use_delay  = None,
            hour_of_day      = 2,
            issuing_country  = "KP",
            issuing_asn      = "AS16509",  # AWS
            ip_is_datacenter = True,
            mfa_satisfied    = False,
            is_bot           = True,
        )
        result = self.scorer.score(event, self.baseline)

        self.assertEqual(result.risk_level, "CRITICAL")
        self.assertIn("TOKEN_UNUSED",        result.flags)
        self.assertIn("UNUSUAL_LOGIN_HOUR",  result.flags)
        self.assertIn("NEW_COUNTRY",         result.flags)
        self.assertIn("MFA_NOT_SATISFIED",   result.flags)
        self.assertIn("BOT_USER_AGENT",      result.flags)
        self.assertEqual(result.recommended_action, "block_and_escalate")

    def test_mfa_not_satisfied_adds_score(self):
        """Missing MFA should add 5 points."""
        event  = self._make_event(mfa_satisfied=False)
        result = self.scorer.score(event, self.baseline)
        self.assertIn("MFA_NOT_SATISFIED", result.flags)
        self.assertEqual(result.total_score, 5)


if __name__ == "__main__":
    unittest.main(verbosity=2)
```

---

## 📋 Summary Walkthrough

```
┌─────────────────────────────────────────────────────────────────┐
│                    UEBA PIPELINE FLOW                           │
│                                                                 │
│  1. AUTH EVENT ARRIVES                                          │
│     └─ user_id, token_id, IP, UA, timestamps                   │
│                  ↓                                              │
│  2. FEATURE EXTRACTION                                          │
│     └─ Enrich with: GeoIP, ASN, UA parsing, time features      │
│                  ↓                                              │
│  3. BASELINE LOOKUP                                             │
│     ├─ Check Redis cache first (fast)                           │
│     └─ Rebuild from PostgreSQL if stale                         │
│                  ↓                                              │
│  4. ANOMALY SCORING (8 checks, weighted)                        │
│     ├─ Token unused?        → 0–20 pts                         │
│     ├─ Unusual hour?        → 0–15 pts                         │
│     ├─ New country?         → 0–25 pts                         │
│     ├─ Suspicious ASN?      → 0–15 pts                         │
│     ├─ New device?          → 0–10 pts                         │
│     ├─ Volume spike?        → 0–10 pts                         │
│     ├─ No MFA?              → 0–5  pts                         │
│     └─ Bot UA?              → 0–10 pts                         │
│                  ↓                                              │
│  5. RISK CLASSIFICATION                                         │
│     ├─ 0–30:  LOW      → Monitor                               │
│     ├─ 31–60: MEDIUM   → Investigate                           │
│     ├─ 61–80: HIGH     → Alert analyst + flag account          │
│     └─ 81+:   CRITICAL → Block token + escalate                │
│                  ↓                                              │
│  6. ALERT ROUTING                                               │
│     ├─ DB log (always)                                          │
│     ├─ SIEM event (Medium+)                                     │
│     ├─ Email alert (High+)                                      │
│     └─ Auto-revoke token (Critical)                             │
└─────────────────────────────────────────────────────────────────┘
```

> 💡 **Tuning Tip:** Start with **permissive thresholds** and tighten over 2–4 weeks as you observe false positive rates. The scoring weights and risk level cutoffs should be adjusted to match your environment's baseline noise level.
