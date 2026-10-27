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
                      alert: with_missing_audits("Recipient was not subscribed. A new Cognito account was created for them but could not be checked or removed. Ask the platform team to check the remaining groups for Cognito user #{e.username} and delete the account only if no groups remain.", e)
        rescue DistributionListService::CreationIndeterminate => e
          # The email is only known from this request, so the instructions are
          # rendered in this response. It must not go in the log, flash or URL.
          Rails.logger.error("distribution_list.creation_indeterminate group=#{@group.name} #{e.message}")
          render :creation_indeterminate, status: :service_unavailable
        rescue DistributionListService::AuditFailed => e
          redirect_to distribution_list_path(@group.name), alert: with_missing_audits(ADD_MESSAGES.fetch(e.result), e)
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
      result = distribution_list_service.remove(
        @group.name,
        params[:username],
        account_deletion_acknowledged: params[:account_deletion_acknowledged] == "true",
      )
      redirect_to distribution_list_path(@group.name), notice: REMOVE_MESSAGES.fetch(result)
    rescue DistributionListService::ConfirmationRequired
      redirect_to remove_distribution_list_recipient_path(@group.name, params[:username]),
                  alert: "Group memberships changed. Review the account deletion warning and confirm again."
    rescue DistributionListService::AuditFailed => e
      redirect_to distribution_list_path(@group.name), alert: with_missing_audits(REMOVE_MESSAGES.fetch(e.result), e)
    rescue DistributionListService::RemovalIndeterminate => e
      Rails.logger.error("distribution_list.removal_indeterminate group=#{@group.name} #{e.message}")
      redirect_to distribution_list_path(@group.name),
                  alert: with_missing_audits(
                    "Cognito did not confirm whether the recipient was unsubscribed. Ask the platform team to check the groups for Cognito user #{e.username}. " \
                    "If the user is no longer in #{@group.name}, record recipient_removed for that user. " \
                    "If no groups remain, delete the Cognito account and record user_deleted.",
                    e,
                  )
    rescue DistributionListService::DeletionFailed => e
      Rails.logger.error("distribution_list.deletion_failed #{e.message}")
      redirect_to distribution_list_path(@group.name),
                  alert: with_missing_audits("Recipient unsubscribed, but their Cognito account could not be checked or deleted. Ask the platform team to check the remaining groups for Cognito user #{e.username} and delete the account only if no groups remain.", e)
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
