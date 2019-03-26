workflow "Deploy" {
  on = "push"
  resolves = ["GitHub Action for Slack", "Deploy to S3"]
}

action "Build Hugo Site" {
  uses = "wcchristian/gh-action-hugo-build@master"
}

action "Filter: Master Branch" {
  uses = "actions/bin/filter@d820d56839906464fb7a57d1b4e1741cf5183efa"
  needs = ["Build Hugo Site"]
  args = "branch master"
}

action "Deploy to S3" {
  uses = "actions/aws/cli@efb074ae4510f2d12c7801e4461b65bf5e8317e6"
  needs = ["Filter: Master Branch"]
  secrets = [
    "AWS_ACCESS_KEY_ID",
    "AWS_SECRET_ACCESS_KEY",
    "ANDERC_S3_BUCKET_URL",
  ]
  args = "s3 sync public s3://$ANDERC_S3_BUCKET_URL --delete"
  env = {
    FOO = "bar"
  }
}

action "GitHub Action for Slack" {
  uses = "Ilshidur/action-slack@4f4215e15353edafdc6d9933c71799e3eb4db61c"
  needs = ["Deploy to S3"]
  secrets = ["SLACK_WEBHOOK"]
  args = "anderc.com build successful! Commit: $GITHUB_SHA"
}
