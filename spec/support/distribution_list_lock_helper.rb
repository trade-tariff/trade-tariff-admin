# Holds DistributionListService's per-recipient advisory lock from a separate
# database connection, as a concurrent request would.
module DistributionListLockHelper
  def holding_distribution_list_lock(username, user_pool_id: "eu-west-2_pool")
    connection = ActiveRecord::Base.connection_pool.checkout
    key = "distribution_list_user:#{user_pool_id}:#{username}"
    connection.execute(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_advisory_lock(hashtextextended(?, 0))", key]))

    yield
  ensure
    if connection
      connection.select_value(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_advisory_unlock(hashtextextended(?, 0))", key]))
      ActiveRecord::Base.connection_pool.checkin(connection)
    end
  end

  def distribution_list_lock_free?(username, user_pool_id: "eu-west-2_pool")
    connection = ActiveRecord::Base.connection_pool.checkout
    key = "distribution_list_user:#{user_pool_id}:#{username}"
    locked = connection.select_value(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_try_advisory_lock(hashtextextended(?, 0))", key]))
    connection.select_value(ActiveRecord::Base.sanitize_sql_array(["SELECT pg_advisory_unlock(hashtextextended(?, 0))", key])) if locked
    locked
  ensure
    ActiveRecord::Base.connection_pool.checkin(connection) if connection
  end
end
