import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from './../src/app.module';

describe('Health (e2e)', () => {
  let app: INestApplication<App>;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('v1');
    await app.init();
  });

  it('/health (GET) without /v1 prefix returns 404', () => {
    return request(app.getHttpServer()).get('/health').expect(404);
  });

  it('/v1/health (GET) returns JSON health payload', async () => {
    const res = await request(app.getHttpServer())
      .get('/v1/health')
      .expect(200);
    const body = res.body as {
      status: string;
      uptime: number;
      db: string;
    };
    expect(body.status).toBe('ok');
    expect(typeof body.uptime).toBe('number');
    expect(['up', 'down']).toContain(body.db);
  });

  afterEach(async () => {
    await app.close();
  });
});
