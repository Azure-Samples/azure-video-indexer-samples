# Video Indexer API Documentation

## Overview
This API provides access to Video Indexer resources, including agent jobs, agents, chats, videos, insights, cameras, and more. It follows the OpenAPI 3.0.1 specification.

## Authentication
All endpoints require Bearer token authentication (JWT).

```http
Authorization: Bearer <your_token>
```

---

## Endpoints

### Agent Jobs

#### Create an Agent Job
`POST /Accounts/{accountId}/AgentJobs`

- **Parameters:**
  - `accountId` (path, required): UUID of the account
- **Request Body:**  
  Content-Type: `application/json`
  - Schema: `CreateOrUpdateAgentJobContract`
- **Responses:**
  - `200`: Agent job created successfully
  - `400`: Agent job name can't be empty
  - `401`: Unauthorized
  - `404`: Account not found
  - `500`: Server error

#### List Agent Jobs
`GET /Accounts/{accountId}/AgentJobs`

- **Parameters:**
  - `accountId` (path, required): UUID
  - `pageSize` (query, optional): int (default 25, max 1000)
  - `skip` (query, optional): int (default 0)
  - `cameraId` (query, optional): array of UUIDs
- **Responses:**
  - `200`: List of agent jobs
  - `401`, `404`, `500`: Error responses

#### Get Agent Job by ID
`GET /Accounts/{accountId}/AgentJobs/{agentJobId}`

- **Parameters:**
  - `accountId` (path, required): UUID
  - `agentJobId` (path, required): UUID
- **Responses:**
  - `200`: Agent job details
  - `401`, `404`, `500`: Error responses

#### Update Agent Job
`PUT /Accounts/{accountId}/AgentJobs/{agentJobId}`

- **Parameters:**
  - `accountId` (path, required): UUID
  - `agentJobId` (path, required): UUID
- **Request Body:**  
  Content-Type: `application/json`
  - Schema: `CreateOrUpdateAgentJobContract`
- **Responses:**
  - `200`: Agent job updated
  - `400`: Invalid input
  - `401`, `404`, `500`: Error responses

#### Delete Agent Job
`DELETE /Accounts/{accountId}/AgentJobs/{agentJobId}`

- **Parameters:**
  - `accountId` (path, required): UUID
  - `agentJobId` (path, required): UUID
- **Responses:**
  - `204`: Deleted successfully
  - `401`, `404`, `500`: Error responses

---

### Agents

#### List Agents
`GET /Accounts/{accountId}/agents`

- **Parameters:**
  - `accountId` (path, required): UUID
  - `pageSize`, `skip`, `sortBy` (query, optional)
- **Responses:**
  - `200`: List of agents
  - `401`, `404`, `500`: Error responses

---

### Chats

#### Create Chat
`POST /Accounts/{accountId}/chats`

- **Parameters:**
  - `accountId` (path, required): UUID
- **Responses:**
  - `201`: Chat created
  - `400`, `401`, `403`, `404`, `429`, `500`: Error responses

#### List Chats
`GET /Accounts/{accountId}/chats`

- **Parameters:**
  - `accountId` (path, required): UUID
  - `pageSize`, `skip`, `includeAgentJobChats`, `sortBy` (query, optional)
- **Responses:**
  - `200`: List of chats
  - `400`, `401`, `404`, `500`: Error responses

---

### Videos

#### Upload Video
`POST /Accounts/{accountId}/Videos`

- **Parameters:**
  - `accountId` (path, required): UUID
  - Various query parameters for video details
- **Request Body:**  
  Content-Type: `multipart/form-data`
- **Responses:**
  - `200`: Video uploaded
  - `400`, `401`, `404`, `500`, `507`: Error responses

#### List Videos
`GET /Accounts/{accountId}/Videos`

- **Parameters:**
  - `accountId` (path, required): UUID
  - Various query parameters for filtering
- **Responses:**
  - `200`: List of videos
  - `400`, `401`, `404`, `500`: Error responses

---

## Schemas

- `CreateOrUpdateAgentJobContract`
- `AgentJobContract`
- `ErrorResponse`
- ... (Add more as needed from the file)

---

## Example Request

```http
POST /Accounts/{accountId}/AgentJobs
Authorization: Bearer <your_token>
Content-Type: application/json

{
  "agentId": "uuid",
  "name": "Job Name",
  "description": "Job Description"
}
```

---

## Notes

- All endpoints require Bearer authentication.
- Replace `{accountId}` and other path parameters with actual values.
- Refer to the schemas section for detailed request/response structures.
