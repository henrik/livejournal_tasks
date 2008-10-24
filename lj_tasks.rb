# LiveJournal::Tasks
# By Henrik Nyh <http://henrik.nyh.se> 2008 under the MIT license.

require 'rubygems'
require 'livejournal/entry'  # sudo gem install livejournal

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
      # So LJ doesn't complain about future entries when making earlier ones.
      if properties[:time] && properties[:time] > Time.now
        properties[:backdated] = true
      end
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
