import { PrismaClient } from '@prisma/client';
import { defaultTaskCatalog } from './default-task-catalog';

const prisma = new PrismaClient();

async function main() {
  for (const task of defaultTaskCatalog) {
    await prisma.task.upsert({
      where: { id: task.id },
      create: {
        id: task.id,
        name: task.id,
        category: task.category,
        points: task.points,
        isDefault: true,
        userId: null,
      },
      update: {
        name: task.id,
        category: task.category,
        points: task.points,
        isDefault: true,
        userId: null,
      },
    });
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
