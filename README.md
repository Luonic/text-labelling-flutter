# text-labelling-flutter

App for classifying texts on mobile.

## What it should do

Using file picker load jsonl file with fields

- `images`: list of image/video names in the dir `./images`
- `title`: string
- `description`: string

Then there should be horizontally swipeable pages of vertically scrollable cards.
Each card consists of:

- horizontally scrollable list of thumbnails of images from the `images` field
- title label, may occupy multiple lines
- description label, may occupy multiple lines

Horizontal grid of flag buttons with label equal to flag name that change color to `redAccent` if selected.

List of flags:

- `nudes_trade`
- `prostitution`
- `underwear_trade`

Store flags as json and load them on app start.

After moving to the next or previous page save flags to the same jsonl file by rewriting entire file.

## Run

```bash
flutter pub get
flutter run
```

Android, iOS, and Linux desktop are enabled. On a phone, copy a JSONL file and an `images` folder next to it onto the device, then open the JSONL from the app.

A sample dataset lives in `example/sample.jsonl` with thumbnails in `example/images/`.

## Data format

Each JSONL line is one record:

```json
{"images": ["a.jpg", "clip.mp4"], "title": "...", "description": "...", "flags": ["nudes_trade"]}
```

- Media files are resolved as `<jsonl directory>/images/<name>`.
- Selected flags are stored on each record as a `flags` string array.
- Unknown extra JSON fields are kept when the file is rewritten.

The flag catalog is bundled as `assets/flags.json` and copied to the app documents directory on first launch so it can be edited without a rebuild:

```json
["nudes_trade", "prostitution", "underwear_trade"]
```

## Architecture

| Piece | Role |
| --- | --- |
| `LabelRecord` | One JSONL row: media names, title, description, selected flags, extra fields |
| `parseJsonl` / `serializeJsonl` | Line-oriented codec used for load and full-file rewrite |
| `FlagsRepository` | Loads/saves the flag catalog JSON on startup |
| `LabelSession` | In-memory records, current page, flag toggles, save-on-swipe |
| `LabellingScreen` | `PageView` of scrollable cards, thumbnail strip, flag grid |

Saves also run when the app is backgrounded and from the toolbar save button, so the last page is not lost if you never swipe away from it.

On Android 11+, grant **All files access** when the app asks. `.jsonl` is not a standard Android MIME type, so the picker shows all files — choose the JSONL from device storage (Downloads or a local folder), not from Drive. The app then resolves the real path so it can load `./images` and rewrite the original file.
