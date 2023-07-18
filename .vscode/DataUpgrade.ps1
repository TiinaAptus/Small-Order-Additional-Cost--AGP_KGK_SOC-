Enter-PSSession -ComputerName nav-1.aptus.internal -Credential aptusgroup\KASUTAJANIMI SIIA
Import-Module 'C:\Program Files\Microsoft Dynamics 365 Business Central\190\Service\NavAdminTool.ps1'
Start-NAVAppDataUpgrade -ServerInstance DEVKonesko190 -Name 'ÄPI NIMI SIIA'
