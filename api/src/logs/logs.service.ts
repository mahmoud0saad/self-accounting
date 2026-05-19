import { BadRequestException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { BatchLogItemDto } from './dto/batch-logs.dto';

@Injectable()
export class LogsService {
  constructor(private readonly prisma: PrismaService) {}

  async listRange(userId: string, from: string, to: string) {
    this.assertIsoDate(from, 'from');
    this.assertIsoDate(to, 'to');

    const rows = await this.prisma.dailyLog.findMany({
      where: {
        userId,
        date: {
          gte: new Date(`${from}T00:00:00.000Z`),
          lte: new Date(`${to}T00:00:00.000Z`),
        },
      },
      orderBy: [{ date: 'asc' }, { taskId: 'asc' }],
    });

    return rows.map((r) => ({
      date: this.formatDate(r.date),
      taskId: r.taskId,
      completed: r.completed,
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async batchUpsert(userId: string, items: BatchLogItemDto[]) {
    const outcomes: Array<{
      date: string;
      taskId: string;
      applied: boolean;
      serverUpdatedAt: string;
    }> = [];

    for (const item of items) {
      this.assertIsoDate(item.date, 'date');
      const clientAt = new Date(item.clientUpdatedAt);
      if (Number.isNaN(clientAt.getTime())) {
        throw new BadRequestException('Invalid clientUpdatedAt.');
      }

      const dateValue = new Date(`${item.date}T00:00:00.000Z`);
      const existing = await this.prisma.dailyLog.findUnique({
        where: {
          userId_date_taskId: {
            userId,
            date: dateValue,
            taskId: item.taskId,
          },
        },
      });

      if (existing && existing.updatedAt > clientAt) {
        outcomes.push({
          date: item.date,
          taskId: item.taskId,
          applied: false,
          serverUpdatedAt: existing.updatedAt.toISOString(),
        });
        continue;
      }

      const row = await this.prisma.dailyLog.upsert({
        where: {
          userId_date_taskId: {
            userId,
            date: dateValue,
            taskId: item.taskId,
          },
        },
        create: {
          userId,
          date: dateValue,
          taskId: item.taskId,
          completed: item.completed,
          updatedAt: clientAt,
        },
        update: {
          completed: item.completed,
          updatedAt: clientAt,
        },
      });

      outcomes.push({
        date: item.date,
        taskId: item.taskId,
        applied: true,
        serverUpdatedAt: row.updatedAt.toISOString(),
      });
    }

    return { outcomes };
  }

  private assertIsoDate(value: string, field: string): void {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
      throw new BadRequestException(`${field} must be YYYY-MM-DD.`);
    }
  }

  private formatDate(d: Date): string {
    return d.toISOString().slice(0, 10);
  }
}
