from io import BytesIO
from typing import Optional
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseUpload
from google.oauth2.service_account import Credentials
import time

from .config import load_settings

_scopes = ["https://www.googleapis.com/auth/drive"]

class DriveClient:
    def __init__(self):
        self.settings = load_settings()
        creds_dict = self.settings.google_credentials_dict()
        creds = Credentials.from_service_account_info(creds_dict, scopes=_scopes)
        self.drive = build("drive", "v3", credentials=creds, cache_discovery=False)

    def upload_invoice_bytes(self, name: str, content: bytes, mimetype: str = "image/jpeg") -> Optional[str]:
        metadata = {
            "name": name,
            "parents": [self.settings.DRIVE_FOLDER_ID],
        }
        media = MediaIoBaseUpload(BytesIO(content), mimetype=mimetype, resumable=False)
        file = self.drive.files().create(body=metadata, media_body=media, fields="id, webViewLink, webContentLink").execute()
        file_id = file.get("id")
        # Make public
        self.drive.permissions().create(fileId=file_id, body={"role": "reader", "type": "anyone"}).execute()
        # Return a view link
        return file.get("webViewLink") or file.get("webContentLink")
