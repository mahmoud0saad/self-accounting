import { SetMetadata } from '@nestjs/common';

export const SKIP_EMAIL_CONFIRMED_KEY = 'skipEmailConfirmed';
export const SkipEmailConfirmed = () =>
  SetMetadata(SKIP_EMAIL_CONFIRMED_KEY, true);
