import { randomUUID } from 'node:crypto';
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTaskDto } from './dto/create-task.dto';

@Injectable()
export class TasksService {
  constructor(private readonly prisma: PrismaService) {}

  listForUser(userId: string) {
    return this.prisma.task.findMany({
      where: {
        OR: [{ isDefault: true, userId: null }, { userId }],
      },
      orderBy: [{ isDefault: 'desc' }, { category: 'asc' }, { id: 'asc' }],
    });
  }

  createForUser(userId: string, dto: CreateTaskDto) {
    return this.prisma.task.create({
      data: {
        id: randomUUID(),
        name: dto.name,
        category: dto.category,
        points: dto.points,
        isDefault: false,
        userId,
      },
    });
  }
}
