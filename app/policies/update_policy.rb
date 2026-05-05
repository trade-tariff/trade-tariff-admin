# Updates (Daily Tariff Files): SUPERADMIN destructive actions, TECHNICAL_OPERATOR/AUDITOR extract/read-only, HMRC_ADMIN hidden, GUEST hidden
class UpdatePolicy < ApplicationPolicy
  def index?
    safe_update_access?
  end

  def show?
    safe_update_access?
  end

  def download_file?
    safe_update_access?
  end

  def schedule_download?
    superadmin?
  end

  def apply_and_clear_cache?
    superadmin?
  end

  def resend_cds_update_notification?
    superadmin?
  end

private

  def safe_update_access?
    technical_operator? || auditor?
  end
end
