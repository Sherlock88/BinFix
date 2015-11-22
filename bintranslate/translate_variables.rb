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
			var_name, var_location, var_type = variable.split(":")
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
						dr_code = translateRegisterOffsetMode var_name, var_location, operand.elements

					when "RegisterMode"
						if(@debug)
							puts operand.text_value
						end
						dr_code = translateRegisterMode var_name, var_location
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


	def translateRegisterOffsetMode(var_name, var_location, tokens)
		"opnd_t " + var_name + " = OPND_CREATE_MEM32(DR_REG_" + tokens[0].text_value.upcase + ", " + tokens[1].text_value + ");" 
	end


	def translateRegisterMode(var_name, var_location)
		"opnd_t " + var_name + " = opnd_create_reg(DR_REG_" + var_location.upcase + ");" 
	end

end