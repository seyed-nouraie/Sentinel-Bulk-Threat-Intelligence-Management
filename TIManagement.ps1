$token = Get-AzAccessToken
$token = $token.token
$header = @{"Accept" = "application/json" ; "authorization" = "bearer $token"}

$subId = Read-Host "Please enter your subscription ID"
$rgName = Read-Host "Please enter your resource group name"
$laName = Read-Host "Please enter your workspace name"

$metrics = Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.OperationalInsights/workspaces/$laName/providers/Microsoft.SecurityInsights/threatIntelligence/main/metrics?api-version=2023-11-01" -Header $header

$metricsObj = $metrics.Content | ConvertFrom-Json

$metricsObj.Value.Properties.SourceMetrics.MetricName

$source = Read-Host "Select a source from the list above to delete"

$indicatorsArr = @()

$body = @{}
$body.sources = @("$source")
$requestJson = $body | ConvertTo-Json

$indicators = Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.OperationalInsights/workspaces/$laName/providers/Microsoft.SecurityInsights/threatIntelligence/main/queryIndicators?api-version=2023-11-01" -Header $header -Body $requestJson -Method Post -ContentType "application/json"


$indicatorsJson = $indicators.Content | ConvertFrom-Json
$indicatorsArr += $indicatorsJson.value


$nextLink = $indicatorsJson.nextLink

while ($nextLink -ne $null){
Write-Host "Reading next batch of indicators..."
$skipToken = $indicatorsJson.nextLink.Substring($indicatorsJson.nextlink.indexof("skipToken") + 10)

$body.skipToken = $skipToken
$requestJson = $body | ConvertTo-Json

$indicators = Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.OperationalInsights/workspaces/$laName/providers/Microsoft.SecurityInsights/threatIntelligence/main/queryIndicators\?api-version=2023-11-01" -Header $header -Body $requestJson -Method Post -ContentType "application/json"
$indicatorsJson = $indicators.Content | ConvertFrom-Json

$indicatorsArr += $indicatorsJson.value

$nextLink = $indicatorsJson.nextLink
}


$indicatorsLen = $indicatorsArr.length

$continue = Read-Host "Would you like to delete $indicatorsLen indicators? [y/n]"

$count = 0
if ($continue -eq "y"){
  $token = Get-AzAccessToken
  $token = $token.token
  $header = @{"Accept" = "application/json" ; "authorization" = "bearer $token"}
  
  foreach ($indicatorName in $indicatorsArr.name){
    $count += 1
    Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.OperationalInsights/workspaces/$laName/providers/Microsoft.SecurityInsights/threatIntelligence/main/indicators/$indicatorName?api-version=2023-11-01" -Method Delete -Header $header
    Write-Host "Deleted $count indicators so far..."
  }}
