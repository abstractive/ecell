require 'ecell/elements/line'

class TestLine < ECell::Elements::Line
  def initialize(line_id, socket, options={})
    @socket = socket
    super(line_id, options)
  end
end

RSpec.describe ECell::Elements::Line do
  it "can set up a binding socket" do
    # restoring `configuration` to normal causes an error on Rubinius (as of 3.49)
    # run the tests on JRuby to avoid this
    allow(ECell::Run).to receive(:configuration) {{
      bindings: {
        test_piece: {
          interface: ECell::Constants::DEFAULT_INTERFACE,
          demo_binder: 7000
        }
      }
    }}
    socket = double(Celluloid::ZMQ::Socket::Rep)

    expect(socket).to receive(:linger=).with(kind_of(Numeric))
    expect(socket).to receive(:identity=).with(:test_piece)
    line = TestLine.new(:demo_binder, socket, mode: :binding, piece_id: :test_piece)
    expect(line.state).to be :initialized

    expect(socket).to receive(:bind).with("tcp://#{ECell::Constants::DEFAULT_INTERFACE}:7000")
    line.provision!
    expect(line.state).to be :provisioned

    expect(socket).to receive(:close)
    line.shutdown!
    expect(line.state).to be :offline

    allow(socket).to receive(:close)
    line.terminate
  end

  it "can set up a connecting socket" do
    socket = double(Celluloid::ZMQ::Socket::Req)

    expect(socket).to receive(:identity=).with(:test_piece)
    line = TestLine.new(:demo_connector, socket, mode: :connecting, piece_id: :test_piece)
    expect(line.state).to be :initialized

    addr = "tcp://#{ECell::Constants::DEFAULT_INTERFACE}:7000"
    expect(socket).to receive(:linger=).with(kind_of(Numeric))
    expect(socket).to receive(:connect).with(addr)
    line.connect = addr
    expect(line.state).to be :provisioned

    expect(socket).to receive(:close)
    line.shutdown!
    expect(line.state).to be :offline

    allow(socket).to receive(:close)
    line.terminate
  end
end

