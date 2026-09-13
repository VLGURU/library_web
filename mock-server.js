const http = require('http');
const { URL } = require('url');

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
  sendJson(res, 422, { message, errors });
}

function conflict(res, message = 'Конфликт операции') {
  sendJson(res, 409, { message });
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

/* ---------------- In-memory data ---------------- */

let nextIds = {
  book: 3,
  author: 4,
  genre: 4,
  publisher: 3,
  reader: 3,
  card: 2,
};

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

const readers = [
  { id: 1, firstName: 'Иван', lastName: 'Петров', phone: '+7 900 000-00-01', deletedAt: null },
  { id: 2, firstName: 'Анна', lastName: 'Иванова', phone: '+7 900 000-00-02', deletedAt: null },
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
    copiesTotal: 2,
    copiesAvailable: 2,
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

// Для демонстрации 409 (выдача книги без свободных экземпляров)
const libraryCards = [
  {
    id: 1,
    bookId: 1,
    readerId: 1,
    issuedAt: nowIso(),
    returnedAt: null,
    dueAt: null,
    deletedAt: null,
  },
];

function expandBook(b) {
  const pub = publishers.find((p) => p.id === b.publisherId) || null;
  const auth = (b.authorIds || [])
    .map((id) => authors.find((a) => a.id === id))
    .filter(Boolean);
  const gen = (b.genreIds || [])
    .map((id) => genres.find((g) => g.id === id))
    .filter(Boolean);

  return { ...b, publisher: pub, authors: auth, genres: gen };
}

function expandCard(c) {
  const book = books.find((b) => b.id === c.bookId) || null;
  const reader = readers.find((r) => r.id === c.readerId) || null;
  return {
    ...c,
    book: book ? expandBook(book) : null,
    reader: reader || null,
  };
}

/* ---------------- Books handlers ---------------- */

async function handleBooks(req, res, urlObj) {
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

    sendJson(res, 200, {
      items: pageObj.items.map(expandBook),
      page: pageObj.page,
      size: pageObj.size,
      total: pageObj.total,
    });
    return;
  }

  if (req.method === 'POST') {
    let body;
    try {
      body = await readBody(req);
    } catch {
      sendJson(res, 400, { message: 'Некорректный JSON' });
      return;
    }

    const errors = {};
    const title = String(body.title || '').trim();
    const isbn = String(body.isbn || '').trim();
    const year = toInt(body.year, null);
    const pages = toInt(body.pages, null);
    const publisherId = toInt(body.publisherId, null);
    const authorIds = Array.isArray(body.authorIds)
      ? body.authorIds.map((x) => toInt(x, null)).filter((x) => x)
      : [];
    const genreIds = Array.isArray(body.genreIds)
      ? body.genreIds.map((x) => toInt(x, null)).filter((x) => x)
      : [];
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

    if (publisherId !== null && !publishers.some((p) => p.id === publisherId)) {
      errors.publisherId = 'Издатель не существует';
    }
    if (authorIds.length && authorIds.some((id) => !authors.some((a) => a.id === id))) {
      errors.authorIds = 'Один из авторов не существует';
    }
    if (genreIds.length && genreIds.some((id) => !genres.some((g) => g.id === id))) {
      errors.genreIds = 'Один из жанров не существует';
    }

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

async function handleBookById(req, res, urlObj, id) {
  const hard = isTruthy(urlObj.searchParams.get('hard'));
  const book = books.find((b) => b.id === id);

  if (!book) {
    sendJson(res, 404, { message: 'Книга не найдена' });
    return;
  }

  if (req.method === 'GET') {
    sendJson(res, 200, expandBook(book));
    return;
  }

  if (req.method === 'PUT') {
    let body;
    try {
      body = await readBody(req);
    } catch {
      sendJson(res, 400, { message: 'Некорректный JSON' });
      return;
    }

    const errors = {};
    const title = String(body.title || '').trim();
    const isbn = String(body.isbn || '').trim();
    const year = toInt(body.year, null);
    const pages = toInt(body.pages, null);
    const publisherId = toInt(body.publisherId, null);
    const authorIds = Array.isArray(body.authorIds)
      ? body.authorIds.map((x) => toInt(x, null)).filter((x) => x)
      : [];
    const genreIds = Array.isArray(body.genreIds)
      ? body.genreIds.map((x) => toInt(x, null)).filter((x) => x)
      : [];
    const copiesTotal = toInt(body.copiesTotal, null);

    if (!title) errors.title = 'Поле обязательно';
    if (!isbn) errors.isbn = 'Поле обязательно';
    if (year === null) errors.year = 'Некорректный год';
    if (pages === null) errors.pages = 'Некорректное количество страниц';
    if (publisherId === null) errors.publisherId = 'Некорректный издатель';
    if (!authorIds.length) errors.authorIds = 'Нужно выбрать хотя бы одного автора';
    if (!genreIds.length) errors.genreIds = 'Нужно выбрать хотя бы один жанр';
    if (copiesTotal === null || copiesTotal < 0) errors.copiesTotal = 'Некорректное значение';

    const isbnExists = books.some(
      (b) => b.id !== id && String(b.isbn || '').toLowerCase() === isbn.toLowerCase(),
    );
    if (isbn && isbnExists) errors.isbn = 'ISBN уже существует';

    if (publisherId !== null && !publishers.some((p) => p.id === publisherId)) {
      errors.publisherId = 'Издатель не существует';
    }
    if (authorIds.length && authorIds.some((aid) => !authors.some((a) => a.id === aid))) {
      errors.authorIds = 'Один из авторов не существует';
    }
    if (genreIds.length && genreIds.some((gid) => !genres.some((g) => g.id === gid))) {
      errors.genreIds = 'Один из жанров не существует';
    }

    if (Object.keys(errors).length) return validationError(res, errors);

    book.title = title;
    book.isbn = isbn;
    book.year = year;
    book.pages = pages;
    book.publisherId = publisherId;
    book.authorIds = authorIds;
    book.genreIds = genreIds;

    // поджимаем available, если total уменьшили
    book.copiesTotal = copiesTotal;
    book.copiesAvailable = Math.min(book.copiesAvailable, copiesTotal);

    sendJson(res, 200, expandBook(book));
    return;
  }

  if (req.method === 'DELETE') {
    if (hard) {
      const idx = books.findIndex((b) => b.id === id);
      if (idx >= 0) books.splice(idx, 1);
      return sendNoContent(res);
    }
    if (!book.deletedAt) book.deletedAt = nowIso();
    return sendNoContent(res);
  }

  notFound(res);
}

async function handleBookRestore(req, res, id) {
  const book = books.find((b) => b.id === id);
  if (!book) return sendJson(res, 404, { message: 'Книга не найдена' });
  book.deletedAt = null;
  sendNoContent(res);
}

async function handleBookBulkDelete(req, res) {
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

/* ---------------- Paged Authors handlers ---------------- */

async function handleAuthors(req, res, urlObj) {
  if (req.method === 'GET') {
    const includeDeleted = isTruthy(urlObj.searchParams.get('includeDeleted'));
    const search = (urlObj.searchParams.get('search') || '').trim().toLowerCase();

    const sortParam = (urlObj.searchParams.get('sort') || 'lastName,asc').trim();
    const [sortFieldRaw, sortDirRaw] = sortParam.split(',');
    const sortField = (sortFieldRaw || 'lastName').trim();
    const sortAsc = String(sortDirRaw || 'asc').toLowerCase() !== 'desc';

    const page = toInt(urlObj.searchParams.get('page'), 1) || 1;
    const size = toInt(urlObj.searchParams.get('size'), 10) || 10;

    let items = authors.slice();
    if (!includeDeleted) items = items.filter((a) => !a.deletedAt);

    if (search) {
      items = items.filter((a) => {
        const s = `${a.firstName || ''} ${a.lastName || ''} ${a.country || ''}`.toLowerCase();
        return s.includes(search);
      });
    }

    items.sort((a, b) => {
      const av = a[sortField];
      const bv = b[sortField];
      if (av === bv) return 0;
      if (av === undefined || av === null) return sortAsc ? -1 : 1;
      if (bv === undefined || bv === null) return sortAsc ? 1 : -1;
      return (av > bv ? 1 : -1) * (sortAsc ? 1 : -1);
    });

    const pageObj = listToPage(items, page, size);
    sendJson(res, 200, {
      items: pageObj.items,
      page: pageObj.page,
      size: pageObj.size,
      total: pageObj.total,
    });
    return;
  }

  if (req.method === 'POST') {
    let body;
    try {
      body = await readBody(req);
    } catch {
      return sendJson(res, 400, { message: 'Некорректный JSON' });
    }

    const errors = {};
    const firstName = String(body.firstName || '').trim();
    const lastName = String(body.lastName || '').trim();
    const country = String(body.country || '').trim();

    if (!firstName) errors.firstName = 'Поле обязательно';
    if (!lastName) errors.lastName = 'Поле обязательно';
    if (!country) errors.country = 'Поле обязательно';

    if (Object.keys(errors).length) return validationError(res, errors);

    const created = {
      id: nextIds.author++,
      firstName,
      lastName,
      country,
      deletedAt: null,
    };
    authors.push(created);
    sendJson(res, 200, created);
    return;
  }

  notFound(res);
}

async function handleAuthorById(req, res, urlObj, id) {
  const hard = isTruthy(urlObj.searchParams.get('hard'));
  const author = authors.find((a) => a.id === id);

  if (!author) return sendJson(res, 404, { message: 'Автор не найден' });

  if (req.method === 'GET') return sendJson(res, 200, author);

  if (req.method === 'PUT') {
    let body;
    try {
      body = await readBody(req);
    } catch {
      return sendJson(res, 400, { message: 'Некорректный JSON' });
    }

    const errors = {};
    const firstName = String(body.firstName || '').trim();
    const lastName = String(body.lastName || '').trim();
    const country = String(body.country || '').trim();

    if (!firstName) errors.firstName = 'Поле обязательно';
    if (!lastName) errors.lastName = 'Поле обязательно';
    if (!country) errors.country = 'Поле обязательно';

    if (Object.keys(errors).length) return validationError(res, errors);

    author.firstName = firstName;
    author.lastName = lastName;
    author.country = country;
    return sendJson(res, 200, author);
  }

  if (req.method === 'DELETE') {
    if (hard) {
      const idx = authors.findIndex((a) => a.id === id);
      if (idx >= 0) authors.splice(idx, 1);
      return sendNoContent(res);
    }
    if (!author.deletedAt) author.deletedAt = nowIso();
    return sendNoContent(res);
  }

  notFound(res);
}

async function handleAuthorRestore(req, res, id) {
  const author = authors.find((a) => a.id === id);
  if (!author) return sendJson(res, 404, { message: 'Автор не найден' });
  author.deletedAt = null;
  sendNoContent(res);
}

async function handleAuthorBulkDelete(req, res) {
  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const ids = Array.isArray(body.ids) ? body.ids.map((x) => toInt(x, null)).filter(Boolean) : [];
  let deleted = 0;

  for (const id of ids) {
    const a = authors.find((x) => x.id === id);
    if (a && !a.deletedAt) {
      a.deletedAt = nowIso();
      deleted++;
    }
  }

  sendJson(res, 200, { deleted });
}

/* ---------------- Simple list entities (genres/publishers/readers) ---------------- */

async function handleListGet(res, urlObj, storage) {
  const includeDeleted = isTruthy(urlObj.searchParams.get('includeDeleted'));
  let items = storage.slice();
  if (!includeDeleted) items = items.filter((x) => !x.deletedAt);
  sendJson(res, 200, items);
}

async function handleSimpleCreate(req, res, storage, nextKey, requiredFields) {
  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const errors = {};
  for (const f of requiredFields) {
    if (!String(body[f] || '').trim()) errors[f] = 'Поле обязательно';
  }
  if (Object.keys(errors).length) return validationError(res, errors);

  const created = { ...body, id: nextIds[nextKey]++, deletedAt: null };
  storage.push(created);
  sendJson(res, 200, created);
}

async function handleSimpleById(req, res, urlObj, storage, id, requiredFields) {
  const hard = isTruthy(urlObj.searchParams.get('hard'));
  const item = storage.find((x) => x.id === id);

  if (!item) return sendJson(res, 404, { message: 'Не найдено' });

  if (req.method === 'GET') return sendJson(res, 200, item);

  if (req.method === 'PUT') {
    let body;
    try {
      body = await readBody(req);
    } catch {
      return sendJson(res, 400, { message: 'Некорректный JSON' });
    }

    const errors = {};
    for (const f of requiredFields) {
      if (!String(body[f] || '').trim()) errors[f] = 'Поле обязательно';
    }
    if (Object.keys(errors).length) return validationError(res, errors);

    for (const k of Object.keys(body)) {
      if (k === 'id' || k === 'deletedAt') continue;
      item[k] = body[k];
    }

    return sendJson(res, 200, item);
  }

  if (req.method === 'DELETE') {
    if (hard) {
      const idx = storage.findIndex((x) => x.id === id);
      if (idx >= 0) storage.splice(idx, 1);
      return sendNoContent(res);
    }
    if (!item.deletedAt) item.deletedAt = nowIso();
    return sendNoContent(res);
  }

  notFound(res);
}

async function handleSimpleRestore(res, storage, id) {
  const item = storage.find((x) => x.id === id);
  if (!item) return sendJson(res, 404, { message: 'Не найдено' });
  item.deletedAt = null;
  sendNoContent(res);
}

/* ---------------- Library Cards (для демонстрации 409) ---------------- */

async function handleCards(req, res, urlObj) {
  if (req.method === 'GET') {
    const includeDeleted = isTruthy(urlObj.searchParams.get('includeDeleted'));
    const page = toInt(urlObj.searchParams.get('page'), 1) || 1;
    const size = toInt(urlObj.searchParams.get('size'), 10) || 10;

    let items = libraryCards.slice();
    if (!includeDeleted) items = items.filter((c) => !c.deletedAt);

    const pageObj = listToPage(items, page, size);
    sendJson(res, 200, {
      items: pageObj.items.map(expandCard),
      page: pageObj.page,
      size: pageObj.size,
      total: pageObj.total,
    });
    return;
  }

  notFound(res);
}

// POST /api/library-cards/issue  body: { bookId, readerId, dueAt? }
async function handleCardIssue(req, res) {
  let body;
  try {
    body = await readBody(req);
  } catch {
    return sendJson(res, 400, { message: 'Некорректный JSON' });
  }

  const errors = {};
  const bookId = toInt(body.bookId, null);
  const readerId = toInt(body.readerId, null);

  if (bookId === null) errors.bookId = 'Некорректная книга';
  if (readerId === null) errors.readerId = 'Некорректный читатель';

  if (Object.keys(errors).length) return validationError(res, errors);

  const book = books.find((b) => b.id === bookId);
  if (!book || book.deletedAt) return validationError(res, { bookId: 'Книга не существует' });

  const reader = readers.find((r) => r.id === readerId);
  if (!reader || reader.deletedAt) return validationError(res, { readerId: 'Читатель не существует' });

  if ((book.copiesAvailable || 0) <= 0) {
    return conflict(res, 'Нет свободных экземпляров книги');
  }

  book.copiesAvailable -= 1;

  const created = {
    id: nextIds.card++,
    bookId,
    readerId,
    issuedAt: nowIso(),
    returnedAt: null,
    dueAt: body.dueAt ? String(body.dueAt) : null,
    deletedAt: null,
  };
  libraryCards.push(created);

  sendJson(res, 200, expandCard(created));
}

// POST /api/library-cards/{id}/return
async function handleCardReturn(req, res, id) {
  const card = libraryCards.find((c) => c.id === id);
  if (!card) return sendJson(res, 404, { message: 'Выдача не найдена' });

  if (card.returnedAt) {
    return sendNoContent(res);
  }

  const book = books.find((b) => b.id === card.bookId);
  if (book) {
    book.copiesAvailable = Math.min(book.copiesTotal, (book.copiesAvailable || 0) + 1);
  }

  card.returnedAt = nowIso();
  sendNoContent(res);
}

/* ---------------- Server routes ---------------- */

const server = http.createServer(async (req, res) => {
  const urlObj = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  // CORS preflight
  if (req.method === 'OPTIONS') return sendNoContent(res);

  const run = applyDebugDelayAndFail(urlObj, async () => {
    // health
    if (req.method === 'GET' && urlObj.pathname === '/api/__health') {
      return sendJson(res, 200, { ok: true, time: nowIso() });
    }

    // books
    if (urlObj.pathname === '/api/books') return handleBooks(req, res, urlObj);
    if (urlObj.pathname === '/api/books/bulk-delete' && req.method === 'POST') return handleBookBulkDelete(req, res);

    if (urlObj.pathname.startsWith('/api/books/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/books/');
      if (id === null) return notFound(res);

      if (urlObj.pathname.endsWith('/restore') && req.method === 'POST') return handleBookRestore(req, res, id);

      return handleBookById(req, res, urlObj, id);
    }

    // authors
    if (urlObj.pathname === '/api/authors') return handleAuthors(req, res, urlObj);
    if (urlObj.pathname === '/api/authors/bulk-delete' && req.method === 'POST') return handleAuthorBulkDelete(req, res);

    if (urlObj.pathname.startsWith('/api/authors/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/authors/');
      if (id === null) return notFound(res);

      if (urlObj.pathname.endsWith('/restore') && req.method === 'POST') return handleAuthorRestore(req, res, id);

      return handleAuthorById(req, res, urlObj, id);
    }

    // genres
    if (urlObj.pathname === '/api/genres') {
      if (req.method === 'GET') return handleListGet(res, urlObj, genres);
      if (req.method === 'POST') return handleSimpleCreate(req, res, genres, 'genre', ['name']);
      return notFound(res);
    }
    if (urlObj.pathname.startsWith('/api/genres/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/genres/');
      if (id === null) return notFound(res);

      if (urlObj.pathname.endsWith('/restore') && req.method === 'POST') return handleSimpleRestore(res, genres, id);

      return handleSimpleById(req, res, urlObj, genres, id, ['name']);
    }

    // publishers
    if (urlObj.pathname === '/api/publishers') {
      if (req.method === 'GET') return handleListGet(res, urlObj, publishers);
      if (req.method === 'POST') return handleSimpleCreate(req, res, publishers, 'publisher', ['name']);
      return notFound(res);
    }
    if (urlObj.pathname.startsWith('/api/publishers/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/publishers/');
      if (id === null) return notFound(res);

      if (urlObj.pathname.endsWith('/restore') && req.method === 'POST') return handleSimpleRestore(res, publishers, id);

      return handleSimpleById(req, res, urlObj, publishers, id, ['name']);
    }

    // readers
    if (urlObj.pathname === '/api/readers') {
      if (req.method === 'GET') return handleListGet(res, urlObj, readers);
      if (req.method === 'POST') return handleSimpleCreate(req, res, readers, 'reader', ['firstName', 'lastName']);
      return notFound(res);
    }
    if (urlObj.pathname.startsWith('/api/readers/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/readers/');
      if (id === null) return notFound(res);

      if (urlObj.pathname.endsWith('/restore') && req.method === 'POST') return handleSimpleRestore(res, readers, id);

      return handleSimpleById(req, res, urlObj, readers, id, ['firstName', 'lastName']);
    }

    // library cards (409 demo)
    if (urlObj.pathname === '/api/library-cards') return handleCards(req, res, urlObj);
    if (urlObj.pathname === '/api/library-cards/issue' && req.method === 'POST') return handleCardIssue(req, res);

    if (urlObj.pathname.startsWith('/api/library-cards/')) {
      const id = parseIdFromPath(urlObj.pathname, '/api/library-cards/');
      if (id === null) return notFound(res);

      if (urlObj.pathname.endsWith('/return') && req.method === 'POST') return handleCardReturn(req, res, id);
    }

    // default
    return notFound(res);
  });

  run(req, res);
});

server.listen(PORT, () => {
  console.log(`[mock-server] listening: http://localhost:${PORT}`);
  console.log(`[mock-server] apiBaseUrl : http://localhost:${PORT}/api`);
  console.log(`[mock-server] origin    : ${ALLOWED_ORIGIN}`);
});
