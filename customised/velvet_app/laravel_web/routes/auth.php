<?php

use App\Http\Controllers\Auth\AuthController;
use Illuminate\Support\Facades\Route;

Route::middleware('guest.net')->group(function () {
    Route::get('login', [AuthController::class, 'create'])->name('login');
    Route::post('login', [AuthController::class, 'store']);
});

Route::middleware('auth.net')->group(function () {
    Route::post('logout', [AuthController::class, 'destroy'])->name('logout');
});
