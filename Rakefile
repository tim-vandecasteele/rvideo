require 'bundler'
Bundler::GemHelper.install_tasks

desc "Run all the specs"
task :spec do
  system "bundle exec rspec spec"
end

desc "Run encoding progress reporting"
task :pg_report do
  system "bundle exec ruby spec/test_progress_reporting.rb"
end



task :default => :spec