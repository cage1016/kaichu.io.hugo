---
date: {{ .Date }}
title: "{{ replace .Name "-" " " | title }}"
draft: true
description: TODO
tags:
  - TODO
resources:
  - name: "featured-image-preview"
    src: "img/placeholder.png"
toc: true
---

<!--more-->

image
{{<image src="/posts/{{ .Name }}/img/placeholder.png">}}


google slide
{{< gslides src="https://docs.google.com/presentation/d/e/2PACX-1vQvBqMYvYRhwQBqcnr-gn__cwyvmsBInyHAANba7loo4NIsm_3W00-XkEK4-n5Vd0HgQ1P2RJcFIEeL/embed?start=false&loop=false&delayms=3000" >}}

slideshare
{{< slideshare id="239269720" >}}

{{< video src="sample.mp4" >}}
or
{{< video src="sample.mp4" width="600px" >}}
