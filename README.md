**What is this?**

The Todoable gem is a client for accessing the [Teachable Todoable API](http://todoable.teachable.tech/)

<br/>

**How do I use it?**

on the command-line...
```bash
rake build
rake install
bundle install
bundle info todoable
rake console
```

in the console...
```ruby
# create a client
client = TodoableClient.new <username>, <password>
# get all lists
lists = TodoableList.all client: client
# get a list
list = TodoableList.by_id lists.first.id, client: client
# create a list
list = TodoableList.new name: '<uniquename>', client: client
# update a list
list.update 'new name'
# get items from a list
list.items
# add an item to a list
item = list.add_item itemname
# finish an item
item.finish
# delete an item
item.delete
# delete a list
list.delete
```

<br/>

**How do I test it?**

test will run RSpec and Rubocop

test_debug will display HTTP debug logging

on the command-line...
```bash
rake test
rake test_debug
```