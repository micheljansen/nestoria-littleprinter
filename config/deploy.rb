require "bundler/capistrano"

set :application, "nestoria-prototype"
set :repository,  "git@git.micheljansen.org:nestoria-prototype"
set :deploy_to, "/srv/apps/nestoria-prototype"

set :user, "capistrano"
set :use_sudo, false

set :scm, :git
set :git_shallow_clone, 1
set :domain, "micheljansen.org"
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, domain
role :app, domain
role :db,  domain, :primary => true # This is where Rails migrations will run

set :deploy_via, :remote_cache

# if you want to clean up old releases on each deploy uncomment this:
# after "deploy:restart", "deploy:cleanup"

# if you're still using the script/reaper helper you will need
# these http://github.com/rails/irs_process_scripts

# If you are using Passenger mod_rails uncomment this:
namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end
