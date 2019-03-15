workflow "New workflow" {
  resolves = [
    "GitHub Action for Slack",
    "Close Issue",
  ]
  on = "project_card"
}

action "GitHub Action for Slack" {
  uses = "Ilshidur/action-slack@29b0e336b25543954d1b82d41d3a3ee83f0e1538"
  secrets = ["SLACK_WEBHOOK"]
  args = "\"Test Message\""
}

action "Close Issue" {
  uses = "swinton/httpie.action@8ab0a0e926d091e0444fcacd5eb679d2e2d4ab3d"
  args = ["--auth-type=jwt", "--auth=$GITHUB_TOKEN", "PATCH", "`jq .url /github/home/Issue.response.body --raw-output`", "state=closed"]
  secrets = ["GITHUB_TOKEN"]
}