import { IsBoolean, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class UpdateUserCategoryDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsString()
  icon?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;

  /** When true, clears [archivedAt] and shows the category again. */
  @IsOptional()
  @IsBoolean()
  restore?: boolean;
}
