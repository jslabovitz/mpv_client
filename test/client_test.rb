$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'mpv_client'

require 'minitest/autorun'
require 'minitest/power_assert'

class MPVClient

  class ClientTest < Minitest::Test

    # i_suck_and_my_tests_are_order_dependent!

    def setup
# ;;puts
      @mpv = MPVClient.new
      @logs = []
      @mpv.register_event('log-message') do |event|
# ;;puts "** #{event.inspect}"
        @logs << event
      end
      @mpv.command('request_log_messages', 'status')
    end

    def shutdown
      @mpv.command('quit')
      @mpv.stop
    end

    def test_version
      version = @mpv.command('get_version')
      assert { version != nil }
      version = @mpv.unpack_version(version)
      assert { version == [1, 101] }
    end

    def test_client_name
      client_name = @mpv.command('client_name')
      assert { client_name == 'ipc_0' }
    end

    def test_time_us
      time = @mpv.command('get_time_us')
      assert { time.kind_of?(Numeric) }
      assert { time > 0 }
    end

    def test_good_command
      assert {
        @mpv.command('stop')
        true
      }
    end

    def test_bad_command
      assert_raises(MPVClient::Error) {
        @mpv.command('xyzzy')
      }
    end

    def test_set_get_property
      expected_value = 50.0
      @mpv.set_property('volume', expected_value)
      actual_value = @mpv.get_property('volume')
      assert {
        actual_value == expected_value
      }
    end

    def test_observe_property
      expected_value = 50.0
      actual_value = nil
      stop = false
      @mpv.observe_property('volume') do |name, value|
        actual_value = value
        stop = true
      end
      @mpv.set_property('volume', expected_value)
      until stop
        @mpv.process_response
      end
      assert {
        actual_value == expected_value
      }
    end

    def test_process_events
      volume = nil
      @mpv.observe_property('volume') do |name, value|
        volume = value
      end
      first = true
      until volume == 50.0
        if (IO.select([@mpv.socket], [], [], 1))
          @mpv.process_response
        else
          if first
            @mpv.set_property('volume', 50.0)
            first = false
          end
        end
      end
    end

  end

end