#!/usr/bin/env bash

# Строгий режим. Если что упало, завершаем скрипт
set -euo pipefail

# Берем первый аргумент командной строки. Если его нет, используется Perm
# 1 — это первый аргумент скрипта
# ${...} — форма подстановки параметра
# :-Perm — "если значение пустое или не задано, возьми Perm"
CITY="${1:-Perm}" # Берем первый аргумент 
OUTPUT_FILE="${2:-/home/viktor/weather.html}"

# $(...) Выполни команду внутри и подставь её вывод сюда
# $ нужно что-то подставить
# (...) после $ означает: подставь результат выполнения команды
# $UPDATED_AT — подставить значение переменной
# $(date ...) — подставить результат команды
# (date ...) без $ — просто запустить команду в подshell, без подстановки в строку
# mktemp — команда, которая создаёт уникальный временный файл
TMP_JSON="$(mktemp)"
TMP_HTML="$(mktemp)"

# Удаляет оба временных файла
cleanup() {
  rm -f "$TMP_JSON" "$TMP_HTML"
}

# При завершении скрипта, даже если она упал, вызвать cleanup
trap cleanup EXIT

# Считываем погоду и записываем во временный файл
curl -fsS "wttr.in/${CITY}?format=j1" > "$TMP_JSON"

# <<< Читать из готовой строки. Мы получаем строку и передаем команде read.
# Она разбивает строку на 3 переменные
# | передать результат дальше
# jq - программа
# -r - опция
# '...' фильтр jq
# "$TMP_JSON" — файл с JSON
read -r TEMP HUMIDITY DESCRIPTION <<<"$(jq -r '
  .["current_condition"][0]
  | [.temp_C, .humidity, (.weatherDesc[0].value // "n/a")]
  | @tsv
' "$TMP_JSON")"

# Записывает текущее время в переменную
UPDATED_AT="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"

# ${CITY} — подстановка переменной
# $(...) — подстановка результата команды

# Запись многострочного текста в файл TMP_HTML
# Все что ниже до EOF попадет в HTML-файл
# cat ждёт входные данные
# <<EOF передаёт ему многострочный текст
# > записывает этот текст в файл "$TMP_HTML"
# команда: cat
# stdin: взять из heredoc до EOF
# stdout: направить в файл "$TMP_HTML"
cat > "$TMP_HTML" <<EOF
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta http-equiv="refresh" content="300">
  <title>Погода в ${CITY}</title>
  <style>
    :root {
      color-scheme: light;
      --bg: #eef6ff;
      --card: #ffffff;
      --text: #10233a;
      --muted: #5e738c;
      --accent: #2b7fff;
      --border: #cfe0f5;
    }

    body {
      margin: 0;
      min-height: 100vh;
      display: grid;
      place-items: center;
      font-family: "Segoe UI", sans-serif;
      background:
        radial-gradient(circle at top, #f7fbff 0%, #eef6ff 45%, #ddeafb 100%);
      color: var(--text);
    }

    main {
      width: min(92vw, 560px);
      padding: 32px;
      border: 1px solid var(--border);
      border-radius: 24px;
      background: rgba(255, 255, 255, 0.92);
      box-shadow: 0 18px 60px rgba(16, 35, 58, 0.12);
      backdrop-filter: blur(8px);
    }

    h1 {
      margin: 0 0 12px;
      font-size: clamp(28px, 5vw, 42px);
    }

    .desc {
      margin: 0 0 28px;
      color: var(--muted);
      font-size: 18px;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 16px;
    }

    .metric {
      padding: 20px;
      border-radius: 18px;
      background: var(--card);
      border: 1px solid var(--border);
    }

    .label {
      margin: 0 0 8px;
      color: var(--muted);
      font-size: 14px;
      text-transform: uppercase;
      letter-spacing: 0.08em;
    }

    .value {
      margin: 0;
      font-size: clamp(32px, 6vw, 48px);
      font-weight: 700;
      color: var(--accent);
    }

    .updated {
      margin: 24px 0 0;
      color: var(--muted);
      font-size: 14px;
    }
  </style>
</head>
<body>
  <main>
    <h1>Погода в ${CITY}</h1>
    <p class="desc">${DESCRIPTION}</p>
    <section class="grid">
      <article class="metric">
        <p class="label">Температура</p>
        <p class="value">${TEMP}&deg;C</p>
      </article>
      <article class="metric">
        <p class="label">Влажность</p>
        <p class="value">${HUMIDITY}%</p>
      </article>
    </section>
    <p class="updated">Обновлено: ${UPDATED_AT}</p>
  </main>
</body>
</html>
EOF

mv "$TMP_HTML" "$OUTPUT_FILE"
# 6 владелец чтение + запись
# 4 группа только чтение
# 4 остальные только чтение
chmod 644 "$OUTPUT_FILE"

echo "HTML updated: $OUTPUT_FILE"
