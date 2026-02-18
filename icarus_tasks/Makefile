PROJECT_ROOT:=$(abspath .)
export PROJECT_ROOT

TASK_NAME?=00_signext
TB_NAME?=signext_tb
DEFINES_RAW?=BEHAVIORAL

TASK_DIR:=$(PROJECT_ROOT)/$(TASK_NAME)
export TASK_DIR

SRC_DIR:=$(TASK_DIR)/src
TB_DIR:=$(TASK_DIR)/tb
RTL_LIST_FILE:=$(TASK_DIR)/rtl_list.f
TB_FILE:=$(TB_DIR)/$(TB_NAME).v
DUMP_FILE:=$(TASK_DIR)/dump.vcd
SIM_FILE:=$(TASK_DIR)/sim

DEFINES:=$(addprefix -D,$(DEFINES_RAW))
OPTIONS:=-g2005-sv

.PHONY: compile
compile:
	cd $(TASK_DIR) && iverilog $(OPTIONS) $(DEFINES) -f $(RTL_LIST_FILE) $(TB_FILE) -o $(SIM_FILE)

.PHONY: run
run:
	cd $(TASK_DIR) && $(SIM_FILE)

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
	&& mkdir $(TB_DIR) && touch $(RTL_LIST_FILE)