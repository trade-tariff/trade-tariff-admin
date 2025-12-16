RSpec.describe QuotaOrderNumbers::QuotaBalanceEvent do
  subject(:quota_balance_event) { build(:quota_balance_event) }

  let(:expected_attributes) do
    {
      id: quota_balance_event.id,
      new_balance: quota_balance_event.new_balance,
      imported_amount: quota_balance_event.imported_amount,
      last_import_date_in_allocation: quota_balance_event.last_import_date_in_allocation,
      old_balance: quota_balance_event.old_balance,
    }
  end

  it "implements the correct attributes" do
    expect(quota_balance_event).to have_attributes(expected_attributes)
  end
end
