RSpec.describe DistributionListService do
  include DistributionListLockHelper

  subject(:service) { described_class.new(client:, user_pool_id: "eu-west-2_pool", actor:, lock_timeout: 0.3) }

  let(:actor) { create(:user, :technical_operator, uid: "operator-1", name: "Olivia Operator") }

  let(:client) { Aws::CognitoIdentityProvider::Client.new(stub_responses: true, region: "eu-west-2") }
  let(:sub) { "11111111-2222-3333-4444-555555555555" }
  let(:email) { "jane@example.com" }

  def cognito_user(username:, email:, status: "CONFIRMED")
    {
      username:,
      user_status: status,
      enabled: true,
      attributes: [{ name: "email", value: email }, { name: "sub", value: username }],
    }
  end

  def requests_for(operation)
    client.api_requests.select { |request| request[:operation_name] == operation }
  end

  # What the SDK raises for a read timeout once its retries are used up.
  def read_timeout = Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new)

  describe ".valid_group_name?" do
    it "accepts dl- prefixed names" do
      expect(described_class.valid_group_name?("dl-tariff-notifications")).to be(true)
    end

    %w[admin myott portal dl- DL-X dl-foo/../admin dl_foo foo-dl-bar].each do |name|
      it "rejects #{name.inspect}" do
        expect(described_class.valid_group_name?(name)).to be(false)
      end
    end
  end

  describe "#groups" do
    before do
      client.stub_responses(:list_groups, [
        { groups: [{ group_name: "admin" }, { group_name: "dl-b", description: "B" }], next_token: "page-2" },
        { groups: [{ group_name: "myott" }, { group_name: "portal" }, { group_name: "dl-a", description: "A" }] },
      ])
    end

    it "returns only dl- groups across all pages, sorted by name" do
      expect(service.groups.map(&:name)).to eq(%w[dl-a dl-b])
    end

    it "follows the pagination token" do
      service.groups

      expect(requests_for(:list_groups).last[:params]).to include(next_token: "page-2", user_pool_id: "eu-west-2_pool")
    end
  end

  describe "#find_group" do
    before { client.stub_responses(:list_groups, groups: [{ group_name: "dl-a" }]) }

    it "finds a dl- group" do
      expect(service.find_group("dl-a").name).to eq("dl-a")
    end

    it "raises NotFound for a missing dl- group" do
      expect { service.find_group("dl-missing") }.to raise_error(described_class::NotFound)
    end

    it "raises InvalidGroup for a role group" do
      expect { service.find_group("admin") }.to raise_error(described_class::InvalidGroup)
    end
  end

  describe "#members" do
    before do
      client.stub_responses(:list_users_in_group, [
        { users: [cognito_user(username: "sub-b", email: "b@example.com")], next_token: "next" },
        { users: [cognito_user(username: "sub-a", email: "a@example.com", status: "FORCE_CHANGE_PASSWORD")] },
      ])
    end

    it "returns members from every page, sorted by email", :aggregate_failures do
      members = service.members("dl-a")

      expect(members.map(&:email)).to eq(%w[a@example.com b@example.com])
      expect(members.first).to have_attributes(username: "sub-a", status: "FORCE_CHANGE_PASSWORD", enabled: true)
    end

    it "never queries a role group", :aggregate_failures do
      expect { service.members("admin") }.to raise_error(described_class::InvalidGroup)
      expect(requests_for(:list_users_in_group)).to be_empty
    end

    it "raises NotFound when Cognito does not know the group" do
      client.stub_responses(:list_users_in_group, "ResourceNotFoundException")

      expect { service.members("dl-a") }.to raise_error(described_class::NotFound)
    end

    it "wraps a timeout reading the list" do
      client.stub_responses(:list_users_in_group, read_timeout)

      expect { service.members("dl-a") }.to raise_error(described_class::Error, /NetworkingError/)
    end
  end

  describe "#add" do
    before { client.stub_responses(:list_users_in_group, users: []) }

    context "when the user exists" do
      before { client.stub_responses(:admin_get_user, username: sub) }

      it "adds the user to the group without creating one", :aggregate_failures do
        expect(service.add("dl-a", " Jane@Example.com ")).to eq(:added)
        expect(requests_for(:admin_get_user).first[:params]).to include(username: email)
        expect(requests_for(:admin_create_user)).to be_empty
        expect(requests_for(:admin_add_user_to_group).first[:params]).to eq(user_pool_id: "eu-west-2_pool", username: sub, group_name: "dl-a")
      end

      it "reports an existing member without adding again", :aggregate_failures do
        client.stub_responses(:list_users_in_group, users: [cognito_user(username: sub, email:)])

        expect(service.add("dl-a", email)).to eq(:already_member)
        expect(requests_for(:admin_add_user_to_group)).to be_empty
      end
    end

    context "when the user does not exist" do
      before do
        client.stub_responses(:admin_get_user, "UserNotFoundException")
        client.stub_responses(:admin_create_user, user: { username: sub })
      end

      it "reports that it created the user" do
        expect(service.add("dl-a", email)).to eq(:created_and_added)
      end

      it "creates the user without an invitation email" do
        service.add("dl-a", email)

        expect(requests_for(:admin_create_user).first[:params]).to include(username: email, message_action: "SUPPRESS")
      end

      it "marks the email as verified so the unverified-user sweep keeps the user" do
        service.add("dl-a", email)

        expect(requests_for(:admin_create_user).first[:params][:user_attributes])
          .to contain_exactly({ name: "email", value: email }, { name: "email_verified", value: "true" })
      end

      it "adds the created user to the group" do
        service.add("dl-a", email)

        expect(requests_for(:admin_add_user_to_group).first[:params]).to include(username: sub, group_name: "dl-a")
      end
    end

    context "when the user was created but adding it to the group fails" do
      before do
        client.stub_responses(:admin_get_user, "UserNotFoundException")
        client.stub_responses(:admin_create_user, user: { username: sub })
        client.stub_responses(:admin_add_user_to_group, "TooManyRequestsException")
        client.stub_responses(:admin_list_groups_for_user, groups: [])
      end

      it "deletes the new user and reports the failure", :aggregate_failures do
        expect { service.add("dl-a", email) }.to raise_error(described_class::Error) { |error|
          expect(error).not_to be_a(described_class::CleanupFailed)
        }
        expect(requests_for(:admin_delete_user).map { |r| r[:params] }).to eq([{ user_pool_id: "eu-west-2_pool", username: sub }])
      end

      it "audits the creation and the deletion", :aggregate_failures do
        expect { service.add("dl-a", email) }.to raise_error(described_class::Error)
        expect(DistributionListAuditEvent.order(:id).pluck(:action, :recipient_username)).to eq([%W[user_created #{sub}], %W[user_deleted #{sub}]])
      end

      it "keeps the new user if another writer has put it in a group", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "myott" }])

        expect { service.add("dl-a", email) }.to raise_error(described_class::Error)
        expect(requests_for(:admin_delete_user)).to be_empty
      end

      it "raises CleanupFailed with the sub when the deletion fails", :aggregate_failures do
        client.stub_responses(:admin_delete_user, "TooManyRequestsException")

        expect { service.add("dl-a", email) }.to raise_error(described_class::CleanupFailed) { |error|
          expect(error.username).to eq(sub)
          expect(error.message).not_to include(email)
        }
      end
    end

    it "does not delete an existing user when adding it to the group fails", :aggregate_failures do
      client.stub_responses(:admin_get_user, username: sub)
      client.stub_responses(:admin_add_user_to_group, "TooManyRequestsException")
      client.stub_responses(:admin_list_groups_for_user, groups: [])

      expect { service.add("dl-a", email) }.to raise_error(described_class::Error)
      expect(requests_for(:admin_delete_user)).to be_empty
    end

    context "when adding an existing user times out" do
      before do
        client.stub_responses(:admin_get_user, username: sub)
        client.stub_responses(:admin_add_user_to_group, read_timeout)
      end

      it "reports success and audits it if the add reached Cognito", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "dl-a" }])

        expect(service.add("dl-a", email)).to eq(:added)
        expect(DistributionListAuditEvent.pluck(:action)).to eq(%w[recipient_added])
      end

      it "reports the failure without deleting the user if the add did not reach Cognito", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [])

        expect { service.add("dl-a", email) }.to raise_error(described_class::Error, /NetworkingError/)
        expect(requests_for(:admin_delete_user)).to be_empty
      end
    end

    context "when the user was created but adding it to the group times out" do
      before do
        client.stub_responses(:admin_get_user, "UserNotFoundException")
        client.stub_responses(:admin_create_user, user: { username: sub })
        client.stub_responses(:admin_add_user_to_group, read_timeout)
      end

      it "keeps the user and reports success if the add reached Cognito", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "dl-a" }])

        expect(service.add("dl-a", email)).to eq(:created_and_added)
        expect(requests_for(:admin_delete_user)).to be_empty
      end

      it "deletes the new user if the add did not reach Cognito", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [])

        expect { service.add("dl-a", email) }.to raise_error(described_class::Error) { |error|
          expect(error).not_to be_a(described_class::CleanupFailed)
        }
        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[user_created user_deleted])
      end

      it "raises CleanupFailed without deleting when the group lookup also times out", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, read_timeout)

        expect { service.add("dl-a", email) }.to raise_error(described_class::CleanupFailed) { |error|
          expect(error.username).to eq(sub)
        }
        expect(requests_for(:admin_delete_user)).to be_empty
      end

      it "raises CleanupFailed when the deletion times out and the user still exists" do
        client.stub_responses(:admin_list_groups_for_user, groups: [])
        client.stub_responses(:admin_delete_user, read_timeout)
        client.stub_responses(:admin_get_user, ["UserNotFoundException", { username: sub }])

        expect { service.add("dl-a", email) }.to raise_error(described_class::CleanupFailed, /NetworkingError/)
      end

      it "treats a timed-out deletion as done when the user is gone", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [])
        client.stub_responses(:admin_delete_user, read_timeout)
        client.stub_responses(:admin_get_user, "UserNotFoundException")

        expect { service.add("dl-a", email) }.to raise_error(described_class::Error, /could not add the recipient/)
        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[user_created user_deleted])
      end
    end

    context "when creating the user times out" do
      before { client.stub_responses(:admin_create_user, read_timeout) }

      it "treats the user as created here if it now exists", :aggregate_failures do
        client.stub_responses(:admin_get_user, ["UserNotFoundException", { username: sub }])

        expect(service.add("dl-a", email)).to eq(:created_and_added)
        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[user_created recipient_added])
      end

      it "reports the failure if the user does not exist", :aggregate_failures do
        client.stub_responses(:admin_get_user, "UserNotFoundException")

        expect { service.add("dl-a", email) }.to raise_error(described_class::Error, /NetworkingError/)
        expect(requests_for(:admin_add_user_to_group)).to be_empty
      end
    end

    context "when another request created the user first" do
      before do
        client.stub_responses(:admin_get_user, ["UserNotFoundException", { username: sub }])
        client.stub_responses(:admin_create_user, "UsernameExistsException")
      end

      it "falls back to the existing user" do
        expect(service.add("dl-a", email)).to eq(:added)
      end
    end

    it "refuses to add anyone to a role group", :aggregate_failures do
      %w[admin myott portal].each do |group|
        expect { service.add(group, email) }.to raise_error(described_class::InvalidGroup)
      end
      expect(client.api_requests).to be_empty
    end

    it "wraps Cognito errors without the email", :aggregate_failures do
      client.stub_responses(:admin_get_user, username: sub)
      client.stub_responses(:admin_add_user_to_group, "TooManyRequestsException")

      expect { service.add("dl-a", email) }.to raise_error(described_class::Error) { |error|
        expect(error.message).not_to include(email)
      }
    end

    context "when auditing" do
      let(:logged) { [] }

      before do
        client.stub_responses(:admin_get_user, username: sub)
        allow(Rails.logger).to receive(:info) { |message| logged << message }
        service.add("dl-a", email)
      end

      it "stores who subscribed which recipient to which list" do
        expect(DistributionListAuditEvent.sole).to have_attributes(
          actor_uid: "operator-1", actor_name: "Olivia Operator", action: "recipient_added", group_name: "dl-a", recipient_username: sub,
        )
      end

      it "stores when the change happened" do
        expect(DistributionListAuditEvent.sole.created_at).to be_within(1.minute).of(Time.current)
      end

      it "does not store the email" do
        expect(DistributionListAuditEvent.pluck(:recipient_username, :group_name, :actor_name).flatten).not_to include(email)
      end

      it "logs the event without the email", :aggregate_failures do
        expect(logged.join).to include("distribution_list.recipient_added", sub, "operator-1")
        expect(logged.join).not_to include(email)
      end
    end

    context "when a user is created" do
      before do
        client.stub_responses(:admin_get_user, "UserNotFoundException")
        client.stub_responses(:admin_create_user, user: { username: sub })
        service.add("dl-a", email)
      end

      it "audits the creation and the subscription" do
        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[user_created recipient_added])
      end
    end
  end

  describe "#last_group?" do
    it "is true when the user is only in this group" do
      client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "dl-a" }])

      expect(service.last_group?("dl-a", sub)).to be(true)
    end

    it "is false when the user is in another group" do
      client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "dl-a" }, { group_name: "myott" }])

      expect(service.last_group?("dl-a", sub)).to be(false)
    end

    it "raises NotFound for an unknown user" do
      client.stub_responses(:admin_list_groups_for_user, "UserNotFoundException")

      expect { service.last_group?("dl-a", sub) }.to raise_error(described_class::NotFound)
    end
  end

  describe "#remove" do
    before { client.stub_responses(:list_users_in_group, users: [cognito_user(username: sub, email:)]) }

    context "when the user is still in another group" do
      before { client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "myott" }]) }

      it "removes the user from the group and keeps the Cognito user", :aggregate_failures do
        expect(service.remove("dl-a", sub)).to eq(:removed)
        expect(requests_for(:admin_remove_user_from_group).first[:params]).to eq(user_pool_id: "eu-west-2_pool", username: sub, group_name: "dl-a")
        expect(requests_for(:admin_delete_user)).to be_empty
      end

      it "audits the removal only" do
        service.remove("dl-a", sub)

        expect(DistributionListAuditEvent.pluck(:action, :recipient_username)).to eq([["recipient_removed", sub]])
      end
    end

    context "when the group was the last group the user was in" do
      before { client.stub_responses(:admin_list_groups_for_user, groups: []) }

      it "requires account deletion to be confirmed before changing Cognito", :aggregate_failures do
        expect { service.remove("dl-a", sub) }.to raise_error(described_class::ConfirmationRequired)
        expect(requests_for(:admin_remove_user_from_group) + requests_for(:admin_delete_user)).to be_empty
        expect(DistributionListAuditEvent.count).to eq(0)
      end

      it "deletes the Cognito user", :aggregate_failures do
        expect(service.remove("dl-a", sub, account_deletion_acknowledged: true)).to eq(:removed_and_deleted)
        expect(requests_for(:admin_delete_user).first[:params]).to eq(user_pool_id: "eu-west-2_pool", username: sub)
      end

      it "checks the groups before removal and again before deletion" do
        service.remove("dl-a", sub, account_deletion_acknowledged: true)

        expect(client.api_requests.map { |r| r[:operation_name] }).to eq(
          %i[list_users_in_group admin_list_groups_for_user admin_remove_user_from_group admin_list_groups_for_user admin_delete_user],
        )
      end

      it "audits the removal and the deletion" do
        service.remove("dl-a", sub, account_deletion_acknowledged: true)

        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[recipient_removed user_deleted])
      end
    end

    context "when the deletion fails" do
      before do
        client.stub_responses(:admin_list_groups_for_user, groups: [])
        client.stub_responses(:admin_delete_user, "TooManyRequestsException")
      end

      it "raises DeletionFailed with the sub but not the email", :aggregate_failures do
        expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::DeletionFailed) { |error|
          expect(error.username).to eq(sub)
        }
        expect(DistributionListAuditEvent.pluck(:action)).to eq(%w[recipient_removed])
      end
    end

    context "when checking the remaining groups fails" do
      before { client.stub_responses(:admin_list_groups_for_user, "TooManyRequestsException") }

      it "does not unsubscribe or delete", :aggregate_failures do
        expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::Error)
        expect(requests_for(:admin_remove_user_from_group)).to be_empty
        expect(requests_for(:admin_delete_user)).to be_empty
      end
    end

    context "when the removal times out" do
      before { client.stub_responses(:admin_remove_user_from_group, read_timeout) }

      it "carries on, and deletes a user left in no group, if the removal reached Cognito", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [])

        expect(service.remove("dl-a", sub, account_deletion_acknowledged: true)).to eq(:removed_and_deleted)
        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[recipient_removed user_deleted])
      end

      it "reports the failure if the user is still in the group", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "dl-a" }])

        expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::Error, /NetworkingError/)
        expect(requests_for(:admin_delete_user)).to be_empty
        expect(DistributionListAuditEvent.count).to eq(0)
      end

      it "reports the failure if the groups cannot be read", :aggregate_failures do
        client.stub_responses(:admin_list_groups_for_user, read_timeout)

        expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::Error, /NetworkingError/)
        expect(requests_for(:admin_delete_user)).to be_empty
      end
    end

    context "when checking the remaining groups times out" do
      before { client.stub_responses(:admin_list_groups_for_user, read_timeout) }

      it "does not unsubscribe or delete", :aggregate_failures do
        expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::Error, /NetworkingError/)
        expect(requests_for(:admin_remove_user_from_group)).to be_empty
        expect(requests_for(:admin_delete_user)).to be_empty
      end
    end

    context "when the deletion times out" do
      before do
        client.stub_responses(:admin_list_groups_for_user, groups: [])
        client.stub_responses(:admin_delete_user, read_timeout)
      end

      it "raises DeletionFailed if the user still exists" do
        client.stub_responses(:admin_get_user, username: sub)

        expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::DeletionFailed, /NetworkingError/)
      end

      it "raises DeletionFailed if it cannot check whether the user still exists" do
        client.stub_responses(:admin_get_user, read_timeout)

        expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::DeletionFailed, /NetworkingError/)
      end

      it "treats the deletion as done if the user is gone", :aggregate_failures do
        client.stub_responses(:admin_get_user, "UserNotFoundException")

        expect(service.remove("dl-a", sub, account_deletion_acknowledged: true)).to eq(:removed_and_deleted)
        expect(DistributionListAuditEvent.order(:id).pluck(:action)).to eq(%w[recipient_removed user_deleted])
      end
    end

    it "refuses to remove anyone from a role group", :aggregate_failures do
      expect { service.remove("admin", sub) }.to raise_error(described_class::InvalidGroup)
      expect(client.api_requests).to be_empty
    end

    it "raises NotFound when the user is gone" do
      client.stub_responses(:admin_remove_user_from_group, "UserNotFoundException")

      expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::NotFound)
    end

    it "does not remove or delete a user who is not on the list", :aggregate_failures do
      client.stub_responses(:list_users_in_group, users: [])

      expect { service.remove("dl-a", sub) }.to raise_error(described_class::NotFound)
      expect(requests_for(:admin_remove_user_from_group) + requests_for(:admin_delete_user)).to be_empty
    end
  end

  describe "per-recipient locking" do
    def other_sub = "99999999-8888-7777-6666-555555555555"

    before do
      # sub is on dl-a. Subscribing uses dl-b, which has no members.
      client.stub_responses(:list_users_in_group, lambda { |context|
        context.params[:group_name] == "dl-a" ? { users: [cognito_user(username: sub, email:)] } : { users: [] }
      })
      client.stub_responses(:admin_list_groups_for_user, groups: [])
    end

    it "does not unsubscribe or delete while another request holds the recipient's lock", :aggregate_failures do
      holding_distribution_list_lock(sub) do
        expect { service.remove("dl-a", sub) }.to raise_error(described_class::Busy)
      end

      expect(client.api_requests).to be_empty
      expect(DistributionListAuditEvent.count).to eq(0)
    end

    it "does not subscribe while another request holds the recipient's lock", :aggregate_failures do
      client.stub_responses(:admin_get_user, username: sub)

      holding_distribution_list_lock(sub) do
        expect { service.add("dl-b", email) }.to raise_error(described_class::Busy)
      end

      expect(requests_for(:admin_add_user_to_group)).to be_empty
    end

    it "only locks the recipient being changed" do
      holding_distribution_list_lock(other_sub) do
        expect(service.remove("dl-a", sub, account_deletion_acknowledged: true)).to eq(:removed_and_deleted)
      end
    end

    context "when deleting the user" do
      let(:lock_states) { [] }

      before do
        allow(client).to receive(:admin_delete_user).and_wrap_original do |original, *args, **kwargs|
          lock_states << distribution_list_lock_free?(sub)
          original.call(*args, **kwargs)
        end
      end

      it "still holds the lock taken for the removal" do
        service.remove("dl-a", sub, account_deletion_acknowledged: true)

        expect(lock_states).to eq([false])
      end
    end

    it "releases the lock after an unsubscribe" do
      service.remove("dl-a", sub, account_deletion_acknowledged: true)

      expect(distribution_list_lock_free?(sub)).to be(true)
    end

    it "releases the lock when Cognito fails", :aggregate_failures do
      client.stub_responses(:admin_remove_user_from_group, "TooManyRequestsException")
      client.stub_responses(:admin_list_groups_for_user, groups: [{ group_name: "dl-a" }])

      expect { service.remove("dl-a", sub, account_deletion_acknowledged: true) }.to raise_error(described_class::Error)
      expect(distribution_list_lock_free?(sub)).to be(true)
    end

    it "releases the lock after a subscribe" do
      client.stub_responses(:admin_get_user, username: sub)
      service.add("dl-b", email)

      expect(distribution_list_lock_free?(sub)).to be(true)
    end

    context "when an unsubscribe deleted the user before the subscribe got the lock" do
      before do
        client.stub_responses(:admin_get_user, [{ username: sub }, "UserNotFoundException"])
        client.stub_responses(:admin_add_user_to_group, ["UserNotFoundException", {}])
        client.stub_responses(:admin_create_user, user: { username: other_sub })
      end

      it "creates the user again and subscribes the new user", :aggregate_failures do
        expect(service.add("dl-b", email)).to eq(:created_and_added)
        expect(requests_for(:admin_add_user_to_group).map { |r| r[:params][:username] }).to eq([sub, other_sub])
      end

      it "audits only the new user" do
        service.add("dl-b", email)

        expect(DistributionListAuditEvent.order(:id).pluck(:action, :recipient_username)).to eq([%W[user_created #{other_sub}], %W[recipient_added #{other_sub}]])
      end
    end

    it "raises NotFound when the user keeps disappearing" do
      client.stub_responses(:admin_get_user, username: sub)
      client.stub_responses(:admin_add_user_to_group, "UserNotFoundException")

      expect { service.add("dl-b", email) }.to raise_error(described_class::NotFound)
    end

    it "does not look the user up while another subscription holds the email's lock", :aggregate_failures do
      holding_distribution_list_email_lock(email) do
        expect { service.add("dl-b", " #{email.upcase} ") }.to raise_error(described_class::Busy)
      end

      expect(client.api_requests).to be_empty
    end

    it "releases the email lock after a subscribe" do
      client.stub_responses(:admin_get_user, username: sub)
      service.add("dl-b", email)

      expect(distribution_list_email_lock_free?(email)).to be(true)
    end

    it "reports a user it created but cannot lock, so the user can be cleaned up", :aggregate_failures do
      client.stub_responses(:admin_get_user, "UserNotFoundException")
      client.stub_responses(:admin_create_user, user: { username: other_sub })

      holding_distribution_list_lock(other_sub) do
        expect { service.add("dl-b", email) }.to raise_error(described_class::CleanupFailed) { |error| expect(error.username).to eq(other_sub) }
      end
    end

    # Request A creates the user. Before A takes the user's lock, request B
    # subscribes the same email. B must not find A's new user, or B could hold
    # its lock until A gives up, and then neither request cleans it up.
    context "when another subscription for the same email starts while this one creates the user" do
      let(:other_request) { {} }

      before do
        other_client = Aws::CognitoIdentityProvider::Client.new(stub_responses: true, region: "eu-west-2")
        other_client.stub_responses(:admin_get_user, username: other_sub)
        other = described_class.new(client: other_client, user_pool_id: "eu-west-2_pool", actor:, lock_timeout: 0.3)
        outcome = other_request
        client.stub_responses(:admin_get_user, "UserNotFoundException")
        client.stub_responses(:admin_add_user_to_group, "TooManyRequestsException")
        client.stub_responses(:admin_create_user, user: { username: other_sub })

        allow(client).to receive(:admin_create_user).and_wrap_original do |original, *args, **kwargs|
          response = original.call(*args, **kwargs)
          outcome[:result] = in_other_request { other.add("dl-c", email.upcase) }
          outcome[:cognito_calls] = other_client.api_requests.map { |r| r[:operation_name] }
          response
        end
      end

      def in_other_request(&block)
        thread = Thread.new do
          ActiveRecord::Base.connection_pool.with_connection(&block)
        rescue StandardError => e
          e.class
        end
        thread.value
      end

      it "makes the other subscription wait without looking the user up", :aggregate_failures do
        expect { service.add("dl-b", email) }.to raise_error(described_class::Error)

        expect(other_request).to eq(result: described_class::Busy, cognito_calls: [])
      end

      it "deletes the user it created when its own subscription fails", :aggregate_failures do
        expect { service.add("dl-b", email) }.to raise_error(described_class::Error)

        expect(requests_for(:admin_delete_user).map { |r| r[:params][:username] }).to eq([other_sub])
      end
    end
  end
end
