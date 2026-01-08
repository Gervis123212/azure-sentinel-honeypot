// Cloud-to-Ground Honeypot - Infrastructure as Code
// Deploys: Windows VM, Network, Public IP, NSG (Open RDP), and Log Analytics Workspace.

param location string = resourceGroup().location
param vmName string = 'Honeypot-VM'
param vmSize string = 'Standard_B2s'
param adminUsername string = 'honeypotadmin'
@secure()
param adminPassword string

// 1. Networking
resource publicIP 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${vmName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-All'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*' // The "Honeypot" configuration
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

// 2. Log Analytics Workspace
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: '${vmName}-law-${uniqueString(resourceGroup().id)}'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// 3. Virtual Machine (Windows 10)
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: 'win10-21h2-pro-g2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

// 4. Install Azure Monitor Agent (Connect VM to LAW)
resource windowsAgent 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vm
  name: 'MicrosoftMonitoringAgent'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'MicrosoftMonitoringAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: logWorkspace.properties.customerId
    }
    protectedSettings: {
      workspaceKey: logWorkspace.listKeys().primarySharedKey
    }
  }
}

output honeypotPublicIP string = publicIP.properties.ipAddress
output workspaceId string = logWorkspace.properties.customerId
