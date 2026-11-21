<#
.SYNOPSIS
    Compila um documento LaTeX (pdfLaTeX) numa copia separada e resume erros e avisos.

.DESCRIPTION
    Copia a pasta do documento para uma pasta de build (nao suja a pasta original com .aux/.log)
    e roda: pdflatex -> bibtex ou biber -> makeglossaries/makeindex/nomencl -> pdflatex x2.
    No fim mostra erros, referencias/citacoes indefinidas, avisos do BibTeX/Biber e Overfull hbox.
    Como no Overleaf, o modo nonstop gera o PDF mesmo com erros (o trecho com erro pode sair errado).
    Codigo de saida: 0 se o PDF foi gerado sem erros, 1 caso contrario.

.PARAMETER Origem
    Pasta do documento (default: pasta atual).

.PARAMETER Principal
    Arquivo principal (default: main.tex).

.PARAMETER Saida
    Pasta de build (default: <pai da origem>\build\<nome da origem>). Nao pode ficar dentro da origem.

.PARAMETER TexBin
    Pasta dos executaveis do TeX (default: $env:TEXLIVE_BIN ou a pasta do pdflatex no PATH).
    Ex.: um TeX Live especifico exigido por um template (C:\texlive\2021\bin\win32).

.PARAMETER ShellEscape
    Forca -shell-escape (detectado automaticamente se o documento carrega o pacote minted).

.PARAMETER Clean
    Apaga a pasta de build antes (recompila do zero; use apos mudar siglas, .bib ou rotulos).

.PARAMETER ShowLog
    Lista todos os avisos (padrao: 15 primeiros de cada tipo).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\compilar-latex.ps1 -Origem .\tcc
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\compilar-latex.ps1 -Origem .\tcc -Clean -TexBin C:\texlive\2021\bin\win32
#>
param(
    [string]$Origem = ".",
    [string]$Principal = "main.tex",
    [string]$Saida,
    [string]$TexBin = $env:TEXLIVE_BIN,
    [switch]$ShellEscape,
    [switch]$Clean,
    [switch]$ShowLog
)

$ErrorActionPreference = "Stop"

$Src = (Resolve-Path -LiteralPath $Origem).Path.TrimEnd("\")
if (-not (Test-Path (Join-Path $Src $Principal))) { throw "Arquivo principal nao encontrado: $(Join-Path $Src $Principal)" }
if (-not $Saida) { $Saida = Join-Path (Join-Path (Split-Path -Parent $Src) "build") (Split-Path -Leaf $Src) }
$Out = [System.IO.Path]::GetFullPath($Saida).TrimEnd("\")
if ($Out -eq $Src -or $Out.StartsWith($Src + "\")) { throw "A pasta de build nao pode ser a origem nem ficar dentro dela: $Out" }
$Marca = Join-Path $Out ".compilar-latex"

# Localiza o TeX
if (-not $TexBin) {
    $cmd = Get-Command pdflatex -ErrorAction SilentlyContinue
    if ($cmd) { $TexBin = Split-Path -Parent $cmd.Source }
}
if (-not $TexBin -or -not (Test-Path (Join-Path $TexBin "pdflatex.exe"))) {
    throw "pdflatex nao encontrado (instale TeX Live/MiKTeX, ponha no PATH ou use -TexBin / `$env:TEXLIVE_BIN)."
}

# minted exige -shell-escape e Pygments
$base = [System.IO.Path]::GetFileNameWithoutExtension($Principal)
$usaMinted = Select-String -Path (Join-Path $Src "*.tex") -Pattern '\\usepackage(\[[^\]]*\])?\{[^}]*minted' -Quiet -ErrorAction SilentlyContinue
if ($usaMinted) { $ShellEscape = $true }
$pyPath = $null
if ($ShellEscape) {
    try {
        $site = (& python -c "import pygments,os;print(os.path.dirname(os.path.dirname(pygments.__file__)))" 2>$null)
        if ($site) {
            foreach ($cand in @((Join-Path (Split-Path $site) "Scripts"), (Join-Path (Split-Path (Split-Path $site)) "Scripts"))) {
                if (Test-Path (Join-Path $cand "pygmentize.exe")) { $pyPath = $cand; break }
            }
        }
    } catch {}
    if ($usaMinted -and -not $pyPath) { Write-Warning "pygmentize nao encontrado (python -m pip install --user pygments); minted vai falhar." }
}

# Prepara a pasta de build (so apaga se foi criada por este script)
if ($Clean -and (Test-Path $Out)) {
    if (-not (Test-Path $Marca)) { throw "Nao apago ${Out}: nao foi criada por este script (falta $Marca)." }
    Remove-Item -Recurse -Force $Out
}
New-Item -ItemType Directory -Force $Out | Out-Null
New-Item -ItemType File -Force $Marca | Out-Null
Copy-Item -Path (Join-Path $Src "*") -Destination $Out -Recurse -Force

$env:PATH = ((@($TexBin, $pyPath) | Where-Object { $_ }) -join ";") + ";" + $env:PATH

Push-Location $Out
try {
    function Run([string]$exe, [string[]]$argv, [string]$log) {
        # PowerShell 5.1 transforma stderr de programa nativo em erro; o resultado vem do codigo de saida.
        $ErrorActionPreference = "Continue"
        & (Join-Path $TexBin "$exe.exe") @argv *> $log
        return $LASTEXITCODE
    }
    $tex = @("-interaction=nonstopmode", "-file-line-error", $Principal)
    if ($ShellEscape) { $tex = @("-shell-escape") + $tex }

    Write-Host "[1/5] pdflatex"
    Run pdflatex $tex "run1.txt" | Out-Null
    Write-Host "[2/5] bibliografia"
    $bibLog = "bib.txt"
    if (Test-Path "$base.bcf") { Run biber @($base) $bibLog | Out-Null }
    elseif ((Test-Path "$base.aux") -and (Select-String -Path "$base.aux" -Pattern '\\bibdata' -Quiet)) { Run bibtex @($base) $bibLog | Out-Null }
    Write-Host "[3/5] glossarios e indices"
    if ((Test-Path "$base.glo") -or (Test-Path "$base.acn")) { Run makeglossaries @($base) "glossaries.txt" | Out-Null }
    if (Test-Path "$base.idx") { Run makeindex @($base) "makeindex.txt" | Out-Null }
    if (Test-Path "$base.nlo") { Run makeindex @("$base.nlo", "-s", "nomencl.ist", "-o", "$base.nls") "nomencl.txt" | Out-Null }
    Write-Host "[4/5] pdflatex"
    Run pdflatex $tex "run2.txt" | Out-Null
    # Repete ate as referencias/sumario estabilizarem (como o latexmk): quando o sumario ou uma
    # lista muda de tamanho, as paginas mudam e o LaTeX pede "Rerun". Limite de 5 passadas.
    $n = 3
    do {
        Write-Host "[5/5] pdflatex (passada $n)"
        $rc = Run pdflatex $tex "run$n.txt"
        $precisa = Select-String -Path "$base.log" -Pattern 'Rerun to get|Label\(s\) may have changed|Rerun LaTeX' -Quiet
        $n++
    } while ($precisa -and $n -le 5)
    if ($precisa) { Write-Warning "O LaTeX ainda pede nova passada depois de 5; numeros de pagina podem estar desatualizados." }

    $log = Get-Content "$base.log" -Encoding Default
    $max = if ($ShowLog) { [int]::MaxValue } else { 15 }
    $errors = @($log | Select-String -Pattern '^(\./)?[^:\s]+\.tex:\d+:|^! ' | Select-Object -ExpandProperty Line -Unique)
    $undef  = @($log | Select-String -Pattern '^LaTeX Warning: (Reference|Citation) ' | Select-Object -ExpandProperty Line -Unique)
    $over   = @($log | Select-String -Pattern '^Overfull \\hbox' | Select-Object -ExpandProperty Line)
    $bibW   = @(Get-Content $bibLog -ErrorAction SilentlyContinue | Select-String -Pattern '^Warning--|^WARN|^ERROR|error message' | Select-Object -ExpandProperty Line)

    $pdf = Join-Path $Out "$base.pdf"
    $m = $log | Select-String -Pattern "Output written on $([regex]::Escape($base))\.pdf \((\d+) pages?" | Select-Object -First 1
    $pages = if ($m) { $m.Matches[0].Groups[1].Value } else { "?" }

    function Show([string]$title, $lines) {
        $n = @($lines).Count
        if ($n -eq 0) { return }
        Write-Host "`n$title ($n):"
        $lines | Select-Object -First $max | ForEach-Object { Write-Host "  $_" }
        if ($n -gt $max) { Write-Host "  ... (-ShowLog para ver todos)" }
    }
    Show "ERROS" $errors
    Show "Referencias/citacoes indefinidas" $undef
    Show "Avisos da bibliografia" $bibW
    Show "Overfull hbox (linha saindo da margem)" $over

    $ok = ($rc -eq 0) -and (@($errors).Count -eq 0) -and (Test-Path $pdf)
    Write-Host ""
    if ($ok) { Write-Host "PDF OK: $pdf ($pages paginas)" -ForegroundColor Green }
    elseif ($m) { Write-Host "PDF gerado COM $(@($errors).Count) ERRO(S): $pdf ($pages paginas). Logs em $Out" -ForegroundColor Yellow }
    else { Write-Host "FALHOU sem gerar PDF (pdflatex rc=$rc). Logs em $Out ($base.log, run*.txt)" -ForegroundColor Red }
    exit $(if ($ok) { 0 } else { 1 })
}
finally {
    Pop-Location
}
