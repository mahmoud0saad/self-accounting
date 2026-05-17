import { Body, Controller, Get, Put, Query } from '@nestjs/common';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../auth/strategies/jwt.strategy';
import { UpsertLogDto } from './dto/upsert-log.dto';
import { LogsService } from './logs.service';

@Controller('logs')
export class LogsController {
  constructor(private readonly logsService: LogsService) {}

  @Put()
  upsert(@CurrentUser() user: AuthenticatedUser, @Body() dto: UpsertLogDto) {
    return this.logsService.upsert(user.userId, dto);
  }

  @Get()
  list(
    @CurrentUser() user: AuthenticatedUser,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.logsService.listInRange(user.userId, from, to);
  }
}
