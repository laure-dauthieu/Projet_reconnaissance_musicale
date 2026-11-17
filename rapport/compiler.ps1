# Compile le rapport en PDF (MiKTeX) : pdflatex, biber, puis deux passes pdflatex.
# Usage, depuis le dossier rapport/ :   .\compiler.ps1
# Résultat : main.pdf

$bin = "$env:LOCALAPPDATA\Programs\MiKTeX\miktex\bin\x64"
Set-Location $PSScriptRoot

& "$bin\pdflatex.exe" -interaction=nonstopmode main.tex | Out-Null
& "$bin\biber.exe" main | Out-Null
& "$bin\pdflatex.exe" -interaction=nonstopmode main.tex | Out-Null
& "$bin\pdflatex.exe" -interaction=nonstopmode main.tex | Select-String "Output written"

# Erreurs, références manquantes et débordements de marge
$problemes = Select-String -Path main.log -Pattern "^! |undefined|Overfull"
if ($problemes) { $problemes | ForEach-Object { $_.Line } } else { "Aucune erreur ni avertissement important." }
