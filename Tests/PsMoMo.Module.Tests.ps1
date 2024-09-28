# !bin/pwsh
# PsMoMo.Module.Tests.ps1
Describe "Module tests: $($([Environment]::GetEnvironmentVariable($env:RUN_ID + 'ProjectName')))" -Tag 'Module' {
  Context " Confirm files are valid Powershell syntax" {
    $_scripts = $(Get-Item -Path "<BuildOutpt_FullName>").GetFiles(
      "*", [System.IO.SearchOption]::AllDirectories
    ).Where({ $_.Extension -in ('.ps1', '.psd1', '.psm1') })
    $testCase = $_scripts | ForEach-Object { @{ file = $_ } }
    It "Script <file> Should have valid Powershell sysntax" -TestCases $testCase {
      param($file) $contents = Get-Content -Path $file.fullname -ErrorAction Stop
      $errors = $null; [void][System.Management.Automation.PSParser]::Tokenize($contents, [ref]$errors)
      $errors.Count | Should -Be 0
    }
  }
  Context " Confirm there are no duplicate function names in private and public folders" {
    It ' Should have no duplicate functions' {
      $Publc_Dir = Get-Item -Path ([IO.Path]::Combine("<BuildOutpt_FullName>", 'Public'))
      $Privt_Dir = Get-Item -Path ([IO.Path]::Combine("<BuildOutpt_FullName>", 'Private'))
      $funcNames = @(); Test-Path -Path ([string[]]($Publc_Dir, $Privt_Dir)) -PathType Container -ErrorAction Stop
      $Publc_Dir.GetFiles("*", [System.IO.SearchOption]::AllDirectories) + $Privt_Dir.GetFiles("*", [System.IO.SearchOption]::AllDirectories) | Where-Object { $_.Extension -eq '.ps1' } | ForEach-Object { $funcNames += $_.BaseName }
      $($funcNames | Group-Object | Where-Object { $_.Count -gt 1 }).Count | Should -BeLessThan 1
    }
  }
}