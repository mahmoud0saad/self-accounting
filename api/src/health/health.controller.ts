import { Controller, Get } from '@nestjs/common';
import { HealthService, type HealthPayload } from './health.service';

@Controller('health')
export class HealthController {
  constructor(private readonly healthService: HealthService) {}

  @Get()
  getHealth(): Promise<HealthPayload> {
    return this.healthService.getHealth();
  }
}
