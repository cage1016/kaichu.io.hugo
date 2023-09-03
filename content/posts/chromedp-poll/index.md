---
date: 2022-12-18T08:28:56Z
title: "Chromedp Poll"
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

<!-- image
{{<image src="/posts/chromedp-poll/img/placeholder.png">}} -->


{{< video src="sample.mp4" >}}


```go
package main

import (
	"context"
	"log"
	"time"

	"github.com/chromedp/chromedp"
)

const script = `(website, limit) => new Promise((resolve) => {
	var entry = new Date()
    var git = setInterval(() => {
        if (limit < 0) {
            clearInterval(git)
            resolve('{"website": "' + website + '", "entry": "' + entry + '", "exit": "' + new Date() + '"}')
        }
        limit--
    }, 1000)
})`

func main() {
	opts := append(chromedp.DefaultExecAllocatorOptions[:],
		chromedp.Flag("headless", false),
		chromedp.Flag("no-default-browser-check", true),
		// chromedp.Flag("no-sandbox", true),
	)
	allocCtx, cancel := chromedp.NewExecAllocator(context.Background(), opts...)
	defer cancel()

	// create chrome instance
	ctx, cancel := chromedp.NewContext(allocCtx, chromedp.WithLogf(log.Printf))
	defer cancel()

	// create a timeout as a safety net to prevent any infinite wait loops
	ctx, cancel = context.WithTimeout(ctx, 180*time.Second)
	defer cancel()

	websites := []string{
		"https://kaichu.io",
		"https://www.google.com",
	}

	for _, website := range websites {
		var res interface{}
		err := chromedp.Run(ctx,
			chromedp.Navigate(website),
			chromedp.PollFunction(script, &res, chromedp.WithPollingArgs(website, 5)),
		)
		if err != nil {
			log.Fatalf(err.Error())
		}
		log.Printf("result: %v", res)
	}
}
```

[Release chromedp v0.6.11 · chromedp/chromedp](https://github.com/chromedp/chromedp/releases/tag/v0.6.11)