$token = Get-AzAccessToken
$token = $token.token
$header = @{"Accept" = "application/json" ; "authorization" = "bearer $token"}

$subId = Read-Host "Please enter your subscription ID"
$rgName = Read-Host "Please enter your resource group name"
$laName = Read-Host "Please enter your workspace name"

$force = Read-Host "Would you like to force delete without being prompted? [y/n]"

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

$count = 0
while ($nextLink -ne $null){
$indicatorsLen = $indicatorsArr.length
Write-Host "Currently read $indicatorsLen indicators. Reading next batch of indicators..."
$skipToken = $indicatorsJson.nextLink.Substring($indicatorsJson.nextlink.indexof("skipToken") + 10)

$body.skipToken = $skipToken
$requestJson = $body | ConvertTo-Json

$indicators = Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.OperationalInsights/workspaces/$laName/providers/Microsoft.SecurityInsights/threatIntelligence/main/queryIndicators\?api-version=2023-11-01" -Header $header -Body $requestJson -Method Post -ContentType "application/json"
$indicatorsJson = $indicators.Content | ConvertFrom-Json

$indicatorsArr += $indicatorsJson.value



if($indicatorsLen -ge 500){
$continue = "n"
if ($force -eq "n"){
  $continue = Read-Host "Would you like to delete $indicatorsLen indicators? [y/n]"
}
if ($continue -eq "y" -or $force -eq "y"){
  $token = Get-AzAccessToken -erroraction silentlyContinue
  if (!($token)){
	connect-azaccount -usedeviceauthentication -subscription $subId
	$token = Get-AzAccessToken
}
  $token = $token.token
  $header = @{"Accept" = "application/json" ; "authorization" = "bearer $token"}
  
  foreach ($indicatorName in $indicatorsArr.name){
    $count += 1
    Invoke-WebRequest -Uri "https://management.azure.com/subscriptions/$subId/resourceGroups/$rgName/providers/Microsoft.OperationalInsights/workspaces/$laName/providers/Microsoft.SecurityInsights/threatIntelligence/main/indicators/$indicatorName\?api-version=2023-11-01" -Method Delete -Header $header
    Write-Host "Deleted $count indicators so far..."
  }}
$indicatorsArr = @()
}

$nextLink = $indicatorsJson.nextLink
}
