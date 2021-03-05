$tp_link_username = ""
$tp_link_password = ""
function get_token () {
    $get_token_params = @{
        method="login"
        params = @{
            appType = ""
            appVersion = ""
            cloudUserName = "$tp_username"
            cloudPassword = "$tp_password"
            platform = ""
            refreshTokenNeeded = $false
            terminalUUID = ""
    	}
    }
    $json = $get_token_params | ConvertTo-Json
    $token = (Invoke-WebRequest "https://n-wap-gw.tplinkcloud.com/api/v1/account" -Method POST -Body $json -ContentType "application/json" | ConvertFrom-Json).result.token
    return $token
}
function ignore_ssl (){
    add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}
function get_things($tp_auth_token){ 
    $things = ((iwr https://euw1-app-server.iot.i.tplinknbu.com/v1/things?page=0 -Headers @{ "Authorization" ="ut|$tp_auth_token"; "app-cid" = "app:TP-Link_Tapo_Android:app" } ).content | ConvertFrom-Json).data
    $countThings = ($things | measure).count
    if ($countThings -eq 1){
        return $things.thingName
    }
    else{
        $selectedThing = $things | Out-GridView -Title "Select a thing" -PassThru
        return $selectedThing.thingName
    }    
}
function turn($tp_link_thing, $tp_link_token, $tp_link_version, $tp_link_on){
    $lamp_params = @{
        version=$tp_link_version+1
        state = @{
            desired = @{
                "on" = $tp_link_on
    	    }
        }
    }
    $json = $lamp_params | ConvertTo-Json
    $response = iwr -Method PATCH -Headers @{ "Authorization" ="ut|$tp_link_token"; "app-cid" = "app:TP-Link_Tapo_Android:app"; "Content-type" = "application/json; charset=UTF-8" } https://euw1-app-server.iot.i.tplinknbu.com/v1/things/$tp_link_thing/shadows -Body $json
}
function get_version($tp_link_thing, $tp_auth_token){
    $version = ((iwr https://euw1-app-server.iot.i.tplinknbu.com/v1/things/shadows?thingNames=$tp_link_thing -Headers @{ "Authorization" ="ut|$tp_auth_token"; "app-cid" = "app:TP-Link_Tapo_Android:app" } ).content | ConvertFrom-Json).shadows.version
    return $version
}
function main($tp_username, $tp_password){
    ignore_ssl
    $tp_link_token = get_token $tp_username $tp_password
    $tp_link_thing = get_things $tp_link_token
    Write-Host "[**] Press 1 to turn on`n[**] Press 2 to turn off`n[**] Press 3 to exit"
    Write-Host "[**] Please choose an option"
    while ($option -ne "D3"){
        $option = [Console]::ReadKey($true).key
        if ($option -eq "D1"){
            $tp_link_version = get_version $tp_link_thing $tp_link_token
            Write-Host "`r[**] Turning lights on"
            turn $tp_link_thing $tp_link_token $tp_link_version $true
        }
        elseif ($option -eq "D2"){
            $tp_link_version = get_version $tp_link_thing $tp_link_token
            Write-Host "`r[**] Turning lights off"
            turn $tp_link_thing $tp_link_token $tp_link_version $false
        }
    }
}
main $tp_link_username $tp_link_password
