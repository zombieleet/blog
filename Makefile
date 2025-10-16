MMDC = npx @mermaid-js/mermaid-cli
SRC  = $(shell find content/_mermaid -name '*.mmd')
OUTS = $(patsubst content/_mermaid/%.mmd,static/diagrams/%.svg,$(SRC)) \
       $(patsubst content/_mermaid/%.mmd,static/diagrams/%.png,$(SRC))

all: $(OUTS)

static/diagrams/%.svg: content/_mermaid/%.mmd
	@mkdir -p $(dir $@)
	$(MMDC) -i $< -o $@ --backgroundColor transparent

static/diagrams/%.png: content/_mermaid/%.mmd
	@mkdir -p $(dir $@)
	$(MMDC) -i $< -o $@ -s 1.25
