BeforeAll {
  Get-Module RandomItems | Remove-Module -Force
  Import-Module -Force (Join-Path $PSScriptRoot '../RandomItems.psd1')
}

Describe 'Get-RandomIp' {

  Context 'When using IPv4' {

    It 'Returns a random Ip' {
      Get-RandomIp | Should -BeOfType [ipaddress]
    }

    It 'Returns multiple random unique Ips' {
      Get-RandomIp -Count 10 | Should -HaveCount 10
      # 100 attempts makes this unlikely to fail--but not impossible! Hate it.
      $tightIntervalIps = Get-RandomIp -Network 192.168.1.0/28 -Count 10 -MaxAttempts 100
      $tightIntervalIps | Sort-Object -Unique | Should -HaveCount 10
      $dups = Get-RandomIp -Network 192.168.1.1/32 -Count 10 -AllowDuplicates
      $dups | Should -HaveCount 10
      $dups | Sort-Object -Unique | Should -HaveCount 1
    }

    It 'Gives consistent results with the same seed' {
      $results = 0 .. 10 | %{ Get-RandomIp -SetSeed 92 }
      $results | Should -HaveCount 11
      $results | Sort-Object -Unique | Should -HaveCount 1
    }

    It 'Rejects invalid network CIDR (no address)' {
      { Get-RandomIp -Network 'none' } | Should -Throw '*invalid IP address*'
    }

    It 'Restricts to the network specified' {
      0 .. 10 | %{
        Get-RandomIp -Network '192.168.1.1/32' | Should -Be '192.168.1.1'
      }
    }

    It 'Accepts networks on the pipeline' {
      0 .. 10 | %{ "192.168.1.$_/24" } | Get-RandomIp | Should -HaveCount 11
      0 .. 10 | %{ "192.168.1.$_/24" } | Get-RandomIp | %{
        Test-NetworkMember '192.168.0.0' $_ -netmask '255.255.0.0' | Should -BeTrue
      }
    }

    It 'Disallows Duplicates' {
      { 0 .. 10 | %{ '192.168.1.1/32' } | Get-RandomIp } | Should -Throw
      0 .. 10 | %{ '192.168.1.1/32' } | Get-RandomIp -AllowDuplicates | %{ $_ | Should -Be '192.168.1.1' }
    }

    It 'Disallows Multicast' {
      { Get-RandomIp -Network '224.0.0.0/4' } | Should -Throw
      Get-RandomIp -Network '224.0.0.0/4' -AllowMulticast | Should -BeOfType [ipaddress]
    }

    It 'Disallows Link-local' {
      { Get-RandomIp -Network '169.254.0.0/16' } | Should -Throw
      Get-RandomIp -Network '169.254.0.0/16' -AllowLinkLocal | Should -BeOfType [ipaddress]
    }

    It 'Disallows Loopback' {
      { Get-RandomIp -Network '127.0.0.0/24' } | Should -Throw
      Get-RandomIp -Network '127.0.0.0/24' -AllowLoopback | Should -BeOfType [ipaddress]
    }


  }

  Context 'When using IPv6' {

    It 'Returns a random Ip' {
      Get-RandomIp -AddressFamily InterNetworkV6 | Should -BeOfType [ipaddress]
    }

    It 'Rejects invalid network CIDR (no address)' {
      { Get-RandomIp -Network 'none' -AddressFamily InterNetworkV6 } | Should -Throw '*invalid IP address*'
    }

    It 'Restricts to the network specified' {
      0 .. 10 | %{
        Get-RandomIp -Network '::ffff:192.168.1.1/128' | Should -Be '::ffff:192.168.1.1'
      }
    }

    It 'Accepts networks on the pipeline' {
      0 .. 10 | %{ "::ffff:192.168.$_.0/120" } | Get-RandomIp | Should -HaveCount 11
      0 .. 10 | %{ "::ffff:192.168.$_.0/120" } | Get-RandomIp | %{
        Test-NetworkMember '::ffff:192.168.0.0' $_ -netmask 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:0' | Should -BeTrue
      }
    }

    It 'Disallows duplicates' {
      { 0 .. 10 | %{ '::ffff:192.168.1.1/128' } | Get-RandomIp } | Should -Throw
      0 .. 10 | %{ '::ffff:192.168.1.1/128' } | Get-RandomIp -AllowDuplicates | %{
        $_ | Should -Be '::ffff:192.168.1.1'
      }
    }

    It 'Disallows Multicast' {
      { Get-RandomIp -Network 'ff00::/8' } | Should -Throw
      Get-RandomIp -Network 'ff00::/8' -AllowMulticast | Should -BeOfType [ipaddress]
    }

    It 'Disallows Link-local' {
      { Get-RandomIp -Network 'fe80::/64' } | Should -Throw
      Get-RandomIp -Network 'fe80::/64' -AllowLinkLocal | Should -BeOfType [ipaddress]
    }

    It 'Disallows Loopback' {
      { Get-RandomIp -Network '::1/128' } | Should -Throw
      Get-RandomIp -Network '::1/128' -AllowLoopback | Should -BeOfType [ipaddress]
    }

  }

}

Describe 'Test-NetworkMember' {
  
  Context 'When using IPv4' {

    It 'Succeeds when address is in network' {
      Test-NetworkMember '192.168.1.0' '192.168.1.22' -netmask '255.255.255.0' | Should -BeTrue
    }

    It 'Fails when address is not in network' {
      Test-NetworkMember '192.168.1.0' '192.168.2.22' -netmask '255.255.255.0' | Should -BeFalse
    }

    It 'Correctly handles (true) edge cases' {
      $data_in_csv = @'
Network,Address,Netmask
192.168.1.0,192.168.1.0,255.255.255.0
192.168.1.5,192.168.1.0,255.255.255.0
192.168.1.0,192.168.1.255,255.255.255.0
'@
      $data_in_csv | ConvertFrom-Csv | %{
        Test-NetworkMember -Network $_.Network -Netmask $_.Netmask -Address $_.Address | Should -BeTrue
      }
    }

    It 'Correctly handles (false) edge cases' {
      $data_in_csv = @'
Network,Address,Netmask
192.168.1.0,192.168.0.255,255.255.255.0
192.168.1.255,192.168.2.0,255.255.255.0
'@
      $data_in_csv | ConvertFrom-Csv | %{
        Test-NetworkMember -Network $_.Network -Netmask $_.Netmask -Address $_.Address | Should -BeFalse
      }
    }

    It 'Accepts addresses on the pipeline' {
      '192.168.0.1' | Test-NetworkMember -Network '192.168.0.0' -Netmask '255.255.255.0' | Should -BeTrue
      '192.168.1.1' | Test-NetworkMember -Network '192.168.0.0' -Netmask '255.255.255.0' | Should -BeFalse
      0 .. 10 | %{ "192.168.0.$_" } | Test-NetworkMember -Network '192.168.0.0' -Netmask '255.255.255.248' | `
        Should -Be $True,$True,$True,$True,$True,$True,$True,$True,$False,$False,$False
    }

  }
}

InModuleScope 'RandomItems' {

  Describe 'ConvertFrom-MaskBits' {

    Context 'When using IPv4' {

      It 'Creates a netmask' {
        $mask = ConvertFrom-MaskBits 24
        $mask | Should -BeOfType [ipaddress]
        $mask.AddressFamily | Should -Be 'InterNetwork'
        $mask | Should -Be '255.255.255.0'    # Stringifies, not sure why?
      }

      It 'Creates netmasks with expected values' {
        $expected = @{
          0 = '0.0.0.0'
          1 = '128.0.0.0'
          4 = '240.0.0.0'
          7 = '254.0.0.0'
          8 = '255.0.0.0'
          9 = '255.128.0.0'
          12 = '255.240.0.0'
          15 = '255.254.0.0'
          16 = '255.255.0.0'
          17 = '255.255.128.0'
          20 = '255.255.240.0'
          23 = '255.255.254.0'
          24 = '255.255.255.0'
          25 = '255.255.255.128'
          28 = '255.255.255.240'
          31 = '255.255.255.254'
          32 = '255.255.255.255'
        }
        foreach ($bits in $expected.keys) {
          ConvertFrom-MaskBits $bits | Should -Be $expected[$bits] -Because "/$bits netmask = $($expected[$bits])"
        }
      }

      It 'Rejects out-of-range bit counts' {
        { ConvertFrom-MaskBits -MaskBits (-1) } | Should -Throw
        { ConvertFrom-MaskBits -MaskBits 33 } | Should -Throw
        { ConvertFrom-MaskBits -AddressFamily 'InterNetworkV6' -MaskBits 129 } | Should -Throw
      }
    }

    Context 'When using IPv6' {
  
      It 'Creates a netmask' {
        $mask = ConvertFrom-MaskBits 24 -AddressFamily 'InterNetworkV6'
        $mask | Should -BeOfType [ipaddress]
        $mask.AddressFamily | Should -Be 'InterNetworkV6'
        $mask | Should -Be 'ffff:ff00::'
      }

      It 'Creates a larger netmask' {
        $mask = ConvertFrom-MaskBits 64 -AddressFamily 'InterNetworkV6'
        $mask | Should -Be 'ffff:ffff:ffff:ffff::'
      }

    }

  }
}
