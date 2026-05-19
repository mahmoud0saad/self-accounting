import { CatalogService } from './catalog.service';
import type { PrismaService } from '../prisma/prisma.service';

describe('CatalogService.getSnapshotState', () => {
  const makePrisma = (counts: {
    userCategories: number;
    userTasks: number;
    categoryOverrides: number;
    taskOverrides: number;
    latest?: Date;
  }) =>
    ({
      userCategory: {
        count: jest.fn().mockResolvedValue(counts.userCategories),
        findFirst: jest.fn().mockResolvedValue(
          counts.latest ? { updatedAt: counts.latest } : null,
        ),
      },
      userTask: {
        count: jest.fn().mockResolvedValue(counts.userTasks),
        findFirst: jest.fn().mockResolvedValue(null),
      },
      userCategoryOverride: {
        count: jest.fn().mockResolvedValue(counts.categoryOverrides),
        findFirst: jest.fn().mockResolvedValue(null),
      },
      userTaskOverride: {
        count: jest.fn().mockResolvedValue(counts.taskOverrides),
        findFirst: jest.fn().mockResolvedValue(null),
      },
    }) as unknown as PrismaService;

  it('returns hasSnapshot false when all counts are zero', async () => {
    const service = new CatalogService(makePrisma({
      userCategories: 0,
      userTasks: 0,
      categoryOverrides: 0,
      taskOverrides: 0,
    }));
    const state = await service.getSnapshotState('user-1');
    expect(state.hasSnapshot).toBe(false);
    expect(state.totals).toEqual({
      userCategories: 0,
      userTasks: 0,
      categoryOverrides: 0,
      taskOverrides: 0,
    });
    expect(state.lastUpdatedAt).toBeUndefined();
  });

  it('returns hasSnapshot true when any customization row exists', async () => {
    const service = new CatalogService(makePrisma({
      userCategories: 0,
      userTasks: 0,
      categoryOverrides: 1,
      taskOverrides: 0,
      latest: new Date('2026-05-19T10:00:00.000Z'),
    }));
    const state = await service.getSnapshotState('user-1');
    expect(state.hasSnapshot).toBe(true);
    expect(state.lastUpdatedAt).toBe('2026-05-19T10:00:00.000Z');
  });

  it('counts archived user tasks toward the snapshot', async () => {
    const service = new CatalogService(makePrisma({
      userCategories: 0,
      userTasks: 1,
      categoryOverrides: 0,
      taskOverrides: 0,
    }));
    const state = await service.getSnapshotState('user-1');
    expect(state.hasSnapshot).toBe(true);
    expect(state.totals.userTasks).toBe(1);
  });
});
