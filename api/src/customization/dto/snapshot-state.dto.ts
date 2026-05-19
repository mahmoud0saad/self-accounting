import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SnapshotTotalsDto {
  @ApiProperty({ example: 2 })
  userCategories!: number;

  @ApiProperty({ example: 5 })
  userTasks!: number;

  @ApiProperty({ example: 1 })
  categoryOverrides!: number;

  @ApiProperty({ example: 3 })
  taskOverrides!: number;
}

export class SnapshotStateDto {
  @ApiProperty({ example: true })
  hasSnapshot!: boolean;

  @ApiProperty({ type: SnapshotTotalsDto })
  totals!: SnapshotTotalsDto;

  @ApiPropertyOptional({
    example: '2026-05-19T10:00:00.000Z',
    description:
      'Latest updatedAt across customization tables; omitted when empty.',
  })
  lastUpdatedAt?: string;
}
