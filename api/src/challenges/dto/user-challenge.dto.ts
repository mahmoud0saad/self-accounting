import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { UserChallengeWeekDto } from './user-challenge-week.dto';

export class UserChallengeDto {
  @ApiProperty()
  id!: string;

  @ApiPropertyOptional({ example: 'fajr_in_jamaah' })
  templateCode?: string;

  @ApiPropertyOptional()
  customTitle?: string;

  @ApiPropertyOptional()
  customIcon?: string;

  @ApiPropertyOptional()
  customSourceKind?: string;

  @ApiPropertyOptional()
  customSourceRef?: string;

  @ApiPropertyOptional()
  customGoalCount?: number;

  @ApiProperty()
  startedAt!: string;

  @ApiPropertyOptional()
  archivedAt?: string;

  @ApiProperty()
  updatedAt!: string;

  @ApiPropertyOptional({ type: UserChallengeWeekDto })
  currentWeek?: UserChallengeWeekDto;

  @ApiProperty({ type: [UserChallengeWeekDto] })
  weeks!: UserChallengeWeekDto[];
}
