# if BOOTCLASSPATH, TARGET are defined, enable building for a specific java
ifneq (,$(and $(BOOTCLASSPATH), $(TARGET)))
  TARGET_ARG=-target $(TARGET)
  SOURCE_ARG=-source $(TARGET)
  BOOTCLASSPATH_ARG=-bootclasspath $(BOOTCLASSPATH)
else
  TARGET_ARG=
  SOURCE_ARG=
  BOOTCLASSPATH_ARG=
endif

all: EncryptSOAPDocument.class DecryptMessage.class

EncryptSOAPDocument.class: main/java/EncryptSOAPDocument.java
	javac $(SOURCE_ARG) $(TARGET_ARG) $(BOOTCLASSPATH_ARG) -classpath '../lib/*:../main/properties' -d ../classes main/java/EncryptSOAPDocument.java

DecryptMessage.class: main/java/DecryptMessage.java
	javac $(SOURCE_ARG) $(TARGET_ARG) $(BOOTCLASSPATH_ARG) -classpath '../lib/*:../main/properties' -d ../classes main/java/DecryptMessage.java

.PHONY: build
build: EncryptSOAPDocument.class DecryptMessage.class
