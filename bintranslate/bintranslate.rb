require 'optparse'
require 'yaml'
require_relative 'addressing_mode_parser'
require_relative 'translate_variables'
require_relative 'code_generator'
require_relative 'write_output'


debug = true


# Parse command-line arguments
command_line_arguments = {}
OptionParser.new do |opt|
	opt.on('-v', '--variables <VARIABLE FILE>') { |o| command_line_arguments[:variable_file] = o }
	opt.on('-p', '--program <PROGRAM FILE>') { |o| command_line_arguments[:program_file] = o }
end.parse!

raise OptionParser::MissingArgument if command_line_arguments[:variable_file].nil?
raise OptionParser::MissingArgument if command_line_arguments[:program_file].nil?


# Create DynamoRIO output file
output_directory = File.dirname(command_line_arguments[:program_file])
write_output = WriteOutput.new(output_directory)


# Process variables
translate_var = TranslateVar.new(command_line_arguments[:variable_file])
variables = translate_var.readVars
translate_var.show_variables


# Process DSL instructions
code_generator = CodeGenerator.new(variables, write_output)
File.readlines(command_line_arguments[:program_file]).each do |dsl_command|
	dsl_command = YAML.load dsl_command.gsub! ':', ''
	puts "\n****************************** Compilation Begins ******************************\n"
	code_generator.compile dsl_command
end


code_generator.write_code