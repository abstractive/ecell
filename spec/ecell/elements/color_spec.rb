require 'ecell/elements/color'

RSpec.describe ECell::Elements::Color do
  let(:data) {ECell::Elements::Color::Instantiator.thing(:foo, {type: :metasyntactic_variable})}

  it "has basic accessor methods" do
    expect(data.form).to be :thing
    expect(data.thing?(:foo)).to be true
    expect(data.thing).to be :foo
    expect(data.type).to be :metasyntactic_variable
    expect(data.asdf?).to be false
    expect(data.asdf).to be_nil
  end

  it "can be packed and unpacked" do
    packed_data = data.packed
    expect(data).to be_packed
    expect {data.type}.to raise_error("Color entity is corrupted.") #benzrf TODO: change this maybe?
    expect(packed_data).to be_a(String)
    unpacked_data = ECell::Elements::Color[packed_data]
    expect(unpacked_data).to be_a(ECell::Elements::Color)
    expect(unpacked_data).to_not be_packed
    expect(unpacked_data.form).to be :thing
    expect(unpacked_data.type).to be :metasyntactic_variable
  end

  describe ECell::Elements::Color::ReturnInstantiator do
    let(:call) {ECell::Elements::Color::Instantiator.call(:bar, to: :some_piece, async: false, args: [1, "hello"])}

    it "can create return objects" do
      received = ECell::Elements::Color[call.packed]
      answer = ECell::Elements::Color::ReturnInstantiator.answer(received, :ok, returns: [2, "goodbye"])
      expect(answer).to be received #benzrf TODO: seems wrong
      expect(answer.form).to be :answer
      expect(answer.returns).to eq([2, "goodbye"])
      expect(answer.to).not_to be :some_piece
    end
  end
end

