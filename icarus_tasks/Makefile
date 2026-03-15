PROJECT_ROOT:=$(abspath .)
export PROJECT_ROOT

TASK_NAME?=fp16
TASK_NUM?=01

TASK_FULL_NAME?=$(TASK_NUM)_$(TASK_NAME)
TB_NAME?=$(TASK_NAME)_tb
DEFINES_RAW?=#BEHAVIORAL
RAND_SEED?=19

TASK_DIR:=$(PROJECT_ROOT)/$(TASK_FULL_NAME)
export TASK_DIR

SRC_DIR:=$(TASK_DIR)/src
TB_DIR:=$(TASK_DIR)/tb

RTL_LIST_FILE:=$(TASK_DIR)/rtl_list.f
TB_FILE:=$(TB_DIR)/$(TB_NAME).v
DUMP_FILE:=$(TASK_DIR)/dump.vcd
SIM_FILE:=$(TASK_DIR)/sim
LOCAL_MK:=$(TASK_DIR)/local.mk

COMPILE_OPTIONS:=-g2012
RUN_OPTIONS:= +RAND_SEED=$(RAND_SEED)

VERILATOR_LINT_OPTS:= --lint-only --timing --sv --timescale 1ns/1ps --top $(TB_NAME)

ifneq ($(wildcard $(LOCAL_MK)),)
include $(LOCAL_MK)
endif

DEFINES:=$(addprefix -D,$(DEFINES_RAW))

.PHONY: verilator_lint
verilator_lint:
	echo $(TASK_DIR)
	cd $(TASK_DIR) && verilator $(VERILATOR_LINT_OPTS) $(DEFINES) \
	-f $(RTL_LIST_FILE) $(TB_FILE)

.PHONY: compile
compile:
	cd $(TASK_DIR) && iverilog $(COMPILE_OPTIONS) $(DEFINES) \
	-f $(RTL_LIST_FILE) $(TB_FILE) -o $(SIM_FILE)

.PHONY: run
run:
	cd $(TASK_DIR) && $(SIM_FILE) $(RUN_OPTIONS)

.PHONY: show_waves
show_waves:
	gtkwave $(DUMP_FILE)

.PHONY: clean_dump
clean_dump:
	rm -f $(DUMP_FILE)

.PHONY: clean_sim
clean_sim:
	rm -f $(SIM_FILE)

.PHONY: clean_all
clean_all: clean_dump clean_sim

.PHONY: create_task_template
create_task_template:
	mkdir $(TASK_DIR) && mkdir $(SRC_DIR) \
	&& mkdir $(TB_DIR) && touch $(RTL_LIST_FILE) \
	&& touch $(TB_FILE)
