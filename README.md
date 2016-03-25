# ytnobody/imager-api

resize, crop a image by url

## how to run

    docker run -p 7091:7091 --rm -it ytnobody/imager-api

## example

This is a source image. 

    https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg

![Uncle Sam from Wikimedia](https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg)

First, crop Sam's face. 

    http://localhost:7091/?action=crop,380,520,300,300&img=https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg

Next, resize to 100px width.

    http://localhost:7091/?action=crop,380,520,300,300&scale,100&img=https://upload.wikimedia.org/wikipedia/commons/1/1d/Unclesamwantyou.jpg

That's all.

## actions

### crop

Crop specified area from image.

* syntax

    action=crop,[left],[top],[width],[height]

* example

    action=crop,50,30,100,80


### resize

Resize a image based on specified width.

* syntax

    action=resize,[new width]

* example

    action=resize,60


### gray

Image makes gray scale.

* syntax

    action=gray


### compose

Overlaying an image to specified position.

* syntax

    action=compose,[overlay image url],[left],[top],([width])

* example

    action=compose,https://www.google.co.jp/images/branding/googlelogo/2x/googlelogo_color_272x92dp.png,0,30

### mosaic

Filtering with mosaic

* syntax

    action=mosaic,[left],[top],[width],[height]

* example

    action=mosaic,20,50,100,60

