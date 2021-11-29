#FROM python:3.10.0-buster
FROM ubuntu:20.04

ARG USER=ci-shell
ENV TZ=Asia/Kolkata
ENV HOME=/home/$USER
ENV HOSTNAME="ci-shell"
ENV ZSH_THEME="powerlevel10k/powerlevel10k"


# Install additional OS packages.
RUN set -x \
    && apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends zsh \
		zsh-autosuggestions zsh-syntax-highlighting  \
        python3-pip git-all sudo curl wget \
    && apt install software-properties-common -y \
    && add-apt-repository --yes --update ppa:ansible/ansible \
    && apt install ansible -y

# add new user
RUN set -ex \
    && useradd -ms /bin/zsh $USER \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers \
    && chmod 0440 /etc/sudoers

# Install pip packages.
RUN set -x \
    && pip3 install  python-openstackclient

USER $USER

# Theme Dot Files
RUN set -ex \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k \
    && echo "source ~/powerlevel10k/powerlevel10k.zsh-theme"  >> $HOME/.zshrc \
    && echo "# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh."  >> $HOME/.zshrc \
    && echo "[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh" >> $HOME/.zshrc

COPY dotfiles/.p10k.zsh $HOME/.p10k.zsh

WORKDIR /workspace/provision/openstack
CMD /bin/zsh "$@"
