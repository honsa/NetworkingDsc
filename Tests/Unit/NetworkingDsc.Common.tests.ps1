$script:ModuleName = 'NetworkingDsc.Common'

Import-Module -Name (Join-Path -Path (Join-Path -Path (Split-Path $PSScriptRoot -Parent) -ChildPath 'TestHelpers') -ChildPath 'CommonTestHelper.psm1') -Global

#region HEADER
# Unit Test Template Version: 1.1.0
[System.String] $script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
    (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone', 'https://github.com/PowerShell/DscResource.Tests.git', (Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1') -Force
Import-Module (Join-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'Modules' -ChildPath $script:ModuleName)) -ChildPath "$script:ModuleName.psm1") -Force
#endregion HEADER

# Begin Testing
try
{
    InModuleScope $script:ModuleName {
        Describe 'NetworkingDsc.Common\Test-IsNanoServer' {
            Context 'When the cmdlet Get-ComputerInfo does not exist' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $false
                    }
                }

                Test-IsNanoServer | Should -Be $false
            }

            Context 'When the current computer is a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo -MockWith {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'NanoServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -Be $true
            }

            Context 'When the current computer is not a Nano server' {
                BeforeAll {
                    Mock -CommandName Test-Command -MockWith {
                        return $true
                    }

                    Mock -CommandName Get-ComputerInfo -MockWith {
                        return @{
                            OsProductType = 'Server'
                            OsServerLevel = 'FullServer'
                        }
                    }
                }

                Test-IsNanoServer | Should -Be $false
            }
        }

        Describe 'NetworkingDsc.Common\Get-LocalizedData' {
            $mockTestPath = {
                return $mockTestPathReturnValue
            }

            $mockImportLocalizedData = {
                $BaseDirectory | Should -Be $mockExpectedLanguagePath
            }

            BeforeEach {
                Mock -CommandName Test-Path -MockWith $mockTestPath -Verifiable
                Mock -CommandName Import-LocalizedData -MockWith $mockImportLocalizedData -Verifiable
            }

            Context 'When loading localized data for Swedish' {
                $mockExpectedLanguagePath = 'sv-SE'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with sv-SE language' {
                    Mock -CommandName Join-Path -MockWith {
                        return 'sv-SE'
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 3 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $false

                It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                    Mock -CommandName Join-Path -MockWith {
                        return $ChildPath
                    } -Verifiable

                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw

                    Assert-MockCalled -CommandName Join-Path -Exactly -Times 4 -Scope It
                    Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                    Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                }

                Context 'When $ScriptRoot is set to a path' {
                    $mockExpectedLanguagePath = 'sv-SE'
                    $mockTestPathReturnValue = $true

                    It 'Should call Import-LocalizedData with sv-SE language' {
                        Mock -CommandName Join-Path -MockWith {
                            return 'sv-SE'
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }

                    $mockExpectedLanguagePath = 'en-US'
                    $mockTestPathReturnValue = $false

                    It 'Should call Import-LocalizedData and fallback to en-US if sv-SE language does not exist' {
                        Mock -CommandName Join-Path -MockWith {
                            return $ChildPath
                        } -Verifiable

                        { Get-LocalizedData -ResourceName 'DummyResource' -ScriptRoot '.' } | Should -Not -Throw

                        Assert-MockCalled -CommandName Join-Path -Exactly -Times 2 -Scope It
                        Assert-MockCalled -CommandName Test-Path -Exactly -Times 1 -Scope It
                        Assert-MockCalled -CommandName Import-LocalizedData -Exactly -Times 1 -Scope It
                    }
                }
            }

            Context 'When loading localized data for English' {
                Mock -CommandName Join-Path -MockWith {
                    return 'en-US'
                } -Verifiable

                $mockExpectedLanguagePath = 'en-US'
                $mockTestPathReturnValue = $true

                It 'Should call Import-LocalizedData with en-US language' {
                    { Get-LocalizedData -ResourceName 'DummyResource' } | Should -Not -Throw
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidResultException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-InvalidResultException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-InvalidResultException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-ObjectNotFoundException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-ObjectNotFoundException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-ObjectNotFoundException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.Exception: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidOperationException' {
            Context 'When calling with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-InvalidOperationException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When calling with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-InvalidOperationException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.InvalidOperationException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-NotImplementedException' {
            Context 'When called with Message parameter only' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'

                    { New-NotImplementedException -Message $mockErrorMessage } | Should -Throw $mockErrorMessage
                }
            }

            Context 'When called with both the Message and ErrorRecord parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockExceptionErrorMessage = 'Mocked exception error message'

                    $mockException = New-Object -TypeName System.Exception -ArgumentList $mockExceptionErrorMessage
                    $mockErrorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $mockException, $null, 'InvalidResult', $null

                    { New-NotImplementedException -Message $mockErrorMessage -ErrorRecord $mockErrorRecord } | Should -Throw ('System.NotImplementedException: {0} ---> System.Exception: {1}' -f $mockErrorMessage, $mockExceptionErrorMessage)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\New-InvalidArgumentException' {
            Context 'When calling with both the Message and ArgumentName parameter' {
                It 'Should throw the correct error' {
                    $mockErrorMessage = 'Mocked error'
                    $mockArgumentName = 'MockArgument'

                    { New-InvalidArgumentException -Message $mockErrorMessage -ArgumentName $mockArgumentName } | Should -Throw ('Parameter name: {0}' -f $mockArgumentName)
                }
            }

            Assert-VerifiableMock
        }

        Describe 'NetworkingDsc.Common\Convert-CIDRToSubhetMask' {
            Context 'Subnet Mask Notation Used "192.168.0.0/255.255.0.0"' {
                It 'Should Return "192.168.0.0/255.255.0.0"' {
                    Convert-CIDRToSubhetMask -Address @('192.168.0.0/255.255.0.0') | Should -Be '192.168.0.0/255.255.0.0'
                }
            }
            Context 'Subnet Mask Notation Used "192.168.0.10/255.255.0.0" resulting in source bits masked' {
                It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                    Convert-CIDRToSubhetMask -Address @('192.168.0.10/255.255.0.0') | Should -Be '192.168.0.0/255.255.0.0'
                }
            }
            Context 'CIDR Notation Used "192.168.0.0/16"' {
                It 'Should Return "192.168.0.0/255.255.0.0"' {
                    Convert-CIDRToSubhetMask -Address @('192.168.0.0/16') | Should -Be '192.168.0.0/255.255.0.0'
                }
            }
            Context 'CIDR Notation Used "192.168.0.10/16" resulting in source bits masked' {
                It 'Should Return "192.168.0.0/255.255.0.0" with source bits masked' {
                    Convert-CIDRToSubhetMask -Address @('192.168.0.10/16') | Should -Be '192.168.0.0/255.255.0.0'
                }
            }
            Context 'Multiple Notations Used "192.168.0.0/16,10.0.0.24/255.255.255.0"' {
                $Result = Convert-CIDRToSubhetMask -Address @('192.168.0.0/16', '10.0.0.24/255.255.255.0')
                It 'Should Return "192.168.0.0/255.255.0.0,10.0.0.0/255.255.255.0"' {
                    $Result[0] | Should -Be '192.168.0.0/255.255.0.0'
                    $Result[1] | Should -Be '10.0.0.0/255.255.255.0'
                }
            }
            Context 'Range Used "192.168.1.0-192.168.1.128"' {
                It 'Should Return "192.168.1.0-192.168.1.128"' {
                    Convert-CIDRToSubhetMask -Address @('192.168.1.0-192.168.1.128') | Should -Be '192.168.1.0-192.168.1.128'
                }
            }
            Context 'IPv6 Used "fe80::/112"' {
                It 'Should Return "fe80::/112"' {
                    Convert-CIDRToSubhetMask -Address @('fe80::/112') | Should -Be 'fe80::/112'
                }
            }
        }

        <#
            InModuleScope has to be used to enable the Get-NetAdapter Mock
            This is because forcing the ModuleName in the Mock command throws
            an exception because the GetAdapter module has no manifest
        #>
        Describe 'NetworkingDsc.Common\Find-NetworkAdapter' {

            # Generate the adapter data to be used for Mocking
            $adapterName = 'Adapter'
            $adapterPhysicalMediaType = '802.3'
            $adapterStatus = 'Up'
            $adapterMacAddress = '11-22-33-44-55-66'
            $adapterInterfaceDescription = 'Hyper-V Virtual Ethernet Adapter #2'
            $adapterInterfaceIndex = 2
            $adapterInterfaceGuid = '75670D9B-5879-4DBA-BC99-86CDD33EB66A'
            $adapterDriverDescription = 'Hyper-V Virtual Ethernet Adapter'
            $nomatchAdapter = [PSObject]@{
                Name                 = 'No Match Adapter'
                PhysicalMediaType    = '802.11'
                Status               = 'Disconnected'
                MacAddress           = '66-55-44-33-22-11'
                InterfaceDescription = 'Some Other Interface #2'
                InterfaceIndex       = 3
                InterfaceGuid        = 'FFFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF'
                DriverDescription    = 'Some Other Interface'
            }
            $matchAdapter = [PSObject]@{
                Name                 = $adapterName
                PhysicalMediaType    = $adapterPhysicalMediaType
                Status               = $adapterStatus
                MacAddress           = $adapterMacAddress
                InterfaceDescription = $adapterInterfaceDescription
                InterfaceIndex       = $adapterInterfaceIndex
                InterfaceGuid        = $adapterInterfaceGuid
                DriverDescription    = $adapterDriverDescription
            }
            $adapterArray = @( $nomatchAdapter, $matchAdapter )
            $multipleMatchingAdapterArray = @( $matchAdapter, $matchAdapter )

            Context 'Name is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -Name $adapterName -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Name is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -Name 'NOMATCH' -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'PhysicalMediaType is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'PhysicalMediaType is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType 'NOMATCH' -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Status is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -Status $adapterStatus -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Status is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -Status 'Disabled' -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'MacAddress is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -MacAddress $adapterMacAddress -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'MacAddress is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -MacAddress '00-00-00-00-00-00' -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceDescription is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceDescription $adapterInterfaceDescription -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceDescription is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceDescription 'NOMATCH' -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceIndex is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceIndex $adapterInterfaceIndex -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceIndex is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceIndex 99 -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceGuid is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceGuid $adapterInterfaceGuid -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'InterfaceGuid is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -InterfaceGuid 'NOMATCH' -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'DriverDescription is passed and one adapter matches' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -DriverDescription $adapterDriverDescription -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'DriverDescription is passed and no adapters match' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.NetAdapterNotFoundError)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -DriverDescription 'NOMATCH' -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'No parameters are passed and multiple Adapters adapters match but IgnoreMultipleMatchingAdapters is not set' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.MultipleMatchingNetAdapterFound -f 2)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'No parameters are passed and multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set and interface number is 2' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $adapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 2 -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Multiple Adapters adapters match but IgnoreMultipleMatchingAdapters is not set' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $multipleMatchingAdapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.MultipleMatchingNetAdapterFound -f 2)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $multipleMatchingAdapterArray }

                It 'Should not throw exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true -Verbose } | Should -Not -Throw
                }

                It 'Should return expected adapter' {
                    $script:result.Name | Should -Be $adapterName
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Multiple Adapters adapters match and IgnoreMultipleMatchingAdapters is set and InterfaceNumber is greater than matching adapters' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $multipleMatchingAdapterArray }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.InvalidNetAdapterNumberError -f 2, 3)

                It 'Should throw the correct exception' {
                    { $script:result = Find-NetworkAdapter -PhysicalMediaType $adapterPhysicalMediaType -IgnoreMultipleMatchingAdapters:$true -InterfaceNumber 3 -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }
        }

        <#
            InModuleScope has to be used to enable the Get-NetAdapter Mock
            This is because forcing the ModuleName in the Mock command throws
            an exception because the GetAdapter module has no manifest
        #>
        Describe 'NetworkingDsc.Common\Get-DnsClientServerStaticAddress' {

            # Generate the adapter data to be used for Mocking
            $interfaceAlias = 'Adapter'
            $interfaceGuid = [Guid]::NewGuid().ToString()
            $nomatchAdapter = $null
            $matchAdapter = [PSObject]@{
                InterfaceGuid = $interfaceGuid
            }
            $ipv4Parameters = @{
                InterfaceAlias = $interfaceAlias
                AddressFamily  = 'IPv4'
            }
            $ipv6Parameters = @{
                InterfaceAlias = $interfaceAlias
                AddressFamily  = 'IPv6'
            }
            $noIpv4StaticAddressString = ''
            $oneIpv4StaticAddressString = '8.8.8.8'
            $secondIpv4StaticAddressString = '4.4.4.4'
            $twoIpv4StaticAddressString = "$oneIpv4StaticAddressString,$secondIpv4StaticAddressString"
            $noIpv6StaticAddressString = ''
            $oneIpv6StaticAddressString = '::1'
            $secondIpv6StaticAddressString = '::2'
            $twoIpv6StaticAddressString = "$oneIpv6StaticAddressString,$secondIpv6StaticAddressString"

            Context 'Interface Alias does not match adapter in system' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $nomatchAdapter }

                $errorRecord = Get-InvalidOperationRecord `
                    -Message ($script:localizedData.InterfaceAliasNotFoundError -f $interfaceAlias)

                It 'Should throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Throw $errorRecord
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv4 NameServer is empty' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        NameServer = $noIpv4StaticAddressString
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:result | Should -BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv4 NameServer property does not exist' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        Dummy = ''
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:result | Should -BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv4 NameServer contains one DNS entry' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        NameServer = $oneIpv4StaticAddressString
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return expected address' {
                    $script:result | Should -Be $oneIpv4StaticAddressString
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv4 NameServer contains two DNS entries' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        NameServer = $twoIpv4StaticAddressString
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv4Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return two expected addresses' {
                    $script:result[0] | Should -Be $oneIpv4StaticAddressString
                    $script:result[1] | Should -Be $secondIpv4StaticAddressString
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv6 NameServer is empty' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        NameServer = $noIpv6StaticAddressString
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:result | Should -BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv6 NameServer property does not exist' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        Dummy = ''
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return null' {
                    $script:result | Should -BeNullOrEmpty
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv6 NameServer contains one DNS entry' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        NameServer = $oneIpv6StaticAddressString
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return expected address' {
                    $script:result | Should -Be $oneIpv6StaticAddressString
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }

            Context 'Interface Alias was found in system but IPv6 NameServer contains two DNS entries' {
                Mock `
                    -CommandName Get-NetAdapter `
                    -MockWith { $matchAdapter }

                Mock `
                    -CommandName Get-ItemProperty `
                    -MockWith {
                    [psobject] @{
                        NameServer = $twoIpv6StaticAddressString
                    }
                }

                It 'Should not throw exception' {
                    { $script:result = Get-DnsClientServerStaticAddress @ipv6Parameters -Verbose } | Should -Not -Throw
                }

                It 'Should return two expected addresses' {
                    $script:result[0] | Should -Be $oneIpv6StaticAddressString
                    $script:result[1] | Should -Be $secondIpv6StaticAddressString
                }

                It 'Should call expected mocks' {
                    Assert-MockCalled -CommandName Get-NetAdapter -Exactly -Times 1
                    Assert-MockCalled -CommandName Get-ItemProperty -Exactly -Times 1
                }
            }
        }

        Describe 'NetworkingDsc.Common\Get-IPAddressPrefix' {
            Context 'IPv4 CIDR notation provided' {
                it 'Should return the provided IP and prefix as separate properties' {
                    $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.10.0/24'

                    $IPaddress.IPaddress | Should -Be '192.168.10.0'
                    $IPaddress.PrefixLength | Should -Be 24
                }
            }

            Context 'IPv4 Class A address with no CIDR notation' {
                it 'Should return correct prefix when Class A address provided' {
                    $IPaddress = Get-IPAddressPrefix -IPAddress '10.1.2.3'

                    $IPaddress.IPaddress | Should -Be '10.1.2.3'
                    $IPaddress.PrefixLength | Should -Be 8
                }
            }

            Context 'IPv4 Class B address with no CIDR notation' {
                it 'Should return correct prefix when Class B address provided' {
                    $IPaddress = Get-IPAddressPrefix -IPAddress '172.16.2.3'

                    $IPaddress.IPaddress | Should -Be '172.16.2.3'
                    $IPaddress.PrefixLength | Should -Be 16
                }
            }

            Context 'IPv4 Class C address with no CIDR notation' {
                it 'Should return correct prefix when Class C address provided' {
                    $IPaddress = Get-IPAddressPrefix -IPAddress '192.168.20.3'

                    $IPaddress.IPaddress | Should -Be '192.168.20.3'
                    $IPaddress.PrefixLength | Should -Be 24
                }
            }

            Context 'IPv6 CIDR notation provided' {
                it 'Should return provided IP and prefix as separate properties' {
                    $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123/64' -AddressFamily IPv6

                    $IPaddress.IPaddress | Should -Be 'FF12::12::123'
                    $IPaddress.PrefixLength | Should -Be 64
                }
            }

            Context 'IPv6 with no CIDR notation provided' {
                it 'Should return provided IP and correct IPv6 prefix' {
                    $IPaddress = Get-IPAddressPrefix -IPAddress 'FF12::12::123' -AddressFamily IPv6

                    $IPaddress.IPaddress | Should -Be 'FF12::12::123'
                    $IPaddress.PrefixLength | Should -Be 64
                }
            }
        }

        Describe 'NetworkingDsc.Common\Remove-CommonParameter' {
            $removeCommonParameter = @{
                Parameter1          = 'value1'
                Parameter2          = 'value2'
                Verbose             = $true
                Debug               = $true
                ErrorAction         = 'Stop'
                WarningAction       = 'Stop'
                InformationAction   = 'Stop'
                ErrorVariable       = 'errorVariable'
                WarningVariable     = 'warningVariable'
                OutVariable         = 'outVariable'
                OutBuffer           = 'outBuffer'
                PipelineVariable    = 'pipelineVariable'
                InformationVariable = 'informationVariable'
                WhatIf              = $true
                Confirm             = $true
                UseTransaction      = $true
            }

            Context 'Hashtable contains all common parameters' {
                It 'Should not throw exception' {
                    { $script:result = Remove-CommonParameter -Hashtable $removeCommonParameter -Verbose } | Should -Not -Throw
                }

                It 'Should have retained parameters in the hashtable' {
                    $script:result.Contains('Parameter1') | Should -Be $true
                    $script:result.Contains('Parameter2') | Should -Be $true
                }

                It 'Should have removed the common parameters from the hashtable' {
                    $script:result.Contains('Verbose') | Should -Be $false
                    $script:result.Contains('Debug') | Should -Be $false
                    $script:result.Contains('ErrorAction') | Should -Be $false
                    $script:result.Contains('WarningAction') | Should -Be $false
                    $script:result.Contains('InformationAction') | Should -Be $false
                    $script:result.Contains('ErrorVariable') | Should -Be $false
                    $script:result.Contains('WarningVariable') | Should -Be $false
                    $script:result.Contains('OutVariable') | Should -Be $false
                    $script:result.Contains('OutBuffer') | Should -Be $false
                    $script:result.Contains('PipelineVariable') | Should -Be $false
                    $script:result.Contains('InformationVariable') | Should -Be $false
                    $script:result.Contains('WhatIf') | Should -Be $false
                    $script:result.Contains('Confirm') | Should -Be $false
                    $script:result.Contains('UseTransaction') | Should -Be $false
                }
            }
        }

        Describe 'NetworkingDsc.Common\Test-DscParameterState' {
            Context 'All current parameters match desired parameters' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -Be $true
                }
            }

            Context 'The current parameters do not match desired parameters because a string mismatches' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'different string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because a boolean mismatches' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $false
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because a int mismatches' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 1
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array is missing a value' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 1
                    parameterArray  = @( 'a', 'b' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array has an additional value' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 1
                    parameterArray  = @( 'a', 'b', 'c', 'd' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array has a different value' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 1
                    parameterArray  = @( 'a', 'd', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because an array has a different type' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 1
                    parameterArray  = @( 'a', 1, 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'The current parameters do not match desired parameters because a parameter has a different type' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = $false
                    parameterBool   = $true
                    parameterInt    = 1
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $valuesToCheck = @(
                    'parameterString'
                    'parameterBool'
                    'ParameterInt'
                    'ParameterArray'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $false' {
                    $script:result | Should -Be $false
                }
            }

            Context 'Some of the current parameters do not match desired parameters but only matching parameter is compared' {
                $currentValues = @{
                    parameterString = 'a string'
                    parameterBool   = $true
                    parameterInt    = 99
                    parameterArray  = @( 'a', 'b', 'c' )
                }

                $desiredValues = [PSObject] @{
                    parameterString = 'a string'
                    parameterBool   = $false
                    parameterInt    = 1
                    parameterArray  = @( 'a', 'b' )
                }

                $valuesToCheck = @(
                    'parameterString'
                )

                It 'Should not throw exception' {
                    { $script:result = Test-DscParameterState `
                            -CurrentValues $currentValues `
                            -DesiredValues $desiredValues `
                            -ValuesToCheck $valuesToCheck `
                            -Verbose } | Should -Not -Throw
                }

                It 'Should return $true' {
                    $script:result | Should -Be $true
                }
            }

            Describe 'NetworkingDsc.Common\Test-DscObjectHasProperty' {
                # Use the Get-Verb cmdlet to just get a simple object fast
                $testDscObject = (Get-Verb)[0]

                Context 'The object contains the expected property' {
                    It 'Should not throw exception' {
                        { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Verb' -Verbose } | Should -Not -Throw
                    }

                    It 'Should return $true' {
                        $script:result | Should -Be $true
                    }
                }

                Context 'The object does not contain the expected property' {
                    It 'Should not throw exception' {
                        { $script:result = Test-DscObjectHasProperty -Object $testDscObject -PropertyName 'Missing' -Verbose } | Should -Not -Throw
                    }

                    It 'Should return $false' {
                        $script:result | Should -Be $false
                    }
                }
            }
        }
    }
}
finally
{
    #region FOOTER
    #endregion
}
