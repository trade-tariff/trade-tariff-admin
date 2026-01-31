module NavigationHelper
  NavigationSection = Data.define(:key, :label, :href, :items, :service)
  NavigationItem = Data.define(:text, :href, :policy_class, :active_when, :service)

  def navigation_sections
    @navigation_sections ||= [
      NavigationSection.new(
        key: :ott_admin,
        label: "OTT Admin",
        href: nil,
        service: nil,
        items: [
          NavigationItem.new(
            text: "Section & chapter notes",
            href: notes_sections_path,
            policy_class: SectionNote,
            active_when: /\/notes/,
            service: nil,
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
            active_when: /\/search_references/,
            service: nil,
          ),
          NavigationItem.new(
            text: "Labels",
            href: goods_nomenclature_labels_path,
            policy_class: GoodsNomenclatureLabel,
            active_when: /\/goods_nomenclature_labels/,
            service: :uk,
          ),
          NavigationItem.new(
            text: "Configuration",
            href: classification_configurations_path,
            policy_class: AdminConfiguration,
            active_when: /\/classification_configurations/,
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
    ]
  end

  def visible_navigation_sections
    navigation_sections.filter_map do |section|
      next if section.service == :uk && !TradeTariffAdmin::ServiceChooser.uk?
      next if section.service == :xi && !TradeTariffAdmin::ServiceChooser.xi?

      if section.items.present?
        visible_items = section.items.select { |item| item_visible?(item) }
        next if visible_items.empty?

        NavigationSection.new(
          key: section.key,
          label: section.label,
          href: section.href,
          items: visible_items,
          service: section.service,
        )
      else
        # Standalone section (e.g. Manage Users) — check policy on href
        next unless policy_allows_section?(section)

        section
      end
    end
  end

  def current_navigation_section
    visible_navigation_sections.find { |section| section_active?(section) }
  end

  def section_active?(section)
    if section.items.present?
      section.items.any? { |item| active_nav_link?(item.active_when) }
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

  def item_visible?(item)
    return false if item.service == :uk && !TradeTariffAdmin::ServiceChooser.uk?
    return false if item.service == :xi && !TradeTariffAdmin::ServiceChooser.xi?

    policy(item.policy_class).index?
  end

  def policy_allows_section?(section)
    case section.key
    when :manage_users
      policy(User).index?
    else
      true
    end
  end
end
