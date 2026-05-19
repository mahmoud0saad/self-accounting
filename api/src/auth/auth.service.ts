import {
  ConflictException,
  ForbiddenException,
  GoneException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { createHash, randomBytes, randomInt } from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { PrismaService } from '../prisma/prisma.service';
import { MailService } from '../mail/mail.service';
import type { JwtPayload } from '../common/types/jwt-payload';
import type {
  ConfirmEmailCodeDto,
  LoginDto,
  RefreshDto,
  RegisterDto,
} from './dto/register.dto';

const BCRYPT_ROUNDS = 12;
const CONFIRMATION_CODE_TTL_MS = 15 * 60 * 1000;
const CONFIRMATION_CODE_EXPIRES_MINUTES = 15;

export type AuthUserDto = {
  id: string;
  email: string;
  fullName: string;
  photoUrl: string | null;
  timezone: string | null;
  locale: string | null;
  bio: string | null;
  emailConfirmedAt: string | null;
};

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly mail: MailService,
  ) {}

  async register(dto: RegisterDto): Promise<{ message: string }> {
    const email = dto.email.trim().toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new ConflictException(
        'An account with this email already exists. Try signing in.',
      );
    }

    const passwordHash = await bcrypt.hash(dto.password, BCRYPT_ROUNDS);
    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        fullName: dto.fullName.trim(),
        provider: 'local',
      },
    });

    await this.issueConfirmationCode(user.id, email);
    return {
      message:
        'Account created. Enter the 6-digit code we sent to your email.',
    };
  }

  async login(dto: LoginDto) {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new UnauthorizedException(
        "That email and password don't match. Try again.",
      );
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException(
        "That email and password don't match. Try again.",
      );
    }

    if (!user.emailConfirmedAt) {
      throw new ForbiddenException({
        code: 'EMAIL_NOT_CONFIRMED',
        email: user.email,
      });
    }

    return this.issueTokens(user);
  }

  async refresh(dto: RefreshDto) {
    const hash = this.hashToken(dto.refreshToken);
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: hash },
      include: { user: true },
    });

    if (!stored || stored.revokedAt) {
      throw new UnauthorizedException('Session expired. Please sign in again.');
    }
    if (stored.expiresAt < new Date()) {
      throw new UnauthorizedException('Session expired. Please sign in again.');
    }

    await this.prisma.refreshToken.update({
      where: { id: stored.id },
      data: { revokedAt: new Date() },
    });

    return this.issueTokens(stored.user, stored.family);
  }

  async logout(refreshToken: string): Promise<void> {
    const hash = this.hashToken(refreshToken);
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash: hash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  async confirmEmailWithCode(
    dto: ConfirmEmailCodeDto,
  ): Promise<{ message: string; already: boolean }> {
    const email = dto.email.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new UnauthorizedException(
        'That code does not match. Check the email and try again.',
      );
    }

    if (user.emailConfirmedAt) {
      return {
        message: 'Your email is already confirmed. You can sign in.',
        already: true,
      };
    }

    const row = await this.prisma.emailConfirmationToken.findFirst({
      where: {
        userId: user.id,
        consumedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'desc' },
      include: { user: true },
    });

    if (!row) {
      throw new GoneException(
        'This code has expired. Tap resend to get a new one.',
      );
    }

    const ok = await bcrypt.compare(dto.code, row.codeHash);
    if (!ok) {
      throw new UnauthorizedException(
        'That code does not match. Check the email and try again.',
      );
    }

    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: user.id },
        data: { emailConfirmedAt: new Date() },
      }),
      this.prisma.emailConfirmationToken.update({
        where: { id: row.id },
        data: { consumedAt: new Date() },
      }),
    ]);

    await this.mail.sendWelcome(user.email, user.fullName);
    return {
      message: 'Email confirmed. You can sign in now.',
      already: false,
    };
  }

  async resendConfirmation(emailRaw: string): Promise<{ message: string }> {
    const email = emailRaw.trim().toLowerCase();
    const user = await this.prisma.user.findUnique({ where: { email } });
    if (!user) {
      return {
        message:
          'If an account exists for this email, a confirmation message was sent.',
      };
    }
    if (user.emailConfirmedAt) {
      return { message: 'This email is already confirmed.' };
    }

    await this.issueConfirmationCode(user.id, email);
    return {
      message:
        'If an account exists for this email, a new confirmation code was sent.',
    };
  }

  private async issueConfirmationCode(
    userId: string,
    email: string,
  ): Promise<void> {
    const code = randomInt(0, 1_000_000).toString().padStart(6, '0');
    const codeHash = await bcrypt.hash(code, BCRYPT_ROUNDS);
    const expiresAt = new Date(Date.now() + CONFIRMATION_CODE_TTL_MS);

    await this.prisma.emailConfirmationToken.updateMany({
      where: { userId, consumedAt: null },
      data: { consumedAt: new Date() },
    });

    await this.prisma.emailConfirmationToken.create({
      data: { userId, codeHash, expiresAt },
    });

    await this.mail.sendConfirmEmail(
      email,
      code,
      CONFIRMATION_CODE_EXPIRES_MINUTES,
    );
  }

  private async issueTokens(
    user: {
      id: string;
      email: string;
      fullName: string;
      photoUrl: string | null;
      timezone: string | null;
      locale: string | null;
      bio: string | null;
      emailConfirmedAt: Date | null;
    },
    family?: string,
  ) {
    const payload: JwtPayload = {
      sub: user.id,
      email: user.email,
      emailConfirmedAt: user.emailConfirmedAt?.toISOString() ?? null,
    };

    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.getOrThrow<string>('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get<string>(
        'JWT_ACCESS_TTL',
        '15m',
      ) as `${number}${'s' | 'm' | 'h' | 'd'}`,
    });

    const refreshToken = randomBytes(48).toString('base64url');
    const refreshTtl = this.config.get<string>('JWT_REFRESH_TTL', '30d');
    const expiresAt = this.addTtl(refreshTtl);

    await this.prisma.refreshToken.create({
      data: {
        userId: user.id,
        tokenHash: this.hashToken(refreshToken),
        family: family ?? uuidv4(),
        expiresAt,
      },
    });

    return {
      accessToken,
      refreshToken,
      user: this.toUserDto(user),
    };
  }

  private toUserDto(user: {
    id: string;
    email: string;
    fullName: string;
    photoUrl: string | null;
    timezone: string | null;
    locale: string | null;
    bio: string | null;
    emailConfirmedAt: Date | null;
  }): AuthUserDto {
    return {
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      photoUrl: user.photoUrl,
      timezone: user.timezone,
      locale: user.locale,
      bio: user.bio,
      emailConfirmedAt: user.emailConfirmedAt?.toISOString() ?? null,
    };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private addTtl(ttl: string): Date {
    const match = /^(\d+)([smhd])$/.exec(ttl);
    if (!match) {
      return new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
    }
    const amount = Number.parseInt(match[1], 10);
    const unit = match[2];
    const ms =
      unit === 's'
        ? amount * 1000
        : unit === 'm'
          ? amount * 60 * 1000
          : unit === 'h'
            ? amount * 60 * 60 * 1000
            : amount * 24 * 60 * 60 * 1000;
    return new Date(Date.now() + ms);
  }
}
