all: base-case.svg \
     libc-bug.svg \
     libc-bug-rebuilds.svg \
     what-we-want.svg
	cp $^ ../source/images/nixos-security-updates-upadate

%.svg : %.dot
	dot $< -T svg > $@
