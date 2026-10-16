---
name: bilibili-video-summary1
description: Search B站 (Bilibili) for videos on a topic, sort by play count, watch the top videos at high speed using AI subtitles, and summarize their content. Use when the user asks to "search B站", "bilibili search", "find videos about X on bilibili", "summarize B站 videos", or similar requests involving B站/哔哩哔哩 video discovery and summarization.
version: 1.0.0
---

# B站视频搜索与AI字幕总结

在B站上按关键词搜索视频，按播放量排序，提取AI字幕并总结视频内容。

## 前置条件

- Playwright MCP 浏览器已启动
- 浏览器已安装 chrome-for-testing
- 如果导航报 "Browser not installed"，清理 npx 缓存重试：
  ```
  rm -rf ~/AppData/Local/ms-playwright/b/*
  rm -rf ~/AppData/Local/npm-cache/_npx/9833c18b2d85bc59  # 和其他旧缓存
  ```

## 工作流程

### 步骤1：搜索并排序

导航到B站搜索页并点击"最多播放"排序：

```
URL: https://search.bilibili.com/all?keyword={搜索关键词}
```

等待页面加载后，点击"最多播放"按钮：
- 目标选择器: `button "最多播放"`
- 点击后 URL 会变为 `?order=click`

### 步骤2：提取搜索结果

使用 `browser_snapshot` 获取页面内容。每个视频卡片包含：
- 播放量（如 "1466.3万"）
- 弹幕数
- 时长
- UP主名称和发布日期
- 视频链接（`/url: //www.bilibili.com/video/BV...`）

选出播放量最高的前N个视频（用户指定，默认2个）。

### 步骤3：打开视频并启用AI字幕

对每个选中视频：

1. **导航到视频页**: `https://www.bilibili.com/video/{BV号}/`

2. **防止自动跳播**: 视频播完后会自动跳转到推荐视频。如页面URL变了，重新 `navigate` 回原视频。

3. **打开字幕菜单**: 点击播放器控制栏的字幕按钮
   - 选择器: `.bpx-player-ctrl-subtitle` (aria-label="字幕")
   - 如果元素不可见，用 `browser_evaluate` 找到可见按钮位置再点击

4. **选择中文AI字幕**: 点击字幕菜单中的"中文"
   - 选择器: `.bpx-player-ctrl-subtitle-major .bpx-player-ctrl-subtitle-language-item:nth-child(1)`
   - 预期: 关闭开关变为非激活状态（`bpx-state-active` 被移除）

5. **确认字幕数据加载**: 使用 `browser_network_requests` 过滤 `subtitle|aisub`
   找到请求 `GET https://aisubtitle.hdslb.com/bfs/ai_subtitle/prod/... => [200]`

6. **提取字幕内容**: 用 `browser_network_request` → `response-body` 获取JSON
   - JSON结构: `body[].{from, to, content}` — 包含每条字幕的时间范围与文字

### 步骤4：总结

根据字幕JSON的 `content` 字段，按时间顺序整理视频内容：
- 分段描述剧情/话题发展
- 提取关键台词和笑点
- 用一句话概括视频核心内容

### 步骤5（可选）：倍速播放验证

用 `browser_evaluate` 控制视频播放：
```js
const video = document.querySelector('video');
video.playbackRate = 3.0;  // 3倍速
video.currentTime = 0;     // 从头播放
video.play();
```
同时收集弹幕（`document.querySelectorAll('.bpx-player-danmaku-item')`）辅助理解。

## 常见问题

| 问题 | 解决 |
|------|------|
| MCP报"Browser not installed" | 清理 `ms-playwright/b/` 和 npx 缓存，重新触发 |
| 页面自动跳转到其他视频 | 视频播完后autoplay触发，重新navigate回原URL |
| 字幕面板显示"暂无字幕" | 先点字幕按钮，再点"中文"；检查 `__INITIAL_STATE__.videoData.subtitle.list` 确认AI字幕存在 |
| `aisubtitle.hdslb.com` 返回403 | 带 `Referer: https://www.bilibili.com` 头；或用浏览器内fetch绕过CDN鉴权 |
| 字幕JSON是protobuf乱码 | 不直接从x/v2/subtitle/web/view获取；等用户手动选语言后拦截 `aisubtitle.hdslb.com` 的请求 |
| 字幕语言选项位置为(0,0)不可点击 | 说明菜单未正确展开。先点字幕按钮让菜单出现，再选语言 |
