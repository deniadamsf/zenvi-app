<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Shift;
use Illuminate\Support\Facades\Storage;
use Carbon\Carbon;

class DeleteOldSelfies extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'shift:delete-old-selfies';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Delete shift selfie photos that are older than 7 days to save storage';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $this->info('Starting to delete old selfies...');
        $count = 0;

        $shifts = Shift::where('created_at', '<', Carbon::now()->subDays(7))
            ->whereNotNull('selfie_path')
            ->get();

        foreach ($shifts as $shift) {
            if (Storage::disk('public')->exists($shift->selfie_path)) {
                Storage::disk('public')->delete($shift->selfie_path);
            }
            $shift->selfie_path = null;
            $shift->save();
            $count++;
        }

        $this->info("Deleted $count old selfie(s) successfully.");
    }
}
