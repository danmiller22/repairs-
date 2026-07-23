import { PrismaClient } from "@/generated/prisma/client";
import { getConnectionString } from "@netlify/database";
import { PrismaPg } from "@prisma/adapter-pg";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

function createPrismaClient() {
  let connectionString: string | undefined;
  try {
    connectionString = getConnectionString();
  } catch {
    connectionString =
      process.env.NETLIFY_DB_URL ?? process.env.DATABASE_URL;
  }

  const adapter = new PrismaPg({
    connectionString,
    max: 10,
    connectionTimeoutMillis: 5000,
    idleTimeoutMillis: 30000,
  });
  return new PrismaClient({
    adapter,
    log: process.env.NODE_ENV === "development" ? ["warn", "error"] : ["error"],
  });
}

export const db = globalForPrisma.prisma ?? createPrismaClient();

globalForPrisma.prisma = db;
