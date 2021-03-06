require 'benchmark/ips'
require 'active_model'

require 'dry-validation'

I18n.locale = :en
I18n.backend.load_translations

class User
  include ActiveModel::Validations

  attr_reader :email, :age

  validates :email, :age, presence: true
  validates :age, numericality: { greater_than: 18 }

  def initialize(attrs)
    @email, @age = attrs.values_at('email', 'age')
  end
end

schema = Dry::Validation.Schema do
  configure do
    config.messages = :i18n
  end

  required(:email).filled
  required(:age).filled(:int?, gt?: 18)
end

form = Dry::Validation.Params do
  configure do
    config.messages = :i18n
    config.type_specs = true
  end

  required(:email, :string).filled
  required(:age, :integer).filled(:int?, gt?: 18)
end

params = { 'email' => '', 'age' => '18' }
coerced = { email: nil, age: 18 }

puts schema.(coerced).inspect
puts form.(params).inspect
puts User.new(params).validate

Benchmark.ips do |x|
  x.report('ActiveModel::Validations') do
    user = User.new(params)
    user.validate
    user.errors
  end

  x.report('dry-validation / schema') do
    schema.(coerced).messages
  end

  x.report('dry-validation / form') do
    form.(params).messages
  end

  x.compare!
end
