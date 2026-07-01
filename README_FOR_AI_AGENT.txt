AI AGENT INSTRUCTION

Do not execute immediately.
1. Read 00_README_FIRST.md.
2. Perform 01_AUDIT_BEFORE_EXECUTION.md and create results/reports/audit_report.md.
3. Stop if any hard-stop condition is present.
4. Execute tasks in 04_AGENT_TASK_MANIFEST.json in dependency order.
5. Use Dry Run before every PowerShell script.
6. Do not apply or change GPU overclock settings automatically.
7. Treat user-provided RTX 5080 performance and RTX 5090D OC stability as hypotheses until measured.
8. Use 100K as the active post-swap validation context. Do not run the 45K long benchmark on RTX 5080.
9. Keep 256K entries as RTX 5090D post-validation candidates, not the first production default.
10. Do not add SYSTEM prompts to the 100K/256K local models.
11. Do not commit results/backups, results/logs, runtime logs, local config backups, or Ollama model blobs.
12. At the end, produce results/final_report.md with evidence, benchmarks, deviations, and rollback status.
