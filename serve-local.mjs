// Optional local preview. Node.js only; no dependencies or Firebase account.
import http from 'node:http';
import fs from 'node:fs';
import {brotliCompressSync,constants} from 'node:zlib';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
const root = fileURLToPath(new URL('./public/', import.meta.url));
const port = Number(process.env.HOUR_ZERO_PORT || process.env.MINDRUSH_PORT || process.env.MindRush_PORT || 8418);
const types = {'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml','.txt':'text/plain; charset=utf-8'};
const compressed = new Map();
for (const name of ['index.wasm','index.pck','index.js']) {
  const file = path.join(root,name);
  const bytes = fs.readFileSync(file);
  compressed.set(file,brotliCompressSync(bytes,{params:{[constants.BROTLI_PARAM_QUALITY]:5}}));
}
http.createServer((req,res) => {
  if (!['GET','HEAD'].includes(req.method)) { res.writeHead(405); res.end(); return; }
  let pathname;
  try { pathname = decodeURIComponent(new URL(req.url,'http://localhost').pathname); }
  catch { res.writeHead(400); res.end(); return; }
  const target = path.resolve(root, '.' + (pathname.endsWith('/') ? pathname+'index.html' : pathname));
  if (!target.startsWith(path.resolve(root)+path.sep)) { res.writeHead(403); res.end(); return; }
  fs.stat(target, (error,stat) => {
    if (error || !stat.isFile()) { res.writeHead(404); res.end('Not found'); return; }
    const accepts = (req.headers['accept-encoding'] || '').split(',').some(part => /^br(?:\s*;\s*q=(?!0(?:\.0*)?$)[.0-9]+)?$/i.test(part.trim()));
    const payload = accepts && compressed.get(target);
    res.writeHead(200, {'Content-Type':types[path.extname(target)] || 'application/octet-stream','Vary':'Accept-Encoding',...(payload?{'Content-Encoding':'br'}:{}),'Content-Length':payload?payload.length:stat.size,'Cache-Control':'no-cache','X-Content-Type-Options':'nosniff'});
    if (req.method==='HEAD') res.end();
    else if(payload) res.end(payload);
    else fs.createReadStream(target).on('error',()=>res.destroy()).pipe(res);
  });
}).listen(port,'127.0.0.1',()=>console.log(`Hour Zero preview: http://127.0.0.1:${port}`));
