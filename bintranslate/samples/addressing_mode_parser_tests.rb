require "treetop"
require "colorize"
require_relative '../addressing_mode_parser.rb'


debug = true
test_case_id = 0
dsl_tests = Array.new
dsl_test_type = Array.new


# Test cases

dsl_tests[test_case_id] = "[rbp-0x4]"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "eax"
dsl_test_type[test_case_id] = true
test_case_id += 1


for i in 0...test_case_id

	ast, failure_reason = Parser.parse(dsl_tests[i])

	# Positive test case
	if dsl_test_type[i]

		# Test passed
		if ast
			puts "[+][PASSED] => ".green + dsl_tests[i]
			if debug
				p ast
			end

		# Test failed
		else
			puts "[+][FAILED] => ".red + dsl_tests[i]
			if debug
				puts failure_reason
			end
		end

	# Negative test case
	else

		# Test passed
		if !ast
			puts "[-][PASSED] => ".green + dsl_tests[i]
			if debug
				puts failure_reason
			end
		
		# Test failed
		else
			puts "[-][FAILED] => ".red + dsl_tests[i]
			if debug
				p ast
			end
		end

	end

end
