# !bin/pwsh
# PsMoMo.Features.Tests.ps1

BeforeAll {
  $Modversion = '<Modversion>'
  $BuildOutpt = Get-Item -Path '<BuildOutpt_FullName>'
  if (![string]::IsNullOrWhiteSpace($Modversion)) {
    Import-Module $BuildOutpt.Parent.FullName -Version $Modversion
  } else {
    Import-Module $BuildOutpt.FullName
  }
  # Initialize the PsMoMo object
  $script:mm = [PsMoMo]::new()
}
Describe "PsMoMo Module Tests" {
  Context "Sandbox Provisioning" {
    BeforeAll {
      $script:prov = $mm.CreateSandboxProvisioning($mm.GetSubscriptionKey("collection"))
      $script:userId = "e2567cb4-c963-4115-8691-1e1249213f0f"
    }

    It "Should get API credentials" {
      $cr = $prov.GetApiCredentials($userId)
      $cr | Should -Not -BeNullOrEmpty
      $cr.user | Should -Be $userId
      $cr.key | Should -Not -BeNullOrEmpty
      # ie: @Gets apikey & create user credentials [ApiCredentials]
      # > echo $cr gets some thing like:
      # user                                  key
      # ----                                  ---
      # e2567cb4-c963-4115-8691-1e1249213f0f  43b3c897a3934c17ab05ebdc66c52478
    }

    It "Should create a new API user" {
      $newUserId = $prov.CreateApiUser()
      $newUserId | Should -HaveLength 36
    }
  }

  Context "Collections" {
    BeforeAll {
      $cr = $prov.GetApiCredentials($userId)
      $script:coll = $mm.CreateCollections($cr.user, $cr.key)
    }

    It "Should create a token" {
      $token = $coll.CreateToken()
      $token | Should -Not -BeNullOrEmpty
    }

    It "Should perform RequestToPay" {
      $req = $coll.requestToPay(900, "RWF", "testId", "0022505777777", "testMSG", "testNote")
      $req | Should -Not -BeNullOrEmpty
      $req.referenceId | Should -Not -BeNullOrEmpty

      $_req = $coll.GetRequestToPay($req.referenceId)
      $_req | Should -Not -BeNullOrEmpty
    }

    It "Should get account balance" {
      $_bal = $coll.GetAccountBalance()
      $_bal | Should -Not -BeNullOrEmpty
    }

    It "Should get account status" {
      $stat = $coll.GetAccountStatus("46733123453")
      $stat | Should -Not -BeNullOrEmpty
    }
  }

  Context "Disbursements" {
    BeforeAll {
      $sk = $mm.GetSubscriptionKey("disbursement")
      $prov = $mm.CreateSandboxProvisioning($sk)
      $cr = $prov.GetApiCredentials()
      $script:ds = $mm.createDisbursements($sk, $cr.user, $cr.key)
    }

    It "Should create a token" {
      $tk = $ds.CreateToken()
      $tk | Should -Not -BeNullOrEmpty
    }

    It "Should perform a transfer" {
      $tr = $ds.Transfer(900, "RWF", "test", "0022505777777", "test", "test")
      $tr | Should -Not -BeNullOrEmpty
      $tr.referenceId | Should -Not -BeNullOrEmpty

      $tp = $ds.GetTransfer($tr.referenceId)
      $tp | Should -Not -BeNullOrEmpty
    }

    It "Should get account balance" {
      $bal = $ds.getAccountBalance()
      $bal | Should -Not -BeNullOrEmpty
    }

    It "Should get account status" {
      $stat = $ds.GetAccountStatus("46733123453")
      $stat | Should -Not -BeNullOrEmpty
    }
  }

  Context "Remittances" {
    BeforeAll {
      $sk = $mm.GetSubscriptionKey("remittance")
      $cr = $prov.GetApiCredentials()
      $script:rm = $mm.createRemittances($sk, $cr.user, $cr.key)
    }

    It "Should create a token" {
      $token = $rm.createToken()
      $token | Should -Not -BeNullOrEmpty
    }

    It "Should perform a transfer" {
      $transfer = $rm.Transfer(900, "EUR", "test", "0022505777777", "test", "test")
      $transfer | Should -Not -BeNullOrEmpty

      $tp = $rm.GetTransfer($rm.referenceId)
      $tp | Should -Not -BeNullOrEmpty
    }

    It "Should get account balance" {
      $_bal = $rm.GetAccountBalance()
      $_bal | Should -Not -BeNullOrEmpty
    }

    It "Should get account status" {
      $stat = $rm.GetAccountStatus("46733123453")
      $stat | Should -Not -BeNullOrEmpty
    }
  }
}