# nice-skills

Nice skills for agents.

## Skills Directory

All skills are located in the `skills/` directory. Each skill has its own folder with documentation.

### Skills List

- [bilibili-video-summary1](#bilibili-video-summary1) - Search and summarize Bilibili videos with AI subtitles

---

## bilibili-video-summary1

**Search and summarize Bilibili videos with AI subtitles**

### Overview

This skill enables you to search for videos on Bilibili (B站), sort by play count, extract AI-generated subtitles, and automatically summarize video content. Perfect for discovering and understanding popular video content on Bilibili.

### When to Use

Use this skill when the user asks to:
- "Search B站 for..."
- "Bilibili search for..."
- "Find videos about X on bilibili"
- "Summarize B站 videos"
- Or similar requests involving Bilibili video discovery and summarization

### Version

1.0.0

### Prerequisites

- Playwright MCP browser is running
- Chrome-for-testing is installed
- If you encounter "Browser not installed" error, clear the npm cache:
  ```bash
  rm -rf ~/AppData/Local/ms-playwright/b/*
  rm -rf ~/AppData/Local/npm-cache/_npx/9833c18b2d85bc59
  ```

### How It Works

#### Step 1: Search and Sort

- Navigate to Bilibili search page with your keyword
- Click "Most Plays" button to sort by play count
- URL format: `https://search.bilibili.com/all?keyword={keyword}&order=click`

#### Step 2: Extract Search Results

- Retrieve video cards containing:
  - Play count (e.g., "1466.3万")
  - Comments count
  - Duration
  - UP creator name and publish date
  - Video link (BV number)
- Select the top N videos by play count (default: 2)

#### Step 3: Open Videos and Enable AI Subtitles

- Navigate to each selected video: `https://www.bilibili.com/video/{BV号}/`
- Open the subtitle menu in the video player
- Select Chinese AI subtitles
- Extract subtitle data from the AI subtitle service
- Verify subtitle data loads from: `GET https://aisubtitle.hdslb.com/bfs/ai_subtitle/prod/...`

#### Step 4: Summarize

- Organize subtitle content chronologically
- Extract key dialogue and highlights
- Generate a one-sentence summary of the video's core content

#### Step 5 (Optional): Playback at High Speed

- Play videos at 3x speed for faster review:
  ```javascript
  const video = document.querySelector('video');
  video.playbackRate = 3.0;
  video.currentTime = 0;
  video.play();
  ```
- Collect bullet comments (danmaku) for additional context

### Subtitle Data Structure

The AI subtitle JSON response contains:

```json
[
  {
    "from": 1000,
    "to": 5000,
    "content": "subtitle text"
  }
]
```

- `from`: Start time in milliseconds
- `to`: End time in milliseconds
- `content`: Subtitle text

---

## Directory Structure

```
nice-skills/
├── README.md
├── skills/
│   ├── bilibili-video-summary1/
│   │   ├── README.md (optional, for detailed skill docs)
│   │   ├── main.py
│   │   └── ...
│   └── [other-skills]/
```

## Contributing

### How to Add a New Skill

1. Create a new folder in the `skills/` directory with your skill name
2. Implement your skill functionality
3. Update this README with a new skill entry following the template below
4. Submit a Pull Request



---

## Questions?

Feel free to open an issue or contact the maintainers.
