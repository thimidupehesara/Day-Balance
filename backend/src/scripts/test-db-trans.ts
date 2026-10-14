import { config } from 'dotenv';
config();

async function testConnections() {
  console.log('Testing drizzle with pg Pool...');
  try {
    const { Pool } = await import('pg');
    const { drizzle } = await import('drizzle-orm/node-postgres');
    const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: true });
    const dbPg = drizzle(pool);
    const res = await dbPg.transaction(async (tx) => {
      const { sql } = await import('drizzle-orm');
      return await tx.execute(sql`SELECT 1 as test`);
    });
    console.log('pg Pool transaction success:', res);
    await pool.end();
  } catch (err) {
    console.error('pg Pool failed:', err);
  }

  console.log('Testing drizzle with neon-serverless Pool...');
  try {
    const { Pool } = await import('@neondatabase/serverless');
    const { drizzle } = await import('drizzle-orm/neon-serverless');
    const pool = new Pool({ connectionString: process.env.DATABASE_URL });
    const dbNeon = drizzle(pool);
    const res = await dbNeon.transaction(async (tx) => {
      const { sql } = await import('drizzle-orm');
      return await tx.execute(sql`SELECT 1 as test`);
    });
    console.log('neon Pool transaction success:', res);
    await pool.end();
  } catch (err) {
    console.error('neon Pool failed:', err);
  }
}

testConnections();
