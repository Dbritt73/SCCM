Function Get-SCCMNetworkAdapter {
    [CmdletBinding()]
    Param (

        [Parameter( Mandatory=$true,
                    ValueFromPipeline=$True,
                    ValueFromPipelineByPropertyName=$true,
                    Position=0)]
        [String[]]$ComputerName,

        [String]$ReportUri = 'http://Report-Server_URI-Goes_HERE%2fHardware+-+Network+Adapter%2fNetwork+adapter+information+for+a+specific+computer&rs:format=xml&variable='

    )

    Begin {}

    Process {

        Try {

            Foreach ($Computer in $ComputerName) {

                $ReportServerUri = $ReportUri + $Computer
                $Response = invoke-RestMethod -Uri $ReportServerUri -UseDefaultCredential

                #Regex required to scrub the XML string of any non-standard ASCII chars
                [xml]$XMLReport = $Response -replace "[^ -x7e]",""

                foreach ($NetAdapter in $XMLReport.Report.Table0.Detail_Collection.Detail) {

                    $Properties = [Ordered]@{

                        'ComputerName' = $NetAdapter.Details_Table0_Netbios_Name0
                        'Description'  = $NetAdapter.Details_Table0_Description0
                        'Manufacturer' = $NetAdapter.Details_Table0_Manufacturer0
                        'AdapterType'  = $NetAdapter.Details_Table0_AdapterType0
                        'MACAddress'   = $NetAdapter.Details_Table0_MACAddress0
                        'IPAddress'    = $NetAdapter.Details_Table0_IPAddress0
                        'IPSubnet'     = $NetAdapter.Details_Table0_IPSubnet0

                    }

                    $Object = New-object -typename PSObject -Property $Properties
                    $Object.PSObject.TypeNames.Insert(0,'SCCM.Desktop')
                    Write-Output $Object

                }

            }

        } Catch {}

    }

    End {}

}
