// Página de testes do LINHA 11.
// Lê dev/version.json e stable/version.json e preenche os cartões dos canais.

const UNPUBLISHED = {
  playable: false,
  status: 'ainda não publicado',
  version: '—',
  commit: '—',
  date: '—',
};

function formatDate(iso) {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return 'data desconhecida';
  return d.toLocaleString('pt-BR', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

/** Converte o conteúdo de um version.json (ou null) no que o cartão mostra. */
export function channelView(data) {
  if (!data || typeof data !== 'object' || Array.isArray(data) || typeof data.version !== 'string') {
    return { ...UNPUBLISHED };
  }
  return {
    playable: true,
    status: 'compilação publicada com sucesso',
    version: data.version,
    commit: typeof data.commit === 'string' ? data.commit : '—',
    date: formatDate(data.date),
  };
}

async function fetchChannel(dir) {
  try {
    const res = await fetch(`${dir}/version.json?t=${Date.now()}`, { cache: 'no-store' });
    if (!res.ok) return null;
    return await res.json();
  } catch {
    return null;
  }
}

function render(card, view) {
  card.dataset.state = view.playable ? 'ok' : 'empty';
  card.querySelector('[data-field="status"]').textContent = view.status;
  card.querySelector('[data-field="version"]').textContent = view.version;
  card.querySelector('[data-field="commit"]').textContent = view.commit;
  card.querySelector('[data-field="date"]').textContent = view.date;
  const button = card.querySelector('[data-field="play"]');
  if (view.playable) {
    button.removeAttribute('aria-disabled');
    button.href = `${card.dataset.channel}/`;
  } else {
    button.setAttribute('aria-disabled', 'true');
    button.removeAttribute('href');
  }
}

if (typeof document !== 'undefined') {
  for (const card of document.querySelectorAll('[data-channel]')) {
    fetchChannel(card.dataset.channel).then((data) => render(card, channelView(data)));
  }
  const canvas = document.createElement('canvas');
  if (!canvas.getContext('webgl2')) {
    document.getElementById('webgl-warning').hidden = false;
  }
}
