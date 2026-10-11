#!/usr/bin/env python3
"""Рендер скелета по профилю проекта (вызывает init.sh; агенту руками не нужен).

  render.py --set k=v … [--profiles FILE] SRC_DIR DST_DIR   развернуть дерево (существующие файлы не трогает)
  render.py --set k=v … FILE                                 напечатать один отрендеренный файл

Подстановки: {{KEY}} → значение (ключ в верхнем регистре: PROJECT, TASK_PREFIX, KIND, TEAM, TRACKER, COMMIT, …);
неизвестные {{…}} остаются как есть — это плейсхолдеры для засева (SEED). Условные блоки — построчно, директива на
своей строке: {{#if EXPR}} … {{#else}} … {{/if}} (внутри строки — тоже, без вложенности); EXPR — `key` (истина: true/yes/1), `!key`, `key=v1|v2`, несколько
через `&`. Вложенность допустима. Файлы по профилю — таблица profiles.txt: «glob  EXPR», без строки — ставится всегда;
skeleton/_claude → .claude, skeleton/_gitignore → .gitignore (иначе белый список
скелета действовал бы внутри репо шаблона)."""
import fnmatch, os, re, sys

DIRECTIVE = re.compile(r'^\s*\{\{(#if\s+(?P<expr>[^}]+)|#else|/if)\}\}\s*$')
INLINE = re.compile(r'\{\{#if\s+([^}]+)\}\}(.*?)(?:\{\{#else\}\}(.*?))?\{\{/if\}\}')
PLACEHOLDER = re.compile(r'\{\{([A-Z][A-Z0-9_]*)\}\}')


def truthy(v):
    return str(v).strip().lower() in ('true', 'yes', '1', 'on')


def cond(expr, vars_):
    for part in expr.split('&'):
        part = part.strip()
        if not part:
            continue
        if '=' in part:
            k, v = part.split('=', 1)
            if str(vars_.get(k.strip(), '')).strip() not in [x.strip() for x in v.split('|')]:
                return False
        elif part.startswith('!'):
            if truthy(vars_.get(part[1:].strip(), '')):
                return False
        elif not truthy(vars_.get(part, '')):
            return False
    return True


def render_text(text, vars_):
    out, stack = [], []          # stack: [(printing_before, this_branch_taken, any_branch_taken)]
    for line in text.split('\n'):
        m = DIRECTIVE.match(line)
        if m:
            tok = m.group(1)
            if tok.startswith('#if'):
                parent = all(s[1] for s in stack)
                taken = parent and cond(m.group('expr'), vars_)
                stack.append([parent, taken, taken])
            elif tok == '#else':
                if not stack:
                    raise SystemExit('render: {{#else}} без {{#if}}')
                parent, _, any_taken = stack[-1]
                stack[-1][1] = parent and not any_taken
                stack[-1][2] = True
            else:
                if not stack:
                    raise SystemExit('render: {{/if}} без {{#if}}')
                stack.pop()
            continue
        if all(s[1] for s in stack):
            line = INLINE.sub(lambda mm: (mm.group(2) if cond(mm.group(1), vars_) else (mm.group(3) or '')), line)
            out.append(PLACEHOLDER.sub(lambda mm: str(vars_[mm.group(1)]) if mm.group(1) in vars_ else mm.group(0), line))
    if stack:
        raise SystemExit('render: незакрытый {{#if}}')
    return '\n'.join(out)


def load_profiles(path):
    rules = []
    if path and os.path.exists(path):
        for raw in open(path, encoding='utf-8'):
            s = raw.split('#', 1)[0].strip()
            if not s:
                continue
            glob, expr = s.split(None, 1)
            rules.append((glob, expr))
    return rules


def wanted(rel, rules, vars_):
    for glob, expr in rules:
        if fnmatch.fnmatchcase(rel, glob) or fnmatch.fnmatchcase(rel, glob.rstrip('/') + '/*'):
            return cond(expr, vars_)
    return True


def main(argv):
    vars_, profiles, args = {}, None, []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == '--set':
            k, v = argv[i + 1].split('=', 1); vars_[k.strip()] = v; vars_[k.strip().upper()] = v; i += 2
        elif a == '--profiles':
            profiles = argv[i + 1]; i += 2
        else:
            args.append(a); i += 1
    if len(args) == 1:
        sys.stdout.write(render_text(open(args[0], encoding='utf-8').read(), vars_)); return
    if len(args) != 2:
        raise SystemExit(__doc__)
    src, dst = args
    rules = load_profiles(profiles)
    skipped, profiled, written = [], [], []
    for root, _, files in os.walk(src):
        for name in files:
            full = os.path.join(root, name)
            rel = os.path.relpath(full, src)
            if not wanted(rel, rules, vars_):
                profiled.append(rel); continue
            out_rel = re.sub(r'^_gitignore$', '.gitignore', re.sub(r'^_claude/', '.claude/', rel))
            out = os.path.join(dst, out_rel)
            if os.path.exists(out):
                skipped.append(out_rel); continue
            os.makedirs(os.path.dirname(out), exist_ok=True)
            with open(full, 'rb') as fh:
                data = fh.read()
            try:
                text = data.decode('utf-8')
                content = render_text(text, vars_).encode('utf-8')
            except UnicodeDecodeError:
                content = data
            with open(out, 'wb') as fh:
                fh.write(content)
            if name.endswith(('.sh', '.py')) or '/hooks/' in out_rel or out_rel.endswith('/pre-commit'):
                os.chmod(out, 0o755)
            written.append(out_rel)
    print(f'создано файлов: {len(written)}')
    if profiled:
        print('не поставлено (не по профилю):'); print('\n'.join('  ' + p for p in sorted(profiled)))
    if skipped:
        print('пропущено (уже есть):'); print('\n'.join('  ' + p for p in sorted(skipped)))


if __name__ == '__main__':
    main(sys.argv[1:])
