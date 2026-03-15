N?=100000

SCRIPTS_DIR:=$(TASK_DIR)/scripts
SCRIPT_PREP_TEST_DAT:=$(SCRIPTS_DIR)/prep_test_dat.py
TEST_DAT_FILE:=$(TASK_DIR)/test_dat.hex

DEFINES_RAW += TEST_SIZE=$(N)

RUN_OPTIONS+= +TEST_DAT_FILE=$(TEST_DAT_FILE)

.PHONY: prep_test_dat
prep_test_dat:
	python3 $(SCRIPT_PREP_TEST_DAT) $(N) > $(TEST_DAT_FILE)


