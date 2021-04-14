---
date: 2021-04-14T16:23:24+08:00
title: "ghcr.io Pack Build"
draft: false
desc: TODO
tags:
  - ghcr.io
  - registry
  - pack
---

Github 提供了開源的專案免費的 registry，所以寫個文章來記錄一下，如果使用 `.github/workflows/build.yml` 中使用 `pack` 來構建 container image

{{< gist cage1016 0c50cfef8364bbdf0a584722917774de >}}


#### Reference
- [Packages: Container registry now supports GITHUB_TOKEN - GitHub Changelog](https://github.blog/changelog/2021-03-24-packages-container-registry-now-supports-github_token/)