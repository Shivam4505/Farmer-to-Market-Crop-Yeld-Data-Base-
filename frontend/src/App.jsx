import React, { useState, useEffect } from 'react';
import {
  TrendingUp,
  Award,
  AlertTriangle,
  RefreshCw,
  Search,
  IndianRupee,
  MapPin,
  Calendar,
  CheckCircle2,
  Users,
  Wheat,
  Building2,
  Database,
  BarChart3,
  HelpCircle,
  FileSpreadsheet,
  ArrowUpRight,
  ShieldCheck,
  LogIn,
  LogOut,
  Lock,
  History,
  Edit3,
  PlusCircle,
  Check,
  X,
  Eye
} from 'lucide-react';

export default function App() {
  // ---------------------------------------------------------------------------
  // AUTHENTICATION & ROLE STATE
  // ---------------------------------------------------------------------------
  const [currentUser, setCurrentUser] = useState({
    user_id: 4,
    username: 'farmer_ramesh',
    full_name: 'Ramesh Patil',
    role: 'FARMER',
    farmer_id: 1,
    market_id: null
  });
  const [authToken, setAuthToken] = useState(null);
  const [assignedMarkets, setAssignedMarkets] = useState([]);
  const [isLoginModalOpen, setIsLoginModalOpen] = useState(false);
  const [loginForm, setLoginForm] = useState({ username: '', password: '' });
  const [loginLoading, setLoginLoading] = useState(false);
  const [loginError, setLoginError] = useState(null);

  // Navigation Tabs (Farmer vs Seller)
  const [activeTab, setActiveTab] = useState('advisor');

  // Database status and summary stats
  const [dbStatus, setDbStatus] = useState({ connected: false, loading: true });
  const [stats, setStats] = useState({
    total_farmers: 0,
    total_crops: 0,
    total_markets: 0,
    total_prices: 0,
    total_alerts: 0,
    total_sales: 0
  });

  // Master Data
  const [crops, setCrops] = useState([]);
  const [districts, setDistricts] = useState([]);

  // Advisor Form State (Farmer)
  const [selectedCropId, setSelectedCropId] = useState('');
  const [quantity, setQuantity] = useState(50);
  const [selectedDistrict, setSelectedDistrict] = useState('All');
  const [advisorLoading, setAdvisorLoading] = useState(false);
  const [advisorData, setAdvisorData] = useState(null);
  const [advisorError, setAdvisorError] = useState(null);

  // Farmer Browsing Data States
  const [priceAlerts, setPriceAlerts] = useState([]);
  const [farmersList, setFarmersList] = useState([]);
  const [yieldsList, setYieldsList] = useState([]);
  const [salesList, setSalesList] = useState([]);
  const [marketsList, setMarketsList] = useState([]);

  // ---------------------------------------------------------------------------
  // SELLER STATE
  // ---------------------------------------------------------------------------
  const [sellerStats, setSellerStats] = useState({
    assigned_mandis: 0,
    today_prices_count: 0,
    active_alerts_count: 0,
    audit_records_count: 0
  });
  const [sellerPricesList, setSellerPricesList] = useState([]);
  const [sellerAuditList, setSellerAuditList] = useState([]);
  const [sellerForm, setSellerForm] = useState({
    market_id: '',
    crop_id: '',
    price_date: new Date().toISOString().split('T')[0],
    min_price: '',
    max_price: '',
    modal_price: '',
    quantity_qtl: '',
    remarks: ''
  });
  const [sellerLoading, setSellerLoading] = useState(false);
  const [sellerSuccess, setSellerSuccess] = useState(null);
  const [sellerError, setSellerError] = useState(null);

  // ---------------------------------------------------------------------------
  // INITIAL DATA LOAD
  // ---------------------------------------------------------------------------
  useEffect(() => {
    loadInitialData();
  }, []);

  // When crops load, default to first crop
  useEffect(() => {
    if (crops.length > 0 && !selectedCropId) {
      setSelectedCropId(crops[0].crop_id);
    }
    if (crops.length > 0 && !sellerForm.crop_id) {
      setSellerForm(prev => ({ ...prev, crop_id: crops[0].crop_id }));
    }
  }, [crops]);

  // When farmer selects crop/district, fetch best market
  useEffect(() => {
    if (selectedCropId && currentUser.role === 'FARMER') {
      fetchBestMarket(selectedCropId, quantity, selectedDistrict);
    }
  }, [selectedCropId, selectedDistrict, currentUser.role]);

  // When seller logs in or changes tab, fetch seller data
  useEffect(() => {
    if (currentUser.role === 'OFFICER' || currentUser.role === 'ADMIN') {
      fetchSellerData();
    }
  }, [currentUser, authToken, activeTab]);

  async function loadInitialData() {
    setDbStatus(prev => ({ ...prev, loading: true }));
    try {
      const [healthRes, statsRes, cropsRes, distRes, mktsRes] = await Promise.all([
        fetch('/api/health'),
        fetch('/api/stats'),
        fetch('/api/crops'),
        fetch('/api/districts'),
        fetch('/api/markets')
      ]);

      const healthJson = await healthRes.json();
      setDbStatus({
        connected: healthJson.status === 'ok' && healthJson.database?.connected,
        database: healthJson.database?.database || 'farmer_market_db',
        loading: false
      });

      const statsJson = await statsRes.json();
      if (statsJson.success) setStats(statsJson.data);

      const cropsJson = await cropsRes.json();
      if (cropsJson.success) setCrops(cropsJson.data);

      const distJson = await distRes.json();
      if (distJson.success) setDistricts(['All', ...distJson.data]);

      const mktsJson = await mktsRes.json();
      if (mktsJson.success) setMarketsList(mktsJson.data);

    } catch (err) {
      console.error('Initial load failed:', err);
      setDbStatus({ connected: false, loading: false });
    }
  }

  // ---------------------------------------------------------------------------
  // AUTHENTICATION HANDLERS
  // ---------------------------------------------------------------------------
  async function performLogin(username, password) {
    setLoginLoading(true);
    setLoginError(null);
    try {
      const res = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password })
      });
      const data = await res.json();
      if (!data.success) {
        throw new Error(data.error || 'Login failed');
      }

      setAuthToken(data.token);
      setCurrentUser(data.user);
      setAssignedMarkets(data.assigned_markets || []);

      if (data.user.role === 'OFFICER' || data.user.role === 'ADMIN') {
        setActiveTab('seller_publish');
        if (data.assigned_markets?.length > 0) {
          setSellerForm(prev => ({ ...prev, market_id: data.assigned_markets[0].market_id }));
        }
      } else {
        setActiveTab('advisor');
      }

      setIsLoginModalOpen(false);
      setLoginForm({ username: '', password: '' });
    } catch (err) {
      setLoginError(err.message);
    } finally {
      setLoginLoading(false);
    }
  }

  // Quick Role Switcher for College Demonstration
  function switchRoleDemo(roleKey) {
    if (roleKey === 'farmer') {
      setCurrentUser({
        user_id: 4,
        username: 'farmer_ramesh',
        full_name: 'Ramesh Patil',
        role: 'FARMER',
        farmer_id: 1,
        market_id: null
      });
      setAuthToken(null);
      setAssignedMarkets([]);
      setActiveTab('advisor');
    } else if (roleKey === 'officer_lasalgaon') {
      performLogin('officer_lasalgaon', 'Password@123');
    } else if (roleKey === 'officer_pune') {
      performLogin('officer_pune', 'Password@123');
    } else if (roleKey === 'admin') {
      performLogin('admin', 'Password@123');
    }
  }

  function handleLogout() {
    setCurrentUser({
      user_id: 4,
      username: 'farmer_ramesh',
      full_name: 'Ramesh Patil',
      role: 'FARMER',
      farmer_id: 1,
      market_id: null
    });
    setAuthToken(null);
    setAssignedMarkets([]);
    setActiveTab('advisor');
  }

  // ---------------------------------------------------------------------------
  // FARMER: BEST MARKET ADVISOR
  // ---------------------------------------------------------------------------
  async function fetchBestMarket(cropId, qtl, district) {
    if (!cropId) return;
    setAdvisorLoading(true);
    setAdvisorError(null);
    try {
      let url = `/api/best-market?crop_id=${cropId}&quantity=${qtl || 10}`;
      if (district && district !== 'All') {
        url += `&district=${encodeURIComponent(district)}`;
      }
      const res = await fetch(url);
      const json = await res.json();
      if (json.success) {
        setAdvisorData(json);
      } else {
        setAdvisorError(json.error || 'Failed to evaluate market prices');
      }
    } catch (err) {
      setAdvisorError('Unable to connect to pricing database.');
    } finally {
      setAdvisorLoading(false);
    }
  }

  function handleAdvisorSubmit(e) {
    e.preventDefault();
    fetchBestMarket(selectedCropId, quantity, selectedDistrict);
  }

  // Refresh All Data
  async function handleRefreshAll() {
    await loadInitialData();
    if (selectedCropId) {
      await fetchBestMarket(selectedCropId, quantity, selectedDistrict);
    }
    if (currentUser.role === 'OFFICER' || currentUser.role === 'ADMIN') {
      await fetchSellerData();
    }
  }

  // ---------------------------------------------------------------------------
  // SELLER: FETCH DATA & SUBMIT PRICE
  // ---------------------------------------------------------------------------
  async function fetchSellerData() {
    if (!authToken && currentUser.role !== 'ADMIN' && currentUser.role !== 'OFFICER') return;
    const headers = authToken ? { Authorization: `Bearer ${authToken}` } : {};

    try {
      const [statsRes, pricesRes, auditRes] = await Promise.all([
        fetch('/api/seller/stats', { headers }),
        fetch('/api/seller/prices', { headers }),
        fetch('/api/seller/audit-log', { headers })
      ]);

      const statsJson = await statsRes.json();
      if (statsJson.success) setSellerStats(statsJson.data);

      const pricesJson = await pricesRes.json();
      if (pricesJson.success) setSellerPricesList(pricesJson.data);

      const auditJson = await auditRes.json();
      if (auditJson.success) setSellerAuditList(auditJson.data);

    } catch (err) {
      console.error('Error fetching seller data:', err);
    }
  }

  async function handleSellerPriceSubmit(e) {
    e.preventDefault();
    setSellerLoading(true);
    setSellerSuccess(null);
    setSellerError(null);

    const minP = parseFloat(sellerForm.min_price);
    const maxP = parseFloat(sellerForm.max_price);
    const modalP = parseFloat(sellerForm.modal_price);

    // Frontend Range Validation
    if (minP <= 0 || maxP <= 0 || modalP <= 0) {
      setSellerError('All prices must be greater than zero.');
      setSellerLoading(false);
      return;
    }
    if (minP > maxP) {
      setSellerError(`Minimum price (₹${minP}) cannot exceed Maximum price (₹${maxP}).`);
      setSellerLoading(false);
      return;
    }
    if (modalP < minP || modalP > maxP) {
      setSellerError(`Modal price (₹${modalP}) must be within [₹${minP} - ₹${maxP}].`);
      setSellerLoading(false);
      return;
    }

    try {
      const res = await fetch('/api/seller/prices', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${authToken}`
        },
        body: JSON.stringify(sellerForm)
      });
      const data = await res.json();
      if (!data.success) {
        throw new Error(data.error || 'Failed to publish price');
      }

      setSellerSuccess({
        message: data.message,
        record: data.data,
        alert: data.alert_generated
      });

      // Clear price fields
      setSellerForm(prev => ({
        ...prev,
        min_price: '',
        max_price: '',
        modal_price: '',
        quantity_qtl: '',
        remarks: ''
      }));

      // Refresh seller records & master stats
      fetchSellerData();
      loadInitialData();

    } catch (err) {
      setSellerError(err.message);
    } finally {
      setSellerLoading(false);
    }
  }

  // Pre-fill form from price history
  function handleEditExistingPrice(p) {
    setSellerForm({
      market_id: p.market_id,
      crop_id: p.crop_id,
      price_date: p.price_date,
      min_price: p.min_price,
      max_price: p.max_price,
      modal_price: p.modal_price,
      quantity_qtl: p.quantity_qtl || '',
      remarks: p.remarks || ''
    });
    setActiveTab('seller_publish');
    window.scrollTo({ top: 250, behavior: 'smooth' });
  }

  // Formatter for Indian Rupees
  function formatINR(val) {
    if (val === null || val === undefined) return '₹0';
    return '₹' + Number(val).toLocaleString('en-IN');
  }

  const selectedCropObj = crops.find(c => String(c.crop_id) === String(selectedCropId));
  const selectedCropName = selectedCropObj ? selectedCropObj.crop_name : 'Selected Crop';

  // ---------------------------------------------------------------------------
  // RENDER UI
  // ---------------------------------------------------------------------------
  return (
    <div className="app-layout">
      {/* ------------------------------------------------------------------- */}
      {/* 1. TOP ROLE SWITCHER BAR (COLLEGE DEMO ACCESSIBILITY)                */}
      {/* ------------------------------------------------------------------- */}
      <div className="role-top-bar">
        <div className="container role-bar-content">
          <div className="role-pills">
            <span style={{ color: '#86efac', fontWeight: 800, fontSize: '11px', textTransform: 'uppercase', letterSpacing: '0.05em' }}>
              Demo Persona:
            </span>
            <button
              onClick={() => switchRoleDemo('farmer')}
              className={`role-pill-btn ${currentUser.role === 'FARMER' ? 'active' : ''}`}
            >
              🧑‍🌾 Farmer (Ramesh)
            </button>
            <button
              onClick={() => switchRoleDemo('officer_lasalgaon')}
              className={`role-pill-btn ${currentUser.username === 'officer_lasalgaon' ? 'active' : ''}`}
            >
              🏢 Seller: Lasalgaon APMC
            </button>
            <button
              onClick={() => switchRoleDemo('officer_pune')}
              className={`role-pill-btn ${currentUser.username === 'officer_pune' ? 'active' : ''}`}
            >
              🏢 Seller: Pune Mandi
            </button>
            <button
              onClick={() => switchRoleDemo('admin')}
              className={`role-pill-btn ${currentUser.role === 'ADMIN' ? 'active' : ''}`}
            >
              👑 Admin (All Mandis)
            </button>
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div className="user-badge-chip">
              <ShieldCheck size={14} style={{ color: '#86efac' }} />
              <span>{currentUser.full_name}</span>
              <span style={{ opacity: 0.7, fontSize: '11px' }}>({currentUser.role})</span>
            </div>

            {authToken ? (
              <button onClick={handleLogout} className="login-btn-header">
                <LogOut size={13} /> Logout
              </button>
            ) : (
              <button onClick={() => setIsLoginModalOpen(true)} className="login-btn-header">
                <LogIn size={13} /> Login
              </button>
            )}
          </div>
        </div>
      </div>

      {/* ------------------------------------------------------------------- */}
      {/* 2. MAIN HEADER                                                      */}
      {/* ------------------------------------------------------------------- */}
      <header className="app-header">
        <div className="container header-content">
          <div className="brand-wrapper">
            <div className="brand-icon">🌾</div>
            <div>
              <h1 className="brand-title">Farmer Market Advisor</h1>
              <p className="brand-subtitle">Find the best market for your harvest.</p>
            </div>
          </div>

          <div className="header-actions">
            <div className="status-badge">
              <span className={`status-indicator ${dbStatus.connected ? 'connected' : 'disconnected'}`}></span>
              <span>
                {dbStatus.loading
                  ? 'Connecting...'
                  : dbStatus.connected
                  ? `Live: ${dbStatus.database}`
                  : 'Database Offline'}
              </span>
            </div>

            <button onClick={handleRefreshAll} className="btn-refresh" title="Reload live from PostgreSQL">
              <RefreshCw size={15} />
              <span>Refresh Data</span>
            </button>
          </div>
        </div>
      </header>

      {/* ------------------------------------------------------------------- */}
      {/* 3. DUAL-ROLE NAVIGATION TABS                                        */}
      {/* ------------------------------------------------------------------- */}
      <nav className="app-nav">
        <div className="container nav-content">
          {currentUser.role === 'FARMER' ? (
            /* FARMER TABS */
            <>
              <button
                onClick={() => setActiveTab('advisor')}
                className={`nav-tab ${activeTab === 'advisor' ? 'active' : ''}`}
              >
                <Award size={16} /> Best Market Advisor
              </button>
              <button
                onClick={() => setActiveTab('chart')}
                className={`nav-tab ${activeTab === 'chart' ? 'active' : ''}`}
              >
                <BarChart3 size={16} /> Price Chart
              </button>
              <button
                onClick={() => {
                  setActiveTab('alerts');
                  fetch('/api/alerts').then(r => r.json()).then(j => j.success && setPriceAlerts(j.data));
                }}
                className={`nav-tab ${activeTab === 'alerts' ? 'active' : ''}`}
              >
                <AlertTriangle size={16} /> Price Alerts ({stats.total_alerts})
              </button>
              <button
                onClick={() => {
                  setActiveTab('farmers');
                  fetch('/api/farmers').then(r => r.json()).then(j => j.success && setFarmersList(j.data));
                }}
                className={`nav-tab ${activeTab === 'farmers' ? 'active' : ''}`}
              >
                <Users size={16} /> Registered Farmers
              </button>
              <button
                onClick={() => setActiveTab('crops')}
                className={`nav-tab ${activeTab === 'crops' ? 'active' : ''}`}
              >
                <Wheat size={16} /> Crops &amp; EER
              </button>
              <button
                onClick={() => setActiveTab('markets')}
                className={`nav-tab ${activeTab === 'markets' ? 'active' : ''}`}
              >
                <Building2 size={16} /> Mandis
              </button>
              <button
                onClick={() => {
                  setActiveTab('yields');
                  fetch('/api/yields').then(r => r.json()).then(j => j.success && setYieldsList(j.data));
                }}
                className={`nav-tab ${activeTab === 'yields' ? 'active' : ''}`}
              >
                <FileSpreadsheet size={16} /> Yields
              </button>
              <button
                onClick={() => {
                  setActiveTab('sales');
                  fetch('/api/sales').then(r => r.json()).then(j => j.success && setSalesList(j.data));
                }}
                className={`nav-tab ${activeTab === 'sales' ? 'active' : ''}`}
              >
                <IndianRupee size={16} /> Sales
              </button>
              <button
                onClick={() => setActiveTab('demo')}
                className={`nav-tab ${activeTab === 'demo' ? 'active' : ''}`}
              >
                <HelpCircle size={16} /> College Demo
              </button>
            </>
          ) : (
            /* SELLER / OFFICER TABS */
            <>
              <button
                onClick={() => setActiveTab('seller_publish')}
                className={`nav-tab ${activeTab === 'seller_publish' ? 'active' : ''}`}
              >
                <PlusCircle size={16} /> Publish Daily Price
              </button>
              <button
                onClick={() => setActiveTab('seller_history')}
                className={`nav-tab ${activeTab === 'seller_history' ? 'active' : ''}`}
              >
                <History size={16} /> Manage Mandi Prices ({sellerPricesList.length})
              </button>
              <button
                onClick={() => setActiveTab('seller_audit')}
                className={`nav-tab ${activeTab === 'seller_audit' ? 'active' : ''}`}
              >
                <ShieldCheck size={16} /> Price Audit Trail ({sellerAuditList.length})
              </button>
              <button
                onClick={() => {
                  setActiveTab('seller_alerts');
                  fetch('/api/alerts').then(r => r.json()).then(j => j.success && setPriceAlerts(j.data));
                }}
                className={`nav-tab ${activeTab === 'seller_alerts' ? 'active' : ''}`}
              >
                <AlertTriangle size={16} /> Mandi Alerts ({stats.total_alerts})
              </button>
              <button
                onClick={() => setActiveTab('demo')}
                className={`nav-tab ${activeTab === 'demo' ? 'active' : ''}`}
              >
                <HelpCircle size={16} /> College Demo
              </button>
            </>
          )}
        </div>
      </nav>

      {/* ------------------------------------------------------------------- */}
      {/* 4. MAIN CONTENT CONTAINER                                           */}
      {/* ------------------------------------------------------------------- */}
      <main className="container main-content">

        {/* ================================================================= */}
        {/* VIEW A: SELLER / MARKET OFFICER DASHBOARD                         */}
        {/* ================================================================= */}
        {(currentUser.role === 'OFFICER' || currentUser.role === 'ADMIN') && (
          <div>
            {/* Quick Switch to Farmer Banner */}
            <div className="seller-switch-banner">
              <div>
                <strong style={{ color: '#15803d', fontSize: '15px' }}>
                  🏢 Active Role: {currentUser.full_name} ({currentUser.role})
                </strong>
                <p style={{ fontSize: '13px', color: '#475569', marginTop: '2px' }}>
                  Authorized Mandis:{' '}
                  {assignedMarkets.map(m => `${m.market_name} (${m.district})`).join(', ') || 'All Mandis (Admin)'}
                </p>
              </div>

              <button
                onClick={() => switchRoleDemo('farmer')}
                className="btn-primary"
                style={{ background: '#15803d', padding: '8px 16px', fontSize: '13px' }}
              >
                <Eye size={15} /> Switch to Farmer View &amp; Verify Price
              </button>
            </div>

            {/* Seller Summary Stats */}
            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-icon green"><Building2 size={22} /></div>
                <div>
                  <div className="stat-label">Authorized Mandis</div>
                  <div className="stat-value">{sellerStats.assigned_mandis || assignedMarkets.length}</div>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon blue"><Calendar size={22} /></div>
                <div>
                  <div className="stat-label">Published Today</div>
                  <div className="stat-value">{sellerStats.today_prices_count}</div>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon amber"><AlertTriangle size={22} /></div>
                <div>
                  <div className="stat-label">Active Mandi Alerts</div>
                  <div className="stat-value">{sellerStats.active_alerts_count || stats.total_alerts}</div>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon purple"><ShieldCheck size={22} /></div>
                <div>
                  <div className="stat-label">Audit Log Records</div>
                  <div className="stat-value">{sellerStats.audit_records_count || sellerAuditList.length}</div>
                </div>
              </div>
            </div>

            {/* TAB: PUBLISH DAILY PRICE */}
            {activeTab === 'seller_publish' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <PlusCircle className="text-emerald-600" size={24} />
                      Publish Daily Market Prices (APMC Mandi Entry)
                    </h2>
                    <p className="card-subtitle">
                      Enter daily wholesale trading rates. Every commit executes PostgreSQL validation triggers and records an immutable audit log.
                    </p>
                  </div>
                </div>

                {/* Feedback Banners */}
                {sellerSuccess && (
                  <div className="seller-alert-box">
                    <CheckCircle2 size={22} style={{ color: '#16a34a', flexShrink: 0 }} />
                    <div style={{ flex: 1 }}>
                      <strong>Success:</strong> {sellerSuccess.message}
                      <div style={{ fontSize: '13px', marginTop: '4px' }}>
                        Price ID <code>#{sellerSuccess.record?.price_id}</code> saved for date {sellerSuccess.record?.price_date}.
                        Modal price set to <strong>₹{sellerSuccess.record?.modal_price}/qtl</strong>.
                      </div>
                      {sellerSuccess.alert && (
                        <div style={{ marginTop: '8px', padding: '8px 12px', background: '#fef3c7', borderRadius: '6px', color: '#92400e', fontSize: '13px' }}>
                          ⚠️ <strong>Automatic Trigger Alert:</strong> {sellerSuccess.alert.alert_message}
                        </div>
                      )}
                    </div>
                  </div>
                )}

                {sellerError && (
                  <div className="alert-box warning" style={{ marginBottom: '20px' }}>
                    <AlertTriangle size={20} />
                    <div>{sellerError}</div>
                  </div>
                )}

                {/* Price Entry Form */}
                <form onSubmit={handleSellerPriceSubmit} className="form-grid" style={{ gridTemplateColumns: 'repeat(auto-fit, minmax(260px, 1fr))' }}>
                  {/* Market (Locked to assigned) */}
                  <div className="form-group">
                    <label className="form-label">
                      <Building2 size={14} /> Assigned Mandi:
                    </label>
                    <select
                      value={sellerForm.market_id}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, market_id: e.target.value }))}
                      className="form-select"
                      required
                    >
                      <option value="">-- Select Authorized Mandi --</option>
                      {assignedMarkets.map(m => (
                        <option key={m.market_id} value={m.market_id}>
                          {m.market_name} ({m.district})
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* Crop */}
                  <div className="form-group">
                    <label className="form-label">
                      <Wheat size={14} /> Crop Produce:
                    </label>
                    <select
                      value={sellerForm.crop_id}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, crop_id: e.target.value }))}
                      className="form-select"
                      required
                    >
                      {crops.map(c => (
                        <option key={c.crop_id} value={c.crop_id}>
                          {c.crop_name} ({c.category})
                        </option>
                      ))}
                    </select>
                  </div>

                  {/* Date */}
                  <div className="form-group">
                    <label className="form-label">
                      <Calendar size={14} /> Price Date:
                    </label>
                    <input
                      type="date"
                      value={sellerForm.price_date}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, price_date: e.target.value }))}
                      className="form-input"
                      required
                    />
                  </div>

                  {/* Min Price */}
                  <div className="form-group">
                    <label className="form-label">
                      <IndianRupee size={14} /> Minimum Price (₹/qtl):
                    </label>
                    <input
                      type="number"
                      step="1"
                      min="1"
                      placeholder="e.g. 2300"
                      value={sellerForm.min_price}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, min_price: e.target.value }))}
                      className="form-input"
                      required
                    />
                  </div>

                  {/* Modal Price */}
                  <div className="form-group">
                    <label className="form-label">
                      <Award size={14} /> Modal / Benchmark Price (₹/qtl):
                    </label>
                    <input
                      type="number"
                      step="1"
                      min="1"
                      placeholder="e.g. 2550"
                      value={sellerForm.modal_price}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, modal_price: e.target.value }))}
                      className="form-input"
                      required
                    />
                  </div>

                  {/* Max Price */}
                  <div className="form-group">
                    <label className="form-label">
                      <IndianRupee size={14} /> Maximum Price (₹/qtl):
                    </label>
                    <input
                      type="number"
                      step="1"
                      min="1"
                      placeholder="e.g. 2700"
                      value={sellerForm.max_price}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, max_price: e.target.value }))}
                      className="form-input"
                      required
                    />
                  </div>

                  {/* Arrival Quantity */}
                  <div className="form-group">
                    <label className="form-label">
                      Arrival Volume in Quintals (Optional):
                    </label>
                    <input
                      type="number"
                      step="1"
                      min="0"
                      placeholder="e.g. 150"
                      value={sellerForm.quantity_qtl}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, quantity_qtl: e.target.value }))}
                      className="form-input"
                    />
                  </div>

                  {/* Market Remarks */}
                  <div className="form-group">
                    <label className="form-label">
                      Market Remarks / Quality Notes (Optional):
                    </label>
                    <input
                      type="text"
                      placeholder="e.g. Heavy festive arrivals, strong mill buying"
                      value={sellerForm.remarks}
                      onChange={(e) => setSellerForm(prev => ({ ...prev, remarks: e.target.value }))}
                      className="form-input"
                    />
                  </div>

                  {/* Submit Button */}
                  <div style={{ gridColumn: '1 / -1', marginTop: '10px' }}>
                    <button
                      type="submit"
                      disabled={sellerLoading}
                      className="btn-primary"
                      style={{ width: '100%', padding: '14px', fontSize: '16px' }}
                    >
                      <Check size={18} />
                      {sellerLoading ? 'Validating & Committing in PostgreSQL...' : 'Publish & Save Price Record'}
                    </button>
                  </div>
                </form>
              </div>
            )}

            {/* TAB: MANAGE MANDI PRICES & HISTORY */}
            {activeTab === 'seller_history' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <History className="text-emerald-600" size={24} />
                      Manage Mandi Prices &amp; Trading History
                    </h2>
                    <p className="card-subtitle">
                      Wholesale price entries logged for your assigned agricultural markets.
                    </p>
                  </div>
                </div>

                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Price ID</th>
                        <th>Trading Date</th>
                        <th>Market (Mandi)</th>
                        <th>Crop</th>
                        <th>Modal Price</th>
                        <th>Range (Min - Max)</th>
                        <th>Volume (qtl)</th>
                        <th>Remarks</th>
                        <th>Action</th>
                      </tr>
                    </thead>
                    <tbody>
                      {sellerPricesList.map((p) => (
                        <tr key={p.price_id}>
                          <td><strong>#{p.price_id}</strong></td>
                          <td>{p.price_date}</td>
                          <td><strong>{p.market_name}</strong></td>
                          <td>{p.crop_name}</td>
                          <td>
                            <strong style={{ color: '#15803d', fontSize: '15px' }}>
                              {formatINR(p.modal_price)}
                            </strong>
                            <span style={{ fontSize: '12px', color: '#64748b' }}>/qtl</span>
                          </td>
                          <td style={{ fontSize: '13px', color: '#64748b' }}>
                            {formatINR(p.min_price)} – {formatINR(p.max_price)}
                          </td>
                          <td>{p.quantity_qtl ? `${p.quantity_qtl} qtl` : '-'}</td>
                          <td style={{ fontSize: '13px', color: '#475569' }}>{p.remarks || '-'}</td>
                          <td>
                            <button
                              onClick={() => handleEditExistingPrice(p)}
                              className="btn-primary"
                              style={{ padding: '4px 10px', fontSize: '12px' }}
                            >
                              <Edit3 size={13} /> Update
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB: PRICE AUDIT TRAIL */}
            {activeTab === 'seller_audit' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <ShieldCheck className="text-emerald-600" size={24} />
                      Immutable Price Audit Log (PRICE_AUDIT)
                    </h2>
                    <p className="card-subtitle">
                      Populated automatically by the PL/pgSQL trigger <code>trg_price_audit</code> whenever a price is inserted or updated.
                    </p>
                  </div>
                </div>

                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Audit ID</th>
                        <th>Action</th>
                        <th>Market</th>
                        <th>Crop</th>
                        <th>Trading Date</th>
                        <th>Prior Modal</th>
                        <th>New Modal</th>
                        <th>Changed By</th>
                        <th>Timestamp</th>
                      </tr>
                    </thead>
                    <tbody>
                      {sellerAuditList.map((a) => (
                        <tr key={a.audit_id}>
                          <td>#{a.audit_id}</td>
                          <td>
                            <span className={`audit-action-badge ${a.action.toLowerCase()}`}>
                              {a.action}
                            </span>
                          </td>
                          <td>{a.market_name}</td>
                          <td><strong>{a.crop_name}</strong></td>
                          <td>{a.price_date}</td>
                          <td>{a.old_modal_price ? formatINR(a.old_modal_price) : <span style={{ color: '#94a3b8' }}>None (New)</span>}</td>
                          <td><strong style={{ color: '#15803d' }}>{formatINR(a.new_modal_price)}</strong></td>
                          <td><code>{a.changed_by}</code></td>
                          <td style={{ fontSize: '12px', color: '#64748b' }}>
                            {new Date(a.changed_at).toLocaleString()}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ================================================================= */}
        {/* VIEW B: FARMER DASHBOARD (ORIGINAL PRESERVED & LIVE-LINKED)       */}
        {/* ================================================================= */}
        {currentUser.role === 'FARMER' && (
          <div>
            {/* Dashboard Overview Cards */}
            <div className="stats-grid">
              <div className="stat-card">
                <div className="stat-icon green"><Users size={22} /></div>
                <div>
                  <div className="stat-label">Registered Farmers</div>
                  <div className="stat-value">{stats.total_farmers}</div>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon blue"><Wheat size={22} /></div>
                <div>
                  <div className="stat-label">Available Crops</div>
                  <div className="stat-value">{stats.total_crops}</div>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon purple"><Building2 size={22} /></div>
                <div>
                  <div className="stat-label">Monitored Mandis</div>
                  <div className="stat-value">{stats.total_markets}</div>
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-icon amber"><Database size={22} /></div>
                <div>
                  <div className="stat-label">Recorded Prices</div>
                  <div className="stat-value">{stats.total_prices}</div>
                </div>
              </div>
            </div>

            {/* TAB 1: BEST MARKET ADVISOR */}
            {activeTab === 'advisor' && (
              <div>
                <div className="content-card">
                  <div className="card-header">
                    <div>
                      <h2 className="card-title">
                        <Award className="text-emerald-600" size={24} />
                        Find the Best Market to Sell Your Crop
                      </h2>
                      <p className="card-subtitle">
                        Select your harvested crop and enter quantity in quintals to see where you get the highest recorded price.
                      </p>
                    </div>
                  </div>

                  {/* Form */}
                  <form onSubmit={handleAdvisorSubmit} className="form-grid">
                    <div className="form-group">
                      <label className="form-label">
                        <Wheat size={14} /> Select Crop:
                      </label>
                      <select
                        value={selectedCropId}
                        onChange={(e) => setSelectedCropId(e.target.value)}
                        className="form-select"
                      >
                        {crops.map((c) => (
                          <option key={c.crop_id} value={c.crop_id}>
                            {c.crop_name} ({c.category} • {c.season})
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="form-group">
                      <label className="form-label">
                        <IndianRupee size={14} /> Quantity (in Quintals):
                      </label>
                      <input
                        type="number"
                        min="1"
                        max="10000"
                        step="1"
                        value={quantity}
                        onChange={(e) => setQuantity(Number(e.target.value))}
                        className="form-input"
                        placeholder="Enter quintals (e.g. 50)"
                      />
                    </div>

                    <div className="form-group">
                      <label className="form-label">
                        <MapPin size={14} /> Location / District Filter:
                      </label>
                      <select
                        value={selectedDistrict}
                        onChange={(e) => setSelectedDistrict(e.target.value)}
                        className="form-select"
                      >
                        {districts.map((d) => (
                          <option key={d} value={d}>
                            {d === 'All' ? 'All Districts (Recommended)' : `${d} District Only`}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <button type="submit" disabled={advisorLoading} className="btn-primary w-full">
                        <Search size={16} />
                        {advisorLoading ? 'Evaluating...' : 'Find Best Market'}
                      </button>
                    </div>
                  </form>

                  {/* Error Message */}
                  {advisorError && (
                    <div className="alert-box warning">
                      <AlertTriangle size={18} />
                      <div>{advisorError}</div>
                    </div>
                  )}

                  {/* Date Transparency Warning */}
                  {advisorData?.has_different_dates_warning && (
                    <div className="alert-box warning">
                      <Calendar size={18} />
                      <div>
                        <strong>Date Transparency Notice:</strong> The recorded prices for this crop were logged on different dates (
                        {advisorData.dates_recorded?.join(', ')}). Prices recorded on different dates may reflect different trading sessions.
                      </div>
                    </div>
                  )}

                  {/* Top Market Banner */}
                  {advisorData?.best_market && (
                    <div className="best-market-banner">
                      <div>
                        <span className="banner-badge">
                          <Award size={14} /> Highest Recorded Price
                        </span>
                        <h3 className="banner-market-name">{advisorData.best_market.market_name}</h3>
                        <p className="banner-market-sub">
                          📍 {advisorData.best_market.district}, {advisorData.best_market.state} • Price Date: {advisorData.best_market.price_date}
                        </p>
                      </div>

                      <div className="banner-figures">
                        <div>
                          <div className="banner-metric-label">Recorded Modal Price</div>
                          <div className="banner-metric-value">{formatINR(advisorData.best_market.modal_price)} / qtl</div>
                        </div>
                        <div>
                          <div className="banner-metric-label">Estimated Gross Revenue</div>
                          <div className="banner-metric-value" style={{ color: '#15803d' }}>
                            {formatINR(advisorData.best_market.estimated_gross_revenue)}
                          </div>
                        </div>
                        {advisorData.max_earnings_gain > 0 && (
                          <div className="banner-gain-chip">
                            📈 Potential +{formatINR(advisorData.max_earnings_gain)} extra earnings
                          </div>
                        )}
                      </div>
                    </div>
                  )}

                  {/* Comparison Table */}
                  {advisorData && advisorData.markets?.length > 0 ? (
                    <div>
                      <h3 style={{ fontSize: '17px', fontWeight: 700, margin: '20px 0 12px 0' }}>
                        Ranked Market Comparison for {quantity} Quintals of {selectedCropName}
                      </h3>

                      <div className="table-container">
                        <table className="data-table">
                          <thead>
                            <tr>
                              <th>Rank</th>
                              <th>Market (Mandi)</th>
                              <th>District</th>
                              <th>Price Date</th>
                              <th>Price per Quintal (Modal)</th>
                              <th>Daily Range (Min - Max)</th>
                              <th>Estimated Gross Revenue</th>
                              <th>Gain vs Lowest Mandi</th>
                            </tr>
                          </thead>
                          <tbody>
                            {advisorData.markets.map((m) => (
                              <tr key={m.market_id} className={m.is_highest_price ? 'top-row' : ''}>
                                <td><span style={{ fontWeight: 700 }}>#{m.rank}</span></td>
                                <td>
                                  <strong>{m.market_name}</strong>{' '}
                                  {m.is_highest_price && (
                                    <span className="badge top-price">Highest Price</span>
                                  )}
                                </td>
                                <td>{m.district}</td>
                                <td>
                                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: '4px', color: '#64748b', fontSize: '13px' }}>
                                    <Calendar size={13} /> {m.price_date}
                                  </span>
                                </td>
                                <td>
                                  <span style={{ fontSize: '15px', fontWeight: 800, color: m.is_highest_price ? '#15803d' : '#1e293b' }}>
                                    {formatINR(m.modal_price)}
                                  </span>{' '}
                                  <span style={{ fontSize: '12px', color: '#64748b' }}>/ qtl</span>
                                </td>
                                <td style={{ fontSize: '13px', color: '#64748b' }}>
                                  {formatINR(m.min_price)} – {formatINR(m.max_price)}
                                </td>
                                <td>
                                  <span style={{ fontSize: '16px', fontWeight: 800, color: '#15803d' }}>
                                    {formatINR(m.estimated_gross_revenue)}
                                  </span>
                                </td>
                                <td>
                                  {m.difference_vs_lowest_revenue > 0 ? (
                                    <span style={{ color: '#16a34a', fontWeight: 700 }}>
                                      +{formatINR(m.difference_vs_lowest_revenue)}
                                    </span>
                                  ) : (
                                    <span style={{ color: '#64748b', fontSize: '13px' }}>Lowest baseline</span>
                                  )}
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>

                      {/* Selling Cost Disclaimer */}
                      <div className="alert-box info" style={{ marginTop: '20px' }}>
                        <CheckCircle2 size={18} />
                        <div>
                          <strong>Important Farmer Advice:</strong> Gross revenue is estimated as <em>Quantity ({quantity} qtl) × recorded modal price</em>.
                          Actual net profit depends on distance, transportation freight, labour loading fees, and mandi commission charges. Always consider travel distance before choosing a market!
                        </div>
                      </div>
                    </div>
                  ) : (
                    !advisorLoading && (
                      <div style={{ textAlign: 'center', padding: '40px', color: '#64748b' }}>
                        <Wheat size={40} style={{ opacity: 0.3, margin: '0 auto 12px auto' }} />
                        <p style={{ fontWeight: 600 }}>No recorded price records found for this crop in the selected location.</p>
                      </div>
                    )
                  )}
                </div>

                {/* Benefits section */}
                <div className="content-card">
                  <h3 className="card-title">
                    <HelpCircle className="text-emerald-600" size={22} />
                    How this System Empowers Indian Farmers
                  </h3>
                  <div className="benefits-grid">
                    <div className="benefit-card">
                      <div className="benefit-num">1</div>
                      <div className="benefit-text">
                        <h4>Price Transparency</h4>
                        <p>Aggregates prices from multiple mandis so farmers don't rely on local rumors or middlemen.</p>
                      </div>
                    </div>
                    <div className="benefit-card">
                      <div className="benefit-num">2</div>
                      <div className="benefit-text">
                        <h4>Gross Revenue Estimation</h4>
                        <p>Instantly projects gross earnings based on exact harvested quintals before traveling to mandi.</p>
                      </div>
                    </div>
                    <div className="benefit-card">
                      <div className="benefit-num">3</div>
                      <div className="benefit-text">
                        <h4>Earn More Money</h4>
                        <p>Highlights the mandi with the highest recorded price, potentially adding thousands of rupees per harvest.</p>
                      </div>
                    </div>
                    <div className="benefit-card">
                      <div className="benefit-num">4</div>
                      <div className="benefit-text">
                        <h4>Price Volatility Protection</h4>
                        <p>Database triggers flag sudden price crashes or surges exceeding 20% in real-time.</p>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* TAB 2: PRICE CHART */}
            {activeTab === 'chart' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <BarChart3 className="text-emerald-600" size={24} />
                      Mandi Price Comparison for {selectedCropName}
                    </h2>
                    <p className="card-subtitle">
                      Visual bar comparison of modal prices recorded across regional agricultural markets.
                    </p>
                  </div>
                </div>

                {advisorData && advisorData.markets?.length > 0 ? (
                  <div className="chart-container">
                    {advisorData.markets.map((m) => {
                      const maxPriceInList = advisorData.markets[0].modal_price;
                      const pct = Math.round((m.modal_price / maxPriceInList) * 100);
                      return (
                        <div key={m.market_id} className="bar-row">
                          <div className="bar-label" title={m.market_name}>
                            {m.market_name} ({m.district})
                          </div>
                          <div className="bar-track">
                            <div
                              className={`bar-fill ${m.is_highest_price ? 'highest' : ''}`}
                              style={{ width: `${pct}%` }}
                            >
                              {pct}%
                            </div>
                          </div>
                          <div className="bar-value-text">{formatINR(m.modal_price)}</div>
                        </div>
                      );
                    })}
                  </div>
                ) : (
                  <p style={{ color: '#64748b', padding: '20px 0' }}>Select a crop in the Advisor tab to view price comparison.</p>
                )}
              </div>
            )}

            {/* TAB 3: PRICE ALERTS */}
            {activeTab === 'alerts' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <AlertTriangle className="text-amber-500" size={24} />
                      Automated Price Alerts (Database Trigger trg_price_alert)
                    </h2>
                    <p className="card-subtitle">
                      Generated automatically by PL/pgSQL database trigger when a newly logged price deviates by &gt;20% from the 7-day average.
                    </p>
                  </div>
                </div>

                {priceAlerts.length > 0 ? (
                  <div className="table-container">
                    <table className="data-table">
                      <thead>
                        <tr>
                          <th>Alert ID</th>
                          <th>Date</th>
                          <th>Crop</th>
                          <th>Market (Mandi)</th>
                          <th>Deviation %</th>
                          <th>Severity</th>
                          <th>Direction</th>
                          <th>Alert Message</th>
                        </tr>
                      </thead>
                      <tbody>
                        {priceAlerts.map((a) => (
                          <tr key={a.alert_id}>
                            <td><strong>#{a.alert_id}</strong></td>
                            <td>{a.alert_date}</td>
                            <td><strong>{a.crop_name}</strong></td>
                            <td>{a.market_name} ({a.market_district})</td>
                            <td>
                              <span style={{ fontWeight: 800, color: a.deviation_pct > 0 ? '#15803d' : '#b91c1c' }}>
                                {a.deviation_pct > 0 ? `+${a.deviation_pct}%` : `${a.deviation_pct}%`}
                              </span>
                            </td>
                            <td>
                              <span className={`badge ${a.alert_severity === 'CRITICAL' ? 'critical' : 'high'}`}>
                                {a.alert_severity}
                              </span>
                            </td>
                            <td>{a.alert_direction}</td>
                            <td style={{ fontSize: '13px' }}>{a.alert_message}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <div style={{ textAlign: 'center', padding: '40px', color: '#64748b' }}>
                    <CheckCircle2 size={36} style={{ color: '#16a34a', margin: '0 auto 10px auto' }} />
                    <p style={{ fontWeight: 600 }}>No unusual price alerts recorded yet.</p>
                  </div>
                )}
              </div>
            )}

            {/* TAB 4: FARMERS */}
            {activeTab === 'farmers' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <Users className="text-emerald-600" size={24} />
                      Registered Farmers Master Table (FARMER)
                    </h2>
                    <p className="card-subtitle">
                      Agricultural producers with landholdings, contact numbers, and village locations.
                    </p>
                  </div>
                </div>

                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Farmer ID</th>
                        <th>Full Name</th>
                        <th>Telephone</th>
                        <th>Village</th>
                        <th>District</th>
                        <th>Total Land (Acres)</th>
                        <th>Parcels Owned</th>
                      </tr>
                    </thead>
                    <tbody>
                      {farmersList.map((f) => (
                        <tr key={f.farmer_id}>
                          <td>#{f.farmer_id}</td>
                          <td><strong>{f.name}</strong></td>
                          <td>{f.phone}</td>
                          <td>{f.village}</td>
                          <td>{f.district}</td>
                          <td>{f.land_area_acres} acres</td>
                          <td>{f.total_fields} parcels</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB 5: CROPS & EER */}
            {activeTab === 'crops' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <Wheat className="text-emerald-600" size={24} />
                      Crop Masters &amp; Extended EER Specialization (1:1 Subclasses)
                    </h2>
                    <p className="card-subtitle">
                      Demonstrating Extended Entity-Relationship disjoint subclasses (CEREAL_CROP, VEGETABLE_CROP, FRUIT_CROP).
                    </p>
                  </div>
                </div>

                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Crop ID</th>
                        <th>Crop Name</th>
                        <th>Category</th>
                        <th>Season</th>
                        <th>EER Specialization Table</th>
                        <th>Specialized Biological Attribute</th>
                      </tr>
                    </thead>
                    <tbody>
                      {crops.map((c) => {
                        let eerTable = 'None';
                        let eerAttr = '-';
                        if (c.avg_duration_days) {
                          eerTable = 'CEREAL_CROP';
                          eerAttr = `${c.avg_duration_days} days field maturity duration`;
                        } else if (c.perishability_days) {
                          eerTable = 'VEGETABLE_CROP';
                          eerAttr = `${c.perishability_days} days perishability shelf life`;
                        } else if (c.harvest_cycle_years) {
                          eerTable = 'FRUIT_CROP';
                          eerAttr = `${c.harvest_cycle_years} years harvest cycle`;
                        }
                        return (
                          <tr key={c.crop_id}>
                            <td>#{c.crop_id}</td>
                            <td><strong>{c.crop_name}</strong></td>
                            <td><span className="badge category">{c.category}</span></td>
                            <td>{c.season}</td>
                            <td><code style={{ color: '#15803d', fontWeight: 700 }}>{eerTable}</code></td>
                            <td>{eerAttr}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB 6: MANDIS */}
            {activeTab === 'markets' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <Building2 className="text-emerald-600" size={24} />
                      Monitored APMC Mandis (MARKET)
                    </h2>
                    <p className="card-subtitle">
                      Agricultural produce market committees across Maharashtra agricultural zones.
                    </p>
                  </div>
                </div>

                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Market ID</th>
                        <th>Market Name</th>
                        <th>District</th>
                        <th>State</th>
                      </tr>
                    </thead>
                    <tbody>
                      {marketsList.map((m) => (
                        <tr key={m.market_id}>
                          <td>#{m.market_id}</td>
                          <td><strong>{m.market_name}</strong></td>
                          <td>{m.district}</td>
                          <td>{m.state}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB 7: YIELDS */}
            {activeTab === 'yields' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <FileSpreadsheet className="text-emerald-600" size={24} />
                      Recorded Crop Yields (YIELD_RECORD &amp; VIEW)
                    </h2>
                    <p className="card-subtitle">
                      Historical sowing vs. harvest dates, expected vs. actual yields, and variance analysis.
                    </p>
                  </div>
                </div>

                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Yield ID</th>
                        <th>Farmer</th>
                        <th>Crop</th>
                        <th>Soil Type</th>
                        <th>Sowing Date</th>
                        <th>Harvest Date</th>
                        <th>Duration</th>
                        <th>Expected (qtl)</th>
                        <th>Actual (qtl)</th>
                        <th>Variance</th>
                        <th>Status</th>
                      </tr>
                    </thead>
                    <tbody>
                      {yieldsList.map((y) => (
                        <tr key={y.yield_id}>
                          <td>#{y.yield_id}</td>
                          <td><strong>{y.farmer_name}</strong></td>
                          <td>{y.crop_name}</td>
                          <td>{y.soil_type}</td>
                          <td>{y.sowing_date}</td>
                          <td>{y.harvest_date}</td>
                          <td>{y.duration_days} days</td>
                          <td>{y.expected_yield_qtl} qtl</td>
                          <td><strong>{y.actual_yield_qtl} qtl</strong></td>
                          <td style={{ color: y.yield_variance_qtl >= 0 ? '#15803d' : '#dc2626', fontWeight: 700 }}>
                            {y.yield_variance_qtl >= 0 ? `+${y.yield_variance_qtl}` : y.yield_variance_qtl} qtl
                          </td>
                          <td>
                            <span className={`badge ${y.yield_status === 'Exceeded Expected' ? 'top-price' : 'category'}`}>
                              {y.yield_status}
                            </span>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}

            {/* TAB 8: SALES */}
            {activeTab === 'sales' && (
              <div className="content-card">
                <div className="card-header">
                  <div>
                    <h2 className="card-title">
                      <IndianRupee className="text-emerald-600" size={24} />
                      Recent Sales Transactions (SALE_TRANSACTION)
                    </h2>
                    <p className="card-subtitle">
                      Realized farmer sales in mandis. Total Amount is automatically calculated using a generated STORED virtual column.
                    </p>
                  </div>
                </div>

                <div className="table-container">
                  <table className="data-table">
                    <thead>
                      <tr>
                        <th>Sale ID</th>
                        <th>Date</th>
                        <th>Farmer</th>
                        <th>Market (Mandi)</th>
                        <th>Crop</th>
                        <th>Quantity (qtl)</th>
                        <th>Price / qtl</th>
                        <th>Total Amount (Generated Column)</th>
                      </tr>
                    </thead>
                    <tbody>
                      {salesList.map((s) => (
                        <tr key={s.sale_id}>
                          <td>#{s.sale_id}</td>
                          <td>{s.sale_date}</td>
                          <td><strong>{s.farmer_name}</strong></td>
                          <td>{s.market_name} ({s.market_district})</td>
                          <td>{s.crop_name}</td>
                          <td>{s.quantity_qtl} qtl</td>
                          <td>{formatINR(s.price_per_qtl)}</td>
                          <td>
                            <strong style={{ color: '#15803d', fontSize: '15px' }}>
                              {formatINR(s.total_amount)}
                            </strong>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </div>
        )}

        {/* ================================================================= */}
        {/* COMMON TAB: COLLEGE DEMONSTRATION GUIDE                           */}
        {/* ================================================================= */}
        {activeTab === 'demo' && (
          <div className="content-card">
            <div className="card-header">
              <div>
                <h2 className="card-title">
                  <HelpCircle className="text-emerald-600" size={24} />
                  Two-Role College Mini-Project Demonstration Walkthrough
                </h2>
                <p className="card-subtitle">
                  Step-by-step presentation script to demonstrate the seller-to-farmer live data sharing to your professor.
                </p>
              </div>
            </div>

            <div style={{ lineHeight: 1.8, fontSize: '15px' }}>
              <h4 style={{ color: '#15803d', fontWeight: 800, marginTop: '10px' }}>
                Step 1: Explain the Dual-Role Architecture &amp; Problem Statement
              </h4>
              <p style={{ color: '#334155' }}>
                "In traditional agricultural markets, farmers lack real-time price awareness. Our system connects two critical actors:
                <strong>Market Officers (Sellers)</strong> who publish authenticated daily rates for their assigned mandis, and
                <strong>Farmers</strong> who use those real-time rates to decide which mandi gives them the highest revenue."
              </p>

              <h4 style={{ color: '#15803d', fontWeight: 800, marginTop: '20px' }}>
                Step 2: Demonstrate Seller Role &amp; Database Security
              </h4>
              <ul style={{ paddingLeft: '24px', margin: '8px 0', color: '#475569' }}>
                <li>Click <strong>🏢 Seller: Lasalgaon APMC</strong> on the top bar.</li>
                <li>Show that the Mandi dropdown is locked strictly to <em>Lasalgaon APMC</em> via <code>SELLER_MARKET_ASSIGNMENT</code>.</li>
                <li>Enter a new price for <strong>Wheat</strong>: Min ₹2,400, Modal <strong>₹2,600</strong>, Max ₹2,800.</li>
                <li>Click <strong>Publish &amp; Save Price Record</strong>. Point out:
                  <ul style={{ paddingLeft: '20px', marginTop: '4px' }}>
                    <li>The transaction commits in PostgreSQL.</li>
                    <li><code>trg_price_audit</code> immediately logs who modified the price and old vs new values.</li>
                  </ul>
                </li>
              </ul>

              <h4 style={{ color: '#15803d', fontWeight: 800, marginTop: '20px' }}>
                Step 3: Demonstrate Live Farmer Synchronization
              </h4>
              <ul style={{ paddingLeft: '24px', margin: '8px 0', color: '#475569' }}>
                <li>Click <strong>🧑‍🌾 Farmer (Ramesh)</strong> on the top bar.</li>
                <li>Select <strong>Wheat</strong> and enter <strong>50 quintals</strong>.</li>
                <li>Show your teacher:
                  <ul style={{ paddingLeft: '20px', marginTop: '4px' }}>
                    <li>Lasalgaon APMC reflects the new <strong>₹2,600/qtl</strong> price just published by the seller!</li>
                    <li>Estimated gross revenue is recalculated to <strong>₹1,30,000</strong>.</li>
                    <li>The revenue gain increases to <strong>+₹20,500 extra earnings</strong> over Pune Mandi!</li>
                  </ul>
                </li>
              </ul>

              <h4 style={{ color: '#15803d', fontWeight: 800, marginTop: '20px' }}>
                Step 4: Show the Immutable Audit Trail &amp; Triggers
              </h4>
              <ul style={{ paddingLeft: '24px', margin: '8px 0', color: '#475569' }}>
                <li>Switch back to Seller and click the <strong>Price Audit Trail</strong> tab.</li>
                <li>Show the row logged with user <code>officer_lasalgaon</code>, trading date, and previous vs new modal prices.</li>
              </ul>
            </div>
          </div>
        )}

      </main>

      {/* ------------------------------------------------------------------- */}
      {/* 5. LOGIN MODAL DIALOG                                               */}
      {/* ------------------------------------------------------------------- */}
      {isLoginModalOpen && (
        <div className="modal-overlay">
          <div className="modal-dialog">
            <div className="modal-header">
              <div className="modal-title">
                <Lock size={18} /> User Login
              </div>
              <button onClick={() => setIsLoginModalOpen(false)} className="modal-close-btn">
                <X size={20} />
              </button>
            </div>

            <div className="modal-body">
              {loginError && (
                <div className="alert-box warning" style={{ marginBottom: '16px' }}>
                  <AlertTriangle size={18} />
                  <div>{loginError}</div>
                </div>
              )}

              <form onSubmit={(e) => { e.preventDefault(); performLogin(loginForm.username, loginForm.password); }}>
                <div className="form-group" style={{ marginBottom: '16px' }}>
                  <label className="form-label">Username:</label>
                  <input
                    type="text"
                    value={loginForm.username}
                    onChange={(e) => setLoginForm(prev => ({ ...prev, username: e.target.value }))}
                    className="form-input"
                    placeholder="e.g. officer_lasalgaon or farmer_ramesh"
                    required
                  />
                </div>

                <div className="form-group" style={{ marginBottom: '20px' }}>
                  <label className="form-label">Password:</label>
                  <input
                    type="password"
                    value={loginForm.password}
                    onChange={(e) => setLoginForm(prev => ({ ...prev, password: e.target.value }))}
                    className="form-input"
                    placeholder="Enter password (default: Password@123)"
                    required
                  />
                </div>

                <div style={{ display: 'flex', gap: '10px' }}>
                  <button type="submit" disabled={loginLoading} className="btn-primary w-full">
                    {loginLoading ? 'Authenticating...' : 'Sign In'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setIsLoginModalOpen(false)}
                    className="btn-primary"
                    style={{ background: '#64748b' }}
                  >
                    Cancel
                  </button>
                </div>
              </form>

              <div style={{ marginTop: '20px', paddingTop: '16px', borderTop: '1px solid #e2e8f0', fontSize: '12px', color: '#64748b' }}>
                <strong>Demo Passwords:</strong> <code>Password@123</code> for all accounts (admin, officer_lasalgaon, officer_pune, farmer_ramesh).
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ------------------------------------------------------------------- */}
      {/* 6. FOOTER                                                           */}
      {/* ------------------------------------------------------------------- */}
      <footer className="app-footer">
        <div className="container">
          <p>
            <strong>Farmer Market Advisor</strong> • Advanced Database Management Systems (ADBMS) Mini Project
          </p>
          <p style={{ marginTop: '6px', fontSize: '12px' }}>
            College Demo Team: Shivam Chaudhari (E213) • Bhavya Sharma (E223) • Akshat Jain (E257) • PostgreSQL 18.6 • Node.js Express • React Vite
          </p>
        </div>
      </footer>
    </div>
  );
}
