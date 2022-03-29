---
date: 2022-03-27T07:16:36Z
title: "Deploy Gokit Todo to Gae With Cloud Build From Github Repo"
draft: true
description: TODO
tags:
  - gokit
  - todomvc
  - gcp
  - gae
  - postgres
  - cloudsql
resources:
  - name: "featured-image-preview"
    src: "img/placeholder.png"
toc: true
---

<!--more-->

## gokit-todo 

https://github.com/cage1016/gokit-todo

>todomvc full stack demo project. react + backend API by gokit microservice toolkit. include unit test, integration test, e2e test, github action ci

{{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/demo.gif" alt="gokit-todo demo">}}

之前的專案搭建一個以 golang gokit 微服務為後端 API (資料儲存使用 Postgres) + React todo 為前端的範例，可以部署在 Kubernets 搭配 Ingres (Istio / Nginx-ingress) 或是 docker-compose 的方式來執行。有興趣的朋友可以到 Github Repo 查看操作方式

## migrate gokit-todo to GAE & Cloud SQL

在我們將 gokit-todo 從 kubernetes 搬到 Google App Engine 上前，我們需要先對 Google App Engine 有一些了解。來確保我們這一個想法是可行的

1. Google App Engine 是一個 PasS (platform as a service) 層級的服務，也就是我們只需要專注在應用程式的開發，底層 OS 的部份由 Cloud vendor 負責。所以我們可以重複使用 gokit-todo, gokit-todo-frontend 中的程式碼 + Google App Engine 相關的 `app.yaml` 即可 ✅
1. Google App Engine 支援的 standard-runtime (`Python`, `Java`, Node.`js`, `PHP`, `Ruby`, `Go`) 及 flexible-runtime (`Go`, `Java 8`, `PHP 5/7`, `Python 2.7/3.6`, `.NET`, `Node.js`, `Ruby`, `Custom runtime`)。
   - gokit-todo 作為單純 API 後端只需要使用 standard-runtime Go 1.16 即可 ✅
   - gokit-todo-frontentd 使用 React 編寫，我們也可以選擇使用 standard-runtime Node.js 16 即可 ✅
1. Gokit-todo 微服務接介的是 Postgres，在 Google App Engine 的環境中可以使用 Cloud SQL 來替代資料庫的腳色。要注意的地方是，得使用 Cloud SQL proxy 提供的 driver `cloudsqlpostgres`，這一個 driver 會幫你處理一些接介 Cloud SQL 上的認證問題，所以資料庫的部份也沒問題 ✅
1. Google App Engine 支援多個獨立的服務，再透過 `disptach.yaml` 的設定來串起多個服務之間的關係。Gokit-todo backend、Gokit-doto frontend 在 `dispatch.yaml` 的設定之下就可以達到微服務的效果 ✅
1. CI/CD 的部份可以使用 Google Cloud Build 來編寫，也可以整合 Github。要注意的部份就是 Cloud Build 設定服務帳號 `project-number@cloudbuild.gserviceaccount.com` 需要給定足夠的權限 ✅

## gokit-todo-gae

{{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/placeholder.png" alt="gokit-todo-gae architecture">}}

上圖為基本架構圖，我們新建立一個專案 [cage1016/gokit-todo-gae](https://github.com/cage1016/gokit-todo-gae)，並將 [cage1016/gokit-todo](https://github.com/cage1016/gokit-todo) 及 [cage1016/gokit-todo-frontend](https://github.com/cage1016/gokit-todo-frontend) 加到 submodule 中把 Google App Engine 相關的設定獨立開來，這樣有一個好處就是可以讓原專案的人專注在開發上，盡量降底非開發的任務綁定來降低隅合性

**[cage1016/gokit-todo-gae](https://github.com/cage1016/gokit-todo-gae)**

```sh
.
├── api                       // gokit-todo sudmodule as api service
├── default                   // gokit-todo-frontend as default service
├── .gitmodules
├── cloudbuild.api.yaml       // deploy api service (Manual)
├── cloudbuild.default.yaml   // deploy default service (Manual)
├── cloudbuild.dispatch.yaml  // deploy dispatch.yaml
└── dispatch.yaml             // gokit-todo-gae dispatch yaml
```

基本上的檔案架構跟上圖架構圖是一致的，操作流程如下

1. 前端人員將修改後的程式推送至 `gokit-todo-frontend` 👉 `cloudbuild.yaml` 會被 Google Cloud Build 觸發進行對應的任務 ex: Test，最後一個動作透過 curl 觸發 `gokit-todo-gae` 上的 trigger `gokit-todo-gae-deploy-default` 👉 `gokit-todo-gae-deploy-default` 會執行 `cloudbuild.default.yaml` 中的任務進行 React Todomvc 進行編擇並部署至 Google App Engine

      __cloudbuild.yaml__
      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/gokit-todo-frontend-cloudbuild.yaml.jpg" alt="gokit-todo-frontend cloudbuild.yaml">}}

      __cloudbuild.default.yaml__
      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/gokit-todo-gae-cloudbuild.default.yaml.jpg" alt="gokit-todo-gae deploy default service">}}

1. 後端人員將修改後的程式推送至 `gokit-todo` 👉 `cloudbuild.yaml` 會被 Google Cloud Build 觸發進行對應的任務 ex: Test，最後一個動作透過 curl 觸發 `gokit-todo-gae` 上的 trigger `gokit-todo-gae-deploy-api` 👉 `gokit-todo-gae-deploy-api` 會執行 `cloudbuild.api.yaml` 中的任務進行部署至 Google App Engine

      __cloudbuild.yaml__
      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/gokit-todo-cloudbuild.yaml.jpg" alt="gokit-todo cloudbuild.yaml">}}

      __cloudbuild.api.yaml__
      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/gokit-todo-gae-cloudbuild.api.yaml.jpg" alt="gokit-todo-gae deploy api service">}}

1. 如果需要更動 Google App Engine 上的 dispatch 設定。可以修改 `dispatch.yaml` 推送至 `gokit-todo-gae` 👉 `cloudbuild.dispatch.yaml` 會進行 dispatch 設定的部署

      __cloudbuild.dispatch.yaml__
      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/cloudbuild.dispatch.yaml.jpg" alt="gokit-todo-gae deploy dispatch.yaml">}}

      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/cloudbuild-trigger.jpg" alt="Cloud Build triggers">}}