const express = require('express');
const axios = require('axios');

const app = express();
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

const PORT = process.env.PORT || 3000;
const INFERENCE_URL = process.env.INFERENCE_URL;
const SNOWFLAKE_PAT = process.env.SNOWFLAKE_PAT;

// --- Feature engineering (mirrors the SQL logic) ---

const HIGH_RISK_LOCATIONS = [
  'Los Angeles', 'San Diego', 'Tucson', 'San Francisco', 'Chicago',
  'Jacksonville', 'Austin', 'New York', 'Memphis', 'Dallas', 'Phoenix'
];

const HIGH_RISK_MERCHANTS = [
  'Walmart', 'Netflix', 'Uber', 'Nike', 'Amazon', 'Costco', 'McDonalds', 'Target'
];

// Sorted lists for deterministic DENSE_RANK encoding
const ALL_LOCATIONS = [
  'Austin', 'Charlotte', 'Chicago', 'Columbus', 'Dallas', 'Denver',
  'El Paso', 'Fort Worth', 'Houston', 'Indianapolis', 'Jacksonville',
  'Los Angeles', 'Memphis', 'Nashville', 'New York', 'Philadelphia',
  'Phoenix', 'San Antonio', 'San Diego', 'San Francisco', 'San Jose',
  'Seattle', 'Tucson', 'Washington'
].sort();

const ALL_MERCHANTS = [
  'Amazon', 'Apple Store', 'Best Buy', 'Costco', 'CVS Pharmacy',
  'Home Depot', 'McDonalds', 'Netflix', 'Nike', 'Starbucks',
  'Target', 'Uber', 'Walmart', 'Whole Foods'
].sort();

function computeFeatures(amount, location, merchant, transactionTime) {
  const dt = new Date(transactionTime);
  const hour = dt.getHours();
  const dayOfWeek = dt.getDay(); // 0=Sunday

  return {
    AMOUNT: parseFloat(amount),
    AMOUNT_LOG: Math.log(1 + parseFloat(amount)),
    HOUR_OF_DAY: hour,
    DAY_OF_WEEK: dayOfWeek,
    IS_NIGHT: (hour >= 0 && hour <= 5) ? 1 : 0,
    IS_HIGH_RISK_LOCATION: HIGH_RISK_LOCATIONS.includes(location) ? 1 : 0,
    IS_HIGH_RISK_MERCHANT: HIGH_RISK_MERCHANTS.includes(merchant) ? 1 : 0,
    LOCATION_ENC: ALL_LOCATIONS.indexOf(location),
    MERCHANT_ENC: ALL_MERCHANTS.indexOf(merchant),
  };
}

// --- Inference endpoint ---

app.post('/infer', async (req, res) => {
  const { amount, location, merchant, transactionTime } = req.body;

  if (!INFERENCE_URL || !SNOWFLAKE_PAT) {
    return res.status(500).json({ error: 'INFERENCE_URL and SNOWFLAKE_PAT env vars are required' });
  }

  const features = computeFeatures(amount, location, merchant, transactionTime);

  const payload = {
    dataframe_records: [
      {
        AMOUNT: features.AMOUNT,
        AMOUNT_LOG: features.AMOUNT_LOG,
        HOUR_OF_DAY: features.HOUR_OF_DAY,
        DAY_OF_WEEK: features.DAY_OF_WEEK,
        IS_NIGHT: features.IS_NIGHT,
        IS_HIGH_RISK_LOCATION: features.IS_HIGH_RISK_LOCATION,
        IS_HIGH_RISK_MERCHANT: features.IS_HIGH_RISK_MERCHANT,
        LOCATION_ENC: features.LOCATION_ENC,
        MERCHANT_ENC: features.MERCHANT_ENC,
      }
    ]
  };

  const url = `${INFERENCE_URL.replace(/\/$/, '')}/predict-proba`;

  try {
    const start = Date.now();
    const response = await axios.post(url, payload, {
      headers: {
        'Authorization': `Snowflake Token="${SNOWFLAKE_PAT}"`,
        'Content-Type': 'application/json',
      },
      timeout: 30000,
    });
    const latency = Date.now() - start;

    res.json({
      features,
      request: payload,
      response: response.data,
      latency_ms: latency,
      endpoint: url,
    });
  } catch (err) {
    res.status(502).json({
      error: 'Inference request failed',
      details: err.response?.data || err.message,
      endpoint: url,
      features,
      request: payload,
    });
  }
});

// --- UI ---

app.get('/', (_req, res) => {
  res.send(HTML);
});

const HTML = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Fraud Detection - Real-Time Inference</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #0f1117; color: #e0e0e0; min-height: 100vh; }
  .header { background: linear-gradient(135deg, #1a1a2e 0%, #16213e 100%); padding: 24px 32px; border-bottom: 1px solid #2a2a4a; }
  .header h1 { font-size: 22px; color: #fff; }
  .header p { font-size: 13px; color: #8892b0; margin-top: 4px; }
  .container { max-width: 1100px; margin: 0 auto; padding: 24px; display: grid; grid-template-columns: 1fr 1fr; gap: 24px; }
  .panel { background: #1a1a2e; border: 1px solid #2a2a4a; border-radius: 8px; padding: 20px; }
  .panel h2 { font-size: 15px; color: #8892b0; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 16px; }
  label { display: block; font-size: 13px; color: #8892b0; margin-bottom: 4px; margin-top: 12px; }
  input, select { width: 100%; padding: 10px 12px; background: #0f1117; border: 1px solid #2a2a4a; border-radius: 6px; color: #e0e0e0; font-size: 14px; }
  input:focus, select:focus { outline: none; border-color: #4a6cf7; }
  .btn-row { display: flex; gap: 10px; margin-top: 20px; }
  button { padding: 10px 20px; border: none; border-radius: 6px; font-size: 14px; font-weight: 600; cursor: pointer; transition: all 0.2s; }
  .btn-primary { background: #4a6cf7; color: #fff; flex: 1; }
  .btn-primary:hover { background: #3b5de7; }
  .btn-primary:disabled { background: #333; color: #666; cursor: not-allowed; }
  .btn-danger { background: #e74c3c; color: #fff; flex: 1; }
  .btn-danger:hover { background: #c0392b; }
  .score-display { text-align: center; padding: 24px; margin-bottom: 16px; border-radius: 8px; background: #0f1117; }
  .score-value { font-size: 48px; font-weight: 700; }
  .score-label { font-size: 13px; color: #8892b0; margin-top: 4px; }
  .badge { display: inline-block; padding: 4px 12px; border-radius: 20px; font-size: 12px; font-weight: 600; margin-top: 8px; }
  .badge-high { background: rgba(231,76,60,0.2); color: #e74c3c; }
  .badge-medium { background: rgba(243,156,18,0.2); color: #f39c12; }
  .badge-low { background: rgba(46,204,113,0.2); color: #2ecc71; }
  .features-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
  .feature-item { background: #0f1117; padding: 8px 12px; border-radius: 6px; font-size: 12px; }
  .feature-item .name { color: #8892b0; }
  .feature-item .val { color: #e0e0e0; font-weight: 600; }
  .log-entry { background: #0f1117; border-radius: 6px; padding: 12px; margin-bottom: 8px; font-size: 12px; border-left: 3px solid #4a6cf7; }
  .log-entry.error { border-left-color: #e74c3c; }
  .log-time { color: #4a6cf7; font-weight: 600; }
  .log-latency { color: #f39c12; float: right; }
  .full-width { grid-column: 1 / -1; }
  .spinner { display: inline-block; width: 16px; height: 16px; border: 2px solid #333; border-top-color: #4a6cf7; border-radius: 50%; animation: spin 0.6s linear infinite; vertical-align: middle; margin-right: 8px; }
  @keyframes spin { to { transform: rotate(360deg); } }
  pre { background: #0f1117; padding: 12px; border-radius: 6px; overflow-x: auto; font-size: 11px; color: #8892b0; margin-top: 8px; max-height: 200px; }
  .empty-state { text-align: center; padding: 40px; color: #555; }
</style>
</head>
<body>
<div class="header">
  <h1>Fraud Detection &mdash; Real-Time Inference</h1>
  <p>Snowflake ML Model Service &bull; FRAUD_DETECTION_XGBOOST V1 &bull; PREDICT_PROBA</p>
</div>
<div class="container">
  <!-- Input Panel -->
  <div class="panel">
    <h2>Transaction Input</h2>
    <label>Amount ($)</label>
    <input type="number" id="amount" value="150.00" step="0.01" min="0">
    <label>Location</label>
    <select id="location">
      <option>Austin</option><option>Charlotte</option><option>Chicago</option>
      <option>Columbus</option><option>Dallas</option><option>Denver</option>
      <option>El Paso</option><option>Fort Worth</option><option>Houston</option>
      <option>Indianapolis</option><option>Jacksonville</option><option>Los Angeles</option>
      <option>Memphis</option><option>Nashville</option><option>New York</option>
      <option>Philadelphia</option><option>Phoenix</option><option>San Antonio</option>
      <option>San Diego</option><option>San Francisco</option><option>San Jose</option>
      <option>Seattle</option><option>Tucson</option><option>Washington</option>
    </select>
    <label>Merchant</label>
    <select id="merchant">
      <option>Amazon</option><option>Apple Store</option><option>Best Buy</option>
      <option>Costco</option><option>CVS Pharmacy</option><option>Home Depot</option>
      <option>McDonalds</option><option>Netflix</option><option>Nike</option>
      <option>Starbucks</option><option>Target</option><option>Uber</option>
      <option>Walmart</option><option>Whole Foods</option>
    </select>
    <label>Transaction Time</label>
    <input type="datetime-local" id="transactionTime">
    <div class="btn-row">
      <button class="btn-primary" id="btnInfer" onclick="sendInference()">Send Inference Request</button>
      <button class="btn-danger" onclick="simulateFraud()">Simulate Fraud</button>
    </div>
  </div>

  <!-- Result Panel -->
  <div class="panel">
    <h2>Inference Result</h2>
    <div id="resultArea">
      <div class="empty-state">Submit a transaction to see the fraud score</div>
    </div>
  </div>

  <!-- Log Panel -->
  <div class="panel full-width">
    <h2>Request Log</h2>
    <div id="logArea">
      <div class="empty-state">No requests yet</div>
    </div>
  </div>
</div>

<script>
  // Set default transaction time to now
  const now = new Date();
  now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
  document.getElementById('transactionTime').value = now.toISOString().slice(0, 16);

  function simulateFraud() {
    document.getElementById('amount').value = '4850.00';
    document.getElementById('location').value = 'New York';
    document.getElementById('merchant').value = 'Walmart';
    // Set to 2:30 AM (night hours = high risk)
    const fraud = new Date();
    fraud.setHours(2, 30, 0, 0);
    fraud.setMinutes(fraud.getMinutes() - fraud.getTimezoneOffset() + 30);
    document.getElementById('transactionTime').value = fraud.toISOString().slice(0, 16);
  }

  async function sendInference() {
    const btn = document.getElementById('btnInfer');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span>Calling service...';

    const body = {
      amount: document.getElementById('amount').value,
      location: document.getElementById('location').value,
      merchant: document.getElementById('merchant').value,
      transactionTime: document.getElementById('transactionTime').value,
    };

    try {
      const res = await fetch('/infer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const data = await res.json();

      if (!res.ok) {
        showError(data);
        addLog(body, data, null, true);
        return;
      }
      showResult(data);
      addLog(body, data, data.latency_ms, false);
    } catch (err) {
      showError({ error: err.message });
      addLog(body, { error: err.message }, null, true);
    } finally {
      btn.disabled = false;
      btn.textContent = 'Send Inference Request';
    }
  }

  function showResult(data) {
    // Extract the fraud probability from the response
    let score = null;
    const resp = data.response;
    if (resp && Array.isArray(resp)) {
      // dataframe_records response: array of objects
      const row = resp[0];
      if (row) score = row['output_feature_0'] ?? row['PREDICT_PROBA'] ?? Object.values(row)[0];
    } else if (resp && resp.data && Array.isArray(resp.data)) {
      // legacy data format
      const row = resp.data[0];
      if (Array.isArray(row)) {
        const val = row[row.length - 1];
        score = typeof val === 'object' ? Object.values(val)[0] : val;
      }
    }
    if (score === null && resp) {
      // try to find any numeric in the response
      const flat = JSON.stringify(resp);
      const m = flat.match(/(\\d+\\.\\d+)/);
      if (m) score = parseFloat(m[1]);
    }

    const pct = score !== null ? (score * 100).toFixed(1) : '—';
    const level = score > 0.7 ? 'high' : score > 0.3 ? 'medium' : 'low';
    const levelLabel = score > 0.7 ? 'HIGH RISK' : score > 0.3 ? 'MEDIUM RISK' : 'LOW RISK';

    const f = data.features;
    document.getElementById('resultArea').innerHTML = \`
      <div class="score-display">
        <div class="score-value" style="color: \${{high:'#e74c3c',medium:'#f39c12',low:'#2ecc71'}[level]}">\${pct}%</div>
        <div class="score-label">Fraud Probability</div>
        <span class="badge badge-\${level}">\${levelLabel}</span>
      </div>
      <h2 style="margin-bottom:8px">Computed Features</h2>
      <div class="features-grid">
        <div class="feature-item"><span class="name">AMOUNT</span><br><span class="val">\${f.AMOUNT}</span></div>
        <div class="feature-item"><span class="name">AMOUNT_LOG</span><br><span class="val">\${f.AMOUNT_LOG.toFixed(4)}</span></div>
        <div class="feature-item"><span class="name">HOUR_OF_DAY</span><br><span class="val">\${f.HOUR_OF_DAY}</span></div>
        <div class="feature-item"><span class="name">DAY_OF_WEEK</span><br><span class="val">\${f.DAY_OF_WEEK}</span></div>
        <div class="feature-item"><span class="name">IS_NIGHT</span><br><span class="val">\${f.IS_NIGHT}</span></div>
        <div class="feature-item"><span class="name">IS_HIGH_RISK_LOC</span><br><span class="val">\${f.IS_HIGH_RISK_LOCATION}</span></div>
        <div class="feature-item"><span class="name">IS_HIGH_RISK_MERCH</span><br><span class="val">\${f.IS_HIGH_RISK_MERCHANT}</span></div>
        <div class="feature-item"><span class="name">LOC_ENC / MERCH_ENC</span><br><span class="val">\${f.LOCATION_ENC} / \${f.MERCHANT_ENC}</span></div>
      </div>
      <h2 style="margin-top:12px;margin-bottom:4px">Raw Response</h2>
      <pre>\${JSON.stringify(data.response, null, 2)}</pre>
    \`;
  }

  function showError(data) {
    document.getElementById('resultArea').innerHTML = \`
      <div class="score-display" style="border:1px solid #e74c3c">
        <div class="score-value" style="color:#e74c3c;font-size:24px">Error</div>
        <div class="score-label">\${data.error || 'Unknown error'}</div>
      </div>
      <pre>\${JSON.stringify(data, null, 2)}</pre>
    \`;
  }

  let logCount = 0;
  function addLog(input, data, latency, isError) {
    logCount++;
    const area = document.getElementById('logArea');
    if (logCount === 1) area.innerHTML = '';
    const time = new Date().toLocaleTimeString();
    const entry = document.createElement('div');
    entry.className = 'log-entry' + (isError ? ' error' : '');
    entry.innerHTML = \`
      <span class="log-time">\${time}</span>
      \${latency ? '<span class="log-latency">' + latency + 'ms</span>' : ''}
      <div style="margin-top:4px">
        <strong>\${input.location}</strong> &bull; \${input.merchant} &bull; $\${input.amount}
        \${!isError && data.response ? ' &rarr; Score: ' + JSON.stringify(data.response).substring(0, 80) : ''}
        \${isError ? ' &rarr; <span style="color:#e74c3c">FAILED</span>' : ''}
      </div>
    \`;
    area.prepend(entry);
  }
</script>
</body>
</html>`;

app.listen(PORT, () => {
  console.log('Fraud Detection Inference app running on http://localhost:' + PORT);
  console.log('Inference endpoint: ' + (INFERENCE_URL || '(not set — set INFERENCE_URL env var)'));
});
