import fs from 'node:fs';
import path from 'node:path';

const root = process.argv[2];
if (!root) throw new Error('Upstream directory is required');

function patch(relative, transform) {
  const file = path.join(root, relative);
  const before = fs.readFileSync(file, 'utf8');
  const after = transform(before);
  if (before === after) {
    throw new Error(`Expected patch did not change ${relative}`);
  }
  fs.writeFileSync(file, after);
}

patch('index.html', (s) =>
  s
    .replace('<html lang="en" translate="no">', '<html lang="ru" translate="no">')
    .replace('<title>AppFlowy</title>', '<title>ЗВС-26 · РГАТУ</title>')
    .replace(
      'content="AppFlowy is an AI collaborative workspace where you achieve more without losing control of your data"',
      'content="Закрытый неофициальный портал и база знаний группы ЗВС-26 РГАТУ"',
    )
    .replace('content="AppFlowy"', 'content="ЗВС-26 · РГАТУ"')
    .replace('content="AppFlowy"', 'content="ЗВС-26 · РГАТУ"')
);

patch('src/components/login/Login.tsx', (s) =>
  s
    .replace(
      "{t('welcomeTo')} AppFlowy",
      'ЗВС-26 · РГАТУ',
    )
    .replace(
      "window.location.href = 'https://appflowy.com';",
      "window.location.href = 'https://www.rsatu.ru/';",
    ),
);

patch('src/components/app/WorkspaceLoadingAnimation.tsx', (s) =>
  s
    .replace(
      "{isLoadingUser ? 'Loading user profile...' : 'Loading workspace data...'}",
      "{isLoadingUser ? 'Загружаем профиль…' : 'Загружаем базу ЗВС-26…'}",
    ),
);
