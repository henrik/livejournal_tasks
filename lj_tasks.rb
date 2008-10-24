# LiveJournal::Tasks
# By Henrik Nyh <http://henrik.nyh.se> 2008 under the MIT license.

require 'rubygems'
require 'livejournal/entry'  # sudo gem install livejournal

module LiveJournal
  
  class Entry  # reopening
    alias_method :body, :event
    alias_method :body=, :event=
    alias_method :tags, :taglist
    alias_method :tags=, :taglist=
    
    alias_method :old_load_prop, :load_prop
    def load_prop(name, value, strict=false)
      old_load_prop(name, value, strict)
      case name
      when 'current_mood'
        @mood = value  # fix value.to_i bug in gem
      end
    end
  end
  
  class Tasks
    class NoSuchProperty < StandardError; end
    class BodyRequired < StandardError; end
    
    def initialize(username, password)
      @username = username
      @password = password
      @user = LiveJournal::User.new(username, password)
    end
    
    # Get all entries. Pass a +limit+ to only get that many (the most recent).
    def entries(limit=nil)
      limit ||= -1
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
    
    # Pass the id of an entry and a hash of properties to update them.
    # Anything you don't pass is not changed. Pass a block for more power.
    # If the block returns false (but not nil), the +properties+ are not assigned.
    # The entry.time will always be in GMT, so use +Time.gm+ for time comparisons.
    #   lj.update(1, :subject => "New") {|entry| entry.body = entry.body.gsub('x', 'y') }
    #   lj.update(1, :security => :private) {|entry| entry.time < Time.gm(2005) }
    def update(id, properties={}, &block)
      entry = entry(id)
      assign_properties(entry, properties)
      if block_given?
        b = block.call(entry)
        return if b == false
      end
      LiveJournal::Request::EditEvent.new(@user, entry).run
      entry
    end
    
    # Update all entries, assigning these properties. Takes a block just like +update+.
    # See that method for details.
    def update_all(properties={}, &block)
      # Since this may take a while, establish "now" at this point, and use that in comparisons
      # to determine whether or not to backdate.
      properties = properties.merge(:now => Time.now)
      updates = []
      entries.each do |id, entry|
        u = update(id, properties, &block)
        updates << u if u
      end
      updates
    end
    
    def delete(id)
      LiveJournal::Request::EditEvent.new(@user, entry(id), :delete => true).run
    end
    
  protected
  
    def assign_properties(entry, properties)
      # So LJ doesn't complain about entries out of time.
      now = properties.delete(:now) || Time.now
      if properties[:time] && properties[:time] != now
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
