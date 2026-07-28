SHELL := /bin/bash
ROOT_DIR := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

TARGET := x86_64-linux-gnu
JOBS := $(shell nproc 2>/dev/null || echo 4)

OUTPUT_DIR := $(ROOT_DIR)/build/out
SOURCES_DIR := $(ROOT_DIR)/build/sources
BUILD_DIR := $(ROOT_DIR)/build/make
CROSS_TOOLS_DIR := $(ROOT_DIR)/build/cross-tools
SYSROOT := $(ROOT_DIR)/build/sysroot
HPM_DIR := $(ROOT_DIR)/flash

CFLAGS := -O2 -pipe
CXXFLAGS := -O2 -pipe
MAKEFLAGS := -j$(JOBS)
