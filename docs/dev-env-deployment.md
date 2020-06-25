# Development Environment #

The following picture shows the topology of the development environment deployed by the Azure Resource Manager (ARM) template.

![topology](../images/development.png)

The [Azure Resource Manager template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) deploys the following resources:

- [Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview): this virtual network has a single subnet that hosts the Linux virtual machine. Virtual networks enable to create a traffic isolation boundary on the Azure platform. A virtual network is composed of a single or multiple virtual network segments, each with a specific IP network prefix (a subnet, either IPv4 or dual stack IPv4/IPv6). The virtual network defines an internal perimeter area where IaaS virtual machines and PaaS services can establish private communications.
- [Network Security Group](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview): A network security group (NSG) is a list of security rules that act as traffic filtering on IP sources, IP destinations, protocols, IP source ports, and IP destination ports (also called a Layer 4 five-tuple). The network security group can be applied to a subnet, a network interface card (NIC) associated with an Azure virtual machine, or both. The network security groups are essential to control inbound and outbound traffic from subnets and virtual machines. The level of security afforded by the network security group is a function of which ports you open, and for what purpose. This network security group deployed by the ARM template contains inbound rules to limit the access to the virtual machine:
  - SSH: this inbound rule allows access on port 22
  - HTTP: this inbound rule allows access on port 80
  - HTTPS: this inbound rule allows access on port 443
- [Public IP](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-public-ip-address): With some Azure features, you can associate service endpoints to a public IP address so that your resource is accessible from the internet. This endpoint uses NAT to route traffic to the internal address and port on the virtual network in Azure. This path is the primary way for external traffic to pass into the virtual network. You can configure public IP addresses to determine which traffic is passed in and how and where it's translated onto the virtual network. This is the Public IP of the Linux virtual machine hosting the OFN solution
- [Network Interface](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-network-interface): A network interface (NIC) enables an Azure virtual machine to communicate with the internet, Azure, and on-premises resources. This is the NIC used by the Linux virtual machine that makes use of the Public IP.
- [Virtual Machine](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/overview): Azure Virtual Machines (VM) is one of several types of on-demand, scalable computing resources that Azure offers. Typically, you choose a VM when you need more control over the computing environment than the other choices offer. An Azure VM gives you the flexibility of virtualization without having to buy and maintain the physical hardware that runs it. However, you still need to maintain the VM by performing tasks, such as configuring, patching, and installing the software that runs on it. This Ubuntu Linux virtual machine is used to host the Open Food Network solution.
- [Log Analytics](https://docs.microsoft.com/en-us/azure/azure-monitor/platform/design-logs-deployment): Azure Monitor stores log data in a Log Analytics workspace, which is an Azure resource and a container where data is collected, aggregated, and serves as an administrative boundary. Data in a workspace is organized into tables, each of which stores different kinds of data and has its own unique set of properties based on the resource generating the data. Most data sources will write to their own tables in a Log Analytics workspace. This Log Analytics workspace is used to monitor the health status of the Linux VM (optional).
- [Front Door](https://docs.microsoft.com/en-us/azure/frontdoor/front-door-overview): Azure Front Door (AFD) is Microsoft's highly available and scalable Web Application Acceleration Platform, Global HTTP Load Balancer, Application Protection, and Content Delivery Network. Running in more than 100 locations at the edge of Microsoft's Global Network, AFD enables you to build, operate, and scale out your dynamic web application and static content. AFD provides your application with world-class end-user performance, unified regional/stamp maintenance automation, BCDR automation, unified client/user information, caching, and service insights. The deployment of this resource is optional. When enabled, Front Door can be used to:
  - Requests acceleration
  - Static content caching at the edge
  - Dynamic compressions of MIME types
  - Static response caching at the edge
  - WAF policy at the edge to protect the web site from malicious attacks
  - SSL Termination
- [WAF Policy](https://docs.microsoft.com/en-us/azure/web-application-firewall/overview): Web Application Firewall (WAF) provides centralized protection of your web applications from common exploits and vulnerabilities. Web applications are increasingly targeted by malicious attacks that exploit commonly known vulnerabilities. SQL injection and cross-site scripting are among the most common attacks. This resource can be deployed along with Front Door.

**NOTE**: the ARM template makes use of conditional provisioning to optionally deploy the following resources:

- Log Analytics
- VM extensions for Log Analytics
- Front Door
- WAF policy

When the ARM template is configured to deploy Front Door, the ARM template creates an inbound rule in the NSG associated to the subnet hosting the virtual machine that allows HTTP ingress traffic to the virtual machine only via Front Door. In other words, you won't be able to access the virtual machine via the following URL:

```batch
http://virtual-machine-name.region.cloudapp.azure.com
```

but only via Front Door URL:

```batch
http(s)://front-door-name.azurefd.net/
```

You can optionally deploy a Web Access Firewall (WAF) policy and associate it to the frontend of Azure Front Door to protect the OFN solution from malicious attacks just setting the value of the deployWaf parameter to true. The WAF policy deployed by the ARM template is configured to use the OWASP default rule set. For more information, see:

- [Azure Web Application Firewall on Azure Front Door](https://docs.microsoft.com/en-us/azure/web-application-firewall/afds/afds-overview) 
- [Tutorial: Create a Web Application Firewall policy on Azure Front Door using the Azure portal](https://docs.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-create-portal).
- [Open Web Application Security Project (OWASP)](https://owasp.org/)

Azure Front Door is configured to collect diagnostics logs and metrics in a Log Analytics workspace deployed by the ARM template.

## Parameters ##

In the parameters section of an [Azure Resource Manager template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) template, you specify which values you can input when deploying the resources. For more information about the syntax of ARM templates, see [Understand the structure and syntax of ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax). When deploying an ARM template to an Azure subscription via a Bash script or a PowerShell script, you can pass parameters as inline values in your script, or you can use a JSON file that contains the parameter values. For more information, see [Create Resource Manager parameter file](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/parameter-files). The following table contains the list of the parameters that you can specify in the parameters file to customize the deployment of the OFN development environment. The **Default Value** column indicates the default value defined in the ARM template for that parameter in case you omit to specify a value when deploying the template. We suggest to review and customize the value of the parameters in the [azuredeploy.dev.parameters.json](../templates/azuredeploy.dev.parameters.json) file before deploying the ARM template to avoid name collisions with existing Azure resources.

| Name |Type | Default Value | Value |
| ------------- | ------------- | ------------- | ------------- |
| location | string | See [template](../templates/azuredeploy.dev.json) | Specifies the location for all the resources deployed by the template.|
| virtualNetworkName | string | UbuntuVnet | Specifies the name of the virtual network hosting the virtual machine. |
| virtualNetworkAddressPrefix | string | 10.0.0.0/16 | Specifies the address prefix of the virtual network hosting the virtual machine. |
| subnetName | string | DefaultSubnet | Specifies the name of the subnet hosting the virtual machine. |
| subnetAddressPrefix | string | 10.0.0.0/24 | Specifies the address prefix of the subnet hosting the virtual machine. |
| storageAccountName | string | Unique ID | Specifies the globally unique name for the storage account used to store the boot diagnostics logs of the virtual machine. |
| storageAccountType | string | Premium_LRS | Specifies the storage SKU for the OS and data disks of the virtual machine. |
| vmName | string | OpenFoodNetworkVm | Specifies the name of the virtual machine. |
| vmSize | string | Standard_D1 | Specifies the size of the virtual machine. |
| imagePublisher | string | Canonical | Specifies the image publisher of the disk image used to create the virtual machine. |
| imageOffer | string | UbuntuServer | Specifies the offer of the platform image or marketplace image used to create the virtual machine. |
| imageSku | string | 18.04-LTS | Specifies the Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. |
| authenticationType | string | password | Specifies the type of authentication when accessing the Virtual Machine. SSH key is recommended. |
| adminUsername | string | azadmin | Specifies the name of the administrator account of the virtual machine. |
| adminPasswordOrKey | string | No default value | Specifies the SSH Key or password for the virtual machine. SSH key is recommended. |
| numDataDisks | int | 1 | Specifies the number of data disks of the virtual machine. |
| osDiskSize | int | 100 | Specifies the size in GB of the OS disk of the virtual machine. |
| osDiskSize | int | 100 | Specifies the size in GB of the OS disk of the virtual machine. |
| dataDiskSize | int | 100 | Specifies the size in GB of each data disk that is attached to the virtual machine. |
| dataDiskCaching | string | ReadWrite | Specifies the caching requirements for the data disks. |
| scriptFilePath | string | See [template](../templates/azuredeploy.dev.json)  | Specifies the relative path of the scripts used to initialize the virtual machine. |
| scriptFileNames | array | See [template](../templates/azuredeploy.dev.json) | Contains the scripts to download from the URI specified by the scriptFilePath parameter. |
| deployLogAnalytics | bool | true | Specifies whether to deploy a Log Analytics workspace to monitor the health and performance of the virtual machine. |
| workspaceName | string | Unique ID | Specifies the globally unique name of the Log Analytics workspace. |
| workspaceSku | string | PerGB2018 | Specifies the SKU of the Log Analytics workspace. |
| deployFrontDoor | bool | true | Specifies whether to deploy Front Door. |
| frontDoorName | string | Unique ID | Specifies the globally unique name of the Front Door resource. |
| frontDoorEnforceCertificateNameCheck | string | Disabled | Specifies whether to enforce certificate name check on HTTPS requests to all backend pools. |
| frontDoorFrontendEndpoint | object | See [template](../templates/azuredeploy.dev.json) | Specifies the name and properties of the Front Door frontend endpoint. |
| frontDoorBackendPool | object | See [template](../templates/azuredeploy.dev.json) | Specifies the the name and properties of the  Front Door backend pool. |
| frontDoorRoutingRule | object | See [template](../templates/azuredeploy.dev.json) | Specifies the name and properties of the Front Door routing rule. |
| frontDoorHealthProbeSettings | object | See [template](../templates/azuredeploy.dev.json) | Specifies the name and properties of the Front Door health probe settings. |
| deployWaf | bool | true | Specifies whether to deploy a global WAF policy in Front Door. |
| wafPolicyName | string | OpenFoodNetworkWAF | Specifies the name of the WAF policy used by Front Door. |
| wafMode | string | Detection | Specifies whether the WAF policy is configured in detection or prevention mode. |
| gitUsername | string | No default value | Specifies the Git account used to clone the OFN solution. See [install-ofn.sh](../scripts/install-ofn.sh) |
| gitEmail | string | No default value | Specifies the email to use in the Git configuration. See [install-ofn.sh](../scripts/install-ofn.sh) |
| gitBranch | string | master | Specifies the name of the OFN branch to clone with Git. See [install-ofn.sh](../scripts/install-ofn.sh) |
| httpPort | int | 3000 | Specifies the HTTP port used by the Open Foor Network solution. |
| httpsPort | int | 443 | Specifies the HTTPS port (if any) used by the Open Foor Network solution. |
