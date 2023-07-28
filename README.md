# whill_ws
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
