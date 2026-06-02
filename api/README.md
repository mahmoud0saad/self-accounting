<p align="center">
  <a href="http://nestjs.com/" target="blank"><img src="https://nestjs.com/img/logo-small.svg" width="120" alt="Nest Logo" /></a>
</p>

[circleci-image]: https://img.shields.io/circleci/build/github/nestjs/nest/master?token=abc123def456
[circleci-url]: https://circleci.com/gh/nestjs/nest

  <p align="center">A progressive <a href="http://nodejs.org" target="_blank">Node.js</a> framework for building efficient and scalable server-side applications.</p>
    <p align="center">
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://discord.gg/G7Qnnhy" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://opencollective.com/nest#backer" target="_blank"><img src="https://opencollective.com/nest/backers/badge.svg" alt="Backers on Open Collective" /></a>
<a href="https://opencollective.com/nest#sponsor" target="_blank"><img src="https://opencollective.com/nest/sponsors/badge.svg" alt="Sponsors on Open Collective" /></a>
  <a href="https://paypal.me/kamilmysliwiec" target="_blank"><img src="https://img.shields.io/badge/Donate-PayPal-ff3f59.svg" alt="Donate us"/></a>
    <a href="https://opencollective.com/nest#sponsor"  target="_blank"><img src="https://img.shields.io/badge/Support%20us-Open%20Collective-41B883.svg" alt="Support us"></a>
  <a href="https://twitter.com/nestframework" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow" alt="Follow us on Twitter"></a>
</p>
  <!--[![Backers on Open Collective](https://opencollective.com/nest/backers/badge.svg)](https://opencollective.com/nest#backer)
  [![Sponsors on Open Collective](https://opencollective.com/nest/sponsors/badge.svg)](https://opencollective.com/nest#sponsor)-->

## Description

Muhasabah REST API (NestJS + Prisma + MySQL). Phase 6 adds optional email/password auth, SMTP confirmation, and sync endpoints under `/v1`.

## Local setup (Phase 6)

1. Copy `.env.example` → `.env` and set `DATABASE_URL`, JWT secrets, and mail vars (`MAIL_PROVIDER`, SMTP or Resend).
2. Start MySQL **in the background** (keeps running while you use another terminal):

```bash
npm run db:up
```

From repo root you can instead run `docker compose up -d --wait`. Do **not** use bare `docker compose up` in the foreground — stopping that terminal (Ctrl+C) shuts MySQL down and Prisma will fail with `P1001`.

3. Apply migrations and seed default tasks:

```bash
npm install
npm run prisma:migrate:deploy
npm run prisma:seed
```

4. Run the API: `npm run start:dev` → `http://localhost:3000/v1/health`, OpenAPI at `/v1/docs`.

### Weekly challenges (`/v1/challenges/*`, Phase 9)

Three MySQL tables: `challenge_templates` (seeded catalog), `user_challenges` (subscriptions / custom definitions), `user_challenge_weeks` (per-week `achieved_count`, `status`, `celebration_seen_at`).

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/v1/challenges/templates` | List active templates |
| GET | `/v1/challenges` | List user subscriptions (+ week rows) |
| POST | `/v1/challenges` | Subscribe to template or create custom |
| PATCH | `/v1/challenges/:id` | Archive/un-archive or edit custom fields |
| PUT | `/v1/challenges/:id/weeks/:weekStart` | Upsert weekly progress |
| GET | `/v1/challenges/snapshot-state` | Cheap restore head-check |
| PUT | `/v1/challenges/batch` | Sync queue drain (`upsert_user_challenge`, `upsert_user_challenge_week`, …) |

### Email (`MAIL_PROVIDER`)

Default is `smtp`. Set `MAIL_PROVIDER=resend` to use [Resend](https://resend.com) instead (keep SMTP vars in `.env` if you switch back).

| Provider | Required vars |
|----------|----------------|
| `smtp` (default) | `SMTP_HOST`, `SMTP_USER`, `SMTP_PASSWORD` |
| `resend` | `RESEND_API_KEY`, `RESEND_FROM` (verified domain or `onboarding@resend.dev` for testing) |

Registration sends a **6-digit code** (15 min TTL); the user enters it in the app via `POST /v1/auth/confirm-email`.

#### Gmail SMTP (anti.mahmoud.saad.6@gmail.com)

Use a [Google App Password](https://support.google.com/accounts/answer/185833) (2FA required). Set `SMTP_USER` and `SMTP_PASSWORD`.

#### Resend

Set `MAIL_PROVIDER=resend`, `RESEND_API_KEY` to your key from the Resend dashboard, and `RESEND_FROM` to a verified sender address.

## Project setup

```bash
$ npm install
```

## Compile and run the project

```bash
# development
$ npm run start

# watch mode
$ npm run start:dev

# production mode
$ npm run start:prod
```

## Run tests

```bash
# unit tests
$ npm run test

# e2e tests
$ npm run test:e2e

# test coverage
$ npm run test:cov
```

## Deployment

When you're ready to deploy your NestJS application to production, there are some key steps you can take to ensure it runs as efficiently as possible. Check out the [deployment documentation](https://docs.nestjs.com/deployment) for more information.

If you are looking for a cloud-based platform to deploy your NestJS application, check out [Mau](https://mau.nestjs.com), our official platform for deploying NestJS applications on AWS. Mau makes deployment straightforward and fast, requiring just a few simple steps:

```bash
$ npm install -g @nestjs/mau
$ mau deploy
```

With Mau, you can deploy your application in just a few clicks, allowing you to focus on building features rather than managing infrastructure.

## Resources

Check out a few resources that may come in handy when working with NestJS:

- Visit the [NestJS Documentation](https://docs.nestjs.com) to learn more about the framework.
- For questions and support, please visit our [Discord channel](https://discord.gg/G7Qnnhy).
- To dive deeper and get more hands-on experience, check out our official video [courses](https://courses.nestjs.com/).
- Deploy your application to AWS with the help of [NestJS Mau](https://mau.nestjs.com) in just a few clicks.
- Visualize your application graph and interact with the NestJS application in real-time using [NestJS Devtools](https://devtools.nestjs.com).
- Need help with your project (part-time to full-time)? Check out our official [enterprise support](https://enterprise.nestjs.com).
- To stay in the loop and get updates, follow us on [X](https://x.com/nestframework) and [LinkedIn](https://linkedin.com/company/nestjs).
- Looking for a job, or have a job to offer? Check out our official [Jobs board](https://jobs.nestjs.com).

## Support

Nest is an MIT-licensed open source project. It can grow thanks to the sponsors and support by the amazing backers. If you'd like to join them, please [read more here](https://docs.nestjs.com/support).

## Stay in touch

- Author - [Kamil Myśliwiec](https://twitter.com/kammysliwiec)
- Website - [https://nestjs.com](https://nestjs.com/)
- Twitter - [@nestframework](https://twitter.com/nestframework)

## License

Nest is [MIT licensed](https://github.com/nestjs/nest/blob/master/LICENSE).
