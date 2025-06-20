<div align="center">
<img src="man/figures/logo.png" />
</div>

mcpr is an R implementation of the [Model Context Protocol (MCP)](https://modelcontextprotocol.io),
enabling R applications to expose capabilities (tools, resources, and prompts)
to AI models through a standard JSON-RPC 2.0 interface. It also provides client
functionality to connect to and interact with MCP servers.

See the official [MCP documentation](https://modelcontextprotocol.io) for more information,
particularly on schemas and capabilities.
Visit [package docs](https://mcpr.opifex.org/) for more information on the R implementation.

## Installation

You can install mcpr from GitHub using the [pak](https://pak.r-lib.org/) package:

```r
pak::pkg_install("devOpifex/mcpr")
```

## Basic Usage

### Server

Here's a simple example that creates an MCP server with a calculator tool:

```r
library(mcpr)

calculator <- new_tool(
  name = "calculator",
  description = "Performs basic arithmetic operations",
  input_schema = schema(
    properties = properties(
      operation = property_enum(
        "Operation", 
        "Math operation to perform", 
        values = c("add", "subtract", "multiply", "divide"),
        required = TRUE
      ),
      a = property_number("First number", "First operand", required = TRUE),
      b = property_number("Second number", "Second operand", required = TRUE)
    )
  ),
  handler = function(params) {
    result <- switch(params$operation,
      "add" = params$a + params$b,
      "subtract" = params$a - params$b,
      "multiply" = params$a * params$b,
      "divide" = params$a / params$b
    )

    response_text(result)
  }
)

mcp <- new_mcp(
  name = "R Calculator Server",
  description = "A simple calculator server implemented in R",
  version = "1.0.0"
)

mcp <- add_capability(mcp, calculator)

serve_io(mcp)
```

You can return multiple responses by returning a list of `response` objects:

```r
response(
  response_text("Hello, world!"),
  response_image(system.file("extdata/logo.png", package = "mcpr")),
  response_audio(system.file("extdata/sound.mp3", package = "mcpr")),
  response_video(system.file("extdata/video.mp4", package = "mcpr")),
  response_file(system.file("extdata/file.txt", package = "mcpr")),
  response_resource(system.file("extdata/resource.json", package = "mcpr"))
)
```

You can also serve via HTTP transport with `serve_http`:

```r
# Serve via HTTP on port 3000
serve_http(mcp, port = 3000)
```

See the [Get Started](https://mcpr.opifex.org/articles/get-started) guide for more information.

## MCP Roclet for Automatic Server Generation

mcpr includes a roxygen2 roclet that can automatically generate MCP servers from your R functions using special documentation tags. This provides a convenient way to expose existing R functions as MCP tools.

### Usage

1. Add `@mcp` and `@type` tags to your function documentation:

```r
#' Add two numbers
#' @param x First number
#' @param y Second number  
#' @type x number
#' @type y number
#' @mcp add_numbers Add two numbers together
add_numbers <- function(x, y) {
  x + y
}
```

2. Generate the MCP server using roxygen2:

```r
# Generate documentation and MCP server
roxygen2::roxygenise(roclets = c("rd", "mcpr::mcp_roclet"))
```

This will create an MCP server file at `inst/mcp_server.R` that includes:
- Tool definitions for all functions with `@mcp` tags
- Proper input schemas based on `@type` tags
- Handler functions that call your original R functions
- A complete, runnable MCP server

### Supported Types

The `@type` tag supports these parameter types:
- `string` - Text values
- `number` - Numeric values (integers and decimals)
- `integer` - Integer values
- `boolean` - True/false values
- `array` - Lists/vectors
- `object` - Complex R objects
- `enum:value1,value2,value3` - Enumerated values

### Example Generated Server

```r
# Generated MCP server code
add_numbers_tool <- new_tool(
  name = "add_numbers",
  description = "Add two numbers together", 
  input_schema = schema(
    properties = properties(
      x = property_number("x", "First number", required = TRUE),
      y = property_number("y", "Second number", required = TRUE)
    )
  ),
  handler = function(params) {
    result <- add_numbers(params$x, params$y)
    response_text(result)
  }
)

mcp_server <- new_server(
  name = "Auto-generated MCP Server",
  description = "MCP server generated from R functions with @mcp tags",
  version = "1.0.0"
)

mcp_server <- add_capability(mcp_server, add_numbers_tool)
serve_io(mcp_server)
```

### Client

Here's a simple example of using the client to interact with an MCP server:

```r
library(mcpr)

# Create a client that connects to an MCP server
# For HTTP transport
client <- new_client_http(
  "http://localhost:8080",
  name = "calculator",
  version = "1.0.0"
)

# Or for standard IO transport
# client <- new_client_io(
#   "Rscript",
#   "/path/to/server.R",
#   name = "calculator",
#   version = "1.0.0"
# )

# List available tools
tools <- tools_list(client)
print(tools)

# Call a tool
result <- tools_call(
  client,
  params = list(
    name = "calculator",
    arguments = list(
      operation = "add",
      a = 5,
      b = 3
    )
  ),
  id = 1L
)
print(result)

# List available prompts
prompts <- prompts_list(client)
print(prompts)

# List available resources
resources <- resources_list(client)
print(resources)

# Read a resource
resource_content <- resources_read(
  client,
  params = list(
    name = "example-resource"
  )
)
print(resource_content)
```

## ellmer integration

Now supports ellmer tools, you can use ellmer's or mcpr's tools,
interchangeably.

See the example below, taken from the
[ellmer documentation](https://ellmer.tidyverse.org/articles/tool-calling.html#defining-a-tool-function)

```r
# create an ellmer tool
current_time <- ellmer::tool(
  \(tz = "UTC") {
    format(Sys.time(), tz = tz, usetz = TRUE)
  },
  "Gets the current time in the given time zone.",
  tz = ellmer::type_string(
    "The time zone to get the current time in. Defaults to `\"UTC\"`.",
    required = FALSE
  )
)

mcp <- new_server(
  name = "R Calculator Server",
  description = "A simple calculator server implemented in R",
  version = "1.0.0"
)

# register ellmer tool with mcpr server
mcp <- add_capability(mcp, current_time)

serve_io(mcp)
```

## Using mcpr

### Claude Code Integration

To use your MCP server with Claude Code, see the [documentation](https://docs.anthropic.com/en/docs/claude-code/tutorials#set-up-model-context-protocol-mcp)

```bash
claude mcp add r-calculator -- Rscript /path/to/calculator_server.R
```

### Cursor Integration

To integrate with Cursor see the [documentation](https://docs.cursor.com/context/model-context-protocol)

```json
{
  "customCommands": {
    "r-calculator": {
      "command": "Rscript 'path/to/calculator_server.R'"
    }
  }
}
```
### VS Code Agent Mode Integration
To integrate with VS Code Agent mode see the [documentation](https://code.visualstudio.com/docs/copilot/chat/mcp-servers#_add-an-mcp-server-to-your-user-settings)
```json
"mcp": {
        "servers": {
            "my-mcp-server-calculator": {
                "type": "stdio",
                "command": "Rscript",
                "args": [
                    "path/to/calculator_server.R"
                ]
            }
      }
}
```
More integrations in the [docs](https://mcpr.opifex.org/articles/client-integration)
