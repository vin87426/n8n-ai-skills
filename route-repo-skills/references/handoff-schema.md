# Target Handoff Schema

路由器只能傳送本文件列出的欄位。省略無值的選填欄位；不可附加原始對話全文。

## 目錄

- [Route envelope](#route-envelope)
- [Common rules](#common-rules)
- [`get-cwa-weather-data` input](#get-cwa-weather-data-input)
- [`dive-site-nowcast-analysis` input](#dive-site-nowcast-analysis-input)
- [`dive-site-forecast-analysis` input](#dive-site-forecast-analysis-input)
- [Pruning checklist](#pruning-checklist)

## Route envelope

環境無法直接調用 target，或使用者要求查看路由時，輸出：

```yaml
routing:
  status: ready | needs_clarification | unsupported | target_unavailable
  target_skill: repo-skill-name | null
  reason: 一句話，僅描述意圖與 target 的匹配
  atomic_request_index: 1
  atomic_request_count: 1
prepared_input: {}
missing_fields: []
assumptions: []
dropped_context_categories: []
```

直接調用 target 時只傳送 `prepared_input`。不要將 `reason`、被刪除資訊或 router 內部判斷傳給 target。

## Common rules

所有 `prepared_input` 可包含：

```yaml
objective: 使用者希望 target 完成的單一具體目標
response_language: zh-TW | 使用者指定語言
user_constraints: []
provided_sources:
  - url: optional
    observed_or_issued_at: optional
    description: optional
assumptions: []
unknowns: []
```

- 保留使用者明確提供的數值、單位、日期、時區、座標與限制。
- 將相對日期轉成 `YYYY-MM-DD`；時間使用 `YYYY-MM-DDTHH:mm:ss±HH:mm`，無法確定 offset 時保留當地時間並列入 `unknowns`。
- 不在 `prepared_input` 放入秘密。最多使用 `credentials_available: true | false | unknown`。
- 不要為了填滿 schema 編造選填值。

## `get-cwa-weather-data` input

```yaml
objective: required
location:
  name: optional
  latitude: optional
  longitude: optional
time_range:
  start: optional
  end: optional
  duration_hours: optional
  timezone: optional
data_request:
  category: observation | forecast | warning | radar | rainfall | history | file | unknown
  variables: []
  dataset_id: optional
  access_mode: rest | file | history | unknown
output:
  format: json | table | csv | parquet | netcdf | code | explanation | unknown
  use_case: optional
credentials_available: true | false | unknown
response_language: optional
user_constraints: []
provided_sources: []
assumptions: []
unknowns: []
```

至少保留 `objective`，以及 location、dataset ID、time range 中使用者實際提供的資訊。「未來 36 小時」等相對窗口使用 `duration_hours`；只有時間基準與時區已知時才推導絕對起訖。不要在 router 階段猜 dataset ID。

## `dive-site-nowcast-analysis` input

```yaml
objective: required
site:
  name: required
  entry_point: optional
  latitude: optional
  longitude: optional
analysis_time: optional
timezone: optional
planned_entry_time: optional
planned_exit_time: optional
dive_type: shore | boat | drift | freediving | snorkeling | unknown
diver_profile:
  experience: beginner | intermediate | advanced | unknown
  constraints: []
site_profile:
  entry_type: optional
  coast_orientation: optional
  exposed_direction: optional
  nearby_river_or_outfall: optional
  known_hazards: []
provided_observations: []
response_language: optional
user_constraints: []
provided_sources: []
assumptions: []
unknowns: []
```

只有潛點完全無法辨識時才將其列為 blocking missing field。缺少座標、潛水型態或入／出水時間通常交由 target 明示假設或要求補充。

## `dive-site-forecast-analysis` input

```yaml
objective: required
site:
  name: required
  entry_point: optional
  latitude: optional
  longitude: optional
time_range:
  start: required
  end: required
  timezone: optional
target_windows: []
dive_type: shore | boat | drift | freediving | snorkeling | unknown
comparison:
  dates: []
  sites: []
  priorities: []
diver_profile:
  experience: beginner | intermediate | advanced | unknown
  constraints: []
site_profile:
  entry_type: optional
  coast_orientation: optional
  exposed_direction: optional
  bottom_type: optional
  nearby_river_or_outfall: optional
  known_hazards: []
response_language: optional
user_constraints: []
provided_sources: []
assumptions: []
unknowns: []
```

相對日期可依已知當地日期正規化；若時區會改變日期而無法判定，提出最小澄清。不要把超過七天的精確分析範圍靜默截短。

## Pruning checklist

交接前刪除：

- IDE active file、open tabs、游標位置與無關 repo 狀態
- 與當前原子請求無關的先前任務、舊地點、舊日期或舊輸出偏好
- 重複內容、寒暄、情緒性填充與內部 chain-of-thought
- API key、token、cookie、密碼與認證 header
- router 自己的 catalog、路由規則與候選評分

保留：

- 會改變 target 結果的事實、限制、來源、時間與使用者偏好
- 使用者已提供且仍具時效的觀測或預報資料
- 明確標記的假設與未知值
