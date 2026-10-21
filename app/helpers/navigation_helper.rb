module NavigationHelper
  NavigationSection = Data.define(:key, :label, :href, :items, :service)
  NavigationItem = Data.define(:text, :href, :policy_class, :active_when, :service, :tabs) do
    def initialize(text:, href:, policy_class:, active_when:, service: nil, tabs: [])
      super(text:, href:, policy_class:, active_when:, service:, tabs:)
    end
  end

  def navigation_sections
    versioning = TradeTariffAdmin.enable_section_chapter_note_versioning?
    @navigation_sections ||= [
      NavigationSection.new(
        key: :ott_admin,
        label: "OTT Admin",
        href: nil,
        service: nil,
        items: [
          NavigationItem.new(
            text: versioning ? "Customs Tariff Updates" : "Section & chapter notes",
            href: versioning ? customs_tariff_updates_path : notes_sections_path,
            policy_class: versioning ? CustomsTariff::Update : SectionNote,
            active_when: versioning ? %r{/customs_tariff} : %r{/notes},
            service: :uk,
          ),
          NavigationItem.new(
            text: "Section & chapter notes",
            href: notes_sections_path,
            policy_class: SectionNote,
            active_when: /\/notes/,
            service: :xi,
          ),
          NavigationItem.new(
            text: "News",
            href: news_items_path,
            policy_class: News::Item,
            active_when: /\/news_items/,
            service: :uk,
          ),
          NavigationItem.new(
            text: "Live Issues",
            href: live_issues_path,
            policy_class: LiveIssue,
            active_when: /\/live_issues/,
            service: :uk,
          ),
          NavigationItem.new(
            text: "Quotas",
            href: new_quota_path,
            policy_class: Quota,
            active_when: /\/quotas/,
            service: :uk,
          ),
          NavigationItem.new(
            text: "Updates",
            href: tariff_updates_path,
            policy_class: Update,
            active_when: /\/tariff_updates/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Reports",
            href: reports_path,
            policy_class: Report,
            active_when: /\/reports/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Rollbacks",
            href: rollbacks_path,
            policy_class: Rollback,
            active_when: /\/rollbacks/,
            service: nil,
          ),
        ],
      ),
      NavigationSection.new(
        key: :classification,
        label: "Classification",
        href: nil,
        service: nil,
        items: [
          NavigationItem.new(
            text: "Search References",
            href: references_sections_path,
            policy_class: SearchReference,
            active_when: %r{/search_references},
            service: nil,
            tabs: [
              NavigationItem.new(
                text: "Browse",
                href: references_sections_path,
                policy_class: SearchReference,
                active_when: %r{/search_references(?!/search(?:/|\z))},
                service: nil,
              ),
              NavigationItem.new(
                text: "Search",
                href: references_search_path,
                policy_class: References::EntitySearch,
                active_when: %r{/search_references/search(?:/|\z)},
                service: nil,
              ),
            ],
          ),
          NavigationItem.new(
            text: "Descriptions",
            href: goods_nomenclature_self_texts_path,
            policy_class: GoodsNomenclatureSelfText,
            active_when: /\/(goods_nomenclature_(self_texts|labels)|tariff_knowledge_compressed_notes)/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Intercepts",
            href: description_intercepts_path,
            policy_class: DescriptionIntercept,
            active_when: /\/description_intercepts/,
            service: :uk,
          ),
          NavigationItem.new(
            text: "Search dashboard",
            href: search_analytics_path,
            policy_class: SearchAnalytics,
            active_when: /\/search_analytics/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Search diagnostics",
            href: search_diagnostics_path,
            policy_class: SearchDiagnostic,
            active_when: /\/search_diagnostics/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Recent changes",
            href: versions_path,
            policy_class: Version,
            active_when: /\/versions/,
            service: nil,
          ),
        ],
      ),
      NavigationSection.new(
        key: :evaluation,
        label: "Evaluation",
        href: nil,
        service: :uk,
        items: [
          NavigationItem.new(
            text: "Synthetic ATaRs",
            href: tariff_knowledge_synthetic_atars_path,
            policy_class: TariffKnowledgeSyntheticAtar,
            active_when: %r{/tariff_knowledge_synthetic_atars},
            service: :uk,
          ),
          NavigationItem.new(
            text: "Gold Query Sets",
            href: evaluation_gold_query_sets_path,
            policy_class: EvaluationGoldQuerySet,
            active_when: %r{/evaluation_gold_query_sets},
            service: :uk,
          ),
          NavigationItem.new(
            text: "Synthetic Input Sets",
            href: new_evaluation_synthetic_input_set_path,
            policy_class: EvaluationSyntheticInputSet,
            active_when: %r{/evaluation_synthetic_input_sets},
            service: :uk,
          ),
          NavigationItem.new(
            text: "Evaluations",
            href: evaluation_experiments_path,
            policy_class: EvaluationExperiment,
            active_when: %r{/evaluation_experiments|/evaluation_runs},
            service: :uk,
          ),
        ],
      ),
      NavigationSection.new(
        key: :spimm,
        label: "SPIMM",
        href: nil,
        service: :xi,
        items: [
          NavigationItem.new(
            text: "Category Assessments",
            href: green_lanes_category_assessments_path,
            policy_class: GreenLanes::CategoryAssessment,
            active_when: /\/category_assessments/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Exemptions",
            href: green_lanes_exemptions_path,
            policy_class: GreenLanes::Exemption,
            active_when: /\/exemptions/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Measures",
            href: green_lanes_measures_path,
            policy_class: GreenLanes::Measure,
            active_when: /\/measures/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Exempting Overrides",
            href: green_lanes_exempting_overrides_path,
            policy_class: GreenLanes::ExemptingOverride,
            active_when: /\/exempting_overrides/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Update Notifications",
            href: green_lanes_update_notifications_path,
            policy_class: GreenLanes::UpdateNotification,
            active_when: /\/update_notifications/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Measure Type Mappings",
            href: green_lanes_measure_type_mappings_path,
            policy_class: GreenLanes::MeasureTypeMapping,
            active_when: /\/measure_type_mappings/,
            service: nil,
          ),
        ],
      ),
      NavigationSection.new(
        key: :manage_users,
        label: "Manage Users",
        href: users_path,
        service: nil,
        items: [],
      ),
      distribution_lists_section,
      NavigationSection.new(
        key: :configuration,
        label: "Configuration",
        href: configurations_path,
        items: [],
        service: :uk,
      ),
    ].compact
  end

  def visible_navigation_sections
    navigation_sections.filter_map do |section|
      next unless service_visible?(section)

      if section.items.present?
        visible_items = section.items.filter_map { |item| visible_navigation_item(item) }
        next if visible_items.empty?

        NavigationSection.new(
          key: section.key,
          label: section.label,
          href: section.href,
          items: visible_items,
          service: section.service,
        )
      else
        next unless policy_allows_section?(section)

        section
      end
    end
  end

  def current_navigation_section
    visible_navigation_sections.find { |section| section_active?(section) }
  end

  def current_navigation_item
    current_navigation_section&.items&.find { |item| item_active?(item) }
  end

  def current_navigation_tabs_section
    item = current_navigation_item
    return if item.nil? || item.tabs.blank?

    NavigationSection.new(
      key: :nested,
      label: item.text,
      href: item.href,
      items: item.tabs,
      service: item.service,
    )
  end

  def item_active?(item)
    return true if item.active_when.present? && active_nav_link?(item.active_when)
    return true if item.tabs.any? { |tab| item_active?(tab) }

    false
  end

  def section_active?(section)
    if section.items.present?
      section.items.any? { |item| item_active?(item) }
    else
      section.href.present? && active_nav_link?(Regexp.new(Regexp.escape(section.href)))
    end
  end

  def section_href(section)
    if section.items.present?
      section.items.first.href
    else
      section.href
    end
  end

private

  # Hidden when no Cognito user pool is configured, because the routes do not exist.
  def distribution_lists_section
    return unless TradeTariffAdmin.distribution_lists_enabled?

    NavigationSection.new(
      key: :distribution_lists,
      label: "Distribution lists",
      href: distribution_lists_path,
      service: nil,
      items: [],
    )
  end

  def service_visible?(record)
    return false if record.service == :uk && !TradeTariffAdmin::ServiceChooser.uk?
    return false if record.service == :xi && !TradeTariffAdmin::ServiceChooser.xi?

    true
  end

  def visible_navigation_item(item)
    return nil unless service_visible?(item)

    if item.tabs.any?
      visible_tabs = item.tabs.filter_map { |tab| visible_navigation_item(tab) }
      return nil if visible_tabs.empty?

      item.with(href: visible_tabs.first.href, tabs: visible_tabs)
    else
      return nil unless policy(item.policy_class).index?

      item
    end
  end

  def policy_allows_section?(section)
    case section.key
    when :manage_users
      policy(User).index?
    when :configuration
      policy(AdminConfiguration).index?
    when :distribution_lists
      policy(:distribution_list).index?
    else
      true
    end
  end
end
