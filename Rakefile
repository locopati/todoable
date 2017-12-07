# testing

task :console do
  require 'irb'
  require 'irb/completion'
  require 'todoable_list'
  require 'todoable_client'

  ARGV.clear
  IRB.start
end

task :test do
  system 'rspec specs'
  system 'rubocop -fp -fo'
end

task :test_debug do
  ENV['HTTP_DEBUG'] = '1'
  Rake::Task['test'].invoke
end

# deployment

task :build do
  system 'gem build todoable.gemspec'
end

task :install do
  system 'gem install -V --user-install todoable-0.0.1.gem'
end