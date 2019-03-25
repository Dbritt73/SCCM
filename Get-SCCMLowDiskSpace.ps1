Function Get-SCCMLowDiskSpace {
    <#
    .SYNOPSIS
    Get a list of computers from the SCCM database who have less than the specified percent of free space on their disk
    drives.

    .DESCRIPTION
    Get-SCCMLowDiskSpace utilizes the built-in SCCM report of low disk space base dont he specified percentage. Report
    executed via Invoke-RestMethod.

    .PARAMETER CollectionID
    ID of collection in SCCM to query

    .PARAMETER ReportUri
    The URI of the low disk report from SCCMs reporting server. This needs to be modified to accept variables.
    '&rs:format=xml&' is left with a '&' at the end to concatenate the collection ID and percent free parameters

    .PARAMETER PercentFree
    Specified percent free to query against

    .EXAMPLE
    Get-SCCMLowDiskSpace -CollectionID 'SITE000A3' -PercentFree 25 -ReportUri $reportUri

    .INPUTS
    [String[]]CollectionID

    [int]PercentFree

    [String]ReportUri

    .OUTPUTS
    Report.SCCM.LowDiskSpace
  #>
    [CmdletBinding()]
    Param (

        [Parameter( Mandatory=$true,
                    HelpMessage='ID of Collection in SCCM',
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [String[]]$CollectionID,

        [int]$PercentFree = 25,

        [String]$ReportUri = 'http://SCCM_DB_SERVER/ReportServer/Pages/ReportViewer.aspx?%2fConfigMgr_SITE%2fHardware+-+Disk%2fComputers+with+low+free+disk+space+(less+than+specified+%25+free)&rs:format=xml&'

    )

        Begin {}

        Process {

            Try {

                Foreach ($ID in $CollectionID) {

                    $ReportServerUri = "$ReportUri" + "CollID=$ID" + '&' + "variable=$PercentFree"

                    Write-Debug 'Test ReportServerURI'

                    $splat = @{

                        'Uri'                   = $ReportServerUri
                        'UseDefaultCredentials' = $true
                        'ErrorAction'           = 'Stop'

                    }

                    $Response = invoke-RestMethod @splat

                    #Regex required to scrub the XML string of any non-standard ASCII chars
                    [xml]$XMLReport = $Response -replace '[^ -x7e]',''

                    foreach ($Result in $XMLReport.Report.Table0.Detail_Collection.Detail) {

                        $Properties = [Ordered]@{

                            'ComputerName' = $Result.Details_Table0_Name
                            'DriveID'      = $Result.Details_Table0_DeviceID0
                            'FreeSpace'    = $Result.Details_Table0_FreeSpace0
                            'DiskSize'     = $Result.Details_Table0_Size0
                            'PercentFree'  = $Result.Details_Table0_C0

                        }

                        $Object = New-object -typename PSObject -Property $Properties
                        $Object.PSObject.TypeNames.Insert(0,'Report.SCCMLowDiskSpace')
                        Write-Output -InputObject $Object

                    }

                }

            } Catch {

                # get error record
                [Management.Automation.ErrorRecord]$e = $_

                # retrieve information about runtime error
                $info = [PSCustomObject]@{

                    Exception = $e.Exception.Message
                    Reason    = $e.CategoryInfo.Reason
                    Target    = $e.CategoryInfo.TargetName
                    Script    = $e.InvocationInfo.ScriptName
                    Line      = $e.InvocationInfo.ScriptLineNumber
                    Column    = $e.InvocationInfo.OffsetInLine

                }

                # output information. Post-process collected info, and log info (optional)
                $info

            }

        }

    End {}

}
