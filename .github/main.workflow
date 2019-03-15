workflow "New workflow" {
  on = "project_column"
  resolves = [
    "GitHub Action for Slack",
    "Close Issue",
  ]
}

action "GitHub Action for Slack" {
  uses = "Ilshidur/action-slack@29b0e336b25543954d1b82d41d3a3ee83f0e1538"
  secrets = ["SLACK_WEBHOOK"]
  args = "\"Test Message\""
}

action "Close issue" {
  uses = "swinton/httpie.action@master"
  args = ["--auth-type=jwt", "--auth=$GITHUB_TOKEN", "PATCH", "`jq .url /github/home/Issue.response.body --raw-output`", "state=closed"]
  secrets = ["GITHUB_TOKEN"]
}
