require 'spec_helper'
require 'optparse'

describe Liberate::App do

  let(:args) { OptionParser.new(['-h']) }
  subject { described_class.new(args) }

  describe '#new' do
    it 'initialized Liberate object' do
      allow(subject).to_receive(:create_options_parser).with(args)
    end
  end

end
