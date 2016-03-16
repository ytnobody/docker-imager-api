# ytnobody/imager-api

resize, crop a image by url

## how to run

    docker run -p 7091:7091 --rm -it ytnobody/imager-api

## example

This is a source image. 

    https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg

![Uncle Sam from Wikimedia](https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg)

First, crop Sam's face. 

    http://localhost:7091/actions/crop:380:520:300:300?img=https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg

Next, resize to 100px width.

    http://localhost:7091/actions/crop:380:520:300:300/width:100?img=https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg

That's all.


