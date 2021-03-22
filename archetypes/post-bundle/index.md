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


{{< video src="my-beautiful-screencast" >}}
or
{{< video src="my-beautiful-screencast" width="600px" >}}

read more
<!--more-->