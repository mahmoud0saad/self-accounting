import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class UpsertChallengeWeekDto {
  @ApiProperty({ example: '2026-05-23' })
  @IsString()
  weekEnd!: string;

  @ApiProperty({ example: 7 })
  @IsInt()
  @Min(1)
  goalCount!: number;

  @ApiProperty({ example: 3 })
  @IsInt()
  @Min(0)
  achievedCount!: number;

  @ApiProperty({ example: 'IN_PROGRESS' })
  @IsString()
  status!: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  completedAt?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  celebrationSeenAt?: string;
}
