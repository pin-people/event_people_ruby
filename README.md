# EventPeople

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/pin-people/event_people_ruby/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/pin-people/event_people_ruby/tree/main)

EventPeople is a tool to simplify the communication of services based on events. It is an extension of the [EventBus](https://github.com/pin-people/event_bus_rb) gem.

The main idea is to provide a tool that can emit or consume events based on its names, the event name has 4 words (`resource.origin.action.destiny`) which defines some important info about what kind of event it is, where it comes from and who is eligible to consume it:

- **resource:** Defines which resource this event is related like a `user`, a `product`, `company` or anything that you want;
- **origin:** Defines the name of the system which emitted the event;
- **action:** What action is made on the resource like `create`, `delete`, `update`, etc. PS: *It is recommended to use the Semple Present tense for actions*;
- **destiny (Optional):** This word is optional and if not provided EventPeople will add a `.all` to the end of the event name. It defines which service should consume the event being emitted, so if it is defined and there is a service whith the given name only this service will receive it. It is very helpful when you need to re-emit some events. Also if it is `.all` all services will receive it.

As of today EventPeople uses RabbitMQ as its datasource, but there are plans to add support for other Brokers in the future.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'event_people'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install event_people

And set env vars:
```ruby
ENV['RABBIT_URL'] = 'amqp://guest:guest@localhost:5672'
ENV['RABBIT_EVENT_PEOPLE_APP_NAME'] = 'service_name'
ENV['RABBIT_EVENT_PEOPLE_VHOST'] = 'event_people'
ENV['RABBIT_EVENT_PEOPLE_TOPIC_NAME'] = 'event_people'
````

## Usage

### Events

The main component of `EventPeople` is the `EventPeople::Event` class which wraps all the logic of an event and whenever you receive or want to send an event you will use it.

It has 2 attributes `name` and `payload`:

- **name:** The name must follow our conventions, being it 3 (`resource.origin.action`) or 4 words (`resource.origin.action.destiny`);
- **payload:** It is the body of the massage, it should be a Hash object for simplicity and flexibility.

```ruby
require 'event_people'

event_name = 'user.users.create'
body = { id: 42, name: 'John Doe', age: 35 }
event = EventPeople::Event.new(event_name, body)
```

There are 3 main interfaces to use `EventPeople` on your project:

- Calling `EventPeople::Emitter.trigger(event)` inside your project;
- Calling `EventPeople::Listener.on(event_name)` inside your project;
- Or extending `EventPeople::Listeners::Base` and use it as a daemon.

### Using the Emitter
You can emit events on your project passing an `EventPeople::Event` instance to the `EventPeople::Emitter.trigger` method. Doing this other services that are subscribed to these events will receive it.

```ruby
require 'event_people'

event_name = 'receipt.payments.pay.users'
body = { amount: 350.76 }
event = EventPeople::Event.new(event_name, body)

EventPeople::Emitter.trigger(event)

# Don't forget to close the connection!!!
EventPeople::Config.broker.close_connection
```
[See more details](https://github.com/pin-people/event_people_ruby/blob/master/examples/emitter.rb)

### Listeners

You can subscribe to events based on patterns for the event names you want to consume or you can use the full name of the event to consume single events.

We follow the RabbitMQ pattern matching model, so given each word of the event name is separated by a dot (`.`), you can use the following symbols:

- `* (star):` to match exactly one word. Example `resource.*.*.all`;
- `# (hash):` to match zero or more words. Example `resource.#.all`.

Other important aspect of event consumming is the result of the processing we provide 3 methods so you can inform the Broker what to do with the event next:

- `success!:` should be called when the event was processed successfuly and the can be discarded;
- `fail!:` should be called when an error ocurred processing the event and the message should be requeued;
- `reject!:` should be called whenever a message should be discarded without being processed.

Given you want to consume a single event inside your project you can use the `EventPeople::Listener.on` method. It consumes a single event, given there are events available to be consumed with the given name pattern.

```ruby
require 'event_people'

# 3 words event names will be replaced by its 4 word wildcard
# counterpart: 'payment.payments.pay.all'
event_name = 'payment.payments.pay'

EventPeople::Listener.on(event_name) do |event, _delivery_info|
  puts ""
  puts "  - Received the "#{event.name}" message from #{event.origin}:"
  puts "     Message: #{event.body}"
  puts ""
  success!
end

EventPeople::Config.broker.close_connection
```

You can also receive all available messages using a loop:

```ruby
require 'event_people'

event_name = 'payment.payments.pay.all'
has_events = true

while has_events do
  has_events = false

  EventPeople::Listener.on(event_name) do |event, _delivery_info|
    has_events = true
    puts ""
    puts "  - Received the "#{event.name}" message from #{event.origin}:"
    puts "     Message: #{event.body}"
    puts ""
    success!
  end
end

EventPeople::Config.broker.close_connection
```
[See more details](https://github.com/pin-people/event_people_ruby/blob/master/examples/listener.rb)

#### Multiple events routing

If your project needs to handle lots of events you can extend `EventPeople::Listeners::Base` class to bind how many events you need to instance methods, so whenever an event is received the method will be called automatically.

```ruby
require 'event_people'

class CustomEventListener < EventPeople::Listeners::Base
  bind :pay, 'resource.custom.pay'
  bind :receive, 'resource.custom.receive'
  bind :private_channel, 'resource.custom.private.service'

  def pay(event)
    puts "Paid #{event.body['amount']} for #{event.body['name']} ~> #{event.name}"

    success!
  end

  def receive(event)
    if event.body['amount'] > 500
      puts "Received #{event.body['amount']} from #{event.body['name']} ~> #{event.name}"
    else
      puts '[consumer] Got SKIPPED message'
      return reject!
    end

    success!
  end

  def private_channel(event)
    puts "[consumer] Got a private message: \"#{event.body['message']}\" ~> #{event.name}"

    success!
  end
end
```
[See more details](https://github.com/pin-people/event_people_ruby/blob/master/examples/daemon.rb)

#### Creating a Daemon

If you have the need to create a deamon to consume messages on background you can use the `EventPeople::Daemon.start` to do so with ease. Just remember to define or import all the event bindings before starting the daemon.

```ruby
require 'event_people'

class CustomEventListener < EventPeople::Listeners::Base
  bind :pay, 'resource.custom.pay'
  bind :receive, 'resource.custom.receive'
  bind :private_channel, 'resource.custom.private.service'

  def pay(event)
    puts "Paid #{event.body['amount']} for #{event.body['name']} ~> #{event.name}"

    success!
  end

  def receive(event)
    if event.body['amount'] > 500
      puts "Received #{event.body['amount']} from #{event.body['name']} ~> #{event.name}"
    else
      puts '[consumer] Got SKIPPED message'

      return reject!
    end

    success!
  end

  def private_channel(event)
    puts "[consumer] Got a private message: \"#{event.body['message']}\" ~> #{event.name}"

    success!
  end
end

puts '****************** Daemon Ready ******************'

EventPeople::Daemon.start
```
[See more details](https://github.com/EmpregoLigado/event_people/blob/master/examples/daemon.rb)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

- Fork it
- Create your feature branch (`git checkout -b my-new-feature`)
- Commit your changes (`git commit -am 'Add some feature'`)
- Push to the branch (`git push origin my-new-feature`)
- Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
