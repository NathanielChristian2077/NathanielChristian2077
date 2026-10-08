# Fedora 44: Niri + Noctalia (bootstrap temporário)

Este branch é uma área **temporária de distribuição**, isolada da branch principal do repositório de perfil. O projeto definitivo deve ir para um repositório próprio.

## No terminal do Fedora 44

Entre com um **usuário comum com sudo**, com rede funcionando, e rode:

```bash
curl -fL --proto '=https' --tlsv1.2 -o bootstrap.sh \
  https://raw.githubusercontent.com/NathanielChristian2077/NathanielChristian2077/fedora44-niri-noctalia-bootstrap/bootstrap.sh
less bootstrap.sh
bash bootstrap.sh
```

O script atualiza o Fedora e instala Niri, Noctalia, ferramentas básicas, aplicativos GNOME selecionados e infraestrutura Wayland. **Não formata discos, não instala drivers NVIDIA, não reinicia o PC e não altera o bootloader.**

Depois de concluir, inicie do TTY com `niri-session`. Em Niri, pressione Super+T para abrir Alacritty e Super+D para Fuzzel. Se a shell não subir automaticamente, abra um terminal e execute `noctalia`. Recupere outro TTY com Ctrl+Alt+F3.

## Login gráfico opcional, depois de testar Niri

```bash
bash bootstrap.sh --greeter
sudo reboot
```

Essa opção instala o **Noctalia Greeter** por meio do repositório comunitário Terra, configura `greetd` e habilita login gráfico no próximo boot. O bootstrap do `terra-release` segue a documentação do Noctalia e usa `--nogpgcheck` na primeira instalação do repositório. Leia e aceite esse risco antes de usar. Se já houver outro gerenciador de login, o script não o substitui automaticamente.

Para recuperar boot em TTY se o greeter não funcionar:

```bash
sudo systemctl disable greetd
sudo systemctl set-default multi-user.target
sudo reboot
```

## Não incluído nesta primeira fase

Drivers NVIDIA proprietários, configuração de monitores/rotação, Steam/Proton, áudio de produção musical, personalização visual e migração dos dotfiles anteriores.

## Referências upstream

- https://github.com/niri-wm/niri/wiki/Getting-Started
- https://github.com/niri-wm/niri/wiki/Important-Software
- https://docs.noctalia.dev/noctalia/getting-started/installation/
- https://docs.noctalia.dev/noctalia/getting-started/running-the-shell/
- https://docs.noctalia.dev/greeter/installation/

### Correção de um erro nas primeiras versões do bootstrap

A versão inicial escrevia apenas `[default_session]` e por isso o greetd falhava com
`no terminal specified`. O bootstrap foi corrigido para incluir `[terminal] vt = 1`
e inicializar o diretório de estado. Se você **já executou** a versão anterior,
não precisa repetir a instalação; corrija o arquivo existente:

```toml
[terminal]
vt = 1

[default_session]
command = "/usr/bin/noctalia-greeter-session"
user = "greeter"
```

Antes de editar, faça backup de `/etc/greetd/config.toml`. Em seguida,
prepare o diretório e teste a partir do TTY3:

```bash
sudo install -d -m 0750 -o greeter -g greeter /var/lib/noctalia-greeter
sudo systemctl reset-failed greetd
sudo systemctl start greetd
sudo systemctl status greetd --no-pager
```

Se ficar ativo, mude para Ctrl+Alt+F1 para testar. Só então execute
`sudo systemctl enable greetd` e `sudo systemctl set-default graphical.target`.
Não reinicie se os erros persistirem.

Fontes:
- https://github.com/kennylevinsen/greetd/blob/master/config.toml
- https://docs.noctalia.dev/greeter/troubleshooting/
- https://github.com/noctalia-dev/noctalia-greeter/blob/main/PACKAGING.md
