require File.expand_path('../helper', __FILE__)

class ErnicornTest < Test::Unit::TestCase
  module TestExposingModule
    def foo
    end

    def bar(a, b, c=nil)
      [a, b, c]
    end

  protected
    def baz
    end

  private
    def bling
    end
  end

  context "expose" do
    setup { Ernicorn.expose :expo, TestExposingModule }
    teardown { Ernicorn.mods.clear }

    should "add all public methods from the module" do
      assert_not_nil Ernicorn.mods[:expo].funs[:foo]
      assert_not_nil Ernicorn.mods[:expo].funs[:bar]
    end

    should "not expose protected methods" do
      assert_nil Ernicorn.mods[:expo].funs[:baz]
    end

    should "not expose private methods" do
      assert_nil Ernicorn.mods[:expo].funs[:bling]
    end

    should "dispatch to module methods properly" do
      res = Ernicorn.dispatch(:expo, :bar, ['a', :b, { :fiz => 42 }])
      assert_equal ['a', :b, { :fiz => 42 }], res
    end
  end

  module TestLoggingModule
    def self.logs() @logs ||= [] end

    def self.dispatched(*args)
      logs << args
    end

    def sleepy(time)
      sleep(time)
      time
    end
  end

  context "logging" do
    setup { Ernicorn.expose :logging, TestLoggingModule; TestLoggingModule.logs.clear  }
    teardown { Ernicorn.mods.clear }

    should "call logger method with timing" do
      ret = Ernicorn.dispatch(:logging, :sleepy, 0.1)
      assert_equal 0.1, ret

      assert_equal 1, TestLoggingModule.logs.size
      assert_in_delta 0.1, TestLoggingModule.logs.first[0], 0.05
    end
  end
end
