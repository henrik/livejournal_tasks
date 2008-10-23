# LiveJournal::Tasks

This Ruby library is a thin wrapper around [Evan Martin's livejournal gem](http://neugierig.org/software/livejournal/ruby/) to make a more task-oriented and easier-to-use lib.

Tasks will be added as I need them. Please fork this project and add your own.

The current tasks are ones I needed for cross-posting: having a non-LJ blog create and update mirror LiveJournal posts.


See [the gem documentation](http://neugierig.org/software/livejournal/ruby/doc/) for more details on the underlying stuff.


## Setup

Install the `livejournal` gem:

    sudo gem install livejournal
    
Then `require` this library.


## Usage

    lj = LiveJournal::Tasks.new('username', 'password')

    lj.entries     # Hash of the last 10 entries, with id keys and LiveJournal::Entry values.
    lj.entries(5)  # Hash of the last 5 entries.

    lj.entry(1)    # LiveJournal::Entry with that id.
    lj.url(1)      # LiveJournal URL for the entry with that id.

    lj.create(:subject => "Foo", :body => "Bar")  # Returns the entry id, an integer.
    lj.update(1, :body => "Baz")  # Update the entry with that id.
    lj.delete(1)   # Remove the entry with that id.

Properties for `create` and `update`:

    :subject       A string.
    :body          The post contents. Alias for :event. Passing nil or "" raises AccidentalDeleteError.
    :tags          An array of strings. Alias for :taglist.
    :time          A Time. LJ will use the time as-is, ignoring the time zone. Can be past or future. Defaults to now on create.
    :mood          A string. TODO: Is currently reset on update unless specified every time.
    :music         A string.
    :location      A string.
    :pickeyword    User picture keyword. A string.
    :security      One of: :public, :friends, :private, :custom (pass an :allowmask integer with :custom).
    :comments      One of: :normal, :none, :noemail
    :screening     One of: :default, :all, :anonymous, :nonfriends, :none
    :preformatted  Boolean. Tells LJ not to touch your HTML. Defaults to true if you update the body.


## Credits and license

By [Henrik Nyh](http://henrik.nyh.se/). Wraps [Evan Martin's livejournal gem](http://neugierig.org/software/livejournal/ruby/).

Under the MIT license:

>  Copyright (c) 2008 Henrik Nyh
>
>  Permission is hereby granted, free of charge, to any person obtaining a copy
>  of this software and associated documentation files (the "Software"), to deal
>  in the Software without restriction, including without limitation the rights
>  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
>  copies of the Software, and to permit persons to whom the Software is
>  furnished to do so, subject to the following conditions:
>
>  The above copyright notice and this permission notice shall be included in
>  all copies or substantial portions of the Software.
>
>  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
>  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
>  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
>  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
>  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
>  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
>  THE SOFTWARE.
