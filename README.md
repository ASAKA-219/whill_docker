# whill_ws
## .envファイルの設定
```bash
id roboworks
```
でパソコンのユーザーidを割り当てる。ユーザーとグループが1000であればok。
そして、.envファイルを開いてユーザー名とグループ名（おそらくターミナルに表示されてる右のやつがグループ名）を書き込んで終わり。

## ビルド
Dockerのビルドはdocker-composeで行います。やり方は、
```bash
docker-compose build
docker-compose up -d
```
そして、doneと出たら
```bash
docker exec -it whill_docker /bin/bash
```
と打つとdocer上のシェルが現れます。ここでwhillのros noetic環境にどのパソコンでも入ることができます。
