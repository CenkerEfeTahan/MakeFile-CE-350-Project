# Automated Codebase Review Pipeline

This repository contains a GNU Make-based pipeline that automates codebase review using a Large Language Model (LLM). It analyzes a given codebase for quality, performance, and security issues in parallel, summarizing and refining the results into a final engineering action plan.

## Project Structure

```text
.
├── ask             # Bash script for API interaction with the LLM
├── codebase.txt    # Sample target code to be analyzed
├── Makefile        # Contains the DAG orchestration for parallel execution
└── README.md       # Project documentation
```

## Requirements

The `ask` script requires:
* `bash`
* `curl`
* `jq`
* A valid Groq API key (or any OpenAI-compatible endpoint)

## Setup

1. Make the `ask` script executable:
   ```bash
   chmod +x ask
   ```

2. Set your API key as an environment variable in your terminal:
   ```bash
   export GROQ_API_KEY="your_actual_api_key_here"
   ```

## Run the Pipeline

Run the pipeline using GNU Make with parallel execution enabled:
```bash
make -j
```
*The `-j` flag allows Make to execute independent targets simultaneously, significantly speeding up the process.*

The final output will be:
`action.plan.md`

## Clean Generated Files

To remove all generated markdown files and artifacts, run:
```bash
make clean
```

## Pipeline Flow

```text
codebase.txt
 ├── quality.md    ── quality.sum.md
 ├── perf.md       ── perf.sum.md
 └── security.md   ── security.sum.md
                            ↓
                     concatenated.md
                            ↓
                        refined.md
                            ↓
                      action.plan.md
```

## How the Pipeline Works

1. **Phase 1 (FAN-OUT):** The pipeline starts with `codebase.txt`. Make runs three independent analysis targets (`quality.md`, `perf.md`, `security.md`) in parallel. Each generates a 5-7 bullet point report.
2. **Phase 2 (LOCAL SUMMARIZATION):** Each raw analysis result is summarized into exactly 5 actionable bullet points (`quality.sum.md`, `perf.sum.md`, `security.sum.md`).
3. **Phase 3 (CONCAT REPORT):** The three summaries are merged into a single file (`concatenated.md`). This step strictly uses shell tools (`printf` and `cat`) without any LLM interaction.
4. **Phase 4 (FAN-IN #1):** The concatenated file is sent to the LLM to remove duplicates and keep only high-signal engineering issues, producing `refined.md`.
5. **Phase 5 (FAN-IN #2):** Finally, `refined.md` is processed to generate `action.plan.md`, which includes prioritized actions (High/Medium/Low), effort estimates (Small/Medium/Large), and an execution order.

## Makefile Configuration

Below is the configuration used in this project to enforce strict shell execution and clear dependency graphs (DAG):

```makefile
SHELL := /bin/bash
.PHONY: all clean analysis summary

SRC_FILE = codebase.txt
AI_CLI = ./ask

all: analysis summary concatenated.md refined.md action.plan.md

analysis: quality.md perf.md security.md
summary: quality.sum.md perf.sum.md security.sum.md

quality.md: $(SRC_FILE)
	set -o pipefail; cat $< | $(AI_CLI) "Evaluate the provided code focusing on readability, structural issues, and duplication. Generate exactly 5 to 7 bullets formatted as 'problem -> fix'." > $@

perf.md: $(SRC_FILE)
	set -o pipefail; cat $< | $(AI_CLI) "Assess the code for performance bottlenecks and inefficiencies. Generate exactly 5 to 7 bullets formatted as 'issue -> optimization'." > $@

security.md: $(SRC_FILE)
	set -o pipefail; cat $< | $(AI_CLI) "Analyze the code for security flaws and unsafe patterns. Generate exactly 5 to 7 bullets formatted as 'risk -> mitigation'." > $@

quality.sum.md: quality.md
	set -o pipefail; cat $< | $(AI_CLI) "Summarize this code quality report into exactly 5 actionable bullet points. Do not include any extra filler text." > $@

perf.sum.md: perf.md
	set -o pipefail; cat $< | $(AI_CLI) "Summarize this performance report into exactly 5 actionable bullet points. Do not include any extra filler text." > $@

security.sum.md: security.md
	set -o pipefail; cat $< | $(AI_CLI) "Summarize this security report into exactly 5 actionable bullet points. Do not include any extra filler text." > $@

concatenated.md: quality.sum.md perf.sum.md security.sum.md
	@printf "## Code Quality\n" > $@
	@cat quality.sum.md >> $@
	@printf "\n## Performance\n" >> $@
	@cat perf.sum.md >> $@
	@printf "\n## Security\n" >> $@
	@cat security.sum.md >> $@

refined.md: concatenated.md
	set -o pipefail; cat $< | $(AI_CLI) "Act as an expert technical lead. Filter this merged report by removing any duplicated points across the three sections. Keep only the most critical, high-signal issues while preserving the original headings." > $@

action.plan.md: refined.md
	set -o pipefail; cat $< | $(AI_CLI) "Based on this refined report, construct a final 'Engineering Action Plan'. Format the output to clearly display priority (High / Medium / Low), effort estimate (Small / Medium / Large), and an execution order number for each action item." > $@

clean:
	rm -f quality.md perf.md security.md quality.sum.md perf.sum.md security.sum.md concatenated.md refined.md action.plan.md
```
