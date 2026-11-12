const { HttpError } = require('./errors');

const isDate = (v) => /^\d{4}-\d{2}-\d{2}$/.test(v) && !isNaN(Date.parse(v));
const isTime = (v) => /^([01]\d|2[0-3]):[0-5]\d$/.test(v);

/** spec: { campo: 'tipo!' } (! = obrigatório). Devolve objeto limpo ou lança 400. */
function clean(spec, body = {}) {
  const out = {};
  for (const [key, def] of Object.entries(spec)) {
    const required = def.endsWith('!');
    const type = def.replace('!', '');
    let v = body[key];
    if (v === undefined || v === null || v === '') {
      if (required) throw new HttpError(400, `Campo obrigatório: ${key}`);
      out[key] = null;
      continue;
    }
    switch (type) {
      case 'text':
        v = String(v).trim();
        if (v.length > 2000) throw new HttpError(400, `${key} demasiado longo`);
        break;
      case 'date': if (!isDate(v)) throw new HttpError(400, `${key}: data inválida (YYYY-MM-DD)`); break;
      case 'time': if (!isTime(v)) throw new HttpError(400, `${key}: hora inválida (HH:MM)`); break;
      case 'ts':
        if (isNaN(Date.parse(v))) throw new HttpError(400, `${key}: data/hora inválida`);
        v = new Date(v).toISOString();
        break;
      case 'num':
        v = Number(v);
        if (!Number.isFinite(v) || v <= 0 || v > 9999) throw new HttpError(400, `${key}: número inválido`);
        break;
      case 'sev':
        if (!['low', 'medium', 'high'].includes(v)) throw new HttpError(400, `${key}: valor inválido`);
        break;
      case 'sex':
        if (!['male', 'female'].includes(v)) throw new HttpError(400, `${key}: valor inválido`);
        break;
      case 'days':
        v = String(v);
        if (!/^[1-7](,[1-7]){0,6}$/.test(v)) throw new HttpError(400, `${key}: dias inválidos`);
        break;
      default: throw new HttpError(500, 'Tipo de validação desconhecido');
    }
    out[key] = v;
  }
  return out;
}
module.exports = { clean };
