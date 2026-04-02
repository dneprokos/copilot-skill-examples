const fs = require("fs");
const path = require("path");

function parseCommaList(value) {
  return String(value || "")
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function parseFields(value) {
  return parseCommaList(value)
    .map((entry) => {
      const [name = "", type = "string", ...constraintParts] = entry.split(":");
      return {
        name: name.trim(),
        type: type.trim() || "string",
        constraint: constraintParts.join(":").trim() || "unspecified",
      };
    })
    .filter((field) => field.name);
}

function parseNameTypePairs(value) {
  return parseCommaList(value)
    .map((entry) => {
      const [name = "", type = "string"] = entry.split(":");
      return { name: name.trim(), type: type.trim() || "string" };
    })
    .filter((item) => item.name);
}

function parseTransitionPairs(value) {
  return parseCommaList(value)
    .map((entry) => {
      const [from = "", to = ""] = entry.split(":");
      return { from: from.trim(), to: to.trim() };
    })
    .filter((item) => item.from && item.to);
}

function parseRelationPairs(value) {
  return parseCommaList(value)
    .map((entry) => {
      const [resource = "", ...policyParts] = entry.split(":");
      return {
        resource: resource.trim(),
        policy: policyParts.join(":").trim() || "must exist first",
      };
    })
    .filter((item) => item.resource);
}

function parseCommandLineContext(args) {
  const context = {
    rawText: "",
    fields: [],
    states: [],
    transitions: [],
    filters: [],
    sortable: [],
    relations: [],
    openapiSpec: "",
    openapiOperationId: "",
  };

  const rawTextParts = [];

  for (let index = 0; index < args.length; index += 1) {
    const token = args[index];

    if (!token.startsWith("--")) {
      rawTextParts.push(token);
      continue;
    }

    const key = token.slice(2);
    const nextValue =
      index + 1 < args.length && !args[index + 1].startsWith("--")
        ? args[(index += 1)]
        : "";

    switch (key) {
      case "fields":
        context.fields = parseFields(nextValue);
        break;
      case "states":
        context.states = parseCommaList(nextValue);
        break;
      case "transitions":
        context.transitions = parseTransitionPairs(nextValue);
        break;
      case "filters":
        context.filters = parseNameTypePairs(nextValue);
        break;
      case "sortable":
        context.sortable = parseCommaList(nextValue);
        break;
      case "relations":
        context.relations = parseRelationPairs(nextValue);
        break;
      case "openapi":
      case "openapiSpec":
        context.openapiSpec = nextValue;
        break;
      case "openapiOperationId":
        context.openapiOperationId = nextValue;
        break;
      default:
        rawTextParts.push(`${token} ${nextValue}`.trim());
        break;
    }
  }

  context.rawText = rawTextParts.join(" ").trim();
  return context;
}

class APITestScenarioGenerator {
  constructor() {
    this.skillDir = path.dirname(path.dirname(__filename));
    this.loadConfig();
    this.loadTemplates();
  }

  tryParseOpenApiSpec(openapiSpecInput) {
    if (!openapiSpecInput) {
      return { spec: null, warnings: [] };
    }

    // Allow passing a JS object (e.g. from the skill runtime).
    if (typeof openapiSpecInput === "object") {
      return { spec: openapiSpecInput, warnings: [] };
    }

    const input = String(openapiSpecInput).trim();
    if (!input) {
      return { spec: null, warnings: [] };
    }

    try {
      // If it's a file path, load and parse it.
      if (fs.existsSync(input)) {
        const fileContents = fs.readFileSync(input, "utf8");
        try {
          return { spec: JSON.parse(fileContents), warnings: [] };
        } catch {
          // Try YAML if js-yaml is available.
          try {
            // eslint-disable-next-line import/no-extraneous-dependencies
            const yaml = require("js-yaml");
            return { spec: yaml.load(fileContents), warnings: [] };
          } catch (e) {
            return {
              spec: null,
              warnings: [
                `OpenAPI file was not valid JSON and YAML parsing is unavailable (missing 'js-yaml'). Path: ${input}`,
              ],
            };
          }
        }
      }

      // Otherwise treat it as JSON (or YAML if js-yaml is available).
      try {
        return { spec: JSON.parse(input), warnings: [] };
      } catch {
        try {
          // eslint-disable-next-line import/no-extraneous-dependencies
          const yaml = require("js-yaml");
          return { spec: yaml.load(input), warnings: [] };
        } catch {
          return {
            spec: null,
            warnings: [
              "OpenAPI spec input could not be parsed as JSON, and YAML parsing is unavailable (missing 'js-yaml').",
            ],
          };
        }
      }
    } catch (e) {
      return {
        spec: null,
        warnings: [`Failed to load OpenAPI spec: ${e.message || String(e)}`],
      };
    }
  }

  resolveJsonPointer(obj, pointer) {
    if (!pointer || typeof pointer !== "string") return null;
    if (!pointer.startsWith("#/")) return null;

    const parts = pointer
      .slice(2)
      .split("/")
      .map((p) => p.replace(/~1/g, "/").replace(/~0/g, "~"));

    let cur = obj;
    for (const part of parts) {
      if (!cur || typeof cur !== "object" || !(part in cur)) {
        return null;
      }
      cur = cur[part];
    }
    return cur || null;
  }

  resolveSchemaRefs(schema, openapiSpec, seenRefs = new Set()) {
    if (!schema || typeof schema !== "object") return schema;
    if (schema.$ref && typeof schema.$ref === "string") {
      const ref = schema.$ref;
      if (seenRefs.has(ref)) return schema;
      seenRefs.add(ref);

      const resolved = this.resolveJsonPointer(openapiSpec, ref);
      return resolved ? this.resolveSchemaRefs(resolved, openapiSpec, seenRefs) : schema;
    }

    // Handle common composite schemas (limited, but useful for extracting fields).
    if (Array.isArray(schema.allOf)) {
      const merged = { type: "object", properties: {}, required: [] };
      for (const item of schema.allOf) {
        const resolvedItem = this.resolveSchemaRefs(item, openapiSpec, seenRefs);
        if (!resolvedItem || typeof resolvedItem !== "object") continue;
        if (resolvedItem.properties) {
          merged.properties = { ...merged.properties, ...resolvedItem.properties };
        }
        if (Array.isArray(resolvedItem.required)) {
          merged.required = Array.from(
            new Set([...(merged.required || []), ...resolvedItem.required]),
          );
        }
      }
      return merged;
    }

    return schema;
  }

  extractSchemaFromContent(content, openapiSpec) {
    if (!content || typeof content !== "object") return null;
    const mediaTypes = Object.keys(content);
    if (mediaTypes.length === 0) return null;

    const preferred =
      mediaTypes.find((m) => /application\/json/i.test(m)) || mediaTypes[0];
    const mediaTypeObj = content[preferred];
    if (!mediaTypeObj || typeof mediaTypeObj !== "object") return null;

    const schema = mediaTypeObj.schema || null;
    return this.resolveSchemaRefs(schema, openapiSpec);
  }

  templateSegments(pathTemplate) {
    const segments = String(pathTemplate || "")
      .split("/")
      .filter(Boolean)
      .map((seg) => {
        if (/^\{[^}]+\}$/.test(seg)) return "{}";
        if (seg.startsWith(":")) return "{}";
        return seg;
      });
    return segments;
  }

  endpointMatchCandidates(endpoint) {
    const normalized = String(endpoint || "").trim();
    if (!normalized) return [];
    const segments = normalized.split("/").filter(Boolean);

    const candidates = [];

    const pushCandidate = (segList) => {
      const joined = "/" + segList.join("/");
      candidates.push(this.templateSegments(joined));
    };

    // 1) Original
    pushCandidate(segments);

    // 2) Remove leading `api`
    if (segments[0] && segments[0].toLowerCase() === "api") {
      pushCandidate(segments.slice(1));
    }

    // 3) Remove leading `v{number}` (common versioning)
    if (segments[0] && /^v\d+$/i.test(segments[0])) {
      pushCandidate(segments.slice(1));
    }

    // 4) Remove leading `api` + `v{number}`
    if (
      segments[0] &&
      segments[0].toLowerCase() === "api" &&
      segments[1] &&
      /^v\d+$/i.test(segments[1])
    ) {
      pushCandidate(segments.slice(2));
    }

    // De-dupe by segment signature.
    const seen = new Set();
    return candidates.filter((c) => {
      const key = c.join("/");
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  }

  matchOpenApiPath(openapiPathTemplate, endpoint) {
    const apiSegs = this.templateSegments(openapiPathTemplate);
    const candidates = this.endpointMatchCandidates(endpoint);
    return candidates.some(
      (candidate) =>
        candidate.length === apiSegs.length &&
        candidate.every(
          (seg, idx) => seg === "{}" || apiSegs[idx] === "{}" || seg === apiSegs[idx],
        ),
    );
  }

  findOpenApiOperation(openapiSpec, method, endpoint, operationId) {
    if (!openapiSpec || typeof openapiSpec !== "object") return null;
    const paths = openapiSpec.paths;
    if (!paths || typeof paths !== "object") return null;

    const methodLower = String(method || "").toLowerCase();
    const operationMethods = [
      "get",
      "post",
      "put",
      "patch",
      "delete",
      "head",
      "options",
    ];

    // 1) operationId takes precedence.
    if (operationId) {
      for (const [pathKey, pathItem] of Object.entries(paths)) {
        if (!pathItem || typeof pathItem !== "object") continue;
        for (const m of operationMethods) {
          const op = pathItem[m];
          if (op && op.operationId === operationId) {
            return { operation: op, matchedPathKey: pathKey, matchedMethodKey: m };
          }
        }
      }
      return null;
    }

    // 2) Match by path template + method.
    for (const [pathKey, pathItem] of Object.entries(paths)) {
      if (!pathItem || typeof pathItem !== "object") continue;
      if (!this.matchOpenApiPath(pathKey, endpoint)) continue;

      const op = pathItem[methodLower];
      if (op) {
        return { operation: op, matchedPathKey: pathKey, matchedMethodKey: methodLower };
      }
    }

    return null;
  }

  inferOpenApiOperationContext(openapiSpec, operation) {
    const derived = {
      responseCodes: [],
      errorCodes: [],
      responseCodesSet: new Set(),
      securityPresent: false,
      queryParams: [],
      inferredStates: [],
      inferredFields: [],
      errorContractFields: [],
    };

    const responses = (operation && operation.responses) || {};
    for (const [codeStr] of Object.entries(responses)) {
      const n = parseInt(codeStr, 10);
      if (!Number.isNaN(n)) {
        derived.responseCodes.push(n);
        derived.responseCodesSet.add(n);
        if (n >= 400) derived.errorCodes.push(n);
      }
    }

    derived.responseCodes = Array.from(new Set(derived.responseCodes)).sort((a, b) => a - b);
    derived.errorCodes = Array.from(new Set(derived.errorCodes)).sort((a, b) => a - b);

    // Security: operation.security overrides top-level security.
    const opSecurity =
      operation && Array.isArray(operation.security)
        ? operation.security
        : openapiSpec && Array.isArray(openapiSpec.security)
          ? openapiSpec.security
          : undefined;
    derived.securityPresent = Array.isArray(opSecurity) ? opSecurity.length > 0 : false;

    // Query parameter inference (best-effort).
    const params = (operation && operation.parameters) || [];
    derived.queryParams = params
      .map((p) => (p && p.$ref ? this.resolveJsonPointer(openapiSpec, p.$ref) : p))
      .filter(Boolean)
      .filter((p) => p.in === "query" && p.name)
      .map((p) => {
        const schema = this.resolveSchemaRefs(p.schema || {}, openapiSpec);
        const type =
          schema && typeof schema === "object"
            ? schema.type || schema.format || "string"
            : "string";
        return { name: p.name, type };
      });

    // Request body schema inference (fields + states).
    const requestBody = operation && operation.requestBody;
    const requestBodyRequired = requestBody && requestBody.required === true;
    const requestContent = requestBody && requestBody.content;
    const requestSchema = this.extractSchemaFromContent(
      requestContent,
      openapiSpec,
    );
    if (requestSchema && typeof requestSchema === "object") {
      const resolved = this.resolveSchemaRefs(requestSchema, openapiSpec);
      const schemaObj = resolved && resolved.properties ? resolved : null;

      const requiredList = Array.isArray(resolved.required) ? resolved.required : [];
      const properties =
        schemaObj && schemaObj.properties && typeof schemaObj.properties === "object"
          ? schemaObj.properties
          : {};

      for (const [propName, propSchema] of Object.entries(properties)) {
        const resolvedPropSchema = this.resolveSchemaRefs(propSchema, openapiSpec);
        if (!resolvedPropSchema || typeof resolvedPropSchema !== "object") continue;

        if (
          /status|state/i.test(propName) &&
          Array.isArray(resolvedPropSchema.enum) &&
          resolvedPropSchema.enum.length > 0
        ) {
          if (derived.inferredStates.length === 0) {
            derived.inferredStates = resolvedPropSchema.enum.map((v) =>
              String(v),
            );
          }
        }

        const schemaType = resolvedPropSchema.type || (resolvedPropSchema.format ? "string" : "string");
        let type = schemaType;
        if (schemaType === "integer" || schemaType === "number") type = "number";
        if (schemaType === undefined && resolvedPropSchema.enum) type = "string";

        const constraintParts = [];
        if (requiredList.includes(propName) || requestBodyRequired) {
          constraintParts.push("required");
        }
        if (resolvedPropSchema.minLength != null) constraintParts.push(`minLength=${resolvedPropSchema.minLength}`);
        if (resolvedPropSchema.maxLength != null) constraintParts.push(`maxLength=${resolvedPropSchema.maxLength}`);
        if (resolvedPropSchema.pattern) constraintParts.push(`pattern=${resolvedPropSchema.pattern}`);
        if (resolvedPropSchema.format) constraintParts.push(`format=${resolvedPropSchema.format}`);
        if (Array.isArray(resolvedPropSchema.enum) && resolvedPropSchema.enum.length > 0) {
          constraintParts.push(`enum=${resolvedPropSchema.enum.join("|")}`);
        }

        derived.inferredFields.push({
          name: propName,
          type,
          constraint: constraintParts.join(", ") || "unspecified",
        });
      }
    }

    // Error contract inference (best-effort).
    // We look for schemas that have an `error` object containing `code`, `message`, and `requestId` (or `traceId`).
    const errorFieldCandidates = new Set();
    for (const [codeStr, resp] of Object.entries(responses)) {
      const n = parseInt(codeStr, 10);
      if (Number.isNaN(n) || n < 400) continue;
      const content = resp && resp.content;
      const schema = this.extractSchemaFromContent(content, openapiSpec);
      if (!schema) continue;
      const resolved = this.resolveSchemaRefs(schema, openapiSpec);
      if (!resolved || typeof resolved !== "object") continue;

      const errObj = resolved.properties && resolved.properties.error;
      if (
        errObj &&
        typeof errObj === "object" &&
        errObj.properties &&
        errObj.properties.code &&
        errObj.properties.message
      ) {
        if (errObj.properties.code) errorFieldCandidates.add("error.code");
        if (errObj.properties.message) errorFieldCandidates.add("error.message");
        if (errObj.properties.requestId) errorFieldCandidates.add("error.requestId");
        if (errObj.properties.traceId) errorFieldCandidates.add("error.traceId");
      }
    }
    derived.errorContractFields = Array.from(errorFieldCandidates);

    return derived;
  }

  enrichContextWithOpenApi(method, endpoint, context) {
    const openapiSpecInput = context.openapiSpec;
    if (!openapiSpecInput) {
      return context;
    }

    const openapiWarnings = [];
    const parsed = this.tryParseOpenApiSpec(openapiSpecInput);
    openapiWarnings.push(...parsed.warnings);

    if (!parsed.spec) {
      context.openapi = {
        operationFound: false,
        securityPresent: false,
        responseCodes: [],
        errorCodes: [],
        inferredFields: [],
        inferredStates: [],
        queryParams: [],
        errorContractFields: [],
      };
      context.openapiWarnings = openapiWarnings;
      return context;
    }

    const operationId = context.openapiOperationId || "";
    const found = this.findOpenApiOperation(parsed.spec, method, endpoint, operationId);
    if (!found) {
      context.openapi = {
        operationFound: false,
        securityPresent: false,
        responseCodes: [],
        errorCodes: [],
        inferredFields: [],
        inferredStates: [],
        queryParams: [],
        errorContractFields: [],
      };
      openapiWarnings.push(
        `OpenAPI spec provided, but no matching operation was found for ${method.toUpperCase()} ${endpoint}${
          operationId ? ` (operationId=${operationId})` : ""
        }.`,
      );
      context.openapiWarnings = openapiWarnings;
      return context;
    }

    const derived = this.inferOpenApiOperationContext(parsed.spec, found.operation);
    context.openapi = { operationFound: true, ...derived, matchedPathKey: found.matchedPathKey };
    context.openapiWarnings = openapiWarnings;

    if (context.fields.length === 0 && derived.inferredFields.length > 0) {
      context.fields = derived.inferredFields;
    }
    if (context.states.length === 0 && derived.inferredStates.length > 0) {
      context.states = derived.inferredStates;
    }

    if (context.filters.length === 0 && derived.queryParams.length > 0) {
      context.filters = derived.queryParams.map((q) => ({
        name: q.name,
        type: q.type,
      }));
    }

    if (context.sortable.length === 0) {
      const sortableNames = derived.queryParams
        .map((q) => q.name)
        .filter((n) => /sort|order/i.test(n));
      if (sortableNames.length > 0) {
        context.sortable = sortableNames;
      }
    }

    return context;
  }

  pickStatusFromOpenApi(openapi, preferredCodes, fallback) {
    if (!openapi || !Array.isArray(preferredCodes) || preferredCodes.length === 0) return fallback;
    if (!openapi.responseCodesSet || !(openapi.responseCodesSet instanceof Set)) return fallback;
    const chosen = preferredCodes.filter((c) => openapi.responseCodesSet.has(c));
    if (!chosen || chosen.length === 0) return fallback;
    return chosen.join("/");
  }

  loadConfig() {
    const validationRulesPath = path.join(
      this.skillDir,
      "config",
      "validation-rules.json",
    );
    const testTypesPath = path.join(this.skillDir, "config", "test-types.json");

    this.validationRules = JSON.parse(
      fs.readFileSync(validationRulesPath, "utf8"),
    );
    this.testTypes = JSON.parse(fs.readFileSync(testTypesPath, "utf8"));
  }

  loadTemplates() {
    const scenarioTablePath = path.join(
      this.skillDir,
      "templates",
      "scenario-table.md",
    );
    const fullReportPath = path.join(
      this.skillDir,
      "templates",
      "full-report.md",
    );

    this.templates = {
      scenarioTable: fs.readFileSync(scenarioTablePath, "utf8"),
      fullReport: fs.readFileSync(fullReportPath, "utf8"),
    };
  }

  normalizeContext(additionalContext = "") {
    if (additionalContext && typeof additionalContext === "object") {
      return {
        rawText: additionalContext.rawText || "",
        fields: additionalContext.fields || [],
        states: additionalContext.states || [],
        transitions: additionalContext.transitions || [],
        filters: additionalContext.filters || [],
        sortable: additionalContext.sortable || [],
        relations: additionalContext.relations || [],
        openapiSpec: additionalContext.openapiSpec || "",
        openapiOperationId: additionalContext.openapiOperationId || "",
        openapi: additionalContext.openapi || null,
        openapiWarnings: additionalContext.openapiWarnings || [],
      };
    }

    return {
      rawText: String(additionalContext || ""),
      fields: [],
      states: [],
      transitions: [],
      filters: [],
      sortable: [],
      relations: [],
      openapiSpec: "",
      openapiOperationId: "",
      openapi: null,
      openapiWarnings: [],
    };
  }

  singularize(name) {
    if (!name) {
      return "resource";
    }

    if (name.endsWith("ies")) {
      return `${name.slice(0, -3)}y`;
    }

    if (name.endsWith("ses")) {
      return name.slice(0, -2);
    }

    if (name.endsWith("s") && name.length > 1) {
      return name.slice(0, -1);
    }

    return name;
  }

  parseEndpoint(endpoint) {
    const segments = endpoint.split("/").filter(Boolean);
    const hasPathParam = segments.some(
      (segment) => segment.startsWith("{") || segment.startsWith(":"),
    );
    const namedSegments = segments.filter(
      (segment) =>
        segment !== "api" &&
        !segment.startsWith("{") &&
        !segment.startsWith(":"),
    );
    const resourceName = namedSegments[namedSegments.length - 1] || "resource";

    return {
      segments,
      hasPathParam,
      isCollection: !hasPathParam && segments.length > 0,
      isResource: hasPathParam,
      resourceName,
      singularResource: this.singularize(resourceName.replace(/[{}:]/g, "")),
      pathParams: this.extractPathParams(endpoint),
    };
  }

  extractPathParams(endpoint) {
    const braceMatches = endpoint.match(/\{([^}]+)\}/g) || [];
    const colonMatches = endpoint.match(/:[^/]+/g) || [];
    return [...braceMatches, ...colonMatches].map((match) =>
      match.replace(/[{}:]/g, ""),
    );
  }

  createScenario(definition) {
    const scenario = { ...definition };
    scenario.testLevel =
      scenario.testLevel ||
      this.determineTestLevel(scenario.testType, scenario.scenario);
    scenario.priority = scenario.priority || this.assignPriority(scenario);
    return scenario;
  }

  generateScenarios(method, endpoint, additionalContext = "") {
    const context = this.normalizeContext(additionalContext);
    const endpointInfo = this.parseEndpoint(endpoint);

    const scenarios = [
      ...this.generateHappyPathScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
      ...this.generateQueryScenarios(method, endpoint, endpointInfo, context),
      ...this.generateBoundaryScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
      ...this.generateNegativeScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
      ...this.generateSecurityScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
      ...this.generateStateTransitionScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
      ...this.generateReliabilityScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
      ...this.generateContractScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
      ...this.generatePerformanceScenarios(
        method,
        endpoint,
        endpointInfo,
        context,
      ),
    ];

    return this.dedupeScenarios(scenarios);
  }

  dedupeScenarios(scenarios) {
    const seen = new Set();

    return scenarios.filter((scenario) => {
      const key = [
        scenario.scenario,
        scenario.testType,
        scenario.description,
      ].join("::");
      if (seen.has(key)) {
        return false;
      }

      seen.add(key);
      return true;
    });
  }

  generateHappyPathScenarios(method, endpoint, endpointInfo) {
    const scenarios = [];

    switch (method) {
      case "GET":
        if (endpointInfo.isCollection) {
          scenarios.push(
            this.createScenario({
              scenario: "Retrieve all resources",
              testType: "Happy Path",
              description: `GET ${endpoint} returns the current resource list`,
              expectedResult: "List of resources returned with stable schema",
              httpStatus: 200,
            }),
          );

          scenarios.push(
            this.createScenario({
              scenario: "Retrieve with pagination",
              testType: "Happy Path",
              description: `GET ${endpoint}?page=1&pageSize=10 returns paginated results (or equivalent page/pageSize or limit/offset parameters)`,
              expectedResult:
                "Paginated list with metadata returned (e.g., page, pageSize, totalItems/totalPages or equivalent pagination fields)",
              httpStatus: 200,
              testLevel: "Integration",
              priority: "Medium (M)",
            }),
          );
        } else if (endpointInfo.isResource) {
          scenarios.push(
            this.createScenario({
              scenario: "Retrieve existing resource",
              testType: "Happy Path",
              description: `GET ${endpoint} with a valid identifier returns resource details`,
              expectedResult: "Resource details returned",
              httpStatus: 200,
            }),
          );
        }
        break;

      case "POST":
        scenarios.push(
          this.createScenario({
            scenario: "Create new resource",
            testType: "Happy Path",
            description: `POST ${endpoint} with valid data creates a new resource`,
            expectedResult:
              "Resource created successfully with identifier returned",
            httpStatus: 201,
          }),
        );
        break;

      case "PUT":
        scenarios.push(
          this.createScenario({
            scenario: "Update existing resource",
            testType: "Happy Path",
            description: `PUT ${endpoint} with valid data updates the existing resource`,
            expectedResult: "Resource updated successfully",
            httpStatus: 200,
          }),
        );
        break;

      case "PATCH":
        scenarios.push(
          this.createScenario({
            scenario: "Partial update resource",
            testType: "Happy Path",
            description: `PATCH ${endpoint} with partial data updates only the targeted fields`,
            expectedResult: "Resource partially updated",
            httpStatus: 200,
          }),
        );
        break;

      case "DELETE":
        scenarios.push(
          this.createScenario({
            scenario: "Delete existing resource",
            testType: "Happy Path",
            description: `DELETE ${endpoint} removes the existing resource`,
            expectedResult: "Resource deleted successfully",
            httpStatus: 204,
          }),
        );
        break;

      case "HEAD":
        scenarios.push(
          this.createScenario({
            scenario: "Metadata-only HEAD request",
            testType: "Happy Path",
            description: `HEAD ${endpoint} returns headers without a response body`,
            expectedResult: "Headers returned and body omitted",
            httpStatus: 200,
            priority: "Medium (M)",
          }),
        );
        break;

      case "OPTIONS":
        scenarios.push(
          this.createScenario({
            scenario: "Discover allowed HTTP methods",
            testType: "Happy Path",
            description: `OPTIONS ${endpoint} returns the Allow header or equivalent capability metadata`,
            expectedResult: "Supported methods documented in response",
            httpStatus: 200,
            priority: "Low (L)",
          }),
        );
        break;
    }

    return scenarios;
  }

  generateQueryScenarios(method, endpoint, endpointInfo, context) {
    const scenarios = [];
    const shouldCheckQueries =
      method === "GET" &&
      (endpointInfo.isCollection ||
        context.filters.length > 0 ||
        context.sortable.length > 0 ||
        /filter|sort|date/i.test(context.rawText));

    if (!shouldCheckQueries) {
      return scenarios;
    }

    scenarios.push(
      this.createScenario({
        scenario: "Filter and sort results",
        testType: "Query Behavior",
        description: `GET ${endpoint} with consistent query parameter naming (camelCase) for supported filters and sort order returns deterministic results`,
        expectedResult:
          "Filtered and sorted resources returned with correct metadata (including deterministic ordering)",
        httpStatus: 200,
        priority: "Medium (M)",
      }),
    );

    scenarios.push(
      this.createScenario({
        scenario: "Invalid filter field",
        testType: "Query Behavior",
        description: `GET ${endpoint} with an unsupported filter field (unknown filter query parameter) is rejected`,
        expectedResult:
          "Validation error for unknown filter field with a meaningful message",
        httpStatus: 400,
      }),
    );

    scenarios.push(
      this.createScenario({
        scenario: "Invalid sort field",
        testType: "Query Behavior",
        description: `GET ${endpoint} with an unsupported sort field (unknown sort/order query parameter) is rejected`,
        expectedResult:
          "Validation error for unknown sort field with a meaningful message",
        httpStatus: 400,
      }),
    );

    scenarios.push(
      this.createScenario({
        scenario: "Invalid date range filter",
        testType: "Query Behavior",
        description: `GET ${endpoint} with an invalid date range (from > to or bad format) is rejected`,
        expectedResult: "Validation error for date-range query with a meaningful message",
        httpStatus: 400,
      }),
    );

    return scenarios;
  }

  generateBoundaryScenarios(method, endpoint, endpointInfo, context) {
    const scenarios = [];

    if (method === "GET" && endpointInfo.isCollection) {
      scenarios.push(
        this.createScenario({
          scenario: "Empty collection",
          testType: "Boundary",
          description: `GET ${endpoint} when no resources exist`,
          expectedResult: "Empty array returned with valid metadata",
          httpStatus: 200,
          priority: "Medium (M)",
        }),
      );

      scenarios.push(
        this.createScenario({
          scenario: "Maximum page size",
          testType: "Boundary",
          description: `GET ${endpoint}?limit=max with the maximum allowed page size`,
          expectedResult: "Results capped at the configured maximum page size",
          httpStatus: 200,
          priority: "Low (L)",
        }),
      );
    }

    if (["POST", "PUT", "PATCH"].includes(method)) {
      scenarios.push(
        this.createScenario({
          scenario: "Maximum field lengths",
          testType: "Boundary",
          description: `${method} ${endpoint} with maximum allowed field lengths`,
          expectedResult:
            "Boundary-length data is accepted or rejected consistently",
          httpStatus: method === "POST" ? 201 : 200,
        }),
      );

      scenarios.push(
        this.createScenario({
          scenario: "Unicode and emoji payload",
          testType: "Boundary",
          description: `${method} ${endpoint} with Unicode text, emoji, and non-Latin characters`,
          expectedResult:
            "Characters are stored or validated correctly without corruption",
          httpStatus: method === "POST" ? 201 : 200,
        }),
      );

      scenarios.push(
        this.createScenario({
          scenario: "Unknown fields in request body",
          testType: "Boundary",
          description: `${method} ${endpoint} with unexpected extra properties in the payload`,
          expectedResult:
            "Unknown fields are ignored or rejected according to the contract",
          httpStatus: "200/201/400/422",
          priority: "Medium (M)",
        }),
      );

      const hasNumericField =
        context.fields.some((field) =>
          /number|int|float|decimal/i.test(field.type),
        ) || /amount|price|total|quantity|qty/i.test(context.rawText);

      if (hasNumericField) {
        scenarios.push(
          this.createScenario({
            scenario: "Zero-value numeric input",
            testType: "Boundary",
            description: `${method} ${endpoint} with a numeric value of 0 (for example, amount=0)`,
            expectedResult:
              "Zero is either accepted explicitly or rejected with a clear validation error",
            httpStatus: "200/201/422",
            priority: "Medium (M)",
          }),
        );
      }
    }

    if (endpointInfo.hasPathParam) {
      scenarios.push(
        this.createScenario({
          scenario: "Path parameter boundary values",
          testType: "Boundary",
          description: `${method} ${endpoint} with boundary identifier values such as 0, max int, or empty UUID`,
          expectedResult: "Appropriate response based on identifier validity",
          httpStatus: "Variable",
        }),
      );
    }

    return scenarios;
  }

  generateNegativeScenarios(method, endpoint, endpointInfo) {
    const scenarios = [];

    if (endpointInfo.hasPathParam) {
      scenarios.push(
        this.createScenario({
          scenario: "Invalid path parameter",
          testType: "Negative",
          description: `${method} ${endpoint} with an invalid identifier format`,
          expectedResult: "Bad request or validation error returned",
          httpStatus: 400,
        }),
      );

      scenarios.push(
        this.createScenario({
          scenario: "Non-existent resource",
          testType: "Negative",
          description: `${method} ${endpoint} with a non-existent identifier`,
          expectedResult: "Resource not found error returned",
          httpStatus: 404,
          priority: "High (H)",
        }),
      );
    }

    if (["POST", "PUT", "PATCH"].includes(method)) {
      if (["POST", "PUT"].includes(method)) {
        scenarios.push(
          this.createScenario({
            scenario: "Payload sent via query parameters",
            testType: "Negative",
            description: `${method} ${endpoint} sends payload fields in query parameters (instead of request body), which should be rejected or safely ignored per API contract`,
            expectedResult:
              "API does not process the payload as a write; returns 400/422 (or safely ignores query payload) with a meaningful message",
            httpStatus: "400/422",
            priority: "Medium (M)",
          }),
        );
      }

      scenarios.push(
        this.createScenario({
          scenario: "Malformed JSON body",
          testType: "Negative",
          description: `${method} ${endpoint} with malformed JSON or invalid payload encoding`,
          expectedResult: "Bad request error returned",
          httpStatus: 400,
        }),
      );

      scenarios.push(
        this.createScenario({
          scenario: "Missing required fields",
          testType: "Negative",
          description: `${method} ${endpoint} with missing required fields`,
          expectedResult: "Validation error returned with field details",
          httpStatus: 422,
          priority: "High (H)",
        }),
      );

      scenarios.push(
        this.createScenario({
          scenario: "Field validation failure",
          testType: "Negative",
          description: `${method} ${endpoint} with invalid field formats or constraint violations`,
          expectedResult: "Validation error returned",
          httpStatus: 422,
        }),
      );
    }

    return scenarios;
  }

  generateSecurityScenarios(method, endpoint, endpointInfo, context) {
    const scenarios = [];

    scenarios.push(
      this.createScenario({
        scenario: "Missing authentication",
        testType: "Security",
        description: `${method} ${endpoint} without an authentication token`,
        expectedResult: "Authentication required error returned",
        httpStatus: 401,
      }),
    );

    scenarios.push(
      this.createScenario({
        scenario: "Expired JWT token",
        testType: "Security",
        description: `${method} ${endpoint} with an expired JWT access token`,
        expectedResult:
          "401 returned and refresh flow is required before retrying",
        httpStatus: 401,
        priority: "High (H)",
      }),
    );

    scenarios.push(
      this.createScenario({
        scenario: "Insufficient permissions",
        testType: "Security",
        description: `${method} ${endpoint} with a valid token but insufficient permissions`,
        expectedResult: "Forbidden error returned",
        httpStatus: 403,
      }),
    );

    if (endpointInfo.hasPathParam || context.relations.length > 0) {
      scenarios.push(
        this.createScenario({
          scenario: "RBAC cross-resource access",
          testType: "Security",
          description: `${method} ${endpoint} where a Customer attempts to access another user's resource while Admin access is allowed or denied per policy`,
          expectedResult: "Ownership and RBAC rules enforced consistently",
          httpStatus: "403/404",
          priority: "High (H)",
        }),
      );
    }

    if (["POST", "PUT", "PATCH"].includes(method)) {
      scenarios.push(
        this.createScenario({
          scenario: "Input sanitization",
          testType: "Security",
          description: `${method} ${endpoint} with potentially malicious input such as XSS or SQL-injection payloads`,
          expectedResult: "Input is sanitized or rejected safely",
          httpStatus: "200/201/400/422",
          priority: "Medium (M)",
        }),
      );
    }

    return scenarios;
  }

  generateStateTransitionScenarios(method, endpoint, endpointInfo, context) {
    const scenarios = [];
    const hasLifecycleContext =
      context.states.length > 0 ||
      context.transitions.length > 0 ||
      /state|status/i.test(endpoint) ||
      /state|status/i.test(context.rawText);

    if (!hasLifecycleContext || !["POST", "PUT", "PATCH"].includes(method)) {
      return scenarios;
    }

    const defaultStates =
      this.validationRules.stateMachinePatterns.defaultStates;
    const states = context.states.length > 0 ? context.states : defaultStates;
    const transitions =
      context.transitions.length > 0
        ? context.transitions
        : states.length > 1
          ? [{ from: states[0], to: states[1] }]
          : [];

    if (transitions.length > 0) {
      const validTransition = transitions[0];
      scenarios.push(
        this.createScenario({
          scenario: "Valid state transition",
          testType: "State Transition",
          description: `${method} ${endpoint} moves the resource from ${validTransition.from} to ${validTransition.to} when preconditions are satisfied`,
          expectedResult:
            "State changes successfully and audit data is preserved",
          httpStatus: "200/204",
          priority: "High (H)",
        }),
      );
    }

    if (states.length >= 2) {
      const fromState = states[states.length - 1];
      const toState = states[0];
      scenarios.push(
        this.createScenario({
          scenario: "Invalid state transition",
          testType: "State Transition",
          description: `${method} ${endpoint} attempts an invalid transition such as ${fromState} to ${toState}`,
          expectedResult:
            "Conflict or validation error returned and state remains unchanged",
          httpStatus: "409/422",
          priority: "High (H)",
        }),
      );
    }

    return scenarios;
  }

  generateReliabilityScenarios(method, endpoint, endpointInfo, context) {
    const scenarios = [];

    scenarios.push(
      this.createScenario({
        scenario: "Unsupported HTTP method",
        testType: "Reliability",
        description: `A non-supported method sent to ${endpoint} is rejected with Allow metadata when applicable`,
        expectedResult: "Method not allowed response returned",
        httpStatus: 405,
        priority: "Medium (M)",
      }),
    );

    if (["POST", "PUT", "PATCH"].includes(method)) {
      scenarios.push(
        this.createScenario({
          scenario: "Unsupported media type",
          testType: "Reliability",
          description: `${method} ${endpoint} with a disallowed Content-Type header`,
          expectedResult: "Unsupported media type response returned",
          httpStatus: 415,
          priority: "Medium (M)",
        }),
      );
    }

    if (["POST", "PUT"].includes(method)) {
      scenarios.push(
        this.createScenario({
          scenario: "Idempotency key replay",
          testType: "Reliability",
          description: `${method} ${endpoint} with the same Idempotency-Key submitted twice`,
          expectedResult:
            "No duplicate write occurs and the same logical result is returned",
          httpStatus: "200/201/409",
          priority: "High (H)",
        }),
      );
    }

    if (method === "DELETE" || context.relations.length > 0) {
      scenarios.push(
        this.createScenario({
          scenario: "Referential integrity and cascade behavior",
          testType: "Reliability",
          description: `${method} ${endpoint} when related child resources exist`,
          expectedResult:
            "Delete or update is either blocked or cascaded according to the documented policy",
          httpStatus: "204/409",
          priority: "High (H)",
        }),
      );
    }

    scenarios.push(
      this.createScenario({
        scenario: "Upstream dependency failure",
        testType: "Reliability",
        description: `${method} ${endpoint} when a required upstream dependency is unavailable or returns an error`,
        expectedResult:
          "Gateway or service-unavailable response is returned predictably",
        httpStatus: "502/503",
        priority: "Medium (M)",
      }),
    );

    return scenarios;
  }

  generateContractScenarios(method, endpoint, endpointInfo, context) {
    const openapi = context && context.openapi ? context.openapi : null;
    const errorCodes = openapi && Array.isArray(openapi.errorCodes) ? openapi.errorCodes : [];
    const httpStatus = errorCodes.length > 0 ? errorCodes.join("/") : "4xx/5xx";

    const errorFields =
      openapi && Array.isArray(openapi.errorContractFields)
        ? openapi.errorContractFields
        : [];

    const fieldHint =
      errorFields.length > 0
        ? ` (contract hints: ${errorFields.join(", ")})`
        : "";

    return [
      this.createScenario({
        scenario: "Structured error response contract",
        testType: "Contract",
        description: `${method} ${endpoint} error responses include structured, meaningful details such as error.code, error.message, and error.requestId (or RFC 9457 Problem Details: status/message/errors[])${fieldHint}`,
        expectedResult:
          errorFields.length > 0
            ? "Structured error payload matches the OpenAPI contract for representative error responses and includes meaningful, field-specific messages (validate RFC 9457 status/message/errors[] when applicable)"
            : "Structured error payload matches the contract for representative 4xx/5xx responses and includes meaningful, field-specific messages (validate RFC 9457 status/message/errors[] when applicable)",
        httpStatus,
        priority: "High (H)",
      }),
    ];
  }

  generatePerformanceScenarios(method, endpoint, endpointInfo) {
    const scenarios = [];

    if (method === "GET" && endpointInfo.isCollection) {
      scenarios.push(
        this.createScenario({
          scenario: "Large dataset handling",
          testType: "Performance",
          description: `GET ${endpoint} with a large dataset still responds within an acceptable time`,
          expectedResult:
            "Performance remains acceptable with pagination or cursoring in place",
          httpStatus: 200,
          priority: "Low (L)",
        }),
      );
    }

    scenarios.push(
      this.createScenario({
        scenario: "Concurrent requests",
        testType: "Performance",
        description: `Multiple concurrent ${method} ${endpoint} requests are handled safely`,
        expectedResult:
          "No data corruption and consistent responses under concurrency",
        httpStatus: "Variable",
        priority: "Medium (M)",
      }),
    );

    scenarios.push(
      this.createScenario({
        scenario: "Rate limiting",
        testType: "Performance",
        description: `${method} ${endpoint} exceeding the rate-limit threshold`,
        expectedResult:
          "429 response returned with retry guidance when applicable",
        httpStatus: 429,
        priority: "Medium (M)",
      }),
    );

    return scenarios;
  }

  determineTestLevel(testType, scenario) {
    if (testType === "Performance") {
      return "E2E";
    }

    if (
      [
        "Happy Path",
        "Security",
        "Query Behavior",
        "State Transition",
        "Reliability",
        "Contract",
      ].includes(testType)
    ) {
      return "Integration";
    }

    if (testType === "Boundary" && /Maximum page size/i.test(scenario)) {
      return "Integration";
    }

    return "Unit";
  }

  assignPriority(scenario) {
    const text =
      `${scenario.testType} ${scenario.scenario} ${scenario.description}`.toLowerCase();

    if (
      ["Happy Path", "Security", "State Transition", "Contract"].includes(
        scenario.testType,
      ) ||
      /auth|rbac|permission|delete|destructive|idempot|integrity|error\.code|expired jwt/i.test(
        text,
      )
    ) {
      return "High (H)";
    }

    if (
      /rate limit|concurrent|upstream|unsupported|filter|sort|date range|validation/i.test(
        text,
      )
    ) {
      return "Medium (M)";
    }

    return "Low (L)";
  }

  escapeCell(value) {
    return String(value).replace(/\|/g, "\\|");
  }

  formatScenarios(scenarios) {
    return scenarios
      .map(
        (scenario) =>
          `| ${this.escapeCell(scenario.scenario)} | ${this.escapeCell(scenario.testType)} | ${this.escapeCell(scenario.description)} | ${this.escapeCell(scenario.expectedResult)} | ${this.escapeCell(scenario.httpStatus)} | ${this.escapeCell(scenario.priority)} | ${this.escapeCell(scenario.testLevel)} |`,
      )
      .join("\n");
  }

  generateDependencyGraph(method, endpoint, additionalContext = "") {
    const context = this.normalizeContext(additionalContext);
    const endpointInfo = this.parseEndpoint(endpoint);
    const actionMap = {
      GET: "read",
      HEAD: "head",
      POST: "create",
      PUT: "update",
      PATCH: "patch",
      DELETE: "delete",
      OPTIONS: "options",
    };

    const currentAction = `${actionMap[method] || method.toLowerCase()}_${endpointInfo.singularResource}`;
    const nodes = [];
    const edges = [];

    const addNode = (node) => {
      if (node && !nodes.includes(node)) {
        nodes.push(node);
      }
    };

    addNode(currentAction);

    if (
      endpointInfo.hasPathParam ||
      ["PUT", "PATCH", "DELETE", "HEAD"].includes(method)
    ) {
      const createNode = `create_${endpointInfo.singularResource}`;
      addNode(createNode);
      if (createNode !== currentAction) {
        edges.push({ from: createNode, to: currentAction });
      }
    }

    context.relations.forEach((relation) => {
      const relationNode = `create_${this.singularize(relation.resource)}`;
      addNode(relationNode);
      edges.push({
        from: relationNode,
        to: currentAction,
        policy: relation.policy || "must exist first",
      });
    });

    context.transitions.forEach((transition) => {
      const fromNode = `state_${transition.from.toLowerCase()}`;
      const toNode = `state_${transition.to.toLowerCase()}`;
      addNode(fromNode);
      addNode(toNode);
      edges.push({ from: fromNode, to: toNode });
    });

    return nodes.length > 1 ? { nodes, edges } : null;
  }

  collectWarnings(method, endpoint, additionalContext = "") {
    const context = this.normalizeContext(additionalContext);
    const warnings = [];

    if (context.openapiWarnings && context.openapiWarnings.length > 0) {
      warnings.push(...context.openapiWarnings);
    }

    if (!context.openapiSpec) {
      warnings.push(
        "REST API design guideline conventions were used to shape scenario wording (pagination params, camelCase query naming, meaningful error messages, and POST/PUT payload-in-body). Verify these match your API contract.",
      );
    }

    if (
      ["POST", "PUT", "PATCH"].includes(method) &&
      context.fields.length === 0
    ) {
      warnings.push(
        "No `--fields` model was provided, so body validation scenarios are generic rather than schema-specific.",
      );
    }

    if (
      method === "GET" &&
      context.filters.length === 0 &&
      context.sortable.length === 0
    ) {
      warnings.push(
        "No `--filters` or `--sortable` hints were provided, so query behavior scenarios use generic assumptions.",
      );
    }

    if (
      (/state|status/i.test(endpoint) ||
        /state|status/i.test(context.rawText)) &&
      context.states.length === 0
    ) {
      warnings.push(
        "Lifecycle states were not supplied, so any state-transition scenarios use common defaults such as PENDING/CONFIRMED/SHIPPED/DELIVERED/CANCELLED.",
      );
    }

    if (
      context.relations.length === 0 &&
      ["POST", "PUT", "PATCH", "DELETE"].includes(method)
    ) {
      warnings.push(
        "No `--relations` hints were provided, so referential-integrity and cascade assumptions should be reviewed.",
      );
    }

    if (!/rbac|role|admin|customer|owner|tenant/i.test(context.rawText)) {
      const hasOpenApiAuth = context.openapi && context.openapi.securityPresent;
      if (!hasOpenApiAuth) {
        warnings.push(
          "RBAC rules were not provided explicitly; Admin/Customer ownership checks are included as common defaults and may need adjustment.",
        );
      }
    }

    return warnings;
  }

  formatWarnings(warnings) {
    if (warnings.length === 0) {
      return "- No unverified assumptions were recorded.";
    }

    return warnings.map((warning) => `- ⚠️ ${warning}`).join("\n");
  }

  getReferencesFileRepoPath() {
    // The generator exists in both `.cursor/...` and `.github/...` skill copies.
    // We emit a repo-root-relative link so the references remain valid in markdown.
    const skillDirNorm = String(this.skillDir).replace(/\\/g, "/").toLowerCase();
    const usesCursor = skillDirNorm.includes("/.cursor/");
    const base = usesCursor ? ".cursor" : ".github";
    return `${base}/skills/api-test-scenario-generator/references/rest-api-design-guidelines.md`;
  }

  getReferencesSection() {
    const refPath = this.getReferencesFileRepoPath();
    return `- [REST API Design guideline](${refPath})`;
  }

  generateReport(method, endpoint, additionalContext = "") {
    const context = this.normalizeContext(additionalContext);
    const enrichedContext = this.enrichContextWithOpenApi(
      method,
      endpoint,
      context,
    );
    const scenarios = this.generateScenarios(method, endpoint, enrichedContext);
    const scenarioRows = this.formatScenarios(scenarios);
    const warnings = this.collectWarnings(method, endpoint, enrichedContext);
    const dependencyGraph = this.generateDependencyGraph(
      method,
      endpoint,
      enrichedContext,
    );

    const scenarioTable = this.templates.scenarioTable.replace(
      "{{SCENARIOS}}",
      scenarioRows,
    );

    const coverageAreas = [
      "happy path",
      "validation",
      "security",
      "query behavior",
      "error contracts",
    ];

    if (context.states.length > 0 || context.transitions.length > 0) {
      coverageAreas.push("state transitions");
    }

    if (context.relations.length > 0) {
      coverageAreas.push("resource dependencies");
    }

    const overview =
      `Generated ${scenarios.length} test scenarios for ${method} ${endpoint}. ` +
      `Coverage includes ${coverageAreas.join(", ")}.`;

    const dependencyGraphSection = dependencyGraph
      ? "## Dependency Graph\n\n```json\n" +
        JSON.stringify(dependencyGraph, null, 2) +
        "\n```"
      : "";

    const implementationTips = this.generateImplementationTips(
      method,
      endpoint,
      context,
    );

    const referencesSection = this.getReferencesSection();

    const fullReport = this.templates.fullReport
      .replace("{{METHOD}}", method)
      .replace("{{ENDPOINT}}", endpoint)
      .replace("{{DATE}}", new Date().toLocaleDateString())
      .replace("{{OVERVIEW}}", overview)
      .replace("{{SCENARIO_TABLE}}", scenarioTable)
      .replace("{{DEPENDENCY_GRAPH_SECTION}}", dependencyGraphSection)
      .replace("{{WARNINGS_SECTION}}", this.formatWarnings(warnings))
      .replace("{{REFERENCES_SECTION}}", referencesSection)
      .replace("{{IMPLEMENTATION_TIPS}}", implementationTips);

    return {
      table: scenarioTable,
      fullReport,
      scenarios,
      dependencyGraph,
      warnings,
    };
  }

  generateImplementationTips(method, endpoint, context) {
    const tips = [];

    tips.push(
      "- Cover `High (H)` scenarios first; they protect auth, critical flows, and data integrity.",
    );
    tips.push(
      "- Use data builders or factories so boundary and invalid payload tests stay readable.",
    );
    tips.push(
      "- Keep unit tests focused on validation and business rules; move API contracts and RBAC checks to integration tests.",
    );
    tips.push(
      "- Use realistic ownership and tenant data for RBAC scenarios instead of generic fixtures.",
    );

    if (method === "GET") {
      tips.push(
        "- Verify filtering, sorting, pagination, and date-range rules against explicit allow-lists.",
      );
    }

    if (["POST", "PUT", "PATCH"].includes(method)) {
      tips.push(
        "- Validate request and error-response schemas, including fields like `error.code` and `error.requestId`.",
      );
      tips.push(
        "- Add duplicate-submission coverage using `Idempotency-Key` where the API contract supports it.",
      );
    }

    if (
      context.states.length > 0 ||
      context.transitions.length > 0 ||
      /state|status/i.test(endpoint)
    ) {
      tips.push(
        "- Cover each allowed state transition once and at least one invalid transition that should be blocked.",
      );
    }

    tips.push(
      "- Reserve E2E tests for a few critical cross-system journeys and keep the rest at unit/integration level.",
    );

    return tips.join("\n");
  }
}

if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.error(
      "Usage: node generate-scenarios.js <HTTP_METHOD> <ENDPOINT> [--fields ...] [--states ...] [--transitions ...] [--filters ...] [--sortable ...] [--relations ...] [--openapiSpec PATH_OR_JSON_OR_YAML] [--openapiOperationId OPERATION_ID] [additional_context]",
    );
    console.error(
      "Example: node generate-scenarios.js POST /api/users --fields name:string:required",
    );
    process.exit(1);
  }

  const [method, endpoint, ...contextArgs] = args;
  const parsedContext = parseCommandLineContext(contextArgs);

  const generator = new APITestScenarioGenerator();
  const result = generator.generateReport(
    method.toUpperCase(),
    endpoint,
    parsedContext,
  );

  console.log(result.table);
}

module.exports = APITestScenarioGenerator;
