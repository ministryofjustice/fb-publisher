FactoryBot.define do
  factory :user do
    sequence :name do |n|
      "user#{n}"
    end

    sequence :email do |n|
      "user#{n}@example.com"
    end
  end
end
