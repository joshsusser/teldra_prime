# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def if_blank(str, alternate)
    str.blank? ? alternate : str
  end

  # flash_div
  # use to display specified flash messages
  # defaults to standard set: [:success, :message, :warning]
  # example:
  #   <%= flash_div %>
  # example with other keys:
  #   <%= flash_div :notice, :violation %>
  # renders like:
  #   <div class="flash flash-success">Positive - successful action</div>
  #   <div class="flash flash-message">Neutral - reminders, status</div>
  #   <div class="flash flash-warning">Negative - error, unsuccessful action</div>
  def flash_div(*keys)
    keys = [:success, :message, :warning] if keys.empty?
    keys.compact.collect do |key|
      flash[key].blank? ? nil : content_tag(:div, flash[key], :class => "flash flash-#{key}")
    end.compact.join("\n")
  end
  
  def current_user_name
    session[:user_id] ? User.find(session[:user_id]).name : "beautiful stranger"
  end
  
  def comment_period_options
    [['Never expire', -1],
     ['Are not allowed', 0], 
     ['Expire 24 hours after publishing',   1],
     ['Expire 1 week after publishing',     7],
     ['Expire 1 month after publishing',   30],
     ['Expire 3 months after publishing',  90]]
  end

  # defeat spam links by adding a rel="nofollow" attribute to <a> tags in submitted comments
  def nofollowize
    tokenizer = HTML::Tokenizer.new(text)
    out = ""
    while token = tokenizer.next
      node = HTML::Node.parse(nil, 0, 0, token, false)
      if node.tag? && node.name.downcase == "a"
        node.attributes["rel"] = "nofollow" unless node.attributes.nil?
      end
      out << node.to_s
    end
    out
  end

end
