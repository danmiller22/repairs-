import { NextRequest, NextResponse } from "next/server";
import { getAuthContext } from "@/lib/get-auth-context";
import { db } from "@/lib/db";
import crypto from "crypto";

const ALLOWED_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/pdf",
  "text/csv",
  "text/plain",
];

const MAX_SIZE = 15 * 1024 * 1024;

export async function POST(request: NextRequest) {
  const ctx = await getAuthContext();

  if (!ctx) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const formData = await request.formData();
  const file = formData.get("file") as File | null;

  if (!file) {
    return NextResponse.json({ error: "No file provided" }, { status: 400 });
  }

  if (!ALLOWED_TYPES.includes(file.type)) {
    return NextResponse.json(
      { error: "File type not allowed. Supported: JPEG, PNG, WebP, PDF, CSV, TXT" },
      { status: 400 }
    );
  }

  if (file.size > MAX_SIZE) {
    return NextResponse.json(
      { error: "File size must be under 15MB" },
      { status: 400 }
    );
  }

  const ext = file.name.split(".").pop() || "bin";
  const filename = `${crypto.randomUUID()}.${ext}`;
  const bytes = new Uint8Array(await file.arrayBuffer());

  await db.storedFile.create({
    data: {
      organizationId: ctx.organizationId,
      category: "services",
      filename,
      originalName: file.name,
      contentType: file.type,
      fileSize: file.size,
      data: bytes,
    },
  });

  return NextResponse.json({
    url: `/api/protected/files/${ctx.organizationId}/services/${filename}`,
    fileName: file.name,
    fileType: file.type,
    fileSize: file.size,
  });
}
