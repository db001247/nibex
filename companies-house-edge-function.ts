// Supabase Edge Function: companies-house
// Deploy to: supabase/functions/companies-house/index.ts
//
// Setup:
//   supabase secrets set CH_API_KEY=your_key_here
//   supabase functions deploy companies-house
//
// Endpoints proxied:
//   GET /search?q=<query>            → CH search
//   GET /company/<number>            → CH company profile + filing history + charges + PSCs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";

const CH_BASE = "https://api.company-information.service.gov.uk";
const CH_KEY  = Deno.env.get("CH_API_KEY") || "";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

async function chFetch(path: string) {
  const resp = await fetch(`${CH_BASE}${path}`, {
    headers: {
      Authorization: "Basic " + btoa(CH_KEY + ":"),
    },
  });
  if (!resp.ok) return null;
  return await resp.json();
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  const url = new URL(req.url);
  const segments = url.pathname.replace(/^\/companies-house\/?/, "").split("/");

  try {
    if (segments[0] === "search") {
      const q = url.searchParams.get("q") || "";
      const data = await chFetch(`/search/companies?q=${encodeURIComponent(q)}&items_per_page=5`);
      return new Response(JSON.stringify(data), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (segments[0] === "company" && segments[1]) {
      const num = segments[1].toUpperCase();
      const [profile, filings, charges, pscs] = await Promise.all([
        chFetch(`/company/${num}`),
        chFetch(`/company/${num}/filing-history?items_per_page=10`),
        chFetch(`/company/${num}/charges`),
        chFetch(`/company/${num}/persons-with-significant-control`),
      ]);
      return new Response(JSON.stringify({ profile, filings, charges, pscs }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    return new Response("Not found", { status: 404, headers: corsHeaders });
  } catch (e) {
    console.error("CH edge function error:", e);
    return new Response("Error", { status: 500, headers: corsHeaders });
  }
});
