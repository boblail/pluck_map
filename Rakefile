require "bundler/gem_tasks"
require "rake/testtask"

namespace :db do
  namespace :mysql do
    task :env do
      system "mysql -e 'drop database if exists pluck_map_test'"
      system "mysql -e 'create database pluck_map_test'"
      ENV["ACTIVE_RECORD_ADAPTER"] = "mysql2"
    end
  end

  namespace :postgres do
    task :env do
      system "psql -c 'drop database if exists pluck_map_test'"
      system "psql -c 'create database pluck_map_test'"
      ENV["ACTIVE_RECORD_ADAPTER"] = "postgresql"
    end
  end

  namespace :sqlite do
    task :env do
      ENV["ACTIVE_RECORD_ADAPTER"] = "sqlite3"
    end
  end
end

ADAPTERS = Rake.application.tasks.each_with_object([]) do |task, adapters|
  match = task.name.match(/db:(.*):env/)
  adapters.push(match[1]) if match
end.freeze

namespace :test do
  ADAPTERS.each do |adapter|
    Rake::TestTask.new(adapter => "db:#{adapter}:env") do |t|
      t.libs << "test"
      t.libs << "lib"
      t.test_files = FileList["test/**/*_test.rb"]
    end  end
end

def run_without_aborting(*tasks)
  errors = []

  tasks.each do |task|
    puts task
    Rake::Task[task].invoke
  rescue Exception
    errors << task
  end

  abort "Errors running #{errors.join(', ')}" if errors.any?
end

desc "Run #{ADAPTERS.join(', ')} tests"
task :test do
  tasks = ADAPTERS.map { |adapter| "test:#{adapter}" }
  run_without_aborting(*tasks)
end

desc "Run #{ADAPTERS.join(', ')} tests by default"
task default: :test
