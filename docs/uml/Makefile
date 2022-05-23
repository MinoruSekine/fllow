PLANTUML_COMMAND := plantuml

SRC_DIR := src
OUT_DIR := out

UML_SRC_FILES := $(wildcard $(SRC_DIR)/*.pu)
UML_PNG_FILES := $(subst $(SRC_DIR), $(OUT_DIR), $(UML_SRC_FILES:.pu=.png))

all: $(UML_PNG_FILES)

$(UML_PNG_FILES): $(OUT_DIR)/%.png: $(SRC_DIR)/%.pu
	-mkdir -p $(dir $@)
	$(PLANTUML_COMMAND) -png $< -o $(abspath $(dir $@))

clean:
	-rm -f $(UML_PNG_FILES)
	-rm -rf $(OUT_DIR)

.PHONY: all clean
