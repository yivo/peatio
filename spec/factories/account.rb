module AccountFactory
  def create_account(*arguments)
    currency   = Hash === arguments.first ? :usd : arguments.first
    attributes = arguments.extract_options!
    attributes.delete(:member) { create(:member) }.ac(currency).tap do |account|
      account.update!(attributes)
    end
  end
end

RSpec.configure { |config| config.include AccountFactory }
