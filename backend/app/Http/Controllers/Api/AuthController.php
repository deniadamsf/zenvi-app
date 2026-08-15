<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class AuthController extends Controller
{
    /**
     * Authenticate or register user via Google Token from Flutter
     */
    public function googleLogin(Request $request)
    {
        $request->validate([
            'token' => 'required|string', // Token (idToken) from Google Sign In on Flutter
            'intended_role' => 'nullable|string|in:Owner,Employee',
        ]);

        try {
            // Validate the idToken directly with Google
            $response = Http::get('https://oauth2.googleapis.com/tokeninfo?id_token=' . $request->token);
            
            if ($response->failed()) {
                throw new \Exception('Token tidak valid: ' . $response->body());
            }

            $googleUser = (object) $response->json();
            
            // Find or create the user
            // Google 'sub' is the unique Google ID
            $googleId = $googleUser->sub ?? null;
            $email = $googleUser->email ?? null;
            $name = $googleUser->name ?? 'User';

            if (!$googleId || !$email) {
                throw new \Exception('Data Google tidak lengkap');
            }

            $user = User::where('google_id', $googleId)->orWhere('email', $email)->first();

            if (!$user) {
                $role = $request->intended_role ?? 'Owner';
                
                // Register new user
                $user = User::create([
                    'google_id' => $googleId,
                    'name' => $name,
                    'email' => $email,
                    'role' => $role,
                    'is_approved' => $role === 'Owner', // Owners are auto-approved
                ]);
            } else {
                // Update google_id if it's missing (e.g. they registered previously another way)
                if (!$user->google_id) {
                    $user->update(['google_id' => $googleId]);
                }
            }

            // Create Sanctum Token
            $token = $user->createToken('auth_token')->plainTextToken;

            return response()->json([
                'status' => 'success',
                'message' => 'Login successful',
                'data' => [
                    'user' => $user->load(['company', 'branch']),
                    'access_token' => $token,
                    'token_type' => 'Bearer',
                ]
            ]);
            
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid Google Token or Authentication Failed.',
                'error' => $e->getMessage()
            ], 401);
        }
    }

    /**
     * Get authenticated user profile with company and branch
     */
    public function me(Request $request)
    {
        $user = $request->user()->load(['company', 'branch']);
        return response()->json([
            'status' => 'success',
            'data' => [
                'user' => $user,
            ]
        ]);
    }

    /**
     * Logout user (Revoke token)
     */
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Successfully logged out'
        ]);
    }
}
