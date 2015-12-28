require 'awesome_print'

class CodeGenerator

	def initialize(variables, write_output)
		@variables = variables
		@variables_used = Hash.new
		@write_output = write_output
		# @general_purpose_registers = ["EAX", "EBX", "ECX", "EDX"]
		# @used_register_index = 0
		@trace = 0
		@patch_start = 0
	end


	def write_code
		puts "\n\n****************************** Variables Used ******************************\n"
		ap @variables_used
		@write_output.close @variables_used
	end


'''
	def get_free_register
		return nil if @used_register_index == @general_purpose_registers.size
		@used_register_index += 1
		@general_purpose_registers[@used_register_index]
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
'''

	def compile(dsl_command)

		opcode = dsl_command[0]

		case opcode
			when "patch_addr"
				cmd_new_patch dsl_command

			when "cexp"
				compile_cexp dsl_command

			when "assign"
				compile_assign dsl_command

			when "delete"
				compile_delete dsl_command

			when "cond_jmp"
				compile_cond_jmp dsl_command

			when "if"
				compile_if dsl_command

'''
			when "add"
				compile_add dsl_command

			when "sub"
				compile_sub dsl_command

			when "gt"
				compile_gt dsl_command

			when "jmp"
				compile_jmp dsl_command
'''
		end

	end


	def cmd_new_patch(dsl_command)
		@patch_address = dsl_command[1].to_s(16)
		puts "\tPatch to be injected at address: 0x#{@patch_address}"
		dr_code =[]
		dr_code << "}\n" if @patch_start == 1
		@patch_start = 1
		dr_code << "\n// " + dsl_command.to_s
		dr_code << "if(cur_pc == (app_pc)0x#{dsl_command[1].to_s(16)})"
		dr_code << "{"
		@write_output.create_instruction dsl_command, dr_code
	end


	def compile_cexp(dsl_command)
		cexp = dsl_command[1].to_s
		dr_code = []

		# Extract distinct variables from C expression
		vars = cexp.scan(/[L|G][0-9]+/)
		vars.uniq!
		vars_used = vars.length

		# Iterate over used variables to form C-type argument string
		args = ''
		dr_args = ''
		for i in 0...vars_used
			args = args + @variables[vars[i]][1] + " " + vars[i] + ", "
			dr_args = dr_args + vars[i] + ", "
			@variables_used[vars[i]] = @variables[vars[i]][2] if @variables_used[vars[i]] == nil
		end

		# Remove the last comma (,)
		args = args[0...(args.length - 2)]
		dr_args = dr_args[0...(dr_args.length - 2)]

		puts "\tC expression: #{cexp}"
		puts "\tArguments: #{args}"

		# Generate DynamoRIO code
		dr_code << "\tvoid* fptr = mmap(NULL, 4096, PROT_WRITE | PROT_EXEC, MAP_ANON | MAP_PRIVATE, -1, 0);"
		cexp_shellcode = @write_output.get_cexp_shellcode cexp, args
		dr_code << "\tunsigned char patch[] = {#{cexp_shellcode}};"
		dr_code << "\tmemcpy(fptr, patch, sizeof(patch));"
		dr_insert_call = "\tdr_insert_call(drcontext, bb, instr, fptr, #{vars_used}"
		dr_insert_call = dr_insert_call + ", #{dr_args}" if vars_used > 0
		dr_insert_call = dr_insert_call + ");"
		dr_code << dr_insert_call
		@write_output.create_instruction dsl_command, dr_code
	end


	def compile_assign(dsl_command)
		dr_code = []
		compile_cexp dsl_command[2]
		dr_code << "\t// MOV #{dsl_command[1]}, EAX"
		@write_output.create_instruction dsl_command, dr_code
	end


	def compile_delete(dsl_command)
		dr_code = []
		dr_code << "\tinstrlist_remove(bb, instr);"
		@write_output.create_instruction dsl_command, dr_code
	end


	def compile_cond_jmp(dsl_command)
		dr_code = []
		cond_jmp_addr = dsl_command[1]
		dr_code << "// cond_jmp 0x" + cond_jmp_addr.to_s(16)
		@write_output.create_instruction dsl_command, dr_code
	end


	def compile_if(dsl_command)
		dr_code = []
		compile_cexp dsl_command[1]
		dr_code << "\tin = INSTR_CREATE_cmp(drcontext, opnd_create_reg(DR_REG_EAX), OPND_CREATE_INT32(0));"
		dr_code << "\tinstrlist_preinsert(bb, instr, in);"
		dr_code << "\tin = INSTR_CREATE_jcc(drcontext, OP_jz_short, opnd_create_pc((app_pc)#{dsl_command[2].to_s}));"
		dr_code << "\tinstrlist_replace(bb, instr, in);"
		dr_code << "\tinstr_set_translation(in, cur_pc);"
		@write_output.create_instruction dsl_command, dr_code
	end


'''
	def compile_mov(dest, src)
		get_operand dest
		get_operand src
		"// MOV <" + dest + "> <" + src + ">"
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

		@write_output.create_instruction dsl_command, dr_code
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
		@write_output.create_instruction dsl_command, dr_code
	end


	def compile_gt(dsl_command)
		dr_code = []
		dsl_command[1..-1].each do |operand|
			operand_type = get_operand operand
		end
		@write_output.create_instruction dsl_command, dr_code
	end


	def compile_jmp(dsl_command)
		dr_code = []
		dsl_command[1..-1].each do |operand|
			operand_type = get_operand operand
		end
		@write_output.create_instruction dsl_command, dr_code
	end
'''

end