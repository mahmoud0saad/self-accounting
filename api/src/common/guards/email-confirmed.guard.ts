import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { SKIP_EMAIL_CONFIRMED_KEY } from '../decorators/skip-email-confirmed.decorator';
import type { RequestUser } from '../types/jwt-payload';

@Injectable()
export class EmailConfirmedGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const skip = this.reflector.getAllAndOverride<boolean>(
      SKIP_EMAIL_CONFIRMED_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (skip) {
      return true;
    }

    const request = context.switchToHttp().getRequest<{ user?: RequestUser }>();
    const user = request.user;
    if (!user) {
      return true;
    }

    if (!user.emailConfirmedAt) {
      throw new ForbiddenException({
        code: 'EMAIL_NOT_CONFIRMED',
        message: 'Please confirm your email before using this feature.',
      });
    }

    return true;
  }
}
