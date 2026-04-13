#!/usr/bin/env bash

# step_exec runs each module's exec block in definition order.
# Tracks hashes in env.yaml to skip unchanged blocks.
# Prompts before each exec unless --yes. --force ignores hashes.
# Returns count of exec blocks that ran (or would run in dry-run).
step_exec() {
	local manifest="$1"
	log_verbose_info "exec: running module exec blocks"

	local count
	count=$(echo "$manifest" | yq -r '[.modules[] | select(.exec)] | length')

	if [[ "$count" -eq 0 ]]; then
		log_ok "exec: no exec blocks"
		echo "0"
		return 0
	fi

	local pending=0
	for ((i = 0; i < count; i++)); do
		local name
		name=$(echo "$manifest" | yq -r "[ .modules[] | select(.exec) ] | .[$i].name")
		local exec_block
		exec_block=$(echo "$manifest" | yq -r "[ .modules[] | select(.exec) ] | .[$i].exec")

		# hash check: skip if unchanged (unless --force)
		local hash
		hash=$(printf '%s' "$exec_block" | sha256sum | cut -d' ' -f1)
		local stored_hash
		stored_hash=$(env_get_hash "$name")

		if [[ "$FORCE_EXEC" != true && "$hash" == "$stored_hash" ]]; then
			log_verbose "exec: $name unchanged, skipping"
			continue
		fi

		pending=$((pending + 1))

		if [[ "$DRY_RUN" == true ]]; then
			log_info "exec: [dry-run] would run exec for '$name'"
			continue
		fi

		# interactive confirmation (unless --yes)
		if [[ "$AUTO_YES" != true ]]; then
			if ! gum confirm "Run exec for '$name'?"; then
				log_warn "exec: skipped '$name'"
				continue
			fi
		fi

		log_info "exec: running '$name'"
		(set +u; eval "$exec_block")
		env_set_hash "$name" "$hash"
	done

	echo "$pending"
}
