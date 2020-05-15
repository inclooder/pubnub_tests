# frozen_string_literal: true

require 'bundler'
Bundler.setup
require 'dotenv/load'

require 'securerandom'
require 'logger'
require 'pubnub'

publish_key = ENV['PUBLISH_KEY']
subscribe_key = ENV['SUBSCRIBE_KEY']
uuid = SecureRandom.uuid
secret_key = ENV['SECRET_KEY']

client_options = {
  publish_key: publish_key,
  subscribe_key: subscribe_key,
  ssl: true,
  http_sync: true,
  logger: Logger.new(STDOUT)
}

puts "Connecting as #{uuid}"

client = Pubnub.new(
  **client_options,
  uuid: uuid,
  secret_key: secret_key,
  http_sync: true
)

puts "Connected!"

callback = Pubnub::SubscribeCallback.new(
    message: ->(envelope) {
        puts "MESSAGE: #{envelope.result[:data]}"
    },
    presence: ->(envelope) {
        puts "PRESENCE: #{envelope.result[:data]}"
    },
    signal: ->(envelope) {
        puts "SIGNAL: #{envelope.result[:data]}"
    },
    status: ->(envelope) {
        puts "STATUS: #{envelope.result[:data]}"
    }
)

client.add_listener(callback: callback)

channel_id = 'test123'

auth_key = SecureRandom.uuid

grant_options = {
  auth_key: auth_key,
  channels: [channel_id],
  manage: true,
  write: true,
  read: true,
}

puts "Granting access to #{channel_id} for key #{auth_key}"

envelope = client.grant(
  **grant_options,
  ttl: 0, # no ttl
  http_sync: true,
)


if envelope.error?
  puts "Error client.grant"
  exit 1
end

puts "Access granted!"

puts "Subscribing to channel #{channel_id}"

envelopes = client.subscribe(channels: channel_id, http_sync: true)

envelopes.each do |evnelope|
  if envelope.error?
    puts "Error client.subscribe"
    exit 1
  end
end

puts "Subscribed!"

loop do
  print "> "
  input = gets.chomp
  break if input == 'exit' || input == 'quit'

  envelope = client.publish(
    channel: channel_id,
    message: input,
    http_sync: true
  )
  resp = envelope.error? ? 'Err' : 'Ok'
  puts resp
end
