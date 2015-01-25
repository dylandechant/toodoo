require "toodoo/version"
require "toodoo/init_db"
require 'highline/import'
require 'pry'


module Toodoo
  class User < ActiveRecord::Base
    has_many :todolists
  end

  class TodoList < ActiveRecord::Base
    belongs_to :user
    has_many :todoitems
  end

  class TodoItem < ActiveRecord::Base
    belongs_to :todolist
  end
end

class TooDooApp
  def initialize
    @user = nil
    @todos = nil
    @show_done = nil
  end

  def new_user
    system 'clear'
    say("Creating a new user:")
    name = ask("Username?") { |q| q.validate = /\A\w+\Z/ }
    @user = Toodoo::User.create(:name => name)
    say("We've created your account and logged you in. Thanks #{@user.name}!")
  end

  def login
    system 'clear'
    puts "Current accounts:"
    choose do |menu|
      menu.prompt = "Please choose an account: "

      Toodoo::User.find_each do |u|
        menu.choice(u.name, "Login as #{u.name}.") { @user = u }
      end

      menu.choice(:back, "Just kidding, back to main menu!") do
        say "You got it!"
        @user = nil
      end
    end
  end

  def delete_user
    choices = 'yn'
    delete = ask("Are you *sure* you want to delete yourself #{@user.name}?") do |q|
      q.validate =/\A[#{choices}]\Z/
      q.character = true
      q.confirm = true
    end
    if delete == 'y'
      @user.destroy
      @user = nil
    end
  end

  def new_todo_list
    # TODO: This should create a new todo list by getting input from the user.
    # The user should not have to tell you their id.
    # Create the todo list in the database and update the @todos variable.
    list_name = ask("What would you like to title your list?")
    @todos = Toodoo::TodoList.create(:name => list_name, :user_id => @user.id)
  end

  def pick_todo_list
    system 'clear'
    puts "Pick one of your lists"
    choose do |menu|
      # TODO: This should get get the todo lists for the logged in user (@user).
      # Iterate over them and add a menu.choice line as seen under the login method's
      # find_each call. The menu choice block should set @todos to the todo list.
      menu.prompt = "Enter your choice"
      Toodoo::TodoList.where(user_id: @user.id).each do |x|
        menu.choice(x.name, "Does this work?") { @todos =  x }
      end

      menu.choice(:back, "Just kidding, back to the main menu!") do
        say "You got it!"
        @todos = nil
      end
    end
  end

  def delete_todo_list
    # TODO: This should confirm that the user wants to delete the todo list.
    # If they do, it should destroy the current todo list and set @todos to nil.
    choices = 'yn'
    delete = ask("Are you sure you wish to delete the list? (yn)") do |q|
      q.validate = /\A[#{choices}]\Z/
      q.character = true
      q.confirm = true
    end
    if delete == 'y'
      @todos.destroy
      @todos = nil
    end
  end

  def new_task
    # TODO: This should create a new task on the current user's todo list.
    # It must take any necessary input from the user. A due date is optional.
    new_item = ask("What task would you like to add?")
    Toodoo::TodoItem.create(:name => new_item, :finished => false, :todo_list_id => @todos.id)
  end

  ## NOTE: For the next 3 methods, make sure the change is saved to the database.
  def mark_done
    # TODO: This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should update the todo to be completed.
    choose do |menu|
      menu.prompt = "Please enter your choice"
      Toodoo::TodoItem.where(todo_list_id: @todos.id, finished: false).each do |x|
        menu.choice(x.name, "something something") {x.update(finished: true)}
        x.save
      end
      menu.choice(:back)
    end
  end

  def change_due_date
    # TODO: This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should update the due date for the todo. You probably want to use
    # `ask("foo", Date)` here.
  end

  def edit_task
    # TODO: This should display the todos on the current list in a menu
    # similarly to pick_todo_list. Once they select a todo, the menu choice block
    # should change the name of the todo.
    choose do |menu|
      menu.prompt = "Please enter your choice"
      Toodoo::TodoItem.where(todo_list_id: @todos.id) do |x|
        menu.choice(x.name, "I LIKE LAMP") {x.update(name: "hellooooo")}
      end
    end
  end

  def show_overdue
    # TODO: This should print a sorted list of todos with a due date *older*
    # than `Date.now`. They should be formatted as follows:
    # "Date -- Eat a Cookie"
    # "Older Date -- Play with Puppies"
  end

  def run
    system 'clear'
    puts "Welcome to your personal TooDoo app."
    loop do
      choose do |menu|
        #menu.layout = :menu_only
        #menu.shell = true

        # Are we logged in yet?
        unless @user
          menu.choice( "Create a new user.", :new_user) { new_user }
          menu.choice("Login with an existing account.", :login) { login }
        end

        # We're logged in. Do we have a todo list to work on?
        if @user && !@todos
          system 'clear'
          puts "Lists by #{@user.name} for #{@user.name}"
          menu.choice( "Delete the current user account.", :delete_account) { delete_user }
          menu.choice("Create a new todo list.", :new_list) { new_todo_list }
          menu.choice("Work on an existing list.", :pick_list) { pick_todo_list }
          menu.choice("Delete a todo list.", :remove_list) { delete_todo_list }
        end

        # Let's work on some todos!
        if @todos
          puts "===List: #{@todos.name}==="
          menu.choice("Add a new task.", :new_task) { new_task }
          menu.choice("Mark a task finished.", :mark_done) { mark_done }
          menu.choice("Change a task's due date.", :move_date) { change_due_date }
          menu.choice("Update a task's description.",:edit_task) { edit_task }
          menu.choice("Toggle display of tasks you've finished.", :show_done) { @show_done = !!@show_done }
          menu.choice("Show a list of task's that are overdue, oldest first.", :show_overdue) { show_overdue }
          menu.choice("Go work on another Toodoo list!", :back) do
            say "You got it!"
            @todos = nil
          end
        end

        menu.choice("Quit!", :quit) { exit }
      end
    end
  end
end

todos = TooDooApp.new
todos.run
