const { chromium } = require('playwright');
(async () => {
  const browser = await chromium.launch({headless:true, executablePath:'/usr/bin/chromium'});
  const page = await browser.newPage({viewport:{width:1440,height:1000}});
  const stamp = new Date().toISOString();
  await page.goto('http://127.0.0.1:8080/WebGoat/login', {waitUntil:'networkidle'});
  await page.screenshot({path:'evidence/screenshots/01-login.png', fullPage:true});
  await page.fill('input[name="username"]', 'user123');
  await page.fill('input[name="password"]', 'user123');
  await page.screenshot({path:'evidence/screenshots/02-login-filled.png', fullPage:true});
  await Promise.all([page.waitForLoadState('networkidle'), page.click('button[type="submit"]')]);
  await page.screenshot({path:'evidence/screenshots/03-dashboard.png', fullPage:true});
  require('fs').writeFileSync('evidence/screenshots/capture-metadata.txt', `Captura: ${stamp}\nURL: http://127.0.0.1:8080/WebGoat\nUsuario: user123\nContraseña: no almacenada\n`);
  await browser.close();
})().catch(e => { console.error(e); process.exit(1); });
