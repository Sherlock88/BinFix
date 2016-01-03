require 'optparse'

debug = true

# Parse command-line arguments
command_line_arguments = {}
OptionParser.new do |opt|
	opt.on('-a', '--address <VIRTUAL ADDRESS>') { |o| command_line_arguments[:address] = o }
	opt.on('-p', '--program <PATH TO PROGRAM FILE>') { |o| command_line_arguments[:program_file] = o }
end.parse!

raise OptionParser::MissingArgument if command_line_arguments[:address].nil?
raise OptionParser::MissingArgument if command_line_arguments[:program_file].nil?
input_file = command_line_arguments[:program_file]
disassembly_file = command_line_arguments[:program_file] + ".dis"
virtual_addr = command_line_arguments[:address] + ":"

#Search for the instruction corresponding to the virtual address
source_operand = `objdump -d -M intel #{input_file} | grep '#{virtual_addr}' | grep -i 'mov*' | cut -d ',' -f 2-`

if source_operand.empty?
	puts "This is not a Move instruction"
elsif source_operand.include? "DWORD"
	size = 4
	operand = `echo "#{source_operand}" | cut -d ' ' -f 3`.strip
elsif source_operand.include? "QWORD"
	size = 8
	operand = `echo "#{source_operand}" | cut -d ' ' -f 3`.strip
else
	operand = source_operand.strip
end

#Creating lua file for synbolic execution on s2e
file_name = `basename "#{input_file}"`.strip
lua_file_path = "../deps/s2e/" + file_name + ".lua"

File.open('../deps/s2e/sample.lua') 
IO.copy_stream('../deps/s2e/sample.lua', lua_file_path)
file_size = File.size(input_file)
module_name = file_name + "_module"
hex_address = "0x" + command_line_arguments[:address]
#{}%x<sed -i 's/<name>/#{file_name}/g' #{lua_file_path}>


%x<sed  -i  -e 's/<name>/#{file_name}/g' \
		    -e 's/<size>/#{file_size}/' \
		    -e 's/<module>/#{module_name}/'\
		    -e 's/<address>/#{hex_address}/' \
		    -e 's/<instr_anno_name>/#{file_name}#{"_ann"}/'\
		    -e 's/<beforeInstructionflag>/true/' \
		    -e 's/<beforeInstructionflag>/true/' \
		    -e 's/<symbolicflag>/true/'\
		    -e 's/<func_name>/#{file_name}#{"_ann"}/' #{lua_file_path}>

symbolic_name = "sym_" + operand
if size.nil?
	%x<sed  -i 's/<mainbody>/curState:writeRegisterSymb(#{operand}, #{symbolic_name})/' #{lua_file_path}>
end
