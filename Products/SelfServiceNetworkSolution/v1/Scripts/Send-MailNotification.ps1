<#
.NAME
    Send-MailNotification.ps1
.DESCRIPTION
    This script will to a CBSP Azure customer when a Self Service Network Solution deployment has been successfully finished.  
#>

[CmdletBinding()]
Param (
    [Parameter(Mandatory = $true)][String]  $SendGridSMTP,
    [Parameter(Mandatory = $true)][String]  $SendGridUserName,
    [Parameter(Mandatory = $true)][String]  $SendGridPassword,
    [Parameter(Mandatory = $false)][String]  $PathToAttachment,
    [Parameter(Mandatory = $true)][String]  $InputObject,
    [Parameter(Mandatory = $false)][Boolean]  $PipelineFailed = $false
)

#Defining body of the mail
Function Get-MailBody {
    Param (
        [String] $Table,
        [String] $DeploymentType
    )

    If ($DeploymentType -eq 'IaaS') {
      $subbody1 = "
      <p><span style='font-family: Arial;'>Dear CBSP Azure Customer,</span></p>
      <p><span style='font-family: Arial;'>We are happy to inform you that the following resources have been successfully deployed:</span></p>
      <table style= 'border: 1px solid #ddd; border-collapse: collapse; width: 100%;'>
      <tbody><tr style='padding-top: 12px; padding-bottom: 12px; text-align: left; background-color: #009286; color: white;'><th>ResourceGroupName</th><th>VirtualNetworkName</th><th width='200'>SubnetName</th><th>AddressSpace</th></tr>"
    }
    ElseIf ($DeploymentType -eq 'ADB') {
      $subbody1 = "
      <p><span style='font-family: Arial;'>Dear CBSP Azure Customer,</span></p>
      <p><span style='font-family: Arial;'>We are happy to inform you that the following resources have been successfully deployed:</span></p>
      <table style= 'border: 1px solid #ddd; border-collapse: collapse; width: 100%;'>
      <tbody><tr style='padding-top: 8px; padding-bottom: 8px; text-align: left; background-color: #009286; color: white;'><th>ResourceGroupName</th><th>VirtualNetworkName</th><th width='200'>PrivateSubnetName</th><th>PrivateAddressSpace</th><th width='200'>PublicSubnetName</th><th>PublicAddressSpace</th></tr>"
    }

    If (![System.String]::IsNullOrWhiteSpace($PathToAttachment)) {
      $subbody3 = "
      </tbody>
      </table>
      <p><span style='font-family: Arial;'>If you wish to customize the deployed network solution, then you can use the attached <i>README.md</i> markdown file as a starting point.<br><br></span></p>
      <p><span style='font-family: Arial;'>Should you have any questions or concerns, please create a <a href='https://servicenow.abnamro.org/myit?id=myit_support_msg'>Service Now Green ticket</a> to CBSP Azure team</span></p>
      <p>&nbsp;</p>
      <p><span color='#18FAD1' style='font-family: Arial;'>With kind regards,<br><br></span>
      <span style='font-family: Segoe UI; font-size: 16px; color: #009286;'><b>CBSP-Azure Team</b><br /></span><a href='mailto:cbsp-azure@nl.abnamro.com'><span style='font-family: Segoe UI; font-size: 14px; color: #868686;'>cbsp-azure@nl.abnamro.com<br /></span></a>
      <span style='font-family: Segoe UI; font-size: 14px; color: #868686;'>020-3830584</span></p>" 
    }
    Else {
      $subbody3 = "
      </tbody>
      </table>
      <p><span style='font-family: Arial;'>Should you have any questions or concerns, please create a <a href='https://servicenow.abnamro.org/myit?id=myit_support_msg'>Service Now Green ticket</a> to CBSP Azure team</span></p>
      <p>&nbsp;</p>
      <p><span color='#18FAD1' style='font-family: Arial;'>With kind regards,<br><br></span>
      <span style='font-family: Segoe UI; font-size: 16px; color: #009286;'><b>CBSP-Azure Team</b><br /></span><a href='mailto:cbsp-azure@nl.abnamro.com'><span style='font-family: Segoe UI; font-size: 14px; color: #868686;'>cbsp-azure@nl.abnamro.com<br /></span></a>
      <span style='font-family: Segoe UI; font-size: 14px; color: #868686;'>020-3830584</span></p>"
  
    }
    $Body = $subbody1+$Table+$subbody3
    Return $Body
}

$SendGridCredential = [System.Management.Automation.PSCredential]::new($SendGridUserName, (ConvertTo-SecureString -String $SendGridPassword -AsPlainText -Force))

## Convert InputObject to Json
If (![System.String]::IsNullOrWhiteSpace($InputObject)) {
  $data = $InputObject | ConvertFrom-Json

  If ($data.NetworkType -eq 'IaaS') {
    $virtualNetworkName = $data.VirtualNetworkInfo.VirtualNetworkName
    $subnetName = $data.VirtualNetworkInfo.SubnetName
    $addressSpace = $data.VirtualNetworkInfo.IPRange
    $resourceGroupName = $data.VirtualNetworkInfo.VnetResourceGroup

    $inputParameters = [PSCustomObject]@{        
        'VirtualNetworkName' = $virtualNetworkName;
        'SubnetName'         = $subnetName;
        'AddressSpace'       = $addressSpace;
        'VnetResourceGroup'  = $resourceGroupName;

    }
  }
  ElseIf ($data.NetworkType -eq 'ADB') {
    $virtualNetworkName = $data.VirtualNetworkInfo.VirtualNetworkName
    $privateSubnetName = $data.VirtualNetworkInfo.PrivateSubnetName
    $privateAddressSpace = $data.VirtualNetworkInfo.PrivateIPRange
    $publicSubnetName = $data.VirtualNetworkInfo.PublicSubnetName
    $publicAddressSpace = $data.VirtualNetworkInfo.PublicIPRange
    $resourceGroupName = $data.VirtualNetworkInfo.VnetResourceGroup

    $inputParameters = [PSCustomObject]@{        
        'VirtualNetworkName'  = $virtualNetworkName;
        'PrivateSubnetName'   = $privateSubnetName;
        'PrivateAddressSpace' = $privateAddressSpace;
        'PublicSubnetName'    = $publicSubnetName;
        'PublicAddressSpace'  = $publicAddressSpace;
        'VnetResourceGroup'   = $resourceGroupName;
    }

  }

  Foreach ($inputParam in $($inputParameters.PSobject.Properties))
  {
      If ([System.String]::IsNullOrWhiteSpace($inputParam.Value)) {
          $ErrorMessage = "Empty value $($inputParam.Name) found! Cannot continue"
          Write-Host "##vso[task.logissue type=error]$ErrorMessage"
          Write-Error $ErrorMessage
      }
  }
}
Else {
  Write-Warning -Message "InputObject parameter is not set"
}


Switch ($PipelineFailed) {
  $true {
    # Create mail body
      $body = "
      <p><span style='font-family: Arial;'>Dear CBSP Azure Customer,</span></p>
      <p style='font-family: Arial;'>Unfortunally, the deployment of Virtual Network <span style='font-family: Segoe UI; color: #009286;'>$virtualNetworkName</span> in Resource Group <span style='font-family: Segoe UI; color: #009286;'>$resourceGroupName</span> has failed.<br><br></p>
      <p><span style='font-family: Arial;'>The CBSP Azure Team will look into the issue and report back to you as soon as possible.<br><br>Should you have any questions or concerns in the meantime, please create a <a href='https://servicenow.abnamro.org/myit?id=myit_support_msg'>Service Now Green ticket</a> to CBSP Azure team</span></p>
      <p>&nbsp;</p>
      <p><span color='#18FAD1' style='font-family: Arial;'>With kind regards,<br><br></span>
      <span style='font-family: Segoe UI; font-size: 16px; color: #009286;'><b>CBSP-Azure Team</b><br /></span><a href='mailto:cbsp-azure@nl.abnamro.com'><span style='font-family: Segoe UI; font-size: 14px; color: #868686;'>cbsp-azure@nl.abnamro.com<br /></span></a>
      <span style='font-family: Segoe UI; font-size: 14px; color: #868686;'>020-3830584</span></p>"

      #Trigger runbook to send notification
      $contactMail = $data.Environment.ContactMail

      Send-MailMessage -SmtpServer $SendGridSMTP `
      -Credential $SendGridCredential `
      -UseSsl -Port 587 `
      -From 'cbsp-azure@nl.abnamro.com' `
      -To $contactMail `
      -Subject "Network Deployment Failed" `
      -BodyAsHtml $body
  }
  $false {
    #Create Tables
    If ($data.NetworkType -eq 'IaaS') {
      $tb       = ""
      $tb       = "<tr style='padding-top: 8px; padding-bottom: 8px; background-color: #f2f2f2; color: #000000;'><td>"+ $resourceGroupName +"</td><td>"+ $virtualNetworkName +"</td><td>"+ $subnetName +"</td><td>"+ $addressSpace +"</td></tr>"
      $table   += $tb

    }
    ElseIf ($data.NetworkType -eq 'ADB') {
      $tb       = ""
      $tb       = "<tr style='padding-top: 8px; padding-bottom: 8px; background-color: #f2f2f2; color: #000000;'><td>"+ $resourceGroupName +"</td><td>"+ $virtualNetworkName +"</td><td>"+ $privateSubnetName +"</td><td>"+ $privateAddressSpace +"</td><td>"+ $publicSubnetName +"</td><td>"+ $publicAddressSpace +"</td></tr>"
      $table   += $tb

    }

    #Trigger runbook to send notification
    If ($null -ne $table) {

      $body = Get-MailBody -Table $table -DeploymentType $data.NetworkType
      $contactMail = $data.Environment.ContactMail

      If (![System.String]::IsNullOrWhiteSpace($PathToAttachment)) {
        Send-MailMessage -SmtpServer $SendGridSMTP `
        -Credential $SendGridCredential `
        -UseSsl -Port 587 `
        -From 'cbsp-azure@nl.abnamro.com' `
        -To $contactMail `
        -Subject "Network Deployment Successful" `
        -BodyAsHtml $body `
        -Attachments $PathToAttachment
      }
      Else {
        Send-MailMessage -SmtpServer $SendGridSMTP `
        -Credential $SendGridCredential `
        -UseSsl -Port 587 `
        -From 'cbsp-azure@nl.abnamro.com' `
        -To $contactMail `
        -Subject "Network Deployment Successful" `
        -BodyAsHtml $body 
      }
    }
  }
}
