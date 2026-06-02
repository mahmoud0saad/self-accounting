import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { BatchLogItemDto } from './dto/batch-logs.dto';

type LogOutcome = {
  date: string;
  taskId?: string | null;
  userTaskId?: string | null;
  applied: boolean;
  serverUpdatedAt: string;
};

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
      orderBy: [{ date: 'asc' }, { taskId: 'asc' }, { userTaskId: 'asc' }],
    });

    return rows.map((r) => ({
      date: this.formatDate(r.date),
      taskId: r.taskId,
      userTaskId: r.userTaskId,
      completed: r.completed,
      updatedAt: r.updatedAt.toISOString(),
    }));
  }

  async batchUpsert(userId: string, items: BatchLogItemDto[]) {
    const outcomes: LogOutcome[] = [];

    for (const item of items) {
      this.assertLogTarget(item);
      this.assertIsoDate(item.date, 'date');
      const clientAt = new Date(item.clientUpdatedAt);
      if (Number.isNaN(clientAt.getTime())) {
        throw new BadRequestException('Invalid clientUpdatedAt.');
      }

      const dateValue = new Date(`${item.date}T00:00:00.000Z`);

      if (item.userTaskId != null) {
        outcomes.push(
          await this.upsertUserTaskLog(
            userId,
            item.date,
            dateValue,
            item.userTaskId,
            item.completed,
            clientAt,
          ),
        );
      } else {
        outcomes.push(
          await this.upsertCatalogTaskLog(
            userId,
            item.date,
            dateValue,
            item.taskId!,
            item.completed,
            clientAt,
          ),
        );
      }
    }

    return { outcomes };
  }

  private async upsertCatalogTaskLog(
    userId: string,
    date: string,
    dateValue: Date,
    taskId: string,
    completed: boolean,
    clientAt: Date,
  ): Promise<LogOutcome> {
    const existing = await this.prisma.dailyLog.findUnique({
      where: {
        userId_date_taskId: {
          userId,
          date: dateValue,
          taskId,
        },
      },
    });

    if (existing && existing.updatedAt > clientAt) {
      return {
        date,
        taskId,
        userTaskId: null,
        applied: false,
        serverUpdatedAt: existing.updatedAt.toISOString(),
      };
    }

    const row = await this.prisma.dailyLog.upsert({
      where: {
        userId_date_taskId: {
          userId,
          date: dateValue,
          taskId,
        },
      },
      create: {
        userId,
        date: dateValue,
        taskId,
        completed,
        updatedAt: clientAt,
      },
      update: {
        completed,
        updatedAt: clientAt,
      },
    });

    return {
      date,
      taskId: row.taskId,
      userTaskId: null,
      applied: true,
      serverUpdatedAt: row.updatedAt.toISOString(),
    };
  }

  private async upsertUserTaskLog(
    userId: string,
    date: string,
    dateValue: Date,
    userTaskId: string,
    completed: boolean,
    clientAt: Date,
  ): Promise<LogOutcome> {
    const userTask = await this.prisma.userTask.findFirst({
      where: { id: userTaskId, userId },
    });
    if (!userTask) {
      throw new NotFoundException(`User task not found: ${userTaskId}`);
    }

    const existing = await this.prisma.dailyLog.findUnique({
      where: {
        userId_date_userTaskId: {
          userId,
          date: dateValue,
          userTaskId,
        },
      },
    });

    if (existing && existing.updatedAt > clientAt) {
      return {
        date,
        taskId: null,
        userTaskId,
        applied: false,
        serverUpdatedAt: existing.updatedAt.toISOString(),
      };
    }

    const row = await this.prisma.dailyLog.upsert({
      where: {
        userId_date_userTaskId: {
          userId,
          date: dateValue,
          userTaskId,
        },
      },
      create: {
        userId,
        date: dateValue,
        userTaskId,
        completed,
        updatedAt: clientAt,
      },
      update: {
        completed,
        updatedAt: clientAt,
      },
    });

    return {
      date,
      taskId: null,
      userTaskId: row.userTaskId,
      applied: true,
      serverUpdatedAt: row.updatedAt.toISOString(),
    };
  }

  private assertLogTarget(item: BatchLogItemDto): void {
    const hasTask = item.taskId != null && item.taskId.length > 0;
    const hasUserTask = item.userTaskId != null && item.userTaskId.length > 0;
    if (hasTask === hasUserTask) {
      throw new BadRequestException(
        'Each log item must include exactly one of taskId or userTaskId.',
      );
    }
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
