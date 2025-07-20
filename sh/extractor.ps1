# Set file paths
$baseDir = $PSScriptRoot
$sourceFilePath = Join-Path $baseDir "sh/utilkit.src.sh"
$targetFilePath = Join-Path $baseDir "sh/utilkit.sh"
$jsonFilePath = Join-Path $baseDir "sh/utilkit.json"

# Function to generate a random 6-character alphanumeric string
function Get-RandomString {
    $charSet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    -join ((1..6) | ForEach-Object { $charSet[(Get-Random -Minimum 0 -Maximum $charSet.Length)] })
}

# Create a new JSON object
$jsonObject = @{
    "en"      = @{}
    "zh-Hans" = @{}
    "zh-Hant" = @{}
}

# Read the source script content
$scriptContent = Get-Content $sourceFilePath -Raw -Encoding UTF8

# Regex to find the target strings
$regex = '(Ask|Txt|Task|Err)\s+"([^"]+)"'
$regexMatches = [regex]::Matches($scriptContent, $regex)

# Process each match in reverse order to avoid messing up indices
for ($i = $regexMatches.Count - 1; $i -ge 0; $i--) {
    $match = $regexMatches[$i]
    $originalText = $match.Groups[2].Value
    
    # Skip if the text is already a placeholder
    if ($originalText -match '^\*#([a-zA-Z0-9]{6})#\*$') {
        continue
    }

    # Generate a unique random ID
    do {
        $randomId = Get-RandomString
    } while ($jsonObject.'zh-Hant'.ContainsKey($randomId))

    # Add the new entry to the JSON object for all languages
    $jsonObject.'en'[$randomId] = $originalText
    $jsonObject.'zh-Hans'[$randomId] = $originalText
    $jsonObject.'zh-Hant'[$randomId] = $originalText
    
    # Replace the text in the script content
    $placeholder = "*#$randomId#*"
    $commandType = $match.Groups[1].Value
    $newCapture = "$commandType `"$placeholder`""
    
    # To avoid replacing parts of other strings, we'll replace based on index
    $scriptContent = $scriptContent.Substring(0, $match.Index) + $newCapture + $scriptContent.Substring($match.Index + $match.Length)
}

# Write the modified content to the new target file
Set-Content -Path $targetFilePath -Value $scriptContent -Encoding UTF8 -NoNewline

# Function to format a JSON string with custom indentation
function Format-Json {
    param(
        [string]$jsonString,
        [int]$indentSize = 2
    )

    $indent = 0
    $result = New-Object System.Text.StringBuilder
    $inString = $false
    $indentStr = ' ' * $indentSize

    for ($i = 0; $i -lt $jsonString.Length; $i++) {
        $char = $jsonString[$i]

        if ($inString) {
            [void]$result.Append($char)
            if ($char -eq '\') {
                $i++
                if ($i -lt $jsonString.Length) {
                    [void]$result.Append($jsonString[$i])
                }
            } elseif ($char -eq '"') {
                $inString = $false
            }
            continue
        }

        if ($char -eq '"') {
            $inString = $true
            [void]$result.Append($char)
            continue
        }

        if ($char -eq '{' -or $char -eq '[') {
            [void]$result.Append($char)
            [void]$result.Append("`n")
            $indent++
            [void]$result.Append($indentStr * $indent)
            continue
        }

        if ($char -eq '}' -or $char -eq ']') {
            [void]$result.Append("`n")
            $indent--
            [void]$result.Append($indentStr * $indent)
            [void]$result.Append($char)
            continue
        }

        if ($char -eq ',') {
            [void]$result.Append($char)
            [void]$result.Append("`n")
            [void]$result.Append($indentStr * $indent)
            continue
        }
        
        if ($char -eq ':') {
            [void]$result.Append($char)
            [void]$result.Append(' ')
            continue
        }

        if (-not [string]::IsNullOrWhiteSpace($char)) {
            [void]$result.Append($char)
        }
    }

    return $result.ToString()
}

# Write the JSON object to the file
$compactJson = $jsonObject | ConvertTo-Json -Depth 100 -Compress
$compactJson = $compactJson.Replace('\\', '\') # Fix for double-escaped backslashes
$formattedJson = Format-Json -jsonString $compactJson -indentSize 2

# Write the updated JSON object to the file without BOM
$utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($jsonFilePath, $formattedJson, $utf8NoBomEncoding)

Write-Host "Creation complete. utilkit.sh and utilkit.json have been created."