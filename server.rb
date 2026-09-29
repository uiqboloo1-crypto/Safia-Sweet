require 'socket'
require 'uri'

PORT = 3000
WEB_ROOT = File.expand_path(File.dirname(__FILE__))

MIME_TYPES = {
  '.html' => 'text/html; charset=utf-8',
  '.htm'  => 'text/html; charset=utf-8',
  '.css'  => 'text/css; charset=utf-8',
  '.js'   => 'application/javascript; charset=utf-8',
  '.mjs'  => 'application/javascript; charset=utf-8',
  '.json' => 'application/json; charset=utf-8',
  '.png'  => 'image/png',
  '.jpg'  => 'image/jpeg',
  '.jpeg' => 'image/jpeg',
  '.gif'  => 'image/gif',
  '.svg'  => 'image/svg+xml',
  '.ico'  => 'image/x-icon',
  '.woff' => 'font/woff',
  '.woff2'=> 'font/woff2',
  '.ttf'  => 'font/ttf'
}

server = TCPServer.new('0.0.0.0', PORT)
puts "Safia Sweets Server running on http://127.0.0.1:#{PORT} and network http://0.0.0.0:#{PORT}"
$stdout.flush

loop do
  Thread.start(server.accept) do |client|
    begin
      request_line = client.gets
      next unless request_line

      method, full_path, _ = request_line.split(' ')
      path = URI.parse(full_path).path
      path = '/index.html' if path == '/' || path.empty?

      # Sanitize path to prevent directory traversal
      clean_path = File.expand_path(File.join(WEB_ROOT, path))
      
      if clean_path.start_with?(WEB_ROOT) && File.file?(clean_path)
        ext = File.extname(clean_path).downcase
        content_type = MIME_TYPES[ext] || 'application/octet-stream'
        content = File.binread(clean_path)

        client.print "HTTP/1.1 200 OK\r\n"
        client.print "Content-Type: #{content_type}\r\n"
        client.print "Content-Length: #{content.bytesize}\r\n"
        client.print "Access-Control-Allow-Origin: *\r\n"
        client.print "Connection: close\r\n"
        client.print "\r\n"
        client.print content
      else
        body = "404 Not Found"
        client.print "HTTP/1.1 404 Not Found\r\n"
        client.print "Content-Type: text/plain\r\n"
        client.print "Content-Length: #{body.bytesize}\r\n"
        client.print "Connection: close\r\n"
        client.print "\r\n"
        client.print body
      end
    rescue => e
      STDERR.puts "Error handling request: #{e.message}"
    ensure
      client.close rescue nil
    end
  end
end
