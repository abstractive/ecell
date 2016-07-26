require 'ecell/elements/line'
require 'ecell/base/strokes'

class TestLine < ECell::Elements::Line
  def initialize(line_id, socket, options={})
    @socket = socket
    super(line_id, options)
  end
end

RSpec.describe ECell::Elements::Line do
  let(:instantiator) {ECell::Elements::Color::Instantiator[:test_piece]}
  let(:data) {[instantiator.msg(1), instantiator.msg(:two), instantiator.msg(3.0)]}

  it "can set up a binding socket and read messages" do
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

    recvd = []
    allow(socket).to receive(:read_multipart) {(n = data.shift) ? [n] : raise(Celluloid::TaskTerminated)}
    expect(socket).to receive(:bind).with("tcp://#{ECell::Constants::DEFAULT_INTERFACE}:7000")
    line.reader {|m| recvd << m}
    expect(line.state).to be :provisioned
    expect(recvd.map(&:msg)).to eq [1, :two, 3.0]

    expect(socket).to receive(:close)
    line.shutdown!
    expect(line.state).to be :offline

    allow(socket).to receive(:close)
    line.terminate
  end

  it "can set up a connecting socket and transmit messages" do
    socket = double(Celluloid::ZMQ::Socket::Req)

    expect(socket).to receive(:identity=).with(:test_piece)
    line = TestLine.new(:demo_connector, socket, mode: :connecting, piece_id: :test_piece)
    expect(line.state).to be :initialized

    addr = "tcp://#{ECell::Constants::DEFAULT_INTERFACE}:7000"
    expect(socket).to receive(:linger=).with(kind_of(Numeric))
    expect(socket).to receive(:connect).with(addr)
    line.connect = addr
    expect(line.state).to be :provisioned

    data.each do |datum|
      expect(socket).to receive(:<<).with(datum.dup.packed).ordered
    end
    data.each do |datum|
      line << datum
    end

    expect(socket).to receive(:close)
    line.shutdown!
    expect(line.state).to be :offline

    allow(socket).to receive(:close)
    line.terminate
  end

  it "successfully operates a pair of communicating endpoints" do
    endpoint = "inproc://test"
    opts = {piece_id: :test_piece, endpoint: endpoint}
    push = ECell::Base::Strokes::Logging::Push.new(opts.merge(mode: :binding, provision: true))
    pull = ECell::Base::Strokes::Logging::Pull.new(opts.merge(mode: :connecting))

    handler = double("Handler")
    data.each do |datum|
      expect(handler).to receive(:async) do |m, d|
        expect(m).to be :handle
        expect(d.msg).to eq datum.msg
      end.ordered
    end
    pull.async.emitter(handler, :handle)

    data.each do |datum|
      push << datum
      sleep 0.1
    end

    push.terminate
    pull.terminate
  end
end

