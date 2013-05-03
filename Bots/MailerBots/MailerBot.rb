begin
  require 'uri'
  require 'net/http'
  require 'json'
  require 'rubygems'
  require 'tlsmail'
  require 'mail'
rescue LoadError => e
  puts "Missing dependency #{e.message}. Run a 'gem install' for the package"
  exit 1
end

class MailerBot
  def initialize(access_token, site_url, site_port, proxy_url, proxy_port)
    @access_token = access_token
    @site_url = site_url
    @site_port = site_port
    @proxy_url = proxy_url
    @proxy_port = proxy_port
  end

  def fetchReminders
    Net::HTTP.start(@site_url, @site_port, @proxy_url, @proxy_port) do |http|
      unixStart = Time.now
      unixEnd = Time.now + 432000 # 5 days in seconds
      request = Net::HTTP::Get.new('/api/v1/reminders?start=' + (unixStart.to_i.to_s) + '&end=' + (unixEnd.to_i.to_s))
      request['Authorization'] = @access_token

      response = http.request request # Net::HTTPResponse object

      if response.body == '{"Access Denied"}'
        puts "Don't forget to create a bot and set the access key!"
        exit 1
      end
      data = JSON.parse response.body

      puts "Got Reminders"
      data.each do |reminder|
        yield reminder
      end
    end
  end

  def fetchUserAndSendEmail(reminder)
    key_id = reminder['api_key_id']
    Net::HTTP.start(@site_url, @site_port, @proxy_url, @proxy_port) do |user_http|
      user_request = Net::HTTP::Get.new('/api/v1/users/key/' + key_id.to_s + '/')
      user_request['Authorization'] = @access_token

      user_response = user_http.request user_request

      user = JSON.parse user_response.body

      datetime_string = DateTime.strptime(reminder['start'], '%Y-%m-%dT%H:%M:%S%z').strftime('%B %e %Y, %l:%M %p')

      puts "Sending email"
      mail = Mail.new do
        from 'reminderemailer@gmail.com'
        to user['email']
        subject 'Reminder: ' + reminder['title'] + ' is coming up soon!'

        html_part do
          content_type 'text/html; charset=UTF-8'
          body %{
            <h3>#{reminder['title']} is coming up!</h3>
            <p>You scheduled a reminder for #{reminder['title']} at #{datetime_string}. Don't forget about it!</p>
            <div>
              #{reminder['customhtml']}
            </div>
          }
        end
      end
      Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
      Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', 'reminderemailer@gmail.com', 'reminderemailer23', :login) do |smtp|
        smtp.send_message(mail.to_s, 'reminderemailer@gmail.com', 'eric.d.brown23@gmail.com')
      end
    end
  end
end

site_url = 'localhost'
site_port = 3000
proxy_url = 'localhost'
proxy_port = 8888

ARGV.each do |arg|
  if /\Asite_url=(?<surl>[\w:\/.\-_]*)\z/ =~ arg
    site_url = surl
  elsif /\Asite_port=(?<sport>[\d:\/.\-_]*)\z/ =~ arg
    site_port = sport.to_i
  elsif /\Aproxy_url=(?<purl>[\w:\/.\-_]*)\z/ =~ arg
    proxy_url = purl
  elsif /\Aproxy_port=(?<pport>[\d:\/.\-_]*)\z/ =~ arg
    proxy_port = pport.to_i
  end
end

mailerBot = MailerBot.new('b819b563b60b5d7addd51fe2174260c6', site_url, site_port, proxy_url, proxy_port)
mailerBot.fetchReminders do |reminder|
  mailerBot.fetchUserAndSendEmail reminder
end