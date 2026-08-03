$root = 'd:\tvtime\nextup\lib'
$files = Get-ChildItem -Path $root -Recurse -Filter '*.dart'
# Pattern: Text('...') or Text("...") containing at least one uppercase Latin letter (English), plus at least 3 chars
$pattern = "Text\(\s*(const\s+)?['`"][^'`"]*[A-Za-z]{3,}[^'`"]*['`"]"
foreach ($f in $files) {
    $matches = Select-String -Path $f.FullName -Pattern $pattern -AllMatches
    foreach ($m in $matches) {
        $line = $m.Line.Trim()
        # skip if it contains persian chars (U+0600-U+06FF)
        if ($line -match '[\u0600-\u06FF]') { continue }
        # skip if it contains AppStrings.of or _p( indicators (already localized)
        if ($line -match 'AppStrings') { continue }
        $rel = $f.FullName.Replace($root + '\', '')
        Write-Output "$rel : line $($m.LineNumber) => $line"
    }
}
