#!/usr/bin/env python3
"""Подготовка описания задачи к публикации в удалённый трекер.
Использование: normalize.py <файл.md> [--json | --diff]
  без флагов  — печатает текст, который уйдёт в трекер
  --json      — {"description": "..."} для инструмента редактирования задачи
  --diff      — что изменится в трекере: нормализованный HEAD-вариант против текущего файла

Что делает:
  - отбрасывает frontmatter;
  - абзац / пункт списка — одной строкой (мягкие переносы склеиваются); таблицы выравниваются; код не трогается;
  - id задач в remote-режиме и есть ключи трекера; упоминание локальной задачи (local_prefix) — предупреждение;
  - ссылки на локальные файлы `[текст](path.md)` превращает в «текст» и предупреждает; http(s)-ссылки оставляет.
Локальный файл при этом не меняется — он остаётся с переносами."""
import difflib, json, os, re, subprocess, sys

FM_ID = re.compile(r'^id:\s*(\S+)', re.M)
FM_REMOTE = re.compile(r'^remote:\s*"?([^"\n]*)"?\s*$', re.M)
FM_LOCAL = re.compile(r'^local_prefix:\s*(\S+)', re.M)
warnings = []

def split_frontmatter(text):
    if not text.startswith('---'): return '', text
    end = text.find('\n---', 3)
    return (text[:end+4], text[end+4:]) if end != -1 else ('', text)

def join_soft_breaks(lines):
    res, buf, code = [], [], False
    def flush():
        if buf: res.append(' '.join(s.strip() for s in buf)); buf.clear()
    for l in lines:
        if l.strip().startswith('```'): flush(); code = not code; res.append(l); continue
        if code: res.append(l); continue
        s = l.rstrip()
        if s.strip() in ('', '---'): flush(); res.append(''); continue
        if s.lstrip().startswith('|'):
            flush(); cells = [c.strip() for c in s.strip().strip('|').split('|')]
            sep = all(re.fullmatch(r':?-+:?', c) for c in cells)
            res.append('|' + '|'.join('---' for _ in cells) + '|' if sep else '| ' + ' | '.join(cells) + ' |'); continue
        if s.startswith('#'): flush(); res.append(s); continue
        if re.match(r'^\s*([-*]|\d+\.)\s', s): flush(); buf.append(s); continue
        buf.append(s)
    flush()
    return re.sub(r'\n{3,}', '\n\n', '\n'.join(res)).strip() + '\n'

def tracker_root(path):
    d = os.path.dirname(os.path.abspath(path))
    while d != '/':
        if os.path.basename(d) == 'tracker' and os.path.isdir(os.path.join(d, 'tasks')): return d
        d = os.path.dirname(d)
    return None

def local_prefix(tr):
    if not tr: return 'LOC'
    p = os.path.join(os.path.dirname(os.path.dirname(tr)), 'project.yaml')
    try: m = FM_LOCAL.search(open(p, encoding='utf-8').read()); return m.group(1) if m else 'LOC'
    except OSError: return 'LOC'

def rewrite_links(text, prefix):
    def link(m):
        label, target = m.group(1), m.group(2)
        if re.match(r'^(https?:|mailto:)', target): return m.group(0)
        warnings.append(f'локальная ссылка убрана: [{label}]({target})'); return label
    text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link, text)
    for i in sorted(set(re.findall(rf'\b{re.escape(prefix)}-\d+\b', text))):
        warnings.append(f'{i}: локальная задача, в трекере её нет')
    return text

def prepare(text, prefix):
    _, body = split_frontmatter(text)
    return rewrite_links(join_soft_breaks(body.splitlines()), prefix)

def main():
    if len(sys.argv) < 2: print(__doc__); sys.exit(2)
    path, flag = sys.argv[1], (sys.argv[2] if len(sys.argv) > 2 else '')
    tr = tracker_root(path); prefix = local_prefix(tr)
    cur = prepare(open(path, encoding='utf-8').read(), prefix)
    if flag == '--json': print(json.dumps({'description': cur}, ensure_ascii=False))
    elif flag == '--diff':
        root = subprocess.run(['git', 'rev-parse', '--show-toplevel'], capture_output=True, text=True,
                              cwd=os.path.dirname(os.path.abspath(path))).stdout.strip()
        rel = os.path.relpath(os.path.abspath(path), root)
        old = subprocess.run(['git', 'show', f'HEAD:{rel}'], capture_output=True, text=True, cwd=root).stdout
        prev = prepare(old, prefix) if old else ''
        sys.stdout.writelines(difflib.unified_diff(prev.splitlines(True), cur.splitlines(True), 'HEAD (в трекере)', 'файл', n=1))
    else: sys.stdout.write(cur)
    for w in dict.fromkeys(warnings): print('▲ ' + w, file=sys.stderr)
main()
