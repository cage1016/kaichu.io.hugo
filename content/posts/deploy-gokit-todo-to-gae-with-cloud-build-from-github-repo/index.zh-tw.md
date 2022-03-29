---
date: 2022-03-27T07:16:36Z
title: "Deploy Gokit Todo to Gae With Cloud Build From Github Repo"
draft: false
description: gokit-todo，gokit-todo-frontend 願先是編寫在 Kubernetes 的環境上執行，在程式碼套件依賴低、任務相對單純的應用。我們可以很容易的對其進行移轉至 Google App Engine 的環境上來執行，搭配 Google Cloud Build 及 Github 一超進行 CI/CD 的開發流程。
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

## 移轉 gokit-todo gokit-todo-frontent 至 GAE 及 Google  Cloud SQL

在我們將 gokit-todo 從 kubernetes 搬到 Google App Engine 上前，我們需要先對 Google App Engine 有一些了解。來確保我們這一個想法是可行的

1. Google App Engine 是一個 PasS (platform as a service) 層級的服務，也就是我們只需要專注在應用程式的開發，底層 OS 的部份由 Cloud vendor 負責。所以我們可以重複使用 gokit-todo, gokit-todo-frontend 中的程式碼 + Google App Engine 相關的 `app.yaml` 即可 ✅
1. Google App Engine 支援的 standard-runtime (`Python`, `Java`, Node.`js`, `PHP`, `Ruby`, `Go`) 及 flexible-runtime (`Go`, `Java 8`, `PHP 5/7`, `Python 2.7/3.6`, `.NET`, `Node.js`, `Ruby`, `Custom runtime`)。
   - gokit-todo 作為單純 API 後端只需要使用 standard-runtime Go 1.16 即可 ✅
   - gokit-todo-frontentd 使用 React 編寫，我們也可以選擇使用 standard-runtime Node.js 16 即可 ✅
1. Gokit-todo 微服務接介的是 Postgres，在 Google App Engine 的環境中可以使用 Cloud SQL 來替代資料庫的腳色。要注意的地方是，得使用 Cloud SQL proxy 提供的 driver `cloudsqlpostgres`，這一個 driver 會幫你處理一些接介 Cloud SQL 上的認證問題，所以資料庫的部份也沒問題 ✅
1. Google App Engine 支援多個獨立的服務，再透過 `disptach.yaml` 的設定來串起多個服務之間的關係。Gokit-todo backend、Gokit-doto frontend 在 `dispatch.yaml` 的設定之下就可以達到微服務的效果 ✅
1. CI/CD 的部份可以使用 Google Cloud Build 來編寫，也可以整合 Github。要注意的部份就是 Cloud Build 設定服務帳號 `project-number@cloudbuild.gserviceaccount.com` 需要給定足夠的權限 ✅

{{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/placeholder.png" alt="gokit-todo-gae architecture">}}

上圖為基本架構圖，我們新建立一個專案 [cage1016/gokit-todo-gae](https://github.com/cage1016/gokit-todo-gae)，並將 [cage1016/gokit-todo](https://github.com/cage1016/gokit-todo) 及 [cage1016/gokit-todo-frontend](https://github.com/cage1016/gokit-todo-frontend) 加到 submodule 中把 Google App Engine 相關的設定獨立開來，這樣有一個好處就是可以讓原專案的人專注在開發上，盡量降底非開發的任務綁定來降低隅合性

## Google App Engine

Google App Engine 的部份在這一次的情境中相對的很單純，基本上就是啟用，後序的部署我們都是使用 Cloud Buiild 來串接

```bash
gcloud app create --region=asia-east1
```

## Cloud SQL

在 [cage1016/gokit-todo](https://github.com/cage1016/gokit-todo) Kubernetes 的 demo 中是使用 Postgres，在 Google Cloud Platfrom 上我們可以選用 Cloud SQL 來建置資料庫的部份, 用我們就選用 share code 給 Demo 使用。實際使用就看需求來配置

```bash
gcloud sql instances create todo --database-version=POSTGRES_11 --cpu=1 --memory=3840MiB --region=asia-east1 --root-password=password --storage-size=10GB --storage-type=SSD
```

Cloud Sql 實例建立好之後，我們需要建立一個資料庫

```bash
gcloud sql databases create todo -i todo
```

資料庫部份的設置基本上就完成了。Cloud SQL 實例的 IP 預設為公開，本機開發的時候就可以使用 Cloud SQL Proxy 連接方便使用。當然可以啟用私人 IP 搭配 VPC Netork 來使用。另外我們資料庫的連線方式為 `<project-id>:<region>:<Database-name>`，這個後序會使用到

## Google Cloud Build

由於這一個專案 CI/CD 都是由 Google Cloud Build 串接起來的，所以這一塊比較複雜一點

1. 二個 git submodule: 後端 gokit-todo (api)，前端 gokit-todo-frontend (default)

      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/submodule trigger.jpg" alt="submodule triggers">}}

      > 在二個 git submodule 中的 `cloudbuild.yaml` 還有用到一個技巧，使用 curl 來觸發父層對應的 trigger 

      ```bash
      curl -d '{"branchName":"master"}' -X POST -H "Content-type: application/json" \
          -H "Authorization: Bearer $(gcloud config config-helper --format='value(credential.access_token)')" \
          https://cloudbuild.googleapis.com/v1/projects/<gcp-project>/triggers/<cloudbuild-trigger-id>:run      
      ```

1. `cloudbuild.default.yaml` 及 `cloudbuild.api.yaml`

      {{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/api default trigger.jpg" alt="api/default triggers">}}

1. 對應 `cloudbuild.dispatch.yaml` 部署 `dispatch.yaml` 的 trigger 也是如此

__全部的設定__
{{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/cloudbuild-trigger.jpg" alt="Cloud Build triggers">}}

## gokit-todo-gae

**[cage1016/gokit-todo-gae](https://github.com/cage1016/gokit-todo-gae)**

```bash
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

## 心得

Google App Engine 還是很好用的，由其是 standard-runtime 每天有 28 小時實例的免費額度，簡單的專案很適合。再以 [cage1016/gokit-todo](https://github.com/cage1016/gokit-todo) + [cage1016/gokit-todo-frontend](https://github.com/cage1016/gokit-todo-frontend) 之前部署在 Kubernetes 上的應用來說，都是可以在不修改程式碼的基礎中加上 Google App Engine 需要的設定檔 `app.yaml` 就可以部署，Github 也可以很好的跟 Google Cloud Build 一起協同工作。

**Q**
Github 本身就有自己的 CI/CD 系統 Github Action，為什麼還需要使用 Google Cloud Buil? </br>
**A** 
Github Action 也是可以使用 curl 來驅動父層的 Google Cloud Build 的 tirgger，在 Github action 得自行處理權限問題，都在 Google Coud Platform 的環境中不用特別處理

{{<image src="/posts/deploy-gokit-todo-to-gae-with-cloud-build-from-github-repo/img/gokit-todo-gae.gif" alt="gokit todo GAE">}}

程式碼 https://github.com/cage1016/gokit-todo-gae