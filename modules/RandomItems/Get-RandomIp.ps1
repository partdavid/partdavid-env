<#

.SYNOPSIS

Generate a random IP address

.DESCRIPTION

The Get-RandomIp command generates a random IP address on a specified
network (the default is 10.0.0.0/8 or ::ffff:10.0.0.0/104 for
IPv6). Another network can be specified. The resulting addresses are
distributed uniformly in the specified network.

By default, Get-RandomIp considers some address ranges "illegal" and
won't generate an adrress in the range. It maintains uniform
distribution across the remaining range by re-attempting
any address that's generated in a prohibited range. This *can*
result in failures: by default, Get-RandomIp attempts to generate
an address 10 times.

When generating multiple addresses, Get-RandomIp ensures they
are unique. This can be changed with the -AllowDuplicates parameter.

.EXAMPLE

PS>Get-RandomIp

AddressFamily      : InterNetwork
ScopeId            :
IsIPv6Multicast    : False
IsIPv6LinkLocal    : False
IsIPv6SiteLocal    : False
IsIPv6Teredo       : False
IsIPv6UniqueLocal  : False
IsIPv4MappedToIPv6 : False
Address            : 2390510858
IPAddressToString  : 10.77.124.142

.EXAMPLE

PS>Get-RandomIp 192.168.0.0/24

AddressFamily      : InterNetwork
ScopeId            :
IsIPv6Multicast    : False
IsIPv6LinkLocal    : False
IsIPv6SiteLocal    : False
IsIPv6Teredo       : False
IsIPv6UniqueLocal  : False
IsIPv4MappedToIPv6 : False
Address            : 1107339456
IPAddressToString  : 192.168.0.66

.EXAMPLE

PS>Get-RandomIp fc00::a0:0:0:00/120

AddressFamily      : InterNetworkV6
ScopeId            : 0
IsIPv6Multicast    : False
IsIPv6LinkLocal    : False
IsIPv6SiteLocal    : False
IsIPv6Teredo       : False
IsIPv6UniqueLocal  : True
IsIPv4MappedToIPv6 : False
Address            :
IPAddressToString  : fc00::a0:0:0:71

.EXAMPLE

PS>Get-RandomIp 127.0.0.0/24
Exception: /usr/local/microsoft/powershell/7/Modules/RandomItems/Get-RandomIp.ps1:66
Line |
  66 |        throw "Couldn't select valid address in $MaxAttempts attempts ( …
     |        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Couldn't select valid address in 10 attempts (attempted: 127.0.0.240, 127.0.0.28, 127.0.0.50, 127.0.0.19, 127.0.0.71,
     | 127.0.0.88, 127.0.0.209, 127.0.0.67, 127.0.0.208, 127.0.0.94)

.EXAMPLE

PS>Get-RandomIp 127.0.0.0/24 -AllowLoopback

AddressFamily      : InterNetwork
ScopeId            :
IsIPv6Multicast    : False
IsIPv6LinkLocal    : False
IsIPv6SiteLocal    : False
IsIPv6Teredo       : False
IsIPv6UniqueLocal  : False
IsIPv4MappedToIPv6 : False
Address            : 2197815423
IPAddressToString  : 127.0.0.131

.EXAMPLE

PS>'192.168.1.0/24' | Get-RandomIp

AddressFamily      : InterNetwork
ScopeId            :
IsIPv6Multicast    : False
IsIPv6LinkLocal    : False
IsIPv6SiteLocal    : False
IsIPv6Teredo       : False
IsIPv6UniqueLocal  : False
IsIPv4MappedToIPv6 : False
Address            : 570534080
IPAddressToString  : 192.168.1.34

.LINK

Get-Random

#>
function Get-RandomIp {
  [CmdletBinding()]
  param(
    # Specify an IPv4 or IPv6 CIDR
    [Parameter(ValueFromPipeline=$True)] [ValidateScript({
                                                           [ipaddress]$net, [int]$bits = $_ -split '/',2
                                                           ($net) -and ($bits -in 0..128)
                                                         })] [string]$Network,
    # Set the number of attempts to be made to find a legal address
    [int]$MaxAttempts = 10,
    # Specify the address family (influences default network)
    [ValidateSet('InterNetwork', 'InterNetworkV6')] [System.Net.Sockets.AddressFamily]$AddressFamily = 'Unspecified',
    # Set the random number seed
    [int]$SetSeed,
    # Generate multiple addresses per network
    [int]$Count = 1,
    # Allow Get-RandomIp to generate link-local addresses
    [switch]$AllowLinkLocal,
    # Allow Get-RandomIp to generate loopback addresses
    [switch]$AllowLoopback,
    # Allow Get-RandomIp to generate multicast addresses
    [switch]$AllowMulticast,
    # Allow Get-RandomIp to generate duplicate addresses
    [switch]$AllowDuplicates
  )

  begin {
    # Note: $seen as an array is pretty inefficient.
    $seen = @()
    if ($PSBoundParameters.ContainsKey('SetSeed')) {
      # Set the random seed for subsequent Get-Random invocations
      Get-Random -SetSeed $SetSeed | Out-Null
    }
  }

  process {
    if (-not $Network) {
      $Network = switch ($AddressFamily) {
        InterNetworkV6 { '::ffff:10.0.0.0/104' }
        default { '10.0.0.0/8' }
      }
    }
    [ipaddress]$networkAddr, [int]$maskBits = $Network -split '/',2
    $networkAddrBytes = $networkAddr.GetAddressBytes()
    $mask = ConvertFrom-MaskBits -AddressFamily $networkAddr.AddressFamily -MaskBits $maskBits
    $maskBytes = $mask.GetAddressBytes()
    for ($addrNum = 0; $addrNum -lt $Count; $addrNum++) {
      Write-Debug "Generating address $addrNum"
      $value = $Null
      $candidates = @()
      $attempts = 0
      :attempts while ($attempts++ -lt $MaxAttempts) {
        [byte[]]$randomBytes = $networkAddrBytes | %{ (Get-Random -Minimum 0 -Maximum 255) }
        [byte[]]$randomAddrBytes = for ($i = 0; $i -lt $randomBytes.length; $i++) {
          $randomByte = ($networkAddrBytes[$i] -band $maskBytes[$i]) -bor ($randomBytes[$i] -band $(-bnot $maskBytes[$i]))
          $randomByte
        }
        $candidate = [ipaddress]$randomAddrBytes
        $candidates += $candidate
        Write-Debug "attempt ${attempts}: $candidate [seen=$($seen -join ', ')] [candidates=$($candidates -join ', ')]"

        if ([System.Net.IpAddress]::IsLoopback($candidate) -and -not $AllowLoopback) {
          continue attempts
        }
        if ($candidate.IsIPv6LinkLocal -and -not $AllowLinkLocal) {
          continue attempts
        }
        if ((Test-NetworkMember -Network '169.254.0.0' -Netmask '255.255.0.0' -Address $candidate) -and -not $AllowLinkLocal) {
          continue attempts
        }
        if ($candidate.IsIPv6Multicast -and -not $AllowMulticast) {
          continue attempts
        }
        if ((Test-NetworkMember -Network '224.0.0.0' -Netmask '240.0.0.0' -Address $candidate) -and -not $AllowMulticast) {
          continue attempts
        }
        if ($candidate -in $seen -and -not $AllowDuplicates) {
          continue attempts
        }
        $value = $candidate
        break attempts
      }
      if (-not $value) {
        throw "Couldn't select valid address in $MaxAttempts attempts (attempted: $($candidates -join ', '))"
      }
      if (-not $AllowDuplicates) {
        $seen += $value
      }
      $value
    }
  }

}

function ConvertFrom-MaskBits {
  [CmdletBinding()]
  param(
    [ValidateRange(0, 128)] [int]$MaskBits,
    [ValidateSet('InterNetwork', 'InterNetworkV6')] [System.Net.Sockets.AddressFamily]$AddressFamily = 'InterNetwork'
  )

  if ($AddressFamily -eq 'InterNetwork') {
    if ($MaskBits -gt 32) {
      throw "Invalid value $MaskBits for IPv4 (out of range)"
    }
  }

  [byte[]]$mask = 0..($AddressFamily -eq 'InterNetworkV6' ? 15 : 3) | %{ 0 }
  $quotient,$remainder = [math]::DivRem($MaskBits, 8)[0,1]
  # Set all the whole bytes involved in mask to 0
  if ($quotient -gt 0) {
    0 .. ($quotient - 1)| %{ $mask[$_] = 0xff }
  }
  # The remainder is the number of bits to shift-left in the byte
  if ($remainder -gt 0) {
    $mask[$quotient] = [byte]0xff -shl (8 - $remainder)
  }

  [ipaddress]$mask
}

<#

.SYNOPSIS

Test whether an address is in the specified network

.DESCRIPTION

The Test-Network command tests whether the specified address
is in the given network, as specified by a network address
and netmask.

#>
function Test-NetworkMember {
  [CmdletBinding()]
  param(
    [ipaddress]$Network,
    [ipaddress]$Netmask,
    [Parameter(ValueFromPipeline=$True)] [ipaddress]$Address
  )

  process {

    $networkBytes = $Network.GetAddressBytes()
    $netmaskBytes = $Netmask.GetAddressBytes()
    $addressBytes = $Address.GetAddressBytes()

    for ($i = 0; $i -lt $networkBytes.length; $i++) {
      if (($networkBytes[$i] -band $netmaskBytes[$i]) -ne ($addressBytes[$i] -band $netmaskBytes[$i])) {
        return $False
      }
    }
    $True
  }
}

# ROADMAP: It should be possible to remove the probabilistic
# -MaxAttempts approach to stopping duplicates and IPs in reserved
# ranges, by doing the same kind of interval splitting

# ROADMAP: For some reason, when you have *any* comment-based help
# present, Get-Help displays all the enum options for
# $AddressFamily. When no comment-based help is present, it accurately
# shows the options in the ValidateSet attribute. I haven't checked
# into whether using XML-based help (MAML, perhaps generated from
# PlatyPS) might improve it.
