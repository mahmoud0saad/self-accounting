import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import type {
  ChallengeTemplate,
  UserChallenge,
  UserChallengeWeek,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import {
  assertCuratedIcon,
  assertGoalCount,
  assertName,
  assertSourceKind,
  assertWeekEndMatches,
  assertWeekStartDow,
  assertWeekStatus,
  parseDateOnly,
} from './challenges.validation';
import type { ChallengeBatchOpDto } from './dto/challenge-batch.dto';
import type { CreateChallengeDto } from './dto/create-challenge.dto';
import type { PatchChallengeDto } from './dto/patch-challenge.dto';
import type { ChallengeSnapshotStateDto } from './dto/snapshot-state.dto';
import type { UpsertChallengeWeekDto } from './dto/upsert-challenge-week.dto';
import { isValidDefaultSourceRef } from './source-refs';

const CHALLENGE_OP_TYPES = new Set([
  'upsert_user_challenge',
  'delete_user_challenge',
  'upsert_user_challenge_week',
]);

@Injectable()
export class ChallengesService {
  constructor(private readonly prisma: PrismaService) {}

  async getTemplates(): Promise<ChallengeTemplate[]> {
    return this.prisma.challengeTemplate.findMany({
      where: { isActive: true },
      orderBy: { defaultSortOrder: 'asc' },
    });
  }

  async listUserChallenges(
    userId: string,
    includeArchived = false,
  ) {
    const challenges = await this.prisma.userChallenge.findMany({
      where: {
        userId,
        ...(includeArchived ? {} : { archivedAt: null }),
      },
      orderBy: { startedAt: 'desc' },
    });
    const weeks = await this.prisma.userChallengeWeek.findMany({
      where: { userId, userChallengeId: { in: challenges.map((c) => c.id) } },
      orderBy: { weekStart: 'desc' },
    });
    const weeksByChallenge = new Map<string, UserChallengeWeek[]>();
    for (const w of weeks) {
      const list = weeksByChallenge.get(w.userChallengeId) ?? [];
      list.push(w);
      weeksByChallenge.set(w.userChallengeId, list);
    }
    return challenges.map((c) =>
      this.mapUserChallenge(c, weeksByChallenge.get(c.id) ?? []),
    );
  }

  async getSnapshotState(userId: string): Promise<ChallengeSnapshotStateDto> {
    const [userChallenges, userChallengeWeeks, latestChallenge, latestWeek] =
      await Promise.all([
        this.prisma.userChallenge.count({ where: { userId } }),
        this.prisma.userChallengeWeek.count({ where: { userId } }),
        this.prisma.userChallenge.findFirst({
          where: { userId },
          orderBy: { updatedAt: 'desc' },
          select: { updatedAt: true },
        }),
        this.prisma.userChallengeWeek.findFirst({
          where: { userId },
          orderBy: { updatedAt: 'desc' },
          select: { updatedAt: true },
        }),
      ]);

    const totals = { userChallenges, userChallengeWeeks };
    const totalCount = userChallenges + userChallengeWeeks;
    const candidates = [
      latestChallenge?.updatedAt,
      latestWeek?.updatedAt,
    ].filter((d): d is Date => d != null);

    return {
      hasSnapshot: totalCount > 0,
      totals,
      lastUpdatedAt:
        candidates.length > 0
          ? new Date(
              Math.max(...candidates.map((d) => d.getTime())),
            ).toISOString()
          : undefined,
    };
  }

  async createChallenge(userId: string, dto: CreateChallengeDto) {
    if (dto.templateCode != null) {
      return this.subscribeToTemplate(userId, dto.templateCode);
    }
    return this.createCustomChallenge(userId, dto);
  }

  private async subscribeToTemplate(userId: string, templateCode: string) {
    const template = await this.prisma.challengeTemplate.findFirst({
      where: { code: templateCode, isActive: true },
    });
    if (!template) {
      throw new UnprocessableEntityException({
        code: 'TEMPLATE_NOT_FOUND',
        message: 'Challenge template not found.',
      });
    }

    const existing = await this.prisma.userChallenge.findFirst({
      where: { userId, templateCode, archivedAt: null },
    });
    if (existing) {
      throw new ConflictException({
        code: 'ALREADY_SUBSCRIBED',
        message: "You're already subscribed to this challenge.",
      });
    }

    const row = await this.prisma.userChallenge.create({
      data: { userId, templateCode },
    });
    return this.mapUserChallenge(row, []);
  }

  private async createCustomChallenge(
    userId: string,
    dto: CreateChallengeDto,
  ) {
    if (
      dto.customTitle == null ||
      dto.customIcon == null ||
      dto.customSourceKind == null ||
      dto.customSourceRef == null ||
      dto.customGoalCount == null
    ) {
      throw new UnprocessableEntityException({
        code: 'CUSTOM_FIELDS_REQUIRED',
        message: 'Custom challenges require all custom fields.',
      });
    }

    assertSourceKind(dto.customSourceKind);
    if (dto.customSourceKind === 'MANUAL') {
      throw new UnprocessableEntityException({
        code: 'MANUAL_NOT_SUPPORTED_PHASE_9',
        message: 'Manual challenges are not supported yet.',
      });
    }
    assertGoalCount(dto.customGoalCount);
    assertCuratedIcon(dto.customIcon);
    const title = assertName(dto.customTitle);
    await this.assertSourceRefOwned(
      userId,
      dto.customSourceKind,
      dto.customSourceRef,
    );

    const row = await this.prisma.userChallenge.create({
      data: {
        userId,
        customTitle: title,
        customIcon: dto.customIcon,
        customSourceKind: dto.customSourceKind,
        customSourceRef: dto.customSourceRef,
        customGoalCount: dto.customGoalCount,
      },
    });
    return this.mapUserChallenge(row, []);
  }

  async patchChallenge(userId: string, id: string, dto: PatchChallengeDto) {
    const existing = await this.findUserChallenge(userId, id);
    if (existing.templateCode != null) {
      if (dto.customTitle != null || dto.customIcon != null || dto.customGoalCount != null) {
        throw new UnprocessableEntityException({
          code: 'TEMPLATE_NOT_EDITABLE',
          message: 'Template challenges cannot edit custom fields.',
        });
      }
    } else {
      const data: {
        customTitle?: string;
        customIcon?: string;
        customGoalCount?: number;
      } = {};
      if (dto.customTitle != null) {
        data.customTitle = assertName(dto.customTitle);
      }
      if (dto.customIcon != null) {
        assertCuratedIcon(dto.customIcon);
        data.customIcon = dto.customIcon;
      }
      if (dto.customGoalCount != null) {
        assertGoalCount(dto.customGoalCount);
        data.customGoalCount = dto.customGoalCount;
      }
      if (Object.keys(data).length > 0) {
        await this.prisma.userChallenge.update({
          where: { id },
          data,
        });
      }
    }

    if (dto.archivedAt !== undefined) {
      const archivedAt =
        dto.archivedAt === null ? null : parseDateOnly(dto.archivedAt);
      await this.prisma.userChallenge.update({
        where: { id },
        data: { archivedAt },
      });
      if (archivedAt != null) {
        await this.prisma.userChallengeWeek.updateMany({
          where: {
            userChallengeId: id,
            userId,
            status: { in: ['IN_PROGRESS', 'COMPLETED'] },
          },
          data: { status: 'CANCELLED' },
        });
      }
    }

    const updated = await this.findUserChallenge(userId, id);
    const weeks = await this.prisma.userChallengeWeek.findMany({
      where: { userChallengeId: id },
      orderBy: { weekStart: 'desc' },
    });
    return this.mapUserChallenge(updated, weeks);
  }

  async upsertChallengeWeek(
    userId: string,
    challengeId: string,
    weekStartParam: string,
    dto: UpsertChallengeWeekDto,
  ) {
    await this.findUserChallenge(userId, challengeId);
    const weekStart = parseDateOnly(weekStartParam);
    const weekEnd = parseDateOnly(dto.weekEnd);
    assertWeekStartDow(weekStart);
    assertWeekEndMatches(weekStart, weekEnd);
    assertWeekStatus(dto.status);
    assertGoalCount(dto.goalCount);

    const existing = await this.prisma.userChallengeWeek.findUnique({
      where: {
        userChallengeId_weekStart: {
          userChallengeId: challengeId,
          weekStart,
        },
      },
    });

    if (existing != null && existing.goalCount !== dto.goalCount) {
      throw new ConflictException({
        code: 'GOAL_COUNT_LOCKED',
        message: 'goalCount cannot change for an existing week row.',
      });
    }

    if (
      existing?.celebrationSeenAt != null &&
      dto.celebrationSeenAt == null
    ) {
      throw new UnprocessableEntityException({
        code: 'CELEBRATION_SEEN_LOCKED',
        message: 'celebrationSeenAt cannot be cleared once set.',
      });
    }

    const completedAt = dto.completedAt
      ? parseDateOnly(dto.completedAt)
      : null;
    const celebrationSeenAt = dto.celebrationSeenAt
      ? parseDateOnly(dto.celebrationSeenAt)
      : null;

    const row = await this.prisma.userChallengeWeek.upsert({
      where: {
        userChallengeId_weekStart: {
          userChallengeId: challengeId,
          weekStart,
        },
      },
      create: {
        userId,
        userChallengeId: challengeId,
        weekStart,
        weekEnd,
        goalCount: dto.goalCount,
        achievedCount: dto.achievedCount,
        status: dto.status,
        completedAt,
        celebrationSeenAt,
      },
      update: {
        weekEnd,
        achievedCount: dto.achievedCount,
        status: dto.status,
        completedAt,
        celebrationSeenAt:
          celebrationSeenAt ?? existing?.celebrationSeenAt ?? null,
      },
    });

    return this.mapWeek(row);
  }

  async processBatch(userId: string, ops: ChallengeBatchOpDto[]) {
    const outcomes: Array<{
      opId: string;
      applied: boolean;
      serverUpdatedAt?: string;
      error?: string;
    }> = [];

    for (const op of ops) {
      if (!CHALLENGE_OP_TYPES.has(op.opType)) {
        outcomes.push({
          opId: op.opId,
          applied: false,
          error: 'INVALID',
        });
        continue;
      }
      const clientAt = new Date(op.clientUpdatedAt);
      try {
        const result = await this.applyBatchOp(userId, op, clientAt);
        outcomes.push({
          opId: op.opId,
          applied: result.applied,
          serverUpdatedAt: result.serverUpdatedAt,
          error: result.error,
        });
      } catch {
        outcomes.push({
          opId: op.opId,
          applied: false,
          error: 'REJECTED',
        });
      }
    }
    return { outcomes };
  }

  private isStale(existingUpdatedAt: Date, clientAt: Date): boolean {
    return existingUpdatedAt > clientAt;
  }

  private async applyBatchOp(
    userId: string,
    op: ChallengeBatchOpDto,
    clientAt: Date,
  ): Promise<{ applied: boolean; serverUpdatedAt?: string; error?: string }> {
    const p = op.payload;
    switch (op.opType) {
      case 'upsert_user_challenge': {
        const id = String(p.id);
        const existing = await this.prisma.userChallenge.findFirst({
          where: { id, userId },
        });
        if (existing) {
          if (this.isStale(existing.updatedAt, clientAt)) {
            return {
              applied: false,
              serverUpdatedAt: existing.updatedAt.toISOString(),
              error: 'STALE',
            };
          }
          const row = await this.prisma.userChallenge.update({
            where: { id },
            data: {
              archivedAt:
                p.archivedAt === null
                  ? null
                  : p.archivedAt != null
                    ? new Date(String(p.archivedAt))
                    : undefined,
              customTitle:
                p.customTitle != null ? String(p.customTitle) : undefined,
              customIcon:
                p.customIcon != null ? String(p.customIcon) : undefined,
              customGoalCount:
                p.customGoalCount != null
                  ? Number(p.customGoalCount)
                  : undefined,
            },
          });
          return { applied: true, serverUpdatedAt: row.updatedAt.toISOString() };
        }
        if (p.templateCode != null) {
          const created = await this.subscribeToTemplate(
            userId,
            String(p.templateCode),
          );
          return { applied: true, serverUpdatedAt: created.updatedAt };
        }
        const row = await this.prisma.userChallenge.create({
          data: {
            id,
            userId,
            customTitle: p.customTitle != null ? String(p.customTitle) : null,
            customIcon: p.customIcon != null ? String(p.customIcon) : null,
            customSourceKind:
              p.customSourceKind != null ? String(p.customSourceKind) : null,
            customSourceRef:
              p.customSourceRef != null ? String(p.customSourceRef) : null,
            customGoalCount:
              p.customGoalCount != null ? Number(p.customGoalCount) : null,
          },
        });
        return { applied: true, serverUpdatedAt: row.updatedAt.toISOString() };
      }
      case 'delete_user_challenge': {
        const id = String(p.id);
        const existing = await this.prisma.userChallenge.findFirst({
          where: { id, userId },
        });
        if (!existing) {
          return { applied: true };
        }
        if (this.isStale(existing.updatedAt, clientAt)) {
          return {
            applied: false,
            serverUpdatedAt: existing.updatedAt.toISOString(),
            error: 'STALE',
          };
        }
        const row = await this.prisma.userChallenge.update({
          where: { id },
          data: { archivedAt: new Date() },
        });
        return { applied: true, serverUpdatedAt: row.updatedAt.toISOString() };
      }
      case 'upsert_user_challenge_week': {
        const challengeId = String(p.userChallengeId);
        const weekStart = String(p.weekStart);
        const result = await this.upsertChallengeWeek(
          userId,
          challengeId,
          weekStart,
          {
            weekEnd: String(p.weekEnd),
            goalCount: Number(p.goalCount),
            achievedCount: Number(p.achievedCount),
            status: String(p.status),
            completedAt:
              p.completedAt != null ? String(p.completedAt) : undefined,
            celebrationSeenAt:
              p.celebrationSeenAt != null
                ? String(p.celebrationSeenAt)
                : undefined,
          },
        );
        return { applied: true, serverUpdatedAt: result.updatedAt };
      }
      default:
        return { applied: false, error: 'INVALID' };
    }
  }

  private async assertSourceRefOwned(
    userId: string,
    sourceKind: string,
    sourceRef: string,
  ): Promise<void> {
    if (isValidDefaultSourceRef(sourceKind, sourceRef)) {
      return;
    }
    if (sourceKind === 'TASK_WEEKLY_COUNT') {
      const owned = await this.prisma.userTask.findFirst({
        where: { id: sourceRef, userId, archivedAt: null },
      });
      if (owned) {
        return;
      }
    }
    if (sourceKind === 'CATEGORY_WEEKLY_COUNT') {
      const owned = await this.prisma.userCategory.findFirst({
        where: { id: sourceRef, userId, archivedAt: null },
      });
      if (owned) {
        return;
      }
    }
    throw new UnprocessableEntityException({
      code: 'INVALID_SOURCE_REF',
      message: 'Source reference is not valid for this user.',
    });
  }

  private async findUserChallenge(
    userId: string,
    id: string,
  ): Promise<UserChallenge> {
    const row = await this.prisma.userChallenge.findFirst({
      where: { id, userId },
    });
    if (!row) {
      throw new NotFoundException('Challenge not found');
    }
    return row;
  }

  private mapUserChallenge(
    c: UserChallenge,
    weeks: UserChallengeWeek[],
  ) {
    const mappedWeeks = weeks.map((w) => this.mapWeek(w));
    return {
      id: c.id,
      templateCode: c.templateCode ?? undefined,
      customTitle: c.customTitle ?? undefined,
      customIcon: c.customIcon ?? undefined,
      customSourceKind: c.customSourceKind ?? undefined,
      customSourceRef: c.customSourceRef ?? undefined,
      customGoalCount: c.customGoalCount ?? undefined,
      startedAt: c.startedAt.toISOString(),
      archivedAt: c.archivedAt?.toISOString(),
      updatedAt: c.updatedAt.toISOString(),
      currentWeek: mappedWeeks[0],
      weeks: mappedWeeks,
    };
  }

  private mapWeek(w: UserChallengeWeek) {
    return {
      id: w.id,
      weekStart: w.weekStart.toISOString().slice(0, 10),
      weekEnd: w.weekEnd.toISOString().slice(0, 10),
      goalCount: w.goalCount,
      achievedCount: w.achievedCount,
      status: w.status,
      completedAt: w.completedAt?.toISOString(),
      celebrationSeenAt: w.celebrationSeenAt?.toISOString(),
      updatedAt: w.updatedAt.toISOString(),
    };
  }
}
