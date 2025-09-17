RSpec.shared_context "with UK service" do
  around do |example|
    original = TradeTariffAdmin::ServiceChooser.service_choice
    TradeTariffAdmin::ServiceChooser.service_choice = "uk"
    example.run
    TradeTariffAdmin::ServiceChooser.service_choice = original
  end
end

RSpec.shared_context "with XI service" do
  around do |example|
    original = TradeTariffAdmin::ServiceChooser.service_choice
    TradeTariffAdmin::ServiceChooser.service_choice = "xi"
    example.run
    TradeTariffAdmin::ServiceChooser.service_choice = original
  end
end

RSpec.shared_context "with default service" do
  around do |example|
    original = TradeTariffAdmin::ServiceChooser.service_choice
    TradeTariffAdmin::ServiceChooser.service_choice = nil
    example.run
    TradeTariffAdmin::ServiceChooser.service_choice = original
  end
end
