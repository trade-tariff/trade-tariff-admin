# Updates (Daily Tariff Files): SUPERADMIN destructive actions, TECHNICAL_OPERATOR/AUDITOR read-only, HMRC_ADMIN hidden, GUEST hidden
class UpdatePolicy < ApplicationPolicy
  def index?
    technical_operator? || auditor?
  end

  def show?
    technical_operator? || auditor?
  end

  # Actions like download, apply_and_clear_cache, resend_cds_update_notification
  def download?
    superadmin?
  end

  def apply_and_clear_cache?
    superadmin?
  end

  def resend_cds_update_notification?
    superadmin?
  end
end
