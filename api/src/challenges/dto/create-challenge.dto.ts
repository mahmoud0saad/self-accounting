import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsInt, IsOptional, IsString, Min, ValidateIf } from 'class-validator';

export class CreateChallengeDto {
  @ApiPropertyOptional({ example: 'fajr_in_jamaah' })
  @ValidateIf((o: CreateChallengeDto) => o.customTitle == null)
  @IsString()
  templateCode?: string;

  @ApiPropertyOptional({ example: 'Memorize 3 ayat' })
  @ValidateIf((o: CreateChallengeDto) => o.templateCode == null)
  @IsString()
  customTitle?: string;

  @ApiPropertyOptional({ example: 'auto_stories' })
  @ValidateIf((o: CreateChallengeDto) => o.templateCode == null)
  @IsString()
  customIcon?: string;

  @ApiPropertyOptional({ example: 'TASK_WEEKLY_COUNT' })
  @ValidateIf((o: CreateChallengeDto) => o.templateCode == null)
  @IsString()
  customSourceKind?: string;

  @ApiPropertyOptional({ example: 'quran_read_six_quarters' })
  @ValidateIf((o: CreateChallengeDto) => o.templateCode == null)
  @IsString()
  customSourceRef?: string;

  @ApiPropertyOptional({ example: 5 })
  @ValidateIf((o: CreateChallengeDto) => o.templateCode == null)
  @IsInt()
  @Min(1)
  customGoalCount?: number;
}
