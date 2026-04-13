gh api 'repos/{owner}/{repo}/pulls?state=all&per_page=1' -i 2>&1 | grep -i 'link:'
