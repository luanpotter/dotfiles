export JAVA_8=/home/luan/softwares/java/jdk1.8.0_201
export JAVA_11=/home/luan/softwares/java/jdk-11.0.2
export JAVA_14=/home/luan/softwares/java/jdk-14.0.1

_clear_path() {
  remove_from_path $JAVA_8/bin
  remove_from_path $JAVA_11/bin
}

_to_java_n() {
  _clear_path
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

