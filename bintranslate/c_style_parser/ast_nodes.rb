# This module contains our custom syntax node classes. Each
# class represents a distinct type of entity. Each clas
# also has a distinct to_array method which allows the 
# final AST to be converted easily into a structured array
# representatiion

module BinFix_DSL

	class JumpLiteral < Treetop::Runtime::SyntaxNode
	end

	class ImplicationOperatorLiteral < Treetop::Runtime::SyntaxNode
	end

	class ArithmeticOperatorLiteral < Treetop::Runtime::SyntaxNode
	end

	class CompoundOperatorLiteral < Treetop::Runtime::SyntaxNode
	end

	class LogicalOperatorLiteral < Treetop::Runtime::SyntaxNode
	end

	class AssignmentOperatorLiteral < Treetop::Runtime::SyntaxNode
	end

	module OperandLiteral
	end

	module ExpressionLiteral
	end

	class VariableLiteral < Treetop::Runtime::SyntaxNode
	end

	class RegisterLiteral < Treetop::Runtime::SyntaxNode
	end

	class IntegerLiteral < Treetop::Runtime::SyntaxNode
	end

end