import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpsertLogDto } from './dto/upsert-log.dto';

function parseDay(date: string): Date {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(date);
  if (!match) {
    throw new BadRequestException('date must be YYYY-MM-DD');
  }
  return new Date(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])));
}

@Injectable()
export class LogsService {
  constructor(private readonly prisma: PrismaService) {}

  async upsert(userId: string, dto: UpsertLogDto) {
    const day = parseDay(dto.date);
    const incomingUpdatedAt = new Date(dto.updatedAt);

    const existing = await this.prisma.dailyLog.findUnique({
      where: {
        userId_date_taskId: {
          userId,
          date: day,
          taskId: dto.taskId,
        },
      },
    });

    if (existing && existing.updatedAt >= incomingUpdatedAt) {
      return existing;
    }

    return this.prisma.dailyLog.upsert({
      where: {
        userId_date_taskId: {
          userId,
          date: day,
          taskId: dto.taskId,
        },
      },
      create: {
        userId,
        date: day,
        taskId: dto.taskId,
        completed: dto.completed,
        updatedAt: incomingUpdatedAt,
      },
      update: {
        completed: dto.completed,
        updatedAt: incomingUpdatedAt,
      },
    });
  }

  listInRange(userId: string, from: string, to: string) {
    const fromDay = parseDay(from);
    const toDay = parseDay(to);
    if (fromDay > toDay) {
      throw new BadRequestException('from must be on or before to');
    }

    return this.prisma.dailyLog.findMany({
      where: {
        userId,
        date: { gte: fromDay, lte: toDay },
      },
      orderBy: [{ date: 'asc' }, { taskId: 'asc' }],
    });
  }
}
