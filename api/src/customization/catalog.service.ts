import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CatalogService {
  constructor(private readonly prisma: PrismaService) {}

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
        where: { userId, archivedAt: null },
        orderBy: { sortOrder: 'asc' },
      }),
      this.prisma.userTask.findMany({
        where: { userId, archivedAt: null },
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
