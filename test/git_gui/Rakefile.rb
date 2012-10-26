gem 'asrake', "~>0.13.0"
require 'asrake'
require 'rake/clean'

#
# Config
#

swf = ASRake::Mxmlc.new "bin/git_gui.swf"
swf.load_config << "obj/git_guiConfig.xml"
swf.isAIR = true
CLEAN.add swf

air = ASRake::Adt.new "deploy/git_gui.air"
air.keystore = "cert.p12"
air.keystore_name = "git_gui"
air.storepass = "git_gui"
air.tsa = "none"
air.include_files << "bin ."
CLEAN.add air

#
# Tasks
#

task :default do
	system("rake --tasks")
end

desc "Build app"
task :build => swf

desc "Package AIR"
task :package => [:build, air]

desc "Run the project through ADL"
task :run do
	puts "Starting AIR Debug Launcher..."
	run "#{FlexSDK::adl} application.xml #{swf.output_dir}"
end