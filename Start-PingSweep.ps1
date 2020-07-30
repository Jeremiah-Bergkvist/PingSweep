<#
.SYNOPSIS
    This function performs a pingsweep on a network.

.DESCRIPTION
    There are several parameters that can be defined for this function that
    improve its features compared to that of Test-Connection.

.PARAMETER IPAddress
    Used to store a dotted deciaml IPv4 address.

.PARAMETER CIDR
    Refers to the CIDR notation of the network to be scanned.

.PARAMETER Timeout
    The delay in MS before the ICMP packet is considered unresponsive.

.PARAMETER TTL
    Allows a user to specify the inital TTL of the outbout ICMP packet.

.PARAMETER DontFragment
    Controls the Do Not Fragment flag on the outbound ICMP packet.

.PARAMETER Message
    Allows a custom payload to be sent along with the outbound ICMP packet.

.PARAMETER AliveOnly
    Return only hosts that responded.

.EXAMPLE
    This example demonstrates how to ping every IP address between 10.0.0.24
    and 10.0.0.31
    Start-PingSweep -IPAddress "10.0.0.29" -CIDR 29

.NOTES
    Author: Jeremiah Bergkvist
    Last Edit: 2020-02-14
    Version 1.0 - initial release of Start-PingSweep
    Reference: https://stackoverflow.com/a/58218274
#>
function Start-PingSweep{
    Param(
        [Parameter(Mandatory = $true,
        HelpMessage = 'IPv4 Address String')]
        [string]$IPAddress,

        [Parameter(Mandatory = $true,
        HelpMessage = 'CIDR')]
        [ValidateRange(8,32)]
        [Int]$CIDR,

        [Parameter(HelpMessage = 'Timeout in MS')]
        [Int]$Timeout = 250,

        [Parameter(HelpMessage = 'Initial TTL')]
        [Int]$TTL = 128,

        [Parameter(HelpMessage = "Don't Fragment Packets")]
        [switch]$DontFragment = $false,

        [Parameter(HelpMessage = "ICMP Payload Message")]
        [string]$Message = "",

        [Parameter(HelpMessage = "Return only hosts that responded")]
        [switch]$AliveOnly = $false
    )
    $Octets = $IPAddress.Split(".")
    $ErrorFound = $false
    if($Octets.Length -ne 4){
        $ErrorFound = $true
    }
    foreach($Octet in $Octets){
        if($Octet -notmatch '\d+'){
            Write-Error "Octet $octet must be a number."
            $ErrorFound = $true
        }
        if([int]$Octet -lt 0 -or [int]$Octet -gt 255) {
            Write-Error "Octet $octet is out of range."
            $ErrorFound = $true
        }
    }
    if($ErrorFound){
        return
    }

    # Ping Options
    $options = new-object system.net.networkinformation.pingoptions
    $options.TTL = $TTL
    $options.DontFragment = $DontFragment
    $buffer=([system.text.encoding]::ASCII).getbytes($Message)

    # Convert IP to integer
    $o1 = [int]$Octets[0]
    $o2 = [int]$Octets[1]
    $o3 = [int]$Octets[2]
    $o4 = [int]$Octets[3]
    $mask = 0xFFFFFFFF -shl (32 - $CIDR)
    $ip = $(( ($o2 -shl 16) + ($o3 -shl 8) + $o4 ))

    # Determine first and last IP in range
    $ipstart=$(( $ip -band $mask ))
    $ipend=$(( ($ipstart -bor (-bnot $mask)) -band 0x7FFFFFFF ))

    $Results = @()
    foreach($ip in $ipstart..$ipend) {
        $o2=$(( ($ip -band 0xFF0000) -shr 16 ))
        $o3=$(( ($ip -band 0xFF00) -shr 8 ))
        $o4=$(( $ip -band 0x00FF ))

        $IPStr = "$o1.$o2.$o3.$o4"
        $Complete = 100 - [math]::Floor((($ipend-$ip)/($ipend-$ipstart)*100))
        Write-Progress -Activity "Scanning: $IPStr" -PercentComplete $Complete

        $ErrorMessage = ""
        $Ping = new-object system.net.networkinformation.ping
        try{
            $Reply = $Ping.Send($IPStr,$timeout,$buffer,$options)	
        }
        catch{
            $ErrorMessage = $_.Exception.Message
        }

        $Online = $false
        if ($Reply.status -eq "Success"){
            $Online = $true
        }

        if ($AliveOnly){
            if($Online){
                $Results += [PSCustomObject]@{
                    ComptuerName = $IPStr
                    Online = $Online
                    Status = $Reply.Status
                    ReplyTTL = $Reply.Options.Ttl
                    ErrorMessage = $ErrorMessage
                }
            }
        }
        else{
            $Results += [PSCustomObject]@{
                ComptuerName = $IPStr
                Online = $false
                Status = $Reply.Status
                ReplyTTL = $Reply.Options.Ttl
                ErrorMessage = $ErrorMessage
            }
        }
    }
    return $Results
}
