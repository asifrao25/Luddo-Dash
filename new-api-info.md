# Live AI (GPT) Tracking API - v1.1.0

New endpoints for tracking GPT-powered AI opponents (gpt-4o-mini) in Luddo.

## New Tables

```sql
-- liveai_decisions: Per-turn GPT decision logs
-- liveai_errors: API error tracking
-- liveai_games: Live AI game metadata
```

## New Endpoints

### GET Endpoints (Read)

| Endpoint | Description |
|----------|-------------|
| `GET /liveai/stats?period=` | Aggregate stats (games, API usage, decisions, outcomes) |
| `GET /liveai/costs?period=` | Token usage, costs, projections |
| `GET /liveai/decisions?limit=&gameId=` | Per-turn decision logs |
| `GET /liveai/errors?period=&limit=` | Error tracking with recovery rates |
| `GET /liveai/games/recent?limit=` | Recent Live AI games |

### Admin Endpoints (Requires Admin Key)

| Endpoint | Description |
|----------|-------------|
| `DELETE /admin/reset/liveai` | Reset all Live AI (GPT) data |

### POST Endpoints (Write)

| Endpoint | Description |
|----------|-------------|
| `POST /events/liveai/decision` | Record each GPT decision |
| `POST /events/liveai/error` | Record API errors |
| `POST /events/liveai/game/start` | Start tracking a Live AI game |
| `POST /events/liveai/game/end` | End a Live AI game |

## Request/Response Examples

### 1. Record Decision
```bash
curl -X POST https://luddo-api.asifrao.com/events/liveai/decision \
  -H "X-API-Key: luddo_metrics_2024_secure_key" \
  -H "Content-Type: application/json" \
  -d '{
    "gameId": "game_xyz789",
    "turnNumber": 15,
    "playerColor": "red",
    "playerName": "GPT-Nova",
    "diceValue": 4,
    "validMoves": [0, 2],
    "selectedToken": 0,
    "parseStrategy": "json",
    "confidence": 0.95,
    "tokensUsed": { "prompt": 380, "completion": 12, "total": 392 },
    "responseTimeMs": 1150,
    "moveOutcome": "capture",
    "retryAttempts": 0
  }'
```

Response:
```json
{
  "success": true,
  "id": "dec_abc123",
  "timestamp": "2025-12-03T19:44:55.000Z"
}
```

### 2. Record Error
```bash
curl -X POST https://luddo-api.asifrao.com/events/liveai/error \
  -H "X-API-Key: luddo_metrics_2024_secure_key" \
  -H "Content-Type: application/json" \
  -d '{
    "gameId": "game_xyz789",
    "turnNumber": 8,
    "errorCode": "timeout",
    "errorMessage": "Request timed out after 10000ms",
    "retryAttempt": 1,
    "recovered": true
  }'
```

### 3. Start Live AI Game
```bash
curl -X POST https://luddo-api.asifrao.com/events/liveai/game/start \
  -H "X-API-Key: luddo_metrics_2024_secure_key" \
  -H "Content-Type: application/json" \
  -d '{
    "gameId": "game_xyz789",
    "playerCount": 4,
    "players": [
      { "color": "red", "name": "Asif", "type": "human" },
      { "color": "blue", "name": "GPT-Nova", "type": "openai" },
      { "color": "yellow", "name": "GPT-Sage", "type": "openai" },
      { "color": "green", "name": "Player 4", "type": "human" }
    ]
  }'
```

### 4. End Live AI Game
```bash
curl -X POST https://luddo-api.asifrao.com/events/liveai/game/end \
  -H "X-API-Key: luddo_metrics_2024_secure_key" \
  -H "Content-Type: application/json" \
  -d '{
    "gameId": "game_xyz789",
    "winner": { "color": "red", "name": "Asif", "type": "human" }
  }'
```

### 5. Get Stats
```bash
curl https://luddo-api.asifrao.com/liveai/stats?period=week \
  -H "X-API-Key: luddo_metrics_2024_secure_key"
```

Response:
```json
{
  "timestamp": "2025-12-03T19:45:00.000Z",
  "period": "week",
  "games": {
    "total": 45,
    "completed": 38,
    "abandoned": 7,
    "completionRate": 84,
    "avgDurationMinutes": 12,
    "allAIGames": 5,
    "mixedGames": 40
  },
  "apiUsage": {
    "totalCalls": 1250,
    "totalTokens": 562000,
    "avgTokensPerGame": 12489,
    "avgTokensPerTurn": 450,
    "estimatedCostUSD": 0.085,
    "avgResponseTimeMs": 1200
  },
  "decisions": {
    "total": 1250,
    "parseSuccess": { "json": 1050, "pattern": 120, "digit": 50, "fallback": 30 },
    "avgConfidence": 0.89,
    "errorRate": 2.4
  },
  "outcomes": {
    "humanWins": 22,
    "aiWins": 16,
    "humanWinRate": 58
  }
}
```

### 6. Get Costs
```bash
curl https://luddo-api.asifrao.com/liveai/costs?period=month \
  -H "X-API-Key: luddo_metrics_2024_secure_key"
```

Response:
```json
{
  "timestamp": "2025-12-03T19:45:00.000Z",
  "period": "month",
  "model": "gpt-4o-mini",
  "pricing": { "inputPer1kTokens": 0.00015, "outputPer1kTokens": 0.0006 },
  "usage": { "totalInputTokens": 480000, "totalOutputTokens": 15000, "totalCalls": 1250 },
  "costs": {
    "inputCostUSD": 0.072,
    "outputCostUSD": 0.009,
    "totalCostUSD": 0.081,
    "avgCostPerGame": 0.018,
    "avgCostPerTurn": 0.00065
  },
  "projections": {
    "dailyAvgGames": 6,
    "projectedMonthlyCost": 3.24,
    "projectedYearlyCost": 38.88
  },
  "perGameBreakdown": [...]
}
```

### 7. Reset Live AI Data (Admin)
```bash
curl -X DELETE https://luddo-api.asifrao.com/admin/reset/liveai \
  -H "X-API-Key: luddo_admin_2024_secure_key"
```

Response:
```json
{
  "success": true,
  "message": "Live AI (GPT) data has been reset",
  "deleted": {
    "liveai_decisions": 1250,
    "liveai_errors": 35,
    "liveai_games": 45
  },
  "timestamp": "2025-12-03T20:00:00.000Z"
}
```

## Files Changed

1. `src/database/index.ts` - Added 3 new tables (liveai_decisions, liveai_errors, liveai_games)
2. `src/services/LiveAIService.ts` - New service (created)
3. `src/routes/liveai.ts` - New GET routes (created)
4. `src/routes/events.ts` - Added POST endpoints for Live AI
5. `src/routes/admin.ts` - Added DELETE /admin/reset/liveai endpoint
6. `src/routes/utils.ts` - Updated version to 1.1.0, added liveai capability
7. `src/server.ts` - Registered liveai routes

## Pricing (gpt-4o-mini)

- Input: $0.00015 per 1K tokens
- Output: $0.0006 per 1K tokens
- Avg cost per game: ~$0.01-0.05
- Avg tokens per turn: ~400-500

## Parse Strategies

1. `json` - Clean JSON response (95% confidence)
2. `pattern` - Pattern matching e.g. "token 0" (80% confidence)
3. `digit` - Single digit extraction (60% confidence)
4. `fallback` - First valid move (10% confidence)

## Error Codes

- `rate_limit` - OpenAI rate limit hit
- `timeout` - Request timed out (10s default)
- `invalid_response` - Could not parse GPT response
- `network_error` - Network/connection error
- `api_error` - OpenAI API error
