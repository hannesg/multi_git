require File.join(File.dirname(__FILE__), 'vendor/org.eclipse.jgit-2.3.1.201302201838-r.jar')

bld = Java::OrgEclipseJgitStorageFile::FileRepositoryBuilder.new
bld.findGitDir(Java::JavaIO::File.new('.'))
repo = bld.build

puts repo.inspect
