// NextUp — Cloudflare Worker entrypoint
// Serves the bilingual glassmorphism download landing page at /app,
// and passes everything else through to the static assets (Flutter web app).

const MYKET_URL = 'https://myket.ir/app/com.nextup.nextup';
const DIRECT_APK_URL =
  'https://drive.google.com/file/d/1pJgKpmkIxwmtCWgBiHOzSMJI2NrDG1Ns/view?usp=sharing';

const APP_VERSION = '1.0.1';

const LANDING_HTML = `<!DOCTYPE html>
<html lang="fa" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="#0A0A0F">
<title>NextUp | دانلود اپ</title>
<meta name="description" content="نکست‌آپ — فیلم و سریال‌هات رو دنبال کن. دانلود از مایکت، دانلود مستقیم APK یا وب اپ برای iOS.">
<link rel="canonical" href="https://nextup.amirs2h.workers.dev/app">
<meta property="og:title" content="NextUp | دانلود اپ">
<meta property="og:description" content="فیلم و سریال‌هات رو دنبال کن؛ هیچ قسمتی رو از دست نده.">
<meta property="og:image" content="https://nextup.amirs2h.workers.dev/icons/Icon-512.png">
<meta property="og:type" content="website">
<link rel="icon" type="image/png" href="/favicon.png">
<link rel="apple-touch-icon" href="/icons/Icon-192.png">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/rastikerdar/vazirmatn@v33.003/Vazirmatn-font-face.css">
<style>
:root{
  --bg:#0A0A0F;
  --ink:#FFFFFF;
  --muted:rgba(255,255,255,.62);
  --faint:rgba(255,255,255,.42);
  --stroke:rgba(255,255,255,.13);
  --stroke-hi:rgba(255,255,255,.30);
  --card:rgba(255,255,255,.055);
  --card-hi:rgba(255,255,255,.10);
  --red:#E50914;
  --red-2:#FF3D47;
  --purple:#6C63FF;
  --purple-2:#9D4EDD;
  --cyan:#00D4FF;
  --green:#00FF88;
  --radius:24px;
}
*{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
html{scroll-behavior:smooth}
html[lang="fa"] .en{display:none}
html[lang="en"] .fa{display:none}
body{
  min-height:100dvh;
  background:var(--bg);
  color:var(--ink);
  font-family:Vazirmatn,system-ui,-apple-system,'Segoe UI',Tahoma,sans-serif;
  display:flex;flex-direction:column;align-items:center;
  overflow-x:hidden;
  padding-top:env(safe-area-inset-top);
  padding-inline:env(safe-area-inset-right) env(safe-area-inset-left);
}
a{color:inherit;text-decoration:none}

/* ── background blobs ─────────────────────────────── */
.blobs{position:fixed;inset:0;z-index:0;pointer-events:none;overflow:hidden}
.blob{position:absolute;border-radius:50%;filter:blur(90px);opacity:.55;animation:float 14s ease-in-out infinite alternate}
.b1{width:340px;height:340px;top:-120px;inset-inline-start:-100px;background:radial-gradient(circle,var(--red) 0%,transparent 70%)}
.b2{width:300px;height:300px;top:34%;inset-inline-end:-130px;background:radial-gradient(circle,var(--purple) 0%,transparent 70%);animation-delay:-4s}
.b3{width:320px;height:320px;bottom:-140px;inset-inline-start:-60px;background:radial-gradient(circle,rgba(0,212,255,.75) 0%,transparent 70%);animation-delay:-8s}
.stars{position:fixed;inset:0;z-index:0;pointer-events:none;background-image:radial-gradient(rgba(255,255,255,.16) 1px,transparent 1px);background-size:26px 26px;mask-image:linear-gradient(180deg,rgba(0,0,0,.5),transparent 55%)}
@keyframes float{from{transform:translate(0,0) scale(1)}to{transform:translate(30px,44px) scale(1.12)}}

/* ── layout ───────────────────────────────────────── */
.wrap{position:relative;z-index:1;width:100%;max-width:480px;padding:20px 20px 44px;display:flex;flex-direction:column;gap:18px}
.topbar{display:flex;align-items:center;justify-content:space-between;padding:4px 2px}
.brand-mini{display:flex;align-items:center;gap:10px;font-weight:700;font-size:15px;letter-spacing:.4px}
.brand-mini .dot{width:26px;height:26px;border-radius:8px;background:linear-gradient(135deg,var(--red),var(--red-2));display:grid;place-items:center;box-shadow:0 4px 14px rgba(229,9,20,.45)}
.brand-mini .dot{overflow:hidden}
.brand-mini .dot img{width:100%;height:100%;object-fit:cover;border-radius:8px;display:block}
.lang-btn{
  border:1px solid var(--stroke);background:var(--card);border-radius:999px;
  padding:7px 16px;font:inherit;font-size:13px;font-weight:600;color:var(--ink);
  backdrop-filter:blur(14px);-webkit-backdrop-filter:blur(14px);cursor:pointer;
  display:flex;align-items:center;gap:7px;transition:border-color .2s,background .2s;
}
.lang-btn:active{transform:scale(.96)}
.lang-btn svg{width:15px;height:15px;fill:currentColor;opacity:.85}

/* ── hero ─────────────────────────────────────────── */
.hero{
  position:relative;overflow:hidden;
  border:1px solid var(--stroke);border-radius:28px;
  background:linear-gradient(160deg,rgba(229,9,20,.16),rgba(108,99,255,.14) 55%,rgba(0,212,255,.08));
  backdrop-filter:blur(22px) saturate(150%);-webkit-backdrop-filter:blur(22px) saturate(150%);
  padding:34px 24px 30px;text-align:center;
  box-shadow:0 24px 60px rgba(0,0,0,.45),inset 0 1px 0 rgba(255,255,255,.10);
}
.hero::before{content:'';position:absolute;inset:0;background:radial-gradient(120% 80% at 50% -20%,rgba(255,255,255,.10),transparent 55%);pointer-events:none}
.app-icon{
  width:88px;height:88px;margin:0 auto 18px;border-radius:26px;
  background:linear-gradient(135deg,var(--red) 0%,#9D4EDD 100%);
  display:grid;place-items:center;position:relative;
  box-shadow:0 18px 44px rgba(229,9,20,.42),0 8px 22px rgba(157,78,221,.32);
  animation:breathe 4.5s ease-in-out infinite;
}
.app-icon{overflow:hidden}
.app-icon img{width:100%;height:100%;object-fit:cover;border-radius:26px;display:block}
.app-icon::after{content:'';position:absolute;inset:0;border-radius:26px;box-shadow:inset 0 1px 0 rgba(255,255,255,.35),inset 0 -8px 18px rgba(0,0,0,.28)}
@keyframes breathe{0%,100%{transform:scale(1)}50%{transform:scale(1.045)}}
.version-pill{
  display:inline-flex;align-items:center;gap:6px;margin-bottom:14px;
  font-size:12px;font-weight:600;color:var(--muted);
  border:1px solid var(--stroke);border-radius:999px;padding:6px 13px;
  background:rgba(0,0,0,.22);backdrop-filter:blur(8px);
}
.version-pill .pulse{width:7px;height:7px;border-radius:50%;background:var(--green);box-shadow:0 0 0 0 rgba(0,255,136,.5);animation:ping 2.2s infinite}
@keyframes ping{0%{box-shadow:0 0 0 0 rgba(0,255,136,.45)}70%{box-shadow:0 0 0 8px rgba(0,255,136,0)}100%{box-shadow:0 0 0 0 rgba(0,255,136,0)}}
h1{font-size:31px;font-weight:800;line-height:1.25;letter-spacing:.3px}
h1 .latin{display:block;font-size:15px;font-weight:700;letter-spacing:4px;color:var(--faint);margin-top:6px;text-transform:uppercase}
.tagline{margin-top:12px;font-size:14.5px;line-height:2;color:var(--muted);max-width:34ch;margin-inline:auto}
.en .tagline{max-width:44ch;line-height:1.7}

.features{display:flex;flex-wrap:wrap;justify-content:center;gap:8px;margin-top:20px}
.chip{
  font-size:12px;font-weight:600;color:var(--muted);
  border:1px solid var(--stroke);border-radius:999px;padding:7px 13px;
  background:rgba(255,255,255,.045);backdrop-filter:blur(10px);
}
.chip b{color:var(--ink);font-weight:700}

/* ── section title ────────────────────────────────── */
.sec-title{display:flex;align-items:center;gap:12px;margin:6px 4px 0}
.sec-title::before,.sec-title::after{content:'';flex:1;height:1px;background:linear-gradient(90deg,transparent,var(--stroke),transparent)}
.sec-title span{font-size:13px;font-weight:700;color:var(--faint);white-space:nowrap}

/* ── download cards ───────────────────────────────── */
.cards{display:flex;flex-direction:column;gap:14px}
.card{
  position:relative;display:flex;align-items:center;gap:16px;
  border:1px solid var(--stroke);border-radius:var(--radius);
  background:linear-gradient(150deg,var(--card-hi),var(--card) 42%);
  backdrop-filter:blur(22px) saturate(150%);-webkit-backdrop-filter:blur(22px) saturate(150%);
  padding:18px 18px;
  box-shadow:0 14px 36px rgba(0,0,0,.38),inset 0 1px 0 rgba(255,255,255,.07);
  transition:transform .18s ease,border-color .18s ease,background .18s ease;
  animation:rise .55s cubic-bezier(.22,1,.36,1) backwards;
}
.card:nth-child(1){animation-delay:.08s}
.card:nth-child(2){animation-delay:.16s}
.card:nth-child(3){animation-delay:.24s}
@keyframes rise{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}
@media(hover:hover){
  .card:hover{transform:translateY(-3px);border-color:var(--stroke-hi);background:linear-gradient(150deg,rgba(255,255,255,.13),rgba(255,255,255,.06) 45%)}
}
.card:active{transform:scale(.985)}
.card.suggested{border-color:rgba(229,9,20,.55);background:linear-gradient(150deg,rgba(229,9,20,.16),rgba(108,99,255,.10) 55%,var(--card));box-shadow:0 16px 44px rgba(229,9,20,.22),inset 0 1px 0 rgba(255,255,255,.09)}
.card.suggested.suggest-purple{border-color:rgba(157,78,221,.55);background:linear-gradient(150deg,rgba(157,78,221,.16),rgba(108,99,255,.10) 55%,var(--card));box-shadow:0 16px 44px rgba(157,78,221,.24),inset 0 1px 0 rgba(255,255,255,.09)}
.badge{
  position:absolute;top:-10px;inset-inline-start:16px;
  font-size:10.5px;font-weight:800;color:#fff;
  background:linear-gradient(90deg,var(--red),#B20710);
  padding:4px 11px;border-radius:999px;letter-spacing:.3px;
  box-shadow:0 6px 16px rgba(229,9,20,.45);
}
.suggest-purple .badge{background:linear-gradient(90deg,var(--purple-2),var(--purple));box-shadow:0 6px 16px rgba(157,78,221,.5)}
.icon-box{
  flex:0 0 auto;width:52px;height:52px;border-radius:16px;display:grid;place-items:center;
  border:1px solid rgba(255,255,255,.10);
}
.icon-box svg{width:26px;height:26px}
.icon-box.green{background:linear-gradient(135deg,rgba(0,255,136,.20),rgba(0,255,136,.06));color:#4CFFA8}
.icon-box.red{background:linear-gradient(135deg,rgba(229,9,20,.28),rgba(229,9,20,.08));color:#FF7A80}
.icon-box.purple{background:linear-gradient(135deg,rgba(157,78,221,.30),rgba(108,99,255,.08));color:#C3A6FF}
.card-txt{flex:1;min-width:0}
.card-txt h2{font-size:15.5px;font-weight:700;line-height:1.4}
.card-txt p{font-size:12px;line-height:1.75;color:var(--muted);margin-top:3px}
.card-txt .en p{line-height:1.5}
.cta{
  flex:0 0 auto;width:38px;height:38px;border-radius:50%;display:grid;place-items:center;
  border:1px solid var(--stroke);background:rgba(255,255,255,.06);transition:background .2s;
}
.cta svg{width:17px;height:17px;fill:none;stroke:currentColor;stroke-width:2.4;stroke-linecap:round;stroke-linejoin:round}

.ios-steps{
  display:flex;gap:8px;margin-top:12px;
}
.ios-step{
  flex:1;border:1px dashed var(--stroke);border-radius:14px;background:rgba(0,0,0,.18);
  padding:9px 6px;text-align:center;font-size:10.5px;line-height:1.55;color:var(--muted);
}
.ios-step b{display:block;font-size:12px;color:var(--ink);margin-bottom:2px}

/* ── footer ───────────────────────────────────────── */
footer{margin-top:8px;text-align:center;display:flex;flex-direction:column;gap:10px}
.foot-links{display:flex;justify-content:center;gap:18px}
.foot-links a{font-size:12px;color:var(--faint);border-bottom:1px dashed transparent;padding-bottom:1px;transition:color .2s,border-color .2s}
.foot-links a:hover{color:var(--ink);border-color:var(--stroke-hi)}
.copyright{font-size:11.5px;color:rgba(255,255,255,.32)}

@media(min-width:640px){
  .wrap{padding-top:44px}
  .hero{padding:44px 32px 38px}
}
@media(prefers-reduced-motion:reduce){
  *{animation:none!important;transition:none!important}
}
</style>
</head>
<body>
<div class="stars" aria-hidden="true"></div>
<div class="blobs" aria-hidden="true">
  <div class="blob b1"></div>
  <div class="blob b2"></div>
  <div class="blob b3"></div>
</div>

<div class="wrap">
  <nav class="topbar">
    <div class="brand-mini">
      <span class="dot"><img id="dotImg" src="" alt="" decoding="async"></span>
      NextUp
    </div>
    <button id="langBtn" class="lang-btn" type="button" aria-label="Switch language">
      <svg viewBox="0 0 24 24"><path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm7.9 9h-3.4a15.7 15.7 0 0 0-1.4-5.6A8 8 0 0 1 19.9 11zM12 4c.9 1.2 1.9 3.2 2.4 7H9.6c.5-3.8 1.5-5.8 2.4-7zM4.1 13h3.4c.2 2.2.7 4.2 1.4 5.6A8 8 0 0 1 4.1 13zm3.4-2H4.1a8 8 0 0 1 4.8-5.6A15.7 15.7 0 0 0 7.5 11zM12 20c-.9-1.2-1.9-3.2-2.4-7h4.8c-.5 3.8-1.5 5.8-2.4 7zm3.1-.4c.7-1.4 1.2-3.4 1.4-5.6h3.4a8 8 0 0 1-4.8 5.6z"/></svg>
      <span class="fa">English</span><span class="en">فارسی</span>
    </button>
  </nav>

  <header class="hero rise" style="animation:rise .55s cubic-bezier(.22,1,.36,1) backwards">
    <div class="app-icon">
      <img id="logoImg" src="data:image/jpeg;base64,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AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP/9k=" alt="NextUp logo" decoding="async">
    </div>
    <div class="version-pill"><span class="pulse"></span><span class="fa">نسخه 1.0.1</span><span class="en">Version 1.0.1</span></div>
    <h1>
      <span class="fa">نکست‌آپ<span class="latin">NextUp</span></span>
      <span class="en">NextUp<span class="latin" style="letter-spacing:2px;font-weight:600;opacity:.9">Download</span></span>
    </h1>
    <p class="tagline">
      <span class="fa">فیلم و سریال‌هات رو دنبال کن؛ هیچ قسمتی رو از دست نده، با دوستات لیست مشترک بساز.</span>
      <span class="en">Track every show &amp; movie you watch. Never miss an episode, build shared watchlists with friends.</span>
    </p>
    <div class="features">
      <span class="chip"><span class="fa"><b>پیگیری</b> سریال‌ها</span><span class="en"><b>Track</b> shows</span></span>
      <span class="chip"><span class="fa"><b>یادآوری</b> قسمت جدید</span><span class="en"><b>Episode</b> reminders</span></span>
      <span class="chip"><span class="fa"><b>لیست</b> مشترک</span><span class="en"><b>Shared</b> lists</span></span>
      <span class="chip"><span class="fa"><b>تقویم</b> پخش</span><span class="en"><b>Release</b> calendar</span></span>
    </div>
  </header>

  <div class="sec-title"><span><span class="fa">نکست‌آپ رو دانلود کن</span><span class="en">Get NextUp</span></span></div>

  <div class="cards">
    <a id="cardMyket" class="card" href="https://myket.ir/app/com.nextup.nextup" target="_blank" rel="noopener">
      <span class="badge"><span class="fa">پیشنهادی</span><span class="en">Recommended</span></span>
      <span class="icon-box green">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M17.5 12.5 4 20.3c-.8.5-1.8-.1-1.8-1V4.7c0-.9 1-1.5 1.8-1L17.5 11.5c.8.4.8 1.6 0 2z"/><path d="M20.2 11.2c.9.5.9 1.8 0 2.3l-1.4.8v-3.9l1.4.8zM5.5 2.2l9.7 5.6-2.2 2.2-7.5-7.8z" opacity=".9"/><path d="M15.2 16.2 5.5 21.8l7.5-3.4z" opacity=".7"/></svg>
      </span>
      <span class="card-txt">
        <h2><span class="fa">دانلود از مایکت</span><span class="en">Get it on Myket</span></h2>
        <p><span class="fa">اندروید • نصب و بروزرسانی خودکار از فروشگاه مایکت</span><span class="en">Android - install &amp; auto-update from the Myket store</span></p>
      </span>
      <span class="cta" aria-hidden="true"><svg viewBox="0 0 24 24"><path class="fa" d="m9 18 6-6-6-6" transform="scale(-1,1) translate(-24,0)"/><path class="en" d="m9 18 6-6-6-6"/></svg></span>
    </a>

    <a id="cardDirect" class="card" href="https://drive.google.com/file/d/1pJgKpmkIxwmtCWgBiHOzSMJI2NrDG1Ns/view?usp=sharing" target="_blank" rel="noopener">
      <span class="icon-box red">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3v11"/><path d="m7 10 5 5 5-5"/><path d="M4 17v2a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2"/></svg>
      </span>
      <span class="card-txt">
        <h2><span class="fa">دانلود مستقیم APK</span><span class="en">Direct APK download</span></h2>
        <p><span class="fa">اندروید • فایل نصب نسخه 1.0.1 (نصب دستی)</span><span class="en">Android - v1.0.1 installer file (manual install)</span></p>
      </span>
      <span class="cta" aria-hidden="true"><svg viewBox="0 0 24 24"><path class="fa" d="m9 18 6-6-6-6" transform="scale(-1,1) translate(-24,0)"/><path class="en" d="m9 18 6-6-6-6"/></svg></span>
    </a>

    <a id="cardWeb" class="card" href="/" target="_blank" rel="noopener">
      <span class="icon-box purple">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M16.4 12.9c0-2.1 1.7-3.1 1.8-3.2-1-1.4-2.5-1.6-3-1.6-1.3-.1-2.5.8-3.2.8-.7 0-1.7-.8-2.8-.8-1.4 0-2.8.8-3.5 2.1-1.5 2.6-.4 6.5 1.1 8.6.7 1 1.5 2.2 2.6 2.1 1.1 0 1.5-.7 2.8-.7s1.6.7 2.8.7c1.2 0 1.9-1 2.6-2.1.8-1.2 1.2-2.4 1.2-2.5 0 0-2.3-.9-2.4-3.4zM14.3 6.6c.6-.7 1-1.7.9-2.7-.9 0-1.9.6-2.5 1.3-.5.6-1 1.6-.9 2.6 1 .1 2-.5 2.5-1.2z"/></svg>
      </span>
      <span class="card-txt">
        <h2><span class="fa">وب اپ برای آیفون و آیپد</span><span class="en">Web app for iPhone &amp; iPad</span></h2>
        <p><span class="fa">بدون نیاز به App Store • اضافه کردن به صفحه اصلی با Safari</span><span class="en">No App Store needed - add to Home Screen from Safari</span></p>
      </span>
      <span class="cta" aria-hidden="true"><svg viewBox="0 0 24 24"><path class="fa" d="m9 18 6-6-6-6" transform="scale(-1,1) translate(-24,0)"/><path class="en" d="m9 18 6-6-6-6"/></svg></span>
    </a>

    <div class="ios-steps" id="iosSteps">
      <div class="ios-step"><b><span class="fa">۱. Safari</span><span class="en">1. Safari</span></b><span class="fa">لینک رو با سافاری باز کن</span><span class="en">Open the link in Safari</span></div>
      <div class="ios-step"><b><span class="fa">۲. Share ⇪</span><span class="en">2. Share ⇪</span></b><span class="fa">دکمه اشتراک‌گذاری</span><span class="en">Tap the Share button</span></div>
      <div class="ios-step"><b><span class="fa">۳. Home Screen</span><span class="en">3. Home Screen</span></b><span class="fa">Add to Home Screen رو بزن</span><span class="en">Tap Add to Home Screen</span></div>
    </div>
  </div>

  <footer>
    <div class="foot-links">
      <a href="/"><span class="fa">باز کردن وب اپ</span><span class="en">Open web app</span></a>
      <a href="https://myket.ir/app/com.nextup.nextup" target="_blank" rel="noopener">Myket</a>
    </div>
    <div class="copyright">NextUp v1.0.1 <span class="fa">• ساخته‌شده برای فیلم‌بازها</span><span class="en">• Made for binge-watchers</span></div>
  </footer>
</div>

<script>
(function(){
  document.getElementById('dotImg').src = document.getElementById('logoImg').src;
  var html = document.documentElement;
  function setLang(l){
    html.setAttribute('lang', l);
    html.setAttribute('dir', l === 'fa' ? 'rtl' : 'ltr');
    try{ localStorage.setItem('nextup_lang', l); }catch(e){}
  }
  var saved = null;
  try{ saved = localStorage.getItem('nextup_lang'); }catch(e){}
  if (saved === 'fa' || saved === 'en') { setLang(saved); }
  else { setLang((navigator.language || '').toLowerCase().indexOf('fa') === 0 ? 'fa' : 'en'); }
  document.getElementById('langBtn').addEventListener('click', function(){
    setLang(html.getAttribute('lang') === 'fa' ? 'en' : 'fa');
  });

  var ua = navigator.userAgent || '';
  var isIOS = /iPhone|iPad|iPod/i.test(ua);
  var isAndroid = /Android/i.test(ua);
  var myket = document.getElementById('cardMyket');
  var web = document.getElementById('cardWeb');
  var steps = document.getElementById('iosSteps');
  if (isIOS) {
    web.classList.add('suggested','suggest-purple');
  } else {
    myket.classList.add('suggested');
    if (isAndroid) steps.style.display = 'none';
    else steps.style.opacity = '.75';
  }
})();
</script>
</body>
</html>`;

const LANDING_HEADERS = {
  'content-type': 'text/html; charset=utf-8',
  'cache-control': 'no-cache, no-store, must-revalidate',
};

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.pathname === '/app' || url.pathname === '/app/') {
      return new Response(LANDING_HTML, { headers: LANDING_HEADERS });
    }

    return env.ASSETS.fetch(request);
  },
};
