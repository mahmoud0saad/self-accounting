import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsISO8601,
  IsObject,
  IsString,
  ValidateNested,
} from 'class-validator';

export class ChallengeBatchOpDto {
  @ApiProperty({ example: 'op-1' })
  @IsString()
  opId!: string;

  @ApiProperty({ example: 'upsert_user_challenge' })
  @IsString()
  opType!: string;

  @ApiProperty()
  @IsObject()
  payload!: Record<string, unknown>;

  @ApiProperty({ example: '2026-05-19T10:00:00.000Z' })
  @IsISO8601()
  clientUpdatedAt!: string;
}

export class ChallengeBatchDto {
  @ApiProperty({ type: [ChallengeBatchOpDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ChallengeBatchOpDto)
  ops!: ChallengeBatchOpDto[];
}
