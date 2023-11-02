require 'json'
require 'socket'

class MPVClient

  class Error < StandardError; end

  attr_accessor :socket

  def initialize(mpv_params={})
    @requests = {}
    @property_observers = {}
    @event_observers = {}
    @request_id = @property_observer_id = 0
    @socket_path = '/tmp/mpv_socket'
    @mpv_params = {
      'idle' => 'yes',
      'input-ipc-server' => @socket_path,
    }.merge(mpv_params).compact
    start
    register_event('property-change') do |event|
      observer = @property_observers[event['name']] \
        or raise Error, "Can't find property observer for event: #{event.inspect}"
      observer.call(event['name'], event['data'])
    end
  end

  def start
    cmd = ['mpv'] + @mpv_params.map { |k, v| "--#{k}" + (v.to_s.empty? ? '' : "=#{v}") }
# ;;pp(cmd: cmd)
    File.unlink(@socket_path) if File.exist?(@socket_path)
    @pid = Process.spawn(*cmd)
    raise Error, "mpv failed to start" unless @pid > 0
    until File.exist?(@socket_path)
# ;;puts "[sleeping until socket path exists]"
      sleep 0.1
      if Process.waitpid(@pid, Process::WNOHANG)
        raise Error, "mpv failed to start (exit status #{$?.exitstatus.inspect})"
      end
    end
    @socket = UNIXSocket.new(@socket_path)
  end

  def stop
    @socket.close
    @socket = nil
    Process.kill('INT', @pid)
# ;;puts "[waiting for mpv to exit: #{@pid}]"
    Process.waitpid(@pid)
# ;;puts "[mpv exited with status #{$?.exitstatus.inspect}]"
    @pid = nil
    File.unlink(@socket_path) if File.exist?(@socket_path)
  end

  def command(*args)
# ;;puts "COMMAND: #{args.inspect}"
    responded = false
    result = nil
    @requests[@request_id] = proc do |response|
      case response['error']
      when 'success'
        responded = true
        result = response['data']
      else
        raise Error, "Response error: #{response.inspect}"
      end
    end
    request = { 'command' => args, 'request_id' => @request_id }
# ;;puts "=> #{request.inspect}"
    @socket.puts(JSON.generate(request))
    @request_id += 1
    process_response until responded
    result
  end

  def process_response
    response = JSON.load(@socket.gets) or return
# ;;puts "<= #{response.inspect}"
    if (name = response['event'])
      if (observer = @event_observers[name])
        observer.call(response)
      end
    elsif (request_id = response['request_id'])
      handler = @requests.delete(request_id) \
        or raise Error, "No handler for response: #{response.inspect}"
      handler.call(response)
    else
      raise Error, "Unhandled response: #{response.inspect}"
    end
  end

  def unpack_version(packed)
    [packed >> 16, packed & 0x00FF]
  end

  def set_property(name, value)
    command('set_property', name, value)
  end

  def get_property(name)
    command('get_property', name)
  end

  def observe_property(name, &block)
    @property_observers[name] = block
    command('observe_property', @property_observer_id, name)
    @property_observer_id += 1
  end

  def register_event(name, &block)
    @event_observers[name] = block
  end

end