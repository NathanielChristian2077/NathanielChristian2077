#!/usr/bin/env bash
# Fedora 44 minimal -> Niri + Noctalia (first-boot bootstrap)
set -Eeuo pipefail

say() { printf '\n\033[1;36m[bootstrap]\033[0m %s\n' "$*"; }
fail() { printf '\n[erro] %s\n' "$*" >&2; exit 1; }
trap 'printf "[erro] Falha na linha %s (codigo %s). Consulte a saida do dnf acima.\n" "$LINENO" "$?" >&2' ERR

mode="${1:-desktop}"
case "$mode" in desktop|--greeter) ;; *) fail "Uso: bash bootstrap.sh [--greeter]" ;; esac
[[ -r /etc/os-release ]] || fail "Nao foi possivel identificar a distribuicao."
# shellcheck disable=SC1091
source /etc/os-release
[[ "$ID" == "fedora" && "$VERSION_ID" == "44" ]] || fail "Requer Fedora 44 (detectado: ${PRETTY_NAME:-desconhecido})."
[[ "$EUID" -ne 0 ]] || fail "Execute como usuario comum, sem sudo. O script pedira sua senha quando necessario."
command -v sudo >/dev/null || fail "sudo nao encontrado. Configure sudo para seu usuario antes de continuar."
command -v dnf >/dev/null || fail "dnf nao encontrado."
sudo -v

say "Atualizando metadados e pacotes do Fedora 44..."
sudo dnf upgrade -y --refresh

say "Instalando compositor, shell e ferramentas essenciais..."
sudo dnf install -y \
  niri noctalia xwayland-satellite \
  xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-gnome \
  gnome-keyring gnome-keyring-pam polkit \
  alacritty fuzzel \
  nautilus firefox \
  pipewire wireplumber pipewire-pulseaudio pipewire-alsa pavucontrol \
  NetworkManager NetworkManager-wifi bluez upower accountsservice \
  mesa-dri-drivers mesa-vulkan-drivers \
  wl-clipboard qt6-qtwayland \
  flatpak xdg-user-dirs \
  curl git nano pciutils

# No full desktop environment. No system-wide graphic/login changes by default.
say "Configurando o autostart do Noctalia sem substituir a configuracao padrao do Niri..."
mkdir -p "$HOME/.config/autostart"
autostart="$HOME/.config/autostart/noctalia.desktop"
if [[ ! -e "$autostart" ]]; then
  cat > "$autostart" <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Noctalia
Comment=Desktop shell for Niri
Exec=noctalia
TryExec=noctalia
Terminal=false
OnlyShowIn=niri;Niri;
DESKTOP
else
  say "Autostart ja existe; mantido: $autostart"
fi

# Fedora's NetworkManager and Bluetooth units should already be managed by
# the distribution. We enable only NetworkManager (and do not restart it).
sudo systemctl enable NetworkManager.service >/dev/null

if [[ "$mode" == "--greeter" ]]; then
  say "Instalacao opcional do Noctalia Greeter (repositorio comunitario Terra)."
  say "A documentacao upstream usa --nogpgcheck SOMENTE para o RPM inicial terra-release."
  sudo dnf install -y greetd greetd-selinux
  if ! rpm -q terra-release >/dev/null 2>&1; then
    sudo dnf install -y --nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release
  fi
  sudo dnf install -y noctalia-greeter
  wrapper="$(command -v noctalia-greeter-session || true)"
  [[ -n "$wrapper" ]] || fail "Greeter instalado, mas noctalia-greeter-session nao existe; greetd nao sera ativado."

  # Never silently replace another display manager or a customized greetd config.
  if systemctl is-enabled -q display-manager.service 2>/dev/null; then
    dm="$(readlink -f /etc/systemd/system/display-manager.service || true)"
    [[ "$dm" == *greetd.service ]] || fail "Outro display manager esta habilitado ($dm). Nada foi substituido."
  fi

  config=/etc/greetd/config.toml
  if [[ -f "$config" ]] && ! grep -Eq 'agreety|noctalia-greeter-session' "$config"; then
    fail "greetd ja possui configuracao possivelmente personalizada ($config). Configure-o manualmente."
  fi
  if [[ -f "$config" ]]; then
    sudo cp -a "$config" "${config}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  # Fedora greetd package provides the "greetd" account, not "greeter".
  # Reuse whichever designated greeter account the system actually provides.
  if getent passwd greetd >/dev/null; then
    greeter_user=greetd
  elif getent passwd greeter >/dev/null; then
    greeter_user=greeter
  else
    fail "Nao existe usuario de servico greetd/greeter. Verifique a instalacao do greetd."
  fi
  printf '[terminal]\nvt = 1\n\n[default_session]\ncommand = "%s"\nuser = "%s"\n' "$wrapper" "$greeter_user" | sudo tee "$config" >/dev/null
  sudo install -d -m 0750 -o "$greeter_user" -g "$greeter_user" /var/lib/noctalia-greeter
  # Override any vendor tmpfiles rule that hardcodes a missing "greeter" user.
  sudo install -d -m 0755 /etc/tmpfiles.d
  printf 'd /var/lib/noctalia-greeter 0750 %s %s - -\n' "$greeter_user" "$greeter_user" | sudo tee /etc/tmpfiles.d/noctalia-greeter.conf >/dev/null
  sudo systemctl enable greetd.service
  sudo systemctl set-default graphical.target
  say "greetd habilitado PARA O PROXIMO BOOT; nao iniciaremos agora para preservar seu TTY."
fi

say "Pacotes principais:"
for program in niri niri-session noctalia alacritty; do
  if command -v "$program" >/dev/null 2>&1; then
    printf '  OK: %s\n' "$program"
  else
    printf '  FALTA: %s\n' "$program"
  fi
done

cat <<'DONE'

Instalacao concluida. Sem reinicio automatico e sem mudanca de particoes.

1. A partir do TTY, como usuario comum, teste:
     niri-session
2. No Niri, Super+T abre Alacritty; Super+D abre Fuzzel.
   Se Noctalia nao aparecer automaticamente, execute 'noctalia' no terminal.
3. Se a tela ficar preta ou a sessao falhar, use Ctrl+Alt+F3 para outro TTY.
4. A rotacao dos monitores, drivers NVIDIA, temas e gaming ficaram
   deliberadamente para uma etapa posterior, depois de verificar o hardware.
5. Para instalar/ativar Noctalia Greeter futuramente, rode este mesmo
   script novamente usando a opcao '--greeter'.

Recuperacao de login (se voce usou --greeter):
     sudo systemctl disable greetd
     sudo systemctl set-default multi-user.target
     sudo reboot
DONE
