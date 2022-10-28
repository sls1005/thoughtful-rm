thoughtful_rm: src/thoughtful_rm.nim
	nim c --out:$@ $<
install: thoughtful_rm.nimble
	nimble install
