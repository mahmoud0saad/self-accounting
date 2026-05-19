import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class CreateUserCategoryDto {
  @IsString()
  name!: string;

  @IsString()
  icon!: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  sortOrder?: number;
}
