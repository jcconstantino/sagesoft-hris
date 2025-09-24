<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Employee;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Create admin user
        User::create([
            'name' => 'Admin User',
            'email' => 'admin@sagesoft.com',
            'password' => Hash::make('password123'),
            'role' => 'admin'
        ]);

        // Create regular user
        User::create([
            'name' => 'HR Manager',
            'email' => 'hr@sagesoft.com',
            'password' => Hash::make('password123'),
            'role' => 'user'
        ]);

        // Create sample employees
        Employee::create([
            'employee_id' => 'EMP001',
            'first_name' => 'John',
            'last_name' => 'Doe',
            'email' => 'john.doe@sagesoft.com',
            'phone' => '+1-555-0101',
            'department' => 'Engineering',
            'position' => 'Software Developer',
            'hire_date' => '2024-01-15',
            'salary' => 75000.00,
            'status' => 'active'
        ]);

        Employee::create([
            'employee_id' => 'EMP002',
            'first_name' => 'Jane',
            'last_name' => 'Smith',
            'email' => 'jane.smith@sagesoft.com',
            'phone' => '+1-555-0102',
            'department' => 'Marketing',
            'position' => 'Marketing Manager',
            'hire_date' => '2024-02-01',
            'salary' => 65000.00,
            'status' => 'active'
        ]);

        Employee::create([
            'employee_id' => 'EMP003',
            'first_name' => 'Mike',
            'last_name' => 'Johnson',
            'email' => 'mike.johnson@sagesoft.com',
            'phone' => '+1-555-0103',
            'department' => 'Sales',
            'position' => 'Sales Representative',
            'hire_date' => '2024-03-10',
            'salary' => 55000.00,
            'status' => 'active'
        ]);
    }
}
