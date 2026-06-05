require "open3"

namespace :db do
  namespace :test do
    desc "Prepare parallel test databases"
    task prepare_parallel: :environment do
      workers = Integer(ENV.fetch("PARALLEL_TEST_PROCESSORS", 5))

      raise "PARALLEL_TEST_PROCESSORS must be at least 1" if workers < 1

      puts "Preparing test databases..."

      1.upto(workers) do |worker|
        test_env_number = worker == 1 ? "" : worker.to_s
        database_name = "tariff_admin_test#{test_env_number}"
        env = {
          "RAILS_ENV" => "test",
          "TEST_ENV_NUMBER" => test_env_number,
        }
        command = %w[bundle exec rails db:drop db:create db:schema:load]

        stdout, stderr, status = Open3.capture3(env, *command)

        if ENV["PARALLEL_TEST_PREPARE_VERBOSE"] == "true"
          puts stdout
          warn stderr
        end

        unless status.success?
          puts stdout
          warn stderr
          abort "Failed to prepare #{database_name}"
        end

        puts "Prepared #{database_name}"
      end
    end
  end
end
