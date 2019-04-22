# java 8

export JAVA_8=/home/luan/softwares/java/jdk1.8.0_201
export JAVA_11=/home/luan/softwares/java/jdk-11.0.2

_clearPath() {
  removeFromPath $JAVA_8/bin
  removeFromPath $JAVA_11/bin
}

to_java8() {
  _clearPath
  export JAVA_HOME=$JAVA_8
  export PATH="$JAVA_HOME/bin:$PATH"
}

to_java11() {
  _clearPath
  export JAVA_HOME=$JAVA_11
  export PATH="$JAVA_HOME/bin:$PATH"
}

