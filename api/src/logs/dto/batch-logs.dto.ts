import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsBoolean,
  IsDateString,
  IsString,
  Matches,
  ValidateNested,
} from 'class-validator';

export class BatchLogItemDto {
  @ApiProperty({ example: '2026-05-18' })
  @Matches(/^\d{4}-\d{2}-\d{2}$/)
  date!: string;

  @ApiProperty({ example: 'fajr_waking_up_adhkar' })
  @IsString()
  taskId!: string;

  @ApiProperty()
  @IsBoolean()
  completed!: boolean;

  @ApiProperty({ example: '2026-05-18T10:30:00.000Z' })
  @IsDateString()
  clientUpdatedAt!: string;
}

export class BatchLogsDto {
  @ApiProperty({ type: [BatchLogItemDto] })
  @IsArray()
  @ArrayMaxSize(500)
  @ValidateNested({ each: true })
  @Type(() => BatchLogItemDto)
  items!: BatchLogItemDto[];
}
