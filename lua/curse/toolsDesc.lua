return [[{
  "tools": [
    {
      "type": "function",
      "function": {
        "name": "codebase_search",
        "description": "Find snippets of code from the codebase most relevant to the search query.",
        "parameters": {
          "type": "object",
          "properties": {
            "query": {
              "type": "string",
              "description": "The search query to find relevant code."
            },
            "target_directories": {
              "type": "array",
              "items": {
                "type": "string"
              },
              "description": "Glob patterns for directories to search over."
            },
            "explanation": {
              "type": "string",
              "description": "One sentence explanation as to why this tool is being used."
            }
          },
          "required": ["query"]
        }
      }
    },
    
    {
      "type": "function",
      "function": {
        "name": "read_file",
        "description": "Read the contents of a file.",
        "parameters": {
          "type": "object",
          "properties": {
            "relative_workspace_path": {
              "type": "string",
              "description": "The path of the file to read, relative to the workspace root."
            },
            "start_line_one_indexed": {
              "type": "integer",
              "description": "The one-indexed line number to start reading from (inclusive)."
            },
            "end_line_one_indexed_inclusive": {
              "type": "integer",
              "description": "The one-indexed line number to end reading at (inclusive)."
            },
            "should_read_entire_file": {
              "type": "boolean",
              "description": "Whether to read the entire file."
            },
            "explanation": {
              "type": "string",
              "description": "One sentence explanation as to why this tool is being used."
            }
          },
          "required": [
            "relative_workspace_path",
            "start_line_one_indexed",
            "end_line_one_indexed_inclusive",
            "should_read_entire_file"
          ]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "run_terminal_cmd",
        "description": "Run a terminal command on the user's system.",
        "parameters": {
          "type": "object",
          "properties": {
            "command": {
              "type": "string",
              "description": "The terminal command to execute."
            },
            "is_background": {
              "type": "boolean",
              "description": "Whether the command should be run in the background."
            },
            "require_user_approval": {
              "type": "boolean",
              "description": "Whether the user must approve the command before execution."
            },
            "explanation": {
              "type": "string",
              "description": "One sentence explanation as to why this command needs to be run."
            }
          },
          "required": ["command", "is_background", "require_user_approval"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "list_dir",
        "description": "List the contents of a directory.",
        "parameters": {
          "type": "object",
          "properties": {
            "relative_workspace_path": {
              "type": "string",
              "description": "Path to list contents of, relative to the workspace root."
            },
            "explanation": {
              "type": "string",
              "description": "One sentence explanation as to why this tool is being used."
            }
          },
          "required": ["relative_workspace_path"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "grep_search",
        "description": "Fast text-based regex search within files or directories.",
        "parameters": {
          "type": "object",
          "properties": {
            "query": {
              "type": "string",
              "description": "The regex pattern to search for."
            },
            "case_sensitive": {
              "type": "boolean",
              "description": "Whether the search should be case sensitive."
            },
            "include_pattern": {
              "type": "string",
              "description": "Glob pattern for files to include (e.g., '*.py')."
            },
            "exclude_pattern": {
              "type": "string",
              "description": "Glob pattern for files to exclude."
            },
            "explanation": {
              "type": "string",
              "description": "One sentence explanation as to why this tool is being used."
            }
          },
          "required": ["query"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "edit_file",
        "description": "Propose an edit to an existing file.",
        "parameters": {
          "type": "object",
          "properties": {
            "target_file": {
              "type": "string",
              "description": "The target file to modify (relative path in the workspace)."
            },
            "code_edit": {
              "type": "string",
              "description": "The precise lines of code to edit, with unchanged code represented as comments."
            },
            "instructions": {
              "type": "string",
              "description": "A single sentence instruction describing the edit."
            },
            "blocking": {
              "type": "boolean",
              "description": "Whether this edit should block further edits until complete."
            }
          },
          "required": ["target_file", "code_edit", "instructions", "blocking"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "file_search",
        "description": "Fast file search based on fuzzy matching against file paths.",
        "parameters": {
          "type": "object",
          "properties": {
            "query": {
              "type": "string",
              "description": "Fuzzy filename to search for."
            },
            "explanation": {
              "type": "string",
              "description": "One sentence explanation as to why this tool is being used."
            }
          },
          "required": ["query", "explanation"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "delete_file",
        "description": "Delete a file at the specified path.",
        "parameters": {
          "type": "object",
          "properties": {
            "target_file": {
              "type": "string",
              "description": "The path of the file to delete, relative to the workspace root."
            },
            "explanation": {
              "type": "string",
              "description": "One sentence explanation as to why this tool is being used."
            }
          },
          "required": ["target_file"]
        }
      }
    },
    {
      "type": "function",
      "function": {
        "name": "reapply",
        "description": "Reapply the last edit to a file if the initial application was incorrect.",
        "parameters": {
          "type": "object",
          "properties": {
            "target_file": {
              "type": "string",
              "description": "The relative path to the file to reapply the last edit to."
            }
          },
          "required": ["target_file"]
        }
      }
    },

    {
      "type": "function",
      "function": {
        "name": "parallel_apply",
        "description": "Apply similar edits to multiple files in parallel.",
        "parameters": {
          "type": "object",
          "properties": {
            "edit_plan": {
              "type": "string",
              "description": "A detailed description of the parallel edits to be applied."
            },
            "edit_regions": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "relative_workspace_path": {
                    "type": "string",
                    "description": "The path to the file to edit."
                  },
                  "start_line": {
                    "type": "integer",
                    "description": "The start line of the region to edit (1-indexed)."
                  },
                  "end_line": {
                    "type": "integer",
                    "description": "The end line of the region to edit (1-indexed)."
                  }
                },
                "required": ["relative_workspace_path"]
              }
            }
          },
          "required": ["edit_plan", "edit_regions"]
        }
      }
    }
  ]
}]]
