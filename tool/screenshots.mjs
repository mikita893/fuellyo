// Robi zrzuty ekranu z webowej wersji aplikacji (podgląd UI w PR).
// Użycie: node tool/screenshots.mjs http://localhost:8080 out/
import { chromium } from 'playwright';
import { mkdirSync } from 'node:fs';

const [url = 'http://localhost:8080', outDir = 'screenshots'] = process.argv.slice(2);
mkdirSync(outDir, { recursive: true });

const browser = await chromium.launch();

async function session(colorScheme) {
  const page = await browser.newPage({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    colorScheme,
  });
  page.on('console', (m) => m.type() === 'error' && console.log('[console]', m.text()));
  await page.goto(url, { waitUntil: 'networkidle' });
  await page.waitForTimeout(4000);
  // Włącz drzewo semantyki Fluttera, żeby klikać po etykietach.
  await page.locator('flt-semantics-placeholder').click({ force: true }).catch(() => {});
  await page.waitForTimeout(800);
  return page;
}

async function click(page, name) {
  const candidates = [
    page.getByRole('tab', { name }),
    page.getByRole('button', { name }),
    page.getByText(name, { exact: false }),
  ];
  for (const c of candidates) {
    try {
      if ((await c.count()) > 0) {
        await c.first().click({ timeout: 3000 });
        await page.waitForTimeout(1200);
        return true;
      }
    } catch (_) {}
  }
  console.log(`!! nie znaleziono: ${name}`);
  return false;
}

async function shot(page, name) {
  await page.screenshot({ path: `${outDir}/${name}.png` });
  console.log(`zapisano ${name}.png`);
}

const page = await session('light');
await shot(page, '01-powitanie');
await click(page, 'Zobacz na przykładowych danych');
await shot(page, '02-pulpit');
await page.mouse.wheel(0, 700);
await page.waitForTimeout(800);
await shot(page, '03-pulpit-dol');
await click(page, 'Tankowania');
await shot(page, '04-tankowania');
await click(page, 'Serwis');
await shot(page, '05-serwis');
await click(page, 'Garaż');
await shot(page, '06-garaz');
await click(page, 'Tankowania');
await click(page, 'Tankowanie');
await shot(page, '07-nowe-tankowanie');
await page.keyboard.press('Escape');
await page.waitForTimeout(800);
await click(page, 'Serwis');
await click(page, 'Wymiana oleju');
await shot(page, '08-szczegoly-zadania');
await page.close();

const dark = await session('dark');
await click(dark, 'Zobacz na przykładowych danych');
await shot(dark, '09-pulpit-ciemny');

await browser.close();
