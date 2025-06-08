module LLMFunctionsModule

using Random: default_rng, AbstractRNG, rand, randperm
using DynamicExpressions:
    Node,
    AbstractExpressionNode,
    AbstractExpression,
    ParametricExpression,
    ParametricNode,
    AbstractNode,
    NodeSampler,
    get_contents,
    with_contents,
    constructorof,
    copy_node,
    set_node!,
    count_nodes,
    has_constants,
    has_operators,
    string_tree,
    AbstractOperatorEnum
using Compat: Returns, @inline
using ..CoreModule: Options, DATA_TYPE, binopmap, unaopmap, LLMOptions
using ..MutationFunctionsModule: gen_random_tree_fixed_size

using PromptingTools: SystemMessage, UserMessage, AIMessage, aigenerate, render, CustomOpenAISchema, OllamaSchema, OpenAISchema
using JSON: parse

"""LLM Recoder records the LLM calls for debugging purposes."""
function llm_recorder(options::LLMOptions, expr::String, mode::String="debug")
    if options.active
        if !isdir(options.llm_recorder_dir)
            mkdir(options.llm_recorder_dir)
        end
        recorder = open(joinpath(options.llm_recorder_dir, "llm_calls.txt"), "a")
        write(recorder, string("[", mode, "] ", expr, "\n[/", mode, "]\n"))
        close(recorder)
    end
end

function load_prompt(path::String)::String
    # load prompt file 
    f = open(path, "r")
    s = read(f, String)
    s = strip(s)
    close(f)
    return s
end

function convertDict(d)::NamedTuple
    return (;Dict(Symbol(k) => v for (k,v) in d)...)
end

function get_vars(options::Options)::String
    variable_names = ["x","y","z","k","j","l","m","n","p","a","b"]
    if !isnothing(options.llm_options.var_order)
        variable_names = [options.llm_options.var_order[key] for key in sort(collect(keys(options.llm_options.var_order)))]
    end
    join(variable_names, ", ")
end

function get_ops(options::Options)::String
    binary_operators = map(v -> string(v), map(binopmap, options.operators.binops))
    unary_operators = map(v -> string(v), map(unaopmap, options.operators.unaops))
    # Binary Ops: +, *, -, /, safe_pow (^)
    # Unary Ops: exp, safe_log, safe_sqrt, sin, cos
    replace(replace("binary operators: " * join(binary_operators, ", ") * ", and unary operators: " * join(unary_operators, ", "), "safe_" => ""), "pow" => "^")
end

function parse_msg_content(msg_content)
    content = msg_content
    try
        content = match(r"```json(.*?)```"s, msg_content).captures[1]
    catch e
        try
            content = match(r"```(.*?)```"s, msg_content).captures[1]
        catch e2
            try
                content = match(r"\[(.*?)\]"s, msg_content).match
            catch e3
                content = msg_content
            end
        end
    end


    try
        out = parse(content) # json parse
        if out isa Dict && all(x -> isa(x, String), values(out))
            return [out[key] for key in keys(out)]
        end

        if out isa Vector && all(x -> isa(x, String), out)
            return out
        end
    catch e
        return []
    end
    return []
end

"""
Constructs a prompt by replacing the element_id_tag with the corresponding element in the element_list.
If the element_list is longer than the number of occurrences of the element_id_tag, the missing elements are added after the last occurrence.
If the element_list is shorter than the number of occurrences of the element_id_tag, the extra ids are removed.
"""
function construct_prompt(user_prompt::String, element_list::Vector, element_id_tag::String)::String
    # Split the user prompt into lines
    lines = split(user_prompt, "\n")
    
    # Filter lines that match the pattern "... : {{element_id_tag[1-9]}}
    pattern = r"^.*: \{\{" * element_id_tag * r"\d+\}\}$"

    # find all occurrences of the element_id_tag
    n_occurrences = count(x -> occursin(pattern, x), lines)

    # if n_occurrences is less than |element_list|, add the missing elements after the last occurrence
    if n_occurrences < length(element_list)
        last_occurrence = findlast(x -> occursin(pattern, x), lines)
        for i in reverse(n_occurrences+1:length(element_list))
            new_line = replace(lines[last_occurrence], string(n_occurrences) => string(i))
            insert!(lines, last_occurrence+1, new_line)
        end
    end

    new_prompt = ""
    idx = 1
    for line in lines
        # if the line matches the pattern
        if occursin(pattern, line)
            if idx > length(element_list)
                continue
            end
            # replace the element_id_tag with the corresponding element
            new_prompt *= replace(line, r"\{\{" * element_id_tag * r"\d+\}\}" => element_list[idx]) * "\n"
            idx += 1
        else
            new_prompt *= line * "\n"
        end
    end
    return new_prompt
end

function gen_llm_random_tree(
    node_count::Int, options::Options, nfeatures::Int, ::Type{T}, idea_database::Union{Vector{String},Nothing}
)::AbstractExpressionNode{T} where {T<:DATA_TYPE}
    # Note that this base tree is just a placeholder; it will be replaced.
    N = 5
    
    println("[GENERATE_MONITOR] 🎲 Starting LLM Random Tree Generation: target nodes = $(node_count)")
    
    if isnothing(idea_database)
        assumptions = []
    else
        assumptions = sample_context(idea_database, min(options.llm_options.num_pareto_context, length(idea_database)), options.llm_options.idea_threshold)
    end

    if options.llm_options.llm_context != ""
    pushfirst!(assumptions, options.llm_options.llm_context)
    end

    if !options.llm_options.prompt_concepts
        assumptions = []
    end

    conversation = [
        SystemMessage(load_prompt(options.llm_options.prompts_dir * "gen_random_system.txt")),
        UserMessage(construct_prompt(
            load_prompt(options.llm_options.prompts_dir * "gen_random_user.txt"),
            assumptions,
            "assump",
            )
        ),
    ]
    rendered_msg = join([x["content"] for x in render(
        CustomOpenAISchema(), conversation;
        variables=get_vars(options),
        operators=get_ops(options),
        N=N,
        no_system_message=false,
    )], "\n")

    llm_recorder(options.llm_options, rendered_msg, "llm_input|gen_random")

    
    msg = nothing
    try
        msg = aigenerate(CustomOpenAISchema(), conversation;
                    variables=get_vars(options),
                    operators=get_ops(options),
                    N=N,
                    api_key=options.llm_options.api_key,
                    model=options.llm_options.model,
                    api_kwargs=convertDict(options.llm_options.api_kwargs),
                    http_kwargs=convertDict(options.llm_options.http_kwargs),
                    no_system_message=true,
                    verbose=false,
                    )
    catch e
        println("[GENERATE_MONITOR] ❌ LLM API call failed: $(e)")
        llm_recorder(options.llm_options, "None", "gen_random|failed")
        return gen_random_tree_fixed_size(node_count, options, nfeatures, T)
    end
    # print type of message and message itself
    println("[GENERATE_MONITOR] 📨 LLM Response received: $(length(string(msg.content))) characters")
    llm_recorder(options.llm_options, string(msg.content), "llm_output|gen_random")

    gen_tree_options = parse_msg_content(String(msg.content))

    N = min(size(gen_tree_options)[1], N)
    
    println("[GENERATE_MONITOR] 🔍 Parsed $(N) candidate expressions from LLM output")

    if N == 0
        println("[GENERATE_MONITOR] ❌ No valid expressions parsed, falling back to random generation")
        llm_recorder(options.llm_options, "None", "gen_random|failed")
        return gen_random_tree_fixed_size(node_count, options, nfeatures, T)
    end

    # Try to parse candidates and collect valid ones
    valid_candidates = []
    for i in 1:N
        raw_expr = gen_tree_options[i]
        cleaned_expr = clean_expression_string(raw_expr)
        
        println("[GENERATE_MONITOR] 🧽 Candidate $(i): \"$(raw_expr)\" -> \"$(cleaned_expr)\"")
        
        try
            t = expr_to_tree(T, cleaned_expr, options)
            if !(t.val == 1 && t.constant)  # Not a trivial constant
                push!(valid_candidates, (t, cleaned_expr))
                println("[GENERATE_MONITOR] ✅ Candidate $(i): Successfully parsed")
            else
                println("[GENERATE_MONITOR] ⚠️  Candidate $(i): Parsed to trivial constant, skipped")
            end
        catch e
            println("[GENERATE_MONITOR] ❌ Candidate $(i): Parse error - $(e)")
        end
    end

    if length(valid_candidates) == 0
        println("[GENERATE_MONITOR] ❌ No valid candidates after cleaning and parsing")
        # Try fallback with the first raw expression
        try
            fallback_expr = clean_expression_string(gen_tree_options[1])
            out = expr_to_tree(T, fallback_expr, options)
            if !(out.val == 1 && out.constant)
                println("[GENERATE_MONITOR] 🔄 Fallback successful: \"$(fallback_expr)\"")
                llm_recorder(options.llm_options, tree_to_expr(out, options), "gen_random")
                return out
            else
                println("[GENERATE_MONITOR] ⚠️  Fallback produced trivial constant")
            end
        catch e
            println("[GENERATE_MONITOR] ❌ Fallback also failed: $(e)")
        end
        
        println("[GENERATE_MONITOR] 🔄 Using traditional random generation as final fallback")
        llm_recorder(options.llm_options, "None", "gen_random|failed")
        return gen_random_tree_fixed_size(node_count, options, nfeatures, T)
    end

    # Select a random valid candidate
    selected_idx = rand(1:length(valid_candidates))
    selected_tree, selected_expr = valid_candidates[selected_idx]
    
    println("[GENERATE_MONITOR] 🎯 Selected candidate $(selected_idx): \"$(selected_expr)\"")
    println("[GENERATE_MONITOR] ✅ Generation successful: $(tree_to_expr(selected_tree, options))")

    llm_recorder(options.llm_options, tree_to_expr(selected_tree, options), "gen_random")

    return selected_tree
end


"""Crossover between two expressions"""
function crossover_trees(tree1::AbstractExpressionNode{T}, tree2::AbstractExpressionNode{T})::Tuple{AbstractExpressionNode{T},AbstractExpressionNode{T}} where {T<:DATA_TYPE}
    tree1 = copy_node(tree1)
    tree2 = copy_node(tree2)

    node1, parent1, side1 = random_node_and_parent(tree1)
    node2, parent2, side2 = random_node_and_parent(tree2)

    node1 = copy_node(node1)

    if side1 == 'l'
        parent1.l = copy_node(node2)
        # tree1 now contains this.
    elseif side1 == 'r'
        parent1.r = copy_node(node2)
        # tree1 now contains this.
    else # 'n'
        # This means that there is no parent2.
        tree1 = copy_node(node2)
    end

    if side2 == 'l'
        parent2.l = node1
    elseif side2 == 'r'
        parent2.r = node1
    else # 'n'
        tree2 = node1
    end
    return tree1, tree2
end

function sketch_const(val)
    does_not_need_brackets = (typeof(val) <: Union{Real,AbstractArray})

    if does_not_need_brackets
        if isinteger(val) && (abs(val) < 5) # don't abstract integer constants from -4 to 4, useful for exponents
            string(val)
        else
            "C"
        end
    else
        if isinteger(val) && (abs(val) < 5) # don't abstract integer constants from -4 to 4, useful for exponents
            "(" * string(val) * ")"
        else
            "(C)"
        end
    end
end

function tree_to_expr(ex::AbstractExpression{T}, options::Options)::String where {T<:DATA_TYPE}
    tree_to_expr(get_contents(ex), options)
end

function tree_to_expr(tree::AbstractExpressionNode{T}, options)::String where {T<:DATA_TYPE}
    variable_names = ["x","y","z","k","j","l","m","n","p","a","b"]
    if !isnothing(options.llm_options.var_order)
        variable_names = [options.llm_options.var_order[key] for key in sort(collect(keys(options.llm_options.var_order)))]
    end
    string_tree(tree, options.operators, f_constant=sketch_const, variable_names=variable_names)
end


function handle_not_expr(::Type{T}, x, var_names)::Node{T} where {T<:DATA_TYPE}
    if x isa Real
        Node{T}(val=convert(T,x)) # old:  Node(T, 0, true, convert(T,x))
    elseif x isa Symbol
        if x === :C # constant that got abstracted
            Node{T}(val=convert(T,1)) # old: Node(T, 0, true, convert(T,1))
        else
            feature = findfirst(isequal(string(x)),var_names)
            if isnothing(feature) # invalid var name, just assume its x0
                feature = 1
            end
            Node{T}(feature=feature) # old: Node(T, 0, false, nothing, feature)
        end
    else
        Node{T}(val=convert(T,1)) # old: Node(T, 0, true, convert(T,1)) # return a constant being 0
    end
end


function expr_to_tree_recurse(::Type{T}, node::Expr, op::AbstractOperatorEnum, var_names)::Node{T} where {T<:DATA_TYPE}
    args = node.args
    x = args[1]
    degree = length(args)

    if degree == 1
        handle_not_expr(T, x, var_names)
    elseif degree == 2
        unary_operators = map(v -> string(v), map(unaopmap, op.unaops))
        idx = findfirst(isequal(string(x)), unary_operators)
        if isnothing(idx) # if not used operator, make it the first one
            idx = findfirst(isequal("safe_" * string(x)), unary_operators)
            if isnothing(idx)
                idx = 1
            end
        end

        left = if (args[2] isa Expr) expr_to_tree_recurse(T, args[2], op, var_names) else handle_not_expr(T, args[2], var_names) end

        Node(op=idx, l=left) # old: Node(1, false, nothing, 0, idx, left)
    elseif degree == 3
        if x === :^
            x = :pow
        end
        binary_operators = map(v -> string(v), map(binopmap, op.binops))
        idx = findfirst(isequal(string(x)), binary_operators)
        if isnothing(idx) # if not used operator, make it the first one
            idx = findfirst(isequal("safe_" * string(x)), binary_operators)
            if isnothing(idx)
                idx = 1
            end
        end
        
        left = if (args[2] isa Expr) expr_to_tree_recurse(T, args[2], op, var_names) else handle_not_expr(T, args[2], var_names) end
        right = if (args[3] isa Expr) expr_to_tree_recurse(T, args[3], op, var_names) else handle_not_expr(T, args[3], var_names) end

        Node(op=idx, l=left, r=right) # old: Node(2, false, nothing, 0, idx, left, right)
    else
        Node{T}(val=convert(T,1))  # old: Node(T, 0, true, convert(T,1)) # return a constant being 1
    end
end

function expr_to_tree_run(::Type{T}, x::String, options)::Node{T} where {T<:DATA_TYPE}
    try
        expr = Meta.parse(x)
        variable_names = ["x","y","z","k","j","l","m","n","p","a","b"]
        if !isnothing(options.llm_options.var_order)
            variable_names = [options.llm_options.var_order[key] for key in sort(collect(keys(options.llm_options.var_order)))]
        end
        if expr isa Expr
            expr_to_tree_recurse(T, expr, options.operators, variable_names)
        else
            handle_not_expr(T, expr, variable_names)
        end
    catch
        Node{T}(val=convert(T,1)) # old: Node(T, 0, true, convert(T,1)) # return a constant being 1
    end
end

function expr_to_tree(::Type{T}, x::String, options) where {T<:DATA_TYPE}
    if options.llm_options.is_parametric
        out = ParametricNode{T}(expr_to_tree_run(T, x, options))
    else
        out = Node{T}(expr_to_tree_run(T, x, options))
    end
    return out
end


function format_pareto(dominating, options, num_pareto_context::Int)::Vector{String}
    pareto = Vector{String}()
    if !isnothing(dominating) && size(dominating)[1] > 0
        idx = randperm(size(dominating)[1])
        for i in 1:min(size(dominating)[1], num_pareto_context)
            push!(pareto,tree_to_expr(dominating[idx[i]].tree, options))
        end
    end
    while size(pareto)[1] < num_pareto_context
        push!(pareto, "None")
    end
    pareto
end

function sample_one_context(idea_database, idea_threshold)::String
    if isnothing(idea_database)
        return "None"
    end

    N = size(idea_database)[1]
    if N == 0
        return "None"
    end

    try
        idea_database[rand(1:min(idea_threshold, N))]
    catch e
        "None"
    end
end

function sample_context(idea_database, N, idea_threshold)::Vector{String}
    assumptions = Vector{String}()
    if isnothing(idea_database)
        println("[IDEA_MONITOR] ⚠️  Context Sampling: No idea database available")
        for _ in 1:N
            push!(assumptions, "None")
        end
        return assumptions
    end

    database_size = size(idea_database)[1]
    if database_size == 0
        println("[IDEA_MONITOR] ⚠️  Context Sampling: Idea database is empty")
        for _ in 1:N
            push!(assumptions, "None")
        end
        return assumptions
    end

    println("[IDEA_MONITOR] 🎯 Context Sampling: Sampling $(N) ideas from database of $(database_size) ideas (threshold: $(idea_threshold))")

    if size(idea_database)[1] < N
        for i in 1:(size(idea_database)[1])
            push!(assumptions, idea_database[i])
        end
        for i in (size(idea_database)[1]+1):N
            push!(assumptions, "None")
        end
        println("[IDEA_MONITOR] 📝 Sampled Ideas: $(join(filter(x -> x != "None", assumptions), ", "))")
        return assumptions
    end

    while size(assumptions)[1] < N
        chosen_idea = sample_one_context(idea_database, idea_threshold)
        if chosen_idea in assumptions
            continue
        end
        push!(assumptions, chosen_idea)
    end
    
    valid_ideas = filter(x -> x != "None", assumptions)
    println("[IDEA_MONITOR] 📝 Sampled Ideas: $(join(valid_ideas, ", "))")
    
    assumptions
end

function prompt_evol(idea_database, options::Options)

    num_ideas = size(idea_database)[1]
    if num_ideas <= options.llm_options.idea_threshold
        return nothing
    end
    n_ideas = 5
    
    println("[IDEA_MONITOR] 🧠 Prompt Evolution: Starting with $(num_ideas) ideas in database")
    
    ideas = [idea_database[rand((options.llm_options.idea_threshold + 1):num_ideas)] for _ in 1:n_ideas]

    N = 5

    conversation = [
        SystemMessage(load_prompt(options.llm_options.prompts_dir * "prompt_evol_system.txt")),
        UserMessage(construct_prompt(
                load_prompt(options.llm_options.prompts_dir * "prompt_evol_user.txt"),
                ideas,
                "idea",
            )
        ),
    ]
    rendered_msg = join([x["content"] for x in render(
        CustomOpenAISchema(), conversation;
        variables=get_vars(options),
        operators=get_ops(options),
        N=N,
        no_system_message=false,
    )], "\n")
    llm_recorder(options.llm_options, rendered_msg, "llm_input|ideas")

    msg = nothing
    try
        msg = aigenerate(CustomOpenAISchema(), conversation; #OllamaSchema(), conversation;
                N=N,
                api_key=options.llm_options.api_key,
                model=options.llm_options.model,
                api_kwargs=convertDict(options.llm_options.api_kwargs),
                http_kwargs=convertDict(options.llm_options.http_kwargs)
                )
    catch e
        println("[IDEA_MONITOR] ❌ Prompt Evolution: LLM call failed - $(e)")
        llm_recorder(options.llm_options, "None", "ideas|failed")
        return nothing
    end
    llm_recorder(options.llm_options, string(msg.content), "llm_output|ideas")

    idea_options = parse_msg_content(String(msg.content))

    N = min(size(idea_options)[1], N)

    if N == 0
        println("[IDEA_MONITOR] ❌ Prompt Evolution: No valid ideas generated")
        llm_recorder(options.llm_options, "None", "ideas|failed")
        return nothing
    end

    # only choose one, merging ideas not really crossover
    chosen_idea = String(strip(idea_options[rand(1:N)], [' ', '\n', '"', ',', '.', '[', ']']))

    println("[IDEA_MONITOR] ✨ Prompt Evolution: Generated new idea -> \"$(chosen_idea)\"")
    
    llm_recorder(options.llm_options, chosen_idea, "ideas")

    chosen_idea
end

function update_idea_database(idea_database, dominating, worst_members, options::Options)
    # turn dominating pareto curve into ideas as strings
    if isnothing(dominating)
        return
    end

    current_size = length(idea_database)
    println("[IDEA_MONITOR] 🔄 Updating Idea Database: Current size = $(current_size)")

    op = options.operators
    num_pareto_context = options.llm_options.num_pareto_context

    gexpr = format_pareto(dominating, options, num_pareto_context)
    bexpr = format_pareto(worst_members, options, num_pareto_context)

    println("[IDEA_MONITOR] 📊 Analysis Input: $(length(dominating)) dominating expressions, $(length(worst_members)) worst expressions")

    N = 5

    # conversation = [
    #     SystemMessage(load_prompt(options.llm_options.prompts_dir * "extract_idea_system.txt")),
    #     UserMessage(load_prompt(options.llm_options.prompts_dir * "extract_idea_user.txt"))]
    conversation = [
        SystemMessage(load_prompt(options.llm_options.prompts_dir * "extract_idea_system.txt")),
        UserMessage(construct_prompt(
                construct_prompt(
                    load_prompt(options.llm_options.prompts_dir * "extract_idea_user.txt"),
                    gexpr,
                    "gexpr"
                    ),
                bexpr,
                "bexpr",
            ),
        ),
    ]
    rendered_msg = join([x["content"] for x in render(
        CustomOpenAISchema(), conversation;
        variables=get_vars(options),
        operators=get_ops(options),
        N=N,
        no_system_message=false,
    )], "\n")

    llm_recorder(options.llm_options, rendered_msg, "llm_input|gen_random")

    msg = nothing
    try
        # msg = aigenerate(OpenAISchema(), conversation; #OllamaSchema(), conversation;
        #         variables=get_vars(options),
        #         operators=get_ops(options),
        #         N=N,
        #         gexpr1=gexpr[1],
        #         gexpr2=gexpr[2],
        #         gexpr3=gexpr[3],
        #         gexpr4=gexpr[4],
        #         gexpr5=gexpr[5],
        #         bexpr1=bexpr[1],
        #         bexpr2=bexpr[2],
        #         bexpr3=bexpr[3],
        #         bexpr4=bexpr[4],
        #         bexpr5=bexpr[5],
        #         model="gpt-3.5-turbo-0125"
        #         )
        msg = aigenerate(CustomOpenAISchema(), conversation; #OllamaSchema(), conversation;
                variables=get_vars(options),
                operators=get_ops(options),
                N=N,
                api_key=options.llm_options.api_key,
                model=options.llm_options.model,
                api_kwargs=convertDict(options.llm_options.api_kwargs),
                http_kwargs=convertDict(options.llm_options.http_kwargs),
                no_system_message=true,
                verbose=false,
        )
    catch e
        println("[IDEA_MONITOR] ❌ Idea Extraction: LLM call failed - $(e)")
        llm_recorder(options.llm_options, "None", "ideas|failed")
        return nothing
    end

    llm_recorder(options.llm_options, string(msg.content), "llm_output|ideas")

    idea_options = parse_msg_content(String(msg.content))

    N = min(size(idea_options)[1], N)

    if N == 0
        println("[IDEA_MONITOR] ❌ Idea Extraction: No valid ideas extracted")
        llm_recorder(options.llm_options, "None", "ideas|failed")
        return nothing
    end

    a = rand(1:N)

    chosen_idea1 = String(strip(idea_options[a], [' ', '\n', '"', ',', '.', '[', ']']))

    println("[IDEA_MONITOR] ➕ Adding New Idea 1: \"$(chosen_idea1)\"")
    llm_recorder(options.llm_options, chosen_idea1, "ideas")
    pushfirst!(idea_database, chosen_idea1)

    if N > 1
        b = rand(1:N-1)
        if a == b
            b += 1
        end
        chosen_idea2 = String(strip(idea_options[b], [' ', '\n', '"', ',', '.', '[', ']']))

        println("[IDEA_MONITOR] ➕ Adding New Idea 2: \"$(chosen_idea2)\"")
        llm_recorder(options.llm_options, chosen_idea2, "ideas")

        pushfirst!(idea_database, chosen_idea2)
    end

    num_add = 2
    evolved_count = 0
    for _ in 1:num_add
        out = prompt_evol(idea_database, options)
        if !isnothing(out)
            pushfirst!(idea_database, out)
            evolved_count += 1
            println("[IDEA_MONITOR] ➕ Adding Evolved Idea: \"$(out)\"")
        end
    end
    
    new_size = length(idea_database)
    total_added = new_size - current_size
    println("[IDEA_MONITOR] ✅ Database Updated: $(current_size) -> $(new_size) (+$(total_added) ideas, $(evolved_count) evolved)")
    println("[IDEA_MONITOR] 📋 Latest Top 3 Ideas:")
    for i in 1:min(3, new_size)
        println("[IDEA_MONITOR]   $(i). \"$(idea_database[i])\"")
    end
end

function llm_mutate_op(ex::AbstractExpression{T}, options::Options, idea_database)::AbstractExpression{T} where {T<:DATA_TYPE}
    tree = get_contents(ex)
    ex = with_contents(ex, llm_mutate_op(tree, options, idea_database))
    return ex
end

"""Clean and normalize LLM-generated expression strings"""
function clean_expression_string(expr_str::String)::String
    # Remove extra whitespace and quotes
    cleaned = strip(expr_str, [' ', '\n', '"', ',', '.', '[', ']'])
    
    # Fix common LLM mistakes
    cleaned = replace(cleaned, "**" => "^")  # Double asterisk to exponent
    cleaned = replace(cleaned, "θ" => "theta")  # Greek theta to theta
    cleaned = replace(cleaned, "Cos" => "cos")  # Uppercase to lowercase
    cleaned = replace(cleaned, "Sin" => "sin")  # Uppercase to lowercase
    cleaned = replace(cleaned, "Exp" => "exp")  # Uppercase to lowercase
    cleaned = replace(cleaned, "Log" => "log")  # Uppercase to lowercase
    cleaned = replace(cleaned, "Sqrt" => "sqrt")  # Uppercase to lowercase
    
    # Map log to safe_log (but system expects log, not safe_log in expressions)
    # The system internally maps log to safe_log during parsing
    
    # Replace unsupported functions with supported equivalents
    cleaned = replace(cleaned, r"\btanh\(" => "((exp(2*") # Start tanh replacement
    cleaned = replace(cleaned, r"\btanh\b" => "((exp(2*theta)-1)/(exp(2*theta)+1))")
    cleaned = replace(cleaned, r"\brho\b" => "C") # Replace rho with C
    cleaned = replace(cleaned, r"\bpi\b" => "C") # Replace pi with C  
    cleaned = replace(cleaned, r"\be\b" => "C") # Replace e with C
    
    # Handle tanh(x) patterns - replace with hyperbolic tangent approximation
    # Note: This is a simplified approach - ideally we'd parse the argument properly
    cleaned = replace(cleaned, r"tanh\(([^)]+)\)" => s"((exp(2*\1)-1)/(exp(2*\1)+1))")
    
    # Remove other unsupported functions entirely and replace with constants
    unsupported_funcs = ["atan", "asin", "acos", "tan", "cot", "sec", "csc", "sinh", "cosh", "asinh", "acosh", "atanh"]
    for func in unsupported_funcs
        cleaned = replace(cleaned, Regex("\\b" * func * "\\([^)]+\\)") => "C")
    end
    
    # Fix malformed expressions
    cleaned = replace(cleaned, r"\(\s*\*\s*" => "(") # Remove orphaned asterisks
    cleaned = replace(cleaned, r"\*\s*\)" => ")") # Remove trailing asterisks
    cleaned = replace(cleaned, r"\(\s*\)" => "C") # Replace empty parentheses with C
    
    # Fix multiple consecutive operators
    cleaned = replace(cleaned, r"\+\s*\+" => "+") # ++ -> +
    cleaned = replace(cleaned, r"-\s*-" => "+") # -- -> +
    cleaned = replace(cleaned, r"\*\s*\*" => "^") # ** -> ^
    cleaned = replace(cleaned, r"/\s*/" => "/") # // -> /
    
    # Handle edge cases where expressions might be malformed
    cleaned = replace(cleaned, r"^\s*[\+\-\*/\^]\s*" => "C") # Expression starting with operator
    cleaned = replace(cleaned, r"\s*[\+\-\*/\^]\s*$" => "") # Expression ending with operator
    
    # Replace sequences of constants/operations that might be invalid
    cleaned = replace(cleaned, r"C\s*C" => "C") # CC -> C
    cleaned = replace(cleaned, r"theta\s*theta" => "theta^2") # theta theta -> theta^2
    
    # Ensure we have a valid expression - if it's just whitespace, return C
    cleaned = strip(cleaned)
    if isempty(cleaned) || cleaned == ""
        cleaned = "C"
    end
    
    return cleaned
end

"""LLM Mutation on a tree"""
function llm_mutate_op(tree::AbstractExpressionNode{T}, options::Options, idea_database)::AbstractExpressionNode{T} where {T<:DATA_TYPE}
    expr = tree_to_expr(tree, options) # TODO: change global expr right now, could do it by subtree (weighted near root more)
    N = 5
    
    println("[MUTATE_MONITOR] 🔄 Starting LLM Mutation: Input expression = \"$(expr)\"")
    
    # LLM prompt
    # TODO: we can use async map to do concurrent requests (useful for trying multiple prompts), see: https://github.com/svilupp/PromptingTools.jl?tab=readme-ov-file#asynchronous-execution

    # conversation = [
    #     SystemMessage(load_prompt(options.llm_options.prompts_dir * "mutate_system.txt")),
    #     UserMessage(load_prompt(options.llm_options.prompts_dir * "mutate_user.txt"))]

    if isnothing(idea_database)
        assumptions = []
    else
        assumptions = sample_context(idea_database, min(options.llm_options.num_pareto_context, length(idea_database)), options.llm_options.idea_threshold)
    end

    if !options.llm_options.prompt_concepts
        assumptions = []
    end
    if options.llm_options.llm_context != ""
        pushfirst!(assumptions, options.llm_options.llm_context)
    end

    conversation = [
        SystemMessage(load_prompt(options.llm_options.prompts_dir * "mutate_system.txt")),
        UserMessage(construct_prompt(
                load_prompt(options.llm_options.prompts_dir * "mutate_user.txt"),
                assumptions,
                "assump",
            ),
        ),
    ]
    rendered_msg = join([x["content"] for x in render(
        CustomOpenAISchema(), conversation;
        variables=get_vars(options),
        operators=get_ops(options),
        N=N,
        no_system_message=false,
    )], "\n")

    llm_recorder(options.llm_options, rendered_msg, "llm_input|mutate")

    msg = nothing
    try
        msg = aigenerate(CustomOpenAISchema(), conversation; #OllamaSchema(), conversation;
            variables=get_vars(options),
            operators=get_ops(options),
            N=N,
            expr=expr,
            api_key=options.llm_options.api_key,
            model=options.llm_options.model,
            api_kwargs=convertDict(options.llm_options.api_kwargs),
            http_kwargs=convertDict(options.llm_options.http_kwargs),
            no_system_message=true,
            verbose=false,
)
    catch e
        println("[MUTATE_MONITOR] ❌ LLM API call failed: $(e)")
        llm_recorder(options.llm_options, "None", "mutate|failed")
        return tree
    end

    println("[MUTATE_MONITOR] 📨 LLM Response received: $(length(string(msg.content))) characters")
    llm_recorder(options.llm_options, string(msg.content), "llm_output|mutate")

    mut_tree_options = parse_msg_content(String(msg.content))

    N = min(size(mut_tree_options)[1], N)
    
    println("[MUTATE_MONITOR] 🔍 Parsed $(N) candidate expressions from LLM output")

    if N == 0
        println("[MUTATE_MONITOR] ❌ No valid expressions parsed from LLM output")
        llm_recorder(options.llm_options, "None", "mutate|failed")
        return tree
    end

    # Try to parse each candidate
    valid_candidates = []
    for i in 1:N
        raw_expr = mut_tree_options[i]
        cleaned_expr = clean_expression_string(raw_expr)
        
        println("[MUTATE_MONITOR] 🧽 Candidate $(i): \"$(raw_expr)\" -> \"$(cleaned_expr)\"")
        
        try
            t = expr_to_tree(T, cleaned_expr, options)
            if !(t.val == 1 && t.constant)  # Not a trivial constant
                push!(valid_candidates, (t, cleaned_expr))
                println("[MUTATE_MONITOR] ✅ Candidate $(i): Successfully parsed")
            else
                println("[MUTATE_MONITOR] ⚠️  Candidate $(i): Parsed to trivial constant, skipped")
            end
        catch e
            println("[MUTATE_MONITOR] ❌ Candidate $(i): Parse error - $(e)")
        end
    end
    
    if length(valid_candidates) == 0
        println("[MUTATE_MONITOR] ❌ No valid candidates after cleaning and parsing")
        # Try fallback with the first raw expression
        try
            fallback_expr = clean_expression_string(mut_tree_options[1])
            out = expr_to_tree(T, fallback_expr, options)
            println("[MUTATE_MONITOR] 🔄 Fallback: Using first candidate \"$(fallback_expr)\"")
            llm_recorder(options.llm_options, tree_to_expr(out, options), "mutate")
            return out
        catch e
            println("[MUTATE_MONITOR] ❌ Fallback also failed: $(e)")
            llm_recorder(options.llm_options, "None", "mutate|failed")
            return tree
        end
    end

    # Select a random valid candidate
    selected_idx = rand(1:length(valid_candidates))
    selected_tree, selected_expr = valid_candidates[selected_idx]
    
    println("[MUTATE_MONITOR] 🎯 Selected candidate $(selected_idx): \"$(selected_expr)\"")
    println("[MUTATE_MONITOR] ✅ Mutation successful: $(tree_to_expr(tree, options)) -> $(tree_to_expr(selected_tree, options))")

    llm_recorder(options.llm_options, tree_to_expr(selected_tree, options), "mutate")

    return selected_tree
end

function llm_crossover_trees(ex1::E, ex2::E, options::Options, idea_database)::Tuple{E,E} where {T,E<:AbstractExpression{T}}
    tree1 = get_contents(ex1)
    tree2 = get_contents(ex2)
    tree1, tree2 = llm_crossover_trees(tree1, tree2, options, idea_database)
    ex1 = with_contents(ex1, tree1)
    ex2 = with_contents(ex2, tree2)
    return ex1, ex2
end


"""LLM Crossover between two expressions"""
function llm_crossover_trees(tree1::AbstractExpressionNode{T}, tree2::AbstractExpressionNode{T}, options::Options, idea_database)::Tuple{AbstractExpressionNode{T},AbstractExpressionNode{T}} where {T<:DATA_TYPE}
    expr1 = tree_to_expr(tree1, options)
    expr2 = tree_to_expr(tree2, options)
    N = 5
    
    println("[CROSSOVER_MONITOR] 🔄 Starting LLM Crossover:")
    println("[CROSSOVER_MONITOR]   Parent 1: \"$(expr1)\"")
    println("[CROSSOVER_MONITOR]   Parent 2: \"$(expr2)\"")

    # LLM prompt
    # conversation = [
    #     SystemMessage(load_prompt(options.llm_options.prompts_dir * "crossover_system.txt")),
    #     UserMessage(load_prompt(options.llm_options.prompts_dir * "crossover_user.txt"))]
    if isnothing(idea_database)
        assumptions = []
    else
        assumptions = sample_context(idea_database, min(options.llm_options.num_pareto_context, length(idea_database)), options.llm_options.idea_threshold)
    end
    # pareto = format_pareto(dominating, options, options.llm_options.num_pareto_context)
    if !options.llm_options.prompt_concepts
        assumptions = []
        # pareto = []
    end

    if options.llm_options.llm_context != ""
        pushfirst!(assumptions, options.llm_options.llm_context)
    end

    conversation = [
        SystemMessage(load_prompt(options.llm_options.prompts_dir * "crossover_system.txt")),
        UserMessage(construct_prompt(
                load_prompt(options.llm_options.prompts_dir * "crossover_user.txt"),
                assumptions,
                "assump"
                )
            )
        ]
    rendered_msg = join([x["content"] for x in render(
        CustomOpenAISchema(), conversation;
        variables=get_vars(options),
        operators=get_ops(options),
        N=N,
        no_system_message=false,
    )], "\n")

    llm_recorder(options.llm_options, rendered_msg, "llm_input|crossover")

    msg = nothing
    try
        msg = aigenerate(CustomOpenAISchema(), conversation; #OllamaSchema(), conversation;
                variables=get_vars(options),
                operators=get_ops(options),
                N=N,
                expr1=expr1,
                expr2=expr2,
                api_key=options.llm_options.api_key,
                model=options.llm_options.model,
                api_kwargs=convertDict(options.llm_options.api_kwargs),
                http_kwargs=convertDict(options.llm_options.http_kwargs),
                no_system_message=true,
                verbose=false,
        )
    catch e
        println("[CROSSOVER_MONITOR] ❌ LLM API call failed: $(e)")
        llm_recorder(options.llm_options, "None", "crossover|failed")
        return tree1, tree2
    end

    println("[CROSSOVER_MONITOR] 📨 LLM Response received: $(length(string(msg.content))) characters")
    llm_recorder(options.llm_options, string(msg.content), "llm_output|crossover")

    cross_tree_options = parse_msg_content(String(msg.content))

    N = min(size(cross_tree_options)[1], N)
    
    println("[CROSSOVER_MONITOR] 🔍 Parsed $(N) candidate expressions from LLM output")

    if N == 0
        println("[CROSSOVER_MONITOR] ❌ No valid expressions parsed from LLM output")
        llm_recorder(options.llm_options, "None", "crossover|failed")
        return tree1, tree2
    end

    # Try to parse candidates and collect valid ones
    valid_candidates = []
    for i in 1:N
        raw_expr = cross_tree_options[i]
        cleaned_expr = clean_expression_string(raw_expr)
        
        println("[CROSSOVER_MONITOR] 🧽 Candidate $(i): \"$(raw_expr)\" -> \"$(cleaned_expr)\"")
        
        try
            t = expr_to_tree(T, cleaned_expr, options)
            if !(t.val == 1 && t.constant)  # Not a trivial constant
                push!(valid_candidates, (t, cleaned_expr))
                println("[CROSSOVER_MONITOR] ✅ Candidate $(i): Successfully parsed")
            else
                println("[CROSSOVER_MONITOR] ⚠️  Candidate $(i): Parsed to trivial constant, skipped")
            end
        catch e
            println("[CROSSOVER_MONITOR] ❌ Candidate $(i): Parse error - $(e)")
        end
    end

    if length(valid_candidates) == 0
        println("[CROSSOVER_MONITOR] ❌ No valid candidates after cleaning and parsing")
        # Try fallback with the first raw expression  
        try
            fallback_expr = clean_expression_string(cross_tree_options[1])
            t = expr_to_tree(T, fallback_expr, options)
            println("[CROSSOVER_MONITOR] 🔄 Fallback: Using first candidate \"$(fallback_expr)\"")
            recording_str = tree_to_expr(t, options) * " && " * tree_to_expr(tree2, options)
            llm_recorder(options.llm_options, recording_str, "crossover")
            return t, tree2
        catch e
            println("[CROSSOVER_MONITOR] ❌ Fallback also failed: $(e)")
            llm_recorder(options.llm_options, "None", "crossover|failed")
            return tree1, tree2
        end
    end

    cross_tree1 = nothing
    cross_tree2 = nothing

    # Try to get two different offspring
    if length(valid_candidates) == 1
        cross_tree1, _ = valid_candidates[1]
        cross_tree2 = tree2  # Keep second parent as second offspring
        println("[CROSSOVER_MONITOR] 🎯 Only one valid candidate, using it as first offspring")
    else
        # Select two different candidates
        selected_indices = []
        for attempt in 1:(2*length(valid_candidates))
            idx = rand(1:length(valid_candidates))
            t, cleaned_expr = valid_candidates[idx]
            
            if cross_tree1 === nothing
                cross_tree1 = t
                push!(selected_indices, idx)
                println("[CROSSOVER_MONITOR] 🎯 Selected candidate $(idx) as first offspring: \"$(cleaned_expr)\"")
            elseif cross_tree2 === nothing && !(idx in selected_indices)
                cross_tree2 = t
                push!(selected_indices, idx)
                println("[CROSSOVER_MONITOR] 🎯 Selected candidate $(idx) as second offspring: \"$(cleaned_expr)\"")
                break
            end
        end
        
        # If we couldn't find two different candidates, use the first one twice
        if cross_tree2 === nothing
            cross_tree2, cleaned_expr = valid_candidates[1]
            println("[CROSSOVER_MONITOR] 🔄 Using first candidate as second offspring: \"$(cleaned_expr)\"")
        end
    end

    if cross_tree1 === nothing
        cross_tree1, _ = valid_candidates[1]
    end
    
    if cross_tree2 === nothing
        cross_tree2, _ = valid_candidates[1]
    end

    recording_str = tree_to_expr(cross_tree1, options) * " && " * tree_to_expr(cross_tree2, options)
    println("[CROSSOVER_MONITOR] ✅ Crossover successful:")
    println("[CROSSOVER_MONITOR]   Offspring 1: $(tree_to_expr(cross_tree1, options))")
    println("[CROSSOVER_MONITOR]   Offspring 2: $(tree_to_expr(cross_tree2, options))")
    llm_recorder(options.llm_options, recording_str, "crossover")

    return cross_tree1, cross_tree2
end

"""Test expression cleaning and parsing"""
function test_expression_cleaning()
    # Test cases from actual LLM failures
    test_cases = [
        "((sqrt((C ^ (1/C)* theta / C)) / C) / (theta * C)) + ((Cos(**theta))*( θ ))",
        "((sqrt(log(C*C**(θ/  C))) /  θ )/ (log(C)*θ))*C+((C**θ)*(θ))",
        "(( sqrt(C^(θ/  C) / C) /  θ  ))^-θ*( C ^(   1.0/  θ    ))+((Cos( **theta ))*( θ ))",
        "((sqrt(C^(1/C)*C/C*theta**-2)) / (C*theta^-1)) + ((Sin(theta))^+2)**θ ",
        "(( sqrt( C^(sin(θ )*θ) / cos( C))) / (C*θ))*C+((C^ θ)*( Sin( **theta**) * sin(*theta )))",
        "**theta",
        "Cos(theta)",
        "θ + C",
        "log(theta)",
        "tanh(theta)",
        "C / ()",
        "++ C",
        "C --",
    ]
    
    println("🧪 Testing Expression Cleaning:")
    println("=" ^ 60)
    
    for (i, test_expr) in enumerate(test_cases)
        println("Test $(i): \"$(test_expr)\"")
        cleaned = clean_expression_string(test_expr)
        println("  Cleaned: \"$(cleaned)\"")
        
        # Try to parse it
        try
            parsed = Meta.parse(cleaned)
            println("  ✅ Parse successful: $(parsed)")
        catch e
            println("  ❌ Parse failed: $(e)")
        end
        println()
    end
end

end