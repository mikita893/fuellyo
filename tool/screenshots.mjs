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
  // Build ma włączoną semantykę (FUELLYO_SEMANTICS), więc elementy mają role i etykiety.
  return page;
}

async function click(page, name, fallback) {
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
  if (fallback) {
    console.log(`.. ${name}: klikam w punkt ${fallback}`);
    await page.mouse.click(fallback[0], fallback[1]);
    await page.waitForTimeout(1200);
    return true;
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
await click(page, 'Zobacz na przykładowych danych', [195, 607]);
await shot(page, '02-pulpit');
await page.mouse.move(195, 400);
await page.mouse.wheel(0, 700);
await page.waitForTimeout(800);
await shot(page, '03-pulpit-dol');
await page.mouse.wheel(0, -2000);
await page.waitForTimeout(500);
await click(page, 'Tankowania', [146, 805]);
await shot(page, '04-tankowania');
await click(page, 'Serwis', [244, 805]);
await shot(page, '05-serwis');
await click(page, 'Garaż', [341, 805]);
await shot(page, '06-garaz');
await click(page, 'Tankowania', [146, 805]);
await click(page, 'Tankowanie', [310, 725]);
await shot(page, '07-nowe-tankowanie');
await page.keyboard.press('Escape');
await page.waitForTimeout(800);
await click(page, 'Serwis', [244, 805]);
await click(page, 'Wymiana oleju', [195, 400]);
await shot(page, '08-szczegoly-zadania');
await page.close();

const dark = await session('dark');
await click(dark, 'Zobacz na przykładowych danych', [195, 607]);
await shot(dark, '09-pulpit-ciemny');

await browser.close();
