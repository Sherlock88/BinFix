require "treetop"
require "colorize"
require_relative '../c_style_parser/c_style_parser.rb'


debug = false
test_case_id = 0
dsl_tests = Array.new
dsl_test_type = Array.new


# Test cases

dsl_tests[test_case_id] = "4 + 5"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "4+5"
dsl_test_type[test_case_id] = false
test_case_id += 1

dsl_tests[test_case_id] = "myfunction(156)"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "myfunction (156)"
dsl_test_type[test_case_id] = false
test_case_id += 1

dsl_tests[test_case_id] = "myfunction( 156)"
dsl_test_type[test_case_id] = false
test_case_id += 1

dsl_tests[test_case_id] = "4 + (5 * (9 + 8))"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "8 && 9 | 50 + [40056] - (9 * 8)"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "[156] + 50 - (9 * [458])"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "[156] + (9 * [458]) > 5 + 6"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "[rax - 0x400056] + 9"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "([rax + 0x48] + [0X50000] * eax) < 90"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "[rax - 0x400056] + 9 jump 0x400568"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "[rax - 0x400056] = [156] + (9 * [458])"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "[rax - 0x400056] = ax"
dsl_test_type[test_case_id] = true
test_case_id += 1

dsl_tests[test_case_id] = "(4 * 4) < 90"
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
