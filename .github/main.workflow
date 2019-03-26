workflow "New workflow" {
  on = "project_card"
  resolves = ["Build Hugo Site"]
}

action "Build Hugo Site" {
  uses = "wcchristian/gh-action-hugo-build@master"
}
