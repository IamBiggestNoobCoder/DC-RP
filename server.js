const express = require('express');
const session = require('express-session');
const passport = require('passport');
const SteamStrategy = require('passport-steam').Strategy;
const mysql = require('mysql2/promise');
const cors = require('cors');
const dotenv = require('dotenv');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Database connection pool
const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'dreamcity_web',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Middleware
app.use(cors({
    origin: process.env.FRONTEND_URL || 'http://localhost:5500',
    credentials: true
}));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Session configuration
app.use(session({
    secret: process.env.SESSION_SECRET || 'dreamcity-rp-secret-key-change-this',
    resave: false,
    saveUninitialized: false,
    cookie: {
        maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production'
    }
}));

// Passport initialization
app.use(passport.initialize());
app.use(passport.session());

// Passport Steam Strategy
passport.use(new SteamStrategy({
    returnURL: process.env.STEAM_RETURN_URL || 'http://localhost:3000/auth/steam/return',
    realm: process.env.STEAM_REALM || 'http://localhost:3000/',
    apiKey: process.env.STEAM_API_KEY
}, async (identifier, profile, done) => {
    try {
        const steamId = profile.id;
        const displayName = profile.displayName;
        const avatar = profile.photos && profile.photos.length > 0 ? profile.photos[2].value : null;
        const profileUrl = profile._json.profileurl;

        // Check if user exists in database
        const [rows] = await pool.execute(
            'SELECT * FROM users WHERE steam_id = ?',
            [steamId]
        );

        let user;
        if (rows.length > 0) {
            // Update existing user
            user = rows[0];
            await pool.execute(
                'UPDATE users SET display_name = ?, avatar_url = ?, profile_url = ?, last_login = NOW() WHERE steam_id = ?',
                [displayName, avatar, profileUrl, steamId]
            );
            user.display_name = displayName;
            user.avatar_url = avatar;
            user.profile_url = profileUrl;
        } else {
            // Create new user
            const [result] = await pool.execute(
                'INSERT INTO users (steam_id, display_name, avatar_url, profile_url, created_at, last_login) VALUES (?, ?, ?, ?, NOW(), NOW())',
                [steamId, displayName, avatar, profileUrl]
            );
            user = {
                id: result.insertId,
                steam_id: steamId,
                display_name: displayName,
                avatar_url: avatar,
                profile_url: profileUrl
            };
        }

        return done(null, user);
    } catch (error) {
        console.error('Steam authentication error:', error);
        return done(error, null);
    }
}));

// Serialize user
passport.serializeUser((user, done) => {
    done(null, user.id);
});

// Deserialize user
passport.deserializeUser(async (id, done) => {
    try {
        const [rows] = await pool.execute('SELECT * FROM users WHERE id = ?', [id]);
        if (rows.length > 0) {
            done(null, rows[0]);
        } else {
            done(new Error('User not found'), null);
        }
    } catch (error) {
        done(error, null);
    }
});

// Middleware to check if user is authenticated
const isAuthenticated = (req, res, next) => {
    if (req.isAuthenticated()) {
        return next();
    }
    res.status(401).json({ error: 'Not authenticated' });
};

// Routes

// Health check
app.get('/', (req, res) => {
    res.json({ 
        message: 'Dream City RP Authentication Server',
        status: 'running',
        version: '1.0.0'
    });
});

// Steam authentication routes
app.get('/auth/steam', passport.authenticate('steam', { failureRedirect: '/login-page.html' }));

app.get('/auth/steam/return',
    passport.authenticate('steam', { failureRedirect: '/login-page.html' }),
    (req, res) => {
        // Successful authentication, redirect to dashboard
        res.redirect(process.env.FRONTEND_URL + '/dashboard.html' || 'http://localhost:5500/dashboard.html');
    }
);

// Check authentication status
app.get('/auth/status', (req, res) => {
    if (req.isAuthenticated()) {
        res.json({
            authenticated: true,
            user: {
                id: req.user.id,
                steam_id: req.user.steam_id,
                display_name: req.user.display_name,
                avatar_url: req.user.avatar_url,
                subscription_tier: req.user.subscription_tier,
                is_whitelisted: req.user.is_whitelisted || false
            }
        });
    } else {
        res.json({ authenticated: false });
    }
});

// Get current user profile
app.get('/api/user/profile', isAuthenticated, async (req, res) => {
    try {
        const [rows] = await pool.execute(
            'SELECT id, steam_id, display_name, avatar_url, profile_url, subscription_tier, queue_priority, is_whitelisted, whitelist_date, created_at, last_login FROM users WHERE id = ?',
            [req.user.id]
        );
        
        if (rows.length > 0) {
            res.json({ success: true, user: rows[0] });
        } else {
            res.status(404).json({ success: false, error: 'User not found' });
        }
    } catch (error) {
        console.error('Error fetching user profile:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});

// Update user subscription
app.post('/api/user/subscription', isAuthenticated, async (req, res) => {
    try {
        const { tier } = req.body;
        const validTiers = ['none', 'silver', 'gold', 'emerald'];
        
        if (!validTiers.includes(tier)) {
            return res.status(400).json({ success: false, error: 'Invalid subscription tier' });
        }

        // Calculate queue priority based on tier
        let queuePriority = 0;
        switch (tier) {
            case 'silver': queuePriority = 10; break;
            case 'gold': queuePriority = 14; break;
            case 'emerald': queuePriority = 25; break;
        }

        await pool.execute(
            'UPDATE users SET subscription_tier = ?, queue_priority = ? WHERE id = ?',
            [tier, queuePriority, req.user.id]
        );

        res.json({ success: true, message: 'Subscription updated successfully' });
    } catch (error) {
        console.error('Error updating subscription:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});

// Get user statistics
app.get('/api/user/stats', isAuthenticated, async (req, res) => {
    try {
        const [rows] = await pool.execute(
            'SELECT * FROM user_stats WHERE user_id = ?',
            [req.user.id]
        );
        
        if (rows.length > 0) {
            res.json({ success: true, stats: rows[0] });
        } else {
            // Create default stats if they don't exist
            await pool.execute(
                'INSERT INTO user_stats (user_id) VALUES (?)',
                [req.user.id]
            );
            res.json({ 
                success: true, 
                stats: {
                    user_id: req.user.id,
                    playtime_hours: 0,
                    total_earnings: 0,
                    total_spent: 0,
                    vehicles_owned: 0,
                    properties_owned: 0
                }
            });
        }
    } catch (error) {
        console.error('Error fetching user stats:', error);
        res.status(500).json({ success: false, error: 'Internal server error' });
    }
});

// Logout
app.get('/auth/logout', (req, res) => {
    req.logout((err) => {
        if (err) {
            return res.status(500).json({ success: false, error: 'Logout failed' });
        }
        res.json({ success: true, message: 'Logged out successfully' });
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({ 
        success: false, 
        error: 'Internal server error',
        message: process.env.NODE_ENV === 'development' ? err.message : undefined
    });
});

// Start server
app.listen(PORT, () => {
    console.log(`🚀 Dream City RP Authentication Server running on port ${PORT}`);
    console.log(`📍 Steam Auth URL: http://localhost:${PORT}/auth/steam`);
    console.log(`📍 Frontend URL: ${process.env.FRONTEND_URL || 'http://localhost:5500'}`);
    console.log(`🔐 Make sure to set your STEAM_API_KEY in .env file`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
    console.log('SIGTERM signal received: closing HTTP server');
    await pool.end();
    process.exit(0);
});
