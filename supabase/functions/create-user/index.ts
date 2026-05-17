// SIGCAL – Edge Function: create-user
//
// Invocada desde el panel de administración de usuarios (solo Lider).
// Crea un usuario en Supabase Auth y su perfil asociado en la tabla
// `profiles`. No expone el service_role_key al frontend.
//
// Entrada (JSON):
//   { email, password, fullName, role }
//
// Salida:
//   { success: true, userId: "..." } o { error: "..." }

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const { email, password, fullName, role } = body;

    if (!email || !password) {
      return new Response(
        JSON.stringify({ error: "Email y contraseña son obligatorios." }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    // Cliente admin (service_role → acceso total a Auth)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    );

    // 1. Crear usuario en Auth
    const { data: authUser, error: authError } =
      await supabaseAdmin.auth.admin.createUser({
        email,
        password,
        email_confirm: true, // evita el flujo de verificación
      });

    if (authError || !authUser?.user) {
      return new Response(
        JSON.stringify({ error: authError?.message || "Error al crear usuario Auth." }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    const userId = authUser.user.id;

    // 2. Crear perfil vinculado
    const { error: profileError } = await supabaseAdmin
      .from("profiles")
      .upsert({
        id: userId,
        email,
        full_name: fullName?.trim() || null,
        role: role || "usuario",
        active: true,
      });

    if (profileError) {
      // Limpiar el usuario Auth si falla el perfil
      await supabaseAdmin.auth.admin.deleteUser(userId);

      return new Response(
        JSON.stringify({ error: "Error al crear perfil: " + profileError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
      );
    }

    return new Response(
      JSON.stringify({ success: true, userId }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Error interno del servidor." }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } },
    );
  }
});
