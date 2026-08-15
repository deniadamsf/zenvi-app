<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class EmployeePermission extends Model
{
    use HasFactory;

    protected $fillable = [
        'company_id',
        'user_id',
        'type',
        'permission_date',
        'estimated_arrival_time',
        'reason',
        'attachment_path',
        'attachment_deleted_at',
        'status',
        'reviewed_by',
        'reviewed_at',
        'rejection_note',
    ];

    protected $casts = [
        'permission_date' => 'date:Y-m-d',
        'attachment_deleted_at' => 'datetime',
        'reviewed_at' => 'datetime',
    ];

    protected $appends = [
        'attachment_url',
        'is_attachment_expired',
        'type_label',
        'status_label',
    ];

    public function getAttachmentUrlAttribute()
    {
        if ($this->attachment_path && file_exists(public_path($this->attachment_path))) {
            return url($this->attachment_path);
        }
        return null;
    }

    public function getIsAttachmentExpiredAttribute()
    {
        return $this->attachment_deleted_at !== null || ($this->attachment_path && !file_exists(public_path($this->attachment_path)));
    }

    public function getTypeLabelAttribute()
    {
        return $this->type === 'late' ? 'Izin Telat Masuk' : 'Izin Libur / Tidak Masuk';
    }

    public function getStatusLabelAttribute()
    {
        switch ($this->status) {
            case 'approved':
                return 'Disetujui';
            case 'rejected':
                return 'Ditolak';
            case 'pending':
            default:
                return 'Menunggu Persetujuan';
        }
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function reviewer()
    {
        return $this->belongsTo(User::class, 'reviewed_by');
    }
}
