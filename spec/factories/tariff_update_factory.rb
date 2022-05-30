FactoryBot.define do
  factory :tariff_update do
    update_type { 'TariffSynchronizer::TaricUpdate' }
    state { %w[A M P F].sample }
    issue_date { Time.zone.today.iso8601 }
    updated_at { Time.zone.now }
    created_at { Time.zone.now }
    inserts { '{}' }
    filename { '2022-02-06_TGB22037.xml' }

    trait :failed do
      state { 'F' }
    end

    trait :taric do
      update_type { 'TariffSynchronizer::TaricUpdate' }
    end

    trait :cds do
      update_type { 'TariffSynchronizer::CdsUpdate' }
    end

    trait :with_exception do
      exception_class { 'CdsImporter::ImportException' }
      exception_queries { "(Sequel::Mysql2::Database) BEGIN \n(Sequel::Mysql2::Database) SELECT * FROM `measures` LIMIT 1 \n(Sequel::Mysql2::Database) ROLLBACK \n(Sequel::Mysql2::Database) UPDATE `tariff_updates` SET `state` = 'F', `updated_at` = '2014-07-22 16:16:15' WHERE ((`tariff_updates`.`update_type` IN ('TariffSynchronizer::TaricUpdate')) AND (`filename` = '2014-07-22_TGB14203.xml')) LIMIT 1 " }
      exception_backtrace { "/var/govuk/trade-tariff-backend/spec/unit/tariff_synchronizer/logger_spec.rb:179:in `block (4 levels) in <top (required)>'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/message_expectation.rb:519:in `call'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/message_expectation.rb:519:in `block in call'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/message_expectation.rb:518:in `map'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/message_expectation.rb:518:in `call'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/message_expectation.rb:186:in `invoke'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/proxy.rb:144:in `message_received'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/method_double.rb:174:in `import'\n/usr/lib/rbenv/versions/2.0.0-p353/lib/ruby/gems/2.0.0/gems/rspec-mocks-2.14.1/lib/rspec/mocks/any_instance/recorder.rb:187:in `import'" }
    end

    trait :missing do
      state { 'M' }
    end

    trait :with_inserts do
      inserts do
        {
          "operations": {
            "create": {
              "count": 2909,
              "duration": 4863.6220703125,
              "allocations": 0,
              "QuotaBalanceEvent": { "count": 2869, "allocations": 0, "duration": 4745.491455078125, "mapping_path": 'quotaBalanceEvent' },
              "QuotaAssociation": { "count": 12, "allocations": 0, "duration": 26.2646484375, "mapping_path": 'quotaAssociation' },
              "QuotaCriticalEvent": { "count": 12, "allocations": 0, "duration": 40.99951171875, "mapping_path": 'quotaCriticalEvent' },
              "QuotaReopeningEvent": { "count": 5, "allocations": 0, "duration": 14.496337890625, "mapping_path": 'quotaReopeningEvent' },
              "QuotaExhaustionEvent": { "count": 10, "allocations": 0, "duration": 25.343017578125, "mapping_path": 'quotaExhaustionEvent' },
              "MeasureExcludedGeographicalArea": { "count": 1, "allocations": 0, "duration": 11.027099609375, "mapping_path": 'measureExcludedGeographicalArea' },
            },
            "update": {
              "count": 93,
              "duration": 334.093017578125,
              "allocations": 0,
              "QuotaDefinition": { "count": 57, "allocations": 0, "duration": 192.965576171875, "mapping_path": nil },
              "Measure": { "count": 18, "allocations": 0, "duration": 87.497802734375, "mapping_path": nil },
              "MeasureComponent": { "count": 18, "allocations": 0, "duration": 53.629638671875, "mapping_path": 'measureComponent' },
            },
            "destroy": { "count": 4, "duration": 0, "allocations": 0 },
            "destroy_cascade": { "count": 5, "duration": 0, "allocations": 0 },
            "destroy_missing": { "count": 7, "duration": 0, "allocations": 0 },
          },
          "total_count": 3002,
          "total_duration": 5197.715087890625,
          "total_allocations": 0,
        }.to_json
      end
    end

    trait :with_old_inserts do
      inserts do
        {
          "FootnoteType::Operation": 1,
          "FootnoteTypeDescription::Operation": 1,
          "QuotaDefinition::Operation": 59,
          "QuotaBalanceEvent::Operation": 2581,
          "QuotaCriticalEvent::Operation": 13,
          "QuotaAssociation::Operation": 13,
          "QuotaReopeningEvent::Operation": 4,
          "QuotaExhaustionEvent::Operation": 9,
        }.to_json
      end
    end
  end
end
