import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  listCatalog() {
    return this.prisma.task.findMany({
      where: { isDefault: true, userId: null },
      orderBy: { id: 'asc' },
      select: {
        id: true,
        category: true,
        defaultPoints: true,
        isDefault: true,
      },
    });
  }
}
