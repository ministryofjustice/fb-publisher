require 'rails_helper'

describe ApplicationJob do
  describe '#temp_dir' do
    context 'when no temp_dir exists' do
      before do
        subject.send(:instance_variable_set, "@temp_dir", nil)
        allow(Dir).to receive(:mktmpdir).and_return('/tmp/new/temp/dir')
      end

      it 'makes a new temp_dir' do
        expect(Dir).to receive(:mktmpdir).and_return('/tmp/new/temp/dir')
        subject.temp_dir
      end

      it 'returns the new temp dir' do
        expect(subject.temp_dir).to eq('/tmp/new/temp/dir')
      end

      it 'caches the value' do
        expect{subject.temp_dir}.to change{subject.send(:instance_variable_get, '@temp_dir')}.from(nil).to('/tmp/new/temp/dir')
      end
    end

    context 'when a temp_dir already exists' do
      before do
        subject.send(:instance_variable_set, "@temp_dir", 'foo')
      end

      it 'dows not make a new temp_dir' do
        expect(Dir).to_not receive(:mktmpdir)
        subject.temp_dir
      end

      it 'returns the existing value' do
        expect(subject.temp_dir).to eq('foo')
      end
    end
  end
end
