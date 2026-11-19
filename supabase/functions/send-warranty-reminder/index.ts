// Supabase Edge Function: send-warranty-reminder
// Otomatisasi pengiriman notifikasi pengingat garansi (H-30 dan H-7) via Telegram Bot API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const TELEGRAM_BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

interface Profile {
  telegram_chat_id?: string | null;
  name?: string | null;
}

interface ReceiptItem {
  id: number;
  product_name: string;
  category: string;
  store_name: string;
  purchase_date: string;
  warranty_months: number;
  user_id: string;
  profiles?: Profile | null;
}

serve(async (req) => {
  try {
    if (!TELEGRAM_BOT_TOKEN) {
      return new Response(
        JSON.stringify({ error: "TELEGRAM_BOT_TOKEN environment variable is not configured." }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Ambil semua nota aktif beserta relasi data profil pemiliknya
    const { data: receipts, error } = await supabase
      .from("receipts")
      .select("id, product_name, category, store_name, purchase_date, warranty_months, user_id, profiles(telegram_chat_id, name)")
      .returns<ReceiptItem[]>();

    if (error) {
      throw error;
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    let sentCount = 0;
    let skippedCount = 0;
    const results = [];

    for (const item of (receipts || [])) {
      const chatId = item.profiles?.telegram_chat_id?.trim();

      // Lewati pengiriman jika telegram_chat_id kosong / null
      if (!chatId) {
        skippedCount++;
        continue;
      }

      const purchaseDate = new Date(item.purchase_date);
      const expirationDate = new Date(purchaseDate);
      expirationDate.setMonth(expirationDate.getMonth() + item.warranty_months);
      expirationDate.setHours(0, 0, 0, 0);

      const diffTime = expirationDate.getTime() - today.getTime();
      const daysLeft = Math.round(diffTime / (1000 * 60 * 60 * 24));

      // Kirim hanya pada H-30 dan H-7
      if (daysLeft === 30 || daysLeft === 7) {
        const userName = item.profiles?.name || "Pengguna SimpanNota";
        const reminderTag = daysLeft === 30 ? "H-30" : "H-7";

        const message = `🔔 *PENGINGAT MASA GARANSI SIMPANNOTA (${reminderTag})*

Halo *${userName}*,
Masa garansi barang Anda akan segera berakhir dalam *${daysLeft} hari* lagi:

📦 *Barang:* ${item.product_name}
🏪 *Toko:* ${item.store_name}
🏷️ *Kategori:* ${item.category}
📅 *Tanggal Beli:* ${item.purchase_date}
⏳ *Durasi Garansi:* ${item.warranty_months} Bulan
🛑 *Jatuh Tempo:* ${expirationDate.toISOString().split("T")[0]}

_Silakan cek kondisi barang Anda. Segera lakukan klaim garansi sebelum tanggal jatuh tempo jika terdapat kendala atau kerusakan._`;

        // Kirim notifikasi menggunakan Telegram Bot API
        const telegramUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
        const res = await fetch(telegramUrl, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            chat_id: chatId,
            text: message,
            parse_mode: "Markdown",
          }),
        });

        const resJson = await res.json();
        if (resJson.ok) {
          sentCount++;
          results.push({ receiptId: item.id, chatId, status: "sent", daysLeft });
        } else {
          results.push({ receiptId: item.id, chatId, status: "failed", error: resJson.description });
        }
      } else {
        skippedCount++;
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        sent_count: sentCount,
        skipped_count: skippedCount,
        results,
      }),
      { headers: { "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: err.message || "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
