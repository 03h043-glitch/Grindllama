param(
    [string]$WorkbookPath = "vanilla_wow_classic_grinding_locations_expanded_addon_db.xlsx",
    [string]$SheetName = "Addon_DB",
    [string]$OutputPath = "Data\GrindLocations.lua",
    [int]$RowsPerShard = 20,
    [int]$MaxShards = 10
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

function N($Value) {
    if ($null -eq $Value) { return "" }
    $text = [string]$Value
    $text = $text -replace [char]0x00A0, " "
    $text = $text -replace [char]0x2018, "'"
    $text = $text -replace [char]0x2019, "'"
    $text = $text -replace [char]0x201C, '"'
    $text = $text -replace [char]0x201D, '"'
    $text = $text -replace [char]0x2013, "-"
    $text = $text -replace [char]0x2014, "-"
    $text = $text -replace [char]0x2026, "..."
    return ($text -replace "\s+", " ").Trim()
}

function I($Value, [int]$Default = 0) {
    $text = N $Value
    if ($text -eq "") { return $Default }
    $number = 0.0
    if ([double]::TryParse($text, [ref]$number)) { return [int][math]::Round($number) }
    return $Default
}

function Rating($Value, [int]$Default = 3) {
    $text = (N $Value).ToLowerInvariant()
    if ($text -eq "") { return $Default }
    $number = 0.0
    if ([double]::TryParse($text, [ref]$number)) {
        if ($number -le 5) { return [math]::Max(1, [math]::Min(5, [int][math]::Round($number))) }
        if ($number -le 10) { return [math]::Max(1, [math]::Min(5, [int][math]::Ceiling($number / 2))) }
        if ($number -ge 85) { return 5 }
        if ($number -ge 70) { return 4 }
        if ($number -ge 50) { return 3 }
        if ($number -ge 30) { return 2 }
        return 1
    }
    if ($text -match "hyper|excellent|very high|dense|best") { return 5 }
    if ($text -match "high|good|strong") { return 4 }
    if ($text -match "medium|moderate|average") { return 3 }
    if ($text -match "low|light") { return 2 }
    if ($text -match "poor|sparse|weak") { return 1 }
    return $Default
}

function Danger($Risks) {
    $text = (N $Risks).ToLowerInvariant()
    if ($text -eq "" -or $text -match "\blow\b|\bsafe\b|minimal") { return 2 }
    $score = 2
    foreach ($word in @("elite", "cave", "caster", "runner", "patrol", "respawn", "pvp", "contested", "stealth", "poison", "fear", "net", "overpull", "danger", "high")) {
        if ($text.Contains($word)) { $score += 1 }
    }
    return [math]::Max(1, [math]::Min(5, $score))
}

function Gold($Drops) {
    $text = (N $Drops).ToLowerInvariant()
    if ($text -eq "") { return 1 }
    $score = 1
    foreach ($word in @("cloth", "leather", "ore", "herb", "elemental", "essence", "pearl", "recipe", "green", "blue", "rare", "vendor", "coin", "gold", "scale")) {
        if ($text.Contains($word)) { $score += 1 }
    }
    return [math]::Max(1, [math]::Min(5, $score))
}

function Competition($Risks, $Notes, $Tags) {
    $text = ((N $Risks) + " " + (N $Notes) + " " + (N $Tags)).ToLowerInvariant()
    $score = 3
    if ($text -match "quiet|remote|low competition|low traffic") { $score -= 1 }
    foreach ($word in @("popular", "competition", "contested", "crowded", "quest", "traffic", "pvp")) {
        if ($text.Contains($word)) { $score += 1 }
    }
    return [math]::Max(1, [math]::Min(5, $score))
}

function List($Value) {
    $text = N $Value
    if ($text -eq "") { return @() }
    return @($text -split "\s*(?:;|\||,)\s*" | ForEach-Object { N $_ } | Where-Object { $_ -ne "" } | Select-Object -Unique)
}

function JoinList([object[]]$Values) {
    if (-not $Values -or $Values.Count -eq 0) { return "" }
    return (($Values | ForEach-Object { (N $_) -replace ";", "," }) -join ";")
}

function Raw($Value) {
    $text = N $Value
    $text = $text -replace "\|", "/"
    $text = $text -replace "\]\]", "] ]"
    return $text
}

function Slug([string]$Value) {
    $slug = (N $Value).ToLowerInvariant()
    $slug = $slug -replace "&", " and "
    $slug = $slug -replace "'", ""
    $slug = $slug -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    if ($slug -eq "") { return "route" }
    return $slug
}

function ZipText([System.IO.Compression.ZipArchive]$Zip, [string]$Name) {
    $entry = $Zip.GetEntry($Name.TrimStart("/"))
    if (-not $entry) { return $null }
    $reader = [System.IO.StreamReader]::new($entry.Open())
    try { return $reader.ReadToEnd() } finally { $reader.Close() }
}

function ColumnIndex([string]$CellRef) {
    $letters = ([regex]::Match($CellRef, "^[A-Z]+")).Value
    $index = 0
    foreach ($char in $letters.ToCharArray()) {
        $index = ($index * 26) + ([int][char]$char - [int][char]"A" + 1)
    }
    return $index
}

function SharedStrings([System.IO.Compression.ZipArchive]$Zip) {
    $text = ZipText $Zip "xl/sharedStrings.xml"
    if (-not $text) { return @() }
    $xml = [xml]$text
    return @($xml.SelectNodes("//*[local-name()='si']") | ForEach-Object {
        (($_.SelectNodes(".//*[local-name()='t']") | ForEach-Object { $_.InnerText }) -join "")
    })
}

function WorkbookSheets([System.IO.Compression.ZipArchive]$Zip) {
    $workbook = [xml](ZipText $Zip "xl/workbook.xml")
    $rels = [xml](ZipText $Zip "xl/_rels/workbook.xml.rels")
    $targetById = @{}
    foreach ($rel in $rels.Relationships.Relationship) {
        $target = [string]$rel.Target
        if ($target.StartsWith("/")) { $target = $target.TrimStart("/") }
        elseif (-not $target.StartsWith("xl/")) { $target = "xl/" + $target }
        $targetById[$rel.Id] = $target
    }
    $sheets = @{}
    foreach ($sheet in $workbook.SelectNodes("//*[local-name()='sheet']")) {
        $rid = $sheet.GetAttribute("id", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
        $sheets[$sheet.GetAttribute("name")] = $targetById[$rid]
    }
    return $sheets
}

function SheetRows([System.IO.Compression.ZipArchive]$Zip, [string]$WorksheetPath, [object[]]$Shared) {
    $xml = [xml](ZipText $Zip $WorksheetPath)
    $rows = @()
    foreach ($row in $xml.SelectNodes("//*[local-name()='sheetData']/*[local-name()='row']")) {
        $values = @{}
        foreach ($cell in $row.SelectNodes("*[local-name()='c']")) {
            $column = ColumnIndex $cell.GetAttribute("r")
            $type = $cell.GetAttribute("t")
            $valueNode = $cell.SelectSingleNode("*[local-name()='v']")
            $value = ""
            if ($type -eq "s" -and $valueNode) { $value = $Shared[[int]$valueNode.InnerText] }
            elseif ($type -eq "inlineStr") { $value = (($cell.SelectNodes(".//*[local-name()='t']") | ForEach-Object { $_.InnerText }) -join "") }
            elseif ($valueNode) { $value = $valueNode.InnerText }
            $values[$column] = N $value
        }
        $rows += $values
    }
    return $rows
}

if ($RowsPerShard -lt 1) { throw "RowsPerShard must be at least 1." }
if ($MaxShards -lt 1) { throw "MaxShards must be at least 1." }

$zip = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $WorkbookPath))
try {
    $sheets = WorkbookSheets $zip
    if (-not $sheets.ContainsKey($SheetName)) { throw "Workbook does not contain sheet '$SheetName'. Found: $($sheets.Keys -join ', ')" }
    $rows = SheetRows $zip $sheets[$SheetName] (SharedStrings $zip)
    if ($rows.Count -lt 2) { throw "Sheet '$SheetName' does not contain data rows." }

    $headers = @{}
    foreach ($column in $rows[0].Keys) { $headers[$rows[0][$column]] = $column }
    foreach ($required in @("GrindID", "MinLevel", "MaxLevel", "Zone", "Area", "MobGroup")) {
        if (-not $headers.ContainsKey($required)) { throw "Sheet '$SheetName' is missing required column '$required'." }
    }

    $rawRows = @()
    for ($i = 1; $i -lt $rows.Count; $i++) {
        $row = $rows[$i]
        $cell = {
            param([string]$Column)
            if (-not $headers.ContainsKey($Column)) { return "" }
            return $row[$headers[$Column]]
        }
        $grindId = N (& $cell "GrindID")
        $zone = N (& $cell "Zone")
        $area = N (& $cell "Area")
        $minLevel = I (& $cell "MinLevel") 0
        $maxLevel = I (& $cell "MaxLevel") $minLevel
        if ($grindId -eq "" -or $zone -eq "" -or $minLevel -le 0 -or $maxLevel -le 0) { continue }

        $alliance = (N (& $cell "AllianceViable")).ToUpperInvariant() -eq "Y"
        $horde = (N (& $cell "HordeViable")).ToUpperInvariant() -eq "Y"
        $fit = (N (& $cell "FactionFit")).ToLowerInvariant()
        $faction = if ($alliance -and $horde) { "B" } elseif ($alliance) { "A" } elseif ($horde) { "H" } elseif ($fit -match "alliance") { "A" } elseif ($fit -match "horde") { "H" } else { "B" }

        $priority = I (& $cell "PriorityScore") 0
        $spawnWeight = & $cell "SpawnWeight"
        $drops = & $cell "DropsMentioned"
        $professions = & $cell "ProfessionSynergy"
        $risks = & $cell "Risks"
        $notes = & $cell "Notes"
        $tags = & $cell "Tags"
        $xp = if ($priority -gt 0) { Rating $priority 3 } else { Rating $spawnWeight 3 }
        $travel = if ($minLevel -le 10) { 1 } elseif ($minLevel -le 20) { 2 } elseif ($minLevel -le 40) { 3 } else { 4 }

        $values = @(
            (Slug $grindId), $minLevel, $maxLevel, $faction,
            (Raw $zone), (Raw $(if ($area -ne "") { $area } else { "$zone Grind" })),
            (Raw (JoinList @(List (& $cell "MobGroup")))), (Raw (& $cell "MobLevelRange")),
            (Rating (& $cell "Density") 3), (Danger $risks), $travel, $xp, (Gold $drops),
            (Competition $risks $notes $tags), $priority,
            (Raw (& $cell "ApproxCoords")), (Raw (& $cell "SpawnType")), (Raw (& $cell "FarmStyle")),
            (Raw (JoinList @(List $drops))), (Raw (JoinList @(List $professions))),
            (Raw $risks), (Raw $notes), (Raw (JoinList @(List $tags)))
        )
        $rawRows += ($values -join "|")
    }

    $outputDirectory = Split-Path -Parent $OutputPath
    if ($outputDirectory -eq "") { $outputDirectory = "." }
    if (-not (Test-Path -LiteralPath $outputDirectory)) { New-Item -ItemType Directory -Path $outputDirectory | Out-Null }

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($OutputPath)
    $extension = [System.IO.Path]::GetExtension($OutputPath)
    $requiredShards = [int][math]::Ceiling($rawRows.Count / [double]$RowsPerShard)
    if ($requiredShards -gt $MaxShards) { throw "Route data requires $requiredShards shards. Increase MaxShards and add matching files to GrindLlama.toc." }

    $loader = @"
-- Auto-generated from $([System.IO.Path]::GetFileName($WorkbookPath)) sheet '$SheetName'.
-- Update the workbook, then rerun tools\Convert-GrindLocationsFromXlsx.ps1.
local function SplitList(value)
    local result = {}
    if not value or value == "" then
        return result
    end
    for item in string.gmatch(value, "([^;]+)") do
        table.insert(result, item)
    end
    return result
end

local function SplitFields(line)
    local result = {}
    for value in string.gmatch(line .. "|", "([^|]*)|") do
        table.insert(result, value)
    end
    return result
end

local function FactionName(value)
    if value == "A" then
        return "Alliance"
    elseif value == "H" then
        return "Horde"
    end
    return "Both"
end

GrindLlama_Locations = GrindLlama_Locations or {}

function GrindLlama_LoadRouteData(rawData)
    for line in string.gmatch(rawData, "[^\r\n]+") do
        local row = SplitFields(line)
        table.insert(GrindLlama_Locations, {
            id = row[1], name = row[6], zone = row[5], subzone = row[6],
            minLevel = tonumber(row[2]), maxLevel = tonumber(row[3]), idealMin = tonumber(row[2]), idealMax = tonumber(row[3]), faction = FactionName(row[4]),
            mobTypes = SplitList(row[7]), mobLevelRange = row[8],
            density = tonumber(row[9]), danger = tonumber(row[10]), travel = tonumber(row[11]), xp = tonumber(row[12]), gold = tonumber(row[13]),
            competition = tonumber(row[14]), priorityScore = tonumber(row[15]),
            coordinates = row[16], spawnType = row[17], farmStyle = row[18],
            loot = SplitList(row[19]), professions = SplitList(row[20]), risks = row[21], notes = row[22], tags = SplitList(row[23])
        })
    end
end
"@

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $OutputPath), $loader.TrimEnd() + "`n", $utf8NoBom)

    Get-ChildItem -Path $outputDirectory -Filter ("{0}_*{1}" -f $baseName, $extension) -File -ErrorAction SilentlyContinue |
        ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force }

    for ($shardNumber = 1; $shardNumber -le $MaxShards; $shardNumber++) {
        $start = ($shardNumber - 1) * $RowsPerShard
        $end = [math]::Min($start + $RowsPerShard - 1, $rawRows.Count - 1)
        $shardPath = Join-Path $outputDirectory ("{0}_{1:00}{2}" -f $baseName, $shardNumber, $extension)
        $lines = @(
            "-- Auto-generated route data shard $shardNumber from $([System.IO.Path]::GetFileName($WorkbookPath)) sheet '$SheetName'.",
            "-- Update the workbook, then rerun tools\Convert-GrindLocationsFromXlsx.ps1."
        )
        if ($start -lt $rawRows.Count) {
            $lines += "if GrindLlama_LoadRouteData then"
            $lines += "    GrindLlama_LoadRouteData([=["
            $lines += $rawRows[$start..$end]
            $lines += "]=])"
            $lines += "end"
        } else {
            $lines += "-- Reserved for future route rows."
        }
        [System.IO.File]::WriteAllText((Join-Path (Get-Location) $shardPath), ($lines -join "`n") + "`n", $utf8NoBom)
    }

    Write-Output "Wrote $($rawRows.Count) routes to $OutputPath across $requiredShards populated shards ($MaxShards files) from '$SheetName'."
} finally {
    $zip.Dispose()
}
