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

    RECIPIENT_GONE_MESSAGE = "Recipient is no longer in this distribution list.".freeze

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
          render_reconciliation(
            "Recipient was not subscribed",
            with_missing_audits("A new Cognito account was created for them but could not be checked or removed. Ask the platform team to check the remaining groups for Cognito user #{e.username} and delete the account only if no groups remain.", e),
          )
        rescue DistributionListService::AddIndeterminate => e
          Rails.logger.error("distribution_list.add_indeterminate group=#{@group.name} #{e.message}")
          render_reconciliation("Subscription not confirmed", with_missing_audits(add_indeterminate_instructions(e), e))
        rescue DistributionListService::CreationIndeterminate => e
          # The email is only known from this request, so the instructions are
          # rendered in this response. It must not go in the log, flash or URL.
          Rails.logger.error("distribution_list.creation_indeterminate group=#{@group.name} #{e.message}")
          render :creation_indeterminate, status: :service_unavailable
        rescue DistributionListService::AuditFailed => e
          render_reconciliation("Audit record not saved", with_missing_audits(ADD_MESSAGES.fetch(e.result), e), status: :ok)
        rescue DistributionListService::RecipientNotFound => e
          recipient_gone("Recipient was not subscribed because their Cognito account was deleted during the request. Try again.", e)
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
        return redirect_to distribution_list_path(@group.name), alert: RECIPIENT_GONE_MESSAGE
      end

      @deletes_account = distribution_list_service.last_group?(@group.name, @member.username)
    rescue DistributionListService::RecipientNotFound => e
      recipient_gone(RECIPIENT_GONE_MESSAGE, e)
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
      render_reconciliation("Audit record not saved", with_missing_audits(REMOVE_MESSAGES.fetch(e.result), e), status: :ok)
    rescue DistributionListService::RemovalIndeterminate => e
      Rails.logger.error("distribution_list.removal_indeterminate group=#{@group.name} #{e.message}")
      render_reconciliation(
        "Unsubscribe not confirmed",
        with_missing_audits(
          "Cognito did not confirm whether the recipient was unsubscribed. Ask the platform team to check the groups for Cognito user #{e.username}. " \
          "If the user is no longer in #{@group.name}, record recipient_removed for that user. " \
          "If no groups remain, delete the Cognito account and record user_deleted.",
          e,
        ),
      )
    rescue DistributionListService::DeletionFailed => e
      Rails.logger.error("distribution_list.deletion_failed #{e.message}")
      render_reconciliation(
        "Cognito account not deleted",
        with_missing_audits("Recipient unsubscribed, but their Cognito account could not be checked or deleted. Ask the platform team to check the remaining groups for Cognito user #{e.username} and delete the account only if no groups remain.", e),
      )
    rescue DistributionListService::RecipientNotFound => e
      recipient_gone(RECIPIENT_GONE_MESSAGE, e)
    end

  private

    # Subscribing again does not fix this: it finds the user already in the
    # list and records no event.
    def add_indeterminate_instructions(error)
      message = "Cognito did not confirm whether the recipient was subscribed. Do not subscribe them again. " \
                "Ask the platform team to check the groups for Cognito user #{error.username}. " \
                "If the user is in #{@group.name}, record recipient_added for that user."
      return message unless error.created

      "#{message} A new Cognito account was created for them. If no groups remain, delete the Cognito account and record user_deleted."
    end

    def recipient_gone(message, error)
      return redirect_to(distribution_list_path(@group.name), alert: message) if error.failed_audits.empty?

      render_reconciliation("Recipient not found", with_missing_audits(message, error), status: :ok)
    end

    def authorize_distribution_list
      authorize :distribution_list, action_name == "create" ? :create? : :destroy?
    end

    def load_group
      @group = distribution_list_service.find_group(params[:distribution_list_group_name])
    end
  end
end
