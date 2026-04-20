# GitLab issue comment via API — avoids $(cat) permission prompts
glab api projects/:id/issues/<IID>/notes -F body=@<FILE>
