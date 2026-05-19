import {
  DEFAULT_CATEGORY_CODES,
  DEFAULT_TASK_IDS,
  isValidDefaultSourceRef,
} from './source-refs';
import { challengeTemplatesSeed } from './seed-templates';

describe('challenge template seed', () => {
  it('defines exactly six templates', () => {
    expect(challengeTemplatesSeed).toHaveLength(6);
    const codes = challengeTemplatesSeed.map((t) => t.code);
    expect(new Set(codes).size).toBe(6);
  });

  it('every template sourceRef is in the static catalog', () => {
    for (const t of challengeTemplatesSeed) {
      expect(isValidDefaultSourceRef(t.sourceKind, t.sourceRef)).toBe(true);
      if (t.sourceKind === 'TASK_WEEKLY_COUNT') {
        expect(DEFAULT_TASK_IDS.has(t.sourceRef)).toBe(true);
      } else {
        expect(DEFAULT_CATEGORY_CODES.has(t.sourceRef)).toBe(true);
      }
    }
  });
});
