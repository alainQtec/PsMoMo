using namespace System.Management.Automation;
using namespace System.Management.Automation.Language

using module Private/models/models.psm1
using module Private/clitools/clitools.psm1
using module Private/exceptions/exceptions.psm1

#region Classes

enum MoMoEnvironment {
  SANDBOX
  PRODUCTION
}
enum ProductType {
  Collection = 0
  Disbursement = 1
  Remittance = 2
}
class Product {
  hidden [ValidateNotNullOrWhiteSpace()][String]$baseUrl;
  hidden [ValidateNotNullOrWhiteSpace()][String]$SubscriptionKey;
  hidden [ValidateNotNullOrEmpty()][ApiCredentials]$apiCredentials;
  hidden [MoMoEnvironment]$environment;

  Product([String]$baseUrl, [MoMoEnvironment]$environment, [String]$SubscriptionKey, [String]$apiUser, [String]$apiKey) {
    $this.baseUrl = $baseUrl; [RestClient]::BaseUrl = $baseUrl
    $this.environment = $environment;
    $this.SubscriptionKey = $SubscriptionKey;
    $this.apiCredentials = [ApiCredentials]::new($apiUser, $apiKey);
  }

  [Token] CreateToken([ProductType]$type) {
    return $this.CreateToken($type, $this.ApiCredentials.User, $this.ApiCredentials.Key)
  }

  [Token] CreateToken([ProductType]$type, [String]$apiUser, [String]$apiKey) {
    [String]$authorization = "Basic " + [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($apiUser + ":" + $apiKey)))
    return [RestClient]::CreateToken($type, $authorization, $this.SubscriptionKey)
  }

  [RequestToPay] GetRequestToPay([ProductType]$type, [string]$token, [String]$referenceId) {
    return [RestClient]::GetRequestToPay($type, $this.GetAuthHeader($token), $this.SubscriptionKey, $this.environment, $referenceId)
  }

  [String] RequestToPay([ProductType]$type, [String]$token, [float]$amount, [String]$currency, [String]$externalId, [String]$payerPartyId, [String]$payerMessage, [String]$payeeNote) {
    $body = [RequestToPayBodyRequest]::new($amount, $currency, $externalId, $payerPartyId, $payerMessage, $payeeNote);
    $referenceId = [Guid]::NewGuid().Guid; [string]$authHeader = $this.GetAuthHeader($token);
    return [RestClient]::CreateRequestToPay($type.ToString(), $authHeader, $this.SubscriptionKey, $referenceId, $this.environment, $body)
  }

  [String] Transfer([ProductType]$type, [String]$token, [float]$amount, [String]$currency, [String]$externalId, [String]$payeePartyId, [String]$payerMessage, [String]$payeeNote) {
    $body = [TransferBodyRequest]::new([xconvert]::Tofloat($amount), $currency, $externalId, $payeePartyId, $payerMessage, $payeeNote);

    [String]$referenceId = [Guid]::NewGuid().Guid;
    return [RestClient]::CreateTransfer($type, $this.GetAuthHeader($token), $this.SubscriptionKey, $referenceId, $this.environment, $body)
  }

  [Transfer] GetTransfer([ProductType]$type, [String]$token, [String]$referenceId) {
    return [RestClient]::GetTransfer($type, $this.GetAuthHeader($token), $this.SubscriptionKey, $this.environment, $referenceId)
  }
  [AccountBalance] GetAccountBalance([ProductType]$type, [String]$token) {
    return [RestClient]::GetAccountBalance($type, $this.GetAuthHeader($token), $this.SubscriptionKey, $this.environment)
  }
  [AccountStatus] GetAccountStatus([ProductType]$type, [String]$token, [String]$msisdn) {
    $resp = [RestClient]::GetAccountStatus($type, $this.GetAuthHeader($token), $this.SubscriptionKey, $this.environment, "msisdn", $msisdn);
    return $resp.Content
  }

  [String] GetAuthHeader([String]$token) {
    return ("Bearer {0}" -f $token);
  }
}

class Collections : Product {
  hidden [ProductType] $TYPE = "collection"; # ! final !

  Collections([String]$baseUrl, [MoMoEnvironment]$environment, [String]$SubscriptionKey, [String]$apiUser, [String]$apiKey) :base($baseUrl, $environment, $SubscriptionKey, $apiUser, $apiKey) {
  }

  [Token] CreateToken() {
    return $this.CreateToken($this.TYPE)
  }
  [RequestToPay] GetRequestToPay([String]$referenceId) {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetRequestToPay($this.TYPE, $token.accessToken, $referenceId)
  }

  [String] RequestToPay([float]$amount, [String]$currency, [String]$externalId, [String]$payerPartyId, [String]$payerMessage, [String]$payeeNote) {
    return $this.RequestToPay($this.TYPE, $this.CreateToken($this.TYPE).accessToken, $amount, $currency, $externalId, $payerPartyId, $payerMessage, $payeeNote);
  }

  [String] RequestToPay([String]$token, [float]$amount, [String]$currency, [String]$externalId, [String]$payerPartyId, [String]$payerMessage, [String]$payeeNote) {
    return $this.RequestToPay($this.TYPE, $token, $amount, $currency, $externalId, $payerPartyId, $payerMessage, $payeeNote);
  }

  [RequestToPay] GetRequestToPay([String]$token, [String]$referenceId) {
    return $this.GetRequestToPay($this.TYPE, $token, $referenceId);
  }

  [AccountBalance] GetAccountBalance() {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetAccountBalance($this.TYPE, $token.AccessToken);
  }

  [AccountBalance] GetAccountBalance([String]$token) {
    return $this.GetAccountBalance($this.TYPE, $token);
  }

  [AccountStatus] GetAccountStatus([String]$msisdn) {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetAccountStatus($this.TYPE, $token.AccessToken, $msisdn);
  }

  [AccountStatus] GetAccountStatus([String]$token, [String]$msisdn) {
    return $this.GetAccountStatus($this.TYPE, $token, $msisdn);
  }
}

class Disbursements : Product {
  hidden [ProductType] $TYPE = "disbursement"; # ! final !

  Disbursements([String]$baseUrl, [MoMoEnvironment]$environment, [String]$SubscriptionKey, [String]$apiUser, [String]$apiKey) : base($baseUrl, $environment, $SubscriptionKey, $apiUser, $apiKey) {
  }

  [System.Collections.ObjectModel.ObservableCollection[Token]] CreateToken() {
    return $this.CreateToken($this.TYPE);
  }

  [String] Transfer([float]$amount, [String]$currency, [String]$externalId, [String]$payeePartyId, [String]$payerMessage, [String]$payeeNote) {
    $token = $this.CreateToken($this.TYPE);
    return $this.Transfer($token.AccessToken, $amount, $currency, $externalId, $payeePartyId, $payerMessage, $payeeNote);
  }

  [String] Transfer([String]$token, [float]$amount, [String]$currency, [String]$externalId, [String]$payeePartyId, [String]$payerMessage, [String]$payeeNote) {
    return $this.Transfer($this.TYPE, $token, $amount, $currency, $externalId, $payeePartyId, $payerMessage, $payeeNote);
  }

  [Transfer] GetTransfer([String]$referenceId) {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetTransfer($token.AccessToken, $referenceId)
  }

  [Transfer] GetTransfer([String]$token, [String]$referenceId) {
    return $this.GetTransfer($this.TYPE, $token, $referenceId)
  }

  [AccountBalance] GetAccountBalance() {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetAccountBalance($token.AccessToken)
  }

  [AccountBalance] GetAccountBalance([String]$token) {
    return $this.GetAccountBalance($this.TYPE, $token);
  }

  [AccountStatus] GetAccountStatus([String]$msisdn) {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetAccountStatus($token.AccessToken, $msisdn)
  }

  [AccountStatus] GetAccountStatus([String]$token, [String]$msisdn) {
    return $this.GetAccountStatus($this.TYPE, $token, $msisdn);
  }
}

class Remittances : Product {
  hidden [ProductType] $TYPE = "remittance";

  Remittances([String]$baseUrl, [MoMoEnvironment]$environment, [String]$SubscriptionKey, [String]$apiUser, [String]$apiKey) : base ($baseUrl, $environment, $SubscriptionKey, $apiUser, $apiKey) {
  }

  [Token] CreateToken() {
    return $this.CreateToken($this.TYPE);
  }

  [String] Transfer([float]$amount, [String]$currency, [String]$externalId, [String]$payeePartyId, [String]$payerMessage, [String]$payeeNote) {
    $token = $this.CreateToken($this.TYPE);
    return $this.Transfer($token.AccessToken, $amount, $currency, $externalId, $payeePartyId, $payerMessage, $payeeNote);
  }

  [String] Transfer([String]$token, [float]$amount, [String]$currency, [String]$externalId, [String]$payeePartyId, [String]$payerMessage, [String]$payeeNote) {
    return $this.Transfer($this.TYPE, $token, $amount, $currency, $externalId, $payeePartyId, $payerMessage, $payeeNote);
  }

  [Transfer] GetTransfer([String]$referenceId) {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetTransfer($this.TYPE, $token.AccessToken, $referenceId);
  }

  [Transfer] GetTransfer([String]$token, [String]$referenceId) {
    return $this.GetTransfer($this.TYPE, $token, $referenceId);
  }

  [AccountBalance] GetAccountBalance() {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetAccountBalance($this.TYPE, $token.AccessToken);
  }

  [AccountBalance] GetAccountBalance([String]$token) {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetAccountBalance($this.TYPE, $token);
  }

  [AccountStatus] GetAccountStatus([String]$msisdn) {
    $token = $this.CreateToken($this.TYPE);
    return $this.GetAccountStatus($token.AccessToken, $msisdn);
  }

  [AccountStatus] GetAccountStatus([String]$token, [String]$msisdn) {
    return $this.GetAccountStatus($this.TYPE, $token, $msisdn);
  }
}

class SandboxProvisioning {
  [String]$baseUrl;
  [ApiUser[]]$users = @(); # SANDBOX users
  [String]$SubscriptionKey;
  [MoMoEnvironment]$environment;

  SandboxProvisioning([String]$SubscriptionKey, [String]$baseUrl) {
    $this.SubscriptionKey = $SubscriptionKey;
    $this.baseUrl = $baseUrl;
    $this.environment = [PsMoMo]::Environment.ToString();
  }
  [String] CreateApiUser() {
    return $this.CreateApiUser([PsMoMo]::CallbackHost);
  }
  [string] CreateApiUser([String]$CallbackHost) {
    [String]$referenceId = [Guid]::NewGuid().Guid; $user = $null
    $body = @{ providerCallbackHost = $CallbackHost }
    try {
      $user = [ApiUser][RestClient]::CreateApiUser($this.SubscriptionKey, $referenceId, $body)
      $user.CallbackHost = $CallbackHost
      $user.TargetEnvironment = $this.environment
      $this.users += $user;
    } catch {
      throw $_
    }
    return $user.UserId
  }
  [ApiUser] GetApiUser([String]$UserId) {
    $user = $null
    try {
      $user = [RestClient]::GetApiUser($this.SubscriptionKey, $UserId)
      $user.CallbackHost = [PsMoMo]::CallbackHost
      $user.TargetEnvironment = $this.environment
    } catch {
      throw $_
    }
    return $user
  }
  [ApiCredentials] GetApiCredentials([String]$UserId) {
    $key = [RestClient]::GetApiCredentials($this.SubscriptionKey, $UserId)
    if ($this.users.Where({ $_.UserId -eq $UserId })) { $this.SetApiKey($UserId, $key) }
    return [ApiCredentials]::new($UserId, $key);
  }
  hidden [string] SetApiKey([String]$UserId, [ApiKey]$apiKey) {
    [ApiUser[]]$_users = @();
    [ApiUser]$user = $this.users.Where({ $_.UserId -eq $UserId })[0]; $user.ApiKey = $apiKey;
    $this.users.Where({ $_.UserId -ne $UserId }).foreach({ $_users += $_ })
    $_users += $user; $this.users = $_users
    return $user.ApiKey.ToString()
  }
}

class RestClient {
  static [ValidateNotNullOrWhiteSpace()][string]$BaseUrl = [PsMoMo]::GetBaseUrl()
  static [ValidateNotNullOrEmpty()][hashtable]$DefaultHeaders
  static [int]$readTimeout = 60 # in seconds
  static [int]$connectTimeout = 60
  RestClient() {}
  RestClient([string]$baseUrl) {
    $this::BaseUrl = $baseUrl
  }
  RestClient([string]$baseUrl, [hashtable]$headers) {
    $this::BaseUrl = $baseUrl
    $this::DefaultHeaders = $headers
    # WIP # TODO: MAKE this property READ-ONLY (use: getters-setters)
  }
  static [ApiUser] CreateApiUser([string]$SubscriptionKey, [string]$xReferenceId, [hashtable]$body) {
    $url = "$([RestClient]::BaseUrl)/v1_0/apiuser"
    $headers = @{
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Reference-Id"            = $xReferenceId
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] CreateApiUser: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Post -Body ($body | ConvertTo-Json) -TimeoutSec ([RestClient]::connectTimeout) -Headers $headers -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 201, $st)
    return [ApiUser]::new($xReferenceId)
  }
  # Method to retrieve an API user by X-Reference-Id
  static [ApiUser] GetApiUser([string]$SubscriptionKey, [string]$xReferenceId) {
    $url = "$([RestClient]::BaseUrl)/v1_0/apiuser/$xReferenceId"
    $headers = @{
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Reference-Id"            = $xReferenceId
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] GetApiUser: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -TimeoutSec ([RestClient]::connectTimeout) -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 200, $st);
    return [ApiUser]::new($xReferenceId);
  }
  static [RequestToPay] CreateRequestToPay([string]$type, [string]$authorization, [string]$SubscriptionKey, [string]$referenceId, [MoMoEnvironment]$environment, [RequestToPayBodyRequest]$body) {
    $url = "$([RestClient]::BaseUrl)/$type/v1_0/requesttopay"
    $headers = @{
      "Authorization"             = $authorization
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Reference-Id"            = $referenceId
      "X-Target-Environment"      = $environment.ToString()
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] CreateRequestToPay: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Post -Body ($body | ConvertTo-Json) -Headers $headers -TimeoutSec ([RestClient]::connectTimeout) -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 202, $st)
    $re = $response.Content | ConvertFrom-Json
    $re | Format-List | Write-Verbose
    return New-Object RequestToPay -Property $re
  }
  # Method to get the status of a request to pay
  static [RequestToPay] GetRequestToPay([string]$type, [string]$authorization, [string]$SubscriptionKey, [string]$TargetEnvironment, [string]$referenceId) {
    #   Observable<Response<RequestToPay>> getRequestToPay(
    #   @Path("type") String type,
    #   @Path("referenceId") String referenceId
    $url = "$([RestClient]::BaseUrl)/$type/v1_0/requesttopay/$referenceId"
    $headers = @{
      "Authorization"             = $authorization
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Target-MoMoEnvironment"  = $TargetEnvironment
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] GetRequestToPay: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -TimeoutSec ([RestClient]::connectTimeout) -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 200, $st)
    $re = $response.Content | ConvertFrom-Json
    $re | Out-String | Write-Verbose
    return [RequestToPay]::new($re)
  }
  static [AccountBalance] GetAccountBalance([string]$type, [string]$authorization, [string]$SubscriptionKey) {
    $url = "$([RestClient]::BaseUrl)/$type/v1_0/account/balance"
    $headers = @{
      "Authorization"             = $authorization
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Target-Environment"      = [PsMoMo]::Environment.ToString()
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now
    Write-Host "[RestClient] GetAccountBalance: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 200, $st)
    $ab = $response.Content | ConvertFrom-Json
    return [AccountBalance]::new([xconvert]::Tofloat($ab.availableBalance), $ab.currency)
  }
  # Creates/regenerates a new API key for an API user
  static [ApiKey] GetApiCredentials([string]$SubscriptionKey, [string]$xReferenceId) {
    $url = "$([RestClient]::BaseUrl)/v1_0/apiuser/$xReferenceId/apikey"; $apiKey = $null
    $headers = @{
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Reference-Id"            = $xReferenceId # @Path
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] GetApiCredentials: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -TimeoutSec ([RestClient]::connectTimeout) -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 201, $st)
    $apiKey = [ApiKey]::new(($response.Content | ConvertFrom-Json).apiKey)
    $apiKey.environment = [PsMoMo]::Environment.ToString()
    return $apiKey
  }
  # Creates a token for a specific service type
  static [Token] CreateToken([string]$type, [string]$authorization, [string]$SubscriptionKey) {
    #  @Path("type") String type
    $url = "$([RestClient]::BaseUrl)/$type/token/"
    $headers = @{
      "Authorization"             = $authorization
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] CreateToken: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Post -Headers $headers -TimeoutSec 60 -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 200, $st)
    $re = $response.Content | ConvertFrom-Json
    return [token]::new($re.access_token, $re.expires_in, $re.token_type)
  }
  # Creates a transfer
  static [string] CreateTransfer([string]$type, [string]$authorization, [string]$SubscriptionKey, [string]$referenceId, [string]$TargetEnvironment, [TransferBodyRequest]$body) {
    #  @Path("type") String type,
    $url = "$([RestClient]::BaseUrl)/$type/v1_0/transfer"
    $headers = @{
      "Authorization"             = $authorization
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Reference-Id"            = $referenceId
      "X-Target-MoMoEnvironment"  = $TargetEnvironment
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] CreateTransfer: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Post -Body ($body | ConvertTo-Json) -Headers $headers -TimeoutSec ([RestClient]::connectTimeout) -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 202, $st)
    return $referenceId
  }

  # Method to get the status of a transfer
  static [Transfer] GetTransfer([string]$type, [string]$authorization, [string]$SubscriptionKey, [string]$TargetEnvironment, [string]$referenceId) {
    #   @Path("type") String type,
    #   @Path("referenceId") String referenceId
    $url = "$([RestClient]::BaseUrl)/$type/v1_0/transfer/$referenceId"
    $headers = @{
      "Authorization"             = $authorization
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Target-MoMoEnvironment"  = $TargetEnvironment
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] GetTransfer: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -TimeoutSec ([RestClient]::connectTimeout) -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 200, $st)
    $tr = $response.Content | ConvertFrom-Json
    $tr | Out-String | Write-Verbose
    return [transfer]::new($tr)
  }

  # Method to get account status
  static [AccountStatus] GetAccountStatus([string]$type, [string]$authorization, [string]$SubscriptionKey, [string]$TargetEnvironment, [string]$accountHolderIdType, [string]$accountHolderId) {
    #  @Path("type") String type,
    #  @Path("accountHolderIdType") String accountHolderIdType,
    #  @Path("accountHolderId") String accountHolderId
    $url = "$([RestClient]::BaseUrl)/$type/v1_0/accountholder/$accountHolderIdType/$accountHolderId/active"
    $headers = @{
      "Authorization"             = $authorization
      "Ocp-Apim-Subscription-Key" = $SubscriptionKey
      "X-Target-MoMoEnvironment"  = $TargetEnvironment
      "Content-Type"              = "application/json"
    }
    $st = [datetime]::Now;
    Write-Host "[RestClient] GetAccountStatus: $url" -f Green
    $response = Invoke-WebRequest -Uri $url -Method Get -Headers $headers -TimeoutSec ([RestClient]::connectTimeout) -SkipHttpErrorCheck -Verbose:$false
    [RestClient]::EvaluateResponse($response, 200, $st)
    $response.Content | Out-String | Write-Verbose
    return $response.Content
  }
  static [void] EvaluateResponse([System.Object]$response, [int]$OKCode, [datetime]$startTime) {
    $code = $response.StatusCode; $desc = $response.StatusDescription
    $t_es = "T: {0} Seconds " -f [int]([datetime]::ParseExact($response.Headers.Date, "ddd, dd MMM yyyy HH:mm:ss GMT", [System.Globalization.CultureInfo]::InvariantCulture) - $startTime).TotalSeconds
    $context = "Context : {0}" -f $response.Headers.'Request-Context'
    ($sth, $color) = switch ($true) {
      $($code -match "^1\d\d") { "[Information]", "Blue"; break }
      $($code -match "^2\d\d") { "[Success]", "Green"; break }
      $($code -match "^3\d\d") { "[Redirection]", "Yellow"; break }
      $($code -match "^4\d\d") { "[Client Error]", "Red"; break }
      $($code -match "^5\d\d") { "[Server Error]", "Magenta"; break }
      default { "Unknown_status", "Gray" }
    }
    Write-Host "$sth " -f $color -NoNewline; Write-Host $t_es -NoNewline;
    Write-Host "Code : $code " -NoNewline -f $color
    Write-Host $context; $message = $desc + " " + ($response.Content | ConvertFrom-Json).message
    Write-Host " Message:" -NoNewline; Write-Host " $desc " -f $color;
    if ($code -ne $OKCode) {
      throw [RequestException]::new($response.StatusCode, $message);
    }
  }
}

class PsMoMo {
  hidden [version] $_Version = (& {
      $this.PsObject.properties.add([psscriptproperty]::new('Version', { return [version]::new("0.1.0") }, { throw [SetValueException]::new("Version is read only") }))
    }
  )
  static [MoMoEnvironment] $environment = (Get-Env NEXT_PUBLIC_MTN_ENVIRONMENT).value;
  static [ValidateNotNullOrWhiteSpace()][string] $CallbackHost = (Get-Env NEXT_PUBLIC_MTN_CALLBACK_HOST).value;

  PsMoMo() { [clitools]::writBanner() }
  PsMoMo([MoMoEnvironment]$environmen) { $this::environment = $environmen }

  [SandboxProvisioning] CreateSandboxProvisioning([String]$SubscriptionKey) {
    return [SandboxProvisioning]::new($SubscriptionKey, [PsMoMo]::GetBaseUrl());
  }
  [Collections] CreateCollections([String]$apiUser, [String]$apiKey) {
    return $this.CreateCollections($this.GetSubscriptionKey("collection"), $apiUser, $apiKey)
  }
  [Collections] CreateCollections([String]$SubscriptionKey, [String]$apiUser, [String]$apiKey) {
    return [Collections]::new([PsMoMo]::GetBaseUrl(), $this::environment, $SubscriptionKey, $apiUser, $apiKey);
  }
  [Disbursements] CreateDisbursements([String]$SubscriptionKey, [String]$apiUser, [String]$apiKey) {
    return [Disbursements]::new([PsMoMo]::GetBaseUrl(), $this::environment, $SubscriptionKey, $apiUser, $apiKey);
  }
  [Remittances] CreateRemittances([String]$SubscriptionKey, [String]$apiUser, [String]$apiKey) {
    return [Remittances]::new([PsMoMo]::GetBaseUrl(), $this::environment, $SubscriptionKey, $apiUser, $apiKey);
  }
  [String] GetSubscriptionKey([ProductType]$type) {
    $name = "NEXT_PUBLIC_MTN_" + $Type.ToString().ToUpper() + "_PRIMARY_KEY"
    return (Get-Env $name).value
  }
  static [String] GetBaseUrl() {
    $cenv = [PsMoMo]::Environment.ToString().ToString();
    $name = "NEXT_PUBLIC_MTN_" + ($cenv -eq "SANDBOX" ? "BASE_URL_SANDBOX" : "BASE_URL_PRODUCTION")
    $value = (Get-Env $name).value; if ([string]::IsNullOrWhiteSpace($value)) { throw "$cenv base url environment variable not set" }
    return $value.Trim('"')
  }
}
#endregion Classes

#region TypeAccelerator
# .DESCRIPTION
# Types that will be available to users when they import the module.
$typestoExport = @(
  [PsMoMo],
  [restclient],
  [MoMoEnvironment]
)
$TypeAcceleratorsClass = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
foreach ($type in $typestoExport) {
  if ($type.FullName -in $TypeAcceleratorsClass::Get.Keys) {
    $Message = @(
      "Unable to register type accelerator '$($type.FullName)'"
      'Accelerator already exists.'
    ) -join ' - '

    throw [System.Management.Automation.ErrorRecord]::new(
      [System.InvalidOperationException]::new($Message),
      'TypeAcceleratorAlreadyExists',
      [System.Management.Automation.ErrorCategory]::InvalidOperation,
      $Type.FullName
    )
  }
}
# Add type accelerators for every exportable type.
foreach ($type in $typestoExport) {
  $TypeAcceleratorsClass::Add($type.FullName, $Type)
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  foreach ($type in $typestoExport) {
    $TypeAcceleratorsClass::Remove($type.FullName)
  }
}.GetNewClosure();
#endregion typeAccelerators

$Private = Get-ChildItem ([IO.Path]::Combine($PSScriptRoot, 'Private')) -Filter "*.ps1" -ErrorAction SilentlyContinue
$Public = Get-ChildItem ([IO.Path]::Combine($PSScriptRoot, 'Public')) -Filter "*.ps1" -ErrorAction SilentlyContinue
foreach ($file in ($Public, $Private)) {
  Try {
    if ([string]::IsNullOrWhiteSpace($file.fullname)) { continue }
    . "$($file.fullname)"
  } Catch {
    Write-Warning "Failed to import function $($file.BaseName): $_"
    $host.UI.WriteErrorLine($_)
  }
}

$Param = @{
  Function = $Public.BaseName
  Variable = 'localizedData'
  Cmdlet   = "*"
  Alias    = "*"
}
Export-ModuleMember @Param -Verbose