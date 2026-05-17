// SIGCAL – Edge Function: create-user (v2)
//
// Invocada desde el panel de administración de usuarios.
// Verifica que quien llama tenga rol LIDER antes de ejecutar.
// Crea usuario en Auth + perfil en profiles.
//
// Entrada (JSON):  { email, password, fullName, role }
// Salida:           { success: true, userId } | { error: "..." }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const _corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: _corsHeaders });
  }

  try {
    // ── 1. Verificar autenticación del caller ────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "No autorizado." }),
        { status: 401, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Cliente normal para verificar el JWT del caller
    const supabaseClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );

    const { data: { user: caller }, error: authErr } =
      await supabaseClient.auth.getUser(authHeader.replace("Bearer ", ""));

    if (authErr || !caller) {
      return new Response(
        JSON.stringify({ error: "Token inválido o expirado." }),
        { status: 401, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Verificar que el caller tenga perfil con rol LIDER
    const { data: profile, error: profileErr } = await supabaseClient
      .from("profiles")
      .select("role")
      .eq("auth_user_id", caller.id)
      .single();

    if (profileErr || profile?.role !== "lider") {
      return new Response(
        JSON.stringify({ error: "Solo un lider puede crear usuarios." }),
        { status: 403, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 2. Leer body ──────────────────────────────────────────────────
    const body = await req.json();
    const { email, password, fullName, role } = body;

    if (!email || !password || password.length < 6) {
      return new Response(
        JSON.stringify({ error: "Email y contraseña (min 6) son obligatorios." }),
        { status: 400, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 3. Cliente admin (service_role) ──────────────────────────────
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // Verificar si el email ya existe
    const { data: existing } = await supabaseAdmin
      .from("profiles")
      .select("id")
      .eq("email", email)
      .maybeSingle();

    if (existing) {
      return new Response(
        JSON.stringify({ error: "Ya existe un usuario con ese correo." }),
        { status: 409, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // ── 4. Crear usuario en Auth ──────────────────────────────────────
    const { data: authUser, error: createError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
      });

    if (createError || !authUser?.user) {
      console.error("createUser error:", createError);
      return new Response(
        JSON.stringify({ error: createError?.message || "Error al crear usuario." }),
        { status: 500, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const userId = authUser.user.id;

    // ── 5. Actualizar perfil creado por el trigger ────────────────────
    // El trigger de la BD ya creó el perfil con valores por defecto.
    // Solo actualizamos los campos que nos interesan.
    const { error: updateError } = await supabaseAdmin
      .from("profiles")
      .update({
        email,
        full_name: fullName?.trim() || null,
        role: role || "usuario",
        active: true,
      })
      .eq("id", userId);

    if (updateError) {
      console.error("profile update error:", updateError);
      // Limpiar el usuario Auth si falla
      await supabaseAdmin.auth.admin.deleteUser(userId);
      return new Response(
        JSON.stringify({ error: "Error al actualizar perfil: " + updateError.message }),
        { status: 500, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true, userId }),
      { headers: { ..._corsHeaders, "Content-Type": "application/json" } },
    );

  } catch (err) {
    console.error("create-user unexpected error:", err);
    return new Response(
      JSON.stringify({ error: "Error interno del servidor." }),
      { status: 500, headers: { ..._corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
