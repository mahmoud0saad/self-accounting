import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class PatchChallengeDto {
  @ApiPropertyOptional({ nullable: true })
  @IsOptional()
  archivedAt?: string | null;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  customTitle?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  customIcon?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(7)
  customGoalCount?: number;
}
