import { Body, Controller, Get, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import type { RequestUser } from '../common/types/jwt-payload';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { BatchLogsDto } from './dto/batch-logs.dto';
import { LogsService } from './logs.service';

@ApiTags('logs')
@ApiBearerAuth()
@Controller('logs')
export class LogsController {
  constructor(private readonly logs: LogsService) {}

  @Get()
  @ApiQuery({ name: 'from', required: true, example: '2026-05-01' })
  @ApiQuery({ name: 'to', required: true, example: '2026-05-18' })
  list(
    @CurrentUser() user: RequestUser,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.logs.listRange(user.sub, from, to);
  }

  @Put('batch')
  batch(@CurrentUser() user: RequestUser, @Body() dto: BatchLogsDto) {
    return this.logs.batchUpsert(user.sub, dto.items);
  }
}
