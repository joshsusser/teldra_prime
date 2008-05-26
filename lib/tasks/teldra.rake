require 'highline'
namespace :teldra do
  namespace :setup do

    desc "Create initial user account, prompting for user name and password."
    task :user => :environment do
      ui = HighLine.new
      name     = ui.ask("Human name: ")
      email    = ui.ask("email: ")
      login    = ui.ask("Login name: ")
      password = ui.ask("Enter password: ") { |q| q.echo = false }
      confirm  = ui.ask("Confirm password: ") { |q| q.echo = false }
      
      user = User.new(:name => name, :email => email, :login => login, :password => password, :password_confirmation => confirm)
      if user.save
        puts "User account '#{login}' created."
      else
        puts
        puts "Problem creating user account:"
        puts user.errors.full_messages
      end
    end

  end
end