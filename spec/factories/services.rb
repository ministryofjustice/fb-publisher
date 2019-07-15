FactoryBot.define do
  factory :service do
    association :created_by_user, factory: :user

    name { 'ioj' }
    slug { 'service-slug' }
    git_repo_url { 'https://github.com/ministryofjustice/fb-ioj.git' }
  end
end
