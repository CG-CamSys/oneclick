# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :fare do
    type ""
    unit "MyString"
    amount 1.5
    base_units "MyString"
    base_cost 1.5
    description "MyString"
    voluntary false
  end
end
