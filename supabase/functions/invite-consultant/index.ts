import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return new Response(JSON.stringify({ error: "Method not allowed" }), { status: 405, headers: { ...cors, "Content-Type": "application/json" } });

  try {
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return new Response(JSON.stringify({ error: "ورود مدیر الزامی است." }), { status: 401, headers: { ...cors, "Content-Type": "application/json" } });

    const url = Deno.env.get("SUPABASE_URL")!;
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const callerClient = createClient(url, anonKey, { global: { headers: { Authorization: `Bearer ${token}` } }, auth: { persistSession: false } });
    const { data: { user }, error: userError } = await callerClient.auth.getUser(token);
    if (userError || !user) return new Response(JSON.stringify({ error: "نشست کاربری معتبر نیست." }), { status: 401, headers: { ...cors, "Content-Type": "application/json" } });

    const { data: caller, error: profileError } = await callerClient.from("profiles").select("role").eq("id", user.id).single();
    if (profileError || caller?.role !== "manager") return new Response(JSON.stringify({ error: "فقط مدیر دفتر می‌تواند مشاور اضافه کند." }), { status: 403, headers: { ...cors, "Content-Type": "application/json" } });

    const body = await req.json();
    const email = String(body.email ?? "").trim().toLowerCase();
    const fullName = String(body.full_name ?? "").trim();
    const phone = String(body.phone ?? "").trim();
    if (!email.includes("@") || !fullName) return new Response(JSON.stringify({ error: "نام و ایمیل معتبر الزامی است." }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });

    const admin = createClient(url, serviceKey, { auth: { persistSession: false } });
    const { data, error } = await admin.auth.admin.inviteUserByEmail(email, { data: { full_name: fullName } });
    if (error) return new Response(JSON.stringify({ error: error.message }), { status: 400, headers: { ...cors, "Content-Type": "application/json" } });

    if (data.user) {
      const { error: saveError } = await admin.from("profiles").upsert({
        id: data.user.id, full_name: fullName, phone, role: "consultant", is_active: true, created_by: user.id
      }, { onConflict: "id" });
      if (saveError) return new Response(JSON.stringify({ error: "دعوت ارسال شد اما تکمیل پروفایل ناموفق بود: " + saveError.message }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
    }
    return new Response(JSON.stringify({ ok: true, message: "دعوت‌نامه مشاور ارسال شد." }), { status: 200, headers: { ...cors, "Content-Type": "application/json" } });
  } catch (error) {
    return new Response(JSON.stringify({ error: error instanceof Error ? error.message : "خطای نامشخص" }), { status: 500, headers: { ...cors, "Content-Type": "application/json" } });
  }
});
