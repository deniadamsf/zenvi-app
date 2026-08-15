<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Branch;
use Illuminate\Http\Request;

class BranchController extends Controller
{
    public function index(Request $request)
    {
        $branches = Branch::where('company_id', $request->user()->company_id)
            ->withCount(['shifts as active_shifts_count' => function ($q) {
                $q->where('status', 'active');
            }])
            ->get();
        return response()->json(['data' => $branches]);
    }

    public function publicList($companyId)
    {
        $branches = Branch::where('company_id', $companyId)->select('id', 'name', 'latitude', 'longitude', 'radius_meters')->get();
        return response()->json(['data' => $branches]);
    }

    public function store(Request $request)
    {
        if ($request->user()->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius_meters' => 'required|integer|min:1',
        ]);

        $branch = Branch::create([
            'company_id' => $request->user()->company_id,
            'name' => $request->name,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'radius_meters' => $request->radius_meters,
        ]);

        return response()->json(['message' => 'Cabang berhasil ditambahkan', 'data' => $branch], 201);
    }

    public function update(Request $request, $id)
    {
        if ($request->user()->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $request->validate([
            'name' => 'required|string|max:255',
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric',
            'radius_meters' => 'required|integer|min:1',
        ]);

        $branch = Branch::where('company_id', $request->user()->company_id)->findOrFail($id);

        $branch->update([
            'name' => $request->name,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'radius_meters' => $request->radius_meters,
        ]);

        return response()->json(['message' => 'Cabang berhasil diupdate', 'data' => $branch]);
    }

    public function destroy(Request $request, $id)
    {
        if ($request->user()->role !== 'Owner') {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $branch = Branch::where('company_id', $request->user()->company_id)->findOrFail($id);
        $branch->delete();

        return response()->json(['message' => 'Cabang berhasil dihapus']);
    }
}
