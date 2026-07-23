--
-- PostgreSQL database dump
--


-- Dumped from database version 17.10
-- Dumped by pg_dump version 17.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.accounts (
    id text NOT NULL,
    "accountId" text NOT NULL,
    "providerId" text NOT NULL,
    "userId" text NOT NULL,
    "accessToken" text,
    "refreshToken" text,
    "idToken" text,
    "accessTokenExpiresAt" timestamp(3) without time zone,
    "refreshTokenExpiresAt" timestamp(3) without time zone,
    scope text,
    password text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: ai_chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_chat_messages (
    id text NOT NULL,
    role text NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "chatId" text NOT NULL
);


--
-- Name: ai_chats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_chats (
    id text NOT NULL,
    title text DEFAULT 'New chat'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text NOT NULL
);


--
-- Name: ai_generated_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_generated_messages (
    id text NOT NULL,
    "vehicleId" text NOT NULL,
    type text NOT NULL,
    content text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: app_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_settings (
    id text NOT NULL,
    key text NOT NULL,
    value text NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text
);


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_logs (
    id text NOT NULL,
    "timestamp" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    action text NOT NULL,
    entity text,
    "entityId" text,
    message text,
    metadata jsonb,
    ip text,
    "userAgent" text,
    "userId" text,
    "organizationId" text
);


--
-- Name: custom_field_definitions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_field_definitions (
    id text NOT NULL,
    name text NOT NULL,
    label text NOT NULL,
    "fieldType" text DEFAULT 'text'::text NOT NULL,
    options text,
    required boolean DEFAULT false NOT NULL,
    "entityType" text NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text
);


--
-- Name: custom_field_values; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_field_values (
    id text NOT NULL,
    value text NOT NULL,
    "entityId" text NOT NULL,
    "entityType" text NOT NULL,
    "fieldId" text NOT NULL
);


--
-- Name: customer_magic_links; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_magic_links (
    id text NOT NULL,
    token text NOT NULL,
    email text NOT NULL,
    "organizationId" text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "usedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customer_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_sessions (
    id text NOT NULL,
    token text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "customerId" text NOT NULL,
    "organizationId" text NOT NULL
);


--
-- Name: customer_sms_codes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customer_sms_codes (
    id text NOT NULL,
    code text NOT NULL,
    phone text NOT NULL,
    "organizationId" text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "usedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: customers; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.customers (
    id text NOT NULL,
    name text NOT NULL,
    email text,
    phone text,
    address text,
    company text,
    notes text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text,
    "telegramChatId" text,
    "taxExempt" boolean DEFAULT false NOT NULL,
    "taxId" text
);


--
-- Name: fuel_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fuel_logs (
    id text NOT NULL,
    date timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    mileage integer NOT NULL,
    gallons double precision NOT NULL,
    "pricePerGallon" double precision NOT NULL,
    "totalCost" double precision NOT NULL,
    "isFillUp" boolean DEFAULT true NOT NULL,
    station text,
    notes text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "vehicleId" text NOT NULL
);


--
-- Name: inspection_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_items (
    id text NOT NULL,
    name text NOT NULL,
    section text NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    condition text DEFAULT 'not_inspected'::text NOT NULL,
    notes text,
    "imageUrls" text[] DEFAULT ARRAY[]::text[],
    "inspectionId" text NOT NULL
);


--
-- Name: inspection_quote_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_quote_requests (
    id text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    message text,
    "selectedItemIds" text[],
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "inspectionId" text NOT NULL,
    "organizationId" text NOT NULL
);


--
-- Name: inspection_template_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_template_items (
    id text NOT NULL,
    name text NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "sectionId" text NOT NULL
);


--
-- Name: inspection_template_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_template_sections (
    id text NOT NULL,
    name text NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "templateId" text NOT NULL
);


--
-- Name: inspection_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspection_templates (
    id text NOT NULL,
    name text NOT NULL,
    description text,
    "isDefault" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "organizationId" text NOT NULL
);


--
-- Name: inspections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inspections (
    id text NOT NULL,
    status text DEFAULT 'in_progress'::text NOT NULL,
    mileage integer,
    notes text,
    "publicToken" text,
    "completedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "vehicleId" text NOT NULL,
    "templateId" text NOT NULL,
    "technicianId" text,
    "organizationId" text NOT NULL,
    "endDateTime" timestamp(3) without time zone,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "startDateTime" timestamp(3) without time zone
);


--
-- Name: inventory_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.inventory_parts (
    id text NOT NULL,
    "partNumber" text,
    name text NOT NULL,
    description text,
    category text,
    quantity integer DEFAULT 0 NOT NULL,
    "minQuantity" integer DEFAULT 0 NOT NULL,
    "unitCost" double precision DEFAULT 0 NOT NULL,
    "sellPrice" double precision DEFAULT 0 NOT NULL,
    supplier text,
    "supplierPhone" text,
    "supplierEmail" text,
    "supplierUrl" text,
    "imageUrl" text,
    location text,
    "isArchived" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text,
    barcode text
);


--
-- Name: labor_preset_items; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labor_preset_items (
    id text NOT NULL,
    description text NOT NULL,
    hours double precision DEFAULT 0 NOT NULL,
    rate double precision DEFAULT 0 NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "presetId" text NOT NULL,
    "pricingType" text DEFAULT 'hourly'::text NOT NULL
);


--
-- Name: labor_preset_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labor_preset_parts (
    id text NOT NULL,
    name text NOT NULL,
    "partNumber" text,
    quantity double precision DEFAULT 1 NOT NULL,
    "unitPrice" double precision DEFAULT 0 NOT NULL,
    "inventoryPartId" text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "presetId" text NOT NULL
);


--
-- Name: labor_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labor_presets (
    id text NOT NULL,
    name text NOT NULL,
    description text,
    "isArchived" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text NOT NULL
);


--
-- Name: notes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notes (
    id text NOT NULL,
    title text NOT NULL,
    content text NOT NULL,
    "isPinned" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "vehicleId" text NOT NULL
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id text NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    "entityType" text NOT NULL,
    "entityId" text NOT NULL,
    "entityUrl" text NOT NULL,
    read boolean DEFAULT false NOT NULL,
    "organizationId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: organization_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organization_members (
    id text NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text NOT NULL,
    "roleId" text
);


--
-- Name: organizations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.organizations (
    id text NOT NULL,
    name text NOT NULL,
    "portalSlug" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: passkeys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.passkeys (
    id text NOT NULL,
    name text,
    "publicKey" text NOT NULL,
    "userId" text NOT NULL,
    "credentialID" text NOT NULL,
    counter integer NOT NULL,
    "deviceType" text NOT NULL,
    "backedUp" boolean NOT NULL,
    transports text,
    aaguid text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id text NOT NULL,
    amount double precision NOT NULL,
    date timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    method text DEFAULT 'other'::text NOT NULL,
    note text,
    provider text,
    "externalId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "serviceRecordId" text NOT NULL
);


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id text NOT NULL,
    action text NOT NULL,
    subject text NOT NULL,
    "roleId" text NOT NULL
);


--
-- Name: quote_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quote_attachments (
    id text NOT NULL,
    "fileName" text NOT NULL,
    "fileUrl" text NOT NULL,
    "fileType" text NOT NULL,
    "fileSize" integer NOT NULL,
    category text DEFAULT 'image'::text NOT NULL,
    description text,
    "includeInInvoice" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "quoteId" text NOT NULL
);


--
-- Name: quote_labor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quote_labor (
    id text NOT NULL,
    description text NOT NULL,
    hours double precision DEFAULT 0 NOT NULL,
    rate double precision DEFAULT 0 NOT NULL,
    total double precision DEFAULT 0 NOT NULL,
    excluded boolean DEFAULT false NOT NULL,
    "quoteId" text NOT NULL,
    "pricingType" text DEFAULT 'hourly'::text NOT NULL
);


--
-- Name: quote_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quote_parts (
    id text NOT NULL,
    "partNumber" text,
    name text NOT NULL,
    quantity double precision DEFAULT 1 NOT NULL,
    "unitPrice" double precision DEFAULT 0 NOT NULL,
    total double precision DEFAULT 0 NOT NULL,
    excluded boolean DEFAULT false NOT NULL,
    "quoteId" text NOT NULL
);


--
-- Name: quotes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.quotes (
    id text NOT NULL,
    "quoteNumber" text,
    title text NOT NULL,
    description text,
    status text DEFAULT 'draft'::text NOT NULL,
    "validUntil" timestamp(3) without time zone,
    subtotal double precision DEFAULT 0 NOT NULL,
    "taxRate" double precision DEFAULT 0 NOT NULL,
    "taxAmount" double precision DEFAULT 0 NOT NULL,
    "discountType" text,
    "discountValue" double precision DEFAULT 0 NOT NULL,
    "discountAmount" double precision DEFAULT 0 NOT NULL,
    "totalAmount" double precision DEFAULT 0 NOT NULL,
    notes text,
    "publicToken" text,
    "sharedAt" timestamp(3) without time zone,
    "viewCount" integer DEFAULT 0 NOT NULL,
    "lastViewedAt" timestamp(3) without time zone,
    "customerMessage" text,
    "convertedToId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text,
    "customerId" text,
    "vehicleId" text,
    "inspectionId" text,
    "taxInclusive" boolean DEFAULT false NOT NULL
);


--
-- Name: recurring_invoices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurring_invoices (
    id text NOT NULL,
    title text NOT NULL,
    description text,
    frequency text NOT NULL,
    "nextRunDate" timestamp(3) without time zone NOT NULL,
    "endDate" timestamp(3) without time zone,
    "isActive" boolean DEFAULT true NOT NULL,
    "lastRunAt" timestamp(3) without time zone,
    "runCount" integer DEFAULT 0 NOT NULL,
    type text DEFAULT 'maintenance'::text NOT NULL,
    cost double precision DEFAULT 0 NOT NULL,
    "taxRate" double precision DEFAULT 0 NOT NULL,
    "invoiceNotes" text,
    "vehicleId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "taxInclusive" boolean DEFAULT false NOT NULL
);


--
-- Name: recurring_labor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurring_labor (
    id text NOT NULL,
    description text NOT NULL,
    hours double precision DEFAULT 0 NOT NULL,
    rate double precision DEFAULT 0 NOT NULL,
    "recurringInvoiceId" text NOT NULL,
    "pricingType" text DEFAULT 'hourly'::text NOT NULL
);


--
-- Name: recurring_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recurring_parts (
    id text NOT NULL,
    name text NOT NULL,
    "partNumber" text,
    quantity integer DEFAULT 1 NOT NULL,
    "unitPrice" double precision DEFAULT 0 NOT NULL,
    "recurringInvoiceId" text NOT NULL
);


--
-- Name: reminders; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reminders (
    id text NOT NULL,
    title text NOT NULL,
    description text,
    "dueDate" timestamp(3) without time zone,
    "dueMileage" integer,
    "isCompleted" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "vehicleId" text NOT NULL
);


--
-- Name: report_schedules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.report_schedules (
    id text NOT NULL,
    name text DEFAULT 'Scheduled Report'::text NOT NULL,
    frequency text NOT NULL,
    "dateRange" text DEFAULT 'last30d'::text NOT NULL,
    sections text NOT NULL,
    recipients text NOT NULL,
    "nextRunDate" timestamp(3) without time zone NOT NULL,
    "endDate" timestamp(3) without time zone,
    "isActive" boolean DEFAULT true NOT NULL,
    "lastRunAt" timestamp(3) without time zone,
    "runCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "organizationId" text NOT NULL,
    "createdById" text NOT NULL
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id text NOT NULL,
    name text NOT NULL,
    "isAdmin" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "organizationId" text NOT NULL
);


--
-- Name: service_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_attachments (
    id text NOT NULL,
    "fileName" text NOT NULL,
    "fileUrl" text NOT NULL,
    "fileType" text NOT NULL,
    "fileSize" integer NOT NULL,
    category text DEFAULT 'diagnostic'::text NOT NULL,
    description text,
    "includeInInvoice" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "serviceRecordId" text NOT NULL
);


--
-- Name: service_labor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_labor (
    id text NOT NULL,
    description text NOT NULL,
    hours double precision DEFAULT 0 NOT NULL,
    rate double precision DEFAULT 0 NOT NULL,
    total double precision DEFAULT 0 NOT NULL,
    "serviceRecordId" text NOT NULL,
    "pricingType" text DEFAULT 'hourly'::text NOT NULL
);


--
-- Name: service_parts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_parts (
    id text NOT NULL,
    "partNumber" text,
    name text NOT NULL,
    quantity double precision DEFAULT 1 NOT NULL,
    "unitPrice" double precision DEFAULT 0 NOT NULL,
    total double precision DEFAULT 0 NOT NULL,
    "serviceRecordId" text NOT NULL,
    "inventoryPartId" text,
    "unitCost" double precision DEFAULT 0 NOT NULL,
    "markupPercent" double precision DEFAULT 0 NOT NULL
);


--
-- Name: service_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_records (
    id text NOT NULL,
    title text NOT NULL,
    description text,
    type text DEFAULT 'maintenance'::text NOT NULL,
    status text DEFAULT 'completed'::text NOT NULL,
    cost double precision DEFAULT 0 NOT NULL,
    mileage integer,
    "serviceDate" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "shopName" text,
    "techName" text,
    parts text,
    "laborHours" double precision,
    "diagnosticNotes" text,
    "invoiceNotes" text,
    subtotal double precision DEFAULT 0 NOT NULL,
    "taxRate" double precision DEFAULT 0 NOT NULL,
    "taxAmount" double precision DEFAULT 0 NOT NULL,
    "totalAmount" double precision DEFAULT 0 NOT NULL,
    "invoiceNumber" text,
    "discountType" text,
    "discountValue" double precision DEFAULT 0 NOT NULL,
    "discountAmount" double precision DEFAULT 0 NOT NULL,
    "manuallyPaid" boolean DEFAULT false NOT NULL,
    "publicToken" text,
    "sharedAt" timestamp(3) without time zone,
    "viewCount" integer DEFAULT 0 NOT NULL,
    "lastViewedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "vehicleId" text NOT NULL,
    "endDateTime" timestamp(3) without time zone,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "startDateTime" timestamp(3) without time zone,
    "technicianId" text,
    "invoiceDate" timestamp(3) without time zone,
    "invoiceDueDate" timestamp(3) without time zone,
    "taxInclusive" boolean DEFAULT false NOT NULL,
    "warrantyExpiresAt" timestamp(3) without time zone,
    "warrantyMileage" integer,
    "warrantyMonths" integer,
    "warrantyNotes" text
);


--
-- Name: service_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.service_requests (
    id text NOT NULL,
    description text NOT NULL,
    "preferredDate" timestamp(3) without time zone,
    status text DEFAULT 'pending'::text NOT NULL,
    "adminNotes" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "customerId" text NOT NULL,
    "vehicleId" text NOT NULL,
    "organizationId" text NOT NULL
);


--
-- Name: sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sessions (
    id text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    token text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "ipAddress" text,
    "userAgent" text,
    "userId" text NOT NULL
);


--
-- Name: sms_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sms_messages (
    id text NOT NULL,
    direction text NOT NULL,
    "fromNumber" text NOT NULL,
    "toNumber" text NOT NULL,
    body text NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL,
    "providerMsgId" text,
    "errorMessage" text,
    "relatedEntityType" text,
    "relatedEntityId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "organizationId" text NOT NULL,
    "customerId" text
);


--
-- Name: status_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_reports (
    id text NOT NULL,
    title text,
    message text,
    "videoUrl" text,
    "videoFileName" text,
    "publicToken" text NOT NULL,
    status text DEFAULT 'draft'::text NOT NULL,
    "sentVia" text,
    "sentAt" timestamp(3) without time zone,
    "viewedAt" timestamp(3) without time zone,
    "customerFeedback" text,
    "feedbackAt" timestamp(3) without time zone,
    "expiresAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "serviceRecordId" text NOT NULL,
    "organizationId" text NOT NULL,
    "technicianId" text
);


--
-- Name: stored_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stored_files (
    id text NOT NULL,
    "organizationId" text NOT NULL,
    category text NOT NULL,
    filename text NOT NULL,
    "originalName" text NOT NULL,
    "contentType" text NOT NULL,
    "fileSize" integer NOT NULL,
    data bytea NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: stored_images; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.stored_images (
    id text NOT NULL,
    url text NOT NULL,
    "fileName" text,
    description text,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "inventoryPartId" text
);


--
-- Name: subscription_plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscription_plans (
    id text NOT NULL,
    name text NOT NULL,
    "stripePriceId" text,
    price double precision DEFAULT 0 NOT NULL,
    "interval" text DEFAULT 'month'::text NOT NULL,
    "maxMembers" integer DEFAULT 1 NOT NULL,
    features text,
    "isActive" boolean DEFAULT true NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL
);


--
-- Name: subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.subscriptions (
    id text NOT NULL,
    status text DEFAULT 'active'::text NOT NULL,
    "stripeSubscriptionId" text,
    "stripeCustomerId" text,
    "currentPeriodStart" timestamp(3) without time zone,
    "currentPeriodEnd" timestamp(3) without time zone,
    "cancelAtPeriodEnd" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "organizationId" text NOT NULL,
    "planId" text NOT NULL
);


--
-- Name: system_settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_settings (
    id text NOT NULL,
    key text NOT NULL,
    value text NOT NULL
);


--
-- Name: team_invitations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.team_invitations (
    id text NOT NULL,
    email text NOT NULL,
    role text DEFAULT 'member'::text NOT NULL,
    token text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "organizationId" text NOT NULL,
    "invitedById" text NOT NULL,
    "roleId" text
);


--
-- Name: technicians; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.technicians (
    id text NOT NULL,
    name text NOT NULL,
    color text DEFAULT '#3b82f6'::text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    "sortOrder" integer DEFAULT 0 NOT NULL,
    "organizationId" text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "dailyCapacity" integer DEFAULT 480 NOT NULL,
    "userId" text
);


--
-- Name: telegram_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.telegram_messages (
    id text NOT NULL,
    direction text NOT NULL,
    "chatId" text NOT NULL,
    body text NOT NULL,
    status text DEFAULT 'queued'::text NOT NULL,
    "telegramMessageId" text,
    "errorMessage" text,
    "relatedEntityType" text,
    "relatedEntityId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "organizationId" text NOT NULL,
    "customerId" text
);


--
-- Name: two_factor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.two_factor (
    id text NOT NULL,
    secret text NOT NULL,
    "backupCodes" text NOT NULL,
    "userId" text NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id text NOT NULL,
    name text NOT NULL,
    email text NOT NULL,
    "emailVerified" boolean DEFAULT false NOT NULL,
    image text,
    "isSuperAdmin" boolean DEFAULT false NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "twoFactorEnabled" boolean DEFAULT false NOT NULL,
    "termsAcceptedAt" timestamp(3) without time zone,
    "lastLogin" timestamp(3) without time zone,
    "lastSeen" timestamp(3) without time zone
);


--
-- Name: vehicle_findings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicle_findings (
    id text NOT NULL,
    description text NOT NULL,
    severity text DEFAULT 'needs_work'::text NOT NULL,
    status text DEFAULT 'open'::text NOT NULL,
    notes text,
    "imageUrls" text[] DEFAULT ARRAY[]::text[],
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "vehicleId" text NOT NULL,
    "serviceRecordId" text,
    "resolvedServiceRecordId" text
);


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vehicles (
    id text NOT NULL,
    make text NOT NULL,
    model text NOT NULL,
    year integer NOT NULL,
    vin text,
    "licensePlate" text,
    color text,
    mileage integer DEFAULT 0 NOT NULL,
    "fuelType" text DEFAULT 'gasoline'::text,
    transmission text DEFAULT 'automatic'::text,
    "engineSize" text,
    "purchaseDate" timestamp(3) without time zone,
    "purchasePrice" double precision,
    "imageUrl" text,
    "isArchived" boolean DEFAULT false NOT NULL,
    "archiveReason" text,
    "maintenanceDismissed" boolean DEFAULT false NOT NULL,
    "maintenanceDismissedAt" timestamp(3) without time zone,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "userId" text NOT NULL,
    "organizationId" text,
    "customerId" text,
    "engineCode" text
);


--
-- Name: verifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.verifications (
    id text NOT NULL,
    identifier text NOT NULL,
    value text NOT NULL,
    "expiresAt" timestamp(3) without time zone NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp(3) without time zone
);


--
-- Name: webhook_deliveries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhook_deliveries (
    id text NOT NULL,
    event text NOT NULL,
    payload text NOT NULL,
    status text DEFAULT 'pending'::text NOT NULL,
    "statusCode" integer,
    "responseBody" text,
    "errorMessage" text,
    attempt integer DEFAULT 0 NOT NULL,
    "maxAttempts" integer DEFAULT 5 NOT NULL,
    "nextRetryAt" timestamp(3) without time zone,
    "deliveredAt" timestamp(3) without time zone,
    "durationMs" integer,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "webhookId" text NOT NULL
);


--
-- Name: webhooks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.webhooks (
    id text NOT NULL,
    name text NOT NULL,
    url text NOT NULL,
    secret text NOT NULL,
    events text NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL,
    description text,
    "lastTriggeredAt" timestamp(3) without time zone,
    "lastSuccessAt" timestamp(3) without time zone,
    "lastFailureAt" timestamp(3) without time zone,
    "failureCount" integer DEFAULT 0 NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "organizationId" text NOT NULL,
    "createdById" text NOT NULL
);


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('09bdd969-2379-4662-b108-d331f838e3e3', 'aae4b0b8abe217c45772f6d215cdcfa3a158b33e9af4568ea73311ceefac339d', '2026-07-22 15:34:18.608362-05', '20260329102940_report_scheduler', NULL, NULL, '2026-07-22 15:34:18.59954-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('94b820ee-9963-4f3f-83fb-e30cb6155819', '2b744da3b4bac277985272e1a4e11eb00da9563486dd0427ba0b5488a411d5ae', '2026-07-22 15:34:18.49136-05', '0_init', NULL, NULL, '2026-07-22 15:34:18.290738-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('31ec444d-0ca5-4e9d-800c-818a60447f87', '31fa1bcde3db30bc6994f97171ced920bf474eb51e4ab299b2eede7c5ca51b32', '2026-07-22 15:34:18.51013-05', '20260307232727_workorder_duration', NULL, NULL, '2026-07-22 15:34:18.491718-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('3b9e512a-f9f4-4f76-b210-fbaf1de9e262', '8c851c7acc2ac4e815873caf1eac38a19541e27a4178da030b195c9677c49fff', '2026-07-22 15:34:18.520556-05', '20260311184346_audit_log', NULL, NULL, '2026-07-22 15:34:18.510561-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('f5721182-350f-406a-9839-55ae3b5edb94', '03e773412b7745c892cf884d716b888e227185d157c8ed1bf837fbf8eda1d17d', '2026-07-22 15:34:18.618835-05', '20260403135129_vehicle_outstanding_items', NULL, NULL, '2026-07-22 15:34:18.608716-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('ab004c6e-8cfe-4f79-ba8e-9fcc24917b9c', 'cfe2d174bb9912ec28c5f158936833ba42f32dfe5d20a00a0c838752c29a4ac1', '2026-07-22 15:34:18.535785-05', '20260312190308_ai_integration', NULL, NULL, '2026-07-22 15:34:18.520915-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('59d06c3b-0a0d-4ab2-977f-0bf10b4aec9f', '0ef51c7232b44c5d1174daa8ec1d80ca5485c8863acda5d36441a7af28d76491', '2026-07-22 15:34:18.546594-05', '20260317075019_labor_preset', NULL, NULL, '2026-07-22 15:34:18.536107-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('5b33e439-f76c-42cb-bbbe-b74c48c46418', '70998d9933e9a3c42b6045842f5cd9fe31bee2b342dc02c155ffd1a6d201babd', '2026-07-23 11:36:32.95758-05', '20260723000000_stored_files', NULL, NULL, '2026-07-23 11:36:32.8911-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('cd89967d-608a-4cc9-b025-8a9be1f91ca2', '75f6f518da27887e7e580dff2295e0724e5a6b57ce6a30596103411b6e582315', '2026-07-22 15:34:18.555405-05', '20260323160120_telegram_messages', NULL, NULL, '2026-07-22 15:34:18.546945-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('006bfd5d-69c7-40bd-8612-2be986ce6473', 'd9a3ad1be97f006c7dfef6b716da6f286ef040ad3b54a03e24e02fb60cdc03cb', '2026-07-22 15:34:18.622142-05', '20260410061236_tax', NULL, NULL, '2026-07-22 15:34:18.619179-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('a3a1ca0c-2a95-45ec-bb02-246f5011ea29', '91e97e070ec964d2f359cc8275973322bfb9c23a15da095537a85c56a916ea09', '2026-07-22 15:34:18.557406-05', '20260324171951_barcode', NULL, NULL, '2026-07-22 15:34:18.555731-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('fc00c2d5-0be8-4fda-97f0-6caa5d38097f', '486b7b445bc5769312b6b73ebf796c3610e44e096e6ccd46ba27f7043f68a082', '2026-07-22 15:34:18.564575-05', '20260324212722_multi_part_images', NULL, NULL, '2026-07-22 15:34:18.557765-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('bc8f4137-6cea-4619-892b-d55d7f6fed1d', 'add6d9d4a1c253c65b8901af7c49c0f9cea121fccc7b1893599f255a334bacd7', '2026-07-22 15:34:18.567171-05', '20260325204612_net_profit', NULL, NULL, '2026-07-22 15:34:18.564895-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('8aedf05d-4f29-4430-b4a9-d82abfc1c250', '68fdce4d543caff7e11752674f48bb42b6afa1b837a2936f27b7fec98d1844d9', '2026-07-22 15:34:18.628924-05', '20260411182756_sms_customer_login', NULL, NULL, '2026-07-22 15:34:18.62249-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('7e1eda9f-8f54-422b-8653-20cba856b1d0', '86ae675e221ecdbb55cfb3138f8213c5175d7d96f6a24c9807502a896d5fa903', '2026-07-22 15:34:18.570132-05', '20260326062211_service_unit', NULL, NULL, '2026-07-22 15:34:18.567492-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('1b2965d6-7344-46ac-8aff-ae621738a106', '9907a23850359701a05275b76936f5df983261d45c79999900d8f3ffcc40c636', '2026-07-22 15:34:18.582169-05', '20260326082336_technician_assignment', NULL, NULL, '2026-07-22 15:34:18.570433-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('7130f88e-8a33-4d04-b89a-4d0b53394333', '1a0c2f7495f250378a996a29da21f17a67a0c2aee049eb62dec5f0e577f3c699', '2026-07-22 15:34:18.585091-05', '20260327055410_invoice_due_date', NULL, NULL, '2026-07-22 15:34:18.582521-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('cbc3693a-f8fb-4ecd-8a82-27521f81b1c6', '44711db1a1ea2575068e1bdbd4c1d9d6d06cf339747cca0032446bcda284ea73', '2026-07-22 15:34:18.636348-05', '20260412140256_service_package', NULL, NULL, '2026-07-22 15:34:18.629272-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('5ec63e94-f662-4b8e-9fc7-e6469dd2ac85', 'f913ccb9c462e64dc9afdb733a1f201e87cb97bc251297266e14573d2cd8a7a9', '2026-07-22 15:34:18.599193-05', '20260327083943_customer_status_report', NULL, NULL, '2026-07-22 15:34:18.585706-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('fd158c49-65b9-4d70-b624-1d365cfa3fa2', '2791964ad962d04c8929b84122a02faf34e34ee0fec5034f4eae35becf6f9a94', '2026-07-22 15:34:18.638287-05', '20260412143333_warranty_tracking', NULL, NULL, '2026-07-22 15:34:18.636722-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('23334a6d-3881-487b-9ea9-da29c80bbead', '9ef499bad0fdbba04f01a2cf48bf0013326eb32407248cf71a0bb49f646aecae', '2026-07-22 15:34:18.650612-05', '20260501152451_webhooks', NULL, NULL, '2026-07-22 15:34:18.638605-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('1387c565-0d6d-4464-9729-06dd3dfb08cb', '3de5d68f24c378fee4a450a96fd2b6d4d9d7f61c91d296615a95208b4ad721be', '2026-07-22 15:34:18.652261-05', '20260503000000_vehicle_engine_code', NULL, NULL, '2026-07-22 15:34:18.650925-05', 1);
INSERT INTO public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) VALUES ('fea572ee-67fc-40ec-8506-4b2c4b99b65a', '8c8712231173fd7314ed21b2f02de0b3cc00c7afbfd10b1d873551d33b82da9e', '2026-07-22 15:34:18.653953-05', '20260525102721_part_markup', NULL, NULL, '2026-07-22 15:34:18.652575-05', 1);


--
-- Data for Name: accounts; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.accounts (id, "accountId", "providerId", "userId", "accessToken", "refreshToken", "idToken", "accessTokenExpiresAt", "refreshTokenExpiresAt", scope, password, "createdAt", "updatedAt") VALUES ('B8jVCRgOk8CzWpW4KmW4mr8itFRtBm53', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'credential', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', NULL, NULL, NULL, NULL, NULL, NULL, '9f25b422138f7d29da22fb195aa3bd77:31e6d8665d266d33cef9833941cdfc2c61edba9131b1d7aa7d70ce04f19d2c2c3a4db4d29007159487794d415c3bcf3290c82914459f91ed123081dcb3d8e689', '2026-07-22 20:41:54.921', '2026-07-23 16:54:00.258');
INSERT INTO public.accounts (id, "accountId", "providerId", "userId", "accessToken", "refreshToken", "idToken", "accessTokenExpiresAt", "refreshTokenExpiresAt", scope, password, "createdAt", "updatedAt") VALUES ('zv5B8cUo8uuNxNFKhu8foAkQ0StjFoHX', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', 'credential', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', NULL, NULL, NULL, NULL, NULL, NULL, 'a2b33de60aabcf10a48d477abe5e0ce5:d25e11f908fd3b39ebb2d732b85a75938b51a296fb954bb83814e787b54e1eb2ea44655a28ea57088949bfcf8279aa27d999d96fb49194ca31c52a2329b97a47', '2026-07-22 20:41:55.126', '2026-07-23 16:54:00.844');
INSERT INTO public.accounts (id, "accountId", "providerId", "userId", "accessToken", "refreshToken", "idToken", "accessTokenExpiresAt", "refreshTokenExpiresAt", scope, password, "createdAt", "updatedAt") VALUES ('kQ1R9TVDGpydWEMx3xtpq6b4MkM6XVNG', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', 'credential', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', NULL, NULL, NULL, NULL, NULL, NULL, '9bf49f90d2e19c2d862d46a715300037:090231cbc5de6f42238511ce032f80a11d541892038b81199a996a647aed8db865a86a89e85a93e044dfc81f0b18af8507cccfa012d4f423bcae091e887d1658', '2026-07-22 20:41:55.255', '2026-07-23 16:54:01.37');
INSERT INTO public.accounts (id, "accountId", "providerId", "userId", "accessToken", "refreshToken", "idToken", "accessTokenExpiresAt", "refreshTokenExpiresAt", scope, password, "createdAt", "updatedAt") VALUES ('Ijx9EXVUGJ80inJ1oRuu8iZfqNtagMtx', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', 'credential', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', NULL, NULL, NULL, NULL, NULL, NULL, '27089f4380178d818ccc241b220fe496:be1e95fba5848799df4e2faa5e5b4525ae5940356536ce54fc9305fcbcee7b9a23f397f2149a53d8962a069910bf4f6f308ee6a568ede1a6cb0e0136d82abc6c', '2026-07-22 20:42:30.966', '2026-07-23 16:54:01.812');
INSERT INTO public.accounts (id, "accountId", "providerId", "userId", "accessToken", "refreshToken", "idToken", "accessTokenExpiresAt", "refreshTokenExpiresAt", scope, password, "createdAt", "updatedAt") VALUES ('O2cXeP0WLcnpHTzL5SnAUlzJwMGElysm', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', 'credential', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', NULL, NULL, NULL, NULL, NULL, NULL, '5989f9f3268427ce0349728898d3aca7:3a16e7065b32f742e4c5aef0e35f9851330a4a27e184b0060a4a0d4fbba61b5946827517f1d74aa7b0cf757ad95ead7d54423c21f3b459cb368f7c748d672501', '2026-07-22 20:42:31.134', '2026-07-23 16:54:02.406');


--
-- Data for Name: ai_chat_messages; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ai_chats; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: ai_generated_messages; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: app_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.app_settings (id, key, value, "userId", "organizationId") VALUES ('a336eaf3993d49d8b6df3126484bd2ba', 'workshop.logo', '/torqvoice_app_logo.png', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjsys20000o8uawnelyodx', '2026-07-22 20:41:54.962', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', NULL);
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjsyww0001o8ua1hllzysw', '2026-07-22 20:41:55.136', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', NULL);
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjsz0f0002o8uau3i4o2z9', '2026-07-22 20:41:55.263', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', NULL);
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjtqkh0003o8uavqi5bg4m', '2026-07-22 20:42:30.977', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.2', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', NULL);
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjtqp60004o8uaee8pcz1h', '2026-07-22 20:42:31.146', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.3', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', NULL);
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjualx0005o8uamqyow3ur', '2026-07-22 20:42:56.949', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.10', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjubbx0006o8uagu4n3cqm', '2026-07-22 20:42:57.885', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.11', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjubp40007o8uaf4e1pjjg', '2026-07-22 20:42:58.36', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.12', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjubzl0008o8uaurmzi76u', '2026-07-22 20:42:58.737', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.13', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjuc9l0009o8ua63jwt05o', '2026-07-22 20:42:59.097', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.14', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrwjvgbm000ao8ua266zh45c', '2026-07-22 20:43:51.01', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/150.0.0.0 Safari/537.36', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxqmc3d0000k4uads15qras', '2026-07-23 16:40:29.113', 'auth.loginFailed', NULL, NULL, 'Failed login attempt for unknown', '{"path": "/api/public/auth/sign-in/email", "email": "unknown", "statusCode": 400}', '127.0.0.1', 'curl/8.19.0', NULL, NULL);
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxqms7c0001k4uaqj9kagt3', '2026-07-23 16:40:49.992', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'curl/8.19.0', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr29rm0000m0uayw96fvin', '2026-07-23 16:52:52.594', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.40', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3pql0001m0uavllf7gzn', '2026-07-23 16:53:59.949', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.11', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3pzs0002m0uankm204h1', '2026-07-23 16:54:00.28', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.11', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3q640003m0uayk4r3r7h', '2026-07-23 16:54:00.508', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.12', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3qfu0004m0uacziba2sl', '2026-07-23 16:54:00.858', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.12', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3qks0005m0uatwbxv0lf', '2026-07-23 16:54:01.036', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.13', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3quh0006m0uatq2sm2qb', '2026-07-23 16:54:01.385', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.13', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3qyy0007m0uaq1aypsca', '2026-07-23 16:54:01.546', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.14', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3r6s0008m0uaiod5ke25', '2026-07-23 16:54:01.828', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.14', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3rco0009m0uatoupk1bo', '2026-07-23 16:54:02.04', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.15', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr3rn6000am0uaegqychcl', '2026-07-23 16:54:02.418', 'auth.login', NULL, NULL, 'User logged in', NULL, '10.22.0.15', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr4921000bm0uazk9dbj4f', '2026-07-23 16:54:24.985', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr498b000cm0ua98wtomcc', '2026-07-23 16:54:25.211', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr49dn000dm0uam4gnsslu', '2026-07-23 16:54:25.403', 'auth.login', NULL, NULL, 'User logged in', NULL, '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', 'ae61e4e12d8a42669757d60757654326');
INSERT INTO public.audit_logs (id, "timestamp", action, entity, "entityId", message, metadata, ip, "userAgent", "userId", "organizationId") VALUES ('cmrxr49ez000em0uafyyf0vt7', '2026-07-23 16:54:25.451', 'auth.loginFailed', NULL, NULL, 'Failed login attempt for mechanic2@fleet.local', '{"path": "/api/public/auth/sign-in/email", "email": "mechanic2@fleet.local", "statusCode": 429}', '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', 'ae61e4e12d8a42669757d60757654326');


--
-- Data for Name: custom_field_definitions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: custom_field_values; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: customer_magic_links; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: customer_sessions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: customer_sms_codes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: customers; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: fuel_logs; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inspection_items; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inspection_quote_requests; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inspection_template_items; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inspection_template_sections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inspection_templates; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inspections; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: inventory_parts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: labor_preset_items; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: labor_preset_parts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: labor_presets; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: notes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: organization_members; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.organization_members (id, role, "userId", "organizationId", "roleId") VALUES ('e5fec8a3885a4f7c8bf6727a406bea8e', 'owner', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'ae61e4e12d8a42669757d60757654326', NULL);
INSERT INTO public.organization_members (id, role, "userId", "organizationId", "roleId") VALUES ('087dcab8388f4f2c93644929ad35a903', 'admin', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb', 'ae61e4e12d8a42669757d60757654326', NULL);
INSERT INTO public.organization_members (id, role, "userId", "organizationId", "roleId") VALUES ('eca5ce7f71f7488eaf1bad3284ecd251', 'member', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw', 'ae61e4e12d8a42669757d60757654326', NULL);
INSERT INTO public.organization_members (id, role, "userId", "organizationId", "roleId") VALUES ('51038302f3d1458497434fc663b1ed62', 'member', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', 'ae61e4e12d8a42669757d60757654326', NULL);
INSERT INTO public.organization_members (id, role, "userId", "organizationId", "roleId") VALUES ('34435db837024fa7b6d08401b89939e4', 'member', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', 'ae61e4e12d8a42669757d60757654326', NULL);


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.organizations (id, name, "portalSlug", "createdAt", "updatedAt") VALUES ('ae61e4e12d8a42669757d60757654326', 'US Team Fleet', NULL, '2026-07-22 15:42:43.17', '2026-07-22 15:42:43.17');


--
-- Data for Name: passkeys; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: quote_attachments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: quote_labor; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: quote_parts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: quotes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: recurring_invoices; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: recurring_labor; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: recurring_parts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reminders; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: report_schedules; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: service_attachments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: service_labor; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: service_parts; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: service_records; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: service_requests; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: sessions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('1s9nKKSkqO90hQpGe8CggSNEOwgIaNad', '2026-07-30 16:54:00.272', 'RkGKJFxsC1pGErcaWqPEP9hk8YVy0Fgz', '2026-07-23 16:54:00.273', '2026-07-23 16:54:00.273', '10.22.0.11', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg');
INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('2wpY3Z6d53kfWG8aXqyq8OPF6EN4v7EA', '2026-07-30 16:54:00.852', 'h887HoPsvbSm9vcoewFCj4wX3pZ9g61k', '2026-07-23 16:54:00.852', '2026-07-23 16:54:00.852', '10.22.0.12', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb');
INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('oYfX8bCeZkTvCMRzA7PG4TRm0zemzDNs', '2026-07-30 16:54:01.376', 'rUUCHPrcbR1BVaD9GSenClx1aelxfR3H', '2026-07-23 16:54:01.376', '2026-07-23 16:54:01.376', '10.22.0.13', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw');
INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('IQuLto085QtVPqcMiSsCmb3gEc77GPVw', '2026-07-30 16:54:01.818', 'SuAnI0ECXdHm7MwrLqcb1wL9GZX7bRH9', '2026-07-23 16:54:01.818', '2026-07-23 16:54:01.818', '10.22.0.14', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg');
INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('7kkU9MOFPliJI1mI1f9VLgAaHh49wRpJ', '2026-07-30 16:54:02.412', 'vHtVhVmgRQz9r7q8rqTRvAOhdCMM3mMO', '2026-07-23 16:54:02.413', '2026-07-23 16:54:02.413', '10.22.0.15', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA');
INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('juUK8zr2BUS6knXczZcnIY4dIc7zQrj8', '2026-07-30 16:54:24.963', 'wCAAzjXcfBmmc4WL0yRWX04fbl4AvyJL', '2026-07-23 16:54:24.963', '2026-07-23 16:54:24.963', '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', '2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg');
INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('w1DidfIl6dm3NsdgbyFyINYCHEZVBZZF', '2026-07-30 16:54:25.202', 'Rroytcrc3ykPLinMBiXVelhVh2uENYaQ', '2026-07-23 16:54:25.202', '2026-07-23 16:54:25.202', '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'miFSdlNDbnwR7JF25wPJgizUERCC0WGb');
INSERT INTO public.sessions (id, "expiresAt", token, "createdAt", "updatedAt", "ipAddress", "userAgent", "userId") VALUES ('Z9qwb0qQYoit4qpJsgj3JaPuQXgnuqOF', '2026-07-30 16:54:25.395', 'eVzhnxqUIEw5qqqKQYTCbCnoJdyIlX6j', '2026-07-23 16:54:25.395', '2026-07-23 16:54:25.395', '127.0.0.1', 'Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.8655', 'glkKPkOTHh8muB1pf254CTVRS2NcgHtw');


--
-- Data for Name: sms_messages; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: status_reports; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: stored_files; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: stored_images; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: subscription_plans; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: subscriptions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: system_settings; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.system_settings (id, key, value) VALUES ('cloud-registration-lock', 'registration.disabled', 'true');


--
-- Data for Name: team_invitations; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: technicians; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: telegram_messages; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: two_factor; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (id, name, email, "emailVerified", image, "isSuperAdmin", "createdAt", "updatedAt", "twoFactorEnabled", "termsAcceptedAt", "lastLogin", "lastSeen") VALUES ('7ESmVq2R8fS8KfCbT6OXhD1ehcfzrGbg', 'Mechanic Two', 'mechanic2@fleet.local', false, NULL, false, '2026-07-22 20:42:30.962', '2026-07-23 16:54:01.823', false, '2026-07-22 20:42:30.973', '2026-07-23 16:54:01.822', NULL);
INSERT INTO public.users (id, name, email, "emailVerified", image, "isSuperAdmin", "createdAt", "updatedAt", "twoFactorEnabled", "termsAcceptedAt", "lastLogin", "lastSeen") VALUES ('ThZq7jDMqivbdLuc7Dh81hbtKtPqHAfA', 'Accounting', 'accounting@fleet.local', false, NULL, false, '2026-07-22 20:42:31.131', '2026-07-23 16:54:02.415', false, '2026-07-22 20:42:31.141', '2026-07-23 16:54:02.415', NULL);
INSERT INTO public.users (id, name, email, "emailVerified", image, "isSuperAdmin", "createdAt", "updatedAt", "twoFactorEnabled", "termsAcceptedAt", "lastLogin", "lastSeen") VALUES ('miFSdlNDbnwR7JF25wPJgizUERCC0WGb', 'Fleet Manager', 'manager@fleet.local', false, NULL, false, '2026-07-22 20:41:55.123', '2026-07-23 16:54:25.209', false, '2026-07-22 20:41:55.132', '2026-07-23 16:54:25.209', NULL);
INSERT INTO public.users (id, name, email, "emailVerified", image, "isSuperAdmin", "createdAt", "updatedAt", "twoFactorEnabled", "termsAcceptedAt", "lastLogin", "lastSeen") VALUES ('glkKPkOTHh8muB1pf254CTVRS2NcgHtw', 'Mechanic One', 'mechanic1@fleet.local', false, NULL, false, '2026-07-22 20:41:55.252', '2026-07-23 16:54:25.399', false, '2026-07-22 20:41:55.261', '2026-07-23 16:54:25.398', NULL);
INSERT INTO public.users (id, name, email, "emailVerified", image, "isSuperAdmin", "createdAt", "updatedAt", "twoFactorEnabled", "termsAcceptedAt", "lastLogin", "lastSeen") VALUES ('2hKM5ZWGNt4bJv2WrL2MWru8v9iDXDzg', 'Fleet Owner', 'owner@fleet.local', false, NULL, true, '2026-07-22 20:41:54.903', '2026-07-23 16:55:50.536', false, '2026-07-22 20:41:54.948', '2026-07-23 16:54:24.968', '2026-07-23 16:55:50.536');


--
-- Data for Name: vehicle_findings; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: verifications; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: webhook_deliveries; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: webhooks; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_messages ai_chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_messages
    ADD CONSTRAINT ai_chat_messages_pkey PRIMARY KEY (id);


--
-- Name: ai_chats ai_chats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chats
    ADD CONSTRAINT ai_chats_pkey PRIMARY KEY (id);


--
-- Name: ai_generated_messages ai_generated_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_generated_messages
    ADD CONSTRAINT ai_generated_messages_pkey PRIMARY KEY (id);


--
-- Name: app_settings app_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT app_settings_pkey PRIMARY KEY (id);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id);


--
-- Name: custom_field_definitions custom_field_definitions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_definitions
    ADD CONSTRAINT custom_field_definitions_pkey PRIMARY KEY (id);


--
-- Name: custom_field_values custom_field_values_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_values
    ADD CONSTRAINT custom_field_values_pkey PRIMARY KEY (id);


--
-- Name: customer_magic_links customer_magic_links_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_magic_links
    ADD CONSTRAINT customer_magic_links_pkey PRIMARY KEY (id);


--
-- Name: customer_sessions customer_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_sessions
    ADD CONSTRAINT customer_sessions_pkey PRIMARY KEY (id);


--
-- Name: customer_sms_codes customer_sms_codes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_sms_codes
    ADD CONSTRAINT customer_sms_codes_pkey PRIMARY KEY (id);


--
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (id);


--
-- Name: fuel_logs fuel_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_logs
    ADD CONSTRAINT fuel_logs_pkey PRIMARY KEY (id);


--
-- Name: inspection_items inspection_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_items
    ADD CONSTRAINT inspection_items_pkey PRIMARY KEY (id);


--
-- Name: inspection_quote_requests inspection_quote_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_quote_requests
    ADD CONSTRAINT inspection_quote_requests_pkey PRIMARY KEY (id);


--
-- Name: inspection_template_items inspection_template_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_template_items
    ADD CONSTRAINT inspection_template_items_pkey PRIMARY KEY (id);


--
-- Name: inspection_template_sections inspection_template_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_template_sections
    ADD CONSTRAINT inspection_template_sections_pkey PRIMARY KEY (id);


--
-- Name: inspection_templates inspection_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_templates
    ADD CONSTRAINT inspection_templates_pkey PRIMARY KEY (id);


--
-- Name: inspections inspections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspections
    ADD CONSTRAINT inspections_pkey PRIMARY KEY (id);


--
-- Name: inventory_parts inventory_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_parts
    ADD CONSTRAINT inventory_parts_pkey PRIMARY KEY (id);


--
-- Name: labor_preset_items labor_preset_items_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_preset_items
    ADD CONSTRAINT labor_preset_items_pkey PRIMARY KEY (id);


--
-- Name: labor_preset_parts labor_preset_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_preset_parts
    ADD CONSTRAINT labor_preset_parts_pkey PRIMARY KEY (id);


--
-- Name: labor_presets labor_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_presets
    ADD CONSTRAINT labor_presets_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: organization_members organization_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT organization_members_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: passkeys passkeys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passkeys
    ADD CONSTRAINT passkeys_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: quote_attachments quote_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quote_attachments
    ADD CONSTRAINT quote_attachments_pkey PRIMARY KEY (id);


--
-- Name: quote_labor quote_labor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quote_labor
    ADD CONSTRAINT quote_labor_pkey PRIMARY KEY (id);


--
-- Name: quote_parts quote_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quote_parts
    ADD CONSTRAINT quote_parts_pkey PRIMARY KEY (id);


--
-- Name: quotes quotes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT quotes_pkey PRIMARY KEY (id);


--
-- Name: recurring_invoices recurring_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_invoices
    ADD CONSTRAINT recurring_invoices_pkey PRIMARY KEY (id);


--
-- Name: recurring_labor recurring_labor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_labor
    ADD CONSTRAINT recurring_labor_pkey PRIMARY KEY (id);


--
-- Name: recurring_parts recurring_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_parts
    ADD CONSTRAINT recurring_parts_pkey PRIMARY KEY (id);


--
-- Name: reminders reminders_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminders
    ADD CONSTRAINT reminders_pkey PRIMARY KEY (id);


--
-- Name: report_schedules report_schedules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_schedules
    ADD CONSTRAINT report_schedules_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: service_attachments service_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_attachments
    ADD CONSTRAINT service_attachments_pkey PRIMARY KEY (id);


--
-- Name: service_labor service_labor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_labor
    ADD CONSTRAINT service_labor_pkey PRIMARY KEY (id);


--
-- Name: service_parts service_parts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_parts
    ADD CONSTRAINT service_parts_pkey PRIMARY KEY (id);


--
-- Name: service_records service_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_records
    ADD CONSTRAINT service_records_pkey PRIMARY KEY (id);


--
-- Name: service_requests service_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_requests
    ADD CONSTRAINT service_requests_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sms_messages sms_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_messages
    ADD CONSTRAINT sms_messages_pkey PRIMARY KEY (id);


--
-- Name: status_reports status_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_reports
    ADD CONSTRAINT status_reports_pkey PRIMARY KEY (id);


--
-- Name: stored_files stored_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stored_files
    ADD CONSTRAINT stored_files_pkey PRIMARY KEY (id);


--
-- Name: stored_images stored_images_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stored_images
    ADD CONSTRAINT stored_images_pkey PRIMARY KEY (id);


--
-- Name: subscription_plans subscription_plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscription_plans
    ADD CONSTRAINT subscription_plans_pkey PRIMARY KEY (id);


--
-- Name: subscriptions subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT subscriptions_pkey PRIMARY KEY (id);


--
-- Name: system_settings system_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_settings
    ADD CONSTRAINT system_settings_pkey PRIMARY KEY (id);


--
-- Name: team_invitations team_invitations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invitations
    ADD CONSTRAINT team_invitations_pkey PRIMARY KEY (id);


--
-- Name: technicians technicians_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technicians
    ADD CONSTRAINT technicians_pkey PRIMARY KEY (id);


--
-- Name: telegram_messages telegram_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telegram_messages
    ADD CONSTRAINT telegram_messages_pkey PRIMARY KEY (id);


--
-- Name: two_factor two_factor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor
    ADD CONSTRAINT two_factor_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicle_findings vehicle_findings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_findings
    ADD CONSTRAINT vehicle_findings_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: verifications verifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.verifications
    ADD CONSTRAINT verifications_pkey PRIMARY KEY (id);


--
-- Name: webhook_deliveries webhook_deliveries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_deliveries
    ADD CONSTRAINT webhook_deliveries_pkey PRIMARY KEY (id);


--
-- Name: webhooks webhooks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks
    ADD CONSTRAINT webhooks_pkey PRIMARY KEY (id);


--
-- Name: accounts_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "accounts_userId_idx" ON public.accounts USING btree ("userId");


--
-- Name: ai_chat_messages_chatId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ai_chat_messages_chatId_createdAt_idx" ON public.ai_chat_messages USING btree ("chatId", "createdAt");


--
-- Name: ai_chats_organizationId_userId_updatedAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "ai_chats_organizationId_userId_updatedAt_idx" ON public.ai_chats USING btree ("organizationId", "userId", "updatedAt" DESC);


--
-- Name: ai_generated_messages_vehicleId_type_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "ai_generated_messages_vehicleId_type_key" ON public.ai_generated_messages USING btree ("vehicleId", type);


--
-- Name: app_settings_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "app_settings_organizationId_idx" ON public.app_settings USING btree ("organizationId");


--
-- Name: app_settings_organizationId_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "app_settings_organizationId_key_key" ON public.app_settings USING btree ("organizationId", key);


--
-- Name: audit_logs_action_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_logs_action_timestamp_idx ON public.audit_logs USING btree (action, "timestamp" DESC);


--
-- Name: audit_logs_organizationId_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "audit_logs_organizationId_timestamp_idx" ON public.audit_logs USING btree ("organizationId", "timestamp" DESC);


--
-- Name: audit_logs_userId_timestamp_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "audit_logs_userId_timestamp_idx" ON public.audit_logs USING btree ("userId", "timestamp" DESC);


--
-- Name: custom_field_definitions_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "custom_field_definitions_organizationId_idx" ON public.custom_field_definitions USING btree ("organizationId");


--
-- Name: custom_field_definitions_organizationId_name_entityType_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "custom_field_definitions_organizationId_name_entityType_key" ON public.custom_field_definitions USING btree ("organizationId", name, "entityType");


--
-- Name: custom_field_values_fieldId_entityId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "custom_field_values_fieldId_entityId_key" ON public.custom_field_values USING btree ("fieldId", "entityId");


--
-- Name: custom_field_values_fieldId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "custom_field_values_fieldId_idx" ON public.custom_field_values USING btree ("fieldId");


--
-- Name: customer_magic_links_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customer_magic_links_token_idx ON public.customer_magic_links USING btree (token);


--
-- Name: customer_magic_links_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX customer_magic_links_token_key ON public.customer_magic_links USING btree (token);


--
-- Name: customer_sessions_customerId_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "customer_sessions_customerId_organizationId_idx" ON public.customer_sessions USING btree ("customerId", "organizationId");


--
-- Name: customer_sessions_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX customer_sessions_token_idx ON public.customer_sessions USING btree (token);


--
-- Name: customer_sessions_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX customer_sessions_token_key ON public.customer_sessions USING btree (token);


--
-- Name: customer_sms_codes_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "customer_sms_codes_organizationId_idx" ON public.customer_sms_codes USING btree ("organizationId");


--
-- Name: customer_sms_codes_phone_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "customer_sms_codes_phone_organizationId_idx" ON public.customer_sms_codes USING btree (phone, "organizationId");


--
-- Name: customers_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "customers_organizationId_idx" ON public.customers USING btree ("organizationId");


--
-- Name: fuel_logs_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "fuel_logs_vehicleId_idx" ON public.fuel_logs USING btree ("vehicleId");


--
-- Name: inspection_items_inspectionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspection_items_inspectionId_idx" ON public.inspection_items USING btree ("inspectionId");


--
-- Name: inspection_quote_requests_inspectionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspection_quote_requests_inspectionId_idx" ON public.inspection_quote_requests USING btree ("inspectionId");


--
-- Name: inspection_quote_requests_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspection_quote_requests_organizationId_idx" ON public.inspection_quote_requests USING btree ("organizationId");


--
-- Name: inspection_template_items_sectionId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspection_template_items_sectionId_idx" ON public.inspection_template_items USING btree ("sectionId");


--
-- Name: inspection_template_sections_templateId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspection_template_sections_templateId_idx" ON public.inspection_template_sections USING btree ("templateId");


--
-- Name: inspection_templates_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspection_templates_organizationId_idx" ON public.inspection_templates USING btree ("organizationId");


--
-- Name: inspections_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspections_organizationId_idx" ON public.inspections USING btree ("organizationId");


--
-- Name: inspections_publicToken_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "inspections_publicToken_key" ON public.inspections USING btree ("publicToken");


--
-- Name: inspections_technicianId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspections_technicianId_idx" ON public.inspections USING btree ("technicianId");


--
-- Name: inspections_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inspections_vehicleId_idx" ON public.inspections USING btree ("vehicleId");


--
-- Name: inventory_parts_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "inventory_parts_organizationId_idx" ON public.inventory_parts USING btree ("organizationId");


--
-- Name: labor_preset_items_presetId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "labor_preset_items_presetId_idx" ON public.labor_preset_items USING btree ("presetId");


--
-- Name: labor_preset_parts_presetId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "labor_preset_parts_presetId_idx" ON public.labor_preset_parts USING btree ("presetId");


--
-- Name: labor_presets_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "labor_presets_organizationId_idx" ON public.labor_presets USING btree ("organizationId");


--
-- Name: notes_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notes_vehicleId_idx" ON public.notes USING btree ("vehicleId");


--
-- Name: notifications_organizationId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notifications_organizationId_createdAt_idx" ON public.notifications USING btree ("organizationId", "createdAt" DESC);


--
-- Name: notifications_organizationId_read_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "notifications_organizationId_read_idx" ON public.notifications USING btree ("organizationId", read);


--
-- Name: organization_members_userId_organizationId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "organization_members_userId_organizationId_key" ON public.organization_members USING btree ("userId", "organizationId");


--
-- Name: organizations_portalSlug_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "organizations_portalSlug_key" ON public.organizations USING btree ("portalSlug");


--
-- Name: passkeys_credentialID_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "passkeys_credentialID_key" ON public.passkeys USING btree ("credentialID");


--
-- Name: passkeys_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "passkeys_userId_idx" ON public.passkeys USING btree ("userId");


--
-- Name: payments_serviceRecordId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "payments_serviceRecordId_idx" ON public.payments USING btree ("serviceRecordId");


--
-- Name: permissions_roleId_action_subject_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "permissions_roleId_action_subject_key" ON public.permissions USING btree ("roleId", action, subject);


--
-- Name: permissions_roleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "permissions_roleId_idx" ON public.permissions USING btree ("roleId");


--
-- Name: quote_attachments_quoteId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "quote_attachments_quoteId_idx" ON public.quote_attachments USING btree ("quoteId");


--
-- Name: quote_labor_quoteId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "quote_labor_quoteId_idx" ON public.quote_labor USING btree ("quoteId");


--
-- Name: quote_parts_quoteId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "quote_parts_quoteId_idx" ON public.quote_parts USING btree ("quoteId");


--
-- Name: quotes_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "quotes_organizationId_idx" ON public.quotes USING btree ("organizationId");


--
-- Name: recurring_invoices_nextRunDate_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "recurring_invoices_nextRunDate_isActive_idx" ON public.recurring_invoices USING btree ("nextRunDate", "isActive");


--
-- Name: recurring_invoices_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "recurring_invoices_vehicleId_idx" ON public.recurring_invoices USING btree ("vehicleId");


--
-- Name: reminders_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "reminders_vehicleId_idx" ON public.reminders USING btree ("vehicleId");


--
-- Name: report_schedules_nextRunDate_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "report_schedules_nextRunDate_isActive_idx" ON public.report_schedules USING btree ("nextRunDate", "isActive");


--
-- Name: report_schedules_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "report_schedules_organizationId_idx" ON public.report_schedules USING btree ("organizationId");


--
-- Name: roles_organizationId_name_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "roles_organizationId_name_key" ON public.roles USING btree ("organizationId", name);


--
-- Name: service_attachments_serviceRecordId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "service_attachments_serviceRecordId_idx" ON public.service_attachments USING btree ("serviceRecordId");


--
-- Name: service_labor_serviceRecordId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "service_labor_serviceRecordId_idx" ON public.service_labor USING btree ("serviceRecordId");


--
-- Name: service_parts_serviceRecordId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "service_parts_serviceRecordId_idx" ON public.service_parts USING btree ("serviceRecordId");


--
-- Name: service_records_publicToken_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "service_records_publicToken_key" ON public.service_records USING btree ("publicToken");


--
-- Name: service_records_technicianId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "service_records_technicianId_idx" ON public.service_records USING btree ("technicianId");


--
-- Name: service_records_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "service_records_vehicleId_idx" ON public.service_records USING btree ("vehicleId");


--
-- Name: service_requests_customerId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "service_requests_customerId_idx" ON public.service_requests USING btree ("customerId");


--
-- Name: service_requests_organizationId_status_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "service_requests_organizationId_status_idx" ON public.service_requests USING btree ("organizationId", status);


--
-- Name: sessions_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX sessions_token_key ON public.sessions USING btree (token);


--
-- Name: sessions_userId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sessions_userId_idx" ON public.sessions USING btree ("userId");


--
-- Name: sms_messages_organizationId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sms_messages_organizationId_createdAt_idx" ON public.sms_messages USING btree ("organizationId", "createdAt" DESC);


--
-- Name: sms_messages_organizationId_customerId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sms_messages_organizationId_customerId_createdAt_idx" ON public.sms_messages USING btree ("organizationId", "customerId", "createdAt" DESC);


--
-- Name: sms_messages_toNumber_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "sms_messages_toNumber_organizationId_idx" ON public.sms_messages USING btree ("toNumber", "organizationId");


--
-- Name: status_reports_expiresAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "status_reports_expiresAt_idx" ON public.status_reports USING btree ("expiresAt");


--
-- Name: status_reports_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "status_reports_organizationId_idx" ON public.status_reports USING btree ("organizationId");


--
-- Name: status_reports_publicToken_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "status_reports_publicToken_idx" ON public.status_reports USING btree ("publicToken");


--
-- Name: status_reports_publicToken_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "status_reports_publicToken_key" ON public.status_reports USING btree ("publicToken");


--
-- Name: status_reports_serviceRecordId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "status_reports_serviceRecordId_idx" ON public.status_reports USING btree ("serviceRecordId");


--
-- Name: stored_files_organizationId_category_filename_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "stored_files_organizationId_category_filename_key" ON public.stored_files USING btree ("organizationId", category, filename);


--
-- Name: stored_files_organizationId_category_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stored_files_organizationId_category_idx" ON public.stored_files USING btree ("organizationId", category);


--
-- Name: stored_images_inventoryPartId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "stored_images_inventoryPartId_idx" ON public.stored_images USING btree ("inventoryPartId");


--
-- Name: subscription_plans_stripePriceId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "subscription_plans_stripePriceId_key" ON public.subscription_plans USING btree ("stripePriceId");


--
-- Name: subscriptions_organizationId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "subscriptions_organizationId_key" ON public.subscriptions USING btree ("organizationId");


--
-- Name: subscriptions_stripeSubscriptionId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "subscriptions_stripeSubscriptionId_key" ON public.subscriptions USING btree ("stripeSubscriptionId");


--
-- Name: system_settings_key_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX system_settings_key_key ON public.system_settings USING btree (key);


--
-- Name: team_invitations_email_organizationId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "team_invitations_email_organizationId_key" ON public.team_invitations USING btree (email, "organizationId");


--
-- Name: team_invitations_token_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX team_invitations_token_idx ON public.team_invitations USING btree (token);


--
-- Name: team_invitations_token_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX team_invitations_token_key ON public.team_invitations USING btree (token);


--
-- Name: technicians_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "technicians_organizationId_idx" ON public.technicians USING btree ("organizationId");


--
-- Name: telegram_messages_organizationId_chatId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "telegram_messages_organizationId_chatId_createdAt_idx" ON public.telegram_messages USING btree ("organizationId", "chatId", "createdAt" DESC);


--
-- Name: telegram_messages_organizationId_customerId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "telegram_messages_organizationId_customerId_createdAt_idx" ON public.telegram_messages USING btree ("organizationId", "customerId", "createdAt" DESC);


--
-- Name: two_factor_userId_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX "two_factor_userId_key" ON public.two_factor USING btree ("userId");


--
-- Name: users_email_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX users_email_key ON public.users USING btree (email);


--
-- Name: vehicle_findings_serviceRecordId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "vehicle_findings_serviceRecordId_idx" ON public.vehicle_findings USING btree ("serviceRecordId");


--
-- Name: vehicle_findings_vehicleId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "vehicle_findings_vehicleId_idx" ON public.vehicle_findings USING btree ("vehicleId");


--
-- Name: vehicles_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "vehicles_organizationId_idx" ON public.vehicles USING btree ("organizationId");


--
-- Name: verifications_identifier_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX verifications_identifier_key ON public.verifications USING btree (identifier);


--
-- Name: webhook_deliveries_status_nextRetryAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "webhook_deliveries_status_nextRetryAt_idx" ON public.webhook_deliveries USING btree (status, "nextRetryAt");


--
-- Name: webhook_deliveries_webhookId_createdAt_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "webhook_deliveries_webhookId_createdAt_idx" ON public.webhook_deliveries USING btree ("webhookId", "createdAt" DESC);


--
-- Name: webhooks_organizationId_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "webhooks_organizationId_idx" ON public.webhooks USING btree ("organizationId");


--
-- Name: webhooks_organizationId_isActive_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX "webhooks_organizationId_isActive_idx" ON public.webhooks USING btree ("organizationId", "isActive");


--
-- Name: accounts accounts_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.accounts
    ADD CONSTRAINT "accounts_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ai_chat_messages ai_chat_messages_chatId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_messages
    ADD CONSTRAINT "ai_chat_messages_chatId_fkey" FOREIGN KEY ("chatId") REFERENCES public.ai_chats(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ai_generated_messages ai_generated_messages_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_generated_messages
    ADD CONSTRAINT "ai_generated_messages_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: app_settings app_settings_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT "app_settings_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: app_settings app_settings_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_settings
    ADD CONSTRAINT "app_settings_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: audit_logs audit_logs_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT "audit_logs_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: audit_logs audit_logs_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT "audit_logs_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: custom_field_definitions custom_field_definitions_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_definitions
    ADD CONSTRAINT "custom_field_definitions_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: custom_field_definitions custom_field_definitions_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_definitions
    ADD CONSTRAINT "custom_field_definitions_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: custom_field_values custom_field_values_fieldId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_field_values
    ADD CONSTRAINT "custom_field_values_fieldId_fkey" FOREIGN KEY ("fieldId") REFERENCES public.custom_field_definitions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: customer_sessions customer_sessions_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customer_sessions
    ADD CONSTRAINT "customer_sessions_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public.customers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: customers customers_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT "customers_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: customers customers_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.customers
    ADD CONSTRAINT "customers_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: fuel_logs fuel_logs_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fuel_logs
    ADD CONSTRAINT "fuel_logs_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inspection_items inspection_items_inspectionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_items
    ADD CONSTRAINT "inspection_items_inspectionId_fkey" FOREIGN KEY ("inspectionId") REFERENCES public.inspections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inspection_quote_requests inspection_quote_requests_inspectionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_quote_requests
    ADD CONSTRAINT "inspection_quote_requests_inspectionId_fkey" FOREIGN KEY ("inspectionId") REFERENCES public.inspections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inspection_template_items inspection_template_items_sectionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_template_items
    ADD CONSTRAINT "inspection_template_items_sectionId_fkey" FOREIGN KEY ("sectionId") REFERENCES public.inspection_template_sections(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inspection_template_sections inspection_template_sections_templateId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_template_sections
    ADD CONSTRAINT "inspection_template_sections_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES public.inspection_templates(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inspection_templates inspection_templates_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspection_templates
    ADD CONSTRAINT "inspection_templates_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inspections inspections_technicianId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspections
    ADD CONSTRAINT "inspections_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES public.technicians(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: inspections inspections_templateId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspections
    ADD CONSTRAINT "inspections_templateId_fkey" FOREIGN KEY ("templateId") REFERENCES public.inspection_templates(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: inspections inspections_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inspections
    ADD CONSTRAINT "inspections_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inventory_parts inventory_parts_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_parts
    ADD CONSTRAINT "inventory_parts_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: inventory_parts inventory_parts_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.inventory_parts
    ADD CONSTRAINT "inventory_parts_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: labor_preset_items labor_preset_items_presetId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_preset_items
    ADD CONSTRAINT "labor_preset_items_presetId_fkey" FOREIGN KEY ("presetId") REFERENCES public.labor_presets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: labor_preset_parts labor_preset_parts_presetId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_preset_parts
    ADD CONSTRAINT "labor_preset_parts_presetId_fkey" FOREIGN KEY ("presetId") REFERENCES public.labor_presets(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: labor_presets labor_presets_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labor_presets
    ADD CONSTRAINT "labor_presets_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: notes notes_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT "notes_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: organization_members organization_members_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT "organization_members_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: organization_members organization_members_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT "organization_members_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: organization_members organization_members_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.organization_members
    ADD CONSTRAINT "organization_members_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: passkeys passkeys_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.passkeys
    ADD CONSTRAINT "passkeys_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: payments payments_serviceRecordId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT "payments_serviceRecordId_fkey" FOREIGN KEY ("serviceRecordId") REFERENCES public.service_records(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: permissions permissions_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT "permissions_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: quote_attachments quote_attachments_quoteId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quote_attachments
    ADD CONSTRAINT "quote_attachments_quoteId_fkey" FOREIGN KEY ("quoteId") REFERENCES public.quotes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: quote_labor quote_labor_quoteId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quote_labor
    ADD CONSTRAINT "quote_labor_quoteId_fkey" FOREIGN KEY ("quoteId") REFERENCES public.quotes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: quote_parts quote_parts_quoteId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quote_parts
    ADD CONSTRAINT "quote_parts_quoteId_fkey" FOREIGN KEY ("quoteId") REFERENCES public.quotes(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: quotes quotes_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT "quotes_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public.customers(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: quotes quotes_inspectionId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT "quotes_inspectionId_fkey" FOREIGN KEY ("inspectionId") REFERENCES public.inspections(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: quotes quotes_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT "quotes_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: quotes quotes_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT "quotes_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: quotes quotes_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.quotes
    ADD CONSTRAINT "quotes_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: recurring_invoices recurring_invoices_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_invoices
    ADD CONSTRAINT "recurring_invoices_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: recurring_labor recurring_labor_recurringInvoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_labor
    ADD CONSTRAINT "recurring_labor_recurringInvoiceId_fkey" FOREIGN KEY ("recurringInvoiceId") REFERENCES public.recurring_invoices(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: recurring_parts recurring_parts_recurringInvoiceId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recurring_parts
    ADD CONSTRAINT "recurring_parts_recurringInvoiceId_fkey" FOREIGN KEY ("recurringInvoiceId") REFERENCES public.recurring_invoices(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: reminders reminders_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reminders
    ADD CONSTRAINT "reminders_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: report_schedules report_schedules_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_schedules
    ADD CONSTRAINT "report_schedules_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: roles roles_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT "roles_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: service_attachments service_attachments_serviceRecordId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_attachments
    ADD CONSTRAINT "service_attachments_serviceRecordId_fkey" FOREIGN KEY ("serviceRecordId") REFERENCES public.service_records(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: service_labor service_labor_serviceRecordId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_labor
    ADD CONSTRAINT "service_labor_serviceRecordId_fkey" FOREIGN KEY ("serviceRecordId") REFERENCES public.service_records(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: service_parts service_parts_serviceRecordId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_parts
    ADD CONSTRAINT "service_parts_serviceRecordId_fkey" FOREIGN KEY ("serviceRecordId") REFERENCES public.service_records(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: service_records service_records_technicianId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_records
    ADD CONSTRAINT "service_records_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES public.technicians(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: service_records service_records_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_records
    ADD CONSTRAINT "service_records_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: service_requests service_requests_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_requests
    ADD CONSTRAINT "service_requests_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public.customers(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: service_requests service_requests_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.service_requests
    ADD CONSTRAINT "service_requests_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sessions sessions_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sessions
    ADD CONSTRAINT "sessions_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: sms_messages sms_messages_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_messages
    ADD CONSTRAINT "sms_messages_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public.customers(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: sms_messages sms_messages_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sms_messages
    ADD CONSTRAINT "sms_messages_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: status_reports status_reports_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_reports
    ADD CONSTRAINT "status_reports_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: status_reports status_reports_serviceRecordId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_reports
    ADD CONSTRAINT "status_reports_serviceRecordId_fkey" FOREIGN KEY ("serviceRecordId") REFERENCES public.service_records(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: status_reports status_reports_technicianId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_reports
    ADD CONSTRAINT "status_reports_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES public.technicians(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: stored_images stored_images_inventoryPartId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.stored_images
    ADD CONSTRAINT "stored_images_inventoryPartId_fkey" FOREIGN KEY ("inventoryPartId") REFERENCES public.inventory_parts(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT "subscriptions_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: subscriptions subscriptions_planId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.subscriptions
    ADD CONSTRAINT "subscriptions_planId_fkey" FOREIGN KEY ("planId") REFERENCES public.subscription_plans(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: team_invitations team_invitations_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invitations
    ADD CONSTRAINT "team_invitations_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: team_invitations team_invitations_roleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.team_invitations
    ADD CONSTRAINT "team_invitations_roleId_fkey" FOREIGN KEY ("roleId") REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: technicians technicians_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technicians
    ADD CONSTRAINT "technicians_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: technicians technicians_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.technicians
    ADD CONSTRAINT "technicians_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: telegram_messages telegram_messages_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telegram_messages
    ADD CONSTRAINT "telegram_messages_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public.customers(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: telegram_messages telegram_messages_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.telegram_messages
    ADD CONSTRAINT "telegram_messages_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: two_factor two_factor_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.two_factor
    ADD CONSTRAINT "two_factor_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vehicle_findings vehicle_findings_resolvedServiceRecordId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_findings
    ADD CONSTRAINT "vehicle_findings_resolvedServiceRecordId_fkey" FOREIGN KEY ("resolvedServiceRecordId") REFERENCES public.service_records(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: vehicle_findings vehicle_findings_serviceRecordId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_findings
    ADD CONSTRAINT "vehicle_findings_serviceRecordId_fkey" FOREIGN KEY ("serviceRecordId") REFERENCES public.service_records(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: vehicle_findings vehicle_findings_vehicleId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicle_findings
    ADD CONSTRAINT "vehicle_findings_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES public.vehicles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vehicles vehicles_customerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT "vehicles_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES public.customers(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: vehicles vehicles_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT "vehicles_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: vehicles vehicles_userId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT "vehicles_userId_fkey" FOREIGN KEY ("userId") REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: webhook_deliveries webhook_deliveries_webhookId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhook_deliveries
    ADD CONSTRAINT "webhook_deliveries_webhookId_fkey" FOREIGN KEY ("webhookId") REFERENCES public.webhooks(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: webhooks webhooks_organizationId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.webhooks
    ADD CONSTRAINT "webhooks_organizationId_fkey" FOREIGN KEY ("organizationId") REFERENCES public.organizations(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--


