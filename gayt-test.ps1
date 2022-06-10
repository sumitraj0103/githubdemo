param (

    [Parameter(Mandatory = $true)][string]$subscription, 
    [Parameter(Mandatory = $true)][string]$RGName,    
    [Parameter(Mandatory = $true)][string]$GatewayName,
    [Parameter(Mandatory = $true)][string]$FrontEndIPConfig,
    [Parameter(Mandatory = $true)][string]$newPool,
    [Parameter(Mandatory = $true)][string]$redirectruleName80,    
    [Parameter(Mandatory = $true)][string]$ruleName443,
    [Parameter(Mandatory = $true)][string]$BackendHttpSettingName,
    [Parameter(Mandatory = $true)][string]$PoolAddresses, 
    [Parameter(Mandatory = $true)][string]$listenerName443,
    [Parameter(Mandatory = $true)][string]$listenerName80Redirect,
    [Parameter(Mandatory = $true)][string]$probeName,
    [Parameter(Mandatory = $true)][string]$URLname,
    [Parameter(Mandatory = $true)][string]$cerNAME,
    [Parameter(Mandatory = $true)][string]$pfxNAME,
    [Parameter(Mandatory = $true)][string]$appid,
    [Parameter(Mandatory = $true)][string]$appsecret,
    [Parameter(Mandatory = $true)][string]$tenantID
)

<#For Debug

$subscription = "US-AZSUB-AME-TAX-DCMSHARED-PSGAPPS-NPD"
$RGName = "AZRG-USE2-TAX-DCM-Filer-DEV-001"
$GatewayName = "azuse2dfilergwy01"
$FrontEndIPConfig = "gatewayIP" #fixed name, dont change
$newPool = "dev2-pool"
$redirectruleName80 = "rulesURLredirect-dev2-filer"
$ruleName443 = "rulesURL-filer-tardi"
$BackendHttpSettingName = "backendhttpSetting-dev2-tardi"
##$PoolAddresses = "10.212.250.139" #if more than 1 IP {$PoolAddresses = "10.212.250.139", "10.10.10.10" }
$PoolAddresses = "10.212.250.42", "10.212.250.5"
$listenerName443 = "listenerURL443-dev2"
$listenerName80Redirect = "listenerURLRedirect-dev2"
$probeName = "probe443-dev2"
$URLname = "dev2-filer.deloitte.com"
$cerNAME = "dev-filer.cer" #to get this name, run: Get-AzApplicationGatewayAuthenticationCertificate -ApplicationGateway $appgw
$pfxNAME = "dev-filer.pfx" #to get this name, run: Get-AzApplicationGatewaySSLCertificate -ApplicationGateway $appgw
 
#>

#Connect to Azure using SP

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appid, $appsecret
Connect-AzAccount -ServicePrincipal -TenantId $tenantID -Credential $Credential

Set-AzContext -Subscription $subscription
#Set the Subscription


#login here
#get the gateway and the CER/PFX
$AppGw = Get-AzApplicationGateway -Name $GatewayName -ResourceGroupName $RGName
$CER= Get-AzApplicationGatewayAuthenticationCertificate -Name $cerNAME -ApplicationGateway $appgw
$PFX= Get-AzApplicationGatewaySSLCertificate -ApplicationGateway $appgw -Name $pfxNAME

#add new backend pool
$Pool = Add-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $newPool -BackendIPAddresses $PoolAddresses
Set-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $newPool -BackendIPAddresses $PoolAddresses
Set-AzApplicationGateway -ApplicationGateway $AppGw
 
 
#add new probe
$Probe = Add-AzApplicationGatewayProbeConfig -ApplicationGateway $AppGw -Name $probeName -Protocol Https -HostName $URLname -Path "/" -Interval 30 -Timeout 30 -UnhealthyThreshold 3
Set-AzApplicationGatewayProbeConfig -ApplicationGateway $AppGw -Name $probeName -Protocol Https -HostName $URLname -Path "/" -Interval 30 -Timeout 30 -UnhealthyThreshold 3
Set-AzApplicationGateway -ApplicationGateway $AppGw
 
 
#add HTTP setting
#get probe
$probecontext=Get-AzApplicationGatewayProbeConfig -ApplicationGateway $AppGW -Name $probename
$HTTPsetting=  Add-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $BackendHttpSettingName -Probe $probecontext -Port 443 -Protocol Https -AuthenticationCertificates $CER -CookieBasedAffinity Disabled -ErrorAction Stop
SET-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $BackendHttpSettingName -Probe $probecontext -Port 443 -Protocol Https -AuthenticationCertificates $CER -CookieBasedAffinity Disabled -ErrorAction Stop
Set-AzApplicationGateway -ApplicationGateway $AppGw
 
 
 
#add Listener 443
$FrontEndIP= Get-AzApplicationGatewayFrontendIPConfig -Name $FrontEndIPConfig -ApplicationGateway $AppGw
$FrontEndPort443 = Get-AzApplicationGatewayFrontendPort -Name "Port443" -ApplicationGateway $AppGw
$Listener443= Add-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw  -Name $listenerName443 -SslCertificate $PFX -HostName $UrlName -Protocol Https -FrontendIPConfiguration $FrontEndIP -FrontendPort $FrontEndPort443 -ErrorAction Stop
Set-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw  -Name $listenerName443 -SslCertificate $PFX -HostName $URLName -Protocol Https -FrontendIPConfiguration $FrontEndIP -FrontendPort $FrontEndPort443 -ErrorAction Stop
Set-AzApplicationGateway -ApplicationGateway $AppGw
 
#add Listener Redirect
$FrontEndIP= Get-AzApplicationGatewayFrontendIPConfig -Name $FrontEndIPConfig -ApplicationGateway $AppGw
$FrontEndPort80 = Get-AzApplicationGatewayFrontendPort -Name "Port80" -ApplicationGateway $AppGw
$Listener80= Add-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw  -Name $listenerName80Redirect -SslCertificate $PFX -HostName $UrlName  -Protocol Http -FrontendIPConfiguration $FrontEndIP -FrontendPort $FrontEndPort80 -ErrorAction Stop
Set-AzApplicationGatewayHttpListener -ApplicationGateway $AppGw  -Name $listenerName80Redirect -SslCertificate $PFX -HostName $URLName -Protocol Http -FrontendIPConfiguration $FrontEndIP -FrontendPort $FrontEndPort80 -ErrorAction Stop
Set-AzApplicationGateway -ApplicationGateway $AppGw
 
 
#add routing rule for listeners
$HTTPsettingcontext=  GET-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $BackendHttpSettingName
$Listener443Context = GET-AzApplicationGatewayHttpListener -ApplicationGateway $AppGW -Name $listenerName443
$BackendPoolContext = GET-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $newPool
$Rule443 = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGw -Name $ruleName443 -RuleType Basic  -BackendHttpSettings $HTTPsettingcontext -HttpListener $Listener443Context -BackendAddressPool $BackendPoolContext
Set-AzApplicationGateway -ApplicationGateway $AppGw
 
#add routing rule for Redirect
$HTTPsettingcontext=  GET-AzApplicationGatewayBackendHttpSetting -ApplicationGateway $AppGW -Name $BackendHttpSettingName
$Listener80Context = GET-AzApplicationGatewayHttpListener -ApplicationGateway $AppGW -Name $listenerName80Redirect
$BackendPoolContext = GET-AzApplicationGatewayBackendAddressPool -ApplicationGateway $AppGw -Name $newPool
$RuleRedirect = Add-AzApplicationGatewayRedirectConfiguration  -ApplicationGateway $AppGw -Name $redirectruleName80 -RedirectType Permanent -TargetListener $Listener443Context -IncludePath $true -IncludeQueryString $true
Set-AzApplicationGateway -ApplicationGateway $AppGw
$RedirectContext = Get-AzApplicationGatewayRedirectConfiguration -Name $redirectruleName80  -ApplicationGateway $appgw  
$Rule80 = Add-AzApplicationGatewayRequestRoutingRule -ApplicationGateway $AppGw -Name $redirectruleName80 -RuleType Basic   -HttpListener $Listener80Context -RedirectConfiguration $RedirectContext
Set-AzApplicationGateway -ApplicationGateway $AppGw  