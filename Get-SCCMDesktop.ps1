function Get-SCCMDesktop {
    <#
    .SYNOPSIS
    Get computer information from SCCM

    .DESCRIPTION
    Get-SCCMDesktop utilizes the ComputerInformation report built in to SCCM to gather pre-defined information about a
    computer. Reports are generated using Sql Server Reporting Services (SSRS), which is intpereted by Get-SCCMDesktop
    using invoke-webrequest and parsing the resultant XML structure for the properties of the report.

    .EXAMPLE
    Get-SCCMDesktop 'SERVER1'

    Example getting information of one computer

    .EXAMPLE
    Get-SCCMDesktop 'SERVER1', 'SERVER2'

    Example getting information on multiple computers

    .EXAMPLE
    (get-content .\computers.txt) | Get-SCCMDesktop

    Example getting information on multiple computers using the pipeline

    .NOTES
    *First foray into leveraging PowerShell with SCCM reporting.
    #>

    [CmdletBinding()]
    Param (

        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [String[]]$ComputerName,

        [String]$ReportUri = "http://SCCM-Database/ReportServer?%2fConfigMgr_SITECODE%2fHardware+-+General%2fComputer+information+for+a+specific+computer&rs:format=xml&variable="

    )

    Begin {}

    Process {

        Try {

            Foreach ($Computer in $ComputerName) {

                $ReportServerUri = $ReportUri + $Computer
                $iwr = invoke-webrequest -Uri $ReportServerUri -UseDefaultCredential

                #Regex required to scrub the XML string of any non-standard ASCII chars
                [xml]$XMLReport = $iwr.content -replace "[^ -x7e]",""

                $Properties = @{

                    'ComputerName' = $XMLReport.Report.Table0.Detail_Collection.Detail.Details_Table0_Netbios_Name0;
                    'UserName' = $XMLReport.Report.Table0.Detail_Collection.Detail.Details_Table0_User_Name0;
                    'Model' = $XMLReport.Report.Table0.Detail_Collection.Detail.Details_Table0_Model0;
                    'CPU' = $XMLReport.Report.Table0.Detail_Collection.Detail.Details_Table0_Name0;
                    'IPAddresses' = $XMLReport.Report.Table0.Detail_Collection.Detail.Details_Table0_IP_Addresses0;
                    'OS' = $XMLReport.Report.Table0.Detail_Collection.Detail.Details_Table0_C0

                }

                $Object = New-object -typename PSObject -Property $Properties
                $Object.PSObject.TypeNames.Insert(0,'SCCM.Desktop')
                Write-Output $Object

            }

        } Catch {

            Write-Warning -Message "$ComputerName : $Error[0].Message"

        }
    }

    End {}

}
