"""Read archived observer logs only. No game control, process attachment, or fabricated samples."""
import argparse
import collections
import html
import json
import math
from pathlib import Path

RUN = 'THD-BOT-KV-OBSERVE-20261010-R1'


def records(path, console=False):
    for number, line in enumerate(path.read_text(encoding='utf-8-sig', errors='replace').splitlines(), 1):
        if console:
            prefix = '[THDNativeKV] '
            if prefix not in line:
                continue
            line = line.split(prefix, 1)[1]
        if not line.lstrip().startswith('{'):
            continue
        try:
            record = json.loads(line)
        except json.JSONDecodeError:
            continue
        if record.get('run') == RUN:
            record['_line'] = number
            yield record


def finite(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value)


def same_number(a, b):
    if not finite(a) or not finite(b):
        return None
    return abs(a - b) < 0.00001


def bounds(values):
    values = [x for x in values if finite(x)]
    return [min(values), max(values)] if values else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', type=Path, required=True)
    parser.add_argument('--kv-log', type=Path, required=True)
    parser.add_argument('--expected', type=Path, default=Path(__file__).with_name('expected-kv.json'))
    parser.add_argument('--snapshot', help='Exact kv_begin/kv_end snapshot ID; required if there are multiple complete snapshots')
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    expected_doc = json.loads(args.expected.read_text(encoding='utf-8'))
    expected = {r['slot']: r for r in expected_doc['heroes']}
    native = list(records(args.native))
    pids = {r.get('pid') for r in native if r.get('pid') is not None}
    if len(pids) != 1:
        raise SystemExit('Provide exactly one native process log; do not combine matches/processes')
    manifests = {r.get('expected_source_sha256') for r in native if r.get('expected_source_sha256')}
    if manifests and manifests != {expected_doc['source_sha256']}:
        raise SystemExit('Expected source manifest differs from compiled observer; use the matching expected-kv.json')
    kv = list(records(args.kv_log, console=True))
    begun = {r.get('snapshot') for r in kv if r.get('event') == 'kv_begin'}
    ended = {r.get('snapshot') for r in kv if r.get('event') == 'kv_end'}
    complete = begun & ended
    if args.snapshot:
        if args.snapshot not in complete:
            raise SystemExit('Requested snapshot is missing its begin/end boundary')
        selected = args.snapshot
    elif len(complete) == 1:
        selected = next(iter(complete))
    else:
        raise SystemExit('Choose one complete --snapshot from: ' + ', '.join(sorted(str(x) for x in complete)))
    kv_rows = {}
    for r in kv:
        if r.get('event') == 'kv_record' and r.get('snapshot') == selected:
            if r['slot'] in kv_rows:
                raise SystemExit('Duplicate slot in selected snapshot; do not concatenate sessions')
            kv_rows[r['slot']] = r
    ends = [r for r in kv if r.get('event') == 'kv_end' and r.get('snapshot') == selected]
    if len(ends) != 1 or ends[0].get('slot_count') != len(kv_rows):
        raise SystemExit('Selected KV snapshot is incomplete or duplicated; preserve the complete console output')
    groups = collections.defaultdict(list)
    for r in native:
        if r.get('event') == 'getter_sample':
            groups[(r.get('level_epoch'), r.get('owner_handle'), r.get('unit_kv_name'), r.get('hero_class'), r.get('getter_rva'))].append(r)
    result_rows = []
    for key, samples in sorted(groups.items(), key=lambda item: str(item[0])):
        epoch, handle, slot, hero_class, getter = key
        reference = expected.get(slot)
        snapshot = kv_rows.get(slot, {})
        engine = snapshot.get('engine_unit_kv', {})
        addon = snapshot.get('addon_source', {})
        base_match = all(same_number(r.get('base_after_call'), reference['base']) is True for r in samples) if reference else None
        mask_match = all(r.get('native_hero_type_mask') == reference['mask'] for r in samples) if reference else None
        engine_match = same_number(engine.get('aggression_declared'), reference['base']) if reference else None
        engine_mask_match = engine.get('recognized_mask') == reference['mask'] if reference and engine.get('bot_present') else None
        result_rows.append({
            'slot': slot, 'level_epoch': epoch, 'owner_handle': handle, 'hero_class': hero_class,
            'getter_rva': getter, 'sample_count': len(samples),
            'consumers': dict(collections.Counter(r.get('consumer') for r in samples)),
            'base_range': bounds(r.get('base_after_call') for r in samples),
            'effective_range': bounds(r.get('effective') for r in samples),
            'ratio_range': bounds(r.get('effective_over_base') for r in samples),
            'original_effective_range': bounds(r.get('original_effective', r.get('effective')) for r in samples),
            'policy_wanted_range': bounds(r.get('policy_wanted') for r in samples),
            'policy_modes': sorted({r.get('policy_mode', 0) for r in samples}),
            'policy_states': sorted({r['policy_state'] for r in samples if 'policy_state' in r}),
            'policy_custom_multiplier_range': bounds(r.get('policy_custom_multiplier') for r in samples),
            'policy_applied_samples': sum(r.get('policy_applied') is True for r in samples),
            'policy_reasons': dict(collections.Counter(r.get('policy_reason', 'legacy_observer') for r in samples)),
            'expected_base': reference['base'] if reference else None,
            'expected_mask': reference['mask'] if reference else None,
            'addon_source': addon, 'engine_unit_kv': engine,
            'base_matches_source': base_match, 'mask_matches_source': mask_match,
            'engine_declared_base_matches_source': engine_match, 'engine_mask_matches_source': engine_mask_match,
            'native_source_lines': [samples[0]['_line'], samples[-1]['_line']],
            'kv_source_line': snapshot.get('_line'),
        })
    observed = {r['slot'] for r in result_rows}
    report = {
        'run': RUN, 'pid': next(iter(pids)), 'selected_kv_snapshot': selected,
        'source_sha256': expected_doc['source_sha256'],
        'native_installed_records': sum(r.get('event') == 'installed' for r in native),
        'fault_records': [r for r in native if r.get('event') in ('load_failed', 'observer_fault_pass_through')
                          or r.get('policy_fault_latched') is True or r.get('policy_reason') == 'context_read_fault'],
        'coverage': {'expected_slots': len(expected), 'observed_expected_slots': len(observed & set(expected)),
                     'unobserved_slots': sorted(set(expected) - observed)},
        'status': 'OBSERVATIONS_PRESENT' if result_rows else 'NO_GETTER_SAMPLES',
        'limits': [
            'KV joined by unit name, not same-frame instance proof; user must confirm both files belong to the same server session.',
            'Missing explicit KV AggressionFactor remains unknown; the tool does not fabricate a default/native field value.',
            'Only naturally invoked and sampled getters are observed; no sample is not evidence of no Bot object or no behavior.',
            'Effective/base ratios describe observed getter output; they do not identify modifier causes or prove behavior improvement.',
        ],
        'rows': result_rows,
    }
    args.out.mkdir(parents=True, exist_ok=True)
    (args.out / 'summary.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
    escape = lambda value: html.escape(str(value))
    body = '<!doctype html><meta charset="utf-8"><title>Bot KV getter observations</title><style>body{font:15px/1.7 system-ui;margin:30px}table{border-collapse:collapse}td,th{border:1px solid #ccd;padding:10px;text-align:left}</style>'
    body += '<h1>Bot 配置与 getter 观测</h1><p>' + escape(report['status']) + ' · PID ' + str(report['pid']) + '</p>'
    body += '<p>KV按名称对照，不证明同帧；请确认两份文件来自同一服务端会话。未采样项不能算失败或通过。</p>'
    body += '<table><tr><th>槽位 / 句柄</th><th>来源 / 数量</th><th>配置期望</th><th>Addon源声明</th><th>引擎KV声明</th><th>对象基础值</th><th>原始getter / 最终返回</th><th>动态模式 / 候选值 / 应用样本数</th><th>实际/基础</th><th>基础 / 角色匹配</th></tr>'
    for row in result_rows:
        values = [str(row['slot']) + ' / ' + str(row['owner_handle']), str(row['consumers']) + ' / ' + str(row['sample_count']),
                  row['expected_base'], row['addon_source'].get('aggression_raw'), row['engine_unit_kv'].get('aggression_raw'),
                  row['base_range'], str(row['original_effective_range']) + ' / ' + str(row['effective_range']),
                  str(row['policy_modes']) + ' / ' + str(row['policy_wanted_range']) + ' / ' + str(row['policy_applied_samples']), row['ratio_range'],
                  str(row['base_matches_source']) + ' / ' + str(row['mask_matches_source'])]
        body += '<tr>' + ''.join('<td>' + escape(value) + '</td>' for value in values) + '</tr>'
    body += '</table><p>详细KV声明、缺失覆盖及日志行号见summary.json。此报告不判定实机行为成功。</p>'
    (args.out / 'report.html').write_text(body, encoding='utf-8')
    print('Wrote', len(result_rows), 'observed actor/getter groups; no game actions performed')


if __name__ == '__main__':
    main()
