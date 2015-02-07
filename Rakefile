require 'rake/clean'

JASMINE_NODE = 'node_modules/jasmine-node/bin/jasmine-node'

task :default => [:test]

task :test => :clean do |t|
  sh JASMINE_NODE, '--coffee', '--forceexit', '--verbose', 'spec'
end

CLEAN.clear
CLEAN << Rake::FileList['{js,spec}/**/*.{js,map}']

task :publish do
  system 'npm publish'
end

# useful to ensure they exist in order to debug with node
task :transpile do
  system 'node_modules/coffee-script/bin/coffee -c js/**/*.coffee spec/**/*.coffee'
end

