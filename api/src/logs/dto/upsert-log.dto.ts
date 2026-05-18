import { IsBoolean, IsDateString, IsString, MinLength } from 'class-validator';

export class UpsertLogDto {
  @IsDateString()
  date!: string;

  @IsString()
  @MinLength(1)
  taskId!: string;

  @IsBoolean()
  completed!: boolean;

  @IsDateString()
  updatedAt!: string;
}
