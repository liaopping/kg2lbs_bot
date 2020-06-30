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
          if event.message['text'] == '本日の視聴数トップ5'
            uri = URI.parse('https://api.avgle.com/v1/videos/page=0?o=mv&t=t&limit=5')
            json = Net::HTTP.get(uri)
            result = JSON.parse(json)
            @videos = []
            result['response']['videos'].each do |v|
              video = {
                type: "video",
                originalContentUrl: v.dig('preview_video_url'),
                previewImageUrl: v.dig('preview_url')
              }
              @videos << video
            end
              client.reply_message(event['replyToken'], @videos)
          elsif event.message['カテゴリごとに探す']
            #
          elsif event.message['女優ごとに探す']
            #
          else
            uri = URI.parse('https://api.avgle.com/v1/videos/page=0?limit=5')
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
