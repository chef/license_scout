DEPS=$(CURDIR)/deps
DIALYZER_DEPS= deps/folsom/ebin deps/lager/ebin
DEPS_PLT = folsom_graphite.plt

all: compile eunit dialyzer

clean:
	@rebar skip_deps=true clean

compile: $(DEPS)
	@rebar compile

$(DEPS):
	@rebar get-deps

distclean:
	@rm -rf deps $(DEPS_PLT)
	@rebar skip_deps=true clean

eunit:
	@rebar skip_deps=true eunit

test: eunit

dialyzer: $(DEPS_PLT)
	@dialyzer -Wunderspecs --plts ~/.dialyzer_plt $(DEPS_PLT) -r ebin

$(DEPS_PLT):
	@dialyzer --build_plt $(DIALYZER_DEPS) --output_plt $(DEPS_PLT)

.PHONY: check_calls

