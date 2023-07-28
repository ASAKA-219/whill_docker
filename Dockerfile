# osrfが提供するrosイメージ（タグがnoetic-desktop-full）をベースとしてダウンロード
FROM osrf/ros:noetic-desktop-full
LABEL maintainer="Yusuke Asaka <yusuke.asaka@aibot.jp>"
SHELL ["/bin/bash", "-c"]
ARG DEBIAN_FRONTEND=noninteractive

# Docker実行してシェルに入ったときの初期ディレクトリ（ワークディレクトリ）の設定
WORKDIR /whill_docker/

# Install Nvidia Container Toollit
RUN distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
  && apt update \
  && apt install -y curl \
  && curl -s -L https://nvidia.github.io/libnvidia-container/gpgkey | apt-key add - \
  && curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | tee /etc/apt/sources.list.d/nvidia-container-toolkit.list


RUN apt-get update \
  && apt-get install -y --no-install-recommends nvidia-container-toolkit \
  && apt-get install -y python3-catkin-tools

# nvidia-container-runtime（描画するための環境変数の設定）
ENV NVIDIA_VISIBLE_DEVICES \
    ${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES \
    ${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

# ROSの環境整理
# ROSのセットアップシェルスクリプトを.bashrcファイルに追記
RUN echo 'source /opt/ros/noetic/setup.sh' >> /root/.bashrc \
# 自分のワークスペース作成のためにフォルダを作成
  && mkdir -p catkin_ws/src \
# srcディレクトリまで移動して，catkin_init_workspaceを実行．
# ただし，Dockerfileでは，.bashrcに追記した分はRUNごとに反映されないため，
# source /opt/ros/noetic/setup.shを実行しておかないと，catkin_init_workspaceを実行できない
  && cd catkin_ws/src && source /opt/ros/noetic/setup.sh && catkin_init_workspace \
# catkin_wsディレクトリに移動して，上と同様にしてcatkin buildを実行．
  && cd .. && source /opt/ros/noetic/setup.sh && catkin build \
# 自分のワークスペースが反映されるように，.bashrcファイルに追記．
  && echo "source ./catkin_ws/devel/setup.bash" >> /root/.bashrc \
  && source /root/.bashrc

#必要なパッケージをインストール
RUN apt-get update \
  && apt-get install -y ros-noetic-joy ros-noetic-teleop-twist-joy ros-noetic-urg-node ros-noetic-serial \
  && apt-get install -y ros-noetic-gmapping libbullet-dev libsdl-image1.2-dev libsdl-dev ros-noetic-navigation ros-noetic-geometry2 \
  && apt install -y ros-noetic-usb-cam ros-noetic-image-view \
  && apt-get install -y git nano wget tmux terminator \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

#Velodyneドライバーのインストール
RUN apt-get update \
  && apt-get install -y ros-noetic-velodyne \
  && cd catkin_ws/src \
  && git clone https://github.com/ros-drivers/velodyne.git \
  && cd .. && rosdep install --from-paths src --ignore-src --rosdistro noetic -y \
  && catkin build && source /root/.bashrc

RUN sudo rm /etc/ros/rosdep/sources.list.d/20-default.list
#whillのパッケージをクローン
RUN cd catkin_ws/src \
  && git clone https://github.com/WHILL/ros_whill.git \
  && git clone https://gitlab.com/okadalaboratory/dev-whill/whill-project.git \
  && cd .. && catkin build \
  && source /root/.bashrc \
  && sudo apt update \
  && sudo rosdep init && rosdep update

# Setup whill env
RUN echo 'KERNEL=="ttyUSB[0-9]*", MODE="0666"' >> /lib/udev/rules.d/50-udev-default.rules

#USBカメラの権限を付与し、起動の準備
RUN cd catkin_ws/src \
  && echo 'export TTY_WHILL=/dev/ttyUSB0' >> /root/.bashrc \
  && source /root/.bashrc \
  #&& sudo chmod 666 /dev/ttyUSB0

# Timezone, Launguage設定
RUN apt update \
  && apt install -y --no-install-recommends \
     locales \
     software-properties-common tzdata \
  && locale-gen ja_JP ja_JP.UTF-8  \
  && update-locale LC_ALL=ja_JP.UTF-8 LANG=ja_JP.UTF-8 \
  && add-apt-repository universe

RUN apt update && apt install iproute2 -y

RUN sudo chmod +x ./catkin_ws/src/whill-project

# Locale
ENV LANG ja_JP.UTF-8
ENV TZ=Asia/Tokyo

# Add user and group
ARG UID
ARG GID
ARG USER_NAME
ARG GROUP_NAME

RUN groupadd -g ${GID} ${GROUP_NAME}
RUN useradd -u ${UID} -g ${GID} -s /bin/bash -m ${USER_NAME}

#PS1プロンプトをカスタマイズ
RUN echo "PS1='\[\033[48;5;255m\]\[\033[30m\]whill:\[\033[0m\]\[\033[1;32m\]\u\[\033[0m\]\[\033[1;33m\]@\[\033[0m\]\[\033[1;33m\]\w\[\033[0m\]\$ '" >> /home/${USER_NAME}/.bashrc
RUN echo "source ~/will_docker/catkin_ws/setup.bash" >> /root/.bashrc

USER ${USER_NAME}

CMD ["/bin/bash"]
