coverage_directory=/tmp/cover-netorcai-d

default: library

library:
	dub build

library-cov:
	dub build -b cov

unittest:
	dub test

unittest-cov:
	mkdir -p $(coverage_directory)
	dub test -b unittest-cov

clean:
	rm -f -- *.lst
	rm -f -- libnetorcai-client.*
	rm -f -- netorcai-client-*
	rm -rf -- $(coverage_directory)
