// Holt öffentliche Decks von Archidekt, weil Archidekt Abrufe direkt aus dem Browser sperrt.
// Aufrufe:  /api/archidekt?user=NAME   -> Liste der öffentlichen Decks dieses Nutzers
//           /api/archidekt?deck=ID     -> Karten eines Decks
// Es werden ausschließlich feste Archidekt-Adressen abgerufen.

const BASE = 'https://archidekt.com/api';
const UA = 'mtg-tour-hobby-app/1.0 (Turnier-App; Deckimport auf Wunsch des Nutzers)';

async function getJson(url) {
  const r = await fetch(url, { headers: { Accept: 'application/json', 'User-Agent': UA } });
  if (!r.ok) {
    const e = new Error('archidekt ' + r.status);
    e.status = r.status;
    throw e;
  }
  return r.json();
}

function catName(c) {
  return typeof c === 'string' ? c : (c && c.name) || '';
}

function toEntries(deck) {
  const excluded = {};
  (Array.isArray(deck.categories) ? deck.categories : []).forEach((c) => {
    if (c && c.includedInDeck === false) excluded[catName(c)] = true;
  });
  const out = [];
  (Array.isArray(deck.cards) ? deck.cards : []).forEach((row) => {
    if (!row || row.deletedAt) return;
    const card = row.card || {};
    const oracle = card.oracleCard || {};
    const name = oracle.name || card.displayName || card.name || '';
    const cats = (Array.isArray(row.categories) ? row.categories : []).map(catName).filter(Boolean);
    if (!name) return;
    if (cats.length && cats.every((c) => excluded[c] || /^(maybeboard|sideboard|considering)$/i.test(c))) return;
    const edition = card.edition || {};
    out.push({
      q: Number(row.quantity) > 0 ? Number(row.quantity) : 1,
      name: name,
      set: edition.editioncode || '',
      cn: card.collectorNumber ? String(card.collectorNumber) : '',
      id: card.uid || '',
      cmdr: cats.some((c) => /^commander$/i.test(c)),
    });
  });
  return out;
}

module.exports = async (req, res) => {
  const q = req.query || {};
  res.setHeader('Cache-Control', 's-maxage=60');
  try {
    if (q.user !== undefined) {
      const user = String(q.user).trim();
      if (!/^[A-Za-z0-9_.\-]{1,40}$/.test(user)) return res.status(400).json({ error: 'Ungültiger Nutzername.' });
      const decks = [];
      let url = BASE + '/decks/v3/?ownerUsername=' + encodeURIComponent(user);
      for (let page = 0; page < 5 && url; page++) {
        const data = await getJson(url);
        (Array.isArray(data.results) ? data.results : []).forEach((d) => {
          const owner = (d.owner && d.owner.username) || '';
          if (owner && owner.toLowerCase() !== user.toLowerCase()) return;
          decks.push({ id: d.id, name: d.name || 'Deck ' + d.id, updated: d.updatedAt || '' });
        });
        url = typeof data.next === 'string' && data.next.indexOf('https://archidekt.com/api/') === 0 ? data.next : null;
      }
      return res.status(200).json({ user: user, decks: decks });
    }
    if (q.deck !== undefined) {
      const id = String(q.deck).trim();
      if (!/^[0-9]{1,12}$/.test(id)) return res.status(400).json({ error: 'Ungültige Deck-Nummer.' });
      const deck = await getJson(BASE + '/decks/' + id + '/');
      const entries = toEntries(deck);
      if (!entries.length) {
        return res.status(502).json({ error: 'Das Deck wurde gefunden, aber die Karten konnten nicht gelesen werden.', keys: Object.keys(deck || {}).slice(0, 30) });
      }
      return res.status(200).json({ id: deck.id, name: deck.name || '', entries: entries });
    }
    return res.status(400).json({ error: 'Es fehlt der Nutzername oder die Deck-Nummer.' });
  } catch (e) {
    const s = e && e.status;
    if (s === 404) return res.status(404).json({ error: 'Bei Archidekt nicht gefunden. Das Deck oder Profil ist vielleicht privat.' });
    if (s === 403 || s === 429) return res.status(502).json({ error: 'Archidekt hat den Abruf abgelehnt (' + s + '). Versuch es später noch einmal oder füge die Liste als Text ein.' });
    return res.status(502).json({ error: 'Archidekt ist gerade nicht erreichbar.' });
  }
};

module.exports.toEntries = toEntries;
