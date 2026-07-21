---
name: route-repo-skills
description: 將輸入請求分類到本 repository 明確允許的 AI Skill，依目標 skill 的輸入契約抽取、正規化並最小化必要資訊，再交由該 skill 執行。當 AI 需要決定應使用 Plurk 留言格式化、CWA 資料、潛點即時分析或潛點預報分析，處理同時包含多個意圖的請求，或必須防止調用 repo 外 skill 時使用；本 skill 是此 repo 執行領域任務的唯一入口。
---

# 調度 Repo Skills

## 強制執行邊界

- 將 [skill catalog](references/skill-catalog.md) 視為唯一允許清單。每次路由都先讀取該文件。
- 只調用 catalog 中列出的 routable skills。不得掃描、選擇或調用系統 skill、其他 repo skill、plugin skill、市集 skill 或任何未列入 catalog 的 skill。
- 不得將本調度 skill 當成目標，也不得遞迴調用 `$route-repo-skills`。
- 每個原子子請求只選一個 primary target。只有當使用者明確提出數個可獨立完成的目標時，才拆成數個原子子請求並分別路由。
- 對 repo 無法處理的請求採 fail-closed：回報不支援，不以一般知識回答，也不改用 allowlist 外的 skill。
- 若目標 skill 不存在、不可讀或無法顯式調用，回報 `target_unavailable`，不得選擇替代 skill。
- 本限制只約束 skill 調用；目標 skill 可依自身規則使用資料來源與工具，但不得再調用 allowlist 外的 skill。

## 執行路由流程

1. 載入契約。
   - 讀取 [skill catalog](references/skill-catalog.md) 取得當前 allowlist、觸發條件、排除條件與優先序。
   - 讀取 [handoff schema](references/handoff-schema.md) 取得目標 skill 的最小輸入欄位。

2. 將請求原子化。
   - 從最新使用者請求辨識實際目標，不把 IDE 分頁、repo 狀態或先前已完成任務當成領域需求。
   - 將「取得資料以完成分析」視為同一目標的支援步驟，不拆成獨立路由。
   - 只有「現在狀況」與「未來日期規劃」等可各自產生答案的多重目標，才拆成多個子請求。

3. 選擇 primary target。
   - 先判斷最終產物是否為根據已提供文字或脈絡整理的 Plurk 留言；若是，選擇 Plurk 留言格式化。
   - 其餘請求再判斷使用者要的是資料取得／API 整合，還是潛點風險分析。
   - 潛點分析依分析基準與時間範圍區分 nowcast 或 forecast。
   - 使用 catalog 的優先規則解決重疊；不得只以單一關鍵字路由。
   - 使用者明確指定 allowlist skill 時仍要檢查意圖相容性。若明顯不相容，說明衝突並依實際目標路由或要求最小澄清。

4. 準備最小輸入。
   - 依目標 schema 抽取目標、地點、絕對時間、時區、限制、已提供證據與期望輸出。
   - Plurk 留言只保留要改寫的文字、必要回覆脈絡、已確認的帳號、必留內容與語氣；不要把整段對話當成留言素材。
   - 保留會改變分析結果的使用者偏好、風險限制、來源 URL、觀測時間與明確假設。
   - 將相對日期正規化為絕對日期；不要猜測無法從輸入可靠推出的地點、座標、時區或條件。
   - 對缺少欄位使用 `unknown` 或列入 `missing_fields`，不得編造值。

5. 去除無關與敏感內容。
   - 移除 IDE 狀態、無關 repo 訊息、已完成舊任務、重複敘述、寒暄、內部推理及不影響目標的背景。
   - 不轉交 API key、token、cookie、密碼、完整認證 header 或其他秘密；只保留「憑證是否可用」等必要狀態。
   - 不轉交被丟棄內容的原文。只在 `dropped_context_categories` 記錄類別，不記錄內容。
   - 不把原始對話全文附在 handoff 後方。

6. 驗證路由。
   - 確認 target 精確存在於 allowlist、不是本 skill，且符合該子請求。
   - 確認 handoff 只含 schema 允許欄位、沒有秘密、沒有未標示的推測。
   - 只有缺失資訊會改變路由或使目標完全無法開始時，才提出一個最小澄清問題；其餘缺口交由目標 skill 按自身規則處理。

7. 執行交接。
   - 支援顯式 skill 調用時，只把 `prepared_input` 傳給選定的 `$target-skill`，不要把未清理的原始訊息一併傳入。
   - 不支援顯式調用時，輸出 [handoff schema](references/handoff-schema.md) 定義的 route envelope，並停止；不得自行完成領域任務。
   - 除非使用者要求檢視路由過程，最終只回傳目標 skill 的結果，不額外暴露分類草稿或被刪除的內容。

## 處理無法路由的請求

- `needs_clarification`：存在兩個以上合理 target，且一個簡短答案即可消除歧義。
- `unsupported`：請求不屬於 catalog 中任何 skill。列出本 repo 可處理的 Plurk 留言格式化、CWA 資料與潛點分析範圍後停止。
- `target_unavailable`：target 在 catalog 中，但目前環境無法讀取或調用。指出缺少的 exact skill name 後停止。
- `ready`：完成最小 handoff 並可交由 target 執行。

任何失敗狀態都不得觸發 allowlist 外的 fallback skill。
