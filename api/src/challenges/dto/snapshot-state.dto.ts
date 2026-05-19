import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class ChallengeSnapshotTotalsDto {
  @ApiProperty({ example: 2 })
  userChallenges!: number;

  @ApiProperty({ example: 4 })
  userChallengeWeeks!: number;
}

export class ChallengeSnapshotStateDto {
  @ApiProperty({ example: true })
  hasSnapshot!: boolean;

  @ApiProperty({ type: ChallengeSnapshotTotalsDto })
  totals!: ChallengeSnapshotTotalsDto;

  @ApiPropertyOptional({ example: '2026-05-19T10:00:00.000Z' })
  lastUpdatedAt?: string;
}
