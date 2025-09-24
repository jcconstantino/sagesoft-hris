<?php

namespace App\Http\Controllers;

use App\Models\Employee;
use Illuminate\View\View;

class DashboardController extends Controller
{
    public function __construct()
    {
        $this->middleware('auth');
    }

    public function index(): View
    {
        $totalEmployees = Employee::count();
        $activeEmployees = Employee::where('status', 'active')->count();
        $inactiveEmployees = Employee::where('status', 'inactive')->count();
        $recentEmployees = Employee::latest()->take(5)->get();

        return view('dashboard', compact(
            'totalEmployees',
            'activeEmployees', 
            'inactiveEmployees',
            'recentEmployees'
        ));
    }
}
