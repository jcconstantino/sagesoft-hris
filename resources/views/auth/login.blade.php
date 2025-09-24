@extends('layouts.app')

@section('title', 'Login - Sagesoft HRIS')

@section('content')
<div class="row justify-content-center">
    <div class="col-md-6 col-lg-4">
        <div class="card shadow">
            <div class="card-body p-5">
                <div class="text-center mb-4">
                    <i class="fas fa-building fa-3x text-primary mb-3"></i>
                    <h2 class="fw-bold">Sagesoft HRIS</h2>
                    <p class="text-muted">Sign in to your account</p>
                </div>

                <form method="POST" action="{{ route('login') }}">
                    @csrf
                    
                    <div class="mb-3">
                        <label for="email" class="form-label">Email Address</label>
                        <input type="email" 
                               class="form-control @error('email') is-invalid @enderror" 
                               id="email" 
                               name="email" 
                               value="{{ old('email') }}" 
                               required 
                               autofocus>
                        @error('email')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="mb-3">
                        <label for="password" class="form-label">Password</label>
                        <input type="password" 
                               class="form-control @error('password') is-invalid @enderror" 
                               id="password" 
                               name="password" 
                               required>
                        @error('password')
                            <div class="invalid-feedback">{{ $message }}</div>
                        @enderror
                    </div>

                    <div class="mb-3 form-check">
                        <input type="checkbox" class="form-check-input" id="remember" name="remember">
                        <label class="form-check-label" for="remember">Remember me</label>
                    </div>

                    <div class="d-grid">
                        <button type="submit" class="btn btn-primary btn-lg">
                            <i class="fas fa-sign-in-alt me-1"></i>Sign In
                        </button>
                    </div>
                </form>

                <div class="mt-4 text-center">
                    <small class="text-muted">
                        Demo Credentials:<br>
                        <strong>admin@sagesoft.com</strong> / password123<br>
                        <strong>hr@sagesoft.com</strong> / password123
                    </small>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
