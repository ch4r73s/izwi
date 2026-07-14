<?php

use App\Http\Controllers\DashboardController;
use App\Http\Controllers\NotificationsController;
use App\Http\Controllers\RecipientsController;
use App\Http\Controllers\SmsController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return redirect()->route('dashboard');
});

Route::middleware('auth.net')->group(function () {
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::get('/recipients', [RecipientsController::class, 'index'])->name('recipients.index');
    Route::get('/recipients/data', [RecipientsController::class, 'search'])->name('recipients.search');
    Route::get('/recipients/districts', [RecipientsController::class, 'districts'])->name('recipients.districts');
    Route::post('/recipients/data', [RecipientsController::class, 'store'])->name('recipients.store');
    Route::put('/recipients/data/{id}', [RecipientsController::class, 'update'])->name('recipients.update');
    Route::delete('/recipients/data/{id}', [RecipientsController::class, 'destroy'])->name('recipients.destroy');

    Route::get('/sms/compose', [SmsController::class, 'create'])->name('sms.create');
    Route::post('/sms/compose', [SmsController::class, 'store'])->name('sms.store');

    Route::get('/notifications', [NotificationsController::class, 'index'])->name('notifications.index');
});

require __DIR__.'/auth.php';
