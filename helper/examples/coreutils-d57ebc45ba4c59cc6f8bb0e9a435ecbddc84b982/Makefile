

ifndef BF_ROOT
$(error BF_ROOT is not set and exported in the parent shell)
endif
SUBJECT := coreutils-d57ebc45ba4c59cc6f8bb0e9a435ecbddc84b982
TESTS = $(shell echo $$((`grep -c "assert-equal" oracle` - 1)))
BUILD_DIR = $(BF_ROOT)/build/$(SUBJECT)
SUBDIR=src
.DEFAULT_GOAL := all
RED = '\033[0;31m'
GREEN = '\033[0;32m'
YELLOW = '\033[1;33m'
NC = '\033[0m'


help:
	@echo "Usage: make <targets>"
	@echo "targets:"
	@echo -e "\thelp  : Display this brief help"
	@echo -e "\tall   : Default rule to build the subject"
	@echo -e "\tbuggy : Execute the buggy program"
	@echo -e "\tfixed : Execute the fixed program"


all: $(BUILD_DIR)
	cd $(BUILD_DIR); \
	git checkout -b buggy d57ebc45ba4c59cc6f8bb0e9a435ecbddc84b982; \
	./bootstrap; \
	./configure; \
	make
	objdump -d -M intel $(BUILD_DIR)/$(SUBDIR)/cut > $(BUILD_DIR)/$(SUBDIR)/cut.dis


$(BUILD_DIR):
	@ printf ${YELLOW}"\n********************* Compile Binary *********************"${NC}"\n"
	git clone git://git.sv.gnu.org/coreutils $(BUILD_DIR)


# To keep test running even in case of failure:
# (A) Either, prepend a '-' in front of the recipe or run make with '-i' or '--ignore-errors' flag
# Ref: http://www.gnu.org/software/make/manual/make.html#Error-Messages
# (B) Or, write the recipe line in such a way that it always returns true/success
# && works if $? is zero and || is proceed in case of a non-zero return value
# Ref: http://unix.stackexchange.com/questions/153763/dont-stop-makeing-if-a-command-fails-but-check-exit-status

buggy:
	@ printf ${YELLOW}"\n********************* Buggy Execution *********************"${NC}"\n"
	@ cp oracle $(BUILD_DIR)
	@ export RUNNER=; \
	cd $(BUILD_DIR); \
	for t in `seq 1 $(TESTS)`; do \
		./oracle $$t && printf ${GREEN}SUCCESS${NC}"\n" || printf ${RED}FAILURE${NC}"\n"; \
	done


fixed: inject
	@ printf ${YELLOW}"\n********************* Fixed Execution *********************"${NC}"\n"
	@ cp oracle $(BUILD_DIR)
	@ export RUNNER="ruby $(BF_ROOT)/bininject/bininject.rb "; \
	cd $(BUILD_DIR); \
	for t in `seq 1 $(TESTS)`; do \
		./oracle $$t && printf ${GREEN}SUCCESS${NC}"\n" || printf ${RED}FAILURE${NC}"\n"; \
	done


$(BUILD_DIR)/variables: variables
	cp variables $(BUILD_DIR)


$(BUILD_DIR)/dsl_patch: dsl_patch
	cp dsl_patch $(BUILD_DIR)


$(BUILD_DIR)/dr_patch.cpp: $(BUILD_DIR)/variables $(BUILD_DIR)/dsl_patch
	@ printf ${YELLOW}"\n********************* Translate DSL Patch *********************"${NC}"\n"
	ruby $(BF_ROOT)/bintranslate/bintranslate.rb -p $(BUILD_DIR)/dsl_patch -v $(BUILD_DIR)/variables


inject: $(BUILD_DIR)/dr_patch.cpp
	@ printf ${YELLOW}"\n********************* Compile Injection Client *********************"${NC}"\n"
	-rm -rf $(BF_ROOT)/build/bininject
	cp $(BUILD_DIR)/dr_patch.cpp $(BF_ROOT)/bininject/source