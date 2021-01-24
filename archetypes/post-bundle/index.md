---
date: {{ .Date }}
title: "{{ replace .Name "-" " " | title }}"
draft: true
desc: TODO
tags:
  - TODO 
---

image
{{<img src="/posts/{{ .Name }}/img/xx.jpg">}}

google slide
{{< gslides src="" >}}

slideshare
{{< slideshare id="2" >}}

read more
<!--more-->