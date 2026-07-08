import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const TMDB_API_KEY = Deno.env.get('TMDB_API_KEY') || '17dc9b5c7bedf50c8146220be73d8a50';
const TMDB_BASE_URL = 'https://api.themoviedb.org/3';

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  try {
    const url = new URL(req.url);
    const path = url.searchParams.get('path') || '';
    
    console.log(`[TMDB Proxy] Request: ${path}`);
    
    if (!path) {
      console.error('[TMDB Proxy] Missing path parameter');
      return new Response(JSON.stringify({ error: 'Missing path parameter' }), {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }
    
    const params = new URLSearchParams(url.searchParams);
    params.delete('path');
    params.set('api_key', TMDB_API_KEY);
    
    const tmdbUrl = `${TMDB_BASE_URL}${path}?${params.toString()}`;
    console.log(`[TMDB Proxy] Fetching: ${tmdbUrl}`);
    
    const response = await fetch(tmdbUrl, {
      headers: { 
        'Accept': 'application/json',
        'User-Agent': 'NextUp/1.0',
      },
    });
    
    console.log(`[TMDB Proxy] Response status: ${response.status}`);
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error(`[TMDB Proxy] TMDB error: ${errorText}`);
      return new Response(JSON.stringify({ error: `TMDB error: ${response.status}`, details: errorText }), {
        status: response.status,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      });
    }
    
    const data = await response.json();
    console.log(`[TMDB Proxy] Success: ${JSON.stringify(data).substring(0, 100)}...`);
    
    return new Response(JSON.stringify(data), {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Cache-Control': 'public, max-age=300',
      },
    });
  } catch (error) {
    console.error(`[TMDB Proxy] Error: ${error.message}`);
    return new Response(JSON.stringify({ error: error.message, stack: error.stack }), {
      status: 500,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
    });
  }
});
