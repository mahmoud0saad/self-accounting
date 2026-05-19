import { Body, Controller, HttpCode, HttpStatus, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { Public } from '../common/decorators/public.decorator';
import { AuthService } from './auth.service';
import {
  ConfirmEmailCodeDto,
  LoginDto,
  RefreshDto,
  RegisterDto,
  ResendConfirmationDto,
} from './dto/register.dto';

@ApiTags('auth')
@Controller('auth')
@Public()
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  register(@Body() dto: RegisterDto) {
    return this.auth.register(dto);
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: 900_000 } })
  login(@Body() dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Body() dto: RefreshDto) {
    return this.auth.refresh(dto);
  }

  @Post('logout')
  @HttpCode(HttpStatus.NO_CONTENT)
  async logout(@Body() dto: RefreshDto): Promise<void> {
    await this.auth.logout(dto.refreshToken);
  }

  @Post('resend-confirmation')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 1, ttl: 60_000 } })
  resend(@Body() dto: ResendConfirmationDto) {
    return this.auth.resendConfirmation(dto.email);
  }

  @Post('confirm-email')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 10, ttl: 900_000 } })
  confirmEmail(@Body() dto: ConfirmEmailCodeDto) {
    return this.auth.confirmEmailWithCode(dto);
  }
}
