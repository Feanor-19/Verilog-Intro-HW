PROJECT_ROOT:=$(abspath .)
export PROJECT_ROOT

TASK_NAME?=blink
TASK_NUM?=ex

TASK_FULL_NAME?=$(TASK_NUM)_$(TASK_NAME)
TB_NAME?=$(TASK_NAME)_tb
DEFINES_RAW?=
RAND_SEED?=25

# NOTE: Quartus requires explicitly specifying Verilog files

# =========================
# ----- FILES & DIRS ------
# =========================

TASK_DIR:=$(PROJECT_ROOT)/$(TASK_FULL_NAME)
export TASK_DIR

SRC_DIR:=$(TASK_DIR)/src
TB_DIR:=$(TASK_DIR)/tb

# may not exist
INC_DIR:=$(TASK_DIR)/inc

# used to reference additional sources and includes
# NOTE: not supported by Quartus currently
RTL_LIST_FILE:=$(TASK_DIR)/rtl_list.f

TB_FILE:=$(TB_DIR)/$(TB_NAME).v
DUMP_FILE:=$(TASK_DIR)/dump.vcd
SIM_FILE:=$(TASK_DIR)/sim
LOCAL_MK:=$(TASK_DIR)/local.mk

QUARTUS_FILES_DIR:=$(TASK_DIR)/quartus_files
FPGA_TOP_FILE:=$(QUARTUS_FILES_DIR)/fpga_top.v

# ============================
# -- ICARUS COMPILE OPTIONS --
# ============================

INCDIR_BASIC_OPT:= -y $(SRC_DIR)

ifneq ($(wildcard $(INC_DIR)),)
INCDIR_BASIC_OPT+= -I$(INC_DIR)
endif

# ============================
# ---- ICARUS RUN OPTIONS ----
# ============================

COMPILE_OPTIONS:=-g2012 $(INCDIR_BASIC_OPT)
RUN_OPTIONS:= +RAND_SEED=$(RAND_SEED)

ifneq ($(wildcard $(RTL_LIST_FILE)),)
RTL_LIST_FILE_OPT:= -f $(RTL_LIST_FILE)
else
RTL_LIST_FILE_OPT:= 
endif

# ===========================
# ------ LOCAL MAKEFILE -----
# ===========================

ifneq ($(wildcard $(LOCAL_MK)),)
include $(LOCAL_MK)
endif

DEFINES:=$(addprefix -D,$(DEFINES_RAW))

# ===========================
# -------- TARGETS ---------- 
# ===========================

# VERILATOR

VERILATOR_LINT_OPTS:= --lint-only --Wall \
					  --Wno-unoptflat --Wno-procassinit --Wno-unusedsignal --Wno-unusedparam\
					  --timing --sv --timescale 1ns/1ps $(INCDIR_BASIC_OPT) --top $(TB_NAME)

.PHONY: verilator_lint
verilator_lint:
	echo $(TASK_DIR)
	cd $(TASK_DIR) && verilator $(VERILATOR_LINT_OPTS) $(DEFINES) \
	$(RTL_LIST_FILE_OPT) $(TB_FILE)

# ICARUS

.PHONY: compile
compile:
	cd $(TASK_DIR) && iverilog $(COMPILE_OPTIONS) $(DEFINES) \
	$(RTL_LIST_FILE_OPT) $(TB_FILE) -o $(SIM_FILE)

.PHONY: run
run:
	cd $(TASK_DIR) && $(SIM_FILE) $(RUN_OPTIONS)

# QUARTUS

.PHONY: quartus_gui
quartus_gui:
	cd $(QUARTUS_FILES_DIR) && quartus fpga & 

.PHONY: quartus_syn
quartus_syn:
	cd $(QUARTUS_FILES_DIR) && quartus_sh --flow compile fpga

.PHONY: quartus_drc
quartus_drc:
	cd $(QUARTUS_FILES_DIR) && quartus_drc fpga

.PHONY: quartus_pgm
quartus_pgm:
	cd $(QUARTUS_FILES_DIR) && quartus_pgm -c "USB-Blaster" -m JTAG -o "p;output/fpga.sof"

# WAVEFORMS

.PHONY: show_waves
show_waves:
	gtkwave $(DUMP_FILE)

# CLEAN

.PHONY: clean_dump
clean_dump:
	rm -f $(wildcard $(PROJECT_ROOT)/**/dump.vcd)

.PHONY: clean_sim
clean_sim:
	rm -f $(wildcard $(PROJECT_ROOT)/**/sim)

.PHONY: clean_quartus
clean_quartus:
	cd $(QUARTUS_FILES_DIR) && rm -rf db incremental_db output simulation fpga.qws greybox_tmp *.bak 

.PHONY: clean_all
clean_all: clean_dump clean_sim clean_quartus
