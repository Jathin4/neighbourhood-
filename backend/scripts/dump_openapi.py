"""Write the current OpenAPI spec to openapi.json (kept in version control, §11)."""
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.main import app  # noqa: E402

out = Path(__file__).resolve().parents[1] / "openapi.json"
out.write_text(json.dumps(app.openapi(), indent=2), encoding="utf-8")
print(f"wrote {out}")
