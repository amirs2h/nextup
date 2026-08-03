$root = 'd:\tvtime\nextup\lib'
$files = Get-ChildItem -Path $root -Recurse -Filter '*.dart'
# hintText / labelText / title: '...English...'
$patterns = @(
    "hintText:\s*['`"][A-Za-z][^'`"]{2,}['`"]",
    "labelText:\s*['`"][A-Za-z][^'`"]{2,}['`"]",
    "title:\s*['`"][A-Za-z][^'`"]{2,}['`"]",
    "tooltip:\s*['`"][A-Za-z][^'`"]{2,}['`"]",
    "SnackBar\([^)]*content:\s*Text\(['`"][A-Za-z][^'`"]{2,}['`"]"
)
foreach ($f in $files) {
    foreach ($p in $patterns) {
        $matches = Select-String -Path $f.FullName -Pattern $p -AllMatches
        foreach ($m in $matches) {
            $line = $m.Line.Trim()
            if ($line -match '[\u0600-\u06FF]') { continue }
            if ($line -match 'AppStrings') { continue }
            # skip imports
            if ($line -match '^import ') { continue }
            # skip TextStyle color: 'red' etc
            $rel = $f.FullName.Replace($root + '\', '')
            Write-Output "$rel : line $($m.LineNumber) => $line"
        }
    }
}
