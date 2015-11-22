require 'awesome_print'

class CodeGenerator

	def initialize(variables, write_output)
		@variables = variables
		@variables_used = Hash.new
		@write_output = write_output
		@general_purpose_registers = ["EAX", "EBX", "ECX", "EDX"]
		@used_register_index = 0
		@trace = 0
	end


	def get_free_register
		return nil if @used_register_index == @general_purpose_registers.size
		@used_register_index += 1
		@general_purpose_registers[@used_register_index]
	end


	def write_code
		puts "\n\n****************************** Variables Used ******************************\n"
		ap @variables_used
		@write_output.close @variables_used
	end


	def get_operand(operand)

		if operand.is_a? Array
			compile operand
			:subexpr
		else
			if @variables[operand] != nil
				@variables_used[operand] = @variables[operand][2] if @variables_used[operand] == nil
				[:variable, operand]
			else
				const_var = "const_" + operand.to_s
				@variables_used[const_var] = "opnd_t " + const_var + " = OPND_CREATE_INT32(" + operand.to_s + ");"
				[:constant, const_var]
			end
		end

	end


	def compile(dsl_command)

		opcode = dsl_command[0]

		case opcode
			when "assign"
				compile_assign dsl_command

			when "add"
				compile_add dsl_command

			when "sub"
				compile_sub dsl_command

			when "gt"
				compile_gt dsl_command

			when "jmp"
				compile_jmp dsl_command

			when "if"
				compile_if dsl_command
		end

	end


	def compile_mov(dest, src)
		get_operand dest
		get_operand src
		"// MOV <" + dest + "> <" + src + ">"
	end


	def compile_assign(dsl_command)
		dr_code = []
		dsl_command[1..-1].each do |operand|
			operand_type = get_operand operand
		end
		@write_output.createInstruction dsl_command, dr_code
	end


	def compile_add(dsl_command)
		dr_code = []
		operands_in_registers = []
		operand_count = 2
		dr_instr = "INSTR_CREATE_add(drcontext, "

		for i in 1..operand_count
			operand_type, operand_name = get_operand dsl_command[i]
			case operand_type
				when :variable
					dr_code << compile_mov("EAX", operand_name)
			end
		end

		@trace += 1
		dr_code << "// " + @trace.to_s
		first_operand_type, first_operand_name = get_operand dsl_command[1]
		if first_operand_type == :variable
			dr_code << compile_mov("EAX", first_operand_name)
			dr_instr += "EAX, "
		end

		@trace += 1
		dr_code << "// " + @trace.to_s
		second_operand_type, second_operand_name = get_operand dsl_command[2]
		if second_operand_type == :variable
			dr_code << compile_mov("EBX", second_operand_name)
		else second_operand_type == :subexpr
			dr_code << compile_mov("EBX", "EAX")
		end
		dr_instr += "EBX);"
		dr_code << dr_instr

		@write_output.createInstruction dsl_command, dr_code
	end


	def compile_sub(dsl_command)
		dr_code = []
		dr_instr = "INSTR_CREATE_sub(drcontext, "
		@trace += 1
		dr_code << "// " + @trace.to_s
		first_operand_type, first_operand_name = get_operand dsl_command[1]
		if first_operand_type == :variable
			dr_code << compile_mov("EAX", first_operand_name)
			dr_instr += "EAX, "
		end
		@trace += 1
		dr_code << "// " + @trace.to_s
		second_operand_type, second_operand_name = get_operand dsl_command[2]
		dr_instr += second_operand_name + ");"
		dr_code << dr_instr		
		@write_output.createInstruction dsl_command, dr_code
	end


	def compile_gt(dsl_command)
		dr_code = []
		dsl_command[1..-1].each do |operand|
			operand_type = get_operand operand
		end
		@write_output.createInstruction dsl_command, dr_code
	end


	def compile_jmp(dsl_command)
		dr_code = []
		dsl_command[1..-1].each do |operand|
			operand_type = get_operand operand
		end
		@write_output.createInstruction dsl_command, dr_code
	end


	def compile_if(dsl_command)
		dr_code = []
		dsl_command[1..-1].each do |operand|
			operand_type = get_operand operand
		end
		@write_output.createInstruction dsl_command, dr_code
	end

end