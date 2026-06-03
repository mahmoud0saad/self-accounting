import { BadRequestException } from '@nestjs/common';
import { assertCuratedIcon, assertName } from '../customization/customization.validation';

const VALID_SOURCE_KINDS = new Set([
  'TASK_WEEKLY_COUNT',
  'CATEGORY_WEEKLY_COUNT',
]);

const VALID_WEEK_STATUSES = new Set([
  'IN_PROGRESS',
  'COMPLETED',
  'MISSED',
  'CANCELLED',
]);

/** Saturday=6, Sunday=0, Monday=1 (JS Date.getDay()). */
const VALID_WEEK_START_DAYS = new Set([0, 1, 6]);

export function assertSourceKind(kind: string): void {
  if (kind === 'MANUAL') {
    throw new BadRequestException({
      code: 'MANUAL_NOT_SUPPORTED_PHASE_9',
      message: 'Manual challenges are not supported yet.',
    });
  }
  if (!VALID_SOURCE_KINDS.has(kind)) {
    throw new BadRequestException({
      code: 'INVALID_SOURCE_KIND',
      message: 'sourceKind must be TASK_WEEKLY_COUNT or CATEGORY_WEEKLY_COUNT.',
    });
  }
}

export function assertCustomGoalCount(count: number): void {
  if (!Number.isInteger(count) || count < 1) {
    throw new BadRequestException({
      code: 'GOAL_COUNT_OUT_OF_RANGE',
      message: 'customGoalCount must be an integer >= 1.',
    });
  }
}

/** Week snapshot goalCount (synced from client); no upper bound. */
export function assertGoalCount(count: number): void {
  if (!Number.isInteger(count) || count < 1) {
    throw new BadRequestException({
      code: 'GOAL_COUNT_OUT_OF_RANGE',
      message: 'goalCount must be an integer >= 1.',
    });
  }
}

export function assertWeekStatus(status: string): void {
  if (!VALID_WEEK_STATUSES.has(status)) {
    throw new BadRequestException({
      code: 'INVALID_WEEK_STATUS',
      message: 'Invalid week status.',
    });
  }
}

export function assertWeekStartDow(weekStart: Date): void {
  const dow = weekStart.getUTCDay();
  if (!VALID_WEEK_START_DAYS.has(dow)) {
    throw new BadRequestException({
      code: 'WEEK_START_DOW_INVALID',
      message: 'weekStart must fall on Saturday, Sunday, or Monday.',
    });
  }
}

export function assertWeekEndMatches(weekStart: Date, weekEnd: Date): void {
  const expected = new Date(weekStart);
  expected.setUTCDate(expected.getUTCDate() + 6);
  if (weekEnd.toISOString().slice(0, 10) !== expected.toISOString().slice(0, 10)) {
    throw new BadRequestException({
      code: 'WEEK_END_MISMATCH',
      message: 'weekEnd must be exactly 6 days after weekStart.',
    });
  }
}

export function parseDateOnly(iso: string): Date {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) {
    throw new BadRequestException({
      code: 'INVALID_DATE',
      message: 'Invalid date.',
    });
  }
  return d;
}

export { assertCuratedIcon, assertName };
