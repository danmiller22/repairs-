ALTER TABLE public.vehicles
  ADD COLUMN "assetType" text NOT NULL DEFAULT 'truck',
  ADD COLUMN "trackingProvider" text,
  ADD COLUMN "trackingExternalId" text,
  ADD COLUMN "trackingLatitude" double precision,
  ADD COLUMN "trackingLongitude" double precision,
  ADD COLUMN "trackingSpeed" double precision,
  ADD COLUMN "trackingHeading" double precision,
  ADD COLUMN "trackingStatus" text,
  ADD COLUMN "trackingAddress" text,
  ADD COLUMN "trackingLastSeenAt" timestamp(3) without time zone;

CREATE INDEX "vehicles_organizationId_assetType_idx"
  ON public.vehicles USING btree ("organizationId", "assetType");
