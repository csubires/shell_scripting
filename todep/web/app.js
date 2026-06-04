// ============================================================
// BASH COMMANDS — añade/modifica los comandos aquí
// ============================================================
const BASH_COMMANDS = [
  { desc: "Listar archivos con detalles",      cmd: "ls -lah" },
  { desc: "Buscar texto en archivos",           cmd: 'grep -rin "texto" ./directorio' },
  { desc: "Ver procesos en tiempo real",        cmd: "htop" },
  { desc: "Uso de disco por carpeta",           cmd: "du -sh * | sort -rh | head -20" },
  { desc: "Espacio libre en discos",            cmd: "df -h" },
  { desc: "Ver puertos en escucha",             cmd: "ss -tulnp" },
  { desc: "Matar proceso por nombre",           cmd: "pkill -f nombre_proceso" },
  { desc: "Comprimir carpeta en tar.gz",        cmd: "tar -czvf archivo.tar.gz ./carpeta/" },
  { desc: "Extraer tar.gz",                     cmd: "tar -xzvf archivo.tar.gz" },
  { desc: "Ver logs en tiempo real",            cmd: "tail -f /var/log/syslog" },
  { desc: "SSH con reenvío de puertos",         cmd: "ssh -L 8080:localhost:80 user@host" },
  { desc: "Sync carpeta a remoto (rsync)",      cmd: "rsync -avz --progress ./local/ user@host:/remoto/" },
  { desc: "Ver historial de comandos",          cmd: "history | grep 'término'" },
  { desc: "Permisos recursivos",                cmd: "chmod -R 755 ./carpeta" },
  { desc: "Encontrar archivos grandes",         cmd: "find / -type f -size +100M 2>/dev/null" },
  { desc: "Alias temporal en sesión",           cmd: "alias ll='ls -lah --color=auto'" },
  { desc: "Contar líneas de un archivo",        cmd: "wc -l archivo.txt" },
  { desc: "Reemplazar texto en archivo",        cmd: "sed -i 's/viejo/nuevo/g' archivo.txt" },
  { desc: "Variables de entorno activas",       cmd: "env | sort | grep -i 'nombre'" },
  { desc: "Descargar archivo con curl",         cmd: "curl -L -o destino.zip https://url/archivo.zip" },
];

// PRESETS viene de presets.js, cargado antes en el HTML

function init() {
  populateSelect();
  renderBashTable();
  updateOutput();
}

function populateSelect() {
  const sel = document.getElementById('preset-select');
  PRESETS.forEach(p => {
    const opt = document.createElement('option');
    opt.value = p.id;
    opt.textContent = p.label;
    sel.appendChild(opt);
  });
}

function renderBashTable() {
  const table = document.getElementById('bash-table');
  BASH_COMMANDS.forEach((item, i) => {
    const row = document.createElement('div');
    row.className = 'bash-row';
    row.innerHTML = `
      <span class="bash-desc">${escHtml(item.desc)}</span>
      <span class="bash-cmd">${escHtml(item.cmd)}</span>
      <button class="btn-copy-cmd" onclick="copyCmd(this, ${i})" title="Copiar comando">⎘ COPY</button>
    `;
    table.appendChild(row);
  });
}

function onPresetChange() {
  const val     = document.getElementById('preset-select').value;
  const preview = document.getElementById('preset-preview');
  if (!val) {
    preview.textContent = 'Selecciona un preset para ver su contenido…';
  } else {
    const p = PRESETS.find(x => x.id === val);
    preview.textContent = p ? p.text : '';
  }
  updateOutput();
}

function buildPrompt() {
  const includeCtx = document.getElementById('include-context').checked;
  const fixedText  = document.getElementById('fixed-text').value.trim();
  const queryText  = document.getElementById('query-text').value.trim();
  const presetId   = document.getElementById('preset-select').value;
  const preset     = presetId ? PRESETS.find(x => x.id === presetId) : null;

  const parts = [];
  if (includeCtx && preset)    parts.push(preset.text);
  if (includeCtx && fixedText) parts.push(fixedText);
  if (queryText)               parts.push(queryText);
  return parts.join('\n\n');
}

function updateOutput() {
  const prompt    = buildPrompt();
  const previewEl = document.getElementById('output-preview');
  const countEl   = document.getElementById('char-count');

  previewEl.textContent = prompt || 'El prompt generado aparecerá aquí…';
  countEl.textContent   = prompt.length.toLocaleString('es') + ' chars';

  const inc = document.getElementById('include-context').checked;
  document.getElementById('preset-preview').classList.toggle('hidden', !inc);
}

function copyMain() {
  const prompt = buildPrompt();
  if (!prompt) return;
  navigator.clipboard.writeText(prompt).then(() => {
    const btn  = document.getElementById('btn-main-copy');
    const text = document.getElementById('btn-main-text');
    btn.classList.add('copied');
    text.textContent = '✓ Copiado al portapapeles';
    setTimeout(() => {
      btn.classList.remove('copied');
      text.textContent = 'Copiar Prompt al Portapapeles';
    }, 2000);
  });
}

function copyCmd(btn, idx) {
  navigator.clipboard.writeText(BASH_COMMANDS[idx].cmd).then(() => {
    btn.textContent = '✓ OK';
    btn.classList.add('copied');
    setTimeout(() => {
      btn.textContent = '⎘ COPY';
      btn.classList.remove('copied');
    }, 1800);
  });
}

function escHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

init();
