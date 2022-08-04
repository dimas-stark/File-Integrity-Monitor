Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}
Function Erase-Baseline-If-Already-Exists() {
    $baselineExists = Test-Path -Path .\baseline.txt

    if ($baselineExists) {
        # Hapus Jika ada
        Remove-Item -Path .\baseline.txt
    }
}


Write-Host ""
Write-Host "Apa yang ingin kamu lakukan?"
Write-Host ""
Write-Host "    A) Mengumpulkan data hash baru?"
Write-Host "    B) Mulai monitoring data yang ada?"
Write-Host ""
$response = Read-Host -Prompt "Masukkan 'A' atau 'B'"
Write-Host ""

if ($response -eq "A".ToUpper()) {
    # Hapus baseline.txt jika ada
    Erase-Baseline-If-Already-Exists

    # Mengkalkulasi hash dari file yang ada
    $files = Get-ChildItem -Path .\Files

    # For each file, kumpulkan dan masukkan ke baseline.txt
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append
    }
    
}

elseif ($response -eq "B".ToUpper()) {
    
    $fileHashDictionary = @{}

    # Load file|hash dari baseline.txt dan simpan ke dictionary
    $filePathsAndHashes = Get-Content -Path .\baseline.txt
    
    foreach ($f in $filePathsAndHashes) {
         $fileHashDictionary.add($f.Split("|")[0],$f.Split("|")[1])
    }

    Write-Host "   Mulai monitoring data!" -ForegroundColor Green -BackgroundColor Black
    Write-Host "   Notifikasi akan muncul jika ada masalah integritas pada data." -ForegroundColor Green -BackgroundColor Black

    # Mulai monitoring!
    while ($true) {
        Start-Sleep -Seconds 1
        $files = Get-ChildItem -Path .\Files

        # For each file, kumpulkan dan masukkan ke baseline.txt
        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName
            #"$($hash.Path)|$($hash.Hash)" | Out-File -FilePath .\baseline.txt -Append

            # Notifikasi jika ada file yang dibuat
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                Write-Host "$($hash.Path.Split("\")[5]) baru saja dibuat!" -ForegroundColor Green
            }
            else {

                # Notif jika ada file yang berubah/update
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                }
                else {
                    Write-Host "$($hash.Path.Split("\")[5]) telah berubah/update!" -ForegroundColor Yellow
                }
            }
        }
        #Notifikasi jika ada file dihapus
        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                Write-Host "$($key.Split("\")[5]) telah dihapus!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
    }

}