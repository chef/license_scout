DEPS = 
all: compile all_tests

all_tests: dialyzer eunit

use_locked_config = $(wildcard USE_REBAR_LOCKED)
ifeq ($(use_locked_config),USE_REBAR_LOCKED)
  rebar_config = rebar.config.lock
else
  rebar_config = rebar.config
endif
REBAR = rebar -C $(rebar_config)

clean:
	$(REBAR) clean

allclean: depclean clean

depclean:
	@rm -rf deps

compile: $(DEPS)
	$(REBAR) compile

compile_app:
	$(REBAR) skip_deps=true compile

plt_clean:
	@dialyzer --build_plt --apps erts kernel stdlib 

plt:
	@dialyzer --add_to_plt deps/*/ebin

dialyze:
	dialyzer --src -Wunmatched_returns -Werror_handling -Wrace_conditions -r src -I deps

dialyzer:
	@rm -rf .eunit
	@dialyzer -Wrace_conditions -Wunderspecs -r src --src

$(DEPS):
	$(REBAR) get-deps

eunit: compile
	$(REBAR) eunit 

test: eunit

tags:
	@find src deps -name "*.[he]rl" -print | etags -

distclean: relclean
	@rm -rf deps
	$(REBAR) clean
