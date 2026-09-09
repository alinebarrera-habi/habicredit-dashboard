# HabiCredit · Dashboard P&L (Habi)

Página publicada: **https://alinebarrera-habi.github.io/habicredit-dashboard/**

Este repo contiene **solo la versión cifrada** (`index.html`) del *Dashboard P&L de HabiCredit*
(Finanzas Corporativas): P&L, funnel de créditos, OpEx, payroll y productividad de la infra.

- El repo es público porque GitHub Pages lo exige; el contenido está cifrado con **AES-256-GCM
  (PBKDF2, 200k iteraciones)** y solo se abre con la contraseña. Sin ella la página es ilegible.
- La contraseña se comparte por fuera de este repo. **No la pegues en issues ni commits.**
- El código fuente del dashboard y los datos viven en el repo privado `P-L-Habicredit`; aquí no
  hay ni `dashboard.html` ni `datos.json` en claro.

## Cómo se actualiza

1. En `P-L-Habicredit`: `py actualizar_datos.py` (regenera `datos.json` desde BigQuery).
2. En esta carpeta:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File publish.ps1
   ```

   `build_page.ps1` embebe `datos.json` dentro de `dashboard.html` (vía `window.__DATOS__`, la misma
   ruta que usa la versión de Apps Script), `publish.ps1` lo cifra con la contraseña de
   `config.local.ps1`, comprueba que la contraseña lo abre, commitea `index.html` y hace push.

`config.local.ps1` (gitignored) tiene una sola línea: `$HABICREDIT_PASSWORD = '...'`.
