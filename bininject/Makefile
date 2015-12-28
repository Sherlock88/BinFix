
#######################################################
# Makefile variables
#######################################################
BF_DIR := $(shell pwd)/..
BUILD_DIR = $(BF_DIR)/build
BININJECT_BUILD_DIR = $(BUILD_DIR)/bininject

#######################################################
# BinInject - The patch injection module
#######################################################
bininject: $(BININJECT_BUILD_DIR)
	cd $(BUILD_DIR)/bininject && make

$(BININJECT_BUILD_DIR): 
	mkdir -p $(BUILD_DIR)/bininject && cd $(BUILD_DIR)/bininject && cmake $(BF_DIR)/bininject 
