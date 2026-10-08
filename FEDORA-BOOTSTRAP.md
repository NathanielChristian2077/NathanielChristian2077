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
