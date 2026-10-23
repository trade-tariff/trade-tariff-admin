module DistributionLists
  class RecipientsController < AuthenticatedController
    include DistributionListHandling

    ADD_MESSAGES = {
      created_and_added: "New user created and subscribed to the distribution list.",
      added: "Recipient subscribed to the distribution list.",
      already_member: "Recipient was already subscribed to the distribution list.",
    }.freeze

    REMOVE_MESSAGES = {
      removed: "Recipient unsubscribed from the distribution list.",
      removed_and_deleted: "Recipient unsubscribed. They were in no other group, so their Cognito account and email address were deleted.",
    }.freeze

    before_action :authorize_distribution_list
    before_action :load_group

    def create
      @form = DistributionListRecipientForm.new(email: params.dig(:distribution_list_recipient_form, :email))

      if @form.valid?
        begin
          result = distribution_list_service.add(@group.name, @form.email)
          redirect_to distribution_list_path(@group.name), notice: ADD_MESSAGES.fetch(result)
        rescue DistributionListService::CleanupFailed => e
          Rails.logger.error("distribution_list.cleanup_failed #{e.message}")
          redirect_to distribution_list_path(@group.name),
                      alert: "Recipient was not subscribed. A new Cognito account was created for them but could not be removed. Ask the platform team to delete Cognito user #{e.username}."
        end
      else
        @members = distribution_list_service.members(@group.name)
        load_audit_events
        render "distribution_lists/show", status: :unprocessable_content
      end
    end

    def remove
      @member = distribution_list_service.find_member(@group.name, params[:username])
      unless @member
        return redirect_to distribution_list_path(@group.name), alert: "Recipient is no longer in this distribution list."
      end

      @deletes_account = distribution_list_service.last_group?(@group.name, @member.username)
    end

    def destroy
      result = distribution_list_service.remove(@group.name, params[:username])
      redirect_to distribution_list_path(@group.name), notice: REMOVE_MESSAGES.fetch(result)
    rescue DistributionListService::DeletionFailed => e
      Rails.logger.error("distribution_list.deletion_failed #{e.message}")
      redirect_to distribution_list_path(@group.name),
                  alert: "Recipient unsubscribed, but their Cognito account could not be checked or deleted. Ask the platform team to check the remaining groups for Cognito user #{e.username} and delete the account only if no groups remain."
    rescue DistributionListService::NotFound
      redirect_to distribution_list_path(@group.name), alert: "Recipient is no longer in this distribution list."
    end

  private

    def authorize_distribution_list
      authorize :distribution_list, action_name == "create" ? :create? : :destroy?
    end

    def load_group
      @group = distribution_list_service.find_group(params[:distribution_list_group_name])
    end
  end
end
