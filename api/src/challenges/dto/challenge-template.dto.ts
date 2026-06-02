import { ApiProperty } from '@nestjs/swagger';

export class ChallengeTemplateDto {
  @ApiProperty({ example: 'fajr_in_jamaah' })
  code!: string;

  @ApiProperty({ example: 'Pray every Fajr in congregation' })
  defaultTitle!: string;

  @ApiProperty({ example: 'groups' })
  defaultIcon!: string;

  @ApiProperty({ example: 'TASK_WEEKLY_COUNT' })
  sourceKind!: string;

  @ApiProperty({ example: 'fajr_first_congregation' })
  sourceRef!: string;

  @ApiProperty({ example: 7 })
  goalCount!: number;

  @ApiProperty({ example: 0 })
  defaultSortOrder!: number;

  @ApiProperty({ example: true })
  isActive!: boolean;
}
