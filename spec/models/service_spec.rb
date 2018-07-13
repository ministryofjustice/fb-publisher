require 'rails_helper'

describe Service do
  describe 'to_slug' do
    context 'given a string' do
      context 'containing upper-case characters' do
        it 'converts them to lower-case' do
          expect(subject.send(:to_slug, 'Apply for something')).to start_with('a')
        end
      end
      context 'containing punctuation' do
        it 'replaces them with -' do
          expect(subject.send(:to_slug, 'Apply, or continue an application for something')).to start_with('apply-')
        end
      end
      context 'containing unicode characters' do
        it 'leaves them in as-is' do
          expect(subject.send(:to_slug, 'Apply for something in 北京')).to end_with('北京')
        end
      end
      context 'containing spaces' do
        it 'replaces them with -' do
          expect(subject.send(:to_slug, 'Apply for something')).to eq('apply-for-something')
        end
      end
      context 'containing sequences of several replaceable characters' do
        it 'replaces each sequence with a single -' do
          expect(subject.send(:to_slug, "Apply, or continue applying(!) for something")).to start_with('apply-or-continue-applying-for-something')
        end

        context 'at the end' do
          it 'strips them entirely' do
            expect(subject.send(:to_slug, 'Apply for something(!)')).to eq('apply-for-something')
          end
        end
        context 'at the start' do
          it 'strips them entirely' do
            expect(subject.send(:to_slug, '(*)Apply for something')).to eq('apply-for-something')
          end
        end
      end
    end
  end
  describe 'validation' do
    before do
      subject.name = "Apply for a license to do something"
    end

    context 'with an empty slug' do
      before do
        subject.slug = ""
      end
      it 'populates slug' do
        expect{ subject.valid? }.to change(subject, :slug).from("")
      end
      describe 'the resulting slug' do
        before do
          subject.valid?
        end
        let(:slug) { subject.slug }

        it 'equals to_slug(name)' do
          expect(slug).to eq(subject.send(:to_slug, subject.name))
        end
      end
    end

    context 'with a git_repo_url' do
      before do
        subject.git_repo_url = git_repo_url
      end

      context 'that is empty' do
        let(:git_repo_url) { nil }

        it 'adds an error on git_repo_url' do
          subject.valid?
          expect(subject.errors[:git_repo_url]).to_not be_empty
        end
      end

      context 'that is too short' do
        let(:git_repo_url) { 'a' }

        it 'adds an error on git_repo_url' do
          subject.valid?
          expect(subject.errors[:git_repo_url]).to_not be_empty
        end
      end

      context 'that is not a parsable URI' do
        let(:git_repo_url) { 'this is not a uri' }

        it 'adds an error on git_repo_url' do
          subject.valid?
          expect(subject.errors[:git_repo_url]).to_not be_empty
        end
      end

      context 'that is just a file path' do
        let(:git_repo_url) { '/my/file/path' }

        it 'adds an error on git_repo_url' do
          subject.valid?
          expect(subject.errors[:git_repo_url]).to_not be_empty
        end
      end

      context 'that is a valid file: uri' do
        let(:git_repo_url) { 'file:/my/file/path' }

        it 'does not add an error on git_repo_url' do
          subject.valid?
          expect(subject.errors[:git_repo_url]).to be_empty
        end
      end

      context 'that is a valid git: uri' do
        let(:git_repo_url) { 'git@github.com:ministryofjustice/fb-sample-json.git' }

        it 'adds an error on git_repo_url' do
          subject.valid?
          expect(subject.errors[:git_repo_url]).to_not be_empty
        end
      end

      context 'that is a valid https: uri' do
        let(:git_repo_url) { 'https://my/https/repo.git' }

        it 'does not add an error on git_repo_url' do
          subject.valid?
          expect(subject.errors[:git_repo_url]).to be_empty
        end
      end
    end
  end

  describe '#to_param' do
    subject { Service.new(slug: 'my-slug') }

    it 'returns the slug' do
      expect(subject.to_param).to eq(subject.slug)
    end
  end
end
