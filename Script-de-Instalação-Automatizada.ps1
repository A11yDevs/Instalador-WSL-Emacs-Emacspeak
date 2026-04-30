# Script de Instalação Automatizada (WSL + Ubuntu + Emacs/Emacspeak)

# Verificar Privilégios de Administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERRO: Este script precisa ser executado como ADMINISTRADOR para instalar o WSL." -ForegroundColor Red
    Pause
    exit
}

Write-Host "Iniciando Verificação do Sistema..." -ForegroundColor Cyan

# Verificação e Instalação do WSL / Ubuntu
$wslCheck = wsl --list --quiet
if ($null -eq $wslCheck) {
    Write-Host "WSL não detectado. Iniciando instalação do WSL e Ubuntu..." -ForegroundColor Yellow
    wsl --install -d Ubuntu
    Write-Host "----------------------------------------------------------------" -ForegroundColor Cyan
    Write-Host "INSTALAÇÃO INICIAL CONCLUÍDA." -ForegroundColor Green
    Write-Host "POR FAVOR, REINICIE O COMPUTADOR para ativar os recursos de virtualização." -ForegroundColor Magent
    Write-Host "Após o reinício, execute este script novamente para configurar o Emacs." -ForegroundColor Cyan
    Pause
    exit
}

# Detecção do Usuário (Se o WSL já estiver instalado)
Write-Host "WSL detectado. Configurando ambiente Linux..." -ForegroundColor Cyan
$wslUser = wsl whoami
if ($null -eq $wslUser -or $wslUser -like "*root*") {
    # Caso o Ubuntu tenha acabado de ser instalado, ele pode cair no root ou pedir setup
    Write-Host "Aguardando inicialização do usuário padrão..." -ForegroundColor Yellow
    # Tenta pegar o primeiro usuário não-root criado
    $wslUser = wsl -d Ubuntu -e bash -c "whoami"
}

# Detecção do Usuário
$homeDir = "/home/$wslUser"
Write-Host "Usuário detectado no WSL: $wslUser" -ForegroundColor Green

# Atualização Completa do Sistema
Write-Host "Limpando e atualizando o sistema..." -ForegroundColor Cyan
wsl -u root sh -c "export DEBIAN_FRONTEND=noninteractive; apt-get update && apt-get upgrade -y"

# Define a escolha do Postfix para "No configuration" evitando do terminal travar 
wsl -u root sh -c "echo 'postfix postfix/main_mailer_type select No configuration' | debconf-set-selections"
wsl -u root sh -c "echo 'postfix postfix/mailname string localhost' | debconf-set-selections"

# Instalação de Dependências (Garante Emacs e Java)
Write-Host "Instalando dependências e programas (Emacs, Java, Git)..." -ForegroundColor Yellow
wsl -u root sh -c "apt-get install -y emacs-nox openjdk-17-jdk espeak-ng libespeak-ng-dev tcl-dev tclx tcl8.6-dev pulseaudio sox git locales"
wsl -u root sh -c "locale-gen pt_BR.UTF-8"

# Download e Compilação do Emacspeak
Write-Host "Configurando Emacspeak em $homeDir..." -ForegroundColor Yellow
# Removemos a pasta se ela estiver incompleta e clonamos novamente
wsl -u $wslUser sh -c "cd $homeDir && rm -rf emacspeak && git clone https://github.com/tvraman/emacspeak.git"
wsl -u $wslUser sh -c "cd $homeDir/emacspeak && make"
wsl -u $wslUser sh -c "cd $homeDir/emacspeak/servers/native-espeak && make"

# Injeção do init.el
Write-Host "Configurando init.el personalizado..." -ForegroundColor Magenta
$init_el = @"

;; Ajuste de Ambiente para Windows/WSL

(setenv "PULSE_SERVER" "unix:/mnt/wslg/PulseServer")

(setenv "DTK_PROGRAM" "espeak")

;; Interface limpa e simples

(setq inhibit-startup-screen t)

(push '(menu-bar-lines . 0) default-frame-alist)

(push '(tool-bar-lines . 0) default-frame-alist)

(push '(vertical-scroll-bars . nil) default-frame-alist)

(add-hook 'emacs-startup-hook
          (lambda ()
            (with-current-buffer "*scratch*"
              (delete-region (point-min) (point-max))
              (insert "Emacs e Emacspeak em funcionamento.\n"))
            (message "Emacs e Emacspeak em funcionamento.")))

;; Caminhos Emacspeak

(defvar emacspeak-directory "$homeDir/emacspeak")

(defvar emacspeak-lisp-directory (expand-file-name "lisp" emacspeak-directory))

(setq emacspeak-sounds-dir (expand-file-name "sounds" emacspeak-directory))

(setq emacspeak-xslt-directory (expand-file-name "xsl" emacspeak-directory))

(add-to-list 'load-path emacspeak-lisp-directory)

;; Carregamento do Emacspeak

(setq warning-minimum-level :error)

(condition-case err

    (load-file (expand-file-name "lisp/emacspeak-setup.el" emacspeak-directory))

  (error (message "Erro no setup: %s" (error-message-string err))))

(setq emacspeak-use-sounds nil)

;; Produtividade Java

(load-theme 'modus-vivendi t)

(global-display-line-numbers-mode t)

(defun stark-java-run ()
  (interactive)
  (save-buffer)
  (let* ((file-path (buffer-file-name))
         (file-dir (file-name-directory file-path))
         (file-name (file-name-nondirectory file-path))
         (class-name (file-name-sans-extension file-name))
         ;; Adicionamos '%s' ao redor do diretório evitando erros na compilação 
         (command (format "cd '%s' && rm -f *.class && javac *.java && java %s"
                          file-dir
                          class-name)))
    ;; Permite a entrada a partir do teclado
    (shell-command (concat command " &") "*Java Output*")
    
    ;; Exibe o buffer e move o foco para a janela dele
    (let ((window (display-buffer "*Java Output*" 
                                 '((display-buffer-reuse-window display-buffer-at-bottom)))))
      (when window
        (select-window window)))))

;; Atalho de Compilar/Salvar código
(global-set-key (kbd "<f5>") 'stark-java-run)

;; Limpeza de avisos irritantes

(when (get-buffer "*Warnings*") (kill-buffer "*Warnings*"))

;; Fixa o Pt-Br no carregamento

(with-eval-after-load 'dtk-speak

  (dtk-set-rate 200 t)

  (setenv "EVENT_VOICE" "pt-br")

  (emacspeak-execute-program "pt-br"))

;; Garante que o espeak use a variante correta

(setq-default espeak-default-variant "pt-br")
"@

$init_el | wsl -u $wslUser sh -c "mkdir -p ~/.emacs.d && cat > ~/.emacs.d/init.el"

# Configuração Final do Terminal (.bashrc)
wsl -u $wslUser sh -c "sed -i '/EMACSPEAK_DIR/d; /DTK_PROGRAM/d' ~/.bashrc"
wsl -u $wslUser sh -c "echo 'export EMACSPEAK_DIR=$homeDir/emacspeak' >> ~/.bashrc && echo 'export DTK_PROGRAM=espeak' >> ~/.bashrc"

Write-Host "Configuração do UBuntu/Emacs realizada com sucesso para o usuário $wslUser." -ForegroundColor Cyan

# CRIAÇÃO DO ATALHO NO WINDOWS
Write-Host "Criando atalhos no Desktop e Menu Iniciar..." -ForegroundColor Magenta

$WshShell = New-Object -ComObject WScript.Shell

# Caminhos dos atalhos
$DesktopPath = [Environment]::GetFolderPath("Desktop")
$StartMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
$ShortcutNames = "Emacs Ubuntu.lnk"

# Função interna para criar o atalho
foreach ($Path in @($DesktopPath, $StartMenuPath)) {
    $Shortcut = $WshShell.CreateShortcut("$Path\$ShortcutNames")
    $Shortcut.TargetPath = "wsl.exe"
    $Shortcut.Arguments = "~ -e emacs -nw"
    $Shortcut.Description = "Abrir Emacs no WSL Ubuntu"
    # $Shortcut.IconLocation = "powershell.exe" # Define um ícone inicial (pode ser alterado)
    $Shortcut.Save()
}

# O atalho abre a distro (Ubuntu) que esteja definida como a principal do sistema (wsl --set-default <Distro>)
Write-Host "Atalhos facilitados criados com sucesso na Área de Trabalho e no Menu Iniciar!" -ForegroundColor Green
