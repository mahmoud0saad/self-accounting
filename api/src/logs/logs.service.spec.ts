import { NotFoundException } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import { LogsService } from './logs.service';
import { PrismaService } from '../prisma/prisma.service';

describe('LogsService', () => {
  let service: LogsService;
  const prisma = {
    dailyLog: {
      findMany: jest.fn(),
      findUnique: jest.fn(),
      upsert: jest.fn(),
    },
    userTask: {
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        LogsService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();
    service = module.get(LogsService);
  });

  it('rejects items with both taskId and userTaskId', async () => {
    await expect(
      service.batchUpsert('user-1', [
        {
          date: '2026-06-02',
          taskId: 'fajr_waking_up_adhkar',
          userTaskId: 'ut_1',
          completed: true,
          clientUpdatedAt: '2026-06-02T10:00:00.000Z',
        },
      ]),
    ).rejects.toThrow('exactly one of taskId or userTaskId');
  });

  it('rejects items with neither taskId nor userTaskId', async () => {
    await expect(
      service.batchUpsert('user-1', [
        {
          date: '2026-06-02',
          completed: true,
          clientUpdatedAt: '2026-06-02T10:00:00.000Z',
        },
      ]),
    ).rejects.toThrow('exactly one of taskId or userTaskId');
  });

  it('upserts a user-task log when the task exists', async () => {
    prisma.userTask.findFirst.mockResolvedValue({ id: 'ut_1' });
    prisma.dailyLog.findUnique.mockResolvedValue(null);
    prisma.dailyLog.upsert.mockResolvedValue({
      userTaskId: 'ut_1',
      taskId: null,
      updatedAt: new Date('2026-06-02T11:00:00.000Z'),
    });

    const result = await service.batchUpsert('user-1', [
      {
        date: '2026-06-02',
        userTaskId: 'ut_1',
        completed: true,
        clientUpdatedAt: '2026-06-02T10:00:00.000Z',
      },
    ]);

    expect(prisma.dailyLog.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: {
          userId_date_userTaskId: {
            userId: 'user-1',
            date: new Date('2026-06-02T00:00:00.000Z'),
            userTaskId: 'ut_1',
          },
        },
      }),
    );
    expect(result.outcomes[0]).toMatchObject({
      userTaskId: 'ut_1',
      applied: true,
    });
  });

  it('returns 404 when user task does not exist', async () => {
    prisma.userTask.findFirst.mockResolvedValue(null);

    await expect(
      service.batchUpsert('user-1', [
        {
          date: '2026-06-02',
          userTaskId: 'ut_missing',
          completed: true,
          clientUpdatedAt: '2026-06-02T10:00:00.000Z',
        },
      ]),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('listRange returns taskId and userTaskId', async () => {
    prisma.dailyLog.findMany.mockResolvedValue([
      {
        date: new Date('2026-06-02T00:00:00.000Z'),
        taskId: 'fajr_waking_up_adhkar',
        userTaskId: null,
        completed: true,
        updatedAt: new Date('2026-06-02T10:00:00.000Z'),
      },
      {
        date: new Date('2026-06-02T00:00:00.000Z'),
        taskId: null,
        userTaskId: 'ut_1',
        completed: false,
        updatedAt: new Date('2026-06-02T11:00:00.000Z'),
      },
    ]);

    const rows = await service.listRange('user-1', '2026-06-01', '2026-06-02');

    expect(rows).toEqual([
      {
        date: '2026-06-02',
        taskId: 'fajr_waking_up_adhkar',
        userTaskId: null,
        completed: true,
        updatedAt: '2026-06-02T10:00:00.000Z',
      },
      {
        date: '2026-06-02',
        taskId: null,
        userTaskId: 'ut_1',
        completed: false,
        updatedAt: '2026-06-02T11:00:00.000Z',
      },
    ]);
  });
});
