# .SYNOPSIS
# Export-PublicFolderStatistics.ps1
#    Generates a CSV file that contains the list of public folders and their individual sizes
#
# .DESCRIPTION
#
# Copyright (c) 2011 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.

Param(
    # File to export to
    [Parameter(
        Mandatory=$true,
        HelpMessage = "Full path of the output file to be generated. If only filename is specified, then the output file will be generated in the current directory.")]
    [ValidateNotNull()]
    [string] $ExportFile,
    
    # Server to connect to for generating statistics
    [Parameter(
        Mandatory=$true,
        HelpMessage = "Public folder server to enumerate the folder hierarchy.")]
    [ValidateNotNull()]
    [string] $PublicFolderServer
    )

#load hashtable of localized string
Import-LocalizedData -BindingVariable PublicFolderStatistics_LocalizedStrings -FileName Export-PublicFolderStatistics.strings.psd1
    
################ START OF DEFAULTS ################

$WarningPreference = 'SilentlyContinue';
$script:Exchange14MajorVersion = 14;
$script:Exchange12MajorVersion = 8;

################ END OF DEFAULTS #################

# Function that determines if to skip the given folder
function IsSkippableFolder()
{
    param($publicFolder);
    
    $publicFolderIdentity = $publicFolder.Identity.ToString();
        
    if ($script:SkippedFolders -Contains $publicFolderIdentity)
    {
        return $true;
    }

    for ($index = 0; $index -lt $script:SkippedSubtree.length; $index++)
    {
        if ($publicFolderIdentity.StartsWith($script:SkippedSubtree[$index]))
        {
            return $true;
        }
    }
    
    return $false;
}

# Function that gathers information about different public folders
function GetPublicFolderDatabases()
{
    $script:ServerInfo = Get-ExchangeServer -Identity:$PublicFolderServer;
    $script:PublicFolderDatabasesInOrg = @();
    if ($script:ServerInfo.AdminDisplayVersion.Major -eq $script:Exchange14MajorVersion)
    {
        $script:PublicFolderDatabasesInOrg = @(Get-PublicFolderDatabase -IncludePreExchange2010);
    }
    elseif ($script:ServerInfo.AdminDisplayVersion.Major -eq $script:Exchange12MajorVersion)
    {
        $script:PublicFolderDatabasesInOrg = @(Get-PublicFolderDatabase -IncludePreExchange2007);
    }
    else
    {
        $script:PublicFolderDatabasesInOrg = @(Get-PublicFolderDatabase);
    }
}

# Function that executes statistics cmdlet on different public folder databases
function GatherStatistics()
{   
    # Running Get-PublicFolderStatistics against each server identified via Get-PublicFolderDatabase cmdlet
    $databaseCount = $($script:PublicFolderDatabasesInOrg.Count);
    $index = 0;
    
    if ($script:ServerInfo.AdminDisplayVersion.Major -eq $script:Exchange12MajorVersion)
    {
        $getPublicFolderStatistics = "@(Get-PublicFolderStatistics ";
    }
    else
    {
        $getPublicFolderStatistics = "@(Get-PublicFolderStatistics -ResultSize:Unlimited ";
    }

    While ($index -lt $databaseCount)
    {
        $serverName = $($script:PublicFolderDatabasesInOrg[$index]).Server.Name;
        $getPublicFolderStatisticsCommand = $getPublicFolderStatistics + "-Server $serverName)";
        Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.RetrievingStatistics -f $serverName);
        $publicFolderStatistics = Invoke-Expression $getPublicFolderStatisticsCommand;
        Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.RetrievingStatisticsComplete -f $serverName,$($publicFolderStatistics.Count));
        RemoveDuplicatesFromFolderStatistics $publicFolderStatistics;
        Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.UniqueFoldersFound -f $($script:FolderStatistics.Count));
        $index++;
    }
}

# Function that removed redundant entries from output of Get-PublicFolderStatistics
function RemoveDuplicatesFromFolderStatistics()
{
    param($publicFolders);
    
    $index = 0;
    While ($index -lt $publicFolders.Count)
    {
        $publicFolderEntryId = $($publicFolders[$index].EntryId);
        $folderSizeFromStats = $($publicFolders[$index].TotalItemSize.Value.ToBytes());
        $folderPath = $($publicFolders[$index].FolderPath);
        $existingFolder = $script:FolderStatistics[$publicFolderEntryId];
        if (($existingFolder -eq $null) -or ($folderSizeFromStats -gt $existingFolder[0]))
        {
            $newFolder = @();
            $newFolder += $folderSizeFromStats;
            $newFolder += $folderPath;
            $script:FolderStatistics[$publicFolderEntryId] = $newFolder;
        }
       
        $index++;
    }    
}

# Function that creates folder objects in right way for exporting
function CreateFolderObjects()
{   
    $index = 1;
    foreach ($publicFolderEntryId in $script:FolderStatistics.Keys)
    {
        $existingFolder = $script:NonIpmSubtreeFolders[$publicFolderEntryId];
        $publicFolderIdentity = "";
        if ($existingFolder -ne $null)
        {
            $result = IsSkippableFolder($existingFolder);
            if (!$result)
            {
                $publicFolderIdentity = "\NON_IPM_SUBTREE\" + $script:FolderStatistics[$publicFolderEntryId][1];
                $folderSize = $script:FolderStatistics[$publicFolderEntryId][0];
            }
        }  
        else
        {
            $publicFolderIdentity = "\IPM_SUBTREE\" + $script:FolderStatistics[$publicFolderEntryId][1];
            $folderSize = $script:FolderStatistics[$publicFolderEntryId][0];
        }  
        
        if ($publicFolderIdentity -ne "")
        {
            if(($index%10000) -eq 0)
            {
                Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.ProcessedFolders -f $index);
            }
            
            # Create a folder object to be exported to a CSV
            $newFolderObject = New-Object PSObject -Property @{FolderName = $publicFolderIdentity; FolderSize = $folderSize}
            $retValue = $script:ExportFolders.Add($newFolderObject);
            $index++;
        }
    }   
}

####################################################################################################
# Script starts here
####################################################################################################

# Array of folder objects for exporting
$script:ExportFolders = $null;

# Hash table that contains the folder list
$script:FolderStatistics = @{};

# Hash table that contains the folder list
$script:NonIpmSubtreeFolders = @{};

# Folders that are skipped while computing statistics
$script:SkippedFolders = @("\", "\NON_IPM_SUBTREE", "\NON_IPM_SUBTREE\EFORMS REGISTRY");
$script:SkippedSubtree = @("\NON_IPM_SUBTREE\OFFLINE ADDRESS BOOK", "\NON_IPM_SUBTREE\SCHEDULE+ FREE BUSY");

Write-Host "[$($(Get-Date).ToString())]" $PublicFolderStatistics_LocalizedStrings.ProcessingNonIpmSubtree;
$nonIpmSubtreeFolderList = Get-PublicFolder "\NON_IPM_SUBTREE" -Server $PublicFolderServer -Recurse -ResultSize:Unlimited;
Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.ProcessingNonIpmSubtreeComplete -f $($nonIpmSubtreeFolderList.Count));
foreach ($nonIpmSubtreeFolder in $nonIpmSubtreeFolderList)
{
    $script:NonIpmSubtreeFolders.Add($nonIpmSubtreeFolder.EntryId, $nonIpmSubtreeFolder); 
}

# Determining the public folder database deployment in the organization
GetPublicFolderDatabases;

# Gathering statistics from each server
GatherStatistics;

# Allocating space here
$script:ExportFolders = New-Object System.Collections.ArrayList -ArgumentList ($script:FolderStatistics.Count + 3);

# Creating folder objects for exporting to a CSV
Write-Host "[$($(Get-Date).ToString())]" ($PublicFolderStatistics_LocalizedStrings.ExportStatistics -f $($script:FolderStatistics.Count));
CreateFolderObjects;

# Creating folder objects for all the skipped root folders
$newFolderObject = New-Object PSObject -Property @{FolderName = "\IPM_SUBTREE"; FolderSize = 0};
# Ignore the return value
$retValue = $script:ExportFolders.Add($newFolderObject);
$newFolderObject = New-Object PSObject -Property @{FolderName = "\NON_IPM_SUBTREE"; FolderSize = 0};
$retValue = $script:ExportFolders.Add($newFolderObject);
$newFolderObject = New-Object PSObject -Property @{FolderName = "\NON_IPM_SUBTREE\EFORMS REGISTRY"; FolderSize = 0};
$retValue = $script:ExportFolders.Add($newFolderObject);

# Export the folders to CSV file
Write-Host "[$($(Get-Date).ToString())]" $PublicFolderStatistics_LocalizedStrings.ExportToCSV;
$script:ExportFolders | Sort-Object -Property FolderName | Export-CSV -Path $ExportFile -Force -NoTypeInformation -Encoding "Unicode";

# SIG # Begin signature block
# MIIayQYJKoZIhvcNAQcCoIIaujCCGrYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBrKykpguKKaNdAr9r7W7luBu
# npugghV5MIIEujCCA6KgAwIBAgIKYQKOQgAAAAAAHzANBgkqhkiG9w0BAQUFADB3
# MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVk
# bW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSEwHwYDVQQDExhN
# aWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EwHhcNMTIwMTA5MjIyNTU4WhcNMTMwNDA5
# MjIyNTU4WjCBszELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAO
# BgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEN
# MAsGA1UECxMETU9QUjEnMCUGA1UECxMebkNpcGhlciBEU0UgRVNOOkY1MjgtMzc3
# Ny04QTc2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBTZXJ2aWNlMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAluyOR01UwlyVgNdOCz2/l0PD
# S+NgZxEvAU0M2NFGLxBA3gukUFISiAtDei0/7khuZseR5gPKbux5qWojm81ins1q
# pD/no0P/YkehtLpE+t9AwYVUfuigpyxDI5tSHzI19P6aVp+NY3d7MJ4KM4VyG8pK
# yMwlzdtdES7HsIzxj0NIRwW1eiAL5fPvwbr0s9jNOI/7Iao9Cm2FF9DK54YDwDOD
# tSXEzFqcxMPaYiVNUyUUYY/7G+Ds90fGgEXmNVMjNnfKsN2YKznAdTUP3YFMIT12
# MMWysGVzKUgn2MLSsIRHu3i61XQD3tdLGfdT3njahvdhiCYztEfGoFSIFSssdQID
# AQABo4IBCTCCAQUwHQYDVR0OBBYEFC/oRsho025PsiDQ3olO8UfuSMHyMB8GA1Ud
# IwQYMBaAFCM0+NlSRnAK7UD7dvuzK7DDNbMPMFQGA1UdHwRNMEswSaBHoEWGQ2h0
# dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY3Jvc29m
# dFRpbWVTdGFtcFBDQS5jcmwwWAYIKwYBBQUHAQEETDBKMEgGCCsGAQUFBzAChjxo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jvc29mdFRpbWVT
# dGFtcFBDQS5jcnQwEwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQEFBQAD
# ggEBAHP/fS6dzY2IK3x9414VceloYvAItkNWxFxKLWjY+UgRkfMRnIXsEtRUoHWp
# OKFZf3XuxvU02FSk4tDMfJerk3UwlwcdBFMsNn9/8UAeDJuA4hIKIDoxwAd1Z+D6
# NJzsiPtXHOVYYiCQRS9dRanIjrN8cm0QJ8VL2G+iqBKzbTUjZ/os2yUtuV2xHgXn
# Qyg+nAV2d/El3gVHGW3eSYWh2kpLCEYhNah1Nky3swiq37cr2b4qav3fNRfMPwzH
# 3QbPTpQkYyALLiSuX0NEEnpc3TfbpEWzkToSV33jR8Zm08+cRlb0TAex4Ayq1fbV
# PKLgtdT4HH4EVRBrGPSRzVGnlWUwggTsMIID1KADAgECAhMzAAAAsBGvCovQO5/d
# AAEAAACwMA0GCSqGSIb3DQEBBQUAMHkxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xIzAhBgNVBAMTGk1pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENB
# MB4XDTEzMDEyNDIyMzMzOVoXDTE0MDQyNDIyMzMzOVowgYMxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xDTALBgNVBAsTBE1PUFIxHjAcBgNVBAMT
# FU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAOivXKIgDfgofLwFe3+t7ut2rChTPzrbQH2zjjPmVz+lURU0VKXPtIup
# P6g34S1Q7TUWTu9NetsTdoiwLPBZXKnr4dcpdeQbhSeb8/gtnkE2KwtA+747urlc
# dZMWUkvKM8U3sPPrfqj1QRVcCGUdITfwLLoiCxCxEJ13IoWEfE+5G5Cw9aP+i/QM
# mk6g9ckKIeKq4wE2R/0vgmqBA/WpNdyUV537S9QOgts4jxL+49Z6dIhk4WLEJS4q
# rp0YHw4etsKvJLQOULzeHJNcSaZ5tbbbzvlweygBhLgqKc+/qQUF4eAPcU39rVwj
# gynrx8VKyOgnhNN+xkMLlQAFsU9lccUCAwEAAaOCAWAwggFcMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMB0GA1UdDgQWBBRZcaZaM03amAeA/4Qevof5cjJB8jBRBgNVHREE
# SjBIpEYwRDENMAsGA1UECxMETU9QUjEzMDEGA1UEBRMqMzE1OTUrNGZhZjBiNzEt
# YWQzNy00YWEzLWE2NzEtNzZiYzA1MjM0NGFkMB8GA1UdIwQYMBaAFMsR6MrStBZY
# Ack3LjMWFrlMmgofMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9z
# b2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY0NvZFNpZ1BDQV8wOC0zMS0yMDEw
# LmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljQ29kU2lnUENBXzA4LTMxLTIwMTAuY3J0
# MA0GCSqGSIb3DQEBBQUAA4IBAQAx124qElczgdWdxuv5OtRETQie7l7falu3ec8C
# nLx2aJ6QoZwLw3+ijPFNupU5+w3g4Zv0XSQPG42IFTp8263Os8lsujksRX0kEVQm
# MA0N/0fqAwfl5GZdLHudHakQ+hywdPJPaWueqSSE2u2WoN9zpO9qGqxLYp7xfMAU
# f0jNTbJE+fA8k21C2Oh85hegm2hoCSj5ApfvEQO6Z1Ktwemzc6bSY81K4j7k8079
# /6HguwITO10g3lU/o66QQDE4dSheBKlGbeb1enlAvR/N6EXVruJdPvV1x+ZmY2DM
# 1ZqEh40kMPfvNNBjHbFCZ0oOS786Du+2lTqnOOQlkgimiGaCMIIFvDCCA6SgAwIB
# AgIKYTMmGgAAAAAAMTANBgkqhkiG9w0BAQUFADBfMRMwEQYKCZImiZPyLGQBGRYD
# Y29tMRkwFwYKCZImiZPyLGQBGRYJbWljcm9zb2Z0MS0wKwYDVQQDEyRNaWNyb3Nv
# ZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwHhcNMTAwODMxMjIxOTMyWhcN
# MjAwODMxMjIyOTMyWjB5MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3Rv
# bjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSMwIQYDVQQDExpNaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQTCCASIwDQYJ
# KoZIhvcNAQEBBQADggEPADCCAQoCggEBALJyWVwZMGS/HZpgICBCmXZTbD4b1m/M
# y/Hqa/6XFhDg3zp0gxq3L6Ay7P/ewkJOI9VyANs1VwqJyq4gSfTwaKxNS42lvXlL
# cZtHB9r9Jd+ddYjPqnNEf9eB2/O98jakyVxF3K+tPeAoaJcap6Vyc1bxF5Tk/TWU
# cqDWdl8ed0WDhTgW0HNbBbpnUo2lsmkv2hkL/pJ0KeJ2L1TdFDBZ+NKNYv3LyV9G
# MVC5JxPkQDDPcikQKCLHN049oDI9kM2hOAaFXE5WgigqBTK3S9dPY+fSLWLxRT3n
# rAgA9kahntFbjCZT6HqqSvJGzzc8OJ60d1ylF56NyxGPVjzBrAlfA9MCAwEAAaOC
# AV4wggFaMA8GA1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFMsR6MrStBZYAck3LjMW
# FrlMmgofMAsGA1UdDwQEAwIBhjASBgkrBgEEAYI3FQEEBQIDAQABMCMGCSsGAQQB
# gjcVAgQWBBT90TFO0yaKleGYYDuoMW+mPLzYLTAZBgkrBgEEAYI3FAIEDB4KAFMA
# dQBiAEMAQTAfBgNVHSMEGDAWgBQOrIJgQFYnl+UlE/wq4QpTlVnkpDBQBgNVHR8E
# STBHMEWgQ6BBhj9odHRwOi8vY3JsLm1pY3Jvc29mdC5jb20vcGtpL2NybC9wcm9k
# dWN0cy9taWNyb3NvZnRyb290Y2VydC5jcmwwVAYIKwYBBQUHAQEESDBGMEQGCCsG
# AQUFBzAChjhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY3Jv
# c29mdFJvb3RDZXJ0LmNydDANBgkqhkiG9w0BAQUFAAOCAgEAWTk+fyZGr+tvQLEy
# tWrrDi9uqEn361917Uw7LddDrQv+y+ktMaMjzHxQmIAhXaw9L0y6oqhWnONwu7i0
# +Hm1SXL3PupBf8rhDBdpy6WcIC36C1DEVs0t40rSvHDnqA2iA6VW4LiKS1fylUKc
# 8fPv7uOGHzQ8uFaa8FMjhSqkghyT4pQHHfLiTviMocroE6WRTsgb0o9ylSpxbZsa
# +BzwU9ZnzCL/XB3Nooy9J7J5Y1ZEolHN+emjWFbdmwJFRC9f9Nqu1IIybvyklRPk
# 62nnqaIsvsgrEA5ljpnb9aL6EiYJZTiU8XofSrvR4Vbo0HiWGFzJNRZf3ZMdSY4t
# vq00RBzuEBUaAF3dNVshzpjHCe6FDoxPbQ4TTj18KUicctHzbMrB7HCjV5JXfZSN
# oBtIA1r3z6NnCnSlNu0tLxfI5nI3EvRvsTxngvlSso0zFmUeDordEN5k9G/ORtTT
# F+l5xAS00/ss3x+KnqwK+xMnQK3k+eGpf0a7B2BHZWBATrBC7E7ts3Z52Ao0CW0c
# gDEf4g5U3eWh++VHEK1kmP9QFi58vwUheuKVQSdpw5OPlcmN2Jshrg1cnPCiroZo
# gwxqLbt2awAdlq3yFnv2FoMkuYjPaqhHMS+a3ONxPdcAfmJH0c6IybgY+g5yjcGj
# Pa8CQGr/aZuW4hCoELQ3UAjWwz0wggYHMIID76ADAgECAgphFmg0AAAAAAAcMA0G
# CSqGSIb3DQEBBQUAMF8xEzARBgoJkiaJk/IsZAEZFgNjb20xGTAXBgoJkiaJk/Is
# ZAEZFgltaWNyb3NvZnQxLTArBgNVBAMTJE1pY3Jvc29mdCBSb290IENlcnRpZmlj
# YXRlIEF1dGhvcml0eTAeFw0wNzA0MDMxMjUzMDlaFw0yMTA0MDMxMzAzMDlaMHcx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xITAfBgNVBAMTGE1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCC
# AQoCggEBAJ+hbLHf20iSKnxrLhnhveLjxZlRI1Ctzt0YTiQP7tGn0UytdDAgEesH
# 1VSVFUmUG0KSrphcMCbaAGvoe73siQcP9w4EmPCJzB/LMySHnfL0Zxws/HvniB3q
# 506jocEjU8qN+kXPCdBer9CwQgSi+aZsk2fXKNxGU7CG0OUoRi4nrIZPVVIM5AMs
# +2qQkDBuh/NZMJ36ftaXs+ghl3740hPzCLdTbVK0RZCfSABKR2YRJylmqJfk0waB
# SqL5hKcRRxQJgp+E7VV4/gGaHVAIhQAQMEbtt94jRrvELVSfrx54QTF3zJvfO4OT
# oWECtR0Nsfz3m7IBziJLVP/5BcPCIAsCAwEAAaOCAaswggGnMA8GA1UdEwEB/wQF
# MAMBAf8wHQYDVR0OBBYEFCM0+NlSRnAK7UD7dvuzK7DDNbMPMAsGA1UdDwQEAwIB
# hjAQBgkrBgEEAYI3FQEEAwIBADCBmAYDVR0jBIGQMIGNgBQOrIJgQFYnl+UlE/wq
# 4QpTlVnkpKFjpGEwXzETMBEGCgmSJomT8ixkARkWA2NvbTEZMBcGCgmSJomT8ixk
# ARkWCW1pY3Jvc29mdDEtMCsGA1UEAxMkTWljcm9zb2Z0IFJvb3QgQ2VydGlmaWNh
# dGUgQXV0aG9yaXR5ghB5rRahSqClrUxzWPQHEy5lMFAGA1UdHwRJMEcwRaBDoEGG
# P2h0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL21pY3Jv
# c29mdHJvb3RjZXJ0LmNybDBUBggrBgEFBQcBAQRIMEYwRAYIKwYBBQUHMAKGOGh0
# dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljcm9zb2Z0Um9vdENl
# cnQuY3J0MBMGA1UdJQQMMAoGCCsGAQUFBwMIMA0GCSqGSIb3DQEBBQUAA4ICAQAQ
# l4rDXANENt3ptK132855UU0BsS50cVttDBOrzr57j7gu1BKijG1iuFcCy04gE1CZ
# 3XpA4le7r1iaHOEdAYasu3jyi9DsOwHu4r6PCgXIjUji8FMV3U+rkuTnjWrVgMHm
# lPIGL4UD6ZEqJCJw+/b85HiZLg33B+JwvBhOnY5rCnKVuKE5nGctxVEO6mJcPxaY
# iyA/4gcaMvnMMUp2MT0rcgvI6nA9/4UKE9/CCmGO8Ne4F+tOi3/FNSteo7/rvH0L
# QnvUU3Ih7jDKu3hlXFsBFwoUDtLaFJj1PLlmWLMtL+f5hYbMUVbonXCUbKw5TNT2
# eb+qGHpiKe+imyk0BncaYsk9Hm0fgvALxyy7z0Oz5fnsfbXjpKh0NbhOxXEjEiZ2
# CzxSjHFaRkMUvLOzsE1nyJ9C/4B5IYCeFTBm6EISXhrIniIh0EPpK+m79EjMLNTY
# MoBMJipIJF9a6lbvpt6Znco6b72BJ3QGEe52Ib+bgsEnVLaxaj2JoXZhtG6hE6a/
# qkfwEm/9ijJssv7fUciMI8lmvZ0dhxJkAj0tr1mPuOQh5bWwymO0eFQF1EEuUKyU
# sKV4q7OglnUa2ZKHE3UiLzKoCG6gW4wlv6DvhMoh1useT8ma7kng9wFlb4kLfchp
# yOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBLowggS2AgEBMIGQMHkx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAAAsBGvCovQO5/dAAEAAACwMAkG
# BSsOAwIaBQCggdwwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFADtiHn7Mz26yy0X
# FMOniH8RSKRdMHwGCisGAQQBgjcCAQwxbjBsoESAQgBFAHgAcABvAHIAdAAtAFAA
# dQBiAGwAaQBjAEYAbwBsAGQAZQByAFMAdABhAHQAaQBzAHQAaQBjAHMALgBwAHMA
# MaEkgCJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vZXhjaGFuZ2UgMA0GCSqGSIb3
# DQEBAQUABIIBAEYBOhA3hwlG0FaR1uABBI5GTEaszXNvWZ90MzdOOk/5pVFIwWQ/
# BH+B1fBh46Fk8mD5tAhGVkjkyzQN8+ZBu5RaF9qFvUtsQum0+Az6KElOYqmpONc0
# pUDrCgzf28ZdoZ8OnXQV4Zi6snnAwkFaDTc/luKD7W2gAVklGO7W76W91LymdnmR
# 2yTH8G2T6nYSXA6Ed4Xoa2nKDJsi+a+/S7Zc/ao9dHbTQswJNHgpfjljaxfizFgp
# 3muDdYzImOE00gg/q08ACSPTGMZqlVUjqLOA55yfHTP+3cWM2VrnLdwfVHwNl+HM
# 6ZjtY7et0+mX0yFQsDmE4jppc79snqq2JXihggIfMIICGwYJKoZIhvcNAQkGMYIC
# DDCCAggCAQEwgYUwdzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBAgphAo5CAAAAAAAf
# MAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3
# DQEJBTEPFw0xMzA0MDQwNjExMjhaMCMGCSqGSIb3DQEJBDEWBBTNrueJyRe/455M
# GFK+jV+ecgXndzANBgkqhkiG9w0BAQUFAASCAQBkqUDwfX9uaMMmBF4aglTyFxx7
# WnfKcvdZfBWh3JVydb8SDVHxNhJR0opjh009tdiwrD7p25ZS5q9jrFx05w53DrKh
# O8z3qnq+0Hu+SX+n+NKbNq5HucmPh8IG/EuPQzDySonuTtbA4vFFgbK6XbL01zIJ
# M/zTiR85hjgknXLK/gv/wO/wKOe74xqykjSl4cIpNnObo8zSmSViGREK6aeqLrzE
# KLQHtmW5VcTH9NR+6PIcYA9g/eJHjVrW5rzrWUJm8UtFmtaf5a2VzwQFI33w6Es2
# hpVTY9+jPAIFErb2d7mmrQn0X9UISsWaqrAEbd9RAWlCXWzkgLKQsv0AxF4E
# SIG # End signature block
