# Set the script to exit immediately if a command fails.
$ErrorActionPreference = "Stop"

# Define input and output file paths
$inputFile = "sh/utilkit.src.sh"
$jsonOutputFile = "sh/utilkit.json" # JSON output file
$translatedScriptFile = "sh/utilkit.sh" # Translated script output file

# Check if the input file exists
if (-not (Test-Path $inputFile)) {
    Write-Error "Input file not found: $inputFile"
    exit 1
}

# Read the entire file content as a single string, specifying UTF-8 encoding
$originalContent = Get-Content -Path $inputFile -Raw -Encoding UTF8

# Regex to find all Txt, Ask, Task (first argument), and Err calls with string literals.
# This regex handles escaped quotes and other special characters within the string.
# It captures the content *inside* the quotes.
$regex = '(?:Txt|Ask|Err|Task)\s+"((?:[^"\\]|\\.)*)"'

# Find all matches in the content
$matches = [regex]::Matches($originalContent, $regex)

# Create an ordered hashtable to store the unique strings and their placeholders for JSON.
# This preserves the order of appearance, which can be helpful for translation context.
# Format: Original String -> Placeholder (e.g., "Original Text" -> "*#RANDOMVALUE#*")
$stringMap = [ordered]@{}

# Function to generate a random string of specified length using A-Za-z0-9 characters
function Generate-RandomAlphaNumericString {
    param(
        [int]$Length = 6
    )
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    $result = -join ($chars.ToCharArray() | Get-Random -Count $Length)
    return $result
}

# First pass: Process each match to build the stringMap (original string -> placeholder)
foreach ($match in $matches) {
    # Get the captured string (the content inside the quotes)
    $capturedString = $match.Groups[1].Value
    
    # Skip empty or whitespace-only strings
    if ([string]::IsNullOrWhiteSpace($capturedString)) {
        continue
    }

    # Add the string to the hashtable if it's not already there.
    # The key is the source string, and the value is a unique placeholder.
    if (-not ($stringMap.Keys -contains $capturedString)) {
        # Generate a 6-character random alphanumeric string for the placeholder
        $randomValue = Generate-RandomAlphaNumericString -Length 6
        # The placeholder for script replacement will include *# and #*
        $placeholderForScript = "*#$randomValue#*" 
        $stringMap[$capturedString] = $placeholderForScript
    }
}

# --- JSON Output Formatting Adjustment ---

# Create an ordered hashtable for the zh-Hant translations (placeholder without *#*# -> original string)
$zhHantMap = [ordered]@{}
foreach ($originalString in $stringMap.Keys) {
    $placeholderForScript = $stringMap[$originalString] # e.g., "*#Etv1ux#*"
    # Extract the random value for the JSON key (e.g., "Etv1ux")
    $jsonKey = $placeholderForScript.Replace("*#", "").Replace("#*", "")
    $zhHantMap[$jsonKey] = $originalString
}

# Create the final JSON structure with zh-Hant, en, and zh-Hans sections
$finalJsonStructure = [ordered]@{
    "zh-Hant" = $zhHantMap
    "en" = [ordered]@{} # Empty ordered hashtable for en
    "zh-Hans" = [ordered]@{} # Empty ordered hashtable for zh-Hans
}

# Convert the final structured object to a JSON formatted string.
# Use -Compress to minimize extra newlines in the JSON output.
$jsonOutput = $finalJsonStructure | ConvertTo-Json -Depth 100 -Compress

# Apply the user's specific un-escaping for single quotes, newlines, and tabs.
# Note: Converting \\n to \n within a JSON string value is non-standard JSON behavior,
# but is performed as per your explicit request to match original content representation.
$jsonOutput = $jsonOutput.Replace('\u0027', "'").Replace('\\\\n', '\\n').Replace('\\\\t', '\\t')

# Write the JSON string to the output file using UTF-8 encoding
Set-Content -Path $jsonOutputFile -Value $jsonOutput -Encoding UTF8

Write-Host "Extraction complete. JSON file created at: $jsonOutputFile"

# --- Script Content Replacement (Second Pass) ---

# Second pass: Generate the translated script by replacing original strings with placeholders.
# Use a regex replacement with a script block to dynamically replace matched strings.
$translatedContent = [regex]::Replace(
    $originalContent,
    $regex,
    {
        param($m) # $m is the Match object for the current match
        $capturedString = $m.Groups[1].Value # The content inside the quotes
        $fullMatchText = $m.Value # The entire matched text, e.g., 'Txt "Original String"'

        # Check if the captured string exists in our map using .Keys -contains
        if ($stringMap.Keys -contains $capturedString) {
            $placeholder = $stringMap[$capturedString] # This placeholder includes *# and #*
            
            # Reconstruct the string literal with the placeholder.
            # We need to find the start and end of the string literal within the full match.
            # The regex ensures there are quotes around the captured string.
            $startQuoteIndex = $fullMatchText.IndexOf('"')
            $endQuoteIndex = $fullMatchText.LastIndexOf('"')
            
            if ($startQuoteIndex -ne -1 -and $endQuoteIndex -ne -1) {
                # Extract the part before the opening quote and the part from the closing quote onwards.
                $prefix = $fullMatchText.Substring(0, $startQuoteIndex + 1) # Includes the opening quote
                $suffix = $fullMatchText.Substring($endQuoteIndex) # Includes the closing quote
                
                # Return the modified string with the placeholder inside the original quotes
                return "$prefix$placeholder$suffix"
            } else {
                # Fallback: if quotes aren't found (shouldn't happen with this regex), return original match
                return $fullMatchText
            }
        } else {
            # If for some reason the string is not in our map, return the original match
            return $fullMatchText
        }
    }
)

# Write the translated content to the new script file using UTF-8 encoding
Set-Content -Path $translatedScriptFile -Value $translatedContent -Encoding UTF8

Write-Host "Translated script created at: $translatedScriptFile"
