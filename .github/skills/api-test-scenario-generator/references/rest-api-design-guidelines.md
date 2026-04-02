# REST API Design guideline

Converted from `REST API Design guideline.pdf`.

Table of contents
1 Table of contents
2 Useful links
3 Endpoint Paths
3.1 Use Nouns, Not Verbs:
3.2 Pluralize Resource Names:
3.3 Hierarchical Relationship in Paths:
3.4 Use Forward Slashes (/) to Indicate Hierarchy:
3.5 Avoid Deep Nesting (3+ levels):
4 HTTP Methods
4.1 Use HTTP Methods for Actions:
5 Status Codes
5.1 Use Standard HTTP Status Codes:
6 Parameters
6.1 Query Parameters for Filters, Sorting, and Searching:
6.2 Use Consistent Naming Conventions:
6.3 Pagination Parameters:
7 Pagination
7.1 Use Limit and Offset:
7.2 Include Pagination in the Response:
8 Filtering, Sorting, and Searching
8.1 Use Filters via Query Parameters:
8.2 Use Common Operators for Filtering:
9 Versioning
9.1 Use Versioning in the URL:
9.2 Avoid Versioning in Query Parameters or Headers:
10 Error Handling
10.1 Return Meaningful Error Messages:
10.2 Standard pagination error messages
11 Request Body
11.1 Use JSON Format for Request Bodies:
11.2 Use Clear, Descriptive Field Names:
11.3 Use Meaningful Data Types:
11.4 Validate Request Body Data:
11.5 Avoid Sending Data in Query Parameters for POST/PUT:
11.6 Use Arrays for Collections of Data:
11.7 Include Only Required Data:
11.8 Partial Updates with PATCH:
11.9 Avoid Nested JSON for Simple Structures:
11.10 Use Standard Formats for Date/Time:
12 Swagger
12.1 API Documentation via Swagger UI
12.2 Include the following in the Swagger documentation
12.3 Versioning:
12.4 Use Swagger Annotations in Code:

Useful links
Endpoint Paths
Use Nouns, Not Verbs:
API paths should represent resources (nouns), not actions (verbs).
Correct: /flowsheets
Incorrect: /getFlowsheets

Pluralize Resource Names:
Use plural form for resource names for consistency.
Correct: /flowsheets
Incorrect: /flowsheet

Hierarchical Relationship in Paths:
Structure endpoints to represent the relationships between resources.
Correct: /flowsheets/{flowsheetId}/units/{unitId}
Incorrect: /getFlowsheetUnit

Use Forward Slashes (/) to Indicate Hierarchy:
Use forward slashes for the hierarchy between resources and sub-resources.
Correct: /users/{userId}/posts/{postId}
Incorrect: /users?userId=123&postId=456

Avoid Deep Nesting (3+ levels):
Avoid deep nesting, which can make the API harder to use and maintain.
Correct: /flowsheets/{flowsheetId}/nodes
Incorrect: /flowsheets/{flowsheetId}/nodes/{nodeId}/items/{itemId}
Note: Suggest avoiding nested resources as much as possible. Unless it is some especially weird collection of objects, a flat representation allows the same functionality while being more
Web API design best practices - Azure Architecture Center | Microsoft Learn

-- 2 of 9 --

flexible. For example, the “nodes” here could be fetched with /nodes?flowsheet= {flowsheetId}

HTTP Methods
Use HTTP Methods for Actions:
Use the appropriate HTTP methods for the actions:
GET → Retrieve data
POST → Create a new resource
PUT → Update an existing resource
PATCH → Partially update a resource
DELETE → Remove a resource

Status Codes
Use Standard HTTP Status Codes:
Use standard HTTP status codes for response clarity:
200 OK → Success for GET, PUT, PATCH
201 Created → Resource successfully created
204 No Content → Successfully deleted or no content to return
400 Bad Request → Invalid input or request format
404 Not Found → Resource not found
500 Internal Server Error → Server-side error

Parameters
Query Parameters for Filters, Sorting, and Searching:
Use query parameters for optional filters, sorting, or searching.
Example:
Use Consistent Naming Conventions:
Stick to a consistent naming convention, such as camelCase, and use it consistently across parameters.
Correct: createdAt
Incorrect: Created-At , createdAtAndTime
GET /flowsheets?statud=error&sort=id&limit=20

-- 3 of 9 --

Pagination Parameters:
Use standard query parameters for pagination:
pageSize for the number of items per page.
page for the page number.
Example:

Pagination
Use Limit and Offset:
For pagination, implement limit (or pageSize ) and offset (or page ).

Include Pagination in the Response:
Filtering, Sorting, and Searching
Use Filters via Query Parameters:
Use query parameters to filter results based on certain fields.
Example:
Use Common Operators for Filtering:
Standardize filter operators like Lt (less than), Gt (greater than), etc.
Example:

Versioning
Use Versioning in the URL:
Version your API using the URL path to allow changes without breaking existing clients.
GET /customers?pageSize=25&page=3
GET /products?page=10&pageSize=30
{
  “items“: {…}
  "totalItems": 100,
  "page": 2,
  "pageSize": 10,
  "totalPages": 10
}
GET /products?category=electronics&price_lt=100
GET /flowsheets?idLt=50&ratingGt=4

-- 4 of 9 --

Example:
Note: Letʼs use only integer versions
Avoid Versioning in Query Parameters or Headers:
Prefer versioning in the URL path over query parameters or headers to make the API self-explanatory.
Correct: /v1/orders
Incorrect: /orders?version=1

Error Handling
Return Meaningful Error Messages:
Provide clear error messages and an appropriate status code.
Example:
"error": "Flowsheet with id ‘{some_guid}ʼ was not found"
Standard pagination error messages
“page cannot be less than 1“
“page cannot not be more than {some_value}“
“pageSize cannot be less than 1“
“pageSize cannot be more than 20000“

Request Body
Use JSON Format for Request Bodies:
JSON (JavaScript Object Notation) is the most commonly used format for REST APIs due to its simplicity and readability. Other formats like XML are generally avoided.
Correct Example:
GET /v1/customers
{
  "name": "John Doe",
  "email": "john.doe@example.com",
  "age": 30
}

-- 5 of 9 --

Use Clear, Descriptive Field Names:
Field names in the request body should be clear and self-explanatory, using either camelCase consistently.
Correct Example (camelCase):

Use Meaningful Data Types:
Ensure that the fields in the request body use appropriate data types, such as strings for text, numbers for integers/floats, arrays for lists, and booleans for true/false values.
Correct Example:

Validate Request Body Data:
Ensure that all required fields are present and that data types and constraints (e.g., max length, formats like emails or phone numbers) are validated at both client and server levels.
Letʼs follow this approach
Example validation rules:
email : must be a valid email address format.
price : must be a positive number.
name : should not exceed a maximum length of 255 characters.
Example Error Response for Invalid Request:

Avoid Sending Data in Query Parameters for POST/PUT:
For POST and PUT requests, place data in the request body, not in query parameters.
Correct Example:
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john.doe@example.com"
}
{
  "name": "Product A",
  "price": 99.99,
  "inStock": true,
  "tags": ["electronics", "sale"]
}

RFC 9457 - Problem Details for HTTP APIs (ietf.org)
{
  "status": 400,
  "message": "Invalid request body",
  "errors": [
    { "field": "email", "message": "Invalid email address format" },
    { "field": "price", "message": "Price must be a positive number" }
  ]
}

-- 6 of 9 --

Incorrect Example:
Use Arrays for Collections of Data:
When submitting a collection of similar data, such as multiple items or objects, use an array in the request body.
Correct Example:

Include Only Required Data:
Keep the request body concise and include only the fields necessary for the operation. Avoid sending unnecessary or redundant data.
Correct Example

Partial Updates with PATCH:
Use the PATCH method for partial updates, where only the fields that need to be updated are sent in the request body.
Correct Example (PATCH):

POST /products Content-Type: application/json { "name": "Product A", "price": 49.99 }
POST /products?name=ProductA&price=49.99
{
  "orderId": 12345,
  "products": [
    { "productId": 1, "quantity": 2 },
    { "productId": 2, "quantity": 1 }
  ]
}
{
  "username": "johndoe",
  "email": "johndoe@example.com",
  "password": "securePassword123"
}
{
  "username": "johndoe",
  "email": "johndoe@example.com",
  "password": "securePassword123",
  "createdAt": "2024-09-15T08:00:00Z",
  "lastLogin": null
}
PATCH /users/123
Content-Type: application/json
{
  "email": "new.email@example.com"
}

-- 7 of 9 --

Avoid Nested JSON for Simple Structures:
Avoid deeply nested structures in the request body unless it's necessary. Keep the structure flat to simplify parsing and validation.
Correct Example:
Incorrect Example:

Use Standard Formats for Date/Time:
Always use ISO 8601 format ( YYYY-MM-DDTHH:MM:SSZ ) for representing date and time in the request body to avoid ambiguity.
Correct Example:

Swagger
Adding Swagger (now known as OpenAPI) to your REST API design is an excellent way to standardize and document your API. It improves clarity for developers consuming your API and makes it easier to maintain, debug, and integrate with other systems.

API Documentation via Swagger UI
Swagger UI allows you to create interactive, web-based documentation for your API. You can host Swagger UI with your API so that developers can view documentation and even test endpoints directly from the web interface.
{
  "orderId": 12345,
  "customer": {
    "customerId": 67890,
    "firstName": "John",
    "lastName": "Doe"
  }
}
{
  "orderId": 12345,
  "customer": {
    "details": {
      "personalInfo": {
        "names": {
          "firstName": "John",
          "lastName": "Doe"
        }
      }
    }
  }
}
{
  "createdAt": "2024-09-15T08:00:00Z"
}

-- 8 of 9 --

Example: .

Include the following in the Swagger documentation
Base Path: Define the base path of your API (e.g., /api/v1 ).
HTTP Methods: Clearly document which HTTP methods (GET, POST, PUT, DELETE, etc.) are supported for each endpoint.
Endpoint Description: Provide a brief but clear description for each endpoint, outlining its purpose.
Parameters: Detail all request parameters (path, query, header, body).
Responses: Define all possible response codes (e.g., 200, 400, 404, 500) with explanations and example payloads.
Authentication: Document the type of authentication used (e.g., JWT, OAuth) in the API, along with relevant headers like Authorization .

Versioning:
It's important to version your API, and this should be reflected in your Swagger documentation (e.g., /v1/users or /api/v1/users ).

Use Swagger Annotations in Code:
If youʼre developing in language like C#, you can use annotations to generate Swagger documentation automatically from your codebase.

Example:
Swagger Petstore
@ApiOperation(value = "Get a list of users", response = List.class)
@GetMapping("/users")
public ResponseEntity<List<User>> getUsers() {
  return ResponseEntity.ok(userService.getAllUsers());
}

-- 9 of 9 --

