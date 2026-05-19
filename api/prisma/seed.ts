import { PrismaClient } from '@prisma/client';
import { defaultTasksSeed } from './seed-data';

const prisma = new PrismaClient();

async function main() {
  for (const task of defaultTasksSeed) {
    await prisma.task.upsert({
      where: { id: task.id },
      create: {
        id: task.id,
        category: task.category,
        defaultPoints: task.defaultPoints,
        isDefault: true,
      },
      update: {
        category: task.category,
        defaultPoints: task.defaultPoints,
        isDefault: true,
      },
    });
  }
  console.log(`Seeded ${defaultTasksSeed.length} default tasks.`);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
