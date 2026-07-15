# AI Skill Repository Development Rules

本文件適用於整個 repository。

## Router invariant

- 將 `route-repo-skills` 視為所有領域請求的唯一入口。
- 只有 `route-repo-skills/references/skill-catalog.md` 列出的 skill 可以成為 runtime target。
- 保持 router 可隱式觸發；保持所有 target skills 的 `policy.allow_implicit_invocation` 為 `false`，讓 target 只能被顯式選取。
- 不得在 target skill 中引入 repo 外 skill 依賴。需要外部資料時使用工具或資料來源，不要調用 allowlist 外的 skill。

## Required router sync before every commit

每次 commit 前都必須檢查 staged diff 對 router 契約的影響。不得因改動看似小就略過。

1. 執行 `git diff --cached --name-status`，列出本次實際要提交的檔案。
2. 重新盤點所有 `*/SKILL.md` 的 `name` 與 `description`。
3. 開啟並審核：
   - `route-repo-skills/SKILL.md`
   - `route-repo-skills/references/skill-catalog.md`
   - `route-repo-skills/references/handoff-schema.md`
4. 依改動同步 router：
   - 新增、刪除、重新命名 skill：更新 allowlist、路由優先序與 handoff schema。
   - 修改 description、觸發條件、時間邊界或排除條件：更新 catalog 與必要的核心路由規則。
   - 修改必要／選填輸入、資料依賴、秘密處理或輸出契約：更新 handoff schema 與 catalog 摘要。
   - 修改 `agents/openai.yaml` 的可調用政策：確認只有 router 可隱式觸發。
   - 只修改不影響路由契約的文字時，仍須完成審核；不製造無意義的 router 文字變更。
5. 將必要的 router 更新與目標 skill 改動放在同一個 commit，不得延後到下一個 commit。

## Pre-commit checks

提交前必須：

1. 執行 `scripts/check-router-sync.sh`。
2. 對 repo 中每個 skill 執行 `quick_validate.py <skill-directory>`。
3. 執行 `git diff --cached --check`。
4. 確認 staged diff 未包含憑證、token、測試用秘密或無關產物。
5. 若修改 router、觸發條件或 handoff schema，使用至少以下案例做路由測試：
   - CWA API／資料請求
   - 潛點現在至三小時 nowcast
   - 潛點明天至七天 forecast
   - 同時包含現在與未來日期的複合請求
   - repo 不支援的請求，必須得到 `unsupported`

不得略過失敗的檢查。若 validator 或 sync checker 無法執行，先修復開發環境或在 commit 前取得維護者明確同意。

## Skill authoring rules

- 使用 lowercase hyphen-case 資料夾名稱，且必須與 frontmatter `name` 完全一致。
- 使用大寫 `SKILL.md`；frontmatter 只能包含 `name` 與 `description`。
- 將核心流程保留在 `SKILL.md`，詳細契約與資料放在單層 `references/`。
- 更新 skill 後同步檢查 `agents/openai.yaml`，並使用 skill-creator 的產生器重建過時 metadata。
- 不新增 README、CHANGELOG、quick reference 或其他與 skill 執行無直接關係的輔助文件。
