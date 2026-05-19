import { Test, TestingModule } from '@nestjs/testing';
import {
  ConflictException,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ChallengesService } from './challenges.service';
import { PrismaService } from '../prisma/prisma.service';

describe('ChallengesService writes', () => {
  let service: ChallengesService;
  const prisma = {
    challengeTemplate: { findFirst: jest.fn() },
    userChallenge: {
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      count: jest.fn(),
    },
    userChallengeWeek: {
      findUnique: jest.fn(),
      upsert: jest.fn(),
      updateMany: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      findFirst: jest.fn(),
    },
    userTask: { findFirst: jest.fn() },
    userCategory: { findFirst: jest.fn() },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChallengesService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = module.get(ChallengesService);
  });

  it('POST custom with MANUAL returns MANUAL_NOT_SUPPORTED_PHASE_9', async () => {
    await expect(
      service.createChallenge('user-1', {
        customTitle: 'X',
        customIcon: 'star',
        customSourceKind: 'MANUAL',
        customSourceRef: 'x',
        customGoalCount: 7,
      }),
    ).rejects.toMatchObject({
      response: { code: 'MANUAL_NOT_SUPPORTED_PHASE_9' },
    });
  });

  it('subscribe twice to same template returns ALREADY_SUBSCRIBED', async () => {
    prisma.challengeTemplate.findFirst.mockResolvedValue({
      code: 'fajr_in_jamaah',
      isActive: true,
    });
    prisma.userChallenge.findFirst.mockResolvedValue({ id: 'existing' });

    await expect(
      service.createChallenge('user-1', { templateCode: 'fajr_in_jamaah' }),
    ).rejects.toBeInstanceOf(ConflictException);

    try {
      await service.createChallenge('user-1', {
        templateCode: 'fajr_in_jamaah',
      });
    } catch (e) {
      expect((e as ConflictException).getResponse()).toMatchObject({
        code: 'ALREADY_SUBSCRIBED',
      });
    }
  });

  it('custom with invalid default sourceRef returns INVALID_SOURCE_REF', async () => {
    prisma.userTask.findFirst.mockResolvedValue(null);
    prisma.userCategory.findFirst.mockResolvedValue(null);

    await expect(
      service.createChallenge('user-1', {
        customTitle: 'My challenge',
        customIcon: 'star',
        customSourceKind: 'TASK_WEEKLY_COUNT',
        customSourceRef: 'nonexistent_task',
        customGoalCount: 7,
      }),
    ).rejects.toMatchObject({
      response: { code: 'INVALID_SOURCE_REF' },
    });
  });

  it('upsert week with mismatched goalCount returns GOAL_COUNT_LOCKED', async () => {
    prisma.userChallenge.findFirst.mockResolvedValue({
      id: 'ch-1',
      userId: 'user-1',
    });
    prisma.userChallengeWeek.findUnique.mockResolvedValue({
      goalCount: 7,
      celebrationSeenAt: null,
    });

    await expect(
      service.upsertChallengeWeek('user-1', 'ch-1', '2026-05-16', {
        weekEnd: '2026-05-22',
        goalCount: 5,
        achievedCount: 3,
        status: 'IN_PROGRESS',
      }),
    ).rejects.toBeInstanceOf(ConflictException);

    try {
      await service.upsertChallengeWeek('user-1', 'ch-1', '2026-05-16', {
        weekEnd: '2026-05-22',
        goalCount: 5,
        achievedCount: 3,
        status: 'IN_PROGRESS',
      });
    } catch (e) {
      expect((e as ConflictException).getResponse()).toMatchObject({
        code: 'GOAL_COUNT_LOCKED',
      });
    }
  });

  it('patch customSourceKind returns SOURCE_NOT_EDITABLE', async () => {
    prisma.userChallenge.findFirst.mockResolvedValue({
      id: 'ch-1',
      userId: 'user-1',
      templateCode: null,
    });

    await expect(
      service.patchChallenge('user-1', 'ch-1', {
        customSourceKind: 'TASK_WEEKLY_COUNT',
      }),
    ).rejects.toMatchObject({
      response: { code: 'SOURCE_NOT_EDITABLE' },
    });
  });

  it('patch missing challenge returns 404', async () => {
    prisma.userChallenge.findFirst.mockResolvedValue(null);
    await expect(
      service.patchChallenge('user-1', 'missing', { archivedAt: null }),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('getSnapshot hasSnapshot true when only archived challenges exist', async () => {
    prisma.userChallenge.count.mockResolvedValue(1);
    prisma.userChallengeWeek.count.mockResolvedValue(0);
    prisma.userChallenge.findFirst.mockResolvedValue({
      updatedAt: new Date('2026-05-19T10:00:00Z'),
    });
    prisma.userChallengeWeek.findFirst.mockResolvedValue(null);

    const state = await service.getSnapshotState('user-1');
    expect(state.hasSnapshot).toBe(true);
    expect(state.totals.userChallenges).toBe(1);
  });
});
