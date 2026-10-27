# DouK-Downloader — Web API: curl mẫu & response thật

> Toàn bộ response trong tài liệu này được **capture trực tiếp** từ server `http://127.0.0.1:5556` (DouK-Downloader V5.8 Stable, Python 3.13), không phải mẫu tự viết.

> Giá trị chuỗi dài (URL CDN, `sec_uid`, chữ ký) đã được rút gọn thành `…<N chars>`.

## 1. Thông tin chung

| Mục | Giá trị |
|---|---|
| Base URL | `http://127.0.0.1:5556` |
| Định dạng | JSON (`Content-Type: application/json`) |
| Xác thực | **Không cần** — `is_valid_token()` ở V5.8 luôn trả `True`, header `token` bị bỏ qua |
| Swagger | `/docs`, `/redoc`, `/openapi.json` |
| Số endpoint | 19 |

> **Đọc kèm:** phần lớn endpoint dùng chung object bài đăng đã chuẩn hoá (32 khoá, mục 6). Điểm khác biệt so với code gốc mà repo này đang có: `src/link/extractor.py` nhận thêm link `modal_id` (精选/推荐) và `src/config/parameter.py` sửa lỗi 500 của `POST /settings`. Server đang chạy phải **restart** sau khi sửa code mới nhận patch.

### Envelope chung

Mọi endpoint đều trả về cùng một khung:

```json
{
  "message": "Successfully retrieved data!",
  "data": <object | array | null>,
  "params": { "...": "body bạn đã gửi (đã điền giá trị mặc định)" },
  "time": "2026-10-27 15:18:38"
}
```

- `message`: chuỗi tiếng Anh cố định, dùng để phân nhánh thay vì HTTP status.
- `data`: `null` khi thất bại hoặc rỗng.
- `params`: echo lại request đã chuẩn hoá — **hữu ích để debug** vì nó cho thấy giá trị mặc định.
- `time`: thời điểm trả về (không phải thời gian xử lý).
- Riêng `/douyin/share` dùng khoá `url` thay cho `data`.

## 2. Cấu hình

### GET /token — kiểm tra kết nối

```bash
curl -s 'http://127.0.0.1:5556/token'
```

```json
{
  "message": "Verification successful!",
  "data": null,
  "params": null,
  "time": "2026-10-27 15:18:38"
}
```

### GET /settings — đọc toàn bộ cấu hình (38 khoá)

```bash
curl -s 'http://127.0.0.1:5556/settings'
```

Response thật (đã lược giá trị cookie):

```json
{
  "accounts_urls": [],
  "accounts_urls_tiktok": [],
  "mix_urls": [],
  "mix_urls_tiktok": [],
  "owner_url": {
    "mark": "",
    "url": ""
  },
  "owner_url_tiktok": null,
  "root": "D:\\Source\\tool\\TikTokDownloader\\Volume",
  "folder_name": "Download",
  "name_format": "create_time type nickname desc",
  "desc_length": 64,
  "name_length": 128,
  "date_format": "%Y-%m-%d %H:%M:%S",
  "split": "-",
  "folder_mode": false,
  "music": false,
  "truncate": 50,
  "storage_format": "",
  "cookie": {
    "<27 cookie keys>": "..."
  },
  "cookie_tiktok": {},
  "dynamic_cover": false,
  "static_cover": false,
  "proxy": null,
  "proxy_tiktok": null,
  "twc_tiktok": "",
  "download": true,
  "max_size": 0,
  "chunk": 2097152,
  "timeout": null,
  "max_retry": 5,
  "max_pages": 99999,
  "run_command": "",
  "ffmpeg": "",
  "live_qualities": null,
  "original_quality": false,
  "douyin_platform": null,
  "tiktok_platform": null,
  "browser_info": null,
  "browser_info_tiktok": null
}
```

> ⚠️ **`GET /settings` trả về cookie dạng plaintext.** Nếu tool của bạn log response này, cookie phiên đăng nhập sẽ nằm trong log. Hãy lọc bỏ khoá `cookie` và `cookie_tiktok` trước khi lưu.

### POST /settings — ⚠️ V5.8 bị lỗi, không nên dùng

```bash
curl -s -X POST 'http://127.0.0.1:5556/settings' \
  -H 'Content-Type: application/json' \
  -d '{"max_pages": 10}'
```

Kết quả thực tế khi test trên bản gốc:

```text
HTTP 500
Internal Server Error
```

Có **hai** lỗi độc lập (đã kiểm chứng bằng cách gọi thẳng `Parameter.set_settings_data`):

1. `set_browser_info()` gọi `browser_info.pop(...)` khi `browser_info = null` → `AttributeError: 'NoneType' object has no attribute 'pop'` → HTTP 500. Chỉ xảy ra khi `browser_info` chưa được cấu hình (mặc định của mọi cài đặt mới).

2. `set_general_params()` gọi các hàm `__check_*` mà **không gán giá trị trả về**, nên hầu hết field vô hại: gửi `{"max_pages": 10}` → `max_pages` vẫn là `99999`; gửi `{"storage_format": "csv"}` → vẫn `""`.

Khuyến nghị tích hợp: **sửa trực tiếp `Volume/settings.json` rồi khởi động lại**, hoặc sửa code (xem mục 8).

## 3. Douyin — nội dung

### POST /douyin/detail — chi tiết 1 bài đăng

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/detail' \
  -H 'Content-Type: application/json' \
  -d '{"detail_id": "7683473853452575461"}'
```

```json
{
  "message": "Successfully retrieved data!",
  "data": {
    "collection_time": "2026-10-27 15:17:41",
    "id": "7683473853452575461",
    "desc": "贪吃鬼呱呱差点被吃了！#沙雕动画 #动画小故事 #可爱 #搞笑动画",
    "create_timestamp": 1788948163,
    "create_time": "2026-09-09 17:02:43",
    "text_extra": [
      "沙雕动画",
      "动画小故事",
      "可爱",
      "搞笑动画"
    ],
    "type": "Video",
    "height": 720,
    "width": 1280,
    "downloads": "https://www.douyin.com/aweme/v1/play/?vi…<361 chars>",
    "duration": "00:00:27",
    "uri": "v2800fgi0000dagis3vog65mkeva5v8g",
    "dynamic_cover": "https://p9-pc-sign.douyinpic.com/obj/tos…<310 chars>",
    "static_cover": "https://p3-pc-sign.douyinpic.com/image-c…<325 chars>",
    "uid": "3340735525170816",
    "sec_uid": "MS4wLjABAAAA9uwGGRVCh-OerJc3SlOz1bmrO9ZV…<76 chars>",
    "unique_id": "95475230857",
    "signature": "OiiOii超创|@OiiOii AI \nAniShort超创｜@AniShor…<99 chars>",
    "user_age": -1,
    "nickname": "呱呱历险记",
    "mark": "呱呱历险记",
    "music_author": "呱呱历险记",
    "music_title": "@呱呱历险记创作的原声",
    "music_url": "https://lf9-music-east.douyinstatic.com/…<80 chars>",
    "digg_count": 43313,
    "comment_count": 656,
    "collect_count": 7559,
    "share_count": 19822,
    "play_count": -1,
    "tag": [
      "二次元",
      "二次元内容",
      "动漫IP"
    ],
    "extra": "",
    "share_url": ""
  },
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "detail_id": "7683473853452575461"
  },
  "time": "2026-10-27 15:17:41"
}
```

### POST /douyin/account — bài đăng của một tài khoản

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/account' \
  -H 'Content-Type: application/json' \
  -d '{"sec_user_id": "<sec_uid lấy từ /douyin/detail>", "tab": "post", "pages": 1}'
```

Request fields:

| Field | Kiểu | Mặc định | Ghi chú |
|---|---|---|---|
| `sec_user_id` | str | **bắt buộc** | lấy từ response `detail` (khoá `sec_uid`) |
| `tab` | str | `post` | `post` / `like` / `favorite` |
| `pages` | int null | `null` | `null` = lấy tới hết |
| `earliest`/`latest` | str\|int\|float null | `null` | lọc theo ngày |
| `cursor` | int | `0` | phân trang |
| `count` | int | `18` | phải > 0 |
| `cookie`/`proxy`/`source` | — | `""`/`""`/`false` | kế thừa từ `APIModel` |

Response: `message = "Successfully retrieved data!"`, `data` là **list 20 phần tử** (1 trang). Mỗi phần tử cùng cấu trúc với `data` của `/douyin/detail`:

```json
{
  "collection_time": "2026-10-27 15:17:52",
  "id": "7699882284404591872",
  "desc": "非洲草原超级杯！五鬣联手，谁敢接招？ （本视频由OiiOii制作） #oiioi…<71 chars>",
  "create_timestamp": 1792803600,
  "create_time": "2026-10-24 08:00:00",
  "text_extra": [
    "oiioii",
    "oiioii创作者计划",
    "搞笑动画",
    "可爱动画",
    "创作者扶持计划"
  ],
  "type": "Video",
  "height": 2160,
  "width": 3840,
  "downloads": "https://www.douyin.com/aweme/v1/play/?vi…<356 chars>",
  "duration": "00:01:07",
  "uri": "v0200fg10000dbdnfmnog65m0gn3dvvg",
  "dynamic_cover": "https://p9-pc-sign.douyinpic.com/obj/tos…<288 chars>",
  "static_cover": "https://p3-pc-sign.douyinpic.com/obj/tos…<274 chars>",
  "uid": "3340735525170816",
  "sec_uid": "MS4wLjABAAAA9uwGGRVCh-OerJc3SlOz1bmrO9ZV…<76 chars>",
  "unique_id": "",
  "signature": "",
  "user_age": -1,
  "nickname": "呱呱历险记",
  "mark": "呱呱历险记",
  "music_author": "呱呱历险记",
  "music_title": "@呱呱历险记创作的原声",
  "music_url": "https://sf11-cdn-tos.douyinstatic.com/ob…<75 chars>",
  "digg_count": 54059,
  "comment_count": 1086,
  "collect_count": 6157,
  "share_count": 23506,
  "play_count": -1,
  "tag": [
    "二次元",
    "二次元内容",
    "动漫IP"
  ],
  "extra": "",
  "share_url": ""
}
```

> Còn 19 phần tử nữa, cấu trúc y hệt. `count` = số bài đăng mỗi trang, `cursor` = vị trí bắt đầu, `pages` = số trang tối đa.

### POST /douyin/mix — bài đăng trong合集

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/mix' \
  -H 'Content-Type: application/json' \
  -d '{"detail_id": "7683473853452575461"}'
```

| Field | Kiểu | Ghi chú |
|---|---|---|
| `mix_id` | str null | ID合集 (`/collection/<id>`) |
| `detail_id` | str null | hoặc truyền ID một bài đăng **nằm trong**合集, hệ thống tự suy ra |
| `cursor` / `count` | int | mặc định `0` / `12` |

Response: `data` = list **18 phần tử**, cùng cấu trúc bài đăng. Ví dụ phần tử đầu:

```json
{
  "collection_time": "2026-10-27 15:18:11",
  "id": "7683473853452575461",
  "desc": "贪吃鬼呱呱差点被吃了！#沙雕动画 #动画小故事 #可爱 #搞笑动画",
  "create_timestamp": 1788948163,
  "create_time": "2026-09-09 17:02:43",
  "text_extra": [
    "沙雕动画",
    "动画小故事",
    "可爱",
    "搞笑动画"
  ],
  "type": "Video",
  "height": 720,
  "width": 1280,
  "downloads": "https://www.douyin.com/aweme/v1/play/?vi…<358 chars>",
  "duration": "00:00:27",
  "uri": "v2800fgi0000dagis3vog65mkeva5v8g",
  "dynamic_cover": "https://p9-pc-sign.douyinpic.com/obj/tos…<307 chars>",
  "static_cover": "https://p3-pc-sign.douyinpic.com/image-c…<322 chars>",
  "uid": "3340735525170816",
  "sec_uid": "MS4wLjABAAAA9uwGGRVCh-OerJc3SlOz1bmrO9ZV…<76 chars>",
  "unique_id": "95475230857",
  "signature": "OiiOii超创|@OiiOii AI \nAniShort超创｜@AniShor…<99 chars>",
  "user_age": -1,
  "nickname": "呱呱和辣条的奇幻冒险",
  "mark": "呱呱和辣条的奇幻冒险",
  "music_author": "呱呱历险记",
  "music_title": "@呱呱历险记创作的原声",
  "music_url": "https://lf3-music-east.douyinstatic.com/…<80 chars>",
  "digg_count": 43313,
  "comment_count": 656,
  "collect_count": 7559,
  "share_count": 19822,
  "play_count": 9346564,
  "tag": [
    "二次元",
    "二次元内容",
    "动漫IP"
  ],
  "extra": "",
  "share_url": ""
}
```

### POST /douyin/comment — bình luận của một bài đăng

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/comment' \
  -H 'Content-Type: application/json' \
  -d '{"pages": 1, "detail_id": "7683473853452575461", "count": 5}'
```

```json
{
  "message": "Successfully retrieved data!",
  "data": [
    {
      "collection_time": "2026-10-27 15:17:44",
      "create_timestamp": 1791962705,
      "create_time": "2026-10-14 14:25:05",
      "ip_label": "广东",
      "text": "原来呱呱和辣条是这样认识的[呲牙]",
      "image": "",
      "sticker": "",
      "digg_count": 1,
      "reply_to_reply_id": "0",
      "reply_comment_total": 0,
      "reply_id": "0",
      "cid": "7696421203212895002",
      "uid": "3918307416085255",
      "sec_uid": "MS4wLjABAAAAt-WSzUwPOGDxOELROR1yemS3kuCM…<76 chars>",
      "unique_id": "m903312185",
      "signature": "",
      "user_age": -1,
      "nickname": "随意~",
      "mark": "随意~"
    },
    {
      "collection_time": "2026-10-27 15:17:44",
      "create_timestamp": 1789014715,
      "create_time": "2026-09-10 11:31:55",
      "ip_label": "河北",
      "text": "这是吸辣条吸上瘾了[捂脸][捂脸][捂脸]",
      "image": "",
      "sticker": "",
      "digg_count": 25,
      "reply_to_reply_id": "0",
      "reply_comment_total": 0,
      "reply_id": "0",
      "cid": "7683759688102494991",
      "uid": "2586498969370926",
      "sec_uid": "MS4wLjABAAAA3vC6jIpsXgQE2FoHlrfTqXF2OeLo…<76 chars>",
      "unique_id": "28303622154",
      "signature": "",
      "user_age": -1,
      "nickname": "寕萌",
      "mark": "寕萌"
    }
  ],
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "detail_id": "7683473853452575461",
    "pages": 1,
    "cursor": 0,
    "count": 5,
    "count_reply": 3,
    "reply": false
  },
  "time": "2026-10-27 15:17:44"
}
```

> Trả về 5 bình luận cấp 1 (theo `count`). Mỗi item có `cid` dùng cho `/douyin/reply`; `count_reply` + `reply: true` để kèm luôn phản hồi con.

Field của item:

```text
cid, collection_time, create_time, create_timestamp, digg_count, image, ip_label, mark, nickname, reply_comment_total, reply_id, reply_to_reply_id, sec_uid, signature, sticker, text, uid, unique_id, user_age
```

### POST /douyin/reply — phản hồi của một bình luận

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/reply' \
  -H 'Content-Type: application/json' \
  -d '{"pages": 1, "comment_id": "7696421203212895002", "detail_id": "7683473853452575461", "count": 3}'
```

Trường hợp **thất bại thật** (bình luận không có phản hồi nào):

```json
{
  "message": "Failed to retrieve data!",
  "data": null,
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "detail_id": "7683473853452575461",
    "comment_id": "7696421203212895002",
    "pages": 1,
    "cursor": 0,
    "count": 3
  },
  "time": "2026-10-27 15:20:35"
}
```

> Đây là hình dạng response khi `data` rỗng — dùng để phân biệt với lỗi mạng. Endpoint chỉ trả dữ liệu khi `cid` thực sự có reply.

### POST /douyin/share — resolve link chia sẻ / link rút gọn

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/share' \
  -H 'Content-Type: application/json' \
  -d '{"text": "https://www.douyin.com/jingxuan?modal_id=7683473853452575461"}'
```

```json
{
  "message": "Request link successful!",
  "url": "https://www.douyin.com/jingxuan?modal_id=7683473853452575461",
  "params": {
    "text": "https://www.douyin.com/jingxuan?modal_id=7683473853452575461",
    "proxy": ""
  },
  "time": "2026-10-27 15:18:14"
}
```

> Body chỉ có `text` và `proxy`. Với link đầy đủ (`www.douyin.com/...`) endpoint trả lại **nguyên văn**; tác dụng thật là theo redirect của link rút gọn `v.douyin.com/xxxx` → URL đầy đủ. Sau đó bạn tự tách ID bằng regex.

## 4. Douyin — tìm kiếm

Bốn endpoint dùng chung `BaseSearch`: `keyword` (**bắt buộc**, không rỗng), `pages` (1), `offset` (0), `count` (**≥ 5**, mặc định 10).

### POST /douyin/search/video — tìm bài đăng

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/search/video' \
  -H 'Content-Type: application/json' \
  -d '{"keyword": "沙雕动画", "count": 5, "pages": 1}'
```

```json
{
  "message": "Successfully retrieved data!",
  "data": [
    {
      "collection_time": "2026-10-27 15:19:22",
      "id": "7667190096646464906",
      "desc": "虾仁修仙系列高分沙雕视频推荐，一看就是一整天 #二次元动漫 #动漫推荐 #沙雕动画 #一口气看完系列 #虾仁动画",
      "create_timestamp": 1785299185,
      "create_time": "2026-07-29 11:26:25",
      "text_extra": [
        "二次元动漫",
        "动漫推荐",
        "沙雕动画",
        "一口气看完系列",
        "虾仁动画"
      ],
      "type": "Video",
      "height": 576,
      "width": 1024,
      "downloads": "https://www.douyin.com/aweme/v1/play/?vi…<355 chars>",
      "duration": "06:09:12",
      "uri": "v02f52g10003d9jl7m7og65hnm2g8ot0",
      "dynamic_cover": "https://p9-pc-sign.douyinpic.com/obj/tos…<294 chars>",
      "static_cover": "https://p3-pc-sign.douyinpic.com/image-c…<321 chars>",
      "uid": "3194524108063242",
      "sec_uid": "MS4wLjABAAAA7ejOxxwgxHSW9VpUVph3kAoqBspg…<76 chars>",
      "unique_id": "",
      "signature": "",
      "user_age": -1,
      "nickname": "虾仁沙雕动画剧场",
      "mark": "虾仁沙雕动画剧场",
      "music_author": "",
      "music_title": "",
      "music_url": "",
      "digg_count": 28154,
      "comment_count": 5330,
      "collect_count": 20787,
      "share_count": 5790,
      "play_count": -1,
      "tag": [],
      "extra": "",
      "share_url": ""
    },
    {
      "collection_time": "2026-10-27 15:19:22",
      "id": "7673132653273814770",
      "desc": "穿越古代，不想内卷却被迫疯狂搞事业，13小时沙雕动画一次看够 #沙雕动画 #动漫推荐 #一口气看完系列 #二次元动漫 #万万想不到",
      "create_timestamp": 1787047786,
      "create_time": "2026-08-18 17:09:46",
      "text_extra": [
        "沙雕动画",
        "动漫推荐",
        "一口气看完系列",
        "二次元动漫",
        "万万想不到"
      ],
      "type": "Video",
      "height": 720,
      "width": 1280,
      "downloads": "https://www.douyin.com/aweme/v1/play/?vi…<355 chars>",
      "duration": "09:59:57",
      "uri": "v02f52g10003d9u6nsfog65livac39qg",
      "dynamic_cover": "https://p3-pc-sign.douyinpic.com/obj/tos…<299 chars>",
      "static_cover": "https://p3-pc-sign.douyinpic.com/image-c…<319 chars>",
      "uid": "3194524108063242",
      "sec_uid": "MS4wLjABAAAA7ejOxxwgxHSW9VpUVph3kAoqBspg…<76 chars>",
      "unique_id": "",
      "signature": "",
      "user_age": -1,
      "nickname": "虾仁沙雕动画剧场",
      "mark": "虾仁沙雕动画剧场",
      "music_author": "",
      "music_title": "",
      "music_url": "",
      "digg_count": 5384,
      "comment_count": 119,
      "collect_count": 4331,
      "share_count": 465,
      "play_count": -1,
      "tag": [],
      "extra": "",
      "share_url": ""
    }
  ],
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "keyword": "沙雕动画",
    "pages": 1,
    "offset": 0,
    "count": 5,
    "channel": 1,
    "sort_type": 0,
    "publish_time": 0,
    "duration": 0,
    "search_range": 0
  },
  "time": "2026-10-27 15:19:22"
}
```

> `data` = list 5 phần tử (theo `count`).

### POST /douyin/search/user — tìm tài khoản

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/search/user' \
  -H 'Content-Type: application/json' \
  -d '{"keyword": "呱呱", "count": 5, "pages": 1}'
```

```json
{
  "message": "Successfully retrieved data!",
  "data": [
    {
      "collection_time": "2026-10-27 15:19:29",
      "avatar": "https://p3-pc.douyinpic.com/aweme/100x10…<124 chars>",
      "nickname": "呱呱🍉",
      "sec_uid": "MS4wLjABAAAAJy9H3Bi4n-wtMKtBi9aE8ppuXsFu…<76 chars>",
      "signature": "持续性骑车健身da人🚲 🏋️‍♀️\n间接性摄影爱好者.    📷 🤳🏻\n私信不回🙅‍♂️",
      "uid": "2427342763861815",
      "short_id": "3872584014",
      "verify": "无",
      "enterprise": "无",
      "follower_count": 10897,
      "total_favorited": 37317,
      "unique_id": "mini02261"
    },
    {
      "collection_time": "2026-10-27 15:19:29",
      "avatar": "https://p3-pc.douyinpic.com/aweme/100x10…<135 chars>",
      "nickname": "呱呱历险记",
      "sec_uid": "MS4wLjABAAAA9uwGGRVCh-OerJc3SlOz1bmrO9ZV…<76 chars>",
      "signature": "OiiOii超创|@OiiOii AI \nAniShort超创｜@AniShor…<99 chars>",
      "uid": "3340735525170816",
      "short_id": "95475230857",
      "verify": "无",
      "enterprise": "无",
      "follower_count": 969823,
      "total_favorited": 7544256,
      "unique_id": "95475230857"
    }
  ],
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "keyword": "呱呱",
    "pages": 1,
    "offset": 0,
    "count": 5,
    "channel": 2,
    "douyin_user_fans": 0,
    "douyin_user_type": 0
  },
  "time": "2026-10-27 15:19:29"
}
```

> `data` = list 5 phần tử (theo `count`).

### POST /douyin/search/general — tìm tổng hợp

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/search/general' \
  -H 'Content-Type: application/json' \
  -d '{"keyword": "沙雕动画", "count": 5, "pages": 1}'
```

```json
{
  "message": "Successfully retrieved data!",
  "data": [
    {
      "collection_time": "2026-10-27 15:20:44",
      "id": "7667190096646464906",
      "desc": "虾仁修仙系列高分沙雕视频推荐，一看就是一整天 #二次元动漫 #动漫推荐 #沙雕动画 #一口气看完系列 #虾仁动画",
      "create_timestamp": 1785299185,
      "create_time": "2026-07-29 11:26:25",
      "text_extra": [
        "二次元动漫",
        "动漫推荐",
        "沙雕动画",
        "一口气看完系列",
        "虾仁动画"
      ],
      "type": "Video",
      "height": 576,
      "width": 1024,
      "downloads": "https://www.douyin.com/aweme/v1/play/?vi…<355 chars>",
      "duration": "06:09:12",
      "uri": "v02f52g10003d9jl7m7og65hnm2g8ot0",
      "dynamic_cover": "https://p9-pc-sign.douyinpic.com/obj/tos…<294 chars>",
      "static_cover": "https://p3-pc-sign.douyinpic.com/image-c…<346 chars>",
      "uid": "3194524108063242",
      "sec_uid": "MS4wLjABAAAA7ejOxxwgxHSW9VpUVph3kAoqBspg…<76 chars>",
      "unique_id": "",
      "signature": "",
      "user_age": -1,
      "nickname": "虾仁沙雕动画剧场",
      "mark": "虾仁沙雕动画剧场",
      "music_author": "",
      "music_title": "",
      "music_url": "",
      "digg_count": 28154,
      "comment_count": 5330,
      "collect_count": 20787,
      "share_count": 5790,
      "play_count": -1,
      "tag": [],
      "extra": "",
      "share_url": ""
    },
    {
      "collection_time": "2026-10-27 15:20:44",
      "id": "7673132653273814770",
      "desc": "穿越古代，不想内卷却被迫疯狂搞事业，13小时沙雕动画一次看够 #沙雕动画 #动漫推荐 #一口气看完系列 #二次元动漫 #万万想不到",
      "create_timestamp": 1787047786,
      "create_time": "2026-08-18 17:09:46",
      "text_extra": [
        "沙雕动画",
        "动漫推荐",
        "一口气看完系列",
        "二次元动漫",
        "万万想不到"
      ],
      "type": "Video",
      "height": 720,
      "width": 1280,
      "downloads": "https://www.douyin.com/aweme/v1/play/?vi…<355 chars>",
      "duration": "09:59:57",
      "uri": "v02f52g10003d9u6nsfog65livac39qg",
      "dynamic_cover": "https://p3-pc-sign.douyinpic.com/obj/tos…<299 chars>",
      "static_cover": "https://p3-pc-sign.douyinpic.com/image-c…<344 chars>",
      "uid": "3194524108063242",
      "sec_uid": "MS4wLjABAAAA7ejOxxwgxHSW9VpUVph3kAoqBspg…<76 chars>",
      "unique_id": "",
      "signature": "",
      "user_age": -1,
      "nickname": "虾仁沙雕动画剧场",
      "mark": "虾仁沙雕动画剧场",
      "music_author": "",
      "music_title": "",
      "music_url": "",
      "digg_count": 5384,
      "comment_count": 119,
      "collect_count": 4331,
      "share_count": 465,
      "play_count": -1,
      "tag": [],
      "extra": "",
      "share_url": ""
    }
  ],
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "keyword": "沙雕动画",
    "pages": 1,
    "offset": 0,
    "count": 5,
    "channel": 0,
    "sort_type": 0,
    "publish_time": 0,
    "duration": 0,
    "search_range": 0,
    "content_type": 0
  },
  "time": "2026-10-27 15:20:44"
}
```

> `data` = list 5 phần tử (theo `count`).

### POST /douyin/search/live — ⚠️ luôn rỗng ở bản này

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/search/live' \
  -H 'Content-Type: application/json' \
  -d '{"keyword":"王者荣耀","pages":1,"count":5}'
```

```json
{
  "message": "The search result is empty!",
  "data": null,
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "keyword": "王者荣耀",
    "pages": 1,
    "offset": 0,
    "count": 5,
    "channel": 3
  },
  "time": "2026-10-27 15:21:15"
}
```

> Đã thử `游戏`, `娱乐`, `音乐`, `王者荣耀` — đều trả `"The search result is empty!"` với `data: null`. Endpoint tìm live phía Douyin coi như không còn hoạt động; `/douyin/live` vì thế không lấy được `web_rid` để test.

### POST /douyin/live — chưa capture được

```bash
curl -s -X POST 'http://127.0.0.1:5556/douyin/live' \
  -H 'Content-Type: application/json' \
  -d '{"web_rid":"123456789"}'
```

| Field | Kiểu | Ghi chú |
|---|---|---|
| `web_rid` | str null | ID phòng trong URL `live.douyin.com/<web_rid>` |

> Không có phòng live đang hoạt động để test (do mục trên). Response dùng envelope chuẩn với `data` = thông tin luồng live; hãy tự kiểm tra khi có `web_rid` thật.

## 5. TikTok — đối xứng hoàn toàn

| Douyin | TikTok | Ghi chú |
|---|---|---|
| `/douyin/detail` | `/tiktok/detail` | cùng body |
| `/douyin/account` | `/tiktok/account` | `count` mặc định 18 |
| `/douyin/mix` | `/tiktok/mix` | `count` mặc định **30** |
| `/douyin/live` | `/tiktok/live` | TikTok dùng `room_id` |
| `/douyin/share` | `/tiktok/share` | cùng body |

Không có endpoint `/tiktok/comment`, `/tiktok/reply`, `/tiktok/search/*`.

Response **thất bại** thật khi chưa cấu hình cookie TikTok:

```json
{
  "message": "Failed to retrieve data!",
  "data": null,
  "params": {
    "cookie": "",
    "proxy": "",
    "source": false,
    "detail_id": "7683473853452575461"
  },
  "time": "2026-10-27 15:18:20"
}
```

> Chú ý: **HTTP vẫn là 200**, chỉ `message` + `data` thay đổi. Đừng chỉ kiểm tra status code khi tích hợp.

## 6. Object bài đăng (32 khoá) — cấu trúc dùng chung

`/douyin/detail` trả 1 object; `/douyin/account`, `/douyin/mix`, `/douyin/search/*` trả array của object này.

| Khoá | Kiểu | Ý nghĩa |
|---|---|---|
| `id` | str(19) | ID bài đăng |
| `desc` | str | mô tả / tiêu đề |
| `type` | str | loại, **đã dịch theo ngôn ngữ UI của server**: `Video`/`Image` khi `Language=en_US`, `视频`/`图集` khi `zh_CN` |
| `create_time` | str | thời điểm đăng, format theo `date_format` |
| `create_timestamp` | int | epoch giây |
| `collection_time` | str | thời điểm lấy dữ liệu |
| `downloads` | str | URL tải — **video: 1 URL**, album ảnh: list URL |
| `duration` | str | `HH:MM:SS` |
| `uri` | str | video_id |
| `width` | int | — |
| `height` | int | — |
| `static_cover` | str | ảnh bìa tĩnh |
| `dynamic_cover` | str | ảnh bìa động (webp) |
| `music_title` | str | tên nhạc |
| `music_author` | str | tác giả nhạc |
| `music_url` | str | URL nhạc |
| `uid` | str | UID tác giả |
| `sec_uid` | str | sec_uid tác giả — dùng cho `/douyin/account` |
| `nickname` | str | tên tác giả |
| `unique_id` | str | 抖音号 |
| `signature` | str | chữ ký tác giả |
| `user_age` | int | `-1` = không công khai |
| `mark` | str | khoá đánh dấu nội bộ |
| `text_extra` | list[str] | hashtag đã tách |
| `tag` | list | tag nội bộ |
| `digg_count` | int | lượt thích |
| `comment_count` | int | bình luận |
| `collect_count` | int | lượt lưu |
| `share_count` | int | lượt chia sẻ |
| `play_count` | int | `-1` = ẩn |
| `extra` | str | thường rỗng |
| `share_url` | str | thường rỗng (chỉ có khi bật `source`) |

## 7. Mã lỗi & trường hợp biên

| Tình huống | HTTP | Response |
|---|---|---|
| Body sai JSON | `422` | `{"detail":[{"type":"json_invalid",...}]}` |
| Thiếu field bắt buộc | `422` | `{"detail":[{"type":"missing","loc":["body","detail_id"],...}]}` |
| `count` < 5 khi search | `422` | constraint của pydantic |
| Không lấy được dữ liệu | `200` | `{"message":"Failed to retrieve data!","data":null,...}` |
| Kết quả rỗng | `200` | `{"message":"The search result is empty!","data":null,...}` |
| Cookie hết hạn | `200` | `Failed to retrieve data!` — **không phải 401** |

Ví dụ 422 thật:

```json
{
  "detail": [
    {
      "type": "json_invalid",
      "loc": ["body", 1],
      "msg": "JSON decode error",
      "input": {},
      "ctx": {"error": "Expecting property name enclosed in double quotes"}
    }
  ]
}
```

> Kết luận quan trọng: **chỉ dựa vào `message` và `data`, đừng dựa vào HTTP status**.

## 8. Ghi chú tích hợp

1. **Không cần auth.** Header `token` là no-op ở V5.8.

2. **`cookie` và `proxy` override từng request**: mọi body đều có `cookie` (str) và `proxy` (str) — truyền vào thì chỉ request đó dùng, không ảnh hưởng server.

3. **`source: true`** trả về JSON gốc của Douyin thay vì object đã chuẩn hoá — hữu ích khi cần field không có trong 32 khoá trên.

4. **Phân trang**: `/douyin/account` và `/douyin/mix` nhận `cursor` + `count`; `pages` = số trang tối đa (bỏ trống = lấy hết, có thể rất lâu).

5. **Giới hạn tần suất**: server không rate-limit, nhưng Douyin thì có. Gọi dồn dập sẽ bị trả `Failed to retrieve data!`. Nên sleep 1–3s giữa các bài đăng.

6. **`GET /settings` làm lộ cookie** — lọc trước khi log.

7. **`POST /settings` hỏng** (mục 2) — sửa `Volume/settings.json` + restart.

8. Server dùng chung `Parameter` toàn cục: đổi cookie qua `POST /settings` (nếu sau này sửa được) là đổi cho **mọi request**, không phải per-session.

### Ví dụ Python

```python
import requests

BASE = 'http://127.0.0.1:5556'

def get_detail(detail_id: str) -> dict | None:
    r = requests.post(
        f'{BASE}/douyin/detail',
        json={'detail_id': detail_id},
        timeout=60,
    )
    j = r.json()
    return j['data'] if j['message'].startswith('Successfully') else None

d = get_detail('7683473853452575461')
if d:
    print(d['nickname'], '-', d['desc'])
    url = d['downloads']
    print('tải:', url if isinstance(url, str) else url[0])
```

### Ví dụ JavaScript

```js
const BASE = 'http://127.0.0.1:5556';

async function getDetail(detailId) {
  const r = await fetch(`${BASE}/douyin/detail`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ detail_id: detailId }),
  });
  const j = await r.json();
  if (!j.data) throw new Error(j.message);
  return j.data;
}
```

## 9. Ghi chú riêng cho Windows / PowerShell

`curl.exe` của Windows nhận `-d` qua PowerShell sẽ **bị mất dấu ngoặc kép**, gây 422 `json_invalid`. Hai cách tránh:

```powershell
# cách 1: ghi body ra file rồi tham chiếu
'{"detail_id":"7683473853452575461"}' | Set-Content -Encoding utf8 body.json
curl.exe -s -X POST 'http://127.0.0.1:5556/douyin/detail' -H 'Content-Type: application/json' -d '@body.json'

# cách 2: dùng Invoke-RestMethod
Invoke-RestMethod -Uri 'http://127.0.0.1:5556/douyin/detail' -Method Post -ContentType 'application/json' -Body '{"detail_id":"7683473853452575461"}'
```

Trên bash/zsh (Linux, macOS, Git Bash, WSL) thì `curl -d '{"k":"v"}'` dùng trực tiếp được như các ví dụ trên.
