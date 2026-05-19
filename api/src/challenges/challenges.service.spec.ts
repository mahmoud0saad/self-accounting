import { Test, TestingModule } from '@nestjs/testing';
import { ChallengesService } from './challenges.service';
import { PrismaService } from '../prisma/prisma.service';
import { challengeTemplatesSeed } from './seed-templates';

describe('ChallengesService', () => {
  let service: ChallengesService;
  const prisma = {
    challengeTemplate: {
      findMany: jest.fn(),
    },
    userChallenge: {
      count: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
    },
    userChallengeWeek: {
      count: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChallengesService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = module.get(ChallengesService);
    jest.clearAllMocks();
  });

  it('getTemplates returns active templates ordered', async () => {
    prisma.challengeTemplate.findMany.mockResolvedValue(challengeTemplatesSeed);
    const rows = await service.getTemplates();
    expect(prisma.challengeTemplate.findMany).toHaveBeenCalledWith({
      where: { isActive: true },
      orderBy: { defaultSortOrder: 'asc' },
    });
    expect(rows).toHaveLength(6);
  });

  it('getSnapshotState returns hasSnapshot false when empty', async () => {
    prisma.userChallenge.count.mockResolvedValue(0);
    prisma.userChallengeWeek.count.mockResolvedValue(0);
    prisma.userChallenge.findFirst.mockResolvedValue(null);
    prisma.userChallengeWeek.findFirst.mockResolvedValue(null);

    const state = await service.getSnapshotState('user-1');
    expect(state.hasSnapshot).toBe(false);
    expect(state.totals).toEqual({
      userChallenges: 0,
      userChallengeWeeks: 0,
    });
    expect(state.lastUpdatedAt).toBeUndefined();
  });

  it('getSnapshotState returns hasSnapshot true when any row exists', async () => {
    prisma.userChallenge.count.mockResolvedValue(1);
    prisma.userChallengeWeek.count.mockResolvedValue(0);
    prisma.userChallenge.findFirst.mockResolvedValue({
      updatedAt: new Date('2026-05-19T10:00:00Z'),
    });
    prisma.userChallengeWeek.findFirst.mockResolvedValue(null);

    const state = await service.getSnapshotState('user-1');
    expect(state.hasSnapshot).toBe(true);
    expect(state.lastUpdatedAt).toBe('2026-05-19T10:00:00.000Z');
  });

  it('listUserChallenges excludes archived by default', async () => {
    prisma.userChallenge.findMany.mockResolvedValue([]);
    prisma.userChallengeWeek.findMany.mockResolvedValue([]);
    await service.listUserChallenges('user-1');
    expect(prisma.userChallenge.findMany).toHaveBeenCalledWith({
      where: { userId: 'user-1', archivedAt: null },
      orderBy: { startedAt: 'desc' },
    });
  });
});
