<#
.SYNOPSIS
  Espelha um projeto do Overleaf (zip do codigo-fonte) numa pasta local, para versionar no git.

.DESCRIPTION
  Obtencao do zip:
  a) -Baixar: baixa direto do Overleaf usando a sessao salva pelo overleaf-mcp-rt
     (~/.config/overleaf-mcp-rt/credentials.json). O cookie so e lido em memoria e enviado apenas
     para o host ao qual ele pertence; nunca e impresso nem gravado.
     Sessao expirada: npx -y overleaf-mcp-rt login --url <url-do-overleaf> --browser
  b) Manual: no Overleaf, Menu -> Download -> Source; o script usa -Zip <arquivo> ou o zip mais
     recente em ~/Downloads que casar com -Padrao.

  Depois extrai numa pasta temporaria e ESPELHA em -Destino (robocopy /MIR):
  arquivos novos/alterados sao copiados e os que sairam do Overleaf sao removidos da copia.
  Por isso ha travas: -Destino nao pode ser a raiz de um repositorio git, nao pode conter .git,
  e, se ja tiver arquivos, precisa ter o -ArquivoRaiz (ser uma copia anterior do documento).
  Nao faz commit: so mostra o git status/diff --stat se -Destino estiver dentro de um repositorio.

.PARAMETER Destino
  Pasta que recebe a copia (ex.: .\docs\relatorio). Obrigatorio.

.PARAMETER ProjetoId
  Id do projeto no Overleaf (parte da URL /project/<id>). Obrigatorio com -Baixar.

.PARAMETER Baixar
  Baixa o zip direto do Overleaf.

.PARAMETER HostOverleaf
  Nome do host no credentials.json do overleaf-mcp-rt (default: o host padrao configurado).

.PARAMETER Zip
  Caminho de um zip ja baixado.

.PARAMETER Padrao
  Padrao do nome do zip em ~/Downloads (default: *.zip, o mais recente).

.PARAMETER ArquivoRaiz
  Arquivo que precisa existir na raiz do zip (default: main.tex). Use "" para nao checar.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\importar-overleaf.ps1 -Baixar -ProjetoId 0123456789abcdef01234567 -Destino .\docs\relatorio
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\importar-overleaf.ps1 -Zip "$env:USERPROFILE\Downloads\Relatorio.zip" -Destino .\docs\relatorio
#>
param(
    [Parameter(Mandatory = $true)][string]$Destino,
    [string]$ProjetoId,
    [switch]$Baixar,
    [string]$HostOverleaf,
    [string]$Zip,
    [string]$Padrao = "*.zip",
    [string]$ArquivoRaiz = "main.tex"
)

$ErrorActionPreference = "Stop"

# 0. Travas de seguranca do destino (o espelhamento apaga o que nao estiver no zip)
$destinoAbs = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Destino))
if ([System.IO.Path]::GetPathRoot($destinoAbs).TrimEnd("\") -eq $destinoAbs.TrimEnd("\")) {
    throw "Destino nao pode ser a raiz de um disco: $destinoAbs"
}
if ($destinoAbs.TrimEnd("\") -eq $env:USERPROFILE.TrimEnd("\")) { throw "Destino nao pode ser a pasta do usuario." }
if (Test-Path -LiteralPath (Join-Path $destinoAbs ".git")) {
    throw "Destino contem .git (e a raiz de um repositorio). Use uma subpasta, ex.: <repo>\docs\relatorio."
}
if ((Test-Path -LiteralPath $destinoAbs) -and @(Get-ChildItem -LiteralPath $destinoAbs -Force).Count -gt 0 -and
    $ArquivoRaiz -and -not (Test-Path -LiteralPath (Join-Path $destinoAbs $ArquivoRaiz))) {
    throw "Destino ja tem arquivos e nao tem $ArquivoRaiz; nao parece uma copia anterior do documento. Nada foi alterado."
}

# 1. Localiza (ou baixa) o zip
$zipBaixado = $null
if ($Baixar) {
    if (-not $ProjetoId) { throw "-Baixar exige -ProjetoId." }
    if ($ProjetoId -notmatch '^[0-9a-f]{24}$') { throw "ProjetoId invalido (esperado 24 caracteres hexadecimais)." }
    $credArq = Join-Path $env:USERPROFILE ".config\overleaf-mcp-rt\credentials.json"
    if (-not (Test-Path $credArq)) { throw "Sessao do Overleaf nao encontrada ($credArq). Faca login com overleaf-mcp-rt." }
    $cred = Get-Content -LiteralPath $credArq -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not $HostOverleaf) { $HostOverleaf = $cred.default }
    $hostCfg = $cred.hosts.($HostOverleaf)
    if (-not $hostCfg -or -not $hostCfg.session_cookie -or -not $hostCfg.url) {
        throw "Host '$HostOverleaf' sem url/session_cookie no credentials.json."
    }
    $baseUrl = $hostCfg.url.TrimEnd("/")
    if ($baseUrl -notmatch '^https://') { throw "URL do Overleaf precisa ser https ($baseUrl)." }

    # Invoke-WebRequest do PowerShell 5 descarta o header Cookie passado em -Headers;
    # por isso HttpWebRequest. Sem redirecionamento automatico: redirect = sessao invalida.
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $zipBaixado = Join-Path ([System.IO.Path]::GetTempPath()) ("overleaf_" + [guid]::NewGuid().ToString("N") + ".zip")
    Write-Host "Baixando $baseUrl/project/$ProjetoId/download/zip ..."
    $req = [System.Net.HttpWebRequest]::Create("$baseUrl/project/$ProjetoId/download/zip")
    $req.AllowAutoRedirect = $false
    $req.Timeout = 120000
    $req.Headers.Add("Cookie", $hostCfg.session_cookie)
    if ($hostCfg.extra_headers) {
        foreach ($p in $hostCfg.extra_headers.PSObject.Properties) { $req.Headers.Add($p.Name, [string]$p.Value) }
    }
    $cred = $null; $hostCfg = $null
    try { $resp = $req.GetResponse() } catch [System.Net.WebException] { throw "Falha no download: $($_.Exception.Message)" }
    try {
        if ([int]$resp.StatusCode -ne 200 -or $resp.ContentType -notlike "application/zip*") {
            throw "O Overleaf respondeu $([int]$resp.StatusCode) ($($resp.ContentType)) em vez do zip (sessao expirada ou sem acesso ao projeto?). Refaca o login: npx -y overleaf-mcp-rt login --url $baseUrl --browser"
        }
        $in = $resp.GetResponseStream()
        $out = [System.IO.File]::Create($zipBaixado)
        try { $in.CopyTo($out) } finally { $out.Close(); $in.Close() }
    } finally { $resp.Close() }

    $fs = [System.IO.File]::OpenRead($zipBaixado)
    try { $b1 = $fs.ReadByte(); $b2 = $fs.ReadByte() } finally { $fs.Close() }
    if ($b1 -ne 0x50 -or $b2 -ne 0x4B) {
        Remove-Item -LiteralPath $zipBaixado -Force -ErrorAction SilentlyContinue
        throw "O arquivo recebido nao e um zip. Nada foi alterado."
    }
    $Zip = $zipBaixado
}
elseif (-not $Zip) {
    $downloads = Join-Path $env:USERPROFILE "Downloads"
    $candidato = Get-ChildItem -Path $downloads -Filter $Padrao -File -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $candidato) { throw "Nenhum zip '$Padrao' em $downloads. Use -Zip ou -Baixar." }
    $Zip = $candidato.FullName
}
if (-not (Test-Path $Zip)) { throw "Zip nao encontrado: $Zip" }
$infoZip = Get-Item $Zip
Write-Host "Zip: $($infoZip.FullName)  ($($infoZip.LastWriteTime))"

# 2. Extrai e espelha
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("overleaf_x_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    Expand-Archive -LiteralPath $Zip -DestinationPath $tmp -Force
    $origem = $tmp
    $itens = @(Get-ChildItem -LiteralPath $tmp -Force)
    if ($itens.Count -eq 1 -and $itens[0].PSIsContainer) { $origem = $itens[0].FullName }
    if ($ArquivoRaiz -and -not (Test-Path (Join-Path $origem $ArquivoRaiz))) {
        throw "O zip nao tem $ArquivoRaiz na raiz; nao parece ser o documento esperado. Nada foi alterado."
    }
    New-Item -ItemType Directory -Path $destinoAbs -Force | Out-Null
    & robocopy $origem $destinoAbs /MIR /NFL /NDL /NJH /NJS /NP /R:1 /W:1 | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy falhou (codigo $LASTEXITCODE)." }
}
finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    if ($zipBaixado) { Remove-Item -LiteralPath $zipBaixado -Force -ErrorAction SilentlyContinue }
}

# 3. Mostra o que mudou (se estiver dentro de um repositorio git)
$repo = & git -C $destinoAbs rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -eq 0 -and $repo) {
    Write-Host ""
    Write-Host "Alteracoes em $destinoAbs (sem commit):"
    & git -C $destinoAbs -c core.quotepath=off status --short -- .
    & git -C $destinoAbs -c core.quotepath=off diff --stat -- .
} else {
    Write-Host "Copia atualizada em $destinoAbs (fora de repositorio git)."
}
