$sshKey = "C:\Users\Hype\.ssh\id_rsa"
$hostUrl = "153.92.8.198"
$port = "65002"
$user = "u731410318"
$remoteDir = "/home/u731410318/domains/cellanoma.my.id/public_html/zenvi/api"
$localBackend = "D:\zenvi\backend"

Write-Host "Mengunggah 4 file perubahan ke server Hostinger..." -ForegroundColor Cyan

# 1. Upload Migration
scp -o StrictHostKeyChecking=no -P $port -i $sshKey "$localBackend\database\migrations\2026_08_01_021336_add_schedule_fields_to_companies_table.php" "$user@${hostUrl}:${remoteDir}/database/migrations/"

# 2. Upload Model
scp -o StrictHostKeyChecking=no -P $port -i $sshKey "$localBackend\app\Models\Company.php" "$user@${hostUrl}:${remoteDir}/app/Models/"

# 3. Upload CompanyController
scp -o StrictHostKeyChecking=no -P $port -i $sshKey "$localBackend\app\Http\Controllers\Api\CompanyController.php" "$user@${hostUrl}:${remoteDir}/app/Http/Controllers/Api/"

# 4. Upload ShiftController
scp -o StrictHostKeyChecking=no -P $port -i $sshKey "$localBackend\app\Http\Controllers\Api\ShiftController.php" "$user@${hostUrl}:${remoteDir}/app/Http/Controllers/Api/"

Write-Host "File berhasil diunggah! Sekarang menjalankan migrasi database..." -ForegroundColor Yellow

# Run php artisan migrate
ssh -o StrictHostKeyChecking=no -p $port -i $sshKey $user@$hostUrl "cd $remoteDir && php artisan migrate"

Write-Host "Selesai! Backend sudah terbarui dan termigrasi." -ForegroundColor Green
