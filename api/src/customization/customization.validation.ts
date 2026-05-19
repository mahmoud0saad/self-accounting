import { BadRequestException } from '@nestjs/common';
import { isCuratedIcon } from '../tasks/icons.constants';

const MIN_POINTS = 1;
const MAX_POINTS = 20;

export function assertPointsInRange(points: number): void {
  if (!Number.isInteger(points) || points < MIN_POINTS || points > MAX_POINTS) {
    throw new BadRequestException({
      code: 'POINTS_OUT_OF_RANGE',
      message: `Points must be an integer between ${MIN_POINTS} and ${MAX_POINTS}.`,
    });
  }
}

export function assertCuratedIcon(icon: string): void {
  if (!isCuratedIcon(icon)) {
    throw new BadRequestException({
      code: 'ICON_NOT_ALLOWED',
      message: 'Icon is not in the curated set.',
    });
  }
}

export function assertName(name: string): string {
  const trimmed = name.trim();
  if (trimmed.length < 2 || trimmed.length > 60) {
    throw new BadRequestException('Name must be 2–60 characters.');
  }
  return trimmed;
}

export function assertCategoryRef(ref: string): void {
  if (!ref.startsWith('category:') && !ref.startsWith('userCategory:')) {
    throw new BadRequestException('Invalid categoryRef.');
  }
}
