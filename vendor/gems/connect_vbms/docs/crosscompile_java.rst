Building for different Java versions
====================================

By default, ``rake build`` will build the java code in this library with
whatever version of Java is on your PATH.

To build the connect_vbms gem for a different Java version, you should set two
environment variables before running ``rake``:

``TARGET``: the targeted version of Java

``BOOTCLASSPATH``: the absolute path of ``rt.jar`` for the targeted Java version

For example, I have Java 1.8 as my default but I want to build for Java 1.7,
so I run::

  export TARGET=1.7
  export BOOTCLASSPATH=/Library/Java/JavaVirtualMachines/jdk1.7.0_80.jdk/Contents/Home/jre/lib/rt.jar
  rake build
