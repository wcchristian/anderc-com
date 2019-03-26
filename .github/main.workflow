workflow "New workflow" {
  resolves = ["Build Hugo Site"]
  on = "push"
}

action "Build Hugo Site" {
  uses = "wcchristian/gh-action-hugo-build@master"
}
