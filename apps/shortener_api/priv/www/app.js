// DOM Elements
const viewShorten = document.getElementById('view-shorten');
const viewStats = document.getElementById('view-stats');
const navStats = document.getElementById('nav-stats');
const btnBack = document.getElementById('btn-back');

const shortenForm = document.getElementById('shorten-form');
const btnToggleOptions = document.getElementById('btn-toggle-options');
const advancedOptions = document.getElementById('advanced-options');
const resultContainer = document.getElementById('result-container');
const errorContainer = document.getElementById('error-container');

const shortLink = document.getElementById('short-link');
const btnCopy = document.getElementById('btn-copy');
const btnQr = document.getElementById('btn-qr');
const successMsg = document.querySelector('.success-msg');

const statsForm = document.getElementById('stats-form');
const statsResult = document.getElementById('stats-result');
const statsError = document.getElementById('stats-error');

const qrModal = document.getElementById('qr-modal');
const closeQr = document.querySelector('.close-modal');
const qrImage = document.getElementById('qr-image');
const qrLink = document.getElementById('qr-link');

// Base URL detection
const API_BASE = window.location.origin;

// Navigation
navStats.addEventListener('click', () => {
    viewShorten.classList.add('hidden');
    viewStats.classList.remove('hidden');
    resultContainer.classList.add('hidden');
    errorContainer.classList.add('hidden');
});

btnBack.addEventListener('click', () => {
    viewStats.classList.add('hidden');
    viewShorten.classList.remove('hidden');
    statsResult.classList.add('hidden');
    statsError.classList.add('hidden');
});

// Toggle Advanced Options
btnToggleOptions.addEventListener('click', () => {
    advancedOptions.classList.toggle('hidden');
    btnToggleOptions.classList.toggle('open');
});

// Main Shorten Logic
shortenForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    // Hide previous UI states
    resultContainer.classList.add('hidden');
    errorContainer.classList.add('hidden');
    const btnSubmit = document.getElementById('btn-shorten');
    btnSubmit.style.opacity = '0.7';
    btnSubmit.style.pointerEvents = 'none';

    // Gather data
    const payload = {
        url: document.getElementById('url-input').value
    };

    const customCode = document.getElementById('custom-code').value.trim();
    if (customCode) payload.custom_code = customCode;

    const pwd = document.getElementById('password').value;
    if (pwd) payload.password = pwd;

    const ttl = document.getElementById('ttl').value;
    if (ttl) payload.ttl = parseInt(ttl, 10);

    const webhookUrl = document.getElementById('webhook-url').value.trim();
    if (webhookUrl) payload.webhook_url = webhookUrl;

    try {
        const response = await fetch(`${API_BASE}/api/shorten`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Something went wrong');
        }

        // Show result
        shortLink.href = data.short_url;
        shortLink.textContent = data.short_url;

        // Setup QR button
        btnQr.onclick = () => showQr(data.short_code, data.short_url);

        resultContainer.classList.remove('hidden');

    } catch (err) {
        errorContainer.textContent = err.message;
        errorContainer.classList.remove('hidden');
    } finally {
        btnSubmit.style.opacity = '1';
        btnSubmit.style.pointerEvents = 'auto';
    }
});

// Copy to Clipboard
btnCopy.addEventListener('click', () => {
    navigator.clipboard.writeText(shortLink.href).then(() => {
        successMsg.classList.add('show');
        setTimeout(() => successMsg.classList.remove('show'), 2000);
    });
});

// QR Modal Logic
function showQr(code, fullUrl) {
    qrImage.src = `${API_BASE}/api/qr/${code}`;
    qrLink.textContent = fullUrl;
    qrModal.classList.remove('hidden');
}

closeQr.addEventListener('click', () => {
    qrModal.classList.add('hidden');
});

// Close modal on outside click
window.addEventListener('click', (e) => {
    if (e.target == qrModal) {
        qrModal.classList.add('hidden');
    }
});

// Stats Logic
statsForm.addEventListener('submit', async (e) => {
    e.preventDefault();

    statsResult.classList.add('hidden');
    statsError.classList.add('hidden');

    let code = document.getElementById('stats-code').value.trim();
    // In case they pasted the full URL, extract the code
    if (code.includes('/')) {
        const parts = code.split('/');
        code = parts[parts.length - 1];
    }

    try {
        const response = await fetch(`${API_BASE}/api/stats/${code}`);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'Stats not found');
        }

        document.getElementById('stat-clicks').textContent = data.click_count;
        document.getElementById('stat-dest').href = data.long_url;
        document.getElementById('stat-dest').textContent = data.long_url;

        const created = new Date(data.created_at).toLocaleString();
        document.getElementById('stat-created').textContent = created;

        if (data.expires_at) {
            const expires = new Date(data.expires_at).toLocaleString();
            document.getElementById('stat-expires').textContent = expires;
        } else {
            document.getElementById('stat-expires').textContent = 'Never';
        }

        statsResult.classList.remove('hidden');

    } catch (err) {
        statsError.textContent = err.message;
        statsError.classList.remove('hidden');
    }
});
