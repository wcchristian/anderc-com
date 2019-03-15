workflow "New workflow" {
  on = "project_column"
  resolves = ["GitHub Action for Slack"]
}

action "GitHub Action for Slack" {
  uses = "Ilshidur/action-slack@29b0e336b25543954d1b82d41d3a3ee83f0e1538"
  secrets = ["SLACK_WEBHOOK"]
  args = "\"Test Message\""
}
