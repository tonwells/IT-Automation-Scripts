' ------------------------------------------------------------------------
' glpi-agent-deployment.vbs
'  Copyright (C) 2010-2017 by the FusionInventory Development Team.
'  Copyright (C) 2021-2024 by Teclib SAS
' ------------------------------------------------------------------------

' Este script é usado para a implantação automatizada do GLPI Agent em sistemas Windows.
' Ele suporta diferentes configurações, como a seleção de arquitetura (x86 ou x64),
' opções de instalação, e a capacidade de desinstalar agentes anteriores (como FusionInventory ou OCS).
'
'  LICENÇA
'
'  Este arquivo faz parte do projeto GLPI Agent.
'
'  Este arquivo é um software livre; você pode redistribuí-lo e/ou modificá-lo
'  sob os termos da Licença Pública Geral GNU conforme publicada pela
'  Free Software Foundation; seja na versão 2 da Licença, ou (a seu
'  critério) qualquer versão posterior.
'
'
'  Este arquivo é distribuído na esperança de que seja útil, mas SEM
'  QUALQUER GARANTIA; sem mesmo a garantia implícita de COMERCIABILIDADE ou
'  ADEQUAÇÃO A UM PROPÓSITO ESPECÍFICO. Consulte a Licença Pública Geral GNU para
'  mais detalhes.
'
'  Você deve ter recebido uma cópia da Licença Pública Geral GNU
'  junto com este programa; se não, escreva para a Free Software Foundation,
'  Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, EUA,
'  ou consulte <http://www.gnu.org/licenses/>.
'
' ------------------------------------------------------------------------
'
'  @package   GLPI Agent
'  @version   1.10
'  @file      contrib/windows/glpi-agent-deployment.vbs
'  @author(s) Benjamin Accary <meldrone@orange.fr>
'             Christophe Pujol <chpujol@gmail.com>
'             Marc Caissial <marc.caissial@zenitique.fr>
'             Tomas Abad <tabadgp@gmail.com>
'             Guillaume Bougard <gbougard@teclib.com>
'  @copyright Copyright (c) 2010-2017 FusionInventory Team
'             Copyright (c) 2021-2024 Teclib SAS
'  @license   GNU GPL version 2 or (a seu critério) qualquer versão posterior
'             http://www.gnu.org/licenses/old-licenses/gpl-2.0-standalone.html
'  @link      http://www.glpi-project.org/
'  @since     2021
'  @tradução PT Welinton Paiva
' ------------------------------------------------------------------------

'
' Propósito:
'     Implementação automática do GLPI Agent.
'
Option Explicit
Dim Reconfigure, Repair, Verbose
Dim Setup, SetupArchitecture, SetupLocation, SetupNightlyLocation, SetupOptions, SetupVersion, RunUninstallFusionInventoryAgent, UninstallOcsAgent

' ------------------------------------------------------------------------
' CONFIGURAÇÕES DO USUÁRIO
' ------------------------------------------------------------------------

' SetupVersion
' Defina a versão do instalador do GLPI Agent que será implantado.
SetupVersion = "1.10"

' SetupLocation
' Defina a localização do instalador. Pode ser uma URL (HTTP/HTTPS) ou um caminho de rede (CIFS/SMB).
SetupLocation = "https://github.com/glpi-project/glpi-agent/releases/download/" & SetupVersion

' SetupNightlyLocation
' Defina a localização para builds noturnos, caso esteja usando uma versão de desenvolvimento.
SetupNightlyLocation = "https://nightly.glpi-project.org/glpi-agent"

' SetupArchitecture
' Defina a arquitetura do instalador: 'x86', 'x64' ou 'Auto' (para detectar automaticamente).
SetupArchitecture = "Auto"

' SetupOptions
' Defina as opções de linha de comando para o instalador. Estas opções controlam o comportamento da instalação.
SetupOptions = "/quiet RUNNOW=1 SERVER='http://glpi.yourcompany.com/'"

' Setup
' Nome do arquivo do instalador. Normalmente, não há necessidade de modificar esta variável.
Setup = "GLPI-Agent-" & SetupVersion & "-" & SetupArchitecture & ".msi"

' Reconfigure
' Configura se a instalação deve apenas reconfigurar a instalação existente caso a versão seja a mesma.
Reconfigure = "Yes"

' Repair
' Configura se a instalação deve reparar a instalação existente.
Repair = "No"

' Verbose
' Habilita ou desabilita mensagens de informação durante a execução do script.
Verbose = "No"

' RunUninstallFusionInventoryAgent
' Configura se o script deve desinstalar o FusionInventory Agent antes de instalar o GLPI Agent.
RunUninstallFusionInventoryAgent = "No"

' UninstallOcsAgent
' Configura se o script deve desinstalar o OCS Agent antes de instalar o GLPI Agent.
UninstallOcsAgent = "No"

' ------------------------------------------------------------------------
' FUNÇÕES
' ------------------------------------------------------------------------

' Função removeOCSAgents
' Esta função desinstala qualquer instância do OCS Inventory Agent, verificando as arquiteturas x86 e x64.
Function removeOCSAgents()
   On error resume next

   Dim Uninstall

   ' Verifica se o OCS Inventory Agent está instalado em um sistema de 32 bits e o desinstala.
   Uninstall = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\OCS Inventory Agent\UninstallString")
   If err.number = 0 then
      WshShell.Run "CMD.EXE /C net stop ""OCS INVENTORY SERVICE""",0,True
      WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles%\OCS Inventory Agent"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%SystemDrive%\ocs-ng"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C sc delete ""OCS INVENTORY""",0,True
   End If

   ' Verifica se o OCS Inventory Agent está instalado em um sistema de 64 bits e o desinstala.
   Uninstall = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\OCS Inventory Agent\UninstallString")
   If err.number = 0 then
      WshShell.Run "CMD.EXE /C net stop ""OCS INVENTORY SERVICE""",0,True
      WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles(x86)%\OCS Inventory Agent"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%SystemDrive%\ocs-ng"" /S /Q",0,True
      WshShell.Run "CMD.EXE /C sc delete ""OCS INVENTORY""",0,True
   End If
End Function

' Função uninstallFusionInventoryAgent
' Esta função desinstala qualquer instância do FusionInventory Agent instalada no sistema.
Function uninstallFusionInventoryAgent()
   Dim Uninstall, getValue

   ' Tenta obter o servidor e a configuração local do FusionInventory Agent do registro.
   If not hasOption("SERVER") then
      On error resume next
      getValue = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\FusionInventory-Agent\server")
      If err.number = 0 And getValue <> "" then
         SetupOptions = SetupOptions & " SERVER='" & getValue & "'"
      End If
   End If
   If not hasOption("LOCAL") then
      On error resume next
      getValue = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\FusionInventory-Agent\local")
      If err.number = 0 And getValue <> "" then
         SetupOptions = SetupOptions & " LOCAL='" & getValue & "'"
      End If
   End If

   ' Verifica e desinstala o FusionInventory Agent instalado em sistemas de 32 bits e 64 bits.
   Uninstall = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\FusionInventory-Agent\UninstallString")
   If err.number = 0 then
      WshShell.Run "CMD.EXE /C net stop FusionInventory-Agent",0,True
      WshShell.Run "CMD.EXE /C """ & Uninstall & """ /S /NOSPLASH",0,True
      WshShell.Run "CMD.EXE /C rmdir ""%ProgramFiles%\FusionInventory-Agent"" /S /Q",0,True
   End If
End Function

' Função GetSystemArchitecture
' Esta função retorna a arquitetura do sistema (x86, x64 ou NotSupported).
Function GetSystemArchitecture()
   Dim strSystemArchitecture
   Err.Clear
   On Error Resume Next
   strSystemArchitecture = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%PROCESSOR_ARCHITECTURE%")
   If Err.Number = 0 Then
      Select Case strSystemArchitecture
         Case "x86"
            GetSystemArchitecture = "x86"
         Case "AMD64"
            GetSystemArchitecture = "x64"
         Case Else
            GetSystemArchitecture = "NotSupported"
      End Select
   Else
      GetSystemArchitecture = "Unknown"
   End If
End Function

' Função IsInstallationNeeded
' Verifica se a instalação do GLPI Agent é necessária, comparando a versão atual com a nova versão.
Function IsInstallationNeeded(strSetupVersion, strSetupArchitecture, strSystemArchitecture)
   Dim strCurrentSetupVersion
   If strSystemArchitecture = "x86" Then
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent\Installer\Version")
      If Err.Number = 0 Then
         If strCurrentSetupVersion <> strSetupVersion Then
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
         IsInstallationNeeded = True
      End If
   Else
      strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\GLPI-Agent\Installer\Version")
      If Err.Number = 0 Then
         If strCurrentSetupVersion <> strSetupVersion Then
            IsInstallationNeeded = True
         End If
         Exit Function
      Else
         strCurrentSetupVersion = WshShell.RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\GLPI-Agent\Installer\Version")
         If Err.Number = 0 Then
            If strCurrentSetupVersion <> strSetupVersion Then
               IsInstallationNeeded = True
            End If
            Exit Function
         Else
            IsInstallationNeeded = True
         End If
      End If
   End If
End Function

' Função SaveWebBinary
' Faz o download do instalador do GLPI Agent a partir de uma URL especificada e o salva localmente.
Function SaveWebBinary(strSetupLocation, strSetup)
   Const adTypeBinary = 1
   Const adSaveCreateOverWrite = 2
   Dim web, strURL
   strUrl = strSetupLocation & "/" & strSetup
   Set web = CreateObject("WinHttp.WinHttpRequest.5.1")
   If web Is Nothing Then Set web = CreateObject("WinHttp.WinHttpRequest")
   web.Open "GET", strURL, False
   web.Send
   If web.Status <> "200" Then
      SaveWebBinary =
