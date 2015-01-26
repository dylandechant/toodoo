require "toodoo/version"
require "toodoo/init_db"
require 'highline/import'
require 'pry'
require 'time'


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

  class AddDatetimeColumn < ActiveRecord::Base
    belongs_to :todolists
  end
end

class TooDooApp
  def initialize
    @user = nil
    @todos = nil
    @show_done = false
  end

  def toggle
    if !@show_done
      @show_done = true
      puts "You are now seeing your completed tasks."
    elsif @show_done
      @show_done = false
      puts "You are now seeing your uncompleted tasks"
    end
    gets
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
    list_name = ask("What would you like to title your list?")
    @todos = Toodoo::TodoList.create(:name => list_name, :user_id => @user.id)
  end

  def pick_todo_list
    system 'clear'
    puts "Pick one of your lists"
    choose do |menu|
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

  def delete_todo_list #done
    choices = 'yn'
    if !@todos
      puts "You are currently not editing a list"
    else
      delete = ask("Are you sure you wish to delete the list? (yn)") do |q|
        q.validate = /\A[#{choices}]\Z/
        q.character = true
      end
    end
    if delete == 'y'
      @todos.destroy
      puts "#{@todos} was deleted"
      @todos = nil
    end
      gets
  end

  def new_task
    choices = 'yn'
    new_item = ask("What task would you like to add?")
    add_date = ask("Would you like to add a due date? (yn)") do |q|
      q.validate =/\A[yn]\Z/
      q.character = true
    end
    if add_date == 'y'
      date = prompt_user_date
    else
      date = Date.parse("2030-01-01")
    end
    Toodoo::TodoItem.create(:name => new_item, :finished => false, :todo_list_id => @todos.id, :due_date => date)
  end

  def mark_done
    system 'clear'
    puts "===List: #{@todos.name}==="
    puts "Mark task as done: "
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
    puts "===List: #{@todos.name}==="
    puts "Change Due Date"
    choose do |menu|
      menu.prompt = "Please enter your choice"
      Toodoo::TodoItem.where(todo_list_id: @todos.id, finished: false).each do |x|
        menu.choice(x.name, "something something") {x.update(due_date: prompt_user_date)}
        x.save
      end
      menu.choice(:back)
    end
  end

  def prompt_user_date
    date = ask("Enter the date for the selected task (YYYY-MM-DD: ") do |x|
      x.validate = /^(?:(?:(?:(?:(?:[13579][26]|[2468][048])00)|(?:[0-9]{2}(?:(?:[13579][26])|(?:[2468][048]|0[48]))))-(?:(?:(?:09|04|06|11)-(?:0[1-9]|1[0-9]|2[0-9]|30))|(?:(?:01|03|05|07|08|10|12)-(?:0[1-9]|1[0-9]|2[0-9]|3[01]))|(?:02-(?:0[1-9]|1[0-9]|2[0-9]))))|(?:[0-9]{4}-(?:(?:(?:09|04|06|11)-(?:0[1-9]|1[0-9]|2[0-9]|30))|(?:(?:01|03|05|07|08|10|12)-(?:0[1-9]|1[0-9]|2[0-9]|3[01]))|(?:02-(?:[01][0-9]|2[0-8])))))$/
    end
    Time.parse(date)
  end

  def edit_task
    puts "===List: #{@todos.name}==="
    choose do |menu|
      menu.prompt = "Please enter your choice"
      Toodoo::TodoItem.where(todo_list_id: @todos.id).each do |x|
        menu.choice(x.name, "I LIKE LAMP") {x.update(name: prompt_new_task_name)}
        x.save
      end
    end
  end

  def prompt_new_task_name
    print "What would you like to rename the task to: "
    input = gets.chomp
    return input
  end

  def show_overdue
    puts "===List: #{@todos.name}==="
    puts "Overdue items"
    Toodoo::TodoItem.where(todo_list_id: @todos.id).order(due_date: :desc).each do |x|
      if x.due_date < Date.today
        due = x.due_date.strftime("Was Due: %m/%d/%Y")
        puts "#{due} \t\t#{x.name}"    
      end
    end
    gets
  end

  def display_tasks
    system 'clear'
    puts "===List: #{@todos.name}==="
    Toodoo::TodoItem.where(todo_list_id: @todos.id, finished: @show_done). each do |x|
      due = x.due_date.strftime("Due: %m/%d/%Y")
      if due == 'Due: 01/01/2030'
        due = 'Due: [whenever]'
      end
      puts "#{due} \t\t#{x.name}"
    end
    gets
  end

  def run
    system 'clear'
    puts "Welcome to your personal TooDoo app."
    loop do
      choose do |menu|

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
          system 'clear'
          puts "===List: #{@todos.name}==="
          menu.choice("Show tasks", :show_tasks) { display_tasks }
          menu.choice("Add a new task.", :new_task) { new_task }
          menu.choice("Mark a task finished.", :mark_done) { mark_done }
          menu.choice("Change a task's due date.", :move_date) { change_due_date }
          menu.choice("Update a task's description.",:edit_task) { edit_task }
          menu.choice("Toggle display of tasks you've finished.", :show_done) { toggle }
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
