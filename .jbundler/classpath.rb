JBUNDLER_CLASSPATH = []
JBUNDLER_CLASSPATH << '/home/hannesgeorg/.m2/repository/org/eclipse/jgit/org.eclipse.jgit/2.3.1.201302201838-r/org.eclipse.jgit-2.3.1.201302201838-r.jar'
JBUNDLER_CLASSPATH << '/home/hannesgeorg/.m2/repository/com/jcraft/jsch/0.1.46/jsch-0.1.46.jar'
JBUNDLER_CLASSPATH.freeze
JBUNDLER_CLASSPATH.each { |c| require c }
