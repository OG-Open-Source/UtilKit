#!/usr/bin/env bash

function var::empty() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do
		[[ -z ${v} ]] || return 1
	done
}
function var::set() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do
		[[ -v ${v} ]] || return 1
	done
}
function var::valid() {
	(($# == 0)) && return 2
	local v
	for v in "$@"; do
		[[ -n ${v} ]] || return 1
	done
}

function io::err() {
	if var::valid "$@"; then
		printf "%b\n" "${CLR[1]}$*${CLR[0]}" >&2
	fi
}
function io::err_die() {
	if var::valid "$@"; then
		printf "%b\n" "${CLR[1]}$*${CLR[0]}" >&2
		return 1
	fi
}
function io::raw() {
	printf "%b" "$*"
}
function io::txt() {
	if var::valid "$@"; then
		printf "%b\n" "$*"
	fi
}

function fs::dir_exist() {
	var::valid "$@"
	local d
	for d in "$@"; do
		[[ -d ${d} ]] || return 1
	done
}
function fs::file_exist() {
	var::valid "$@"
	local f
	for f in "$@"; do
		[[ -f ${f} ]] || return 1
	done
}
function fs::file_valid() {
	var::valid "$@"
	local f
	for f in "$@"; do
		[[ -s ${f} ]] || return 1
	done
}
function fs::file_grep() {
	(($# < 2)) && return 2
	command -v grep &>/dev/null || return 126

	local args=() files=()
	for arg in "$@"; do
		if [[ ${arg} =~ ^- ]]; then
			args+=("${arg}")
		else
			files+=("${arg}")
		fi
	done

	if ((${#files[@]} >= 2)); then
		for file in "${files[@]:1}"; do
			[[ ! (-f ${file} && -r ${file} && -s ${file}) ]] && return 2
		done
	fi

	command grep "$@"
}
function fs::path_exist() {
	var::valid "$@"
	local p
	for p in "$@"; do
		[[ -e ${p} || -L ${p} ]] || return 1
	done
}
function fs::perm_read() {
	var::valid "$@"
	local p
	for p in "$@"; do
		[[ -r ${p} ]] || return 1
	done
}
function fs::perm_write() {
	var::valid "$@"
	local p
	for p in "$@"; do
		[[ -w ${p} ]] || return 1
	done
}
function fs::perm_exec() {
	var::valid "$@"
	local p
	for p in "$@"; do
		[[ -x ${p} ]] || return 1
	done
}
