SHELL := /bin/bash

.PHONY: all clean analysis summary check-env

SRC_FILE = codebase.txt
AI_CLI = ./ask

check-env:
	@test -n "$(ASK_API_URL)" || (echo "Error: ASK_API_URL is not set" >&2; exit 1)
	@test -n "$(ASK_MODEL)" || (echo "Error: ASK_MODEL is not set" >&2; exit 1)
	@test -n "$(ASK_API_KEY)" || (echo "Error: ASK_API_KEY is not set" >&2; exit 1)

all: check-env analysis summary concatenated.md refined.md action.plan.md

analysis: quality.md perf.md security.md
summary: quality.sum.md perf.sum.md security.sum.md

quality.md: $(SRC_FILE) $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Evaluate the provided code focusing on readability, structural issues, and duplication. Generate exactly 5 to 7 bullets formatted as 'problem -> fix'." > $@

perf.md: $(SRC_FILE) $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Assess the code for performance bottlenecks and inefficiencies. Generate exactly 5 to 7 bullets formatted as 'issue -> optimization'." > $@

security.md: $(SRC_FILE) $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Analyze the code for security flaws and unsafe patterns. Generate exactly 5 to 7 bullets formatted as 'risk -> mitigation'." > $@

quality.sum.md: quality.md $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Summarize this code quality report into exactly 5 actionable bullet points. Do not include any extra filler text." > $@

perf.sum.md: perf.md $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Summarize this performance report into exactly 5 actionable bullet points. Do not include any extra filler text." > $@

security.sum.md: security.md $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Summarize this security report into exactly 5 actionable bullet points. Do not include any extra filler text." > $@

concatenated.md: quality.sum.md perf.sum.md security.sum.md
	@printf "## Code Quality\n" > $@
	@cat quality.sum.md >> $@
	@printf "\n## Performance\n" >> $@
	@cat perf.sum.md >> $@
	@printf "\n## Security\n" >> $@
	@cat security.sum.md >> $@

refined.md: concatenated.md $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Act as an expert technical lead. Filter this merged report by removing any duplicated points across the three sections. Keep only the most critical, high-signal issues while preserving the original headings." > $@

action.plan.md: refined.md $(AI_CLI)
	set -o pipefail; cat $< | $(AI_CLI) "Based on this refined report, construct a final 'Engineering Action Plan'. Format the output to clearly display priority (High / Medium / Low), effort estimate (Small / Medium / Large), and an execution order number for each action item." > $@

clean:
	rm -f quality.md perf.md security.md quality.sum.md perf.sum.md security.sum.md concatenated.md refined.md action.plan.md
