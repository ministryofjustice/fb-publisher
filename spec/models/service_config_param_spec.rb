require 'rails_helper'

describe ServiceConfigParam do
  describe 'validation' do
    let(:name){ 'VALID_NAME' }
    let(:environment_slug){ 'dev' }
    let(:service){ Service.new }
    let(:user){ User.new }
    before do
      subject.service = service
      subject.name = name
      subject.environment_slug = environment_slug
      subject.last_updated_by_user = user
    end

    describe 'an environment_slug' do
      context 'in the list of ServiceEnvironment.all_slugs' do
        let(:environment_slug){ 'staging' }
        it 'is valid' do
          expect(subject.valid?).to eq(true)
        end
      end
      context 'not in the list of ServiceEnvironment.all_slugs' do
        let(:environment_slug){ 'made_up_slug' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
      context 'that is blank' do
        let(:environment_slug){ '' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
    end
    describe 'a name' do
      context 'of less than 3 characters' do
        let(:name){ 'AB' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
      context 'of more than 64 characters' do
        let(:name){ '0123456789ABCDEFG0123456789ABCDEFG0123456789ABCDEFG0123456789ABCDEFG0' }
        it 'is invalid' do
          expect(subject.valid?).to eq(false)
        end
      end
      context 'of 3-64 characters' do
        context 'containing lowercase letters' do
          let(:name){ 'lowercase_letters' }
          it 'is invalid' do
            expect(subject.valid?).to eq(false)
          end
        end
        context 'containing unicode letters' do
          let(:name){ 'CÉDILLE' }
          it 'is invalid' do
            expect(subject.valid?).to eq(false)
          end
        end
        context 'containing spaces' do
          let(:name){ 'THIS IS MY NAME' }
          it 'is invalid' do
            expect(subject.valid?).to eq(false)
          end
        end
        context 'containing only uppercase letters numbers and _' do
          let(:name){ 'THIS_NAME_IS_VALID_1234' }
          it 'is valid' do
            expect(subject.valid?).to eq(true)
          end
        end
      end
    end
  end

  describe '#key_value_pairs' do
    
  end
end
