# java 8

export JAVA_8=/home/luan/softwares/java/jdk1.8.0_201
export JAVA_11=/home/luan/softwares/java/jdk-11.0.2
export JAVA_14=/home/luan/softwares/java/jdk-14.0.1

_clearPath() {
  removeFromPath $JAVA_8/bin
  removeFromPath $JAVA_11/bin
}

_to_java_n() {
  _clearPath
  export JAVA_HOME=$1
  export PATH="$JAVA_HOME/bin:$PATH"
}

to_java8() {
  _to_java_n $JAVA_8
}

to_java11() {
  _to_java_n $JAVA_11
}

to_java14() {
  _to_java_n $JAVA_14
}

