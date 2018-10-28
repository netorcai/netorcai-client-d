default: library

library:
	dub build

library-cov:
	dub build -b cov

unittest:
	dub test

unittest-cov:
	dub test -b unittest-cov

clean:
	rm -f -- *.lst
	rm -f -- libnetorcai-client.*
	rm -f -- netorcai-client-*
