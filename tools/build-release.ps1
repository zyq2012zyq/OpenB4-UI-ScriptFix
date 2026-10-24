param(
    [Parameter(Mandatory = $true)][string]$Jdk8Home,
    [Parameter(Mandatory = $true)][string]$Jdk17Home,
    [string]$GradleExecutable,
    [string]$InputJar
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$cache = Join-Path $PSScriptRoot '.cache'
$dist = Join-Path $root 'dist'
New-Item -ItemType Directory -Force -Path $cache, $dist | Out-Null

if (-not $InputJar) { $InputJar = Join-Path $root 'vendor\RavenB4-scriptfix-input.jar' }
if (-not $GradleExecutable) { $GradleExecutable = Join-Path $root 'OpenB4\gradlew.bat' }
$toolsJar = Join-Path $Jdk8Home 'lib\tools.jar'
$javac = Join-Path $Jdk8Home 'bin\javac.exe'
$java = Join-Path $Jdk8Home 'bin\java.exe'
foreach ($file in @($InputJar, $GradleExecutable, $toolsJar, $javac, $java)) {
    if (-not (Test-Path -LiteralPath $file)) { throw "Missing required file: $file" }
}

$asmJar = Join-Path $cache 'asm-9.7.1.jar'
if (-not (Test-Path -LiteralPath $asmJar)) {
    Invoke-WebRequest 'https://repo.maven.apache.org/maven2/org/ow2/asm/asm/9.7.1/asm-9.7.1.jar' -OutFile $asmJar
}
$asmHash = (Get-FileHash -LiteralPath $asmJar -Algorithm SHA256).Hash
if ($asmHash -ne '8CADD43AC5EB6D09DE05FAECCA38B917A040BB9139C7EDEB4CC81C740B713281') {
    throw 'ASM download checksum mismatch'
}

$oldJavaHome = $env:JAVA_HOME
$oldPath = $env:PATH
try {
    $env:JAVA_HOME = $Jdk17Home
    $env:PATH = "$(Join-Path $Jdk17Home 'bin');$oldPath"
    $jdk8GradlePath = $Jdk8Home.Replace('\', '/')
    $gradleArgs = @('build', '--no-daemon', '--console=plain', "-Porg.gradle.java.installations.paths=$jdk8GradlePath")
    if ($env:HTTPS_PROXY) {
        $proxy = [uri]$env:HTTPS_PROXY
        $gradleArgs += "-Dhttps.proxyHost=$($proxy.Host)"
        $gradleArgs += "-Dhttps.proxyPort=$($proxy.Port)"
        $gradleArgs += "-Dhttp.proxyHost=$($proxy.Host)"
        $gradleArgs += "-Dhttp.proxyPort=$($proxy.Port)"
    }
    Push-Location (Join-Path $root 'OpenB4')
    try {
        & $GradleExecutable @gradleArgs
        if ($LASTEXITCODE -ne 0) { throw 'Gradle build failed' }
    } finally { Pop-Location }

    $env:JAVA_HOME = $Jdk8Home
    $env:PATH = "$(Join-Path $Jdk8Home 'bin');$oldPath"
    $patcherClasses = Join-Path $cache 'classes'
    New-Item -ItemType Directory -Force -Path $patcherClasses | Out-Null
    & $javac -cp $asmJar -d $patcherClasses (Join-Path $PSScriptRoot 'PatchSliderNumber.java')
    if ($LASTEXITCODE -ne 0) { throw 'Bytecode patcher compilation failed' }

    $python = (Get-Command python -ErrorAction Stop).Source
    $builtJar = Join-Path $root 'OpenB4\build\libs\RavenB4.jar'
    $intermediate = Join-Path $cache 'merged.jar'
    $patchedClass = Join-Path $cache 'ScriptDefaults-modules.class'
    $release = Join-Path $dist 'RavenB4.jar'
    & $python (Join-Path $PSScriptRoot 'merge_compiler_jar.py') $InputJar $builtJar $toolsJar $intermediate
    if ($LASTEXITCODE -ne 0) { throw 'JAR merge failed' }
    & $java -cp "$patcherClasses;$asmJar" PatchSliderNumber $intermediate $patchedClass
    if ($LASTEXITCODE -ne 0) { throw 'Slider patch failed' }
    & $python (Join-Path $PSScriptRoot 'patch_slider_jar.py') $intermediate $patchedClass $release
    if ($LASTEXITCODE -ne 0) { throw 'Final JAR packaging failed' }
    Write-Output "Release ready: $release"
    Write-Output "SHA-256: $((Get-FileHash -LiteralPath $release -Algorithm SHA256).Hash)"
} finally {
    $env:JAVA_HOME = $oldJavaHome
    $env:PATH = $oldPath
}
