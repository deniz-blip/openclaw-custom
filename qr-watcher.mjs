#!/usr/bin/env node
/**
 * QR Watcher — captures WhatsApp QR codes from OpenClaw gateway stdout
 * and POSTs them to Supabase so the dashboard can display them.
 * 
 * Usage: node openclaw.mjs gateway 2>&1 | node qr-watcher.mjs
 * 
 * OpenClaw (Baileys) outputs QR code data in the logs when WhatsApp
 * needs pairing. This script detects the QR string and saves it.
 */

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
const INSTANCE_ID = process.env.INSTANCE_ID;

let lastQR = '';
let qrCount = 0;

async function saveQR(qrData) {
    if (!SUPABASE_URL || !SUPABASE_KEY || !INSTANCE_ID) {
        console.log('[qr-watcher] Missing env vars — cannot save QR');
        return;
    }

    try {
        const res = await fetch(`${SUPABASE_URL}/rest/v1/deployments?id=eq.${INSTANCE_ID}`, {
            method: 'PATCH',
            headers: {
                'apikey': SUPABASE_KEY,
                'Authorization': `Bearer ${SUPABASE_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ whatsapp_qr: qrData }),
        });
        if (res.ok) {
            console.log(`[qr-watcher] QR #${++qrCount} saved to Supabase ✓`);
        } else {
            console.log(`[qr-watcher] Failed to save QR: ${res.status}`);
        }
    } catch (err) {
        console.log('[qr-watcher] Error saving QR:', err.message);
    }
}

async function clearQR() {
    if (!SUPABASE_URL || !SUPABASE_KEY || !INSTANCE_ID) return;
    try {
        await fetch(`${SUPABASE_URL}/rest/v1/deployments?id=eq.${INSTANCE_ID}`, {
            method: 'PATCH',
            headers: {
                'apikey': SUPABASE_KEY,
                'Authorization': `Bearer ${SUPABASE_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ whatsapp_qr: null }),
        });
        console.log('[qr-watcher] QR cleared (session established)');
    } catch (_) { }
}

// Read stdin line by line
import { createInterface } from 'readline';

const rl = createInterface({ input: process.stdin, terminal: false });

let qrBuffer = '';
let capturing = false;

rl.on('line', (line) => {
    // Always pass through to stdout so logs still work
    process.stdout.write(line + '\n');

    // Detect QR code patterns from Baileys/OpenClaw
    // Pattern 1: Direct QR data string (common in Baileys)
    // The QR code data is typically a base64-like string on its own line
    const qrDataMatch = line.match(/QR\s*(?:code)?[\s:]*([A-Za-z0-9+/=,@]{20,})/i);
    if (qrDataMatch) {
        const qr = qrDataMatch[1];
        if (qr !== lastQR) {
            lastQR = qr;
            saveQR(qr);
        }
        return;
    }

    // Pattern 2: "Scan this QR code" followed by data
    if (/scan.*qr|qr.*scan|pairing.*qr|qr.*pair/i.test(line)) {
        capturing = true;
        qrBuffer = '';
        return;
    }

    // Pattern 3: WhatsApp connected / authenticated
    if (/whatsapp.*connect|authenticated|session.*saved|login.*success|connection.*open/i.test(line)) {
        clearQR();
        capturing = false;
        return;
    }

    // If we're in capture mode, collect potential QR data
    if (capturing && line.trim().length > 10) {
        // Check if this looks like QR data (base64-ish, alphanumeric)
        const trimmed = line.trim();
        if (/^[A-Za-z0-9+/=,@._\-]{10,}$/.test(trimmed)) {
            if (trimmed !== lastQR) {
                lastQR = trimmed;
                saveQR(trimmed);
            }
            capturing = false;
        }
    }
});

rl.on('close', () => {
    console.log('[qr-watcher] Gateway output stream closed');
});

console.log('[qr-watcher] WhatsApp QR watcher started — monitoring gateway output...');
