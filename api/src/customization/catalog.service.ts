import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { SnapshotStateDto } from './dto/snapshot-state.dto';

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

  async getSnapshotState(userId: string): Promise<SnapshotStateDto> {
    const [
      userCategories,
      userTasks,
      categoryOverrides,
      taskOverrides,
      latestCategory,
      latestTask,
      latestCatOv,
      latestTaskOv,
    ] = await Promise.all([
      this.prisma.userCategory.count({ where: { userId } }),
      this.prisma.userTask.count({ where: { userId } }),
      this.prisma.userCategoryOverride.count({ where: { userId } }),
      this.prisma.userTaskOverride.count({ where: { userId } }),
      this.prisma.userCategory.findFirst({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
      this.prisma.userTask.findFirst({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
      this.prisma.userCategoryOverride.findFirst({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
      this.prisma.userTaskOverride.findFirst({
        where: { userId },
        orderBy: { updatedAt: 'desc' },
        select: { updatedAt: true },
      }),
    ]);

    const totals = {
      userCategories,
      userTasks,
      categoryOverrides,
      taskOverrides,
    };
    const totalCount =
      userCategories + userTasks + categoryOverrides + taskOverrides;

    const candidates = [
      latestCategory?.updatedAt,
      latestTask?.updatedAt,
      latestCatOv?.updatedAt,
      latestTaskOv?.updatedAt,
    ].filter((d): d is Date => d != null);

    return {
      hasSnapshot: totalCount > 0,
      totals,
      lastUpdatedAt:
        candidates.length > 0
          ? new Date(Math.max(...candidates.map((d) => d.getTime()))).toISOString()
          : undefined,
    };
  }

  async getFullCatalog(userId: string) {
    const [
      categories,
      tasks,
      userCategories,
      userTasks,
      userCategoryOverrides,
      userTaskOverrides,
    ] = await Promise.all([
      this.prisma.category.findMany({ orderBy: { defaultSortOrder: 'asc' } }),
      this.prisma.task.findMany({
        where: { isDefault: true },
        orderBy: { defaultSortOrder: 'asc' },
      }),
      this.prisma.userCategory.findMany({
        where: { userId },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.userTask.findMany({
        where: { userId },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.userCategoryOverride.findMany({ where: { userId } }),
      this.prisma.userTaskOverride.findMany({ where: { userId } }),
    ]);

    return {
      categories: categories.map((c) => ({
        code: c.code,
        defaultName: c.defaultName,
        defaultIcon: c.defaultIcon,
        defaultSortOrder: c.defaultSortOrder,
        isFard: c.isFard,
      })),
      tasks: tasks.map((t) => ({
        code: t.id,
        categoryCode: t.categoryCode,
        defaultPoints: t.defaultPoints,
        defaultIcon: t.defaultIcon,
        defaultSortOrder: t.defaultSortOrder,
      })),
      userCategories: userCategories.map((c) => ({
        id: c.id,
        name: c.name,
        icon: c.icon,
        sortOrder: c.sortOrder,
        archivedAt: c.archivedAt?.toISOString() ?? null,
        updatedAt: c.updatedAt.toISOString(),
      })),
      userTasks: userTasks.map((t) => ({
        id: t.id,
        categoryRef: t.categoryRef,
        name: t.name,
        points: t.points,
        icon: t.icon,
        sortOrder: t.sortOrder,
        description: t.description,
        kind: t.kind,
        archivedAt: t.archivedAt?.toISOString() ?? null,
        updatedAt: t.updatedAt.toISOString(),
      })),
      userCategoryOverrides: userCategoryOverrides.map((o) => ({
        categoryCode: o.categoryCode,
        hidden: o.hidden,
        customName: o.customName,
        customIcon: o.customIcon,
        sortOrder: o.sortOrder,
        updatedAt: o.updatedAt.toISOString(),
      })),
      userTaskOverrides: userTaskOverrides.map((o) => ({
        taskCode: o.taskCode,
        hidden: o.hidden,
        customName: o.customName,
        customPoints: o.customPoints,
        customIcon: o.customIcon,
        customCategoryRef: o.customCategoryRef,
        sortOrder: o.sortOrder,
        updatedAt: o.updatedAt.toISOString(),
      })),
    };
  }
}
