import { PrismaClient } from '@prisma/client';
import { defaultCategoriesSeed, defaultTasksSeed } from './seed-data';

const prisma = new PrismaClient();

async function main() {
  for (const cat of defaultCategoriesSeed) {
    await prisma.category.upsert({
      where: { code: cat.code },
      create: {
        code: cat.code,
        defaultName: cat.defaultName,
        defaultIcon: cat.defaultIcon,
        defaultSortOrder: cat.defaultSortOrder,
        isFard: cat.isFard,
      },
      update: {
        defaultName: cat.defaultName,
        defaultIcon: cat.defaultIcon,
        defaultSortOrder: cat.defaultSortOrder,
        isFard: cat.isFard,
      },
    });
  }
  console.log(`Seeded ${defaultCategoriesSeed.length} categories.`);

  for (const task of defaultTasksSeed) {
    await prisma.task.upsert({
      where: { id: task.id },
      create: {
        id: task.id,
        categoryCode: task.categoryCode,
        defaultPoints: task.defaultPoints,
        defaultIcon: 'star',
        defaultSortOrder: task.defaultSortOrder,
        isDefault: true,
      },
      update: {
        categoryCode: task.categoryCode,
        defaultPoints: task.defaultPoints,
        defaultSortOrder: task.defaultSortOrder,
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
