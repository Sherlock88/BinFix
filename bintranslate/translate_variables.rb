require 'awesome_print'

class TranslateVar

	def initialize(varFile)
		@debug = false
		@varFile = varFile
		@variables = Hash.new
	end


	def show_variables
		puts "\n****************************** Variables ******************************\n"
		ap @variables
	end


	def readVars

		# Process @variables
		File.readlines(@varFile).each do |variable|
			variable.strip!
			var_name, var_location, var_size, var_type = variable.split(":")
			var_size = var_size.to_i
			operand, failure_reason = Parser.parse var_location

			if(@debug)
				printf "%-20s: ", operand.addressingMode
			end

			# Parse failure
			if(!operand)
				p failure_reason

			# Parse success
			else
				@variables[var_name] = [var_location, var_type]

				case operand.addressingMode
					when "RegisterOffsetMode"
						if(@debug)
							p operand.elements
						end
						dr_code = translateRegisterOffsetMode var_name, operand.elements

					when "RegisterMode"
						if(@debug)
							puts operand.text_value
						end
						dr_code = translateRegisterMode var_name, var_location, var_size

					when "AbsoluteMode"
						if(@debug)
							puts operand.text_value
						end
						dr_code = translateAbsoluteMode var_name, operand.elements, var_size
				end

				@variables[var_name] << dr_code
			end
		end

		addRegisters
		@variables
	end


	def addRegisters
		@variables["EAX"] = ["eax", "INT_REG", "opnd_t EAX = opnd_create_reg(DR_REG_EAX);"]
		@variables["EBX"] = ["ebx", "INT_REG", "opnd_t EBX = opnd_create_reg(DR_REG_EBX);"]
	end


	def translateRegisterOffsetMode(var_name, tokens)
		if var_size == 4
			"opnd_t " + var_name + " = OPND_CREATE_MEM32(DR_REG_" + tokens[0].text_value.upcase + ", " + tokens[1].text_value + ");"
		else
			"opnd_t " + var_name + " = OPND_CREATE_MEM64(DR_REG_" + tokens[0].text_value.upcase + ", " + tokens[1].text_value + ");"
		end
	end


	def translateRegisterMode(var_name, var_location)
		"opnd_t " + var_name + " = opnd_create_reg(DR_REG_" + var_location.upcase + ");" 
	end


	def translateAbsoluteMode(var_name, tokens, var_size)
		if var_size == 4
			"opnd_t " + var_name + " = opnd_create_abs_addr((void*)#{tokens[0].text_value}, OPSZ_4);"
		else
			"opnd_t " + var_name + " = opnd_create_abs_addr((void*)#{tokens[0].text_value}, OPSZ_8);"
		end
	end

end