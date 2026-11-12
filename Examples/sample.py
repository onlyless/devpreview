from dataclasses import dataclass
from pathlib import Path


@dataclass
class PreviewItem:
    name: str
    language: str
    extensions: list[str]

    def summary(self) -> str:
        return f"{self.name} ({self.language}): {', '.join(self.extensions)}"


def load_items(path: Path) -> list[PreviewItem]:
    if path.stat().st_size > 8 * 1024 * 1024:
        raise ValueError("file too large")
    return [PreviewItem("DevPreview", "Python", [".py", ".md"])]


if __name__ == "__main__":
    print(load_items(Path("sample.py"))[0].summary())
