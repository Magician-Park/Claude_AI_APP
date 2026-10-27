import { createReadStream } from 'node:fs';
import { realpath, stat } from 'node:fs/promises';
import { createServer } from 'node:http';
import { extname, isAbsolute, relative, resolve, sep } from 'node:path';
import { pipeline } from 'node:stream/promises';
import { fileURLToPath } from 'node:url';

const root = await realpath(fileURLToPath(new URL('../', import.meta.url)));
const host = process.env.FARMCARGO_HOST ?? '127.0.0.1';
const port = Number(process.env.FARMCARGO_PORT ?? 4173);
if (!Number.isInteger(port) || port < 0 || port > 65535) {
  throw new Error('FARMCARGO_PORT must be an integer between 0 and 65535.');
}

const contentTypes = {
  '.html': 'text/html; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.webmanifest': 'application/manifest+json; charset=utf-8',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
};

function sendError(response, status, message) {
  response.writeHead(status, { 'Content-Type': 'text/plain; charset=utf-8' });
  response.end(message);
}

const server = createServer(async (request, response) => {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    response.setHeader('Allow', 'GET, HEAD');
    sendError(response, 405, 'Method not allowed');
    return;
  }

  let pathname;
  try {
    pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    if (pathname.includes('\0') || pathname.includes('\\')) throw new Error('Invalid path');
  } catch {
    sendError(response, 400, 'Bad request');
    return;
  }
  if (pathname.split('/').some((part) => part.startsWith('.'))) {
    sendError(response, 403, 'Forbidden');
    return;
  }

  try {
    let file = await realpath(resolve(root, `.${pathname}`));
    if ((await stat(file)).isDirectory()) file = await realpath(resolve(file, 'index.html'));
    const relativePath = relative(root, file);
    if (relativePath === '..' || relativePath.startsWith(`..${sep}`) || isAbsolute(relativePath)
      || relativePath.split(sep).some((part) => part.startsWith('.'))) {
      sendError(response, 403, 'Forbidden');
      return;
    }
    const info = await stat(file);
    if (!info.isFile()) {
      sendError(response, 404, 'Not found');
      return;
    }
    response.writeHead(200, {
      'Content-Type': contentTypes[extname(file).toLowerCase()] ?? 'application/octet-stream',
      'Content-Length': info.size,
      'Cache-Control': 'no-store',
      'X-Content-Type-Options': 'nosniff',
    });
    if (request.method === 'HEAD') response.end();
    else await pipeline(createReadStream(file), response);
  } catch (error) {
    if (response.headersSent) {
      response.destroy();
      return;
    }
    const missing = error.code === 'ENOENT' || error.code === 'ENOTDIR';
    sendError(response, missing ? 404 : 500, missing ? 'Not found' : 'Server error');
    if (!missing) console.error(error);
  }
});

server.on('error', (error) => {
  console.error(error.message);
  process.exitCode = 1;
});
server.listen(port, host, () => {
  console.log(`FarmCargo workspace: http://${host}:${server.address().port}`);
});
