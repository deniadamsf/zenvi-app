<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;

class User extends Authenticatable implements FilamentUser
{
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'google_id',
        'company_id',
        'branch_id',
        'role',
        'job_title',
        'permissions',
        'is_approved',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The attributes that should be cast.
     *
     * @var array<string, string>
     */
    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'is_approved' => 'boolean',
        'permissions' => 'array',
    ];

    public function hasPermission(string $permission): bool
    {
        if ($this->role === 'Owner') {
            return true;
        }
        
        $perms = $this->permissions;
        if (is_array($perms) && isset($perms[$permission])) {
            $val = $perms[$permission];
            return $val === true || $val === 1 || $val === '1' || $val === 'true';
        }

        // Default permissions for Employee role if not explicitly set in JSON
        $title = strtolower($this->job_title ?? '');

        if ($permission === 'can_access_pos') {
            if (str_contains($title, 'kapster') || str_contains($title, 'terapis') || str_contains($title, 'dapur') || str_contains($title, 'gudang') || str_contains($title, 'staff')) {
                return false;
            }
            return true;
        }

        if ($permission === 'can_access_stock') {
            if (str_contains($title, 'dapur') || str_contains($title, 'barista') || str_contains($title, 'gudang') || str_contains($title, 'koki')) {
                return true;
            }
            return false;
        }

        if ($permission === 'can_access_reservations') {
            if (str_contains($title, 'dapur') || str_contains($title, 'koki') || str_contains($title, 'gudang')) {
                return false;
            }
            return true;
        }

        if ($permission === 'can_access_expenses') {
            if (str_contains($title, 'kasir') || str_contains($title, 'admin')) {
                return true;
            }
            return false;
        }

        return false;
    }

    public function company()
    {
        return $this->belongsTo(Company::class);
    }

    public function branch()
    {
        return $this->belongsTo(Branch::class);
    }

    public function shifts()
    {
        return $this->hasMany(Shift::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function devices()
    {
        return $this->hasMany(UserDevice::class);
    }

    public function inAppNotifications()
    {
        return $this->hasMany(InAppNotification::class);
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->role === 'Owner' || $this->role === 'Admin';
    }
}
