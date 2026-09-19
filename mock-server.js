const http = require('http');
const { URL } = require('url');
const crypto = require('crypto');

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next && !next.startsWith('--')) {
      args[key] = next;
      i++;
    } else {
      args[key] = true;
    }
  }
  return args;
}

const args = parseArgs(process.argv);
const PORT = Number(args.port || 8080);
const ALLOWED_ORIGIN = String(args.origin || 'http://localhost:5555');
const ACCESS_TTL_SEC = Number(args.ttl || 900);
const REFRESH_TTL_SEC = Number(args.refreshTtl || 7 * 24 * 60 * 60);

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    'Vary': 'Origin',
    'Access-Control-Allow-Methods': 'GET,POST,PUT,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}

function sendJson(res, status, data) {
  res.writeHead(status, {
    ...corsHeaders(),
    'Content-Type': 'application/json; charset=utf-8',
  });
  res.end(JSON.stringify(data));
}

function sendNoContent(res) {
  res.writeHead(204, { ...corsHeaders() });
  res.end();
}

function toInt(v, def = null) {
  if (v === null || v === undefined || v === '') return def;
  const n = Number(v);
  return Number.isFinite(n) ? Math.trunc(n) : def;
}

function isTruthy(v) {
  if (v === null || v === undefined) return false;
  const s = String(v).toLowerCase();
  return s === '1' || s === 'true' || s === 'yes';
}

function nowIso() {
  return new Date().toISOString();
}

function nowMs() {
  return Date.now();
}

function applyDebugDelayAndFail(urlObj, handler) {
  const delay = toInt(urlObj.searchParams.get('__delay'), 0) || 0;
  const fail = toInt(urlObj.searchParams.get('__fail'), null);

  return (req, res) => {
    const run = () => {
      if (fail !== null) {
        sendJson(res, fail, { message: `Принудительная ошибка __fail=${fail}` });
        return;
      }
      handler(req, res);
    };
    if (delay > 0) setTimeout(run, delay);
    else run();
  };
}

function notFound(res) {
  sendJson(res, 404, { message: 'Не найдено' });
}

function validationError(res, errors, message = 'Ошибка валидации') {
  // чистим undefined чтобы клиент не падал
  const clean = {};
  for (const k of Object.keys(errors)) {
    if (errors[k] !== undefined && errors[k] !== null) clean[k] = errors[k];
  }
  sendJson(res, 422, { message, errors: clean });
}

function conflict(res, message = 'Конфликт операции') {
  sendJson(res, 409, { message });
}

function forbidden(res, message = 'Недостаточно прав') {
  sendJson(res, 403, { message });
}

function unauthorized(res, message = 'Требуется вход') {
  sendJson(res, 401, { message });
}

function parseIdFromPath(pathname, prefix) {
  if (!pathname.startsWith(prefix)) return null;
  const rest = pathname.slice(prefix.length);
  const part = rest.split('/')[0];
  const id = toInt(part, null);
  return id;
}

function listToPage(items, page, size) {
  const total = items.length;
  const totalPages = total === 0 ? 1 : Math.ceil(total / size);
  const safePage = Math.min(Math.max(page, 1), totalPages);
  const start = (safePage - 1) * size;
  const paged = items.slice(start, start + size);
  return { items: paged, page: safePage, size, total };
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => {
      if (!raw) return resolve({});
      try {
        resolve(JSON.parse(raw));
      } catch (e) {
        reject(e);
      }
    });
    req.on('error', reject);
  });
}

/* ---- password hashing (server-side) ---- */

function hashPassword(password) {
  const salt = crypto.randomBytes(16);
  const hash = crypto.scryptSync(password, salt, 32);
  return `${salt.toString('hex')}:${hash.toString('hex')}`;
}

function verifyPassword(stored, password) {
  const parts = String(stored || '').split(':');
  if (parts.length !== 2) return false;
  const salt = Buffer.from(parts[0], 'hex');
  const hash = Buffer.from(parts[1], 'hex');
  const test = crypto.scryptSync(password, salt, 32);
  return crypto.timingSafeEqual(hash, test);
}

/* ---- roles ---- */

const Role = {
  READER: { name: 'READER', level: 1 },
  LIBRARIAN: { name: 'LIBRARIAN', level: 2 },
  ADMIN: { name: 'ADMIN', level: 3 },
};

function roleFromName(name) {
  const n = String(name || '').toUpperCase().trim();
  return Role[n] || Role.READER;
}

function hasRole(user, requiredRole) {
  return user && roleFromName(user.role).level >= roleFromName(requiredRole).level;
}

/* ---- tokens ---- */

const accessTokens = new Map();  // token -> { userId, expMs }
const refreshTokens = new Map(); // token -> { userId, expMs }

function issueTokens(userId) {
  const accessToken = crypto.randomUUID();
  const refreshToken = crypto.randomUUID();

  accessTokens.set(accessToken, { userId, expMs: nowMs() + ACCESS_TTL_SEC * 1000 });
  refreshTokens.set(refreshToken, { userId, expMs: nowMs() + REFRESH_TTL_SEC * 1000 });

  return { accessToken, refreshToken };
}

function getBearerToken(req) {
  const h = req.headers['authorization'];
  if (!h) return null;
  const s = String(h);
  if (!s.toLowerCase().startsWith('bearer ')) return null;
  return s.slice(7).trim();
}

/* ---- data ---- */

let nextIds = {
  book: 3,
  author: 4,
  genre: 4,
  publisher: 3,
  reader: 3,
  user: 4,
  card: 2,
};

const users = [
  {
    id: 1,
    username: 'reader',
    passwordHash: hashPassword('reader123!'),
    fullName: 'Reader User',
    role: 'READER',
    deletedAt: null,
  },
  {
    id: 2,
    username: 'librarian',
    passwordHash: hashPassword('librarian123!'),
    fullName: 'Librarian User',
    role: 'LIBRARIAN',
    deletedAt: null,
  },
  {
    id: 3,
    username: 'admin',
    passwordHash: hashPassword('admin123!'),
    fullName: 'Admin User',
    role: 'ADMIN',
    deletedAt: null,
  },
];

const readers = [
  { id: 1, firstName: 'Иван', lastName: 'Петров', phone: '+7 900 000-00-01', deletedAt: null },
  { id: 2, firstName: 'Анна', lastName: 'Иванова', phone: '+7 900 000-00-02', deletedAt: null },
];

const publishers = [
  { id: 1, name: 'Питер', deletedAt: null },
  { id: 2, name: 'Эксмо', deletedAt: null },
];

const genres = [
  { id: 1, name: 'Роман', deletedAt: null },
  { id: 2, name: 'Фантастика', deletedAt: null },
  { id: 3, name: 'Детектив', deletedAt: null },
];

const authors = [
  { id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия', deletedAt: null },
  { id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия', deletedAt: null },
  { id: 3, firstName: 'Жюль', lastName: 'Верн', country: 'Франция', deletedAt: null },
];

const books = [
  {
    id: 1,
    title: 'Война и мир',
    isbn: 'ISBN-0001',
    year: 1869,
    pages: 1200,
    publisherId: 1,
    authorIds: [1],
    genreIds: [1],
    copiesTotal: 1,
    copiesAvailable: 0,
    deletedAt: null,
  },
  {
    id: 2,
    title: 'Таинственный остров',
    isbn: 'ISBN-0002',
    year: 1874,
    pages: 640,
    publisherId: 2,
    authorIds: [3],
    genreIds: [2],
    copiesTotal: 1,
    copiesAvailable: 1,
    deletedAt: null,
  },
];

const libraryCards = [
  {
    id: 1,
    bookId: 2,
    readerId: 1,
    issuedAt: nowIso(),
    returnedAt: null,
    dueAt: null,
    deletedAt: null,
  },
];

function expandBook(b) {
  const pub = publishers.find((p) => p.id === b.publisherId) || null;
  const auth = (b.authorIds || []).map((id) => authors.find((a) => a.id === id)).filter(Boolean);
  const gen = (b.genreIds || []).map((id) => genres.find((g) => g.id === id)).filter(Boolean);
  return { ...b, publisher: pub, authors: auth, genres: gen };
}

function expandCard(c) {
  const book = books.find((b) => b.id === c.bookId) || null;
  const reader = readers.find((r) => r.id === c.readerId) || null;
  return { ...c, book: book ? expandBook(book) : null, reader: reader || null };
}

function safeUser(u) {
  return { id: u.id, username: u.username, fullName: u.fullName, role: u.role };
}

/* ---- auth middleware ---- */

function requireAuth(req, res) {
  const token = getBearerToken(req);
  if (!token) {
    unauthorized(res);
    return null;
  }

  const rec = accessTokens.get(token);
  if (!rec) {
    unauthorized(res, 'Токен недействителен');
    return null;
  }

  if (rec.expMs <= nowMs()) {
    accessTokens.delete(token);
    unauthorized(res, 'Срок действия токена истёк');
    return null;
  }

  const user = users.find((u) => u.id === rec.userId);
  if (!user) {
    unauthorized(res, 'Пользователь не найден');
    return null;
  }

  return user;
}

/* ---- AUTH endpoints ---- */

async function handleAuthRegister(req, res) {
  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const username = String(body.username || '').trim();
  const password = String(body.password || '').trim();
  const fullName = String(body.fullName || '').trim();

  const errors = {};
  if (!username) errors.username = 'Поле обязательно';
  if (!password) errors.password = 'Поле обязательно';
  if (!fullName) errors.fullName = 'Поле обязательно';

  if (password) {
    const hasDigit = /\d/.test(password);
    const hasSpec = /[^a-zA-Z0-9]/.test(password);
    if (password.length < 8) errors.password = 'Минимум 8 символов';
    else if (!hasDigit) errors.password = 'Должна быть цифра';
    else if (!hasSpec) errors.password = 'Должен быть спецсимвол';
  }

  if (username && users.some((u) => u.username.toLowerCase() === username.toLowerCase())) {
    errors.username = 'Логин уже занят';
  }

  if (Object.keys(errors).length) return validationError(res, errors);

  const created = {
    id: nextIds.user++,
    username,
    passwordHash: hashPassword(password),
    fullName,
    role: 'READER',
    deletedAt: null,
  };
  users.push(created);

  const tokens = issueTokens(created.id);
  sendJson(res, 200, { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user: safeUser(created) });
}

async function handleAuthLogin(req, res) {
  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const username = String(body.username || '').trim();
  const password = String(body.password || '').trim();

  if (!username || !password) {
    return validationError(res, {
      username: !username ? 'Поле обязательно' : undefined,
      password: !password ? 'Поле обязательно' : undefined,
    });
  }

  const user = users.find((u) => u.username.toLowerCase() === username.toLowerCase());
  if (!user || !verifyPassword(user.passwordHash, password)) {
    return unauthorized(res, 'Неверный логин или пароль');
  }

  const tokens = issueTokens(user.id);
  sendJson(res, 200, { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user: safeUser(user) });
}

async function handleAuthRefresh(req, res) {
  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const refreshToken = String(body.refreshToken || '').trim();
  if (!refreshToken) return validationError(res, { refreshToken: 'Поле обязательно' });

  const rec = refreshTokens.get(refreshToken);
  if (!rec) return unauthorized(res, 'refresh token недействителен');
  if (rec.expMs <= nowMs()) {
    refreshTokens.delete(refreshToken);
    return unauthorized(res, 'refresh token истёк');
  }

  const user = users.find((u) => u.id === rec.userId);
  if (!user) return unauthorized(res, 'Пользователь не найден');

  const tokens = issueTokens(user.id);
  sendJson(res, 200, { accessToken: tokens.accessToken, refreshToken: tokens.refreshToken, user: safeUser(user) });
}

/* ---- BOOKS (GET for all, write only librarian+, hard delete admin) ---- */

async function handleBooks(req, res, urlObj, user) {
  if (req.method === 'GET') {
    const includeDeleted = isTruthy(urlObj.searchParams.get('includeDeleted'));
    const search = (urlObj.searchParams.get('search') || '').trim().toLowerCase();
    const genreId = toInt(urlObj.searchParams.get('genreId'), null);
    const publisherId = toInt(urlObj.searchParams.get('publisherId'), null);
    const yearFrom = toInt(urlObj.searchParams.get('yearFrom'), null);
    const yearTo = toInt(urlObj.searchParams.get('yearTo'), null);

    const sortParam = (urlObj.searchParams.get('sort') || 'title,asc').trim();
    const [sortFieldRaw, sortDirRaw] = sortParam.split(',');
    const sortField = (sortFieldRaw || 'title').trim();
    const sortAsc = String(sortDirRaw || 'asc').toLowerCase() !== 'desc';

    const page = toInt(urlObj.searchParams.get('page'), 1) || 1;
    const size = toInt(urlObj.searchParams.get('size'), 10) || 10;

    let items = books.slice();
    if (!includeDeleted) items = items.filter((b) => !b.deletedAt);

    if (search) {
      items = items.filter((b) => {
        const t = String(b.title || '').toLowerCase();
        const i = String(b.isbn || '').toLowerCase();
        return t.includes(search) || i.includes(search);
      });
    }

    if (genreId !== null) items = items.filter((b) => (b.genreIds || []).includes(genreId));
    if (publisherId !== null) items = items.filter((b) => b.publisherId === publisherId);
    if (yearFrom !== null) items = items.filter((b) => b.year >= yearFrom);
    if (yearTo !== null) items = items.filter((b) => b.year <= yearTo);

    items.sort((a, b) => {
      const av = a[sortField];
      const bv = b[sortField];
      if (av === bv) return 0;
      if (av === undefined || av === null) return sortAsc ? -1 : 1;
      if (bv === undefined || bv === null) return sortAsc ? 1 : -1;
      return (av > bv ? 1 : -1) * (sortAsc ? 1 : -1);
    });

    const pageObj = listToPage(items, page, size);
    sendJson(res, 200, { items: pageObj.items.map(expandBook), page: pageObj.page, size: pageObj.size, total: pageObj.total });
    return;
  }

  if (!hasRole(user, 'LIBRARIAN')) return forbidden(res);

  if (req.method === 'POST') {
    let body;
    try {
      body = await readBody(req);
    } catch {
      return sendJson(res, 400, { message: 'Некорректный JSON' });
    }

    const errors = {};
    const title = String(body.title || '').trim();
    const isbn = String(body.isbn || '').trim();
    const year = toInt(body.year, null);
    const pages = toInt(body.pages, null);
    const publisherId = toInt(body.publisherId, null);
    const authorIds = Array.isArray(body.authorIds) ? body.authorIds.map((x) => toInt(x, null)).filter(Boolean) : [];
    const genreIds = Array.isArray(body.genreIds) ? body.genreIds.map((x) => toInt(x, null)).filter(Boolean) : [];
    const copiesTotal = toInt(body.copiesTotal, null);

    if (!title) errors.title = 'Поле обязательно';
    if (!isbn) errors.isbn = 'Поле обязательно';
    if (year === null) errors.year = 'Некорректный год';
    if (pages === null) errors.pages = 'Некорректное количество страниц';
    if (publisherId === null) errors.publisherId = 'Некорректный издатель';
    if (!authorIds.length) errors.authorIds = 'Нужно выбрать хотя бы одного автора';
    if (!genreIds.length) errors.genreIds = 'Нужно выбрать хотя бы один жанр';
    if (copiesTotal === null || copiesTotal < 0) errors.copiesTotal = 'Некорректное значение';

    const isbnExists = books.some((b) => String(b.isbn || '').toLowerCase() === isbn.toLowerCase());
    if (isbn && isbnExists) errors.isbn = 'ISBN уже существует';

    if (Object.keys(errors).length) return validationError(res, errors);

    const created = {
      id: nextIds.book++,
      title,
      isbn,
      year,
      pages,
      publisherId,
      authorIds,
      genreIds,
      copiesTotal,
      copiesAvailable: copiesTotal,
      deletedAt: null,
    };
    books.push(created);
    sendJson(res, 200, expandBook(created));
    return;
  }

  notFound(res);
}

async function handleBookById(req, res, urlObj, user, id) {
  const hard = isTruthy(urlObj.searchParams.get('hard'));
  const book = books.find((b) => b.id === id);
  if (!book) return sendJson(res, 404, { message: 'Книга не найдена' });

  if (req.method === 'GET') return sendJson(res, 200, expandBook(book));

  if (!hasRole(user, 'LIBRARIAN')) return forbidden(res);

  if (req.method === 'PUT') {
    let body;
    try {
      body = await readBody(req);
    } catch {
      return sendJson(res, 400, { message: 'Некорректный JSON' });
    }

    const errors = {};
    const title = String(body.title || '').trim();
    const isbn = String(body.isbn || '').trim();
    const year = toInt(body.year, null);
    const pages = toInt(body.pages, null);
    const publisherId = toInt(body.publisherId, null);
    const authorIds = Array.isArray(body.authorIds) ? body.authorIds.map((x) => toInt(x, null)).filter(Boolean) : [];
    const genreIds = Array.isArray(body.genreIds) ? body.genreIds.map((x) => toInt(x, null)).filter(Boolean) : [];
    const copiesTotal = toInt(body.copiesTotal, null);

    if (!title) errors.title = 'Поле обязательно';
    if (!isbn) errors.isbn = 'Поле обязательно';
    if (year === null) errors.year = 'Некорректный год';
    if (pages === null) errors.pages = 'Некорректное количество страниц';
    if (publisherId === null) errors.publisherId = 'Некорректный издатель';
    if (!authorIds.length) errors.authorIds = 'Нужно выбрать хотя бы одного автора';
    if (!genreIds.length) errors.genreIds = 'Нужно выбрать хотя бы один жанр';
    if (copiesTotal === null || copiesTotal < 0) errors.copiesTotal = 'Некорректное значение';

    const isbnExists = books.some((b) => b.id !== id && String(b.isbn || '').toLowerCase() === isbn.toLowerCase());
    if (isbn && isbnExists) errors.isbn = 'ISBN уже существует';

    if (Object.keys(errors).length) return validationError(res, errors);

    book.title = title;
    book.isbn = isbn;
    book.year = year;
    book.pages = pages;
    book.publisherId = publisherId;
    book.authorIds = authorIds;
    book.genreIds = genreIds;
    book.copiesTotal = copiesTotal;
    book.copiesAvailable = Math.min(book.copiesAvailable, copiesTotal);

    return sendJson(res, 200, expandBook(book));
  }

  if (req.method === 'DELETE') {
    if (hard) {
      if (!hasRole(user, 'ADMIN')) return forbidden(res);
      const idx = books.findIndex((b) => b.id === id);
      if (idx >= 0) books.splice(idx, 1);
      return sendNoContent(res);
    }
    if (!book.deletedAt) book.deletedAt = nowIso();
    return sendNoContent(res);
  }

  notFound(res);
}

async function handleBookRestore(req, res, user, id) {
  if (!hasRole(user, 'LIBRARIAN')) return forbidden(res);
  const book = books.find((b) => b.id === id);
  if (!book) return sendJson(res, 404, { message: 'Книга не найдена' });
  book.deletedAt = null;
  sendNoContent(res);
}

async function handleBookBulkDelete(req, res, user) {
  if (!hasRole(user, 'LIBRARIAN')) return forbidden(res);

  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const ids = Array.isArray(body.ids) ? body.ids.map((x) => toInt(x, null)).filter(Boolean) : [];
  let deleted = 0;

  for (const id of ids) {
    const b = books.find((x) => x.id === id);
    if (b && !b.deletedAt) {
      b.deletedAt = nowIso();
      deleted++;
    }
  }

  sendJson(res, 200, { deleted });
}

/* ---- library cards ---- */

async function handleCardsMine(req, res, user) {
  // учебно: readerId = user.id
  const readerId = user.id;
  const items = libraryCards.filter((c) => c.readerId === readerId && !c.deletedAt);
  sendJson(res, 200, items.map(expandCard));
}

async function handleCardIssue(req, res, user) {
  if (!hasRole(user, 'LIBRARIAN')) return forbidden(res);

  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const bookId = toInt(body.bookId, null);
  const readerId = toInt(body.readerId, null);
  const errors = {};
  if (bookId === null) errors.bookId = 'Некорректная книга';
  if (readerId === null) errors.readerId = 'Некорректный читатель';
  if (Object.keys(errors).length) return validationError(res, errors);

  const book = books.find((b) => b.id === bookId);
  if (!book || book.deletedAt) return validationError(res, { bookId: 'Книга не существует' });

  const reader = readers.find((r) => r.id === readerId);
  if (!reader || reader.deletedAt) return validationError(res, { readerId: 'Читатель не существует' });

  if ((book.copiesAvailable || 0) <= 0) return conflict(res, 'Нет свободных экземпляров книги');

  book.copiesAvailable -= 1;

  const created = {
    id: nextIds.card++,
    bookId,
    readerId,
    issuedAt: nowIso(),
    returnedAt: null,
    dueAt: null,
    deletedAt: null,
  };
  libraryCards.push(created);
  sendJson(res, 200, expandCard(created));
}

async function handleCardReturn(req, res, user, id) {
  if (!hasRole(user, 'LIBRARIAN')) return forbidden(res);

  const card = libraryCards.find((c) => c.id === id);
  if (!card) return sendJson(res, 404, { message: 'Выдача не найдена' });

  if (card.returnedAt) return sendNoContent(res);

  const book = books.find((b) => b.id === card.bookId);
  if (book) {
    book.copiesAvailable = Math.min(book.copiesTotal, (book.copiesAvailable || 0) + 1);
  }

  card.returnedAt = nowIso();
  sendNoContent(res);
}

/* ---- admin ---- */

async function handleAdminUsers(req, res, user) {
  if (!hasRole(user, 'ADMIN')) return forbidden(res);
  if (req.method === 'GET') return sendJson(res, 200, users.map(safeUser));
  notFound(res);
}

/* ---- server ---- */

const server = http.createServer(async (req, res) => {
  const urlObj = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') return sendNoContent(res);

  const run = applyDebugDelayAndFail(urlObj, async () => {
    if (req.method === 'GET' && urlObj.pathname === '/api/__health') {
      return sendJson(res, 200, { ok: true, time: nowIso() });
    }

    // PUBLIC AUTH
    if (urlObj.pathname === '/api/auth/register' && req.method === 'POST') return handleAuthRegister(req, res);
    if (urlObj.pathname === '/api/auth/login' && req.method === 'POST') return handleAuthLogin(req, res);
    if (urlObj.pathname === '/api/auth/refresh' && req.method === 'POST') return handleAuthRefresh(req, res);

    // PROTECTED
    const user = requireAuth(req, res);
    if (!user) return;

    // BOOKS
    if (urlObj.pathname === '/api/books') return handleBooks(req, res, urlObj, user);
    if (urlObj.pathname === '/api/books/bulk-delete' && req.method === 'POST') return handleBookBulkDelete(req, res, user);

    if (urlObj.pathname.startsWith('/api/books/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/books/');
      if (id === null) return notFound(res);

      if (urlObj.pathname.endsWith('/restore') && req.method === 'POST') return handleBookRestore(req, res, user, id);

      return handleBookById(req, res, urlObj, user, id);
    }

    // LIBRARY CARDS
    if (urlObj.pathname === '/api/library-cards/mine' && req.method === 'GET') return handleCardsMine(req, res, user);
    if (urlObj.pathname === '/api/library-cards/issue' && req.method === 'POST') return handleCardIssue(req, res, user);

    if (urlObj.pathname.startsWith('/api/library-cards/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/library-cards/');
      if (id === null) return notFound(res);
      if (urlObj.pathname.endsWith('/return') && req.method === 'POST') return handleCardReturn(req, res, user, id);
    }

    // ADMIN
    if (urlObj.pathname === '/api/admin/users') return handleAdminUsers(req, res, user);

    return notFound(res);
  });

  run(req, res);
});

server.listen(PORT, () => {
  console.log(`[mock-server] listening: http://localhost:${PORT}`);
  console.log(`[mock-server] apiBaseUrl : http://localhost:${PORT}/api`);
  console.log(`[mock-server] origin    : ${ALLOWED_ORIGIN}`);
  console.log(`[mock-server] ttl       : ${ACCESS_TTL_SEC}s`);
  console.log(`[mock-server] accounts  : reader/reader123!, librarian/librarian123!, admin/admin123!`);
});