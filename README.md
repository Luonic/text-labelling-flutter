# text-labelling-flutter
App for classifying texts on mobile

## What it should do
Using file picker load jsonl file with fields
images: list of image/video names in the dir ./images
title: string
description: string

Then there should be horizontally swipeable pages of vertically scrollable cards
Each card consists of:
- horizontally scrollable list of thumbnails of images from images field
- title label, may occupy multiple lines
- description label, may occupy multiple lines

Horizontal grid of flag buttons with label equal to flag name that change color to redAccent if selected
List of flags:
- nudes_trade
- prostitution
- underwear_trade

Store flags as json and load them on app start

After moving to the next or previous page save flags to the same jsonl file by rewriting entire file