# Conversão de Script PowerShell (.ps1)

# para Executável (.exe)

Este documento detalha o processo de transformação de scripts PowerShell em ficheiros
binários executáveis utilizando o módulo **PS2EXE**. Este método é ideal para criar instaladores e
ferramentas de automação que podem ser distribuídas de forma simplificada para utilizadores
finais.

## Visão Geral do Método PS2EXE

O **PS2EXE** é um módulo de código aberto que atua como um "wrapper" (encapsulador). Ele
não compila o código em linguagem de máquina pura, mas cria um executável C# que contém
o seu script PowerShell original, executando-o num host invisível do PowerShell no momento
da abertura.

### Vantagens

```
● Portabilidade: Gera um único ficheiro .exe.
● Estética: Permite adicionar ícones personalizados e informações de versão.
● Facilidade: O utilizador final não precisa de saber como abrir o terminal ou configurar
políticas de execução.
```
## Pré-requisitos

```
● Sistema Operativo: Windows 10 ou 11.
● PowerShell: Versão 5.1 ou superior.
● Permissões: Deve executar o PowerShell como Administrador para instalar o módulo.
```
## Preparação do Script (Melhores Práticas)

Antes de converter, certifique-se de que o seu **script.ps1** é robusto. Como discutido, para um
instalador de ambiente WSL/Linux, é recomendável incluir uma verificação de sanidade no
início:

# Verificação de ambiente sugerida

if (!(wsl --list --quiet)) {
Write-Host "O WSL não foi detectado. A iniciar instalação do Ubuntu..." -ForegroundColor
Cyan
wsl --install -d Ubuntu
Write-Host "Instalação concluída. Reinicie o computador e execute este instalador
novamente."
exit
}


## Passo a Passo da Conversão

### Passo 1: Instalação do Módulo

Abra o PowerShell como Administrador e execute o comando abaixo:

Install-Module -Name ps2exe -Force -Scope CurrentUser

_Nota: Se o sistema pedir permissão para instalar do repositório 'PSGallery', responda com A
(Yes to All)._

### Passo 2: Conversão Simples

Para uma conversão rápida sem personalizações, use os seguintes comandos:

Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process

ps2exe "C:\Users\usuário\Caminho\Local\Script.ps1" -outputFile ".\Installer.exe" -requireAdmin

_Nota: Copie o caminho do seu script e cole ao terminal substituindo a seção
"C:\Users\usuário\Caminho\Local\Script.ps1" pelas informações do seu determinado arquivo._

### Passo 3: Conversão Profissional (Opcional)

Para o projeto de maior seriedade é recomendável adicionar metadados e um ícone para
passar mais confiança ao utilizador:

ps2exe .\Script.ps1 .\InstaladorWSL.exe

-IconFile "seu_icone.ico"

-Title "Instalador"

-Description "Configuração/Instalação Automática do Ambiente"

-Company "O Seu Nome/Empresa" `

-Version "1.0.0.1"

#### Parâmetros Úteis:

```
● -IconFile: Caminho para o ficheiro .ico.
● -noConsole: Use isto se o seu script tiver uma interface gráfica (GUI) e quiser esconder o
terminal preto.
● -title: Define o título que aparece nas propriedades do ficheiro.
```

## Questões Críticas e Segurança

### Falsos Positivos (Antivírus)

É comum que o **Windows Defender** ou outros antivírus sinalizem o executável gerado como
malicioso.
● **Porquê?** O comportamento de "encapsular scripts ocultos" é frequentemente usado por
malwares.
● **Solução:** Se o uso for interno ou para colegas técnicos, peça para adicionar o ficheiro às
exclusões. Para uso oficial/comercial, a melhor opção é o **Inno Setup** ou assinar
digitalmente o executável (o que requer um certificado pago).

### Política de Execução

O executável gerado pelo PS2EXE tenta contornar as restrições de execução (ExecutionPolicy)
automaticamente, mas em sistemas muito restritos, pode ser necessário garantir que o
utilizador tenha permissões mínimas de execução de scripts.

## Alternativas de Distribuição

Se o PS2EXE não atender às necessidades de instalação e uso devido certos aspectos tal
como o antivírus, considere:

1. **Inno Setup:** Cria um instalador tradicional com janelas de "Avançar/Seguinte". É a opção
    mais profissional e evita muitos bloqueios de segurança.
2. **Atalho Direto:** Criar um atalho que executa:
    powershell.exe -ExecutionPolicy Bypass -File "C:\caminho\Script.ps1"

## Conclusão

O método **PS2EXE** é a ponte mais rápida para transformar o seu trabalho de automação numa
ferramenta de clique-único. Lembre-se sempre de testar o executável numa máquina "limpa"
(onde o ambiente ainda não esteja configurado) para garantir que toda a lógica de instalação
funciona conforme o esperado.


