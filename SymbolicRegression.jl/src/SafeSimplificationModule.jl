module SafeSimplificationModule

using DynamicExpressions: AbstractExpressionNode, AbstractExpression, get_tree, combine_operators

export conservative_combine_operators

# Pattern recognition for protected mathematical structures
function is_protected_structure(tree::AbstractExpressionNode, operators)::Bool
    # Check if this is a sqrt/square root function with sum of squares pattern
    if tree.degree == 1 
        # Look for sqrt or power functions that might be square roots
        unary_ops = operators.unaops
        if length(unary_ops) > 0
            current_op = unary_ops[tree.op]
            # Check for sqrt function (common names: sqrt, √)
            if current_op == sqrt
                child = tree.l
                return is_sum_of_squares(child, operators)
            end
            # Also check for custom square root implementations
            # You can add more patterns here
        end
    end
    return false
end

function is_sum_of_squares(tree::AbstractExpressionNode, operators)::Bool
    # Check if tree represents sum of squared terms: x^2 + y^2 + z^2 + ...
    if tree.degree == 2
        binary_ops = operators.binops
        if length(binary_ops) > 0
            current_op = binary_ops[tree.op]
            # Check for addition operation
            if current_op == (+)
                # Both left and right can be either squared terms OR sums of squares
                left_is_valid = is_squared_term(tree.l, operators) || is_sum_of_squares(tree.l, operators)
                right_is_valid = is_squared_term(tree.r, operators) || is_sum_of_squares(tree.r, operators)
                return left_is_valid && right_is_valid
            end
        end
    end
    return is_squared_term(tree, operators)
end

function is_squared_term(tree::AbstractExpressionNode, operators)::Bool
    # Check if tree represents x^2 pattern
    if tree.degree == 2
        binary_ops = operators.binops
        if length(binary_ops) > 0
            current_op = binary_ops[tree.op]
            # Check for power operation x^2
            if current_op == (^) || current_op == (*) 
                # Check for x^2 pattern
                if tree.r.degree == 0 && tree.r.constant && tree.r.val ≈ 2.0
                    return tree.l.degree == 0 && !tree.l.constant  # Variable
                end
                # Check for x*x pattern (when * is used for multiplication)
                if current_op == (*) &&
                   tree.l.degree == 0 && tree.r.degree == 0 && 
                   !tree.l.constant && !tree.r.constant && 
                   tree.l.feature == tree.r.feature
                    return true
                end
            end
        end
    end
    return false
end

# Conservative combine_operators that protects certain structures
function conservative_combine_operators(tree::Union{AbstractExpressionNode, AbstractExpression}, operators)
    # Extract the tree node if it's an expression
    tree_node = tree isa AbstractExpression ? get_tree(tree) : tree
    
    # If this tree or any subtree contains protected patterns, skip combine_operators
    if contains_protected_structure(tree_node, operators)
        return tree
    else
        return combine_operators(tree, operators)
    end
end

function contains_protected_structure(tree::AbstractExpressionNode, operators)::Bool
    # Check current node
    if is_protected_structure(tree, operators)
        return true
    end
    
    # Recursively check children
    if tree.degree >= 1 && contains_protected_structure(tree.l, operators)
        return true
    end
    if tree.degree >= 2 && contains_protected_structure(tree.r, operators)
        return true
    end
    
    return false
end

end