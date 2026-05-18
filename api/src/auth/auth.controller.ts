import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  Res,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import type { Response } from 'express';
import { Throttle } from '@nestjs/throttler';
import { Public } from '../common/decorators/public.decorator';
import { AuthService } from './auth.service';
import {
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

  @Get('confirm')
  async confirm(
    @Query('token') token: string,
    @Res() res: Response,
  ): Promise<void> {
    const result = await this.auth.confirmEmail(token ?? '');
    const title = result.already
      ? 'Already confirmed'
      : 'Email confirmed';
    const body = result.already
      ? 'Your email was already confirmed. You can return to Muhasabah and sign in.'
      : 'Thank you. Your email is confirmed. You can return to Muhasabah and sign in.';
    res
      .status(HttpStatus.OK)
      .type('html')
      .send(`<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"/><title>${title}</title>
<style>body{font-family:system-ui,sans-serif;max-width:32rem;margin:4rem auto;padding:0 1rem;color:#2d4a38;background:#f7fbf8;}
h1{font-weight:600;font-size:1.5rem;}p{line-height:1.6;color:#4a6356;}</style></head>
<body><h1>${title}</h1><p>${body}</p></body></html>`);
  }
}
