module AgentHelper
  def agent_show_view(agent)
    name = agent.short_type.underscore
    if File.exist?(Rails.root.join("app", "views", "agents", "agent_views", name, "_show.html.erb"))
      File.join("agents", "agent_views", name, "show")
    end
  end

  def scenario_links(agent)
    agent.scenarios.map { |scenario|
      link_to(scenario.name, scenario, class: "label", style: style_colors(scenario))
    }.join(" ").html_safe
  end

  def agent_show_class(agent)
    agent.short_type.underscore.dasherize
  end

  def agent_schedule(agent, delimiter = ', ')
    return 'n/a' unless agent.can_be_scheduled?

    case agent.schedule
    when nil, 'never'
      agent_controllers(agent, delimiter) || 'Never'
    else
      [
        agent.schedule.humanize.titleize,
        *(agent_controllers(agent, delimiter))
      ].join(delimiter).html_safe
    end
  end

  def agent_controllers(agent, delimiter = ', ')
    if agent.controllers.present?
      agent.controllers.map { |agent|
        link_to(agent.name, agent_path(agent))
      }.join(delimiter).html_safe
    end
  end

  def agent_dry_run_with_event_mode(agent)
    case
    when agent.cannot_receive_events?
      'no'.freeze
    when agent.cannot_be_scheduled?
      # incoming event is the only trigger for the agent
      'yes'.freeze
    else
      'maybe'.freeze
    end
  end

  def agent_type_icon(agent, agents)
    receiver_count = links_counter_cache(agents)[:links_as_receiver][agent.id] || 0
    control_count  = links_counter_cache(agents)[:control_links_as_controller][agent.id] || 0
    source_count   = links_counter_cache(agents)[:links_as_source][agent.id] || 0

    if control_count > 0 && receiver_count > 0
      content_tag ('span') do
        concat icon_tag('glyphicon-arrow-right')
        concat tag('br')
        concat icon_tag('glyphicon-log-out', class: 'glyphicon-flipped')
      end
    elsif control_count > 0 && receiver_count == 0
      icon_tag('glyphicon-log-out', class: 'glyphicon-flipped')
    elsif receiver_count > 0 && source_count == 0
      icon_tag('glyphicon-arrow-right')
    elsif receiver_count == 0 && source_count > 0
      icon_tag('glyphicon-arrow-left')
    elsif receiver_count > 0 && source_count > 0
      icon_tag('glyphicon-transfer')
    else
      icon_tag('glyphicon-unchecked')
    end
  end

  private

  def links_counter_cache(agents)
    @counter_cache ||= {}.tap do |cache|
      agent_ids = agents.map(&:id)
      cache[:links_as_receiver] = Link.where(receiver_id: agent_ids).group(:receiver_id).pluck('receiver_id', 'count(receiver_id) as id').to_h
      cache[:links_as_source] = Link.where(source_id: agent_ids).group(:source_id).pluck('source_id', 'count(source_id) as id').to_h
      cache[:control_links_as_controller] = ControlLink.where(controller_id: agent_ids).group(:controller_id).pluck('controller_id', 'count(controller_id) as id').to_h
    end
  end
end
