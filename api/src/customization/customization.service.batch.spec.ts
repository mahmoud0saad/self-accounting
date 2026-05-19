import { Test } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { CustomizationService } from './customization.service';
import { PrismaService } from '../prisma/prisma.service';

describe('CustomizationService.processBatch', () => {
  let service: CustomizationService;
  const prisma = {
    userCategory: {
      findFirst: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
    },
    userTask: {
      findFirst: jest.fn(),
    },
    userCategoryOverride: { findUnique: jest.fn() },
    userTaskOverride: { findUnique: jest.fn() },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module = await Test.createTestingModule({
      providers: [
        CustomizationService,
        {
          provide: PrismaService,
          useValue: prisma,
        },
        {
          provide: ConfigService,
          useValue: { get: () => 10 },
        },
      ],
    }).compile();
    service = module.get(CustomizationService);
    jest
      .spyOn(service, 'updateUserCategory')
      .mockResolvedValue({ updatedAt: '2026-05-19T08:00:00.000Z' } as never);
    jest
      .spyOn(service, 'upsertCategoryOverride')
      .mockResolvedValue({ updatedAt: '2026-05-19T08:00:00.000Z' } as never);
  });

  it('creates a user category with the client-provided id', async () => {
    prisma.userCategory.findFirst.mockResolvedValue(null);
    prisma.userCategory.count.mockResolvedValue(0);
    prisma.userCategory.create.mockResolvedValue({
      updatedAt: new Date('2026-05-19T08:00:00.000Z'),
    });

    const result = await service.processBatch('user-1', [
      {
        opId: '1',
        opType: 'create_user_category',
        payload: {
          id: 'uc_local_1',
          name: 'My Category',
          icon: 'mosque',
          sortOrder: 50,
        },
        clientUpdatedAt: '2026-05-19T07:00:00.000Z',
      },
    ]);

    expect(prisma.userCategory.create).toHaveBeenCalledWith({
      data: {
        id: 'uc_local_1',
        userId: 'user-1',
        name: 'My Category',
        icon: 'mosque',
        sortOrder: 50,
      },
    });
    expect(result.outcomes[0]).toMatchObject({ opId: '1', applied: true });
  });

  it('does not return UNKNOWN_OP for create_user_category', async () => {
    prisma.userCategory.findFirst.mockResolvedValue(null);
    prisma.userCategory.count.mockResolvedValue(0);
    prisma.userCategory.create.mockResolvedValue({
      updatedAt: new Date('2026-05-19T08:00:00.000Z'),
    });

    const result = await service.processBatch('user-1', [
      {
        opId: '2',
        opType: 'create_user_category',
        payload: { id: 'uc_x', name: 'Test', icon: 'star' },
        clientUpdatedAt: '2026-05-19T07:00:00.000Z',
      },
    ]);

    expect(result.outcomes[0].error).not.toBe('UNKNOWN_OP');
  });
});
