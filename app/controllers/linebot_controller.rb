require 'json'
require 'uri'
require 'net/http'

class LinebotController < ApplicationController
  def callback
    body = request.body.read
    events = client.parse_events_from(body)

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          uri = URI.parse('https://api.avgle.com/v1/videos/page=0?limit=100')
          json = Net::HTTP.get(uri)
          result = JSON.parse(json)
          result['response']['videos'].each do |v|
            if v['title'] == event.message['text'] || v['title'].include?(event.message['text']) || v['keyword'] == event.message['text'] || v['keyword'].include?(event.message['text'])
              title = {
                type: 'text',
                text: v['title']
              }
              video = {
                type: "video",
                originalContentUrl: v['preview_video_url'],
                previewImageUrl: v['preview_url']
              }
              client.reply_message(event['replyToken'], video)
            else
              failure = {
                type: 'text',
                text: '検索ワードにヒットする動画が見つかりませんでした。'
              }
              client.reply_message(event['replyToken'], failure)
            end
          end
        when Line::Bot::Event::MessageType::Image, Line::Bot::Event::MessageType::Video
          response = client.get_message_content(event.message['id'])
          tf = Tempfile.open("content")
          tf.write(response.body)
        end
      end
    }
    "OK"
  end
end

class Array
  def index_select(obj = nil)
    if obj.nil? && !block_given?
      self.each
    else
      proc = obj.nil? ? ->(i){ yield self[i] } : ->(i){ self[i] == obj }
      self.each_index.select(&proc)
    end
  end
end