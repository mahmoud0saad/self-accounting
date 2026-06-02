import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class UserChallengeWeekDto {
  @ApiProperty()
  id!: string;

  @ApiProperty({ example: '2026-05-17' })
  weekStart!: string;

  @ApiProperty({ example: '2026-05-23' })
  weekEnd!: string;

  @ApiProperty({ example: 7 })
  goalCount!: number;

  @ApiProperty({ example: 3 })
  achievedCount!: number;

  @ApiProperty({ example: 'IN_PROGRESS' })
  status!: string;

  @ApiPropertyOptional()
  completedAt?: string;

  @ApiPropertyOptional()
  celebrationSeenAt?: string;

  @ApiProperty()
  updatedAt!: string;
}
