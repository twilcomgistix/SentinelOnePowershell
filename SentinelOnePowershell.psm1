<#
.Synopsis
A tool to intreract with Sentinel One from Powershell

.Description
Leverages the Sentinel One API to allow users to get information, create/edit sites, execute actions on agents, and more.

.Example
    # Enter and store API Key and Server FQDN
    Set-S1ModuleConfig

.Example
    # List all sites
    Get-S1Sites

.Example
    # Get All Info on a single site
    Get-S1Site -Name "Example Site Name"
    Get-S1Site -id 12345678910928376
    Get-S1Site -Name "Example Site Name" -IncludeDeleted

.Example
    # Clear out store API Key and Server FQDN
    Reset-S1ModuleConfig

.Example
    # Send a custom API request
    Get-BaseS1Request -endpoint "users?email=user@domain.com" | ForEach {$_.fullName;$_.id}

#>

Function Set-S1ModuleConfig {
    $ConfigPath = "$env:userprofile\sentinelOnePowershell.xml"
    if (Test-Path $ConfigPath) {
        $config = Import-Clixml $ConfigPath
    } else {
        $ConfigHash = @{
            apiToken = Read-Host "Paste your Sentinel One Api Token"
            email = Read-Host "What is your Sentinel One Username?"
            url = Read-Host "What is your Sentinel One management server address?"
        }
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Authorization", "ApiToken $($ConfigHash.apiToken)")
        $headers.Add("Content-Type", "application/json")
        $acctName = (Invoke-RestMethod -Uri "https://$($ConfigHash.url)/web/api/v2.1/accounts" -Method 'GET' -Headers $headers).data.name
        $choose = Read-Host "Is $acctName the Account Scope Name For your Sentinel One Instance? (y/n)"
        if ($choose -match "y") {
            $acctId = (Invoke-RestMethod -Uri "https://$($ConfigHash.url)/web/api/v2.1/accounts" -Method 'GET' -Headers $headers).data.id
        } else {
            $acctId = Read-Host "Enter the Account Id for your Sentinel One Instance"
        }
        $ConfigHash.Add("acctId",$acctId)
        $config = New-Object -TypeName PSObject -Property $ConfigHash
        $config | Export-Clixml $ConfigPath
    }
    Return $config
}

Function Reset-S1ModuleConfig {
    $confirm = Read-Host "This will delete your API Key and user info from this computer. Are you sure? (Y/N)"
    if ($confirm.ToLower() -eq "y") {
        $ConfigPath = "$env:userprofile\sentinelOnePowershell.xml"
        if (Test-Path $ConfigPath) {
            Remove-Item -Path $ConfigPath -Force
            Write-Host "Config deleted."
        } else {
            Write-Host "No Config Found"
        }
    } else {
        Write-Host "Nothing was changed"
    }
}

Function Get-BaseS1Request {
    Param (
        [Parameter(Mandatory=$true)][string]$endpoint
    )
    $config = Set-S1ModuleConfig
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "ApiToken $($config.apiToken)")
    $headers.Add("Content-Type", "application/json")
    $url = "https://$($config.url)/web/api/v2.1/$endpoint"
    $req = Invoke-RestMethod -Uri $url -Method 'GET' -Headers $headers
    return $req.data
}

Function Submit-BaseS1PostRequest {
    Param (
        [Parameter(Mandatory=$true)][string]$endpoint,
        [Parameter(Mandatory=$true)][Object]$payload
    )
    $config = Set-S1ModuleConfig
    $json = $payload | ConvertTo-Json -Depth 10 
    Write-Host $json
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "ApiToken $($config.apiToken)")
    $headers.Add("Content-Type", "application/json")
    $url = "https://$($config.url)/web/api/v2.1/$endpoint"
    $req = Invoke-RestMethod -Uri $url -Method 'POST' -Headers $headers -Body $json
    return $req
}

Function Send-BaseS1PutRequest {
    Param (
        [Parameter(Mandatory=$true)][string]$endpoint,
        [Parameter(Mandatory=$true)][Object]$payload
    )
    $config = Set-S1ModuleConfig
    $json = $payload | ConvertTo-Json -Depth 10 
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "ApiToken $($config.apiToken)")
    $headers.Add("Content-Type", "application/json")
    $url = "https://$($config.url)/web/api/v2.1/$endpoint"
    $req = Invoke-RestMethod -Uri $url -Method 'PUT' -Headers $headers -Body $json
    return $req
}

Function Remove-BaseS1Request {
    Param (
        [Parameter(Mandatory=$true)][string]$endpoint
    )
    $config = Set-S1ModuleConfig
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", "ApiToken $($config.apiToken)")
    $headers.Add("Content-Type", "application/json")
    $url = "https://$($config.url)/web/api/v2.1/$endpoint"
    $req = Invoke-RestMethod -Uri $url -Method 'DELETE' -Headers $headers
    return $req.data
}

Function Remove-S1Site {
    Param (
        [Parameter(Mandatory=$true)][long]$id
    )
    $req = Remove-BaseS1Request -endpoint "sites/$id"
    return $req.data
}

Function Get-S1Sites {
    $data = Get-BaseS1Request -endpoint "sites?limit=100&state=active"
    $data.sites | ForEach {
        $site = [PSCustomObject]@{
            Name = $_.name
            Sku = $_.sku
            Agents = $_.activeLicenses
            SiteID = $_.id
            Token = $_.registrationToken
        }
        $site
    }
}

Function Get-S1Site {
    Param (
        [Parameter(Mandatory=$false)][long]$id,
        [Parameter(Mandatory=$false)][string]$name,
        [switch]$IncludeDeleted
    )
    if ((!$id) -and (!$name)) {
        Write-Host "Please include a Site Id or a Site Name"
    } else {
        if ($id) {
            $data = Get-BaseS1Request -endpoint "sites/$id"
            $data
        }
        if ($name -and ($IncludeDeleted -eq $false)) {
            $data = Get-BaseS1Request -endpoint "sites?name=$name&state=active"
            $data.sites
        }
        if ($name -and ($IncludeDeleted -eq $true)){
            $data = Get-BaseS1Request -endpoint "sites?name=$name"
            $data.sites
        } 
    }   
}

Function Get-S1User {
    Param (
        [Parameter(Mandatory=$false)][string]$email,
        [Parameter(Mandatory=$false)][long]$id,
        [switch]$all
    )
    if ($all -eq $true) {
        $data = Get-BaseS1Request -endpoint "users?limit=100"
        $data | ForEach { $_ }
    }
    if ($email) {
        $data = Get-BaseS1Request -endpoint "users?email=$email"
        $data
    }
    if ($id) {
        $data = Get-BaseS1Request -endpoint "users/$id"
        $data
    }
}

# This function was originally created for a specific tenant. It's been redacted and will require some updating to work universally
# Function Set-S1UserRole {
#     Param (
#         [Parameter(Mandatory=$true)][string]$email,
#         [Parameter(Mandatory=$true)][ValidateSet("Admin","Viewer","IT","IR Team","SOC","C-Level")][string]$role,
#         [Parameter(Mandatory=$false)][switch]$all,
#         [Parameter(Mandatory=$false)][long]$siteId
#     )
#     $userId = (Get-S1User -email $email).id
#     $assignments = [PSCustomObject]@()
#     $roles = (Get-BaseS1Request -endpoint "rbac/roles" | Select name,id)
#     $roleData = $roles | Where {$_.name -match "$role"}
#     if ($siteId -and !$all) {
#         $sites = (Get-S1Site -id $siteId | Select).id
#     } elseif ($all -and !$siteId) {
#         $sites = Get-S1Sites | Where { !($_.Name -match "REDACTED") } | Select -Expand SiteID
#     }
#     $sites | ForEach {
#         $role = [PSCustomObject]@{
#             roleId = "$($roleData.id)"
#             id = "$_"
#         }
#         $assignments += $role
#     }
#     $permissions = [PSCustomObject]@{
#         data = [PSCustomObject]@{
#             scope = "site"
#             scopeRoles = $assignments
#         }
#     }
#     Send-BaseS1PutRequest -endpoint "users/$userId" -payload $permissions
# }

Function Add-S1SiteGroup {
    Param (
        [Parameter(Mandatory=$true)][string]$siteId,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$FilterId
    )
    $payload = [PSCustomObject]@{
        data = [PSCustomObject]@{
            siteId = "$siteId"
            name = "$Name"
            filterId = "$FilterId"
            inherits = $true
        }
    }
    Submit-BaseS1PostRequest -endpoint "groups" -payload $payload
}

Function Add-S1SiteFilters {
    Param (
        [Parameter(Mandatory=$true)][string]$siteId
    )
    $wks = [PSCustomObject]@{
        data = [PSCustomObject]@{
            name = "Workstations"
            filterFields = [PSCustomObject]@{
                machineTypes = "laptop","desktop"
            }
            siteId = "$siteId"
            scopeLevel = "site"
        }
    }
    $srv = [PSCustomObject]@{
        data = [PSCustomObject]@{
            name = "Servers"
            filterFields = [PSCustomObject]@{
                machineTypes = "server"
            }
            siteId = "$siteId"
            scopeLevel = "site"
        }
    }
    $wksreq = Submit-BaseS1PostRequest -endpoint "filters" -payload $wks
    $srvreq = Submit-BaseS1PostRequest -endpoint "filters" -payload $srv
    Add-S1SiteGroup -siteId $siteId -Name "Servers" -FilterId "$($srvreq.data.id)"
    Add-S1SiteGroup -siteId $siteId -Name "Workstations" -FilterId "$($wksreq.data.id)"
}

Function Add-NewS1Site {
    Param (
        [Parameter(Mandatory=$true)][string]$Name
    )
    $id = (Set-S1ModuleConfig).acctId
    $payload = [PSCustomObject]@{
        data = [PSCustomObject]@{
            siteType = "Paid"
            name = "$Name"
            totalLicenses = 200
            sku = "Control"
            inherits = $true
            suite = "Control"
            accountId = "$id"
        }
    }
    $req = Submit-BaseS1PostRequest -endpoint "sites" -payload $payload
    $req.data.id
    Add-S1SiteFilters -siteId "$($req.data.id)"
    # $users = Get-S1User -all | Where {$_.source -eq "sso_saml"} | Select email,id
    # $users | ForEach {
    #     Set-S1UserRole -email $_.email -siteId "$($req.data.id)" -role "Admin"
    # }
}

Function Update-AgentsSiteWide {
    Param (
        [Parameter(Mandatory=$true)][string]$SiteId
    )
    $version = Get-BaseS1Request -endpoint "update/agent/packages?sortBy=version&fileExtension=.msi&sortOrder=desc&osTypes=windows&limit=2&packageTypes=AgentAndRanger" | Where{ $_.osArch -eq "64 bit" }
    $newVersionId = $version.id
    $payload = [PSCustomObject]@{
        data = [PSCustomObject]@{
            packageId = $newVersionId
        }
        filter = [PSCustomObject]@{
            siteIds = $siteId
        }
    }
    Submit-BaseS1PostRequest -endpoint "agents/actions/update-software" -payload $payload
}

Export-ModuleMember -Function *