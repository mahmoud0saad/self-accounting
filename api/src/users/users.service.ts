import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found.');
    }
    return this.toDto(user);
  }

  async updateMe(userId: string, dto: UpdateProfileDto) {
    const data: Record<string, unknown> = {};
    if (dto.fullName !== undefined) {
      data.fullName = dto.fullName.trim();
    }
    if (dto.photoUrl !== undefined) {
      data.photoUrl = dto.photoUrl;
    }
    if (dto.timezone !== undefined) {
      data.timezone = dto.timezone;
    }
    if (dto.locale !== undefined) {
      data.locale = dto.locale;
    }
    if (dto.bio !== undefined) {
      data.bio = dto.bio;
    }

    const user = await this.prisma.user.update({
      where: { id: userId },
      data,
    });
    return this.toDto(user);
  }

  private toDto(user: {
    id: string;
    email: string;
    fullName: string;
    photoUrl: string | null;
    timezone: string | null;
    locale: string | null;
    bio: string | null;
    emailConfirmedAt: Date | null;
  }) {
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
}
