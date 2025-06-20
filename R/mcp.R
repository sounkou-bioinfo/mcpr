#' Create a new MCP object
#'
#' @param name Name of the MCP server
#' @type name string
#' @param description Description of the MCP server
#' @type description string
#' @param version Version of the MCP server
#' @type version string
#' @param tools List of tools (optional)
#' @type tools array
#' @param resources List of resources (optional)
#' @type resources array
#' @param prompts List of prompts (optional)
#' @type prompts array
#' @param ... Forwarded to [new_server()]
#'
#' @return A new MCP object
#' @mcp create_mcp_server Create a new MCP server with specified name, description, and version
#' @export
#'
#' @examples
#' mcp <- new_server(
#'   name = "My MCP",
#'   description = "This is a description",
#'   version = "1.0.0"
#' )
#' @name new_server
new_server <- function(
  name,
  description,
  version,
  tools = list(),
  resources = list(),
  prompts = list()
) {
  # Validate inputs
  if (missing(name)) {
    stop("name is required")
  }
  if (missing(description)) {
    stop("description is required")
  }
  if (missing(version)) {
    stop("version is required")
  }
  if (!is.character(version) || length(version) != 1) {
    stop("version must be a single character string")
  }
  if (!is.character(name) || length(name) != 1) {
    stop("name must be a single character string")
  }
  if (!is.character(description) || length(description) != 1) {
    stop("description must be a single character string")
  }
  if (!is.list(tools)) {
    stop("tools must be a list")
  }
  if (!is.list(resources)) {
    stop("resources must be a list")
  }
  if (!is.list(prompts)) {
    stop("prompts must be a list")
  }

  # Create the structure
  server <- list(
    tools = tools,
    resources = resources,
    prompts = prompts,
    version = version,
    capabilities = list(
      tools = list(
        listChanged = FALSE
      ),
      resources = list(
        subscribe = FALSE,
        listChanged = FALSE
      ),
      prompts = list(
        listChanged = FALSE
      )
    )
  )

  structure(
    server,
    initialized = FALSE,
    name = name,
    description = description,
    class = c("server", class(server))
  )
}

#' @rdname new_server
#' @export
new_mcp <- function(...) {
  .Deprecated("new_server")
  new_server(...)
}

#' Create a new tool
#'
#' @param name Name of the tool
#' @type name string
#' @param description Description of the tool  
#' @type description string
#' @param input_schema Input schema for the tool (must be a schema object)
#' @type input_schema object
#' @param handler Function to handle the tool execution
#' @type handler object
#'
#' @return A new tool capability
#' @mcp create_mcp_tool Create a new MCP tool with input schema and handler function
#' @export
#'
#' @examples
#' tool <- new_tool(
#'   name = "My Tool",
#'   description = "This is a description",
#'   input_schema = schema(
#'     properties = list(
#'       input1 = property_string("Input 1", "Description of input 1"),
#'       input2 = property_number("Input 2", "Description of input 2")
#'     )
#'   ),
#'   handler = function(input) {
#'     # Process the input here
#'     return(input)
#'   }
#' )
new_tool <- function(
  name,
  description,
  input_schema,
  handler
) {
  stopifnot(
    !missing(name),
    !missing(description),
    !missing(input_schema),
    !missing(handler)
  )

  if (!inherits(input_schema, "schema")) {
    stop("input_schema must be a schema object")
  }

  if (!is.function(handler)) {
    stop("handler must be a function")
  }

  cap <- new_capability(
    name = name,
    description = description,
    inputSchema = input_schema,
    type = "tool"
  )

  attr(cap, "handler") <- handler

  cap
}

#' Create a new resource
#'
#' @param name Name of the resource
#' @type name string
#' @param description Description of the resource
#' @type description string
#' @param uri URI of the resource
#' @type uri string
#' @param mime_type MIME type of the resource (optional)
#' @type mime_type string
#' @param handler Function to handle the resource request
#' @type handler object
#'
#' @return A new resource capability
#' @mcp create_mcp_resource Create a new MCP resource with URI and MIME type
#' @export
#'
#' @examples
#' resource <- new_resource(
#'   name = "My Resource",
#'   description = "This is a description",
#'   uri = "https://example.com/resource",
#'   mime_type = "text/plain",
#'   handler = function(params) {
#'     # Process the resource request
#'     return(list(content = "Resource content"))
#'   }
#' )
new_resource <- function(name, description, uri, mime_type = NULL, handler) {
  stopifnot(
    !missing(name),
    !missing(description),
    !missing(uri),
    !missing(handler)
  )

  if (!is.function(handler)) {
    stop("handler must be a function")
  }

  cap <- new_capability(
    name = name,
    description = description,
    uri = uri,
    mimeType = mime_type,
    type = "resource"
  )

  attr(cap, "handler") <- handler

  cap
}

#' Create a new prompt
#'
#' @param name Name of the prompt
#' @type name string
#' @param description Description of the prompt
#' @type description string
#' @param arguments List of arguments for the prompt
#' @type arguments array
#' @param handler Function to handle the prompt execution
#' @type handler object
#'
#' @return A new prompt capability
#' @mcp create_mcp_prompt Create a new MCP prompt with arguments and handler function
#' @export
#'
#' @examples
#' prompt <- new_prompt(
#'   name = "My Prompt",
#'   description = "This is a description",
#'   arguments = list(
#'     input1 = list(
#'       type = "string",
#'       description = "Input 1"
#'     ),
#'     input2 = list(
#'       type = "number",
#'       description = "Input 2"
#'     )
#'   ),
#'   handler = function(params) {
#'     # Process the prompt request
#'     return(list(text = "Generated text from prompt"))
#'   }
#' )
new_prompt <- function(name, description, arguments = list(), handler) {
  stopifnot(
    !missing(name),
    !missing(description),
    !missing(handler)
  )

  if (!is.function(handler)) {
    stop("handler must be a function")
  }

  cap <- new_capability(
    name = name,
    description = description,
    arguments = arguments,
    type = "prompt"
  )

  attr(cap, "handler") <- handler

  cap
}

new_capability <- function(
  name,
  description,
  ...,
  type = c("tool", "resource", "prompt")
) {
  stopifnot(!missing(name), !missing(description))
  type <- match.arg(type)

  structure(
    list(
      name = name,
      description = description,
      ...
    ),
    class = c("capability", type, "list")
  )
}

#' Add a capability to an MCP object
#'
#' @param mcp An MCP server object
#' @type mcp object
#' @param capability A tool, resource, or prompt capability object
#' @type capability object
#'
#' @return The MCP object with the capability added
#' @mcp add_mcp_capability Add a tool, resource, or prompt capability to an existing MCP server
#' @export
add_capability <- function(mcp, capability) {
  UseMethod("add_capability", capability)
}

#' @export
#' @method add_capability ellmer::ToolDef
`add_capability.ellmer::ToolDef` <- function(mcp, capability) {
  capability <- ellmer_to_mcpr_tool(capability)
  mcp$tools[[capability$name]] <- capability
  invisible(mcp)
}

#' @export
#' @method add_capability tool
add_capability.tool <- function(mcp, capability) {
  mcp$tools[[capability$name]] <- capability
  invisible(mcp)
}


#' @export
#' @method add_capability resource
add_capability.resource <- function(mcp, capability) {
  mcp$resources[[capability$name]] <- capability
  invisible(mcp)
}

#' @export
#' @method add_capability prompt
add_capability.prompt <- function(mcp, capability) {
  mcp$prompts[[capability$name]] <- capability
  invisible(mcp)
}
