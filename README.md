# SimpleDrive

[![CI](https://github.com/anykey007/SimpleDrive/actions/workflows/ci.yml/badge.svg)](https://github.com/anykey007/SimpleDrive/actions)
[![codecov](https://codecov.io/gh/anykey007/SimpleDrive/graph/badge.svg)](https://codecov.io/gh/anykey007/SimpleDrive)

SimpleDrive is a unified, multi-tenant file storage service that enables storing and retrieving files across different storage backends. The application supports storing files on:
- **S3** (e.g., MinIO or AWS S3)
- **Local Filesystem**
- **Database (DB)**
- **FTP Server**

Each tenant is configured with their own storage provider and associated users with dedicated API tokens.

---

## Running the Project with Docker Compose

To spin up the entire application stack (including PostgreSQL, MinIO S3, and vsftpd FTP server), follow these steps:

### 0. Clone the project
```bash
git clone git@github.com:anykey007/SimpleDrive.git
```
```bash
cd SimpleDrive
```
### 1. Start the Containers
Run the following command from the project root:
```bash
docker compose up -d
```
if you are using an older version
```bash
docker-compose up -d
```
I will only use the new version of docker compose in the code examples below.

### 2. Prepare and Seed the Database
Initialize the database and load the seed data:
```bash
docker compose exec app bin/rails db:prepare
```
If you ever need to specifically run the database seed task to reload/ensure seed data is present, run:
```bash
docker compose exec app bin/rails db:seed
```

The application will be accessible at `http://localhost:3000`.

---

## Rails Console and Testing

### Access the Rails Console
You can access the interactive Rails console within the running application container:
```bash
docker compose exec app bin/rails console
```

### Run the Test Suite
To run all tests inside the containerized environment, execute:
```bash
docker compose exec app bin/rails test
```

---

## API Usage Examples via curl

The API utilizes a `Bearer` token in the `Authorization` header for request authentication. All uploaded data (`data` parameter) must be a **Base64-encoded string**.

Below are copy-pasteable `curl` examples of storing (POST) and retrieving (GET) files for each of the supported storage backends using the seeded configurations.

### 1. Local Filesystem Storage (Tenant: Acme)
- **User**: `john@acme.test`
- **Token**: `e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9`

#### Store File (POST)
```bash
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "filesystem_file_example",
    "data": "SGVsbG8gRmlsZXN5c3RlbSBTdG9yYWdlIQ=="
  }'
```

#### Retrieve File (GET)
```bash
curl -X GET http://localhost:3000/v1/blobs/filesystem_file_example \
  -H "Authorization: Bearer e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9"
```

---

### 2. S3 Storage (Tenant: Globex)
- **User**: `jim@globex.test`
- **Token**: `e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7`

#### Store File (POST)
```bash
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "s3_file_example",
    "data": "SGVsbG8gUzMgU3RvcmFnZSE="
  }'
```

#### Retrieve File (GET)
```bash
curl -X GET http://localhost:3000/v1/blobs/s3_file_example \
  -H "Authorization: Bearer e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7"
```

---

### 3. Database Storage (Tenant: Cyberdyne)
- **User**: `sarah@cyberdyne.test`
- **Token**: `d88214fa3ca59d332d78632eb54957f467e10fa0628213e2c1896fb0c37338ff`

#### Store File (POST)
```bash
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer d88214fa3ca59d332d78632eb54957f467e10fa0628213e2c1896fb0c37338ff" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "db_file_example",
    "data": "SGVsbG8gRGF0YWJhc2UgU3RvcmFnZSE="
  }'
```

#### Retrieve File (GET)
```bash
curl -X GET http://localhost:3000/v1/blobs/db_file_example \
  -H "Authorization: Bearer d88214fa3ca59d332d78632eb54957f467e10fa0628213e2c1896fb0c37338ff"
```

---

### 4. FTP Storage (Tenant: Uplink)
- **User**: `user@uplink.test`
- **Token**: `f44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b4`

#### Store File (POST)
```bash
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer f44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b4" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "ftp_file_example",
    "data": "SGVsbG8gRlRQIFN0b3JhZ2Uh"
  }'
```

#### Retrieve File (GET)
```bash
curl -X GET http://localhost:3000/v1/blobs/ftp_file_example \
  -H "Authorization: Bearer f44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b4"
```

---

### 5. Wildcard Routing and Special Characters in IDs

#### Example with Complex Path and Special Characters
- **User**: `john@acme.test` (Acme)
- **Token**: `e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9`
- **File Path / ID**: `documents/2026/archive(final)+draft-v2_approved?\image.pdf`

##### Store File (POST)
```bash
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "documents/2026/archive(final)+draft-v2_approved?\\image.pdf",
    "data": "SGVsbG8gV2lsZGNhcmQgUm91dGluZyE="
  }'
```

##### Retrieve File (GET)
Characters that have structural meaning in URIs or HTTP engines must be URL-encoded:
- `?` must be URL-encoded as `%3F` so it is not interpreted as the start of a query string.
- `\` must be URL-encoded as `%5C` so it is processed correctly as a path character.

Here is the curl request with the properly encoded path:
```bash
curl -X GET http://localhost:3000/v1/blobs/documents%2F2026%2Farchive%28final%29%2Bdraft-v2_approved%3F%5Cimage.pdf \
  -H "Authorization: Bearer e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9"
```

---

## Error Handling Examples

Here are some examples of how the service handles various client errors, complete with expected status codes and response bodies.

### 1. Unauthorized Access (401 Unauthorized)
Returned if the `Authorization` header is missing, malformed, or contains an invalid token.
```bash
curl -X GET http://localhost:3000/v1/blobs/s3_file_example
```
**Response Status**: `401 Unauthorized`
```json
{
  "error": "Unauthorized"
}
```

### 2. File / Blob Not Found (404 Not Found)
Returned if the requested file ID does not exist in the system.
```bash
curl -X GET http://localhost:3000/v1/blobs/non_existent_file \
  -H "Authorization: Bearer e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7"
```
**Response Status**: `404 Not Found`
```json
{
  "error": "Blob not found"
}
```

### 3. Cross-Tenant Access Violation (404 Not Found)
Returned if a valid user attempts to retrieve a file belonging to a different tenant/user. For instance, user `john` (Acme) trying to retrieve a file uploaded by user `jim` (Globex).
```bash
curl -X GET http://localhost:3000/v1/blobs/s3_file_example \
  -H "Authorization: Bearer e44319627c65ed15e80b36a9029a34c3eb3eb57cb2c13defa3fd8acf1b8ef7b9"
```
**Response Status**: `404 Not Found`
```json
{
  "error": "Blob not found"
}
```

### 4. Invalid Base64 Payload (422 Unprocessable Entity)
Returned when creating a blob with `data` that cannot be properly strict Base64 decoded.
```bash
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "invalid_b64_file",
    "data": "not-valid-base64!!"
  }'
```
**Response Status**: `422 Unprocessable Entity`
```json
{
  "error": "data must be a valid Base64 encoded string"
}
```

### 5. Duplicate File Identifier (422 Unprocessable Entity)
Returned if a user attempts to upload a file with an ID (`id`) that has already been taken.
```bash
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "s3_file_example",
    "data": "SGVsbG8gUzMgU3RvcmFnZSE="
  }'
```
**Response Status**: `422 Unprocessable Entity`
```json
{
  "errors": [
    "External has already been taken"
  ]
}
```

### 6. File Exceeds Size Limit (422 Unprocessable Entity)
Returned if the uploaded file's uncompressed payload size is 1MB or larger.
```bash
# Data contains 1MB+ string in base64 (omitted for brevity)
curl -X POST http://localhost:3000/v1/blobs \
  -H "Authorization: Bearer e572fbc29acf3a627f1dd8ac876de2a54d120febb2b7a3c4fd7cc1f6e49837f7" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "too_large_file",
    "data": "..."
  }'
```
**Response Status**: `422 Unprocessable Entity`
```json
{
  "errors": [
    "Size bytes must be less than 1048576"
  ]
}
```
