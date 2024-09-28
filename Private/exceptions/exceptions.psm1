using namespace System.Management.Automation;
enum FailureReason {
  PAYEE_NOT_FOUND
  PAYER_NOT_FOUND
  NOT_ALLOWED
  NOT_ALLOWED_TARGET_ENVIRONMENT
  INVALID_CALLBACK_URL_HOST
  INVALID_CURRENCY
  SERVICE_UNAVAILABLE
  INTERNAL_PROCESSING_ERROR
  NOT_ENOUGH_FUNDS
  PAYER_LIMIT_REACHED
  PAYEE_NOT_ALLOWED_TO_RECEIVE
  PAYMENT_NOT_APPROVED
  RESOURCE_NOT_FOUND
  APPROVAL_REJECTED
  EXPIRED
  TRANSACTION_CANCELED
  RESOURCE_ALREADY_EXIST
  LOW_BALANCE_OR_PAYEE_LIMIT_REACHED_OR_NOT_ALLOWED
}

class RequestException : System.Exception {
  [int]$code
  hidden [FailureReason] $_FailureReason
  RequestException([int]$code, [string]$message) : base($message) {
    $this.code = $code
    $this.PsObject.properties.Add([psscriptproperty]::new('FailureReason',
        {
          $this._FailureReason = $this.ParseMessage($this.Message)
          return $this._FailureReason
        },
        {
          throw [SetValueException]::new("FailureReason is read only")
        }
      )
    )
  }
  [int] GetCode() {
    return $this.code
  }
  hidden [FailureReason] ParseMessage([string]$message) {
    # WIP # TODO: Add implementation
    return '######'
  }
}