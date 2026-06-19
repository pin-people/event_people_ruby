# EventPeople

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/pin-people/event_people_ruby/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/pin-people/event_people_ruby/tree/main)

EventPeople is a tool to simplify the communication of services based on events. It is an extension of the [EventBus](https://github.com/EmpregoLigado/event_bus_rb) gem.

The main idea is to provide a tool that can emit or consume events based on its names, the event name has 4 words (`resource.origin.action.destination`) which defines some important info about what kind of event it is, where it comes from and who is eligible to consume it:

- **resource:** Defines which resource this event is related like a `user`, a `product`, `company` or anything that you want;
- **origin:** Defines the name of the system which emitted the event;
- **action:** What action is made on the resource like `create`, `delete`, `update`, etc. PS: *It is recommended to use the Simple Present tense for actions*;
- **destination (Optional):** This word is optional and if not provided EventPeople will add a `.all` to the end of the event name. It defines which service should consume the event being emitted, so if it is defined and there is a service whith the given name only this service will receive it. It is very helpful when you need to re-emit some events. Also if it is `.all` all services will receive it.

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

- **name:** The name must follow our conventions, being it 3 (`resource.origin.action`) or 4 words (`resource.origin.action.destination`);
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

- `success:` should be called when the event was processed successfuly and can be discarded;
- `fail:` should be called when an error ocurred processing the event and the message should be retried or dead-lettered;
- `reject:` should be called whenever a message should be discarded without being processed (routes directly to DLQ).

Given you want to consume a single event inside your project you can use the `EventPeople::Listener.on` method. It consumes a single event, given there are events available to be consumed with the given name pattern.

```ruby
require 'event_people'

# 3 words event names will be replaced by its 4 word wildcard
# counterpart: 'payment.payments.pay.all'
event_name = 'payment.payments.pay'

EventPeople::Listener.on(event_name) do |event, context|
  puts ""
  puts "  - Received the "#{event.name}" message from #{event.origin}:"
  puts "     Message: #{event.body}"
  puts ""
  context.success
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

  EventPeople::Listener.on(event_name) do |event, context|
    has_events = true
    puts ""
    puts "  - Received the "#{event.name}" message from #{event.origin}:"
    puts "     Message: #{event.body}"
    puts ""
    context.success
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

    success
  end

  def receive(event)
    if event.body['amount'] > 500
      puts "Received #{event.body['amount']} from #{event.body['name']} ~> #{event.name}"
    else
      puts '[consumer] Got SKIPPED message'
      return reject
    end

    success
  end

  def private_channel(event)
    puts "[consumer] Got a private message: \"#{event.body['message']}\" ~> #{event.name}"

    success
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
[See more details](https://github.com/pin-people/event_people_ruby/blob/master/examples/daemon.rb)

## Retry and Dead Letter Queue (DLQ)

### Configuration

Retry behaviour is configured in code, not via environment variables (since v1.2.0):

```ruby
# Optional: set global retry defaults (call once at boot time)
EventPeople::Config.configure(
  max_attempts:   5,          # default: 3
  initial_delay:  500,        # default: 1000 ms
  delay_strategy: 'fixed',   # default: 'exponential'
  dlq_name:       'my_dlq'   # default: '{app_name}_dlq'
)
```

Connection attributes (`RABBIT_URL`, `RABBIT_EVENT_PEOPLE_APP_NAME`, etc.) are still read from environment variables.

### Per-listener override

Retry settings can also be declared directly on a listener class, which overrides the global Config defaults for that listener:

```ruby
class OrderListener < EventPeople::Listeners::Base
  self.max_attempts   = 5
  self.initial_delay  = 500
  self.delay_strategy = 'fixed'
  self.dlq_name       = 'orders_dlq'

  bind :handle_created, 'order.service.created'

  def handle_created(event)
    # ...
  end
end
```

### How it works

On `context.fail`:
- If retries remain → message published to `{queue}_retry` with exponential backoff delay, then acked
- If retries exhausted → message published to the `{app_name}_dlq` queue (application-level), then acked
- If publish to retry queue fails → nacked without requeue (never requeued, to avoid infinite loops)

On `context.reject` → message published to the `{app_name}_dlq` queue (application-level), then acked

Dead-lettering is handled **at the application level**: the library publishes failed messages directly to a plain `{app_name}_dlq` queue via the default exchange, rather than relying on a broker dead-letter-exchange. If the DLQ publish fails (or no DLQ is configured) the message is nacked without requeue.

**Delay strategies:**
- `exponential` (default): `min(initialDelay × 5^retry_count, 600000)` ms
- `fixed`: constant `initialDelay` ms

### Queue topology (auto-created on subscribe)

| Queue/Exchange | Name | Purpose |
|---|---|---|
| Main queue | `{app_name}-{routing_key}.all` | Declared **argument-free** (no dead-letter-exchange) |
| DLQ | `{app_name}_dlq` | Plain durable queue; the library publishes failed messages to it directly |
| Retry queue | `{queue_name}_retry` | Holds messages until backoff delay expires |

> No `{app_name}_dlx` fanout exchange is declared anymore — dead-lettering is application-level.

### Migrating from the broker-DLX version (≤ v1.2.0)

Upgrading from the previous broker-DLX implementation (where the main queue was declared **with**
`x-dead-letter-exchange: {app_name}_dlx`) is **not drop-in**. RabbitMQ queue arguments are immutable,
so the first argument-free redeclare against an existing main queue fails with `PRECONDITION_FAILED`.

Operators must **delete the old main queue once** (per environment) so the library can recreate it
argument-free on the next subscribe. The `{app_name}_dlx` fanout exchange left over from the old
topology is harmless and can be deleted at leisure.

### Usage

```ruby
class OrderListener < EventPeople::Listeners::Base
  bind :handle_created, 'order.service.created'

  def handle_created(event)
    puts "Attempt #{event.retry_count + 1} of #{context.max_retries}"

    if invalid?(event)
      reject  # → DLQ immediately, no retries
      return
    end

    process(event)
    success
  rescue StandardError
    puts 'Final attempt, sending to DLQ' if context.is_last_retry
    fail  # → retry queue (or DLQ if exhausted)
  end
end
```

> **Note:** `success!`, `fail!`, `reject!` still work but are deprecated — prefer `success`, `fail`, `reject`.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

- Fork it
- Create your feature branch (`git checkout -b my-new-feature`)
- Commit your changes (`git commit -am 'Add some feature'`)
- Push to the branch (`git push origin my-new-feature`)
- Create new Pull Request

## License

The gem is available as open source under the terms of the [LGPL 3.0 License](https://www.gnu.org/licenses/lgpl-3.0.en.html).
