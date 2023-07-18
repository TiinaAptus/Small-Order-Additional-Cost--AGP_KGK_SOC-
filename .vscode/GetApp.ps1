Enter-PSSession -ComputerName nav-1.aptus.internal -Credential aptusgroup\tiina
Import-Module 'C:\Program Files\Microsoft Dynamics 365 Business Central\190\Service\NavAdminTool.ps1'
GET-NAVAppRuntimePackage -ServerInstance DEVKonesko190 -Name 'ÄPI NIMI SIIA' -Path 'W:\APP\Konesko\...app'
