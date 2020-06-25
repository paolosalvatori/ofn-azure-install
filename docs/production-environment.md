# Production Environment #

The following picture shows the topology of the production environment deployed by the Azure Resource Manager (ARM) template.

![topology](../images/production.png)

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
- [Azure Database for PostgreSQL](https://docs.microsoft.com/en-us/azure/postgresql/): Azure Database for PostgreSQL is a relational database service based on the open-source Postgres database engine. It's a fully managed database-as-a-service offering that can handle mission-critical workloads with predictable performance, security, high availability, and dynamic scalability. The deployment of this resource is optional, but highly recommended to host the OFN database in a managed database which provides better scalability and resiliency compared to hosting the database in the same Linux virtual machine running the web site. This resource is the managed server hosting the darabase
- [Azure Database for PostgreSQL]((https://docs.microsoft.com/en-us/azure/postgresql/)): This is the OFN database hosted by the Azure Database for PostgreSQL managed server.
- [Private Link for Azure Database for PostgreSQL](https://docs.microsoft.com/en-us/azure/private-link/private-link-overview): Azure Private Link enables you to access Azure PaaS Services (for example, Azure Storage and SQL Database) and Azure hosted customer-owned/partner services over a [Private Endpoint](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview) in your virtual network. Traffic between your virtual network and the service travels the Microsoft backbone network. This resource is used to let the virtual machine hosting the OFN solution to access data hosted by the Azure Database for PostgreSQL server via a private IP address.
- [Private DNS Zone](https://docs.microsoft.com/en-us/azure/dns/private-dns-overview): Azure Private DNS provides a reliable, secure DNS service to manage and resolve domain names in a virtual network without the need to add a custom DNS solution. By using private DNS zones, you can use your own custom domain names rather than the Azure-provided names available today. You can use private DNS zones to override the DNS resolution for a particular [Private Endpoint](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview). A private DNS zone can be linked to your virtual network to resolve specific domains. For more information about Private Endpoints and Private DNS Zone integration, see [Azure Private Endpoint DNS configuration](https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns)

**NOTE**: the ARM template makes use of [conditional provisioning](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/conditional-resource-deployment) to optionally deploy the following resources:

- Azure Log Analytics
- Azure Front Door
- Azure Database for PostgreSQL
- VM extensions for Log Analytics
- WAF policy

When the ARM template is configured to deploy Front Door, the ARM template creates an inbound rule in the NSG associated to the subnet hosting the virtual machine that allows HTTP ingress traffic to the virtual machine only via Front Door. In other words, you won't be able to access the virtual machine via the following URL:

```batch
http://virtual-machine-name.region.cloudapp.azure.com
```

but only via Front Door URL:

```batch
http(s)://front-door-name.azurefd.net/
```

As mentioned above, you can optionally deploy a Web Access Firewall (WAF) policy and associate it to the frontend of Azure Front Door to protect the OFN solution from malicious attacks just setting the value of the **deployWaf** parameter to true. The WAF policy deployed by the ARM template is configured to use the OWASP default rule set. For more information, see:

- [Azure Web Application Firewall on Azure Front Door](https://docs.microsoft.com/en-us/azure/web-application-firewall/afds/afds-overview) 
- [Tutorial: Create a Web Application Firewall policy on Azure Front Door using the Azure portal](https://docs.microsoft.com/en-us/azure/web-application-firewall/afds/waf-front-door-create-portal).
- [Open Web Application Security Project (OWASP)](https://owasp.org/)

## Prerequisites ##

- An Azure subscription. If you don't have an Azure subscription, [sign up now](https://azure.microsoft.com/en-us/free/?utm_source=campaign&utm_campaign=vscode-tutorial-functions-extension&mktingSource=vscode-tutorial-functions-extension) for a free 30-day account with $200 in Azure credits to try out any combination of services.
- (Optional) [Visual Studio Code](https://code.visualstudio.com/) with the [Azure Functions extension pack](https://marketplace.visualstudio.com/items?itemName=ms-vscode.vscode-node-azure-pack).

## Deployment ##

You can use the [azuredeploy.prod.json](../templates/azuredeploy.prod.json) ARM template and [azuredeploy.prod.parameters.json](../templates/azuredeploy.prod.parameters.json)parameters.json file included in this repository to deploy the OFN solution into a production environment on Azure. You can use the [deploy-prod.sh](../scripts/deploy-prod.sh) Bash script to deploy all the Azure resources to a single resource group to an Azure region of choice using the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest). A resource group is a container that holds related resources for an Azure solution. The resource group includes those resources that you want to manage as a group. You decide which resources belong in a resource group based on what makes the most sense for your organization. For more information, see [Resource groups](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview#resource-groups). Before deploying the solution to Azure make sure to perform the following steps:

- Edit the variables in the [deploy-prod.sh](../scripts/deploy-prod.sh) to choose a resource group name and a location for the OFN solution.
- Edit the [azuredeploy.prod.parameters.json](../templates/azuredeploy.prod.parameters.json) file as indicated the next section before deploying the solution.

## Parameters ##

In the parameters section of an [Azure Resource Manager template](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/overview) template, you specify which values you can input when deploying the resources. For more information about the syntax of ARM templates, see [Understand the structure and syntax of ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/template-syntax). When deploying an ARM template to an Azure subscription via a Bash script or a PowerShell script, you can pass parameters as inline values in your script, or you can use a JSON file that contains the parameter values. For more information, see [Create Resource Manager parameter file](https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/parameter-files). The following table contains the list of the parameters that you can specify in the parameters file to customize the deployment of the OFN production environment. The **Default Value** column indicates the default value defined in the ARM template for that parameter in case you omit to specify a value when deploying the template. We suggest to review and customize the value of the parameters in the [azuredeploy.prod.parameters.json](../templates/azuredeploy.prod.parameters.json) file before deploying the ARM template to avoid name collisions with existing Azure resources.

| Name |Type | Default Value | Value |
| ------------- | ------------- | ------------- | ------------- |
| location | string | See [ARM template](../templates/azuredeploy.prod.json) | Specifies the location for all the resources deployed by the template.|
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
| scriptFilePath | string | See [ARM template](../templates/azuredeploy.prod.json) | Specifies the relative path of the scripts used to initialize the virtual machine. |
| scriptFileNames | array | See [ARM template](../templates/azuredeploy.prod.json) | Contains the scripts to download from the URI specified by the scriptFilePath parameter. |
| deployLogAnalytics | bool | true | Specifies whether to deploy a Log Analytics workspace to monitor the health and performance of the virtual machine. |
| workspaceName | string | Unique ID | Specifies the globally unique name of the Log Analytics workspace. |
| workspaceSku | string | PerGB2018 | Specifies the SKU of the Log Analytics workspace. |
| deployFrontDoor | bool | true | Specifies whether to deploy Front Door. |
| frontDoorName | string | Unique ID | Specifies the globally unique name of the Front Door resource. |
| frontDoorEnforceCertificateNameCheck | string | Disabled | Specifies whether to enforce certificate name check on HTTPS requests to all backend pools. |
| frontDoorFrontendEndpoint | object | See [ARM template](../templates/azuredeploy.prod.json) | Specifies the name and properties of the Front Door frontend endpoint. |
| frontDoorBackendPool | object | See [ARM template](../templates/azuredeploy.prod.json) | Specifies the the name and properties of the  Front Door backend pool. |
| frontDoorRoutingRule | object | See [ARM template](../templates/azuredeploy.prod.json) | Specifies the name and properties of the Front Door routing rule. |
| frontDoorHealthProbeSettings | object | See [ARM template](../templates/azuredeploy.prod.json) | Specifies the name and properties of the Front Door health probe settings. |
| httpPort | int | 3000 | Specifies the HTTP port used by the Open Foor Network solution. |
| httpsPort | int | 443 | Specifies the HTTPS port (if any) used by the Open Foor Network solution. |
| deployWaf | bool | true | Specifies whether to deploy a global WAF policy in Front Door. |
| wafPolicyName | string | OpenFoodNetworkWAF | Specifies the name of the WAF policy used by Front Door. |
| wafMode | string | Detection | Specifies whether the WAF policy is configured in detection or prevention mode. |
| deployPostgreSQL | bool | Specifies whether to deploy Azure Database for PostgreSQL. |
| serverName | string | See [ARM template](../templates/azuredeploy.prod.json) | Specifies the name of the PostgreSQL server. |
| databaseName | string | open_food_network_prod | Specifies the name of the PostgreSQL database. |
| administratorLogin | string | ofn | Specifies the login name of the database administrator. |
| administratorLoginPassword | string | No defualt value | Specifies the password of the database administrator. |
| databaseSkuCapacity | int | 2 | Specifies the compute capacity in vCores (2,4,8,16,32) of the Azure Database for PostgreSQL. |
| databaseSkuName | string | GP_Gen5_2 | Specifies the SKU name of the Azure Database for PostgreSQL. |
| databaseSkuSizeMB | int | 51200 | Specifies the SKU size of the Azure Database for PostgreSQL. |
| databaseSkuTier | string | GeneralPurpose | Specifies the pricing tier of the Azure Database for PostgreSQL. |
| postgresqlVersion | string | 9.5 | Specifies the PostgreSQL version. |
| databaseskuFamily | string | Gen5 | Specifies the SLU familiy of the Azure Database for PostgreSQL. |
| databaseFirewallStartIpAddress | string | 0.0.0.0 | Specifies the start IP address of the server firewall rule. Must be IPv4 format. |
| databaseFirewallEndIpAddress | string | 255.255.255.255 | Specifies the end IP address of the server firewall rule. Must be IPv4 format. |
| databaseCharset | string | utf8 | Specifies the charset of the database. |
| databaseCollation | string | English_United States.1252 | Specifies the collation of the database. |
| databaseCharset | string | utf8 | Specifies the charset of the database. |
| postgreSQLPrivateEndpointName | string | PostgreSQLPrivateEndpoint | Specifies the name of the private link to Azure Database for PostgreSQL. |

## Alternative Topologies ##

- If you set the **deployLogAnalytics** parameter to **false**, the Log Analytics and the virtual machine extensions used to monitor the virtual machine hosting the OFN solution will not be deployed.
- If you set the **deployFrontDoor** parameter to **false**, the Front Door global load balancer will not be deployed.
- If you set the **deployWaf** parameter to **false**, the Web Access Firewall will not be deployed and associated to Front Door.
- If you set the **deployPostgreSQL** parameter to **false**, the Azure Database for PostgreSQL will not be deployed and the OFN database will be hosted by a PostgreSQL instance located in the same Linux virtual machine that hosts the OFN solution.
