#!/usr/bin/env bash
input=$(cat)
IFS=$'\t' read -r cwd model effort ctx_size used rl_5h rl_7d < <(
  echo "$input" | jq -r '[
    .cwd,
    .model.display_name,
    (.effort.level // ""),
    (.context_window.context_window_size // ""),
    (.context_window.used_percentage // ""),
    (.rate_limits.five_hour.used_percentage // ""),
    (.rate_limits.seven_day.used_percentage // "")
  ] | @tsv'
)

time_str=$(date '+%y-%m-%d %T')
user=$(whoami)
host=$(hostname -s)

# 1M context marker
size_str=""
if [ "$ctx_size" = "1000000" ]; then
  size_str=" 1M"
fi

# effort level
effort_str=""
if [ -n "$effort" ]; then
  effort_str="[$effort]"
fi

# rate limits (5h / 7d) — each independently absent
rl_str=""
if [ -n "$rl_5h" ]; then
  rl_str=$(printf "%s 5h:%.0f%%" "$rl_str" "$rl_5h")
fi
if [ -n "$rl_7d" ]; then
  rl_str=$(printf "%s 7d:%.0f%%" "$rl_str" "$rl_7d")
fi

# context usage
if [ -n "$used" ]; then
  ctx_str=$(printf " ctx:%.0f%%" "$used")
else
  ctx_str=""
fi

printf "\033[2;37m[%s]\033[0m \033[2;32m%s@%s\033[0m \033[2;34m%s\033[0m \033[2;33m%s%s\033[0m\033[2;35m%s\033[0m\033[2;36m%s\033[0m%s" \
  "$time_str" "$user" "$host" "$cwd" "$model" "$size_str" "$effort_str" "$rl_str" "$ctx_str"
