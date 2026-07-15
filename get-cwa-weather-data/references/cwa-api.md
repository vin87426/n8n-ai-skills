# CWA API 指南

只有在選擇資料集、撰寫 API 呼叫或排查下載問題時讀取本文件。正式整合前重新檢查官方文件與公告，因為資料集、欄位與配額可能變動。

## 官方入口

- [開發指南－使用說明](https://opendata.cwa.gov.tw/devManual/insrtuction)
- [資料擷取 API Swagger](https://opendata.cwa.gov.tw/dist/opendata-swagger.html)
- [CWA 開放資料平臺](https://opendata.cwa.gov.tw/)
- [常見問答](https://opendata.cwa.gov.tw/faq)
- [使用規範](https://opendata.cwa.gov.tw/about/rules)

以官方頁面列出的當前 dataset ID、參數、格式、配額與授權條款為準。

## 選擇取得模式

| 需求 | 路徑模式 | 注意事項 |
|---|---|---|
| 最新結構化資料 | `/api/v1/rest/datastore/{dataid}` | JSON 通常為預設格式；依 Swagger 套用資料集專屬參數 |
| 檔案型產品 | `/fileapi/v1/opendataapi/{dataid}` | 用 `format` 選資料集支援的格式；支援時使用 ETag 快取 |
| 短期過去資料清單 | `/historyapi/v1/getDataId/` | 先確認資料集是否支援歷史 API |
| 歷史資料集資訊 | `/historyapi/v1/getDataId/{dataid}` | 查供應期間、更新頻率與說明 |
| 歷史檔案清單 | `/historyapi/v1/getMetadata/{dataid}` | 可依當前文件使用 `format`、`limit`、`offset`、`timeFrom`、`timeTo` |

Base URL：`https://opendata.cwa.gov.tw`

只使用 HTTPS。下載檔案時允許官方要求的 302 redirect，但要驗證最終回應與內容類型。

## 查找 dataset ID

1. 依使用者要的觀測、預報、警特報、雷達、衛星、海象或氣候主題搜尋官方資料清單。
2. 在 Swagger 確認 dataset ID 是否有 REST endpoint 與哪些查詢參數。
3. 打開資料集說明，確認更新頻率、地理範圍、時間語意、格式與欄位文件。
4. 先用小範圍請求檢查實際回應，再編寫完整解析器。

下列只能當查找起點，不得取代當前官方清單：

- `O-A0001-001`：地面氣象觀測站逐時資料。
- `O-A0002-001`：雨量觀測站資料。
- `F-C0032-001`：行政區短期天氣預報。
- `O-A0059-001`：雷達整合回波相關產品。

每次使用前在 Swagger 或資料集頁確認代碼仍有效且內容符合需求。

## 認證

從秘密變數讀取授權碼，例如 `CWA_API_KEY`。擇一使用：

```bash
curl --fail-with-body --silent --show-error \
  --header "Authorization: ${CWA_API_KEY}" \
  --header "Accept: application/json" \
  "https://opendata.cwa.gov.tw/api/v1/rest/datastore/${DATASET_ID}?format=JSON"
```

或在無法設定 header 時，將授權碼放入 URL query。避免同時使用兩種方式；官方說明指出 header 認證會優先，header 失敗時不會再改用 query 認證。

不要把完整請求 URL（若含 query 授權碼）寫入日誌、錯誤追蹤或分析結果。

## History API 流程

1. 呼叫 `getDataId` 取得目前支援的資料集。
2. 呼叫 `getDataId/{dataid}` 確認供應期間與 metadata。
3. 呼叫 `getMetadata/{dataid}` 取得符合時間範圍的檔案清單。
4. 追蹤回應中的下載 URL，驗證格式與時間後保存原始檔。
5. 若有分頁，直到回傳筆數小於 `limit` 或官方回應顯示結束；設定最大頁數避免無限迴圈。

## 錯誤處理

| 狀況 | 處理 |
|---|---|
| 400 類參數錯誤 | 不重試；檢查 dataset 專屬參數、編碼、時間格式 |
| 401／403 | 不重試；檢查授權碼與會員權限 |
| 404 | 回查官方資料清單、Swagger、公告與 base URL |
| 429 或配額訊息 | 遵守 `Retry-After`；降頻、縮小請求並使用快取 |
| 5xx／網路暫時錯誤 | 僅對冪等 GET 做有限次指數退避與 jitter |
| 200 但內容錯誤 | 檢查 content type、成功旗標、錯誤欄位與 schema |
| 304 | 使用已快取內容，更新檢查時間但不重複解析下載 |

不要無上限重試，也不要把空 records 當作成功取得有效資料。

## 正式整合檢查表

- 將 base URL、dataset ID、格式與查詢條件外部化。
- 設定連線與讀取 timeout。
- 保留 request ID 或可追蹤資訊，但遮蔽密鑰。
- 記錄 dataset ID、HTTP 狀態、資料時間、擷取時間、筆數與 schema 版本指紋。
- 對欄位新增採寬容策略；對必要欄位消失、單位改變或型別改變立即告警。
- 依產品發布節奏排程，不以固定高頻輪詢替代資料成熟判斷。
- 遵守官方顯名與當前使用規範。
