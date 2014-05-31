require 'rake/clean'

JASMINE_NODE = 'node_modules/jasmine-node/bin/jasmine-node'

task :default => [:test]

task :test => :clean do |t|
  sh JASMINE_NODE, '--coffee', '--forceexit', '--verbose', 'spec'
end

# i'm not sure what the expectations are for .js transpiling location
# but while i'm still getting used to coffeescript, i'm choosing to
# output js files to the same directory. but - jasmine-node will then
# pick up both .coffee and .js files and execute both, so rather than
# 'knowing' and 'trusting' my .js files and having them output elsewhere,
# going to leave them be and clean my js files up here.
CLEAN.clear
CLEAN << Rake::FileList['spec/*.js']

task :deploy do
  FileUtils.cp(Dir['./js/token-poker-hubot-dealer.coffee'], '../hungrybot/scripts', verbose: true)
  FileUtils.cp(Dir['./js/token-poker/*.coffee'], '../hungrybot/scripts/token-poker', verbose: true)
end