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

    context 'with a user generated slug' do
      describe 'with invalid slug' do
        context 'when the slug contains capital letters' do
          before do
            subject.slug = 'aCaptialLetter'
          end

          it 'adds an error on slug' do
            subject.valid?
            expect(subject.errors[:slug]).to_not be_empty
          end
        end

        context 'when the slug contains spaces' do
          before do
            subject.slug = 'apply for a license'
          end

          it 'adds an error on slug' do
            subject.valid?
            expect(subject.errors[:slug]).to_not be_empty
          end
        end

        context "when the slug contains a symbol '@'" do
          before do
            subject.slug = '99-problems@'
          end

          it 'adds an error on slug' do
            subject.valid?
            expect(subject.errors[:slug]).to_not be_empty
          end
        end

        context "when the slugs first character is '-'" do
          before do
            subject.slug = '-apply-for-a-license'
          end

          it 'adds an error on slug' do
            subject.valid?
            expect(subject.errors[:slug]).to_not be_empty
          end
        end

        context "when the slugs last character is'-'" do
          before do
            subject.slug = 'apply-for-a-license-'
          end

          it 'adds an error on slug' do
            subject.valid?
            expect(subject.errors[:slug]).to_not be_empty
          end
        end

        context "when the slug contains the character '_'" do
          before do
            subject.slug = '.apply_for_a_license'
          end

          it 'adds an error on slug' do
            subject.valid?
            expect(subject.errors[:slug]).to_not be_empty
          end
        end
      end

      describe 'with a valid slug' do
        context 'when the slug only contains lowercase letters and hypens' do
          before do
            subject.slug = 'apply-for-a-license-to-do-something'
          end

          it 'does not add an error on the slug' do
            subject.valid?
            expect(subject.errors[:slug]).to be_empty
          end
        end

        context "when the slug contains the character '.' " do
          before do
            subject.slug = 'example.com'
          end

          it 'does not add an error on the slug' do
            subject.valid?
            expect(subject.errors[:slug]).to be_empty
          end
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

    context 'with an empty token' do
      before do
        subject.token = nil
      end

      it 'generates a token' do
        expect{ subject.valid? }.to change(subject, :token)
        expect(subject.token).to_not be_blank
      end
    end
  end

  describe '#to_param' do
    subject { Service.new(slug: 'my-slug') }

    it 'returns the slug' do
      expect(subject.to_param).to eq(subject.slug)
    end
  end

  describe '.visible_to' do
    context 'given a user' do
      let(:user) { User.create!(name: 'test user', email: 'test@example.com') }
      let(:other_user) { User.create!(name: 'Other User', email: 'otheruser@example.com') }

      context 'who has created a Service' do
        let!(:service_created_by_user) { Service.create!(name: 'test users service', created_by_user: user, git_repo_url: 'https://some/repo') }

        context 'and a service created by someone else' do
          let!(:service_created_by_other_user) { Service.create!(name: 'other users service', created_by_user: other_user, git_repo_url: 'https://some/repo') }

          it 'includes the service created by the given user' do
            expect(Service.visible_to(user).pluck(:id)).to include(service_created_by_user.id)
          end

          it 'does not include the service created by the other user' do
            expect(Service.visible_to(user).pluck(:id)).to_not include(service_created_by_other_user.id)
          end
        end
      end

      context 'who is a member of a team' do
        let!(:team_with_user_as_member) { Team.create!(name: 'test users team', created_by_user: other_user) }
        before do
          team_with_user_as_member.members << TeamMember.new(user: user, created_by_user: other_user)
        end

        context 'and a Service created by another user' do
          let!(:service_with_permission_created_by_other_user) { Service.create!(name: 'other users service', created_by_user: other_user, git_repo_url: 'https://some/repo') }

          context 'without permission granted to the users team' do
            before do
              service_with_permission_created_by_other_user.permissions.delete_all
            end

            it 'does not include that service' do
              expect(Service.visible_to(user).pluck(:id)).to_not include(service_with_permission_created_by_other_user.id)
            end
          end

          context 'with permission granted to the users team' do
            before do
              service_with_permission_created_by_other_user.permissions.create!(team: team_with_user_as_member, created_by_user: other_user)
            end

            it 'includes the service with the given user as member' do
              expect(Service.visible_to(user).pluck(:id)).to include(service_with_permission_created_by_other_user.id)
            end
          end
        end
      end
    end
  end
end
