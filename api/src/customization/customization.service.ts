import {
  ConflictException,
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';
import { isFardCategoryCode } from './fard.constants';
import {
  assertCategoryRef,
  assertCuratedIcon,
  assertName,
  assertPointsInRange,
} from './customization.validation';
import type { CreateUserCategoryDto } from './dto/create-user-category.dto';
import type { CreateUserTaskDto } from './dto/create-user-task.dto';
import type { CustomizationBatchOpDto } from './dto/customization-batch.dto';
import type { UpdateUserCategoryDto } from './dto/update-user-category.dto';
import type { UpsertCategoryOverrideDto } from './dto/upsert-category-override.dto';
import type { UpsertTaskOverrideDto } from './dto/upsert-task-override.dto';

@Injectable()
export class CustomizationService {
  private readonly maxUserCategories: number;
  private readonly maxUserTasks: number;

  constructor(
    private readonly prisma: PrismaService,
    config: ConfigService,
  ) {
    this.maxUserCategories = Number(config.get('MAX_USER_CATEGORIES', 10));
    this.maxUserTasks = Number(config.get('MAX_USER_TASKS', 30));
  }

  async createUserCategory(userId: string, dto: CreateUserCategoryDto) {
    const active = await this.prisma.userCategory.count({
      where: { userId, archivedAt: null },
    });
    if (active >= this.maxUserCategories) {
      throw new UnprocessableEntityException({
        code: 'LIMIT_EXCEEDED',
        message: 'Maximum user categories reached.',
      });
    }
    const name = assertName(dto.name);
    assertCuratedIcon(dto.icon);
    const row = await this.prisma.userCategory.create({
      data: {
        userId,
        name,
        icon: dto.icon,
        sortOrder: dto.sortOrder ?? 100,
      },
    });
    return this.mapUserCategory(row);
  }

  async updateUserCategory(
    userId: string,
    id: string,
    dto: UpdateUserCategoryDto,
  ) {
    const existing = await this.findUserCategory(userId, id);
    const data: {
      name?: string;
      icon?: string;
      sortOrder?: number;
    } = {};
    if (dto.name != null) {
      data.name = assertName(dto.name);
    }
    if (dto.icon != null) {
      assertCuratedIcon(dto.icon);
      data.icon = dto.icon;
    }
    if (dto.sortOrder != null) {
      data.sortOrder = dto.sortOrder;
    }
    const row = await this.prisma.userCategory.update({
      where: { id: existing.id },
      data: {
        ...data,
        ...(dto.restore === true ? { archivedAt: null } : {}),
      },
    });
    return this.mapUserCategory(row);
  }

  async deleteUserCategory(
    userId: string,
    id: string,
    force: boolean,
    archive = false,
  ) {
    const existing = await this.prisma.userCategory.findFirst({
      where: { id, userId },
    });
    if (!existing) {
      throw new NotFoundException('User category not found');
    }
    if (archive) {
      const row = await this.prisma.userCategory.update({
        where: { id: existing.id },
        data: { archivedAt: new Date() },
      });
      return this.mapUserCategory(row);
    }
    const taskCount = await this.prisma.userTask.count({
      where: { userId, categoryRef: `userCategory:${id}`, archivedAt: null },
    });
    if (taskCount > 0 && !force) {
      throw new ConflictException(
        'Category has tasks. Use ?force=true to reassign them to Misc.',
      );
    }
    if (force && taskCount > 0) {
      await this.prisma.userTask.updateMany({
        where: { userId, categoryRef: `userCategory:${id}` },
        data: { categoryRef: 'category:miscAdhkar' },
      });
    }
    await this.prisma.userCategory.delete({ where: { id: existing.id } });
    return { deleted: true };
  }

  async upsertCategoryOverride(
    userId: string,
    categoryCode: string,
    dto: UpsertCategoryOverrideDto,
  ) {
    await this.assertDefaultCategoryExists(categoryCode);
    if (dto.hidden && isFardCategoryCode(categoryCode)) {
      throw new UnprocessableEntityException({
        code: 'FARD_CATEGORY_LOCKED',
        message: 'Fard category cannot be hidden.',
      });
    }
    if (dto.customName != null && isFardCategoryCode(categoryCode)) {
      throw new UnprocessableEntityException({
        code: 'FARD_CATEGORY_LOCKED',
        message: 'Fard category cannot be renamed.',
      });
    }
    if (dto.customIcon != null) {
      assertCuratedIcon(dto.customIcon);
    }

    const isEmpty =
      !dto.hidden &&
      dto.customName == null &&
      dto.customIcon == null &&
      dto.sortOrder == null;

    if (isEmpty) {
      await this.prisma.userCategoryOverride.deleteMany({
        where: { userId, categoryCode },
      });
      return { deleted: true };
    }

    const row = await this.prisma.userCategoryOverride.upsert({
      where: { userId_categoryCode: { userId, categoryCode } },
      create: {
        userId,
        categoryCode,
        hidden: dto.hidden ?? false,
        customName: dto.customName ?? undefined,
        customIcon: dto.customIcon ?? undefined,
        sortOrder: dto.sortOrder ?? undefined,
      },
      update: {
        hidden: dto.hidden ?? false,
        customName: dto.customName ?? null,
        customIcon: dto.customIcon ?? null,
        sortOrder: dto.sortOrder ?? null,
      },
    });
    return {
      categoryCode: row.categoryCode,
      hidden: row.hidden,
      customName: row.customName,
      customIcon: row.customIcon,
      sortOrder: row.sortOrder,
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  async createUserTask(userId: string, dto: CreateUserTaskDto) {
    return this.createUserTaskWithId(userId, undefined, dto);
  }

  private async createUserTaskWithId(
    userId: string,
    id: string | undefined,
    dto: CreateUserTaskDto,
  ) {
    const active = await this.prisma.userTask.count({
      where: { userId, archivedAt: null },
    });
    if (active >= this.maxUserTasks) {
      throw new UnprocessableEntityException({
        code: 'LIMIT_EXCEEDED',
        message: 'Maximum user tasks reached.',
      });
    }
    const name = assertName(dto.name);
    assertPointsInRange(dto.points);
    assertCuratedIcon(dto.icon);
    assertCategoryRef(dto.categoryRef);
    await this.assertCategoryRefResolvable(userId, dto.categoryRef);

    const row = await this.prisma.userTask.create({
      data: {
        ...(id != null ? { id } : {}),
        userId,
        name,
        categoryRef: dto.categoryRef,
        points: dto.points,
        icon: dto.icon,
        sortOrder: dto.sortOrder ?? 0,
      },
    });
    return this.mapUserTask(row);
  }

  async updateUserTask(
    userId: string,
    id: string,
    dto: Partial<CreateUserTaskDto>,
  ) {
    const existing = await this.findUserTask(userId, id);
    const data: {
      name?: string;
      categoryRef?: string;
      points?: number;
      icon?: string;
      sortOrder?: number;
    } = {};
    if (dto.name != null) {
      data.name = assertName(dto.name);
    }
    if (dto.categoryRef != null) {
      assertCategoryRef(dto.categoryRef);
      await this.assertCategoryRefResolvable(userId, dto.categoryRef);
      data.categoryRef = dto.categoryRef;
    }
    if (dto.points != null) {
      assertPointsInRange(dto.points);
      data.points = dto.points;
    }
    if (dto.icon != null) {
      assertCuratedIcon(dto.icon);
      data.icon = dto.icon;
    }
    if (dto.sortOrder != null) {
      data.sortOrder = dto.sortOrder;
    }
    const restore =
      dto && 'restore' in dto && (dto as { restore?: boolean }).restore === true;
    const row = await this.prisma.userTask.update({
      where: { id: existing.id },
      data: {
        ...data,
        ...(restore ? { archivedAt: null } : {}),
      },
    });
    return this.mapUserTask(row);
  }

  async deleteUserTask(userId: string, id: string, archive: boolean) {
    const existing = await this.findUserTask(userId, id);
    const logCount = await this.prisma.dailyLog.count({
      where: { userId, userTaskId: id },
    });
    if (logCount > 0 && !archive) {
      throw new ConflictException(
        'Task has history. Use ?archive=true to hide it.',
      );
    }
    if (archive || logCount > 0) {
      const row = await this.prisma.userTask.update({
        where: { id: existing.id },
        data: { archivedAt: new Date() },
      });
      return { archived: true, id: row.id };
    }
    await this.prisma.userTask.delete({ where: { id: existing.id } });
    return { deleted: true };
  }

  async upsertTaskOverride(
    userId: string,
    taskCode: string,
    dto: UpsertTaskOverrideDto,
  ) {
    await this.assertDefaultTaskExists(taskCode);
    if (dto.customPoints != null) {
      assertPointsInRange(dto.customPoints);
    }
    if (dto.customIcon != null) {
      assertCuratedIcon(dto.customIcon);
    }
    if (dto.customCategoryRef != null) {
      assertCategoryRef(dto.customCategoryRef);
      await this.assertCategoryRefResolvable(userId, dto.customCategoryRef);
    }

    const isEmpty =
      !dto.hidden &&
      dto.customName == null &&
      dto.customPoints == null &&
      dto.customIcon == null &&
      dto.customCategoryRef == null &&
      dto.sortOrder == null;

    if (isEmpty) {
      await this.prisma.userTaskOverride.deleteMany({
        where: { userId, taskCode },
      });
      return { deleted: true };
    }

    const row = await this.prisma.userTaskOverride.upsert({
      where: { userId_taskCode: { userId, taskCode } },
      create: {
        userId,
        taskCode,
        hidden: dto.hidden ?? false,
        customName: dto.customName ?? undefined,
        customPoints: dto.customPoints ?? undefined,
        customIcon: dto.customIcon ?? undefined,
        customCategoryRef: dto.customCategoryRef ?? undefined,
        sortOrder: dto.sortOrder ?? undefined,
      },
      update: {
        hidden: dto.hidden ?? false,
        customName: dto.customName ?? null,
        customPoints: dto.customPoints ?? null,
        customIcon: dto.customIcon ?? null,
        customCategoryRef: dto.customCategoryRef ?? null,
        sortOrder: dto.sortOrder ?? null,
      },
    });

    const warning =
      dto.hidden && taskCode.endsWith('_first_congregation')
        ? 'FARD_TASK_HIDDEN'
        : undefined;

    return {
      taskCode: row.taskCode,
      hidden: row.hidden,
      customName: row.customName,
      customPoints: row.customPoints,
      customIcon: row.customIcon,
      customCategoryRef: row.customCategoryRef,
      sortOrder: row.sortOrder,
      updatedAt: row.updatedAt.toISOString(),
      warning,
    };
  }

  async processBatch(userId: string, ops: CustomizationBatchOpDto[]) {
    const outcomes: Array<{
      opId: string;
      applied: boolean;
      serverUpdatedAt?: string;
      error?: string;
    }> = [];

    for (const op of ops) {
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
    op: CustomizationBatchOpDto,
    clientAt: Date,
  ): Promise<{ applied: boolean; serverUpdatedAt?: string; error?: string }> {
    const p = op.payload;
    switch (op.opType) {
      case 'create_user_category': {
        const id = String(p.id);
        const existing = await this.prisma.userCategory.findFirst({
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
          const row = await this.updateUserCategory(userId, id, {
            name: String(p.name),
            icon: String(p.icon),
            sortOrder: p.sortOrder as number | undefined,
          });
          return { applied: true, serverUpdatedAt: row.updatedAt };
        }
        const active = await this.prisma.userCategory.count({
          where: { userId, archivedAt: null },
        });
        if (active >= this.maxUserCategories) {
          throw new UnprocessableEntityException({
            code: 'LIMIT_EXCEEDED',
            message: 'Maximum user categories reached.',
          });
        }
        const name = assertName(String(p.name));
        assertCuratedIcon(String(p.icon));
        const row = await this.prisma.userCategory.create({
          data: {
            id,
            userId,
            name,
            icon: String(p.icon),
            sortOrder: (p.sortOrder as number | undefined) ?? 100,
          },
        });
        return { applied: true, serverUpdatedAt: row.updatedAt.toISOString() };
      }
      case 'update_user_category': {
        const id = String(p.id);
        const existing = await this.prisma.userCategory.findFirst({
          where: { id, userId },
        });
        if (!existing) {
          return { applied: false, error: 'NOT_FOUND' };
        }
        if (this.isStale(existing.updatedAt, clientAt)) {
          return {
            applied: false,
            serverUpdatedAt: existing.updatedAt.toISOString(),
            error: 'STALE',
          };
        }
        const row = await this.updateUserCategory(userId, id, {
          name: p.name != null ? String(p.name) : undefined,
          icon: p.icon != null ? String(p.icon) : undefined,
          sortOrder: p.sortOrder as number | undefined,
          restore: p.restore === true ? true : undefined,
        });
        return { applied: true, serverUpdatedAt: row.updatedAt };
      }
      case 'delete_user_category': {
        const id = String(p.id);
        const existing = await this.prisma.userCategory.findFirst({
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
        const result = await this.deleteUserCategory(
          userId,
          id,
          p.force === true,
          p.archive === true,
        );
        const updatedAt =
          'updatedAt' in result ? String(result.updatedAt) : new Date().toISOString();
        return { applied: true, serverUpdatedAt: updatedAt };
      }
      case 'create_user_task': {
        const id = String(p.id);
        const existing = await this.prisma.userTask.findFirst({
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
          const row = await this.updateUserTask(userId, id, {
            name: String(p.name),
            categoryRef: String(p.categoryRef),
            points: Number(p.points),
            icon: String(p.icon),
            sortOrder: p.sortOrder as number | undefined,
          });
          return { applied: true, serverUpdatedAt: row.updatedAt };
        }
        const row = await this.createUserTaskWithId(userId, id, {
          name: String(p.name),
          categoryRef: String(p.categoryRef),
          points: Number(p.points),
          icon: String(p.icon),
          sortOrder: (p.sortOrder as number | undefined) ?? 0,
        });
        return { applied: true, serverUpdatedAt: row.updatedAt };
      }
      case 'update_user_task': {
        const id = String(p.id);
        const existing = await this.prisma.userTask.findFirst({
          where: { id, userId },
        });
        if (!existing) {
          return { applied: false, error: 'NOT_FOUND' };
        }
        if (this.isStale(existing.updatedAt, clientAt)) {
          return {
            applied: false,
            serverUpdatedAt: existing.updatedAt.toISOString(),
            error: 'STALE',
          };
        }
        const row = await this.updateUserTask(userId, id, {
          name: p.name != null ? String(p.name) : undefined,
          categoryRef:
            p.categoryRef != null ? String(p.categoryRef) : undefined,
          points: p.points != null ? Number(p.points) : undefined,
          icon: p.icon != null ? String(p.icon) : undefined,
          sortOrder: p.sortOrder as number | undefined,
          ...(p.restore === true ? { restore: true } : {}),
        } as Partial<CreateUserTaskDto> & { restore?: boolean });
        return { applied: true, serverUpdatedAt: row.updatedAt };
      }
      case 'delete_user_task': {
        const id = String(p.id);
        const existing = await this.prisma.userTask.findFirst({
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
        await this.deleteUserTask(userId, id, p.archive === true);
        const row = await this.prisma.userTask.findFirst({
          where: { id, userId },
        });
        return {
          applied: true,
          serverUpdatedAt:
            row?.updatedAt.toISOString() ?? new Date().toISOString(),
        };
      }
      case 'upsert_user_category_override': {
        const code = String(p.categoryCode);
        const existing = await this.prisma.userCategoryOverride.findUnique({
          where: { userId_categoryCode: { userId, categoryCode: code } },
        });
        if (existing && existing.updatedAt > clientAt) {
          return {
            applied: false,
            serverUpdatedAt: existing.updatedAt.toISOString(),
            error: 'STALE',
          };
        }
        const row = await this.upsertCategoryOverride(userId, code, {
          hidden: Boolean(p.hidden),
          customName: p.customName as string | null | undefined,
          customIcon: p.customIcon as string | null | undefined,
          sortOrder: p.sortOrder as number | null | undefined,
        });
        const updatedAt =
          'updatedAt' in row ? String(row.updatedAt) : new Date().toISOString();
        return { applied: true, serverUpdatedAt: updatedAt };
      }
      case 'upsert_user_task_override': {
        const taskCode = String(p.taskCode);
        const existing = await this.prisma.userTaskOverride.findUnique({
          where: { userId_taskCode: { userId, taskCode } },
        });
        if (existing && existing.updatedAt > clientAt) {
          return {
            applied: false,
            serverUpdatedAt: existing.updatedAt.toISOString(),
            error: 'STALE',
          };
        }
        const row = await this.upsertTaskOverride(userId, taskCode, {
          hidden: Boolean(p.hidden),
          customName: p.customName as string | null | undefined,
          customPoints: p.customPoints as number | null | undefined,
          customIcon: p.customIcon as string | null | undefined,
          customCategoryRef: p.customCategoryRef as string | null | undefined,
          sortOrder: p.sortOrder as number | null | undefined,
        });
        const updatedAt =
          'updatedAt' in row ? String(row.updatedAt) : new Date().toISOString();
        return { applied: true, serverUpdatedAt: updatedAt };
      }
      default:
        return { applied: false, error: 'UNKNOWN_OP' };
    }
  }

  private async findUserCategory(userId: string, id: string) {
    const row = await this.prisma.userCategory.findFirst({
      where: { id, userId },
    });
    if (!row) {
      throw new NotFoundException('User category not found.');
    }
    return row;
  }

  private async findUserTask(userId: string, id: string) {
    const row = await this.prisma.userTask.findFirst({
      where: { id, userId },
    });
    if (!row) {
      throw new NotFoundException('User task not found.');
    }
    return row;
  }

  private async assertDefaultCategoryExists(code: string) {
    const cat = await this.prisma.category.findUnique({ where: { code } });
    if (!cat) {
      throw new NotFoundException(`Unknown category: ${code}`);
    }
  }

  private async assertDefaultTaskExists(code: string) {
    const task = await this.prisma.task.findUnique({ where: { id: code } });
    if (!task?.isDefault) {
      throw new NotFoundException(`Unknown default task: ${code}`);
    }
  }

  private async assertCategoryRefResolvable(userId: string, ref: string) {
    if (ref.startsWith('category:')) {
      await this.assertDefaultCategoryExists(ref.slice('category:'.length));
      return;
    }
    const id = ref.slice('userCategory:'.length);
    await this.findUserCategory(userId, id);
  }

  private mapUserCategory(row: {
    id: string;
    name: string;
    icon: string;
    sortOrder: number;
    updatedAt: Date;
  }) {
    return {
      id: row.id,
      name: row.name,
      icon: row.icon,
      sortOrder: row.sortOrder,
      updatedAt: row.updatedAt.toISOString(),
    };
  }

  private mapUserTask(row: {
    id: string;
    categoryRef: string;
    name: string;
    points: number;
    icon: string;
    sortOrder: number;
    updatedAt: Date;
  }) {
    return {
      id: row.id,
      categoryRef: row.categoryRef,
      name: row.name,
      points: row.points,
      icon: row.icon,
      sortOrder: row.sortOrder,
      updatedAt: row.updatedAt.toISOString(),
    };
  }
}
