
module AddressingMode

	class IntegerRegisterLiteral < Treetop::Runtime::SyntaxNode
	end

	class IntegerLiteral < Treetop::Runtime::SyntaxNode
	end

	class RegisterOffsetMode < Treetop::Runtime::SyntaxNode
		def addressingMode
			"RegisterOffsetMode"
		end
	end

	class RegisterIndirectMode < Treetop::Runtime::SyntaxNode
	end

	module RegisterMode
		def addressingMode
			"RegisterMode"
		end
	end

	class AbsoluteMode < Treetop::Runtime::SyntaxNode
	end

end