# Updates (Daily Tariff Files): TECHNICAL_OPERATOR monitor/diagnose/clear cache, HMRC_ADMIN hidden, AUDITOR read-only, GUEST hidden
class UpdatePolicy < ApplicationPolicy
  def index?
    technical_operator? || auditor?
  end

  def show?
    technical_operator? || auditor?
  end

  # Actions like download, apply_and_clear_cache, resend_cds_update_notification
  def download?
    technical_operator?
  end

  def apply_and_clear_cache?
    technical_operator?
  end

  def resend_cds_update_notification?
    technical_operator?
  end
end
