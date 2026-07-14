<?php

namespace App\Services\NetApi;

use Illuminate\Http\Client\Response;

class RecipientsApi
{
    public function __construct(private readonly NetApiClient $client)
    {
    }

    public function my(int $page = 1, int $pageSize = 20, ?string $search = null, ?string $district = null): Response
    {
        $query = ['page' => $page, 'pageSize' => $pageSize];

        if ($search !== null && $search !== '') {
            $query['search'] = $search;
        }

        if ($district !== null && $district !== '') {
            $query['district'] = $district;
        }

        return $this->client->get('/api/recipients/my', $query);
    }

    public function districts(): Response
    {
        return $this->client->get('/api/recipients/districts');
    }

    public function create(array $data): Response
    {
        return $this->client->post('/api/recipients', $data);
    }

    public function update(string $id, array $data): Response
    {
        return $this->client->put("/api/recipients/{$id}", $data);
    }

    public function delete(string $id): Response
    {
        return $this->client->delete("/api/recipients/{$id}");
    }
}
