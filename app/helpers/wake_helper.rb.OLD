module WakeHelper
  
  # def paginate(*args)
  #   will_paginate args
  # end
    
  def ico(x, color=nil, title=nil)
    title ||= "wake.ico.#{x}".tt
    color ||= "white"
    raw "<i class=\"icon-#{x} icon-#{color}\" title='#{title}'></i> "
  end


  def wdbg(x)
    false ? raw("<div class=\"wakeDebug\">#{x}</div>") : ''
  end

  def wnote(x)
    true ? raw("<div class=\"wakeNote\">NOTE: #{x}</div>") : ''
  end

  def werror(x)
    true ? raw("<div class=\"wakeError\">ERROR: #{x}</div>") : ''
  end
  
  def menu_link_to(label, path)
    req_path = request.path.gsub(/\/\//, "/")
    liclass = req_path.starts_with?(path) ? "active" : ""
    out = ""
    out << "<li class=\"#{liclass}\">"
    out << link_to(label, path)
    out << "</li>"
    return raw out
  end

  def menu_match(*args)
    return false if @menu_matched
    args = args.first if args.first.is_a? Array
    req_path = request.path.gsub(/\/\//, "/")
    for arg in args
        if req_path.starts_with? arg
          @menu_matched = true
          return true
        end
    end
    return false
  end
  
  
  def wake_referer_param?(*args)
    x = session[:wake_referer_params]
    for arg in args
      return false if x.blank?
      return true if x[arg.to_s] == true
      x = x[arg.to_s]
    end
    not x.blank?
  end

  def wake_click_order_by(column, _label=nil)
    _label ||= column.gsub(/^.*\./,'').humanize
    o = @wake_params[:order]
    if o and o.include? column.to_s
      no = o =~ /ASC/ ? o.gsub(/ASC/,'DESC') : o.gsub(/DESC/, 'ASC')
      link_to _label, url_for(:action=>'index', :wake=>@wake_params.merge(:order=>no)), :class=>'selected'
    else
      link_to _label, url_for(:action=>'index', :wake=>@wake_params.merge(:order=>"#{column.to_s} ASC"))
    end
  end

  def wake_check_box(item)
    'x'
  end

  # def wake_icon(ident, alt=nil)
  #   ident = ident.to_s
  #   raw '<img src="/wake/icons/'+ident+'.png" alt="'+(alt||ident)+'" title="'+(alt||ident)+'">'
  # end

  def wake_onclick(item)
#    raise item.to_yaml if item.nil?
    raw "onclick=\"document.location='#{url_for :action=>'edit', :id=>item, :wake=>@wake_params}'\""
  end

  def wake_onclick_remote(item)
    url = url_for :action=>'edit', :id=>item
    raw "onclick=\"$.ajax({url: '#{url}.js', data: 'page=#{params[:page]}'});\""
  end

  def wake_hl(string)
    @_search ||= @wake_params[:search]    
#    raise "'#{sanitize @_search}' vs '#{sanitize string}'"   

    # return string if @_search.blank? or string.blank?
    # @_regexp ||= Regexp.new("(#{sanitize(@_search)})", Regexp::EXTENDED|Regexp::IGNORECASE)
    # raw sanitize(string.to_s).gsub @_regexp, "<span class=\"wake_hl\">\\1</span>"
    
    return string if @_search.blank? or string.blank?
    @_regexp ||= /(#{sanitize(@_search)})/ # , Regexp::EXTENDED|Regexp::IGNORECASE)
    raw sanitize(string.to_s).gsub @_regexp, "<span class=\"wake_hl\">\\1</span>"
  end

  # def wake_star_button(item)
  #   link_to raw(wake_icon(item.is_star? ? :star_on : :star_off)), {:action=>'toggle_star', :id=>item}, :method=>:post
  # end

  def wake_field_error(attr_sym)
    raw @item.errors.empty? ? '' : "<span class=\"error\">#{@item.errors[attr_sym].first}</span>"
  end
  
  # def wake_select(collection, key=nil)
  #   key ||= collection.first.class.to_s.underscore + '_id'
  #   
  #   select
  # end

  def wake_filter_enum(key, choices)
	  choices = [['', nil]] + choices
		url = url_for :action=>'index'		

		filter_params = "?"

		for k,v in @wake_params[:filter]
		  next if k == key
  		filter_params << "wake[filter][#{k}]=#{v}&"
		end if @wake_params[:filter]

		for k,v in @wake_params[:filter_range]
  		filter_params << "wake[filter_range][#{k}]=#{v}&"
	  end if @wake_params[:filter_range]

    for r in [:search, :order]
  		filter_params << "wake[#{r}]=#{@wake_params[r]}&" if @wake_params[r]
  	end
#  		filter_params << "wake[order]=#{@wake_params[:order]}&" if @wake_params[:order]

	  onchange = "document.location='#{url}#{URI.escape filter_params}wake[filter][#{key}]='+this.options[this.selectedIndex].value"
		selected = @wake_params[:filter] ? @wake_params[:filter][key] : nil
	  select 'not', 'important', choices, {:selected=>selected}, :onchange=>onchange
  end


	def wake_filter_exclusive(collection, key=nil, name=:name)
		key ||= collection.first.class.to_s.underscore + '_id'

	  choices = [['', nil]] + collection.map{ |x| [x.send(name),x.id] }
		url = url_for :action=>'index'

		filter_params = "?"

		for k,v in @wake_params[:filter]
		  next if k == key
  		filter_params << "wake[filter][#{k}]=#{v}&"
		end if @wake_params[:filter]

		for k,v in @wake_params[:filter_range]
  		filter_params << "wake[filter_range][#{k}]=#{v}&"
	  end if @wake_params[:filter_range]

    #		filter_params << "wake[search]=#{@wake_params[:search]}&" if @wake_params[:search]
    for r in [:search, :order]
  		filter_params << "wake[#{r}]=#{@wake_params[r]}&" if @wake_params[r]
  	end

	  onchange = "document.location='#{url}#{URI.escape filter_params}wake[filter][#{key}]='+this.options[this.selectedIndex].value"
		selected = @wake_params[:filter] ? @wake_params[:filter][key] : nil
	  select 'not', 'important', choices, {:selected=>selected}, :onchange=>onchange
	end

  def wake_form_select(f,column,array)
    if f.object.new_record? and @wake_params[:filter][column]
      f.select column, [[nil,nil]]+array.map{ |x| [x.name, x.id] }, :selected=>@wake_params[:filter][column]
    else
      f.select column, [[nil,nil]]+array.map{ |x| [x.name, x.id] }
    end
  end

  
  def wake_form_url
  	@item.new_record? ? {:action=>"create", :wake=>params[:wake]} : {:action=>"update",:id=>@item.id, :wake=>params[:wake]}
  end

  def wake_with_filter(path, fltr)
    if path.is_a? Hash
      path.merge!(:wake=>{:filter=>fltr})
    elsif path.is_a? Symbol
      send path, :wake=>{:filter=>fltr}
    else
      raise 'unexpected'
    end
  end

  def wake_destroy_button(item)
    return '' if not item.wake_destroyable? if item.respond_to? :wake_destroyable?
    link_to ico("remove","white") + "wake.button.destroy".tt, {:action=>'destroy',:id=>item, :wake=>params[:wake]}, :class=>"btn btn-danger",
      :method=>:delete, :data=>{:confirm=>'wake.general.confirm_destroy'.tt(:item=>item)}
  end


  def wake_new_button(params={})
    link_to ico("plus","white") + 'wake.button.new'.tt, {:action=>'new', :wake=>@wake_params}, {:class=>'btn btn-primary'}.merge(params)
  end

  def wake_edit_button(link)
    link_to ico("edit","white") + 'wake.button.edit'.tt,link,{:class=>'btn btn-warning'}
  end

  def wake_back_button(params={})
      link_to 'wake.button.back'.tt, {:action=>'index', :wake=>@wake_params}, {:class=>'btn'}.merge(params)
  end 

  def wake_save_button(form)
    form.submit "wake.button.save".tt, :class => "btn btn-primary"
  end  

  def wake_info
    #raw('<p class="text-info">') + @wake_info + raw('</p>')
    raw('<h4>') + @wake_info + raw('</h4>')
  end
  
  
  alias :wo :wake_onclick
  alias :wor :wake_onclick_remote
  alias :wcob :wake_click_order_by
  alias :whl :wake_hl  
  alias :wfe :wake_field_error
  alias :wwf :wake_with_filter
#  alias :wico :wake_icon
  
end
