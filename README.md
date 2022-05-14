# Powershell Module
## Requirements

- An API Token for Sentinel One.
- The FQDN for the Sentinel One Management Server. Like: `hostname.sentinelone.net`

## Installation

Download this directory into `$Home\Documents\WindowsPowerShell\Modules`

You will be prompted for your API Token and the Server FQDN on first usage. You can optionally run `Set-S1ModuleConfig` after installation to set it up.


## Synopsis
A tool to intreract with Sentinel One from Powershell

## Description
Leverages the Sentinel One API to allow users to get information, create/edit sites, execute actions on agents, and more.

## Examples
### Enter and store API Key and Server FQDN
```powershell
Set-S1ModuleConfig
```
### List all sites
```powershell
Get-S1Sites
```
### Get All Info on a single site
```powershell
Get-S1Site -Name "Example Site Name"
```
> Get all data for a chosen client.
```powershell
Get-S1Site -id 12345678910928376
```
```powershell
Get-S1Site -Name "Example Site Name" -IncludeDeleted
```
Use the `-IncludeDeleted` flag to search for sites that are no longer active.
### Create new client site
```powershell
Add-NewS1Site -Name "Name Of Client"
```
> This will automatically create Workstation and Server device groups.

### Clear out stored API Key and Server FQDN
```powershell
Reset-S1ModuleConfig
```
### Send a custom API request
You can use this cmdlet to send custom API requests to the Sentinel One Management API. 

```powershell
Get-BaseS1Request -endpoint "users?email=user@domain.com" | ForEach {$_.fullName;$_.id}
```
```powershell
Get-BaseS1Request -endpoint "agents?sortBy=activeThreats&sortOrder=desc&Infected=true" | Select computerName,id,siteName,siteId
```

# Other Scripts

## Agent installation
Use `Install-S1Agent.ps1` to download and execute the MSI Windows installer for Sentinel One. This script is filtered for only 64-bit. If you need something else, adjust it.

## Api Token generation

Use `Get-NewApiToken.ps1` to generate a new API Token. Executing that script will invalidate the token you used in it.

This script is a proof of concept. If you run it, your new token will be printed to your terminal where you can save it somewhere safe.

I recommend adapting that script to store its results in your RMM or whatever tool you're using to deploy installations and other API calls from. Make it so that it generates a new token and stores it in a variable that the installation script can reference and that the New token script can also reference the very next time it runs.

If you do it this way, you will never have to manually update the API Token which expires every 6 months. 

If you're using some kind of database where you can safely store that token, all the better.