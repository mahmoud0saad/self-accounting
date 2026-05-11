import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export type HealthDbStatus = 'up' | 'down';

export interface HealthPayload {
  status: 'ok';
  uptime: number;
  db: HealthDbStatus;
}

@Injectable()
export class HealthService {
  constructor(private readonly prisma: PrismaService) {}

  async getHealth(): Promise<HealthPayload> {
    const db = await this.checkDb();
    return {
      status: 'ok',
      uptime: Math.round(process.uptime()),
      db,
    };
  }

  private async checkDb(): Promise<HealthDbStatus> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
      return 'up';
    } catch {
      return 'down';
    }
  }
}
