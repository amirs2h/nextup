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
.brand-mini .dot svg{width:14px;height:14px;fill:#fff}
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
.app-icon svg{width:42px;height:42px;fill:#fff}
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
      <span class="dot"><svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg></span>
      NextUp
    </div>
    <button id="langBtn" class="lang-btn" type="button" aria-label="Switch language">
      <svg viewBox="0 0 24 24"><path d="M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20zm7.9 9h-3.4a15.7 15.7 0 0 0-1.4-5.6A8 8 0 0 1 19.9 11zM12 4c.9 1.2 1.9 3.2 2.4 7H9.6c.5-3.8 1.5-5.8 2.4-7zM4.1 13h3.4c.2 2.2.7 4.2 1.4 5.6A8 8 0 0 1 4.1 13zm3.4-2H4.1a8 8 0 0 1 4.8-5.6A15.7 15.7 0 0 0 7.5 11zM12 20c-.9-1.2-1.9-3.2-2.4-7h4.8c-.5 3.8-1.5 5.8-2.4 7zm3.1-.4c.7-1.4 1.2-3.4 1.4-5.6h3.4a8 8 0 0 1-4.8 5.6z"/></svg>
      <span class="fa">English</span><span class="en">فارسی</span>
    </button>
  </nav>

  <header class="hero rise" style="animation:rise .55s cubic-bezier(.22,1,.36,1) backwards">
    <div class="app-icon">
      <svg viewBox="0 0 24 24"><path d="M8 5v14l11-7z"/></svg>
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
