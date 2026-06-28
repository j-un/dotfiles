#!/usr/bin/env zsh
input=$(cat)

# "__END__" sentinel prevents trailing empty field loss from $() newline stripping
f=("${(@f)$(echo "$input" | jq -r '
  .cwd // "",
  .model.display_name // "",
  (.effort.level // ""),
  (.context_window.context_window_size // ""),
  (.context_window.used_percentage // ""),
  (.rate_limits.five_hour.used_percentage // ""),
  (.rate_limits.seven_day.used_percentage // ""),
  (.transcript_path // ""),
  "__END__"
')}")
cwd=$f[1] model=$f[2] effort=$f[3] ctx_size=$f[4]
used=$f[5] rl_5h=$f[6] rl_7d=$f[7] transcript_path=$f[8]

time_str=$(date '+%y-%m-%d %T')
user=$(whoami)
host=$(hostname -s)

size_str=""
[[ $ctx_size == "1000000" ]] && size_str=" 1M"

effort_str=""
[[ -n $effort ]] && effort_str="[$effort]"

rl_str=""
[[ -n $rl_5h ]] && rl_str=$(printf "%s 5h:%.0f%%" "$rl_str" "$rl_5h")
[[ -n $rl_7d ]] && rl_str=$(printf "%s 7d:%.0f%%" "$rl_str" "$rl_7d")

ctx_str=""
[[ -n $used ]] && ctx_str=$(printf " ctx:%.0f%%" "$used")

# cache hit rate (T=last human turn, S=session) and cost save rate
stats=""
if [[ -n $transcript_path && -f $transcript_path ]]; then
  stats=$(jq -nr '
    [inputs] as $all |

    # last assistant entry index
    ($all | to_entries | map(select(.value.type == "assistant")) |
      if length > 0 then (last).key else -1 end) as $la |

    # last *human* user entry before $la (exclude pure tool_result arrays)
    (if $la >= 0 then
      ($all | to_entries | map(select(
        .value.type == "user" and
        .key < $la and
        ((.value.message?.content? // "") |
          (type == "string" or (type == "array" and all(.[]; .type? != "tool_result"))))
      )) | if length > 0 then (last).key else -1 end)
    else -1 end) as $lu |

    [$all[$lu+1:$la+1][] | select(.type == "assistant") | .message?.usage? | select(. != null)] as $T |
    [$all[]               | select(.type == "assistant") | .message?.usage? | select(. != null)] as $S |

    def agg(arr):
      (arr | reduce .[] as $u ({r:0,c:0,i:0};
        .r += ($u.cache_read_input_tokens     // 0) |
        .c += ($u.cache_creation_input_tokens // 0) |
        .i += ($u.input_tokens                // 0)
      )) as $s |
      ($s.r + $s.c + $s.i) as $tot |
      if $tot > 0 then
        (($s.r * 100 / $tot) | round | tostring) as $hit |
        (((1 - ($s.r*0.1 + $s.c*1.25 + $s.i*1.0) / $tot) * 100) | round | tostring) as $save |
        "\($hit)\t\($save)"
      else "-\t-" end;

    "\(agg($T))\t\(agg($S))"
  ' "$transcript_path" 2>/dev/null)
fi

t_hit=- t_save=- s_hit=- s_save=-
[[ -n $stats ]] && IFS=$'\t' read -r t_hit t_save s_hit s_save <<< "$stats"

# Render T and S independently; omit whichever side has no data
hit_parts=() save_parts=()
[[ $t_hit != "-" ]] && hit_parts+=("T${t_hit}%") && save_parts+=("T${t_save}%")
[[ $s_hit != "-" ]] && hit_parts+=("S${s_hit}%") && save_parts+=("S${s_save}%")
cache_str=""
(( ${#hit_parts} > 0 )) && cache_str=$(printf " cache:%s save:%s" "${(j:/:)hit_parts}" "${(j:/:)save_parts}")

printf "\033[2;37m[%s]\033[0m \033[2;32m%s@%s\033[0m \033[2;34m%s\033[0m \033[2;33m%s%s\033[0m\033[2;35m%s\033[0m\033[2;36m%s\033[0m%s\033[2;36m%s\033[0m" \
  "$time_str" "$user" "$host" "$cwd" "$model" "$size_str" "$effort_str" "$rl_str" "$ctx_str" "$cache_str"
