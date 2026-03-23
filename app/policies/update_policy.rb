# Updates (Daily Tariff Files): SUPERADMIN full control, AUDITOR read-only, HMRC_ADMIN hidden, GUEST hidden
class UpdatePolicy < ApplicationPolicy
  def index?
    superadmin? || auditor?
  end

  def show?
    superadmin? || auditor?
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
