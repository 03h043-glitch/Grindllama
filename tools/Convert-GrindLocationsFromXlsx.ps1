param(
    [string]$WorkbookPath = "vanilla_wow_classic_grinding_locations_expanded_addon_db.xlsx",
    [string]$SheetName = "Addon_DB",
    [string]$OutputPath = "Data\GrindLocations.lua"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Read-ZipText {
    param(
        [System.IO.Compression.ZipArchive]$Zip,
        [string]$Name
    )

    $entry = $Zip.GetEntry($Name.TrimStart("/"))
    if (-not $entry) {
        return $null
    }

    $reader = [System.IO.StreamReader]::new($entry.Open())
    try {
        return $reader.ReadToEnd()
    } finally {
        $reader.Close()
    }
}

function Get-ColumnIndex {
    param([string]$CellRef)

    $letters = ([regex]::Match($CellRef, "^[A-Z]+")).Value
    $index = 0
    foreach ($char in $letters.ToCharArray()) {
        $index = ($index * 26) + ([int][char]$char - [int][char]"A" + 1)
    }
    return $index
}

function Normalize-Text {
    param($Value)

    if ($null -eq $Value) {
        return ""
    }

    $text = [string]$Value
    $text = $text -replace [char]0x00A0, " "
    $text = $text -replace [char]0x2018, "'"
    $text = $text -replace [char]0x2019, "'"
    $text = $text -replace [char]0x201C, '"'
    $text = $text -replace [char]0x201D, '"'
    $text = $text -replace [char]0x2013, "-"
    $text = $text -replace [char]0x2014, "-"
    $text = $text -replace [char]0x2026, "..."
    $text = $text -replace "\s+", " "
    return $text.Trim()
}

function Convert-ToInt {
    param(
        $Value,
        [int]$Default = 0
    )

    $text = Normalize-Text $Value
    if ($text -eq "") {
        return $Default
    }

    $number = 0.0
    if ([double]::TryParse($text, [ref]$number)) {
        return [int][math]::Round($number)
    }

    return $Default
}

function Convert-ToRating {
    param(
        $Value,
        [int]$Default = 3
    )

    $text = (Normalize-Text $Value).ToLowerInvariant()
    if ($text -eq "") {
        return $Default
    }

    $number = 0.0
    if ([double]::TryParse($text, [ref]$number)) {
        if ($number -le 5) {
            return [math]::Max(1, [math]::Min(5, [int][math]::Round($number)))
        }
        if ($number -le 10) {
            return [math]::Max(1, [math]::Min(5, [int][math]::Ceiling($number / 2)))
        }
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

function Convert-ToDanger {
    param($Risks)

    $text = (Normalize-Text $Risks).ToLowerInvariant()
    if ($text -eq "" -or $text -match "\blow\b|\bsafe\b|minimal") {
        return 2
    }

    $score = 2
    foreach ($keyword in @("elite", "cave", "caster", "runner", "patrol", "respawn", "pvp", "contested", "stealth", "poison", "fear", "net", "overpull", "danger", "high")) {
        if ($text.Contains($keyword)) {
            $score += 1
        }
    }

    return [math]::Max(1, [math]::Min(5, $score))
}

function Convert-ToGold {
    param($Drops)

    $text = (Normalize-Text $Drops).ToLowerInvariant()
    if ($text -eq "") {
        return 1
    }

    $score = 1
    foreach ($keyword in @("cloth", "leather", "ore", "herb", "elemental", "essence", "pearl", "recipe", "green", "blue", "rare", "vendor", "coin", "gold", "scale")) {
        if ($text.Contains($keyword)) {
            $score += 1
        }
    }

    return [math]::Max(1, [math]::Min(5, $score))
}

function Convert-ToCompetition {
    param(
        $Risks,
        $Notes,
        $Tags
    )

    $text = ((Normalize-Text $Risks) + " " + (Normalize-Text $Notes) + " " + (Normalize-Text $Tags)).ToLowerInvariant()
    $score = 3

    if ($text -match "quiet|remote|low competition|low traffic") {
        $score -= 1
    }
    foreach ($keyword in @("popular", "competition", "contested", "crowded", "quest", "traffic", "pvp")) {
        if ($text.Contains($keyword)) {
            $score += 1
        }
    }

    return [math]::Max(1, [math]::Min(5, $score))
}

function Convert-ToFaction {
    param(
        $FactionFit,
        $AllianceViable,
        $HordeViable
    )

    $fit = (Normalize-Text $FactionFit).ToLowerInvariant()
    $alliance = (Normalize-Text $AllianceViable).ToUpperInvariant() -eq "Y"
    $horde = (Normalize-Text $HordeViable).ToUpperInvariant() -eq "Y"

    if ($alliance -and $horde) { return "Both" }
    if ($alliance) { return "Alliance" }
    if ($horde) { return "Horde" }
    if ($fit -match "alliance") { return "Alliance" }
    if ($fit -match "horde") { return "Horde" }
    return "Both"
}

function Split-List {
    param($Value)

    $text = Normalize-Text $Value
    if ($text -eq "") {
        return @()
    }

    return @(
        $text -split "\s*(?:;|\||,)\s*" |
            ForEach-Object { Normalize-Text $_ } |
            Where-Object { $_ -ne "" } |
            Select-Object -Unique
    )
}

function Convert-ToSlug {
    param([string]$Value)

    $slug = (Normalize-Text $Value).ToLowerInvariant()
    $slug = $slug -replace "&", " and "
    $slug = $slug -replace "'", ""
    $slug = $slug -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")
    if ($slug -eq "") {
        return "route"
    }
    return $slug
}

function Join-RawList {
    param([object[]]$Values)

    if (-not $Values -or $Values.Count -eq 0) {
        return ""
    }

    return (($Values | ForEach-Object { (Normalize-Text $_) -replace ";", "," }) -join ";")
}

function Convert-ToRawField {
    param($Value)

    $text = Normalize-Text $Value
    $text = $text -replace "\|", "/"
    $text = $text -replace "\]\]", "] ]"
    return $text
}

function Get-SharedStrings {
    param([System.IO.Compression.ZipArchive]$Zip)

    $sharedStrings = @()
    $text = Read-ZipText $Zip "xl/sharedStrings.xml"
    if (-not $text) {
        return $sharedStrings
    }

    $xml = [xml]$text
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace("x", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")

    foreach ($si in $xml.SelectNodes("//x:si", $ns)) {
        $parts = @()
        foreach ($node in $si.SelectNodes(".//x:t", $ns)) {
            $parts += $node.InnerText
        }
        $sharedStrings += ($parts -join "")
    }

    return $sharedStrings
}

function Get-WorkbookSheets {
    param([System.IO.Compression.ZipArchive]$Zip)

    $workbook = [xml](Read-ZipText $Zip "xl/workbook.xml")
    $rels = [xml](Read-ZipText $Zip "xl/_rels/workbook.xml.rels")

    $targetById = @{}
    foreach ($rel in $rels.Relationships.Relationship) {
        $target = [string]$rel.Target
        if ($target.StartsWith("/")) {
            $target = $target.TrimStart("/")
        } elseif (-not $target.StartsWith("xl/")) {
            $target = "xl/" + $target
        }
        $targetById[$rel.Id] = $target
    }

    $ns = New-Object System.Xml.XmlNamespaceManager($workbook.NameTable)
    $ns.AddNamespace("x", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")
    $ns.AddNamespace("r", "http://schemas.org/officeDocument/2006/relationships")

    $sheets = @{}
    foreach ($sheet in $workbook.SelectNodes("//x:sheet", $ns)) {
        $relationshipId = $sheet.GetAttribute("id", "http://schemas.openxmlformats.org/officeDocument/2006/relationships")
        $sheets[$sheet.GetAttribute("name")] = $targetById[$relationshipId]
    }

    return $sheets
}

function Get-SheetRows {
    param(
        [System.IO.Compression.ZipArchive]$Zip,
        [string]$WorksheetPath,
        [object[]]$SharedStrings
    )

    $xml = [xml](Read-ZipText $Zip $WorksheetPath)
    $ns = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
    $ns.AddNamespace("x", "http://schemas.openxmlformats.org/spreadsheetml/2006/main")

    $rows = @()
    foreach ($row in $xml.SelectNodes("//x:sheetData/x:row", $ns)) {
        $values = @{}
        foreach ($cell in $row.SelectNodes("x:c", $ns)) {
            $ref = $cell.GetAttribute("r")
            $columnIndex = Get-ColumnIndex $ref
            $type = $cell.GetAttribute("t")
            $valueNode = $cell.SelectSingleNode("x:v", $ns)
            $value = ""

            if ($type -eq "s" -and $valueNode) {
                $value = $SharedStrings[[int]$valueNode.InnerText]
            } elseif ($type -eq "inlineStr") {
                $parts = @()
                foreach ($textNode in $cell.SelectNodes(".//x:t", $ns)) {
                    $parts += $textNode.InnerText
                }
                $value = $parts -join ""
            } elseif ($valueNode) {
                $value = $valueNode.InnerText
            }

            $values[$columnIndex] = Normalize-Text $value
        }
        $rows += $values
    }

    return $rows
}

$resolvedWorkbookPath = Resolve-Path -LiteralPath $WorkbookPath
$zip = [System.IO.Compression.ZipFile]::OpenRead($resolvedWorkbookPath)

try {
    $sharedStrings = Get-SharedStrings $zip
    $sheets = Get-WorkbookSheets $zip
    if (-not $sheets.ContainsKey($SheetName)) {
        throw "Workbook does not contain sheet '$SheetName'. Found: $($sheets.Keys -join ', ')"
    }

    $rows = Get-SheetRows $zip $sheets[$SheetName] $sharedStrings
    if ($rows.Count -lt 2) {
        throw "Sheet '$SheetName' does not contain data rows."
    }

    $headerByColumn = $rows[0]
    $headers = @{}
    foreach ($columnIndex in $headerByColumn.Keys) {
        $headers[$headerByColumn[$columnIndex]] = $columnIndex
    }

    foreach ($required in @("GrindID", "MinLevel", "MaxLevel", "Zone", "Area", "MobGroup")) {
        if (-not $headers.ContainsKey($required)) {
            throw "Sheet '$SheetName' is missing required column '$required'."
        }
    }

    function Get-Value {
        param(
            [hashtable]$Row,
            [string]$Column
        )

        if (-not $headers.ContainsKey($Column)) {
            return ""
        }

        $columnIndex = $headers[$Column]
        if ($Row.ContainsKey($columnIndex)) {
            return $Row[$columnIndex]
        }

        return ""
    }

    $lines = @()
    $lines += "-- Auto-generated from $([System.IO.Path]::GetFileName($WorkbookPath)) sheet '$SheetName'."
    $lines += "-- Update the workbook, then rerun tools\Convert-GrindLocationsFromXlsx.ps1."
    $lines += "local function SplitList(value)"
    $lines += "    local result = {}"
    $lines += "    if not value or value == """" then"
    $lines += "        return result"
    $lines += "    end"
    $lines += "    for item in string.gmatch(value, ""([^;]+)"") do"
    $lines += "        table.insert(result, item)"
    $lines += "    end"
    $lines += "    return result"
    $lines += "end"
    $lines += ""
    $lines += "local function SplitFields(line)"
    $lines += "    local result = {}"
    $lines += "    for value in string.gmatch(line .. ""|"", ""([^|]*)|"") do"
    $lines += "        table.insert(result, value)"
    $lines += "    end"
    $lines += "    return result"
    $lines += "end"
    $lines += ""
    $lines += "local function FactionName(value)"
    $lines += "    if value == ""A"" then"
    $lines += "        return ""Alliance"""
    $lines += "    elseif value == ""H"" then"
    $lines += "        return ""Horde"""
    $lines += "    end"
    $lines += "    return ""Both"""
    $lines += "end"
    $lines += ""
    $lines += "local rawData = [=["

    $written = 0
    for ($i = 1; $i -lt $rows.Count; $i++) {
        $row = $rows[$i]
        $grindId = Normalize-Text (Get-Value $row "GrindID")
        $zone = Normalize-Text (Get-Value $row "Zone")
        $area = Normalize-Text (Get-Value $row "Area")
        $minLevel = Convert-ToInt (Get-Value $row "MinLevel") 0
        $maxLevel = Convert-ToInt (Get-Value $row "MaxLevel") $minLevel

        if ($grindId -eq "" -or $zone -eq "" -or $minLevel -le 0 -or $maxLevel -le 0) {
            continue
        }

        $name = $area
        if ($name -eq "") {
            $name = "$zone Grind"
        }

        $id = Convert-ToSlug $grindId
        $faction = Convert-ToFaction (Get-Value $row "FactionFit") (Get-Value $row "AllianceViable") (Get-Value $row "HordeViable")
        $factionCode = if ($faction -eq "Alliance") { "A" } elseif ($faction -eq "Horde") { "H" } else { "B" }
        $priorityScore = Convert-ToInt (Get-Value $row "PriorityScore") 0
        $spawnWeight = Get-Value $row "SpawnWeight"
        $drops = Get-Value $row "DropsMentioned"
        $risks = Get-Value $row "Risks"
        $notes = Get-Value $row "Notes"
        $tagsText = Get-Value $row "Tags"

        $xpRating = if ($priorityScore -gt 0) { Convert-ToRating $priorityScore 3 } else { Convert-ToRating $spawnWeight 3 }
        $densityRating = Convert-ToRating (Get-Value $row "Density") 3
        $goldRating = Convert-ToGold $drops
        $dangerRating = Convert-ToDanger $risks
        $competitionRating = Convert-ToCompetition $risks $notes $tagsText
        $travelRating = if ($minLevel -le 10) { 1 } elseif ($minLevel -le 20) { 2 } elseif ($minLevel -le 40) { 3 } else { 4 }

        $mobTypes = @(Split-List (Get-Value $row "MobGroup"))
        $mobLevelRange = Normalize-Text (Get-Value $row "MobLevelRange")

        $rawValues = @(
            $id
            $minLevel
            $maxLevel
            $factionCode
            Convert-ToRawField $zone
            Convert-ToRawField $name
            Convert-ToRawField (Join-RawList $mobTypes)
            Convert-ToRawField $mobLevelRange
            $densityRating
            $dangerRating
            $travelRating
            $xpRating
            $goldRating
            $competitionRating
            $priorityScore
        )
        $lines += ($rawValues -join "|")
        $written += 1
    }

    $lines += "]=]"
    $lines += ""
    $lines += "GrindLlama_Locations = {}"
    $lines += "for line in string.gmatch(rawData, ""[^\r\n]+"") do"
    $lines += "    local row = SplitFields(line)"
    $lines += "    table.insert(GrindLlama_Locations, {"
    $lines += "        id = row[1], name = row[6], zone = row[5], subzone = row[6],"
    $lines += "        minLevel = tonumber(row[2]), maxLevel = tonumber(row[3]), idealMin = tonumber(row[2]), idealMax = tonumber(row[3]), faction = FactionName(row[4]),"
    $lines += "        mobTypes = SplitList(row[7]), mobLevelRange = row[8],"
    $lines += "        density = tonumber(row[9]), danger = tonumber(row[10]), travel = tonumber(row[11]), xp = tonumber(row[12]), gold = tonumber(row[13]),"
    $lines += "        competition = tonumber(row[14]), priorityScore = tonumber(row[15])"
    $lines += "    })"
    $lines += "end"
    $content = $lines -join "`n"

    $outputDirectory = Split-Path -Parent $OutputPath
    if ($outputDirectory -ne "" -and -not (Test-Path -LiteralPath $outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    }

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText((Join-Path (Get-Location) $OutputPath), $content + "`n", $utf8NoBom)

    Write-Output "Wrote $written routes to $OutputPath from '$SheetName'."
} finally {
    $zip.Dispose()
}
