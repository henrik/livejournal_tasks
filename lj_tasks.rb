# Thin wrapper around Evan Martin's livejournal gem
# (http://neugierig.org/software/livejournal/ruby/)
# to make a more task-oriented and easier to use lib.
#
# See the gem documentation for more details, if you need them:
# http://neugierig.org/software/livejournal/ruby/doc/
#
# Install the gem:
#   sudo gem install livejournal
#
# By Henrik Nyh <http://henrik.nyh.se> 2008 under the MIT license.
#
# Tasks will be added as I need them. Please fork this project and add your own.
# The current tasks are ones I needed for cross-posting: having a non-LJ blog
# create and update mirror LiveJournal posts.
#
# Example usage:
#
#   lj = LiveJournal::Tasks.new('username', 'password')
#
#   lj.entries     # Hash of the last 10 entries, with id keys and LiveJournal::Entry values.
#   lj.entries(5)  # Hash of the last 5 entries.
#
#   lj.entry(1)    # LiveJournal::Entry with that id.
#   lj.url(1)      # LiveJournal URL for the entry with that id.
#
#   lj.create(:subject => "Foo", :body => "Bar")  # Returns the entry id, an integer.
#   lj.update(1, :body => "Baz")  # Update the entry with that id.
#   lj.delete(1)   # Remove the entry with that id.
#
# Properties for #create and #update:
#
#  :subject       A string.
#  :body          The post contents. Alias for :event. Passing nil or "" raises AccidentalDeleteError.
#  :tags          An array of strings. Alias for :taglist.
#  :time          A Time object. LiveJournal will use the time as-is, ignoring the time zone. Can be past or future.
#  :mood          A string. TODO: Is currently reset on update unless specified every time.
#  :music         A string.
#  :location      A string.
#  :pickeyword    User picture keyword. A string.
#  :security      One of: :public, :friends, :private, :custom (pass an :allowmask integer with :custom).
#  :comments      One of: :normal, :none, :noemail
#  :screening     One of: :default, :all, :anonymous, :nonfriends, :none
#  :preformatted  Boolean. Tells LJ not to touch your HTML. Defaults to true if you update the body.

require 'rubygems'
require 'livejournal/entry'

module LiveJournal
  class Tasks
    class NoSuchProperty < StandardError; end
    class BodyRequired < StandardError; end
    
    def initialize(username, password)
      @username = username
      @password = password
      @user = LiveJournal::User.new(username, password)
    end
    
    # Get the last +limit+ entries.
    def entries(limit=10)
      LiveJournal::Request::GetEvents.new(@user, :recent => limit, :strict => false).run
    end
    
    # Get the LiveJournal::Entry with a given id.
    def entry(id)
      LiveJournal::Request::GetEvents.new(@user, :itemid => id, :strict => false).run
    end
    
    # Get the LiveJournal URL (e.g. http://foo.livejournal.com/123.html) for the entry with a given id.
    def url(id)
      entry(id).url(@user)
    end
    
    # Pass a hash of properties to create an entry. The :body is required. If you don't set
    # a :subject, a date string like "Jan. 1st, 2009" will be used.
    def create(properties={})
      entry = LiveJournal::Entry.new
      properties[:time] ||= Time.now
      unless properties[:body]
        raise BodyRequired, "You must pass a :body."
      end
      assign_properties(entry, properties)
      LiveJournal::Request::PostEvent.new(@user, entry).run
      entry.itemid
    end
    
    # Pass the id of an entry and a hash of properties to update them. Anything you don't pass
    # is not changed (except for :mood that is currently reset if not passed every time).
    def update(id, properties={})
      entry = entry(id)
      assign_properties(entry, properties)
      LiveJournal::Request::EditEvent.new(@user, entry).run
    end
    
    def delete(id)
      LiveJournal::Request::EditEvent.new(@user, entry(id), :delete => true).run
    end
    
  protected
  
    def assign_properties(entry, properties)
      if properties[:time].is_a?(Time)
        properties[:time] = LiveJournal.coerce_gmt(properties[:time])
      end
      if body = properties.delete(:body)
        properties[:event] ||= body
      end
      if tags = properties.delete(:tags)
        properties[:taglist] ||= tags
      end
      if properties.has_key?(:event)
        properties[:preformatted] ||= true
      end
      
      properties.each do |key, value|
        m = "#{key}="
        if entry.respond_to?(m)
          entry.send(m, value)
        else
          raise NoSuchProperty, %{Entries don't have the "#{key}" property.}
        end
      end
    end
    
  end
end
