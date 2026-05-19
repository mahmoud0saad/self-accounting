import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  listCatalog() {
    return this.prisma.task.findMany({
      where: { isDefault: true },
      orderBy: { id: 'asc' },
      select: {
        id: true,
        categoryCode: true,
        defaultPoints: true,
        defaultIcon: true,
        isDefault: true,
      },
    });
  }
}
