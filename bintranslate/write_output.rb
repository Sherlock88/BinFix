
class WriteOutput

	attr_reader :dr_output_file
	

	def initialize(output_directory)
		@dr_output_file = File.open(File.join(output_directory,"binfix_patch.cpp"), "w")
		@dr_patch_code = Array.new
		@dr_patch_code[0] = "#include \"dr_api.h\"\n\n\nvoid inject_binfix_patch(void *drcontext, instr_t *next, instrlist_t *bb)\n{\n\tinstr_t *dsl_instr;"
		@dr_patch_code[1] = ''
	end


	def createInstruction(dsl_command, dr_code)
		@dr_patch_code << "\n\n\t// " + dsl_command.to_s
		dr_code.each { |dr_instr| @dr_patch_code << "\n\t" + dr_instr }
		@dr_patch_code << "\n\tinstrlist_postinsert(bb, next, dsl_instr);"
	end


	def close(variables_used)
		variables_used.values.each { |variable_used| @dr_patch_code[1] << "\n\t" + variable_used }
		@dr_patch_code.each { |dr_patch_code_instr| @dr_output_file.syswrite(dr_patch_code_instr) }
		@dr_output_file.syswrite("\n}")
		@dr_output_file.close
	end

end