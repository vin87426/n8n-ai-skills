# Routable Skill Catalog

本文件是 `$route-repo-skills` 的 runtime allowlist。只有下列三個二級標題中的 skill 可以成為 target。`route-repo-skills` 是控制層，不得成為 target。

## `get-cwa-weather-data`

路由條件：

- 使用者要查找、取得、解析或驗證臺灣 CWA 官方氣象資料。
- 使用者指定 CWA dataset ID、REST／File／History API、下載格式、認證、schema、ETL 或錯誤排查。
- 使用者要的是原始／整理後的觀測、預報、警特報、雷達、雨量或歷史資料，而不是潛水適合度分析。

不要路由：

- 問題核心是某潛點現在能否考慮下水；改用 `dive-site-nowcast-analysis`。
- 問題核心是比較未來日期、時段或潛點；改用 `dive-site-forecast-analysis`。
- 非臺灣氣象資料或與 CWA 無關的一般 API 任務。

最小可開始輸入：明確資料目標，以及地點／dataset ID／時間範圍三者至少一項。詳細欄位見 [handoff schema](handoff-schema.md)。

## `dive-site-nowcast-analysis`

路由條件：

- 使用者詢問潛點現在、現場、今天稍後或未來約 1–3 小時的狀況。
- 使用者要判斷即時進出水、浪況、Surge、海流、漂流、能見度、快速惡化或預報與觀測偏差。
- 請求包含 CWA／浮標／雷達等資料需求，但最終目標是潛點即時風險分析。

不要路由：

- 分析窗口主要落在 3 小時後、明天、週末或未來七天；改用 `dive-site-forecast-analysis`。
- 只要求 CWA 資料或 API 操作，不要求潛點判讀；改用 `get-cwa-weather-data`。

最小可開始輸入：潛點識別資訊與分析基準時間。詳細欄位見 [handoff schema](handoff-schema.md)。

## `dive-site-forecast-analysis`

路由條件：

- 使用者規劃主要落在未來 3 小時後至七天內的潛水日期或時段。
- 使用者要比較日期、時段或多個潛點，尋找相對較佳時窗，或分析未來浪、風、潮、流、降雨與能見度趨勢。
- 請求包含氣象資料需求，但最終目標是未來潛點風險與時窗比較。

不要路由：

- 問題只關心現在到未來約 1–3 小時；改用 `dive-site-nowcast-analysis`。
- 只要求 CWA 資料、API 範例或資料處理；改用 `get-cwa-weather-data`。
- 超過七天且使用者要求精確潛點條件；回報目前 repo skill 範圍不足，或要求縮小時間範圍。

最小可開始輸入：潛點識別資訊與未來時間範圍。詳細欄位見 [handoff schema](handoff-schema.md)。

# Routing Precedence

依序判斷：

1. 先判斷最終產物：資料／程式整合，或潛點風險分析。
2. 潛點風險分析以目標時間範圍區分 nowcast 與 forecast。
3. CWA 是潛點分析的資料來源時，不因此把 primary target 改成 `get-cwa-weather-data`。
4. 同一請求同時要求現在與未來日期時，拆成 nowcast 與 forecast 兩個原子子請求；不要建立第三種混合路由。
5. 不屬於以上三種 target 時回傳 `unsupported`，不得調用其他 skill。

# Catalog Maintenance Rules

- 新增、移除或重新命名 repo skill 時，同一個 commit 更新本 allowlist。
- 修改 skill description、觸發邊界、必要輸入、時間範圍或依賴時，同一個 commit 更新對應段落與 handoff schema。
- 保持每個 routable skill 使用精確的 `name` frontmatter 值。
