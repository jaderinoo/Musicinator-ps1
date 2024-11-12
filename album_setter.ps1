# Define the base directory (current directory)
$baseDirectory = Get-Location

# Define the path to the WinRAR executable
$winRARPath = "C:\Program Files\WinRAR\WinRAR.exe"  # Update if WinRAR is installed elsewhere

# Function to extract all TAR files using WinRAR
function Extract-TarFiles {
    param (
        [string]$baseDir,
        [string]$rarPath
    )

    # Get all TAR files in the base directory
    $tarFiles = Get-ChildItem -Path $baseDir -Filter *.tar -File

    if ($tarFiles.Count -eq 0) {
        Write-Output "No TAR files found in $baseDir."
        return
    }

    foreach ($tarFile in $tarFiles) {
        Write-Output "Extracting $($tarFile.Name) to $baseDir using WinRAR..."
        Start-Process -FilePath $rarPath -ArgumentList "x -y `"$($tarFile.FullName)`" `"$baseDir\`"" -Wait
        Write-Output "Extraction of $($tarFile.Name) completed."
    }
}

# Function to process "Artist - Album (Year)" folders
function Process-AlbumFolders {
    param (
        [string]$baseDir
    )

    # Define the regex pattern for "Artist - Album (Year)"
    $pattern = '^(.*?)\s*-\s*.*\(\d{4}\)$'

    # Find all directories matching the pattern
    $albumFolders = Get-ChildItem -Path $baseDir -Directory -Recurse | Where-Object { $_.Name -match $pattern }

    Write-Output "Found $($albumFolders.Count) album folder(s) matching the pattern 'Artist - Album (Year)'."

    foreach ($albumFolder in $albumFolders) {
        Write-Output "Processing album folder: $($albumFolder.FullName)"

        # Delete 'CORERADIO.ONLINE.url' if it exists
        $unwantedFile = Join-Path -Path $albumFolder.FullName -ChildPath "CORERADIO.ONLINE.url"
        if (Test-Path -Path $unwantedFile) {
            Remove-Item -Path $unwantedFile -Force
            Write-Output "Deleted unwanted file: $unwantedFile"
        }

        # Extract artist name from folder name
        if ($albumFolder.Name -match '^(.*?)\s*-\s*') {
            $artistName = $matches[1].Trim()
        }
        else {
            Write-Warning "Could not extract artist name from folder: $($albumFolder.Name). Skipping."
            continue
        }

        # Define artist folder path
        $artistFolderPath = Join-Path -Path $baseDir -ChildPath $artistName

        # Create artist folder if it doesn't exist
        if (!(Test-Path -Path $artistFolderPath)) {
            New-Item -ItemType Directory -Path $artistFolderPath | Out-Null
            Write-Output "Created artist folder: $artistFolderPath"
        }

        # Define destination path for the album folder
        $destinationPath = Join-Path -Path $artistFolderPath -ChildPath $albumFolder.Name

        # Move the album folder into the artist folder
        try {
            Move-Item -Path $albumFolder.FullName -Destination $artistFolderPath -Force
            Write-Output "Moved '$($albumFolder.Name)' into '$artistName' folder."
        }
        catch {
            Write-Error "Failed to move '$($albumFolder.Name)': $_"
        }
    }
}

# Main Execution Flow

# Step 1: Extract all TAR files using WinRAR
Extract-TarFiles -baseDir $baseDirectory -rarPath $winRARPath

# Step 2: Process all "Artist - Album (Year)" folders
Process-AlbumFolders -baseDir $baseDirectory

Write-Output "Folder organization complete."
