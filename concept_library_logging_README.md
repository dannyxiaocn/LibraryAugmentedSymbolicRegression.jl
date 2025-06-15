# Concept Library Logging System

## Overview

This document describes the new concept library logging system implemented for LibraryAugmentedSymbolicRegression.jl. The system replaces emoji-based console output with structured logging to a dedicated log file, providing clear and professional tracking of concept library changes.

## Features

### 1. Structured Logging Format
- **timestamp**: All log entries include precise timestamps in `yyyy-mm-dd HH:MM:SS` format
- **Clear categories**: Each log entry is categorized with clear prefixes (INITIALIZATION, UPDATE, ANALYSIS_INPUT, etc.)
- **No emojis**: Professional, text-based logging without decorative elements
- **Structured data**: Consistent format makes it easy to parse logs programmatically

### 2. Comprehensive Tracking

#### Initialization
- Records when concept library databases are created
- Logs initial state of each dataset's concept library

#### Updates
- Tracks database size changes with precise before/after counts
- Records number of ideas extracted vs evolved
- Logs analysis input (dominating and worst expressions processed)
- Documents each new idea added to the library
- Shows current top ideas after each update

#### Context Sampling
- Logs when ideas are sampled from the library for context
- Records which specific ideas were selected

#### Prompt Evolution
- Tracks when new ideas are generated through evolution
- Logs successful and failed evolution attempts

#### Final Summary
- Comprehensive report at search completion
- Shows final state of all concept libraries
- Lists top ideas for each dataset

## Log File Structure

### Default Behavior
- Log file: `concept_library.log` (created in working directory)
- Appends to existing file (preserves history across runs)
- Also prints to console for immediate feedback

### Log Entry Format
```
[TIMESTAMP] CATEGORY: Message with specific details
```

### Categories
- `INITIALIZATION`: System startup and database creation
- `DATASET`: Dataset initialization and status
- `UPDATE_DATASET`: Database updates
- `ANALYSIS_INPUT_DATASET`: Input data for LLM analysis
- `NEW_IDEA_X`: New ideas extracted from analysis (X = idea number)
- `EVOLVED_IDEA_X`: Ideas generated through evolution
- `CURRENT_TOP_IDEAS`: Current state of top ideas
- `TOP_IDEA_X`: Individual top ideas (X = rank)
- `CONTEXT_SAMPLING`: Idea sampling for context
- `CONTEXT_SAMPLING_RESULT`: Results of context sampling
- `PROMPT_EVOLUTION`: Evolution process results
- `ERROR_DATASET`: Dataset-specific errors
- `ERROR_PROMPT_EVOLUTION`: Evolution-specific errors
- `FINAL_SUMMARY`: Search completion summary
- `FINAL_DATASET`: Final state summary
- `FINAL_TOP_IDEA_X`: Final top ideas (X = rank)

## Implementation Details

### Core Functions

#### `concept_library_logger(message::String, log_file::String="concept_library.log")`
- Core logging function
- Adds timestamp and writes to both file and console
- Thread-safe file operations

#### `log_concept_library_init(num_datasets::Int, log_file::String="concept_library.log")`
- Called during system initialization
- Records creation of concept library databases
- Logs initial state for each dataset

#### `log_concept_library_update(...)`
- Called when concept libraries are updated
- Comprehensive logging of all changes
- Tracks ideas added, evolved, and current state

#### `log_concept_library_final_summary(idea_database_all::Vector{Vector{String}}, log_file::String="concept_library.log")`
- Called at search completion
- Generates comprehensive final report
- Shows accumulated ideas and top performers

### Integration Points

The logging system is integrated at key points in the search process:

1. **Initialization**: `LaSR.jl` and `SymbolicRegression.jl` during startup
2. **Updates**: `update_idea_database()` function in `LLMFunctions.jl`
3. **Context Sampling**: `sample_context()` function
4. **Prompt Evolution**: `prompt_evol()` function
5. **Final Summary**: End of search in main loop

## Migration from Old System

### Removed Elements
- All emoji symbols (🚀, 💡, 🔄, 📊, ➕, ✅, 📋, etc.)
- Inconsistent formatting
- Mixed console-only output

### Preserved Information
- All original data tracking
- Concept library size changes
- Idea content and evolution
- Analysis input details
- Top idea rankings

## Usage Examples

### Reading Logs Programmatically
```julia
# Simple log parsing example
function parse_concept_log(filename="concept_library.log")
    entries = []
    for line in eachline(filename)
        if startswith(line, "[")
            timestamp_end = findfirst("] ", line)
            if timestamp_end !== nothing
                timestamp = line[2:timestamp_end[1]-1]
                content = line[timestamp_end[2]+1:end]
                push!(entries, (timestamp=timestamp, content=content))
            end
        end
    end
    return entries
end
```

### Filtering Specific Events
```julia
# Extract only update events
function get_updates(log_entries)
    return filter(e -> startswith(e.content, "UPDATE_DATASET"), log_entries)
end

# Extract final summary
function get_final_summary(log_entries)
    return filter(e -> startswith(e.content, "FINAL_"), log_entries)
end

# Extract new ideas
function get_new_ideas(log_entries)
    return filter(e -> startswith(e.content, "NEW_IDEA_"), log_entries)
end
```

## Configuration

### Custom Log File
You can specify a custom log file by modifying the `log_file` parameter in the logging functions, or by setting it globally in your configuration.

### Log Rotation
For long-running experiments, consider implementing log rotation:
```julia
# Archive old log before starting new run
if isfile("concept_library.log")
    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    mv("concept_library.log", "concept_library_$timestamp.log")
end
```

## Benefits

1. **Professional Output**: Clean, structured logs suitable for production environments
2. **Easy Analysis**: Consistent format enables programmatic analysis
3. **Complete History**: Persistent file-based logging preserves full history
4. **Debugging**: Detailed error logging helps diagnose issues
5. **Research**: Structured data supports research analysis and paper writing
6. **Monitoring**: Easy to monitor concept library evolution over time

## Future Enhancements

Potential improvements to consider:
- JSON structured logging for even easier parsing
- Log level configuration (DEBUG, INFO, WARN, ERROR)
- Integration with logging frameworks
- Automated log analysis and reporting tools
- Web-based log viewer
- Performance metrics logging 