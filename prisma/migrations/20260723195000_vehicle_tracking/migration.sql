ALTER TABLE "vehicles"
  ADD COLUMN "assetType" TEXT NOT NULL DEFAULT 'truck',
  ADD COLUMN "trackingProvider" TEXT,
  ADD COLUMN "trackingExternalId" TEXT,
  ADD COLUMN "trackingLatitude" DOUBLE PRECISION,
  ADD COLUMN "trackingLongitude" DOUBLE PRECISION,
  ADD COLUMN "trackingSpeed" DOUBLE PRECISION,
  ADD COLUMN "trackingHeading" DOUBLE PRECISION,
  ADD COLUMN "trackingStatus" TEXT,
  ADD COLUMN "trackingAddress" TEXT,
  ADD COLUMN "trackingLastSeenAt" TIMESTAMP(3);

CREATE INDEX "vehicles_organizationId_assetType_idx"
  ON "vehicles"("organizationId", "assetType");
