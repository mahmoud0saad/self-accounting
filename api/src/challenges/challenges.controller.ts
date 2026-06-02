import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Put,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import type { RequestUser } from '../common/types/jwt-payload';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { ChallengesService } from './challenges.service';
import { ChallengeBatchDto } from './dto/challenge-batch.dto';
import { ChallengeTemplateDto } from './dto/challenge-template.dto';
import { CreateChallengeDto } from './dto/create-challenge.dto';
import { PatchChallengeDto } from './dto/patch-challenge.dto';
import { ChallengeSnapshotStateDto } from './dto/snapshot-state.dto';
import { UpsertChallengeWeekDto } from './dto/upsert-challenge-week.dto';
import { UserChallengeDto } from './dto/user-challenge.dto';

@ApiTags('Challenges')
@ApiBearerAuth()
@Controller('challenges')
export class ChallengesController {
  constructor(private readonly challenges: ChallengesService) {}

  @Get('templates')
  @ApiOperation({ summary: 'List active challenge templates' })
  @ApiOkResponse({ type: [ChallengeTemplateDto] })
  @ApiUnauthorizedResponse()
  @ApiForbiddenResponse()
  getTemplates() {
    return this.challenges.getTemplates();
  }

  @Get('snapshot-state')
  @ApiOperation({
    summary: 'Whether this account has saved weekly challenges',
    description:
      'Cheap head check before a full challenge restore on sign-in.',
  })
  @ApiOkResponse({ type: ChallengeSnapshotStateDto })
  @ApiUnauthorizedResponse()
  @ApiForbiddenResponse()
  getSnapshotState(
    @CurrentUser() user: RequestUser,
  ): Promise<ChallengeSnapshotStateDto> {
    return this.challenges.getSnapshotState(user.sub);
  }

  @Get()
  @ApiOperation({ summary: 'List user challenge subscriptions' })
  @ApiQuery({ name: 'includeArchived', required: false, type: Boolean })
  @ApiOkResponse({ type: [UserChallengeDto] })
  @ApiUnauthorizedResponse()
  @ApiForbiddenResponse()
  listChallenges(
    @CurrentUser() user: RequestUser,
    @Query('includeArchived') includeArchived?: string,
  ) {
    return this.challenges.listUserChallenges(
      user.sub,
      includeArchived === 'true',
    );
  }

  @Post()
  @ApiOperation({ summary: 'Subscribe to a template or create a custom challenge' })
  @ApiCreatedResponse({ type: UserChallengeDto })
  @ApiUnauthorizedResponse()
  @ApiForbiddenResponse()
  createChallenge(
    @CurrentUser() user: RequestUser,
    @Body() dto: CreateChallengeDto,
  ) {
    return this.challenges.createChallenge(user.sub, dto);
  }

  @Put('batch')
  @ApiOperation({ summary: 'Apply challenge sync operations' })
  batch(@CurrentUser() user: RequestUser, @Body() dto: ChallengeBatchDto) {
    return this.challenges.processBatch(user.sub, dto.ops);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update subscription (archive or edit custom fields)' })
  @ApiOkResponse({ type: UserChallengeDto })
  patchChallenge(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Body() dto: PatchChallengeDto,
  ) {
    return this.challenges.patchChallenge(user.sub, id, dto);
  }

  @Put(':id/weeks/:weekStart')
  @ApiOperation({ summary: 'Upsert weekly progress for a challenge' })
  @ApiOkResponse()
  upsertWeek(
    @CurrentUser() user: RequestUser,
    @Param('id') id: string,
    @Param('weekStart') weekStart: string,
    @Body() dto: UpsertChallengeWeekDto,
  ) {
    return this.challenges.upsertChallengeWeek(
      user.sub,
      id,
      weekStart,
      dto,
    );
  }
}
