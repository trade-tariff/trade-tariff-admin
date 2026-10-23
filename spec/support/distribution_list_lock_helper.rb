# Holds DistributionListService's advisory locks from a separate database
# connection, as a concurrent request would.
module DistributionListLockHelper
  def holding_distribution_list_lock(username, user_pool_id: "eu-west-2_pool", &)
    holding_advisory_lock("distribution_list_user:#{user_pool_id}:#{username}", &)
  end

  def holding_distribution_list_email_lock(email, user_pool_id: "eu-west-2_pool", &)
    holding_advisory_lock("distribution_list_email:#{user_pool_id}:#{Digest::SHA256.hexdigest(email)}", &)
  end

  def distribution_list_lock_free?(username, user_pool_id: "eu-west-2_pool")
    advisory_lock_free?("distribution_list_user:#{user_pool_id}:#{username}")
  end

  def distribution_list_email_lock_free?(email, user_pool_id: "eu-west-2_pool")
    advisory_lock_free?("distribution_list_email:#{user_pool_id}:#{Digest::SHA256.hexdigest(email)}")
  end

private

  def holding_advisory_lock(key)
    connection = ActiveRecord::Base.connection_pool.checkout
    connection.execute(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_advisory_lock(hashtextextended(?, 0))", key]))

    yield
  ensure
    if connection
      connection.select_value(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_advisory_unlock(hashtextextended(?, 0))", key]))
      ActiveRecord::Base.connection_pool.checkin(connection)
    end
  end

  def advisory_lock_free?(key)
    connection = ActiveRecord::Base.connection_pool.checkout
    locked = connection.select_value(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_try_advisory_lock(hashtextextended(?, 0))", key]))
    connection.select_value(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_advisory_unlock(hashtextextended(?, 0))", key])) if locked
    locked
  ensure
    ActiveRecord::Base.connection_pool.checkin(connection) if connection
  end
end
