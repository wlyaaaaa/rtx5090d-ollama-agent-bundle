# 定期备份工作流

目标：把公开安全的 Ollama 配置、模板和文档定期提交到 GitHub。

## 原则

- 只提交白名单文件。
- 不提交模型权重、manifest、日志、`.bak`、真实 GUI 配置和密钥。
- 提交前必须跑敏感信息扫描。
- 自动推送到 `codex/public-config-backup` 分支；通过 PR 合并到 `main`。

## 手动执行

```powershell
.\scripts\10_public_config_backup_to_github.ps1 -Apply
```

## 默认白名单

- `README.md`
- `00_README_FIRST.md`
- `03_ACCEPTANCE_TESTS.md`
- `GUI_MODEL_DISPLAY_POLICY.md`
- `public_config_backup/`
- `configs/Modelfile.*v1*`
- `scripts/05_start_ollama_32100.ps1`
- `scripts/06_stop_ollama_32100.ps1`
- `scripts/09_disable_ollama_firewall_admin.ps1`
- `scripts/10_public_config_backup_to_github.ps1`
- `results/final_report.md`
- `results/reports/audit_report.md`

## 建议频率

每周一次足够。Ollama 配置不需要每天上传；真正变化通常来自模型别名、上下文策略、端口、脚本或文档。
