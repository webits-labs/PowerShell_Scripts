# .SYNOPSIS
# PublicFolderToMailboxMapGenerator.ps1
#    Generates a CSV file that contains the mapping of public folder branch to mailbox
#
# .DESCRIPTION
#
# Copyright (c) 2011 Microsoft Corporation. All rights reserved.
#
# THIS CODE IS MADE AVAILABLE AS IS, WITHOUT WARRANTY OF ANY KIND. THE ENTIRE RISK
# OF THE USE OR THE RESULTS FROM THE USE OF THIS CODE REMAINS WITH THE USER.
param(
    # Mailbox size 
    [Parameter(
	Mandatory=$true,
        HelpMessage = "Size (in Bytes) of any one of the Public folder mailboxes in destination. (E.g. For 1GB enter 1 followed by nine 0's)")]
    [long] $MailboxSize,

    # File to import from
    [Parameter(
        Mandatory=$true,
        HelpMessage = "This is the path to a CSV formatted file that contains the folder names and their sizes.")]
    [ValidateNotNull()]
    [string] $ImportFile,

    # File to export to
    [Parameter(
        Mandatory=$true,
        HelpMessage = "Full path of the output file to be generated. If only filename is specified, then the output file will be generated in the current directory.")]
    [ValidateNotNull()]
    [string] $ExportFile
    )

# Folder Node's member indices
# This is an optimization since creating and storing objects as PSObject types
# is an expensive operation in powershell
# CLASSNAME_MEMBERNAME
$script:FOLDERNODE_PATH = 0;
$script:FOLDERNODE_MAILBOX = 1;
$script:FOLDERNODE_TOTALITEMSIZE = 2;
$script:FOLDERNODE_AGGREGATETOTALITEMSIZE = 3;
$script:FOLDERNODE_PARENT = 4;
$script:FOLDERNODE_CHILDREN = 5;
$script:MAILBOX_NAME = 0;
$script:MAILBOX_UNUSEDSIZE = 1;
$script:MAILBOX_ISINHERITED = 2;

$script:ROOT = @("`\", $null, 0, 0, $null, @{});

#load hashtable of localized string
Import-LocalizedData -BindingVariable MapGenerator_LocalizedStrings -FileName PublicFolderToMailboxMapGenerator.strings.psd1

# Function that constructs the entire tree based on the folderpath
# As and when it constructs it computes its aggregate folder size that included itself
function LoadFolderHierarchy() 
{
    foreach ($folder in $script:PublicFolders)
    {
        $folderSize = [long]$folder.FolderSize;
        if ($folderSize -gt $MailboxSize)
        {
            Write-Host "[$($(Get-Date).ToString())]" ($MapGenerator_LocalizedStrings.MammothFolder -f $folder, $folderSize, $MailboxSize);
            return $false;
        }

        # Start from root
        $parent = $script:ROOT;
        foreach ($familyMember in $folder.FolderName.Split('\', [System.StringSplitOptions]::RemoveEmptyEntries))
        {
            # Try to locate the appropriate subfolder
            $child = $parent[$script:FOLDERNODE_CHILDREN][$familyMember];
            if ($child -eq $null)
            {
                # Create and add subfolder to parent's children
                $child = @($folder.FolderName, $null, $folderSize, $folderSize, $parent, @{});
                $parent[$script:FOLDERNODE_CHILDREN][$familyMember] = $child;
            }

            # Add child's individual size to parent's aggregate size
            $parent[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE] += $folderSize;
            $parent = $child;
        }
    }

    return $true;
}

# Function that assigns content mailboxes to public folders
# $node: Root node to be assigned to a mailbox
# $mailboxName: If not $null, we will attempt to accomodate folder in this mailbox
function AllocateMailbox()
{
    param ($node, $mailboxName)

    if ($mailboxName -ne $null)
    {
        # Since a mailbox was supplied by the caller, we should first attempt to use it
        if ($node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE] -le $script:PublicFolderMailboxes[$mailboxName][$script:MAILBOX_UNUSEDSIZE])
        {
            # Node's contents (including branch) can be completely fit into specified mailbox
            # Assign the folder to mailbox and update mailbox's remaining size
            $node[$script:FOLDERNODE_MAILBOX] = $mailboxName;
            $script:PublicFolderMailboxes[$mailboxName][$script:MAILBOX_UNUSEDSIZE] -= $node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE];
            if ($script:PublicFolderMailboxes[$mailboxName][$script:MAILBOX_ISINHERITED] -eq $false)
            {
                # This mailbox was not parent's content mailbox, but was created by a sibling
                $script:AssignedFolders += New-Object PSObject -Property @{FolderPath = $node[$script:FOLDERNODE_PATH]; TargetMailbox = $node[$script:FOLDERNODE_MAILBOX]};
            }

            return $mailboxName;
        }
    }

    $newMailboxName = "Mailbox" + ($script:NEXT_MAILBOX++);
    $script:PublicFolderMailboxes[$newMailboxName] = @($newMailboxName, $MailboxSize, $false);

    $node[$script:FOLDERNODE_MAILBOX] = $newMailboxName;
    $script:AssignedFolders += New-Object PSObject -Property @{FolderPath = $node[$script:FOLDERNODE_PATH]; TargetMailbox = $node[$script:FOLDERNODE_MAILBOX]};
    if ($node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE] -le $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_UNUSEDSIZE])
    {
        # Node's contents (including branch) can be completely fit into the newly created mailbox
        # Assign the folder to mailbox and update mailbox's remaining size
        $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_UNUSEDSIZE] -= $node[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE];
        return $newMailboxName;
    }
    else
    {
        # Since node's contents (including branch) could not be fitted into the newly created mailbox,
        # put it's individual contents into the mailbox
        $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_UNUSEDSIZE] -= $node[$script:FOLDERNODE_TOTALITEMSIZE];
    }

    $subFolders = @(@($node[$script:FOLDERNODE_CHILDREN].Values) | Sort-Object @{Expression={$_[$script:FOLDERNODE_AGGREGATETOTALITEMSIZE]}; Ascending=$true});
    $script:PublicFolderMailboxes[$newMailboxName][$script:MAILBOX_ISINHERITED] = $true;
    foreach ($subFolder in $subFolders)
    {
        $newMailboxName = AllocateMailbox $subFolder $newMailboxName;
    }

    return $null;
}

# Function to check if further optimization can be done on the output generated
function TryAccomodateSubFoldersWithParent()
{
    $numAssignedFolders = $script:AssignedFolders.Count;
    for ($index = $numAssignedFolders - 1 ; $index -ge 0 ; $index--)
    {
        $assignedFolder = $script:AssignedFolders[$index];

        # Locate folder's parent
        for ($jindex = $index - 1 ; $jindex -ge 0 ; $jindex--)
        {
            if ($assignedFolder.FolderPath.StartsWith($script:AssignedFolders[$jindex].FolderPath))
            {
                # Found first ancestor
                $ancestor = $script:AssignedFolders[$jindex];
                $usedMailboxSize = $MailboxSize - $script:PublicFolderMailboxes[$assignedFolder.TargetMailbox][$script:MAILBOX_UNUSEDSIZE];
                if ($usedMailboxSize -le $script:PublicFolderMailboxes[$ancestor.TargetMailbox][$script:MAILBOX_UNUSEDSIZE])
                {
					# If the current mailbox can fit into its ancestor mailbox, add the former's contents to ancestor
					# and remove the mailbox assigned to it.Update the ancestor mailbox's size accordingly
                    $script:PublicFolderMailboxes[$assignedFolder.TargetMailbox][$script:MAILBOX_UNUSEDSIZE] = $MailboxSize;
                    $script:PublicFolderMailboxes[$ancestor.TargetMailbox][$script:MAILBOX_UNUSEDSIZE] -= $usedMailboxSize;
                    $assignedFolder.TargetMailbox = $null;
                }

                break;
            }
        }
    }
    
    if ($script:AssignedFolders.Count -gt 1)
    {
        $script:AssignedFolders = $script:AssignedFolders | where {$_.TargetMailbox -ne $null};
    }
}

# Parse the CSV file
Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.ProcessFolder;
$script:PublicFolders = Import-CSV $ImportFile;

# Check if there is atleast one public folder in existence
if (!$script:PublicFolders)
{
    Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.ProcessEmptyFile;
    return;
}

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.LoadFolderHierarchy;
$loadHierarchy = LoadFolderHierarchy;
if ($loadHierarchy -ne $true)
{
    Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.CannotLoadFolders;
    return;
}

# Contains the list of instantiated public folder maiboxes
# Key: mailbox name, Value: unused mailbox size
$script:PublicFolderMailboxes = @{};
$script:AssignedFolders = @();
$script:NEXT_MAILBOX = 1;

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.AllocateFolders;
$ignoreReturnValue = AllocateMailbox $script:ROOT $null;

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.AccomodateFolders;
TryAccomodateSubFoldersWithParent;

Write-Host "[$($(Get-Date).ToString())]" $MapGenerator_LocalizedStrings.ExportFolderMap;
$script:NEXT_MAILBOX = 2;
$previous = $script:AssignedFolders[0];
$previousOriginalMailboxName = $script:AssignedFolders[0].TargetMailbox;
$numAssignedFolders = $script:AssignedFolders.Count;

# Prepare the folder object that is to be finally exported
# During the process, rename the mailbox assigned to it.  
# This is done to prevent any gap in generated mailbox name sequence at the end of the execution of TryAccomodateSubFoldersWithParent function
for ($index = 0 ; $index -lt $numAssignedFolders ; $index++)
{
    $current = $script:AssignedFolders[$index];
    $currentMailboxName = $current.TargetMailbox;
    if ($previousOriginalMailboxName -ne $currentMailboxName)
    {
        $current.TargetMailbox = "Mailbox" + ($script:NEXT_MAILBOX++);
    }
    else
    {
        $current.TargetMailbox = $previous.TargetMailbox;
    }

    $previous = $current;
    $previousOriginalMailboxName = $currentMailboxName;
}

# Export the folder mapping to CSV file
$script:AssignedFolders | Export-CSV -Path $ExportFile -Force -NoTypeInformation -Encoding "Unicode";

# SIG # Begin signature block
# MIIa0gYJKoZIhvcNAQcCoIIawzCCGr8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUx8+Ur193aqIoAWUQdXnknW4L
# GFagghV5MIIEujCCA6KgAwIBAgIKYQKOQgAAAAAAHzANBgkqhkiG9w0BAQUFADB3
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
# yOZu6qeXzjEp/w7FW1zYTRuh2Povnj8uVRZryROj/TGCBMMwggS/AgEBMIGQMHkx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xIzAhBgNVBAMTGk1p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBAhMzAAAAsBGvCovQO5/dAAEAAACwMAkG
# BSsOAwIaBQCggeUwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGC
# NwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFIEIJHT98j+qyd7X
# QUC4S3CozttwMIGEBgorBgEEAYI3AgEMMXYwdKBMgEoAUAB1AGIAbABpAGMARgBv
# AGwAZABlAHIAVABvAE0AYQBpAGwAYgBvAHgATQBhAHAARwBlAG4AZQByAGEAdABv
# AHIALgBwAHMAMaEkgCJodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vZXhjaGFuZ2Ug
# MA0GCSqGSIb3DQEBAQUABIIBAGTKenr9l/cc5qgOEIZ5WghOdMlhKX4pA5afQs9s
# ZEh5cAGq0j12XV8dtbs7mn74nAgQCt2mNzuHPMrKALHEzH7oADN/XgkHmm2AW+L0
# 6Rn8Ygl5uUhJIHeIPLgh55ozqAmaepMuRfp3+s6WZNLY1NUCJtmtipisn61xH6lW
# 1nD2dxpw0p7W2bQn4KTFXHqi29T28JTTb+CwYPuwxwMpLuODggix0NUY7iWPj4PS
# QkAGHaj1300KMMhvx8dKYncypLDg3nwyjg/RrHztkwtpevbBm1Be/OHyFcQkAnJ/
# F9RjaH30Mgwimc3JeEOgY/eIXiVfmv4ROKZNI5urPhF+khyhggIfMIICGwYJKoZI
# hvcNAQkGMYICDDCCAggCAQEwgYUwdzELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEhMB8GA1UEAxMYTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBAgph
# Ao5CAAAAAAAfMAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcB
# MBwGCSqGSIb3DQEJBTEPFw0xMzA0MDQwNjExMzNaMCMGCSqGSIb3DQEJBDEWBBTr
# A8YczWmCRbk9nyiI53CkZFkE5zANBgkqhkiG9w0BAQUFAASCAQAI58EllCVbvn2s
# 3xJOFHV1LII+/V7NuQhWEIucNR0cA997FJKPAhl0Lr5hX+9g9YPdv9yxDrQyoGfl
# 5JeqXONRW4Q/hN6mhzfaZvcoN5RKtjQIEMVf5pwvT287oiKyrMQJCld2PV6K+ocy
# 9vbjRBSesaBvWG6A60m1i6Gn5SVz6KuRRFRoeEjmY/bsBSYlbWZPgXss67pKFHHr
# 8CgexWjtwiu6hn+srKOmOadGQDTQreEt2ZTb+DSSm4BF0MLIkOyx71T8sw3TP8dE
# YRVNZyBHl/u8q3m/dleBJeGa14ebnraDTzIEP2bGpcTzY3llllyq/eEBYUjFpHYY
# 4CL0m4dq
# SIG # End signature block
