---
title: 'Hosting on Amazon S3'
date: 2018-12-20T18:29:47-06:00
draft: false
featuredImg: ''
tags:
    - dev
---

# Introduction

A few different times, I've hosted a personal site to blog, use as a portfolio, photo gallery, etc. Each and every time I ended up tearing it down (or not setting it back up again after moving hosts). In those days, I was using a VPS running nginx to host my site and had a seperate server I was running for a blog.

Getting to the point, I think a lot of times that I've tried to run a site before and failed it has been because of the following reasons.

-   Site is a pain to deploy / write posts for.
-   Site costs too much for what it benefits me.

I figured that if I could make a site work that is easier to publish posts and make improvements without having to ssh and redeploy every time, I might actually keep this whole writing thing up!

I decided to host on AWS. [Dan Salmon](https://danthesalmon.com) mentioned that hosting a hugo site with S3 and cloudfront was super easy and reletively inexpensive.

Below is my attempt at setting this up. It's breif and to the point since I believe that there are too many tutorials out there that aren't straight forward. I'm hoping this is nice and clear. If you have questions please reach out to me at anderc(at)protonmail(dot)com and I can try and update this as needed.

# Pieces of the Puzzle

## Hugo

Hugo is my static site generator of choice for this project. I won't say much about it here since there are a ton of articles about how to use it.

To prepare for running through the steps below, build a basic hugo site or any other static website to host.

## S3

1. Go to S3 and create a new bucket with the domain name of the site you wish to host.
1. Upload your static website into the bucket.
1. Navigate to the Permissions area for the bucket and add the following (change example.com to your bucket name)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::example.com/*"
        }
    ]
}
```

4. Go to properties for the bucket and click on Static Website Hosting.
5. Enter your index.html document and your 404.html document in the fields provided.
6. Note the endpoint listed here. Attempt to reach your site.

If you can reach your site here, move on to generating the certificate.

## Certificate Manager

1. Navigate to the AWS certificate manager.
1. Request a public certificate
1. enter your root domain (example.com)
1. Enter a wildcard domain (\*.example.com)
1. Choose either DNS or Email Validation (DNS is really easy if route53 is your registrar)
1. Validate both domains and wait for them to become issued.

## Cloudfront

1. Navigate to Cloudfront in AWS
1. Click to create a new distribution
1. Set Origin Domain Name to the endpoint listed in S3
1. Set Viewer Protocol Policy to Redirect HTTP to HTTPS
1. Ensure that cache is set up properly (Or you will have a tough time reloading and testing.)
1. Set Altername Domain Names www.example.com and example.com (whatever your domain is.)
1. Set SSL Certificate to Custom and select the certificate you generated in the certificate manager.
1. Click to create the distribution and wait for it to be deployed. (When it is, try and access it via it's domain name)

This could take a while to deploy.

## Route 53

1. Create a new hosted zone for your domain.
1. Create an A record with nothing as subdomain, use the alias feature and point it at your cloudfront distribution.
1. Create another A record with www as subdomain, again use the alias feature and point it at your cloudfront distribution.

After this propotgates, you should be able to access your site via your domain name. You should see a certificate from Amazon and should see network requests are coming from S3.

## Circle CI setup

I've been using Circle CI for a while for my projects. It's pretty slick and easy to set up and allows private and public repos with it's free version up to a set number of build minutes per month.

To set this up for your project, add the integration to github. Once added navigate to the circle ci UI and click Projects and add the repo for your static site.

Next, head to AWS IAM User area and create a new user with S3 access, you should receive a few keys (SAVE THESE SOMEWHERE SECURE)

After the keys are generated, copy them and save them in the Environment Variables section of your circle CI project.
With the keys, you can set the following variables.

```
AWS_ACCESS_KEY_ID = {Enter your key}
AWS_SECRET_ACCESS_KEY = {Enter your secret access key}
S3_BUCKET_URL = example.com (should be whatever your bucket name is)
```

After this is complete, add a new file to your repo ate .circleci/config.yml

```yaml
version: 2
jobs:
    build:
        docker:
            - image: circleci/python
        steps:
            - checkout
            - run:
                  name: Clean Repo
                  command: 'rm -rf public'
            - run:
                  name: Build Site
                  command: './tools/hugo-linux'
            - persist_to_workspace:
                  root: public
                  paths:
                      - ./*

    artifact:
        docker:
            - image: circleci/python
        steps:
            - attach_workspace:
                  at: public
            - store_artifacts:
                  path: ./public

    deploy:
        docker:
            - image: circleci/python
        environment:
            FOO: $S3_BUCKET_URL
        steps:
            - attach_workspace:
                  at: public
            - run:
                  name: Install AWS CLI
                  command: sudo pip install awscli
            - run:
                  name: Deploy to S3
                  command: aws s3 sync public s3://$S3_BUCKET_URL

workflows:
    version: 2
    build-deploy:
        jobs:
            - build
            - artifact:
                  requires:
                      - build
                  filters:
                      branches:
                          only: master
            - deploy:
                  requires:
                      - build
                      - artifact
                  filters:
                      branches:
                          only: master
```

the config is pretty straight forward. Let's talk about the top part first. I am configuring three jobs.

### Jobs

The build job simply clears the public directory and rebuilds the site.

The job also sets up a workspace so that files can be used in multiple jobs without rebuilding.

The artifact job simply artifacts the public directory (which is our site).

The deploy job installs the AWS CLI and syncs the public directory to the s3 bucket.

### Workflow

The workflow simply says.

```
ALWAYS build
IF master then artifact
IF master then deploy
```

This is set up so that I can develop in a branch and push to master when I want this thing to go live.

An alternative would be to set up a staging branch that deploys to it's own S3 bucket. that way you can test out your changes online before deploying to the main domain.
