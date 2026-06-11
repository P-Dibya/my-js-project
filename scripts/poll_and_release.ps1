$buildId = 'd0fa4494-4f00-4ec9-b527-f1545a6610aa'
$repo = 'P-Dibya/my-js-project'
$tag = 'v1.0.0'
$outApk = 'D:\dibya\myapp\myapp.apk'
$maxAttempts = 40
$interval = 15

for ($i = 0; $i -lt $maxAttempts; $i++) {
    Write-Host ("Checking build status (attempt {0}/{1})" -f ($i+1), $maxAttempts)
    $out = eas build:list --platform android --limit 5 2>&1
    if ($out -match 'Status\s+([^\r\n]+)') {
        $status = $matches[1].Trim()
    } else {
        $status = 'unknown'
    }
    Write-Host ("Status: {0}" -f $status)
    if ($status -match 'finished|success|completed') {
        break
    }
    Start-Sleep -Seconds $interval
}

Write-Host 'Final status check...'
$out2 = eas build:list --platform android --limit 5 2>&1
$url = ''
if ($out2 -match 'Build Artifacts URL\s+([^\r\n]+)') { $url = $matches[1].Trim() }
elseif ($out2 -match 'Application Archive URL\s+([^\r\n]+)') { $url = $matches[1].Trim() }

if ([string]::IsNullOrEmpty($url)) {
    Write-Host 'No artifact URL found yet.'
    exit 2
} else {
    Write-Host ("Artifact URL: {0}" -f $url)
    Write-Host ("Downloading to {0}" -f $outApk)
    try {
        Invoke-WebRequest -Uri $url -OutFile $outApk -UseBasicParsing -ErrorAction Stop
    } catch {
        Write-Host "Download failed: $_"
        exit 3
    }
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        Write-Host 'Creating GitHub release with gh CLI'
        gh release create $tag $outApk --repo $repo --title $tag --notes "EAS build $buildId"
        if ($LASTEXITCODE -eq 0) { Write-Host 'Release created successfully.' } else { Write-Host 'gh release command failed.'; exit 5 }
    } else {
        Write-Host 'GitHub CLI (gh) not installed — cannot create release. Install gh or provide a GitHub token to upload.'
        exit 4
    }
}
