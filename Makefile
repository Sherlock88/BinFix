
#######################################################
# Makefile variables
#######################################################
.PHONY: binfault
BF_VERSION = 1.0
BF_DIR := $(shell pwd)
BUILD_DIR = build
DEPENDENCY_DIR = deps
DYNAMORIO_URL = "https://github.com/DynamoRIO/dynamorio/releases/download/release_6_0_0/DynamoRIO-Linux-6.0.0-6.tar.gz"
DYNAMORIO_ARCHIVE := $(shell basename $(DYNAMORIO_URL))
DYNAMORIO_ARCHIVE_PATH = $(BUILD_DIR)/$(DEPENDENCY_DIR)/$(DYNAMORIO_ARCHIVE)
DYNAMORIO_DIR = $(DEPENDENCY_DIR)/DynamoRIO
BINFAULT_BUILD_DIR = $(BUILD_DIR)/binfault

#######################################################
# Build all
#######################################################
all: help dynamorio binfault

#######################################################
# Show banner and tool help
#######################################################
help:
	@echo "-------------------------------------"
	@echo "|            BinFix $(BF_VERSION)             |"
	@echo "-------------------------------------"
	@echo 

#######################################################
# DynamoRIO - The dynamic instrumentation tool
#######################################################
dynamorio: $(DYNAMORIO_DIR)

$(DYNAMORIO_DIR): $(DYNAMORIO_ARCHIVE_PATH)
	mkdir -p $(DYNAMORIO_DIR)
	tar -xvzf $(DYNAMORIO_ARCHIVE_PATH) --directory $(DYNAMORIO_DIR) --strip 1

$(DYNAMORIO_ARCHIVE_PATH):
	mkdir -p build/deps && cd build/deps && wget $(DYNAMORIO_URL)

#######################################################
# BinFault - The fault localization module
#######################################################
binfault: $(BINFAULT_BUILD_DIR)
	cd $(BUILD_DIR)/binfault && make

$(BINFAULT_BUILD_DIR): 
	mkdir -p $(BUILD_DIR)/binfault && cd $(BUILD_DIR)/binfault && cmake $(BF_DIR)/binfault