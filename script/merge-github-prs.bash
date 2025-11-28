#!/bin/bash

confirm() {
  local prompt=${1:-"Are you sure?"}
  local def=${2:-N}   # Y or N (default when user presses Enter)
  local ans suffix

  case "$def" in
    [Yy]) suffix="Y/n" ;;
    [Nn]) suffix="y/N" ;;
    *)    suffix="y/n" ;;
  esac

  while true; do
    read -r -p "$prompt [$suffix] " ans
    [[ -z $ans ]] && ans=$def
    case "$ans" in
      [Yy]|[Yy][Ee][Ss]) return 0 ;;
      [Nn]|[Nn][Oo])     return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}


#gh project item-list --owner orange-cloudfoundry 15 --format json --jq 'select(.items|.[].title=="Dependency Dashboard")'|jq '.items|.[]?.content?.repository'
repositories="$(gh project item-list --owner orange-cloudfoundry 15 --format json |jq -r '.items|.[].content|select(.title=="Dependency Dashboard")|.repository')"

for repo in $repositories;do
	if confirm "Do you want to scan $repo PRs ?" Y; then
	  echo " > processing $repo"
	else
	  echo " > Skipping $repo."
	  continue
	fi
	#gh pr status -R $repo
	#repo="orange-cloudfoundry/node-hardening-release"
	prs="$(gh pr list -R $repo --json number|jq '.[]?.number')"
	if [ -z "$prs" ];then
		echo " > No PRs found for $repo"
	fi

	for pr in $prs;do
		gh pr diff -R "$repo" "$pr"
		if confirm "$repo: Do you want to merge the PR $pr ?" N; then
		  gh pr merge -R "$repo" -d -m "$pr"
		else
		  echo " > Cancelled merge of $repo/pulls/$pr."
		fi
	done
done
