require 'fileutils'
require 'pathname'
require_relative 'helper'


REDIRECT_STDERR = false
DISABLE_INSTRUMENTATION = false
abort("Usage: bininject <binary> [arguments]") if ARGV.length == 0
program_file = ARGV[0]
arguments = ARGV[1..ARGV.length].map{|arg| " " + arg}.join


# Copy patch to bininject source directory
patch_directory = File.dirname(program_file)
begin
	# FileUtils.cp(patch_directory + "/dr_patch.cpp", "source")
rescue Errno::ENOENT => err
  puts red(err.message)
end


# Build bininject DR client
puts "\n\n************************* 1.Building injection client ************************\n"
# If this script is called from another script/Makefile, bash sets the working directory
# to be the same as that of parent/caller script. It breaks any paths relative to the caller,
# e.g. path to the executable. There are a couple of workarounds:
# (A) Let the parent/caller script pass absolute path
# (B) Make the callee script translate paths relative to caller leaving absolute paths intact
# 'working_dir' saves the working directory to implement (B)
working_dir = `pwd`.strip

# Get the file system path of this script and set it as the working directory
current_dir = File.dirname(__FILE__)
Dir.chdir(current_dir)

# Build the client
system("make")


# Patch the buggy executable on the fly
puts "\n\n****************************** 2.Applying patch ******************************\n"
# Know CPU architecture: 32 or 64
arch = `getconf LONG_BIT`
arch.strip!

# Workaround (A) [Not encouraged]
# Concatenating bash commands with && makes those run by the same sub-shell.
# In the caller script, we must explicitly change the working directory to that of bininject 
# module's (this script). Otherwise, callee (this script) invokes Makefile in the working
# directory (caller's) instead of bininject/Makefile. The result is a never ending compilation loop.
# Prepending $(PWD) to the relative path of the executable makes it absolute,
# because altering working directory in the sub-shell breaks the relative path(s).
# e.g. cd $(BF_ROOT)/bininject/ && ruby bininject.rb -p $(PWD)/$(BUILD_DIR)/$(SUBJECT) -a "40"

# Workaround (B) [Adapted]
# Leave the absolute path as-it-is. Only join (prepend) the initial working directory
# saved in 'working_dir' (script location of the caller) to the relative path passed
# to the callee (this script) to construct the absolute path. This approach enables
# the callee to handle both absolute and relative paths transparently.
program_path = program_file
program_path = File.join(working_dir, program_path) unless (Pathname.new program_path).absolute?

# Execute the buggy binary with the patch injected
# Output from binary will appear on console
# oracle is expected to parse the output to decide on outcome, e.g.SUCCESS/FAILURE
cmd_patch_binary = "../deps/DynamoRIO/bin" + arch + "/drrun -c ../build/bininject/libbininject.so "

# Optionally disables instrumentation, comes handy to collect unmodified execution trace
cmd_patch_binary = DISABLE_INSTRUMENTATION ? (cmd_patch_binary + "--disable_instrumentation 1 ") : (cmd_patch_binary + "--disable_instrumentation 0 ")
cmd_patch_binary = cmd_patch_binary + "-- " + program_path

# Pass arguments to the binary, if any
cmd_patch_binary = cmd_patch_binary + arguments unless arguments.nil?

# Redirect stderr to stdout
cmd_patch_binary = cmd_patch_binary + " 2>&1" if REDIRECT_STDERR

# Show and trigger the command
puts green(">> " + cmd_patch_binary)
ret = system(cmd_patch_binary)

# Prompt in case of failure
puts red("[FAILURE]: Patch execution unsuccessful, non-zero exit status") if !ret
puts red("[FAILURE]: Patch execution failed, non-zero exit status") if ret.nil?

# Returns process status, relevant in case of segmentation fault
# $? is an instance of <Process:Status> class
# http://ruby-doc.org/core-2.2.0/Process/Status.html
exit_status = REDIRECT_STDERR ? $?.exitstatus : $?.to_i
puts $?.to_i
exit exit_status