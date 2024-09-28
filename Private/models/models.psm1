class Payer {
  [String]$partyIdType;
  [String]$partyId;

  Payer() {}

  Payer([String]$partyId) {
    $this.partyId = $partyId;
    $this.partyIdType = "MSISDN";
  }
}

class Token {
  [ValidateNotNullOrWhiteSpace()][String]$accessToken
  [ValidateNotNullOrWhiteSpace()][String]$tokenType
  [ValidateNotNullOrEmpty()][int]$expiresIn

  Token() {}

  Token([string]$accessToken, [int]$expiresIn, [string]$tokenType) {
    $this.accessToken = $accessToken
    $this.expiresIn = $expiresIn
    $this.tokenType = $tokenType
  }
  [string] ToJson() {
    return ConvertTo-Json -InputObject @{
      "access_token" = $this.accessToken
      "token_type"   = $this.tokenType
      "expires_in"   = $this.expiresIn
    }
  }
  [string] ToString() {
    return $this.ToJson()
  }

  static [Token] FromJson([string]$jsonString) {
    $json = $jsonString | ConvertFrom-Json
    $token = [Token]::new()
    $token.accessToken = $json.access_token
    $token.tokenType = $json.token_type
    $token.expiresIn = $json.expires_in
    return $token
  }
}

class Payee {
  [String]$partyIdType;
  [String]$partyId;
  Payee() {}
}

class ApiKey {
  [String]$apiKey;
  [ValidateSet("PRODUCTION", "SANDBOX")][string] $environment
  ApiKey() {}
  ApiKey([String]$apiKey) {
    $this.apiKey = $apiKey;
  }
  [string] ToString() {
    return $this.apiKey
  }
}

class ApiCredentials {
  [String]$user;
  [String]$key;

  ApiCredentials() {}
  ApiCredentials([String]$user, [String]$key) {
    $this.user = $user;
    $this.key = $key;
  }
}

class RequestToPay {
  [String]$reason;
  [float] $amount;
  [String]$status;
  [String]$financialTransactionId;
  [String]$currency;
  [String]$externalId;
  [Payer] $payer;
  [String]$payerMessage;
  [String]$payeeNote;
}


class RequestToPayBodyRequest {
  [float]$amount
  [string]$currency
  [string]$externalId
  [Payer]$payer
  [string]$payerMessage
  [string]$payeeNote
  RequestToPayBodyRequest() {}
  RequestToPayBodyRequest([float]$amount, [String]$currency, [String]$externalId, [String]$payerPartyId, [String]$payerMessage, [String]$payeeNote) {
    $this.amount = $amount;
    $this.currency = $currency;
    $this.externalId = $externalId;
    $this.payer = [Payer]::new($payerPartyId);
    $this.payerMessage = $payerMessage;
    $this.payeeNote = $payeeNote;
  }
}

class AccountStatus {
  [boolean]$result;
  AccountStatus() {}
  AccountStatus([boolean]$result) {
    $this.result = $result
  }
}
class AccountBalance {
  [float]$availableBalance;
  [String]$currency;
  AccountBalance() {}
  AccountBalance([float]$availableBalance, [String]$currency) {
    $this.availableBalance = $availableBalance
    $this.currency = $currency
  }
}

class Transfer {
  [String]$reason;
  [float]$amount;
  [String]$status;
  [String]$financialTransactionId;
  [String]$currency;
  [String]$externalId;
  [Payee]$payee;
  [String]$payerMessage;
  [String]$payeeNote;

  Transfer() {}

  Transfer([float]$amount, [String]$currency, [String]$externalId, [String]$payeePartyId, [String]$payerMessage, [String]$payeeNote) {
    $this.amount = $amount;
    $this.currency = $currency;
    $this.externalId = $externalId;
    $this.payee = [Payee]::new($payeePartyId);
    $this.payerMessage = $payerMessage;
    $this.payeeNote = $payeeNote;
  }
}

class TransferBodyRequest {
  [float]$amount;
  [String]$currency;
  [String]$externalId;
  [Payee]$payee;
  [String]$payerMessage;
  [String]$payeeNote;

  TransferBodyRequest() {}

  TransferBodyRequest([String]$amount, [String]$currency, [String]$externalId, [String]$payerPartyId, [String]$payerMessage, [String]$payeeNote) {
    $this.amount = [xConvert]::Tofloat($amount);
    $this.currency = $currency;
    $this.externalId = $externalId;
    $this.payee = [Payee]::new($payerPartyId);
    $this.payerMessage = $payerMessage;
    $this.payeeNote = $payeeNote;
  }
}

class ApiUser {
  [string]$UserId;
  [String]$CallbackHost;
  [ApiKey]$ApiKey;
  [String]$TargetEnvironment;

  ApiUser() {}
  ApiUser([string]$Id) { $this.UserId = $Id }
  ApiUser([string]$Id, [ApiKey]$ApiKey) {
    $this.UserId = $Id
    $this.ApiKey = $ApiKey
  }
  ApiUser([String]$CallbackHost, [String]$TargetEnvironment) {
    $this.CallbackHost = $CallbackHost;
    $this.TargetEnvironment = $TargetEnvironment;
  }
}

class xConvert {
  static[float] Tofloat([string]$amount) {
    $floatAmount = 0.0
    if ([float]::TryParse($amount, [ref]$floatAmount)) {
      return $floatAmount
    } else {
      throw "Conversion failed. Invalid number string."
    }
  }
}