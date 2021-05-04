---
date: {{ .Date }}
title: "{{ replace .Name "-" " " | title }}"
draft: true
desc: TODO
tags:
  - TODO 
---

image
{{<img src="/posts/{{ .Name }}/img/placeholder.png">}}

read more
<!--more-->

google slide
{{< gslides src="https://docs.google.com/presentation/d/e/2PACX-1vQvBqMYvYRhwQBqcnr-gn__cwyvmsBInyHAANba7loo4NIsm_3W00-XkEK4-n5Vd0HgQ1P2RJcFIEeL/embed?start=false&loop=false&delayms=3000" >}}

slideshare
{{< slideshare id="239269720" >}}

{{< video src="sample.mp4" >}}
or
{{< video src="sample.mp4" width="600px" >}}
