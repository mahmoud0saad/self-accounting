import { ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcrypt';
import { AuthService } from './auth.service';
import { MailService } from '../mail/mail.service';
import { PrismaService } from '../prisma/prisma.service';

describe('AuthService', () => {
  let service: AuthService;
  const prisma = {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    emailConfirmationToken: { create: jest.fn() },
    refreshToken: {
      findUnique: jest.fn(),
      update: jest.fn(),
      create: jest.fn(),
    },
  };
  const mail = { sendConfirmEmail: jest.fn(), sendWelcome: jest.fn() };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        {
          provide: JwtService,
          useValue: { signAsync: jest.fn().mockResolvedValue('access') },
        },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn((key: string, def?: string) => def),
            getOrThrow: jest.fn((key: string) => {
              if (key === 'JWT_ACCESS_SECRET') return 'test-access-secret';
              if (key === 'APP_PUBLIC_URL') return 'http://localhost:3000';
              return 'x';
            }),
          },
        },
        { provide: MailService, useValue: mail },
      ],
    }).compile();

    service = module.get(AuthService);
  });

  it('login rejects unknown email', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    await expect(
      service.login({ email: 'a@b.com', password: 'password1' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('login rejects wrong password', async () => {
    const hash = await bcrypt.hash('correct', 12);
    prisma.user.findUnique.mockResolvedValue({
      id: 'u1',
      email: 'a@b.com',
      passwordHash: hash,
      emailConfirmedAt: new Date(),
      fullName: 'Test',
      photoUrl: null,
      timezone: null,
      locale: null,
      bio: null,
    });
    await expect(
      service.login({ email: 'a@b.com', password: 'wrongpass' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('login returns 403 when email not confirmed', async () => {
    const hash = await bcrypt.hash('password1', 12);
    prisma.user.findUnique.mockResolvedValue({
      id: 'u1',
      email: 'a@b.com',
      passwordHash: hash,
      emailConfirmedAt: null,
      fullName: 'Test',
      photoUrl: null,
      timezone: null,
      locale: null,
      bio: null,
    });
    await expect(
      service.login({ email: 'a@b.com', password: 'password1' }),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('refresh rejects revoked token', async () => {
    prisma.refreshToken.findUnique.mockResolvedValue({
      id: 'rt1',
      revokedAt: new Date(),
      expiresAt: new Date(Date.now() + 60_000),
      family: 'fam',
      user: {
        id: 'u1',
        email: 'a@b.com',
        fullName: 'T',
        photoUrl: null,
        timezone: null,
        locale: null,
        bio: null,
        emailConfirmedAt: new Date(),
      },
    });
    await expect(
      service.refresh({ refreshToken: 'any-token-value-here' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
