
class WriteOutput

	attr_reader :dr_output_file
	

	def initialize(output_directory)
		@output_directory = output_directory
		@dr_output_file = File.open(File.join(output_directory,"dr_patch.cpp"), "w")
		@dr_patch_code = Array.new
		# @dr_patch_code << "#include \"dr_api.h\"\n\n\nvoid inject_binfix_patch(void *drcontext, instr_t *next, instrlist_t *bb)\n{\ninstr_t *dsl_instr;"
		@dr_patch_code << "\n"
		@dr_patch_code[1] = ''
		@cexp_method_counter = 0
	end


	def inject_binfix_patch(patch_addr)

	end


	def get_cexp_shellcode(cexp, args)
		# Set the filenames
		shared_lib_base_name = "binfix_cexp_lib_" + @cexp_method_counter.to_s
		shared_lib_src = File.join(@output_directory, shared_lib_base_name + ".c")
		shared_lib_obj = File.join(@output_directory, shared_lib_base_name + ".o")
		# shared_lib_so = File.join(@output_directory, shared_lib_base_name + ".so")
		# shared_lib_dis = File.join(@output_directory, shared_lib_base_name + ".so.dis")
		shared_obj_dis = File.join(@output_directory, shared_lib_base_name + ".o.dis")

		# Write the shared library source code
		shared_lib_src_handle = File.open(shared_lib_src, "w")
		shared_lib_method = "\nint compute_cexp_" + @cexp_method_counter.to_s
		shared_lib_src_handle << shared_lib_method + "(#{args})\n{\n\treturn #{cexp};\n}"
		shared_lib_src_handle.close

		# Compile the source code
		cmd_compile_obj = "gcc -c -fPIC " + shared_lib_src + " -o " + shared_lib_obj
		system(cmd_compile_obj)
		# cmd_compile_so = "gcc -shared " + shared_lib_obj + " -o " + shared_lib_so
		# system(cmd_compile_so)
		# cmd_so_disassemble = "objdump -d -M intel #{shared_lib_so} > #{shared_lib_dis}"
		# system(cmd_so_disassemble)
		cmd_obj_disassemble = "objdump -d -M intel #{shared_lib_obj} > #{shared_obj_dis}"
		system(cmd_obj_disassemble)
		cmd_cexp_shellcode = "cat #{shared_obj_dis}|grep '[0-9a-f]:'|grep -v 'file'|cut -f2 -d:|cut -f1-6 -d' '|tr -s ' '|tr '\\t' ' '|sed 's/ $//g'|sed 's/ /, 0\\x/g'|paste -d '' -s |sed 's/^, //'|sed 's/$//g'"
		cexp_shellcode = `#{cmd_cexp_shellcode}`
		puts "\tShellcode: #{cexp_shellcode}"

		# Increment the shared library counter
		@cexp_method_counter = @cexp_method_counter + 1

		cexp_shellcode.strip!
	end


	def create_instruction(dsl_command, dr_code)
		# @dr_patch_code << "\n\t// " + dsl_command.to_s
		dr_code.each { |dr_instr| @dr_patch_code << "\n" + dr_instr }
		# @dr_patch_code << "\n\tinstrlist_postinsert(bb, next, dsl_instr);"
	end


	def close(variables_used)
		variables_used.values.each { |variable_used| @dr_patch_code[1] << "\n" + variable_used }
		@dr_patch_code[1] << "\n"
		@dr_patch_code.each { |dr_patch_code_instr| @dr_output_file.syswrite(dr_patch_code_instr) }
		@dr_output_file.syswrite("\n}")
		@dr_output_file.close
	end

end