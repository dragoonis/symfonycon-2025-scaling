<?php

namespace App\Projection;

use Predis\ClientInterface;

final class ProductProjectionRepository
{
    private const REDIS_KEY_PREFIX = 'product:';
    private const REDIS_ALL_KEY = 'products:all';

    public function __construct(
        private readonly ClientInterface $redis
    ) {}

    public function find(int $id): ?ProductProjection
    {
        $data = $this->redis->get(self::REDIS_KEY_PREFIX . $id);

        if (!$data) {
            return null;
        }

        return unserialize($data);
    }
    public function findAll(): array
    {
        $allIds = $this->redis->smembers(self::REDIS_ALL_KEY);

        if (empty($allIds)) {
            return [];
        }

        $keys = array_map(fn($id) => self::REDIS_KEY_PREFIX . $id, $allIds);

        $allData = $this->redis->mget($keys);

        $projections = [];
        foreach ($allData as $data) {
            if ($data !== null) {
                $projections[] = unserialize($data);
            }
        }

        return $projections;
    }

    public function save(ProductProjection $projection): void
    {
        $this->redis->set(self::REDIS_KEY_PREFIX . $projection->id, serialize($projection));
        $this->redis->sadd(self::REDIS_ALL_KEY, [$projection->id]);
    }

    public function delete(int $id): void
    {
        $this->redis->del(self::REDIS_KEY_PREFIX . $id);
        $this->redis->srem(self::REDIS_ALL_KEY, $id);
    }

    public function clear(): void
    {
        $allIds = $this->redis->smembers(self::REDIS_ALL_KEY);

        if (!empty($allIds)) {
            $keys = array_map(fn($id) => self::REDIS_KEY_PREFIX . $id, $allIds);
            $this->redis->del($keys);
        }

        $this->redis->del(self::REDIS_ALL_KEY);
    }
}