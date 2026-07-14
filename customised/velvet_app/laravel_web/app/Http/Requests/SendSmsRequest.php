<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SendSmsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['required', 'string', 'max:255'],
            'message' => ['required', 'string', 'max:1600'],
            'recipients' => ['required', 'array', 'min:1'],
            'recipients.*.name' => ['required', 'string', 'max:255'],
            'recipients.*.phoneNumber' => ['required', 'string', 'max:30'],
            'recipients.*.gender' => ['nullable', 'string'],
        ];
    }
}
