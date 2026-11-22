/* ===== TiradA anon — Supabase client (cloud accounts, profiles, presence) =====
   Public anon key: safe to ship in the client — all data is guarded by
   Row Level Security policies in the database. */
window.TiradaSupaCfg = {
  url: "https://qrlyuvnfkrufnnladclf.supabase.co",
  key: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFybHl1dm5ma3J1Zm5ubGFkY2xmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTUzNDA5OTQsImV4cCI6MjExMDkxNjk5NH0.JyIVlJjLG7co0kv215Jesykwy9XCMqpRlqY3Nh-lKrw"
};
window.TiradaDB = window.supabase.createClient(
  window.TiradaSupaCfg.url,
  window.TiradaSupaCfg.key,
  { auth: { persistSession: true, autoRefreshToken: true } }
);
