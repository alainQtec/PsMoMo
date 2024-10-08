﻿@{
    ModuleName    = 'PsMoMo'
    ModuleVersion = [System.Management.Automation.SemanticVersion]::new(0, 1, 1)
    ReleaseNotes  = @"
# Changelog`n`n

* Added Import from the same Github repo.
  Now you don't need to specify the file path if It's in the same repo.

`n`n***`n`n# Install guide:`n`n
1. [Click here](https://github.com/alainQtec/PsMoMo/releases/download/v<versionToDeploy>/PsMoMo.zip) to download the *PsMoMo.zip* file attached to the release.
2. **If on Windows**: Right-click the downloaded zip, select Properties, then unblock the file.
    > _This is to prevent having to unblock each file individually after unzipping._
3. Unzip the archive.
4. (Optional) Place the module folder somewhere in your ``PSModulePath``.
    > _You can view the paths listed by running the environment variable ```$Env:PSModulePath``_
5. Import the module, using the full path to the PSD1 file in place of ``PsMoMo`` if the unzipped module folder is not in your ``PSModulePath``:
    ``````powershell
    # In Env:PSModulePath
    Import-Module PsMoMo

    # Otherwise, provide the path to the manifest:
    Import-Module -Path Path\to\PsMoMo\<versionToDeploy>\PsMoMo.psd1
    ``````
"@
}