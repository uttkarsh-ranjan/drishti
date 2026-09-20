import hashlib
from datetime import datetime, timezone
from PIL import Image
from io import BytesIO

def verify_hash(file_bytes, submitted_hash):
    """
    Verifies if the SHA-256 hash of the received bytes matches the hash generated on the device.
    """
    calculated_hash = hashlib.sha256(file_bytes).hexdigest()
    return calculated_hash == submitted_hash

def get_exif_datetime(file_bytes):
    """
    Extracts the DateTimeOriginal from the image's EXIF data.
    """
    try:
        image = Image.open(BytesIO(file_bytes))
        exif_data = image._getexif()
        if not exif_data:
            return None
        
        # 36867 is the EXIF tag for DateTimeOriginal
        date_string = exif_data.get(36867)
        if date_string:
            # EXIF format is usually 'YYYY:MM:DD HH:MM:SS'
            return datetime.strptime(date_string, '%Y:%m:%d %H:%M:%S')
    except Exception:
        pass
    
    return None

def verify_timestamp(exif_datetime, tolerance_seconds=30):
    """
    Verifies if the EXIF timestamp is within the acceptable tolerance of the server's current UTC time.
    """
    if not exif_datetime:
        return False
        
    server_time = datetime.utcnow()
    time_diff = abs((server_time - exif_datetime).total_seconds())
    
    return time_diff <= tolerance_seconds
