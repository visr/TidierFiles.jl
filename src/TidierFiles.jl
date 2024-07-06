module TidierFiles

using CSV
using DataFrames
using XLSX
using Dates #bc XLSX type parsing does not seem to be working so i made some auto parsers for read_excel 
using HTTP
using ReadStatTables
using Reexport
using Parquet2
using Arrow

@reexport using DataFrames: DataFrame

export read_csv, write_csv, read_tsv, write_tsv, read_table, write_table, read_delim, read_xlsx, write_xlsx, 
 read_fwf, write_fwf, fwf_empty, fwf_positions, fwf_positions, read_sav, read_sas, read_dta, write_sav, write_sas, 
 write_dta, read_arrow, write_arrow, read_parquet, write_parquet, read_csv2
 

include("docstrings.jl")
include("fwf.jl")
include("xlfiles.jl")
include("statsfiles.jl")
include("parquet_files.jl")
include("arrow_files.jl")

"""
$docstring_read_csv
"""
function read_csv(file;
                  delim=',',
                  col_names=true,
                  skip=0,
                  n_max=Inf,
                  col_select=nothing,
                  comment=nothing,
                  missingstring="",
                  escape_double=true,
                  ntasks::Int = Threads.nthreads(),  # Default ntasks value
                  num_threads::Union{Int, Nothing}=nothing) # Optional num_threads

    # Use num_threads if provided, otherwise stick with ntasks
    effective_ntasks = isnothing(num_threads) ? ntasks : num_threads
    
    # Convert n_max from Inf to Nothing for compatibility with CSV.File's limit argument
    limit = isinf(n_max) ? nothing : Int(n_max)

    # Calculate skipto and header correctly
    skipto = skip + (col_names === true ? 1 : 0)

    # Prepare arguments for CSV.read, including the effective number of tasks to use
    read_options = (
        delim = delim,
        header = col_names === true ? 1 : 0,
        skipto = skipto + 1,
        footerskip = 0,
        select = col_select,
        limit = limit,
        comment = comment,
        missingstring = missingstring,
        escapechar = escape_double ? '"' : '\\',
        quotechar = '"',
        normalizenames = false,
        ntasks = effective_ntasks > 1
    )


    # Filter options to remove any set to `nothing`
   # clean_options = Dict{Symbol,Any}(filter(p -> !isnothing(p[2]), read_options))

    # Check if the file is a URL and read accordingly
    if startswith(file, "http://") || startswith(file, "https://")
        # Fetch the content from the URL
        response = HTTP.get(file)
        
        # Ensure the request was successful
        if response.status != 200
            error("Failed to fetch the CSV file: HTTP status code ", response.status)
        end

        # Read the CSV data from the fetched content using cleaned options
        df = CSV.File(IOBuffer(response.body); read_options...) |> DataFrame
    else
        # Read from a local file using cleaned options
        df = CSV.File(file; read_options...) |> DataFrame
    end

    return df
end

"""
$docstring_read_delim
"""
function read_delim(file;
                  delim='\t',
                  decimal = '.',
                  col_names=true,
                  skip=0,
                  n_max=Inf,
                  groupmark=nothing,
                  col_select=nothing,
                  comment=nothing,
                  missingstring="",
                  escape_double=true,
                  ntasks::Int = Threads.nthreads(),  # Default ntasks value
                  num_threads::Union{Int, Nothing}=nothing) # Optional num_threads

    # Use num_threads if provided, otherwise stick with ntasks
    effective_ntasks = isnothing(num_threads) ? ntasks : num_threads
    
    # Convert n_max from Inf to Nothing for compatibility with CSV.File's limit argument
    limit = isinf(n_max) ? nothing : Int(n_max)

    # Calculate skipto and header correctly
    skipto = skip + (col_names === true ? 1 : 0)

    # Prepare arguments for CSV.read, including the effective number of tasks to use
    read_options = (
        delim = delim,
        decimal = decimal,
        header = col_names === true ? 1 : 0,
        skipto = skipto + 1,
        select = col_select,
        groupmark=groupmark,
        footerskip = 0,
        limit = limit,
        comment = comment,
        missingstring = missingstring,
        escapechar = escape_double ? '"' : '\\',
        quotechar = '"',
        normalizenames = false,
        ntasks = effective_ntasks > 1
    )
    # Filter options to remove any set to `nothing`
  #  clean_options = Dict{Symbol,Any}(filter(p -> !isnothing(p[2]), read_options))

    # Read the file into a DataFrame
    if startswith(file, "http://") || startswith(file, "https://")
        # Fetch the content from the URL
        response = HTTP.get(file)
        
        # Ensure the request was successful
        if response.status != 200
            error("Failed to fetch the delim file: HTTP status code ", response.status)
        end

        # Read the CSV data from the fetched content using cleaned options
        df = CSV.File(IOBuffer(response.body); read_options...) |> DataFrame
    else
        # Read from a local file using cleaned options
        df = CSV.File(file; read_options...) |> DataFrame
    end
    return df
end

"""
$docstring_read_tsv
"""
function read_tsv(file;
                  delim='\t',
                  col_names=true,
                  skip=0,
                  n_max=Inf,
                  col_select=nothing,
                  comment=nothing,
                  missingstring="",
                  escape_double=true,
                  ntasks::Int = Threads.nthreads(),  # Default ntasks value
                  num_threads::Union{Int, Nothing}=nothing) # Optional num_threads
                 
    # Use num_threads if provided, otherwise stick with ntasks
    effective_ntasks = isnothing(num_threads) ? ntasks : num_threads
    
    # Convert n_max from Inf to Nothing for compatibility with CSV.File's limit argument
    limit = isinf(n_max) ? nothing : Int(n_max)

    # Calculate skipto and header correctly
    skipto = skip + (col_names === true ? 1 : 0)

    # Prepare arguments for CSV.read, including the effective number of tasks to use
    read_options = (
        delim = delim,
        header = col_names === true ? 1 : 0,
        skipto = skipto + 1,
        footerskip = 0,
        limit = limit,
        select = col_select,
        comment = comment,
        missingstring = missingstring,
        escapechar = escape_double ? '"' : '\\',
        quotechar = '"',
        normalizenames = false,
        ntasks = effective_ntasks > 1
    )
    # Read the TSV file into a DataFrame
    if startswith(file, "http://") || startswith(file, "https://")
        # Fetch the content from the URL
        response = HTTP.get(file)
        
        # Ensure the request was successful
        if response.status != 200
            error("Failed to fetch the TSV file: HTTP status code ", response.status)
        end

        # Read the CSV data from the fetched content using cleaned options
        df = CSV.File(IOBuffer(response.body); read_options...) |> DataFrame
    else
        # Read from a local file using cleaned options
        df = CSV.File(file; read_options...) |> DataFrame
    end
    return df
end


#"""
#$docstring_read_csv2
#"""
function read_csv2(file;
                  delim=';',
                  decimal = ',',
                  col_names=true,
                  groupmark=nothing,
                  skip=0,
                  n_max=Inf,
                  col_select=nothing,
                  comment=nothing,
                  missingstring="",
                  escape_double=true,
                  ntasks::Int = Threads.nthreads(),  # Default ntasks value
                  num_threads::Union{Int, Nothing}=nothing) # Optional num_threads

    # Use num_threads if provided, otherwise stick with ntasks
    effective_ntasks = isnothing(num_threads) ? ntasks : num_threads
    
    # Convert n_max from Inf to Nothing for compatibility with CSV.File's limit argument
    limit = isinf(n_max) ? nothing : Int(n_max)

    # Calculate skipto and header correctly
    skipto = skip + (col_names === true ? 1 : 0)

    # Prepare arguments for CSV.read, including the effective number of tasks to use
    read_options = (
        delim = delim,
        decimal = decimal,
        header = col_names === true ? 1 : 0,
        groupmark = groupmark,
        skipto = skipto + 1,
        footerskip = 0,
        select = col_select,
        limit = limit,
        comment = comment,
        missingstring = missingstring,
        escapechar = escape_double ? '"' : '\\',
        quotechar = '"',
        normalizenames = false,
        ntasks = effective_ntasks > 1
    )


    # Filter options to remove any set to `nothing`
   # clean_options = Dict{Symbol,Any}(filter(p -> !isnothing(p[2]), read_options))

    # Check if the file is a URL and read accordingly
    if startswith(file, "http://") || startswith(file, "https://")
        # Fetch the content from the URL
        response = HTTP.get(file)
        
        # Ensure the request was successful
        if response.status != 200
            error("Failed to fetch the CSV file: HTTP status code ", response.status)
        end

        # Read the CSV data from the fetched content using cleaned options
        df = CSV.File(IOBuffer(response.body); read_options...) |> DataFrame
    else
        # Read from a local file using cleaned options
        df = CSV.File(file; read_options...) |> DataFrame
    end

    return df
end








"""
$docstring_read_table
"""
function read_table(file; 
        col_names=true, 
        skip=0, 
        n_max=Inf, 
        comment=nothing, 
        col_select=nothing,
        missingstring="",
        kwargs...)
    # Open the file and preprocess the lines
    processed_lines, header = open(file, "r") do io
        lines = readlines(io)
        lines = map(line -> replace(line, r"\s+" => " "), lines)

        # Filter out commented lines if a comment character is specified
        if !isnothing(comment)
            lines = filter(line -> !startswith(line, comment), lines)
        end

        header = nothing
        # Extract column names if necessary, considering skips
        if col_names == true
            header_line_index =  1
            if header_line_index <= length(lines)
                header = split(lines[header_line_index], ' ')
                if skip != 0
                  lines = lines[(skip+2):end]
                else
                lines = lines[header_line_index+1:end]  # Skip the header line for data
                end
            end
        else
            lines = lines[(skip+2):end]
        end

        # Apply n_max limit
        if !isinf(n_max)
            lines = lines[1:min(n_max, length(lines))]
        end

        (lines, header)
    end

    # Ensure header is a Vector{String} if not nothing
    header_option = header !== nothing ? Vector{String}(header) : false

    # Convert processed lines into a DataFrame
    df = CSV.File(IOBuffer(join(processed_lines, "\n")); 
                  delim=' ', 
                  header=header_option,  # Pass correct header
                  missingstring=missingstring,
                  select=col_select,
                  kwargs...) |> DataFrame

    return df
end

"""
$docstring_write_csv
"""
function write_csv(
    x::DataFrame,
    file::String;
    missingstring::String = "NA",
    append::Bool = false,
    col_names::Bool = true,
    eol::String = "\n",
    num_threads::Int = Threads.nthreads())

    # Configure threading
    CSV.write(
        file,
        x,
        append = append,
        header = col_names && !append,
        missingstring = missingstring,
        newline = eol,
        threaded = num_threads > 1    )
end

"""
$docstring_write_tsv
"""
function write_tsv(
    x::DataFrame,
    file::String;
    missingstring::String = "",
    append::Bool = false,
    col_names::Bool = true,
    eol::String = "\n",
    num_threads::Int = Threads.nthreads())

    # Write DataFrame to TSV
    CSV.write(
        file,
        x,
        delim = '\t',  # Use tab as the delimiter for TSV
        append = append,
        header = col_names && !append,
        missingstring = missingstring,
        newline = eol,
        threaded = num_threads > 1)
end

"""
$docstring_write_table
"""
function write_table(
    x::DataFrame,
    file::String;
    delim::Char = '\t',  # Default to TSV, but allow flexibility
    missingstring::String = "",
    append::Bool = false,
    col_names::Bool = true,
    eol::String = "\n",
    num_threads::Int = Threads.nthreads())
    
    # Write DataFrame to a file with the specified delimiter
    CSV.write(
        file,
        x,
        delim = delim,  # Flexible delimiter based on argument
        append = append,
        header = col_names && !append,
        missingstring = missingstring,
        newline = eol,
        threaded = num_threads > 1)
end

end