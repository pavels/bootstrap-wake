module WakeHelper

	def ico(html_class)
		raw "<span class=\"fa fa-#{html_class}\"></span>"
	end

	def wake_sort_params(col_name)
		if @wake_params[:order] == "#{col_name} ASC"
			@wake_params.merge :order=>"#{col_name} DESC"
		else
			@wake_params.merge :order=>"#{col_name} ASC"
		end
	end

	def wake_sort_by_link(col_name, title=col_name.humanize)
		link_to title, url_for(action: 'index', wake: wake_sort_params(col_name)), 
			class: "#{'text-success' if @wake_params[:order].to_s.starts_with?(col_name)}", 
			title: "Sort by this column."
	end

	def wake_filter_input(col_name)
		raw "<input id=\"WakeFilter-#{col_name}\" name=\"wake[filter][#{col_name}]\" 
			value=\"#{@wake_params[:filter][col_name]}\" 
			class=\"wake_filter_input form-control input-xsm\">"
		#		 style="display: inline; width: 100%;"
	end
	
	def wake_filter_reflection(the_model, refl_sym, html_options={})
		raise 'expecting symbol as refl_sym' unless refl_sym.is_a? Symbol

		refl = the_model.reflections[refl_sym]
		raise "reflection #{refl_name} expected to exist" unless refl

		choices = [['', nil]] + refl.klass.all.map{ |x| [nice_model_name(x), x.to_param] }		

    	# onchange = "document.location='#{controller.request.path}?wake[filter][#{key}]='+this.options[this.selectedIndex].value"
        selected = @wake_params[:filter] ? @wake_params[:filter][refl.foreign_key] : nil

        select "wake[filter]", refl.foreign_key, choices, {:selected=>selected}, html_options #, :onchange=>onchange
	end


	def wake_filter_enum(the_model, the_column, choices, html_options={})
		selected = @wake_params[:filter] ? @wake_params[:filter][the_column].to_s : nil
		select "wake[filter]", the_column, [['', nil]]+choices, {:selected=>selected}, html_options
	end


	def wake_order_by(the_column, label=the_column)
		#raise @wake_params.to_yaml
		if @wake_params[:order] and @wake_params[:order] == "#{the_column} ASC"
			link_to label, url_for(params.merge(:wake=>@wake_params.merge(:order=>"#{the_column} ASC" ))), class: 'text-success'
		elsif @wake_params[:order] and @wake_params[:order] == "#{the_column} DESC"
			link_to label, url_for(params.merge(:wake=>@wake_params.merge(:order=>"#{the_column} DESC" ))), class: 'text-success'
		else
			link_to label, url_for(params.merge(:wake=>@wake_params.merge(:order=>"#{the_column} ASC" )))
		end
	end


	def wake_filter_text(the_column)
		text_field_tag "wake[filter][#{the_column}]", @wake_params[:filter][the_column], class: 'form-control input-xsm'
	end

	def wake_list_destroy_checkbox(item)
		check_box_tag "destroy_ids[#{item.to_param}]", 1, false, onclick: '$(this).parent().removeClass("hover-child");', class: 'destroyCheckbox'
	end

	def wake_list_destroy_multiple_submit
		ret = raw link_to ico('trash-o'), "#", onclick: "$('#DestroyConfirmation').val('destroy'); $('#TheForm').submit();", class: 'btn btn-danger', title: 'Destroy records', confirm: 'Sure?'
		ret << raw('<input id="DestroyConfirmation" type="hidden" name="destroy" />')
		ret
	end

end