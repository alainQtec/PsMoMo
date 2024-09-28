function New-SessionTicket {
  # .SYNOPSIS
  #   Create an access token
  # .DESCRIPTION
  #   Create an access token which can then be used to authorize and authenticate towards the other end-points of the API.
  # .EXAMPLE
  #   New-SessionTicket -Verbose
  [CmdletBinding(SupportsShouldProcess)][Alias('New-AccessToken')]
  [OutputType([string])]
  param (
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$Url = "https://sandbox.momodeveloper.mtn.com/collection/token/"
  )

  process {
    try {
      if ($PSCmdlet.ShouldProcess("$Url", "Make POST Request")) {
        # .....
      }
    } catch {
      Write-Error "An error occurred while fetching the access token:`n$_"
    }
  }

  end {
    return $reslt
  }
}