import {
  assertCustomGoalCount,
  assertGoalCount,
  assertSourceKind,
  assertWeekStartDow,
} from './challenges.validation';
import { BadRequestException } from '@nestjs/common';

describe('challenges.validation', () => {
  it('rejects MANUAL source kind with MANUAL_NOT_SUPPORTED_PHASE_9', () => {
    expect(() => assertSourceKind('MANUAL')).toThrow(BadRequestException);
    try {
      assertSourceKind('MANUAL');
    } catch (e) {
      expect((e as BadRequestException).getResponse()).toMatchObject({
        code: 'MANUAL_NOT_SUPPORTED_PHASE_9',
      });
    }
  });

  it('accepts TASK_WEEKLY_COUNT and CATEGORY_WEEKLY_COUNT', () => {
    expect(() => assertSourceKind('TASK_WEEKLY_COUNT')).not.toThrow();
    expect(() => assertSourceKind('CATEGORY_WEEKLY_COUNT')).not.toThrow();
  });

  it('rejects goalCount below 1', () => {
    expect(() => assertGoalCount(0)).toThrow(BadRequestException);
    expect(() => assertGoalCount(5)).not.toThrow();
    expect(() => assertGoalCount(21)).not.toThrow();
  });

  it('accepts customGoalCount without upper bound', () => {
    expect(() => assertCustomGoalCount(0)).toThrow(BadRequestException);
    expect(() => assertCustomGoalCount(8)).not.toThrow();
    expect(() => assertCustomGoalCount(50)).not.toThrow();
  });

  it('rejects weekStart not on Sat/Sun/Mon (UTC)', () => {
    const tuesday = new Date('2026-05-19T00:00:00.000Z');
    expect(() => assertWeekStartDow(tuesday)).toThrow(BadRequestException);
    try {
      assertWeekStartDow(tuesday);
    } catch (e) {
      expect((e as BadRequestException).getResponse()).toMatchObject({
        code: 'WEEK_START_DOW_INVALID',
      });
    }
    const saturday = new Date('2026-05-16T00:00:00.000Z');
    expect(() => assertWeekStartDow(saturday)).not.toThrow();
  });
});
