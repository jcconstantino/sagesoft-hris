@extends('layouts.app')

@section('title', 'Employee Details - Sagesoft HRIS')

@section('content')
<div class="d-flex justify-content-between flex-wrap flex-md-nowrap align-items-center pt-3 pb-2 mb-3 border-bottom">
    <h1 class="h2"><i class="fas fa-user me-2"></i>Employee Details</h1>
    <div>
        <a href="{{ route('employees.edit', $employee) }}" class="btn btn-warning">
            <i class="fas fa-edit me-1"></i>Edit
        </a>
        <a href="{{ route('employees.index') }}" class="btn btn-secondary">
            <i class="fas fa-arrow-left me-1"></i>Back to List
        </a>
    </div>
</div>

<div class="card">
    <div class="card-body">
        <div class="row">
            <div class="col-md-6">
                <table class="table table-borderless">
                    <tr>
                        <th width="30%">Employee ID:</th>
                        <td>{{ $employee->employee_id }}</td>
                    </tr>
                    <tr>
                        <th>Full Name:</th>
                        <td>{{ $employee->full_name }}</td>
                    </tr>
                    <tr>
                        <th>Email:</th>
                        <td>{{ $employee->email }}</td>
                    </tr>
                    <tr>
                        <th>Phone:</th>
                        <td>{{ $employee->phone }}</td>
                    </tr>
                    <tr>
                        <th>Department:</th>
                        <td>{{ $employee->department }}</td>
                    </tr>
                </table>
            </div>
            <div class="col-md-6">
                <table class="table table-borderless">
                    <tr>
                        <th width="30%">Position:</th>
                        <td>{{ $employee->position }}</td>
                    </tr>
                    <tr>
                        <th>Hire Date:</th>
                        <td>{{ $employee->hire_date->format('F j, Y') }}</td>
                    </tr>
                    <tr>
                        <th>Salary:</th>
                        <td>${{ number_format($employee->salary, 2) }}</td>
                    </tr>
                    <tr>
                        <th>Status:</th>
                        <td>
                            <span class="badge bg-{{ $employee->status === 'active' ? 'success' : 'secondary' }}">
                                {{ ucfirst($employee->status) }}
                            </span>
                        </td>
                    </tr>
                    <tr>
                        <th>Created:</th>
                        <td>{{ $employee->created_at->format('F j, Y g:i A') }}</td>
                    </tr>
                </table>
            </div>
        </div>
    </div>
</div>
@endsection
