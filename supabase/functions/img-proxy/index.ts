import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p';

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, OPTIONS',
        'Access-Control-Max-Age': '86400',
      },
    });
  }

  try {
    const url = new URL(req.url);
    const size = url.searchParams.get('size') || 'w500';
    const path = url.searchParams.get('path') || '';

    if (!path) {
      return new Response('Missing path parameter', { status: 400 });
    }

    const imageUrl = `${TMDB_IMAGE_BASE}/${size}${path}`;
    console.log(`[Image Proxy] Redirecting to: ${imageUrl}`);

    // Simply redirect to the TMDB image URL
    return Response.redirect(imageUrl, 302);
  } catch (error) {
    console.error(`[Image Proxy] Error: ${error.message}`);
    return new Response(error.message, { status: 500 });
  }
});
