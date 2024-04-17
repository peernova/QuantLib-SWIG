
CLEANFILES = quantlib_wrap.cpp libQuantLibJNI.@JNILIB_EXTENSION@ QuantLib.jar

BUILT_SOURCES = quantlib_wrap.cpp quantlib_wrap.h

EXAMPLES = Bonds CallableBonds CallableBondsOAS DiscreteHedging EquityOptions FRA FunctionDelegates Time

NATIVE_FOLDER = libraries/$(shell uname | tr '[:upper:]' '[:lower:]')/$(shell uname -m)

NATIVE_SOURCE = $(shell quantlib-config --prefix)/lib

SWIGFLAGS =

if JAVA_AUTOLOAD
SWIGFLAGS += -DJAVA_AUTOLOAD
endif

if JAVA_FINALIZER
SWIGFLAGS += -DJAVA_FINALIZER
endif

if JAVA_AUTOCLOSEABLE
SWIGFLAGS += -DJAVA_AUTOCLOSEABLE
endif

if HAVE_JAVA
if BUILD_JAVA

examples/%.class: examples/%.java QuantLib.jar
	$(JAVAC)  -cp QuantLib.jar examples/$*.java

.PHONY: $(EXAMPLES)

all-local: libQuantLibJNI.@JNILIB_EXTENSION@ QuantLib.jar

quantlib_wrap.o: quantlib_wrap.cpp quantlib_wrap.h
	$(CXX) -c quantlib_wrap.cpp -fno-strict-aliasing -fPIC $(CXXFLAGS) @JDK_INCLUDE@ @JDK_SYSTEM_INCLUDE@ `quantlib-config --cflags` -o quantlib_wrap.o

libQuantLibJNI.@JNILIB_EXTENSION@: quantlib_wrap.o
	$(CXX) $(CXXFLAGS) $(LDFLAGS) @SHARED_LIB@ quantlib_wrap.o -o libQuantLibJNI.@JNILIB_EXTENSION@ `quantlib-config --libs`

QuantLib.jar: quantlib_wrap.cpp org/quantlib/*.java
	rm -rf bin $(NATIVE_FOLDER)
	mkdir -p bin $(NATIVE_FOLDER)
	mv libQuantLibJNI.jnilib $(NATIVE_FOLDER)
	find -EL $(NATIVE_SOURCE) -regex '.*/libQuantLib\.(dylib|so)$$' -exec cp {} $(NATIVE_FOLDER) \;
	find org/quantlib -name '*.java' | xargs $(JAVAC) -g -d bin
	$(JAR) cf QuantLib.jar -C bin org libraries

install-exec-local:
	mkdir -p $(DESTDIR)/$(libdir)
	cp -p libQuantLibJNI.@JNILIB_EXTENSION@ $(DESTDIR)/$(libdir)/libQuantLibJNI.@JNILIB_EXTENSION@
	cp -p QuantLib.jar $(DESTDIR)/$(libdir)/QuantLib.jar

check-local: $(EXAMPLES)

$(EXAMPLES): $(EXAMPLES:%=examples/%.class)
	LD_LIBRARY_PATH=. $(JAVA) -cp ".:QuantLib.jar" examples.$@

endif
endif


quantlib_wrap.cpp: ../SWIG/*.i QuantLibJNI.patch
	mkdir -p org/quantlib
	$(SWIG) $(SWIGFLAGS) -java -c++ -outdir org/quantlib \
            -package org.quantlib -o quantlib_wrap.cpp ../SWIG/quantlib.i
	patch org/quantlib/QuantLibJNI.java <QuantLibJNI.patch

dist-hook:
	mkdir -p $(distdir)/org/quantlib
	cp ./org/quantlib/*.java $(distdir)/org/quantlib
	touch $(distdir)/quantlib_wrap.cpp
	touch $(distdir)/quantlib_wrap.h
	mkdir -p $(distdir)/examples
	cp ./examples/*.java $(distdir)/examples

clean-local:
	rm -rf org 
	rm -f examples/*.class
	rm -f quantlib_wrap.o
	rm -rf bin

EXTRA_DIST = README.txt $(BUILT_SOURCES)

