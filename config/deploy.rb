# config valid for current version and patch releases of Capistrano
lock "~> 3.17.0"

set :application, "deploy-test"
set :repo_url, "https://github.com/k-nishimoto-libertyfish/deploy-test.git"
server "nakadate-pro.local", port: 2525, roles: [:app, :web, :db], primary: true

set :user, "nakadate"
set :use_sudo, false
set :stage, :production
set :deploy_via, :remote_cache
set :deploy_to, "/home/nakadate/rails/#{fetch(:application)}"

set :puma_threads, [4,16]
set :puma_workers, 0
set :puma_bind, "unix://#{shared_path}/tmp/sockets/puma.sock"
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{shared_path}/log/puma.access.log"
set :puma_error_log, "#{shared_path}/log/puma.error.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true

set :pry, true
set :ssh_options, {
    user: 'nakadate'
}

set :rbnev_type, :user
set :rbenv_ruby, '2.7.4'

set :linked_dirs, fetch(:linked_dirs, []).push(
    'log',
    'tmp/pids',
    'tmp/cache',
    'tmp/sockets',
    'vendor/bundle',
    'public/system',
    'public/uploads'
)

set :lined_files, fetch(:linked_files, []).push(
    'config/database.yml'
)

namespace :puma do
  desc 'make_dirs'
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end
  before :deploy, "puma:make_dirs"
end

namespace :deploy do
  desc "deploy"
  task :check_revision do
    on roles(:app) do
      unless `git rev-parse HEAD` == `git rev-parse origin/master`
        puts "WARNING"
        puts "run ..."
        exit
      end
    end
  end

  desc "restart"
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      invoke "puma:restart"
    end
  end
  desc "upload..."
  task :upload do
    on roles(:app) do |host|
      if test "[ ! -d #{shared_path}/config ]"
        execute "mkdir -p #{shared_path}/config"
      end
      upload!('config/database.yml', "#{shared_path}/config/database.yml")
    end
  end
  before :deploy, 'deploy:upload'
  before :deploy, 'deploy:check_revision'
end

      