﻿class consoleTools {
  static [void] writBanner() {
    Write-Host @'
     .  .              .  .                          .  .              .  .
    [#BB#B~          .G#BB#]                        P#BB#G:          ~B#BB#]
    [######5.       !######]                        G######?        J######]
    [#######B~     Y#######]        .:~!!~:.        G#######G:    .G#######]        .^~!!~:.
    [#########5. :B########]     .JG########G?.     G#########?  !#########]     ^YB########P7
    [####BG####BY####YP####]    J#####BGGB#####J    G####GB####G5####JB####]   .P#####BGGB####B!
    [####P 7########! Y####]   5####5:    :5####Y   G####J Y#######B: B####]   B####?.    ^G####!
    [####G  :P####G.  Y####]  .####P        G####.  G####J  ~B####Y   B####]  !####?       .####G
    [####G    !??7    Y####]  .####G       .B####.  G####J   .7??~    B####]  ~####Y       ^####P
    [####G            Y####]   ?####G!...:7B####7   G####J            B####]   5####P~...:?#####:
    [####G            5####]    ~B############G~    G####Y            B####]    ?#############P:
    [GPPGY            ?GPPGJ      ~YGB####BGY^      YGPPG7            5GPPG!     .!5B#####BGJ:
                                     ..::.                                           ..::.
'@ -f Yellow
    Write-Host @'

    █▀▀ █▀█ █▀█ █▀▄▀█   █▀▄▀█ ▀█▀ █▄░█
    █▀░ █▀▄ █▄█ █░▀░█   █░▀░█ ░█░ █░▀█

'@ -f DarkYellow;
  }
}


# .SYNOPSIS
#   tests The banner
function Test-MomoBanner {
  [consoleTools]::writBanner()
}
Export-ModuleMember -Function "Test-MomoBanner"