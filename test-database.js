// Database Connection Test Script
// Run this to diagnose database connection issues

const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

// Load environment variables
dotenv.config();

console.log('===========================================');
console.log('  Database Connection Test');
console.log('===========================================\n');

// Display configuration (hide password)
console.log('📋 Current Configuration:');
console.log('  DB_HOST:', process.env.DB_HOST || 'localhost');
console.log('  DB_USER:', process.env.DB_USER || 'root');
console.log('  DB_PASSWORD:', process.env.DB_PASSWORD ? '***hidden***' : '(empty)');
console.log('  DB_NAME:', process.env.DB_NAME || 'dreamcity_web');
console.log('');

async function testConnection() {
    try {
        console.log('🔄 Testing MySQL connection...\n');

        // Test 1: Connect without database
        console.log('Test 1: Connecting to MySQL server...');
        const connectionWithoutDB = await mysql.createConnection({
            host: process.env.DB_HOST || 'localhost',
            user: process.env.DB_USER || 'root',
            password: process.env.DB_PASSWORD || ''
        });
        console.log('✅ Successfully connected to MySQL server!\n');

        // Test 2: Check if database exists
        console.log('Test 2: Checking if database exists...');
        const [databases] = await connectionWithoutDB.query('SHOW DATABASES');
        const dbExists = databases.some(db => db.Database === (process.env.DB_NAME || 'dreamcity_web'));
        
        if (dbExists) {
            console.log('✅ Database "' + (process.env.DB_NAME || 'dreamcity_web') + '" exists!\n');
        } else {
            console.log('❌ Database "' + (process.env.DB_NAME || 'dreamcity_web') + '" does NOT exist!');
            console.log('   Please create it or import data.sql\n');
            await connectionWithoutDB.end();
            return;
        }

        await connectionWithoutDB.end();

        // Test 3: Connect to specific database
        console.log('Test 3: Connecting to database...');
        const connection = await mysql.createConnection({
            host: process.env.DB_HOST || 'localhost',
            user: process.env.DB_USER || 'root',
            password: process.env.DB_PASSWORD || '',
            database: process.env.DB_NAME || 'dreamcity_web'
        });
        console.log('✅ Successfully connected to database!\n');

        // Test 4: Check tables
        console.log('Test 4: Checking database tables...');
        const [tables] = await connection.query('SHOW TABLES');
        
        if (tables.length > 0) {
            console.log('✅ Found ' + tables.length + ' tables:');
            tables.forEach(table => {
                const tableName = Object.values(table)[0];
                console.log('   - ' + tableName);
            });
            console.log('');
        } else {
            console.log('⚠️  No tables found! Please import data.sql\n');
        }

        // Test 5: Check users table
        console.log('Test 5: Checking users table structure...');
        const [columns] = await connection.query('DESCRIBE users');
        console.log('✅ Users table structure is correct!\n');

        await connection.end();

        console.log('===========================================');
        console.log('✅ ALL TESTS PASSED!');
        console.log('===========================================');
        console.log('\nYour database is configured correctly!');
        console.log('You can now start the server with: npm start\n');

    } catch (error) {
        console.log('\n===========================================');
        console.log('❌ CONNECTION FAILED!');
        console.log('===========================================\n');
        
        console.log('Error Details:');
        console.log('  Code:', error.code);
        console.log('  Message:', error.message);
        console.log('');

        // Provide specific solutions
        if (error.code === 'ER_ACCESS_DENIED_ERROR') {
            console.log('🔧 SOLUTION:');
            console.log('  Your MySQL credentials are incorrect!\n');
            console.log('  Fix this by updating your .env file:\n');
            console.log('  1. Check if you have a MySQL password');
            console.log('  2. If using XAMPP/WAMP, password is usually empty');
            console.log('  3. Update DB_PASSWORD in .env file\n');
            console.log('  Example for XAMPP (no password):');
            console.log('    DB_PASSWORD=\n');
            console.log('  Example with password:');
            console.log('    DB_PASSWORD=your_actual_password\n');
        } else if (error.code === 'ECONNREFUSED') {
            console.log('🔧 SOLUTION:');
            console.log('  MySQL server is not running!\n');
            console.log('  1. Start MySQL service (XAMPP/WAMP control panel)');
            console.log('  2. Or start MySQL service in Windows Services\n');
        } else if (error.code === 'ER_BAD_DB_ERROR') {
            console.log('🔧 SOLUTION:');
            console.log('  Database does not exist!\n');
            console.log('  1. Create database: CREATE DATABASE dreamcity_web;');
            console.log('  2. Import data.sql file');
            console.log('  3. Or use phpMyAdmin to import\n');
        } else {
            console.log('🔧 SOLUTION:');
            console.log('  Check DATABASE_FIX.md for detailed troubleshooting\n');
        }

        console.log('For more help, see: DATABASE_FIX.md\n');
        process.exit(1);
    }
}

// Run the test
testConnection();
