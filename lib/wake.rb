require "wake/version"
require "wake/engine"

# ------------ W A K E ----------------
# for Rails 3 + 4

# todo --- case in/sensitive search

# ked sa rozsirujem este o non-ajax like ajax verziu ... ? treba to ?
# + wrapper treba dodat

# GET   /photos   index   display a list of all photos
# GET   /photos/new   new   return an HTML form for creating a new photo
# POST  /photos   create  create a new photo
# GET   /photos/:id   show  display a specific photo
# GET   /photos/:id/edit  edit  return an HTML form for editing a photo
# PUT   /photos/:id   update  update a specific photo
# DELETE  /photos/:id   destroy   delete a specific photo

# :wake_filter => { 
#   :assoc_item_id => id ???
#   :order => 'table.column ASC, table2.column ASC'
#   :search => 'pattern'
#   :filter => {:column=>'value'}
#   :filter_range => ??
#   :filter_ids => ??
# }
#
# + wake_referer_params
# + wake_constraints
#

#vrequire "wake/engine"
require 'kaminari'

module Kaminari
  module Helpers
    class Tag
      def page_url_for(page)
        @template.url_for @params.merge(@param_name => page)
      end
    end
  end  
end

Kaminari.configure do |config|
  config.param_name = 'wake[page]'
end


# module Kaminari
#   module ActiveRecordRelationMethods
#     def total_count
# #      raise 'hovno'
#       @items_total_count || super
#     end
#   end
# end

class String
  def tt(options={})
    I18n.translate(self, {:default=>self}.merge(options))
  end
end

module Wake
    
  #autoload :WakeHelper, '../app/helpers/wake_helper'
    
  # --- defaults ---
  
  module Defaults
    PER_PAGE = 30
  end
  
  module Extension
    # Wake the controller!
    #
    # options:
    #   * model => :the_model
    #   * prefix => "the_prefix"
    #   * within_module => 'MyEngine'
    #
    def wake(options={})
      # include actions
      self.send :include, ClassMethods
      # i want a helper too
      self.send :helper, :wake
      # setup before filter
      send :before_filter, :wake_prepare
      
      hi_there_hackers = to_s.gsub(/.*::|Controller/,'').singularize
      model_str = (options[:model] ? options[:model].to_s : hi_there_hackers).camelize
      ident_str = (options[:prefix] ? options[:prefix].to_s : hi_there_hackers).underscore

#      _module.const_get '#{model_str}'
      
      send :class_eval, <<-eos
        def _module
          #{options[:within_module] ? options[:within_module].camelize : 'self'}
        end
        def _model
          #{options[:within_module] ? "#{options[:within_module].camelize}::" : ''}#{model_str.camelize}
        end
        def _model_sym
          :#{model_str.underscore}
        end
        def _ident
          "#{ident_str}"
        end
      eos
      
    end
  end
  
  
  module ClassMethods   
  
    def index
      return multi_destroy if params[:destroy] == 'destroy'

      wake_list  
      render :action => _ident+'_list'
    end
    
    def new
      @item ||= _model.new
#      params[_model_sym].each{ |k,v| @item.send "#{k}=", v} if params[_model_sym]
      @item.attributes = params[_model_sym] if params[_model_sym]
      @item.attributes = wake_constraints if wake_constraints
   
      respond_to do |format|      
        format.html { render :action => _ident+'_form' } #render_list_or_form 
        format.js { render :template => '/wake/form' }
      end
    end
  
  
    def create
      begin  
        @item ||= _model.new
        @item.attributes = params[_model_sym]
        @item.attributes = wake_constraints if wake_constraints
        ret = @item.save
      rescue Exception => @exception
        wake_log_exception
        ret = nil
      end

      if ret
        flash[:success] = "wake.#{_ident}.create_ok".tt
        respond_to do |format|
          format.html { redirect_to :action=>'edit', :id=>@item.to_param, :wake=>@wake_params }
          format.js { render :template=>'/wake/redirect' } 
        end
      else
        flash.now[:error] = @exception ? @exception.message : @item.errors.first.to_s
        respond_to do |format|
          format.html { render :action => _ident+'_form' }
          format.js { render :template => '/wake/form' }
        end
      end
    end
  
  
    def show
      edit
    end
  
    def edit
      respond_to do |format|
        format.html { render :action => _ident+'_form' } #
        format.js { render :template=>'/wake/form' }
      end
    end  
  
    def update
      begin
        params[_model_sym].each do |k,v|
          if v.kind_of? ActionDispatch::Http::UploadedFile
            data = File.read(v.tempfile.to_path.to_s)
            data.force_encoding "ASCII-8BIT"
            @item.send("#{k}=", data)
          else
            @item.send("#{k}=", v)
          end
        end
        @item.attributes = wake_constraints if wake_constraints
        ret = @item.save
      rescue Exception => @exception
        wake_log_exception
        ret = nil
      end
    
      if ret

        respond_to do |format|
          format.html do
            flash[:success] = "wake.#{_ident}.update_ok".tt
            redirect_to :action=>'edit', :wake=>params[:wake]
          end
          format.js do
            flash.now[:success] = "wake.#{_ident}.update_ok".tt
            render :template => '/wake/update'
          end
        end

      else       
        logger.debug @item.errors.to_yaml if not ret == false
        flash_msg = @exception ? @exception.message : @item.errors.first.to_s

        respond_to do |format|
          format.html do
            flash.now[:error] = flash_msg #{}"wake.#{_ident}.update_error".tt
            render action: _ident+'_form'
          end
          format.js do
            flash.now[:error] = flash_msg #{}"wake.#{_ident}.update_error".tt
            render template: '/wake/update'
          end
        end

      end

    end
  
  
    def destroy
      begin
        ret = @item.destroy
        raise RuntimeError, 'Destroy failed.' unless ret.is_a? _model or ret==[]
      rescue Exception => @exception
        flash.now[:error] = @exception.message # "wake.#{_ident}.destroy_error"
        wake_log_exception    
        wake_list
        render :action => _ident+'_form'
      else
        flash[:success] = "wake.#{_ident}.destroy_ok".tt
        redirect_to :action=>'index', :id=>nil, :wake=>params[:wake]
      end
    end


    def multi_destroy
      begin 
        for the_id in (params[:destroy_ids]||{}).keys
          #item = @model.where( @model.primary_key=>the_id ).first
          #item.destroy! if item
          @model.destroy the_id
        end
      rescue Exception => @exception
        wake_log_exception
        flash[:error] = @exception.message
        redirect_to :action=>'index', :id=>nil, :wake=>params[:wake]
      else
        flash[:success] = "wake.#{_ident}.multi_destroy_ok".tt
        redirect_to :action=>'index', :id=>nil, :wake=>params[:wake]
      end
    end

    
    # --- content for ---

    def view_context
      super.tap do |view|
        (@_content_for || {}).each do |name,content|
          view.content_for name, content
        end
      end
    end
    def content_for(name, content) # no blocks allowed yet
      @_content_for ||= {}
      if @_content_for[name].respond_to?(:<<)
        @_content_for[name] << content
      else
        @_content_for[name] = content
      end
    end
    def content_for?(name)
      @_content_for[name].present?
    end  
  
    # --- private ---
  
    private
    def wake_prepare
      logger.debug "Wake PREPARE"
      params[:wake] ||= {}
      params[:wake][:filter] ||= {}
#      params[:wake][:page] = params[:page] #if params[:page]
      @wake_params = params[:wake]      
      @item ||= _model.find params[:id] if params[:id]
      
      if @item and wake_constraints 
        # check if everything is all right
        for k,v in wake_constraints
          next if @item.send(k) == v
          flash[:error] = 'Sorry, this is illegal.'
          redirect_to :action=>'index'
          return false
        end         
      end
             
      for k,v in params
        if k.ends_with? "_id"
          name = k.chop.chop.chop
#          instance_variable_set "@#{name}".to_s, Class.const_get(name.camelcase).find_by_id(v)
          if _module == self
            instance_variable_set "@#{name}".to_s, name.camelize.constantize.find_by_id(v)
          else
            instance_variable_set "@#{name}".to_s, "#{_module}::#{name.camelize}".constantize.find_by_id(v)
          end
        end
      end  
    end
  
    def wake_list
      @items ||= _model
      @items = @items.joins _model.wake_joins if _model.respond_to? :wake_joins
      @items = @items.where wake_constraints if wake_constraints
      @items = @items.includes _model.wake_includes if _model.respond_to? :wake_includes
      
      #raise @wake_params.to_yaml
      
#      begin
        if @wake_params[:filter]
          for k,v in @wake_params[:filter]
            Rails.logger.debug "-- k/v: #{k} - #{v}"
            next if v.blank?
            ksat = k.gsub /[^A-Za-z0-9\._]/, ''
            #vsat = v.gsub /[^ A-Za-z0-9%<>=\.\-\[\]_]/, ''
            vsat = v
            
            if ['IS TRUE','IS NOT TRUE', 'IS NULL', 'IS NOT NULL'].include? vsat
              @items = @items.where "#{ksat} #{vsat}"

            elsif vsat =~ /^[><=].* .*/
              operator = vsat.gsub(/([><=].*) (.*)/, '\1')
              value = vsat.gsub(/([><=].*) (.*)/, '\2')
              @items = @items.where "#{ksat} #{operator} ?", value
            else
              @items = @items.where "#{ksat} LIKE ?", vsat
              #raise "#{ksat} LIKE ? --#{vsat}--"
            end
          end
        end
      # rescue Exception => e
      #   flash.now[:error] = @exception.message
      #   @items = nil
      #   return false
      # end

      #raise 'fuck' 
    
      if @wake_params[:filter_range] and !@wake_params[:filter_range][:key].blank?
        begin
          @wake_params[:filter_range][:from].strip!
#          from = @wake_params[:filter_range][:from].blank? ? nil : DateTime.parse(@wake_params[:filter_range][:from])
          from = @wake_params[:filter_range][:from].blank? ? nil : begin
            if @wake_params[:filter_range][:key] =~ /.*(_at|_on)$/
              DateTime.parse @wake_params[:filter_range][:from]
            else
              @wake_params[:filter_range][:from].gsub /[^0-9\.]/, ''
            end
          end
        rescue ArgumentError
          from, @wake_params[:filter_range][:from_error] = nil, true
        end
        begin
          @wake_params[:filter_range][:until].strip!
#          untl = @wake_params[:filter_range][:until].blank? ? nil : DateTime.parse(@wake_params[:filter_range][:until])
          untl = @wake_params[:filter_range][:until].blank? ? nil : begin
            if @wake_params[:filter_range][:key] =~ /.*(_at|_on)$/
              DateTime.parse @wake_params[:filter_range][:until]
            else
              @wake_params[:filter_range][:until].gsub /[^0-9\.]/, ''
            end
          end
        rescue ArgumentError
          untl, @wake_params[:filter_range][:until_error] = nil, true
        end
        
        key = @wake_params[:filter_range][:key].gsub /[^a-z\+\-\._ ]/, ''
      
        if key.include? '+'
          tmp = key.split('+').map{ |x| x.strip }
          key = "DATE_ADD(#{tmp.first}, INTERVAL #{tmp.last} DAY)"
        end
        if key.include? '-'
          tmp = key.split('-').map{ |x| x.strip }
          key = "DATE_SUB(#{tmp.first}, INTERVAL #{tmp.last} DAY)"
        end
        
  #      DATE_ADD(made_out_on, INTERVAL maturity DAY)     
  #      raise key.inspect
      
        if from and untl
          @items = @items.where("? <= #{key} AND #{key} <= ?", from, (untl))
#          raise "#{from} - #{untl}"
        elsif from
          @items = @items.where("? <= #{key}", from)
        elsif untl
          if @wake_params[:filter_range][:key] =~ /.*(_at|_on)$/
            @items = @items.where("#{key} <= ?", untl+1)
          else
            @items = @items.where("#{key} <= ?", untl)
          end
        end
      end

      if @wake_params[:order]
        @items = @items.reorder @wake_params[:order] #+((wake_params[:desc]=='true' or wake_params[:desc]==true)  ? ' DESC' : ' ASC')) 
      end
    

      if @wake_params[:search]
        where_array = [(_model.wake_search_fields.join(" LIKE ? OR ")+' LIKE ?')] + ["%#{@wake_params[:search]}%"]*_model.wake_search_fields.size
        @items = @items.where where_array      
#        @item ||= @items.first if @items.size == 1
      end
    
      if @wake_params[:filter_ids]
        the_ids = @wake_params[:filter_ids].map { |x| x=x.to_i }
        where_array = [(" id = ? OR ")*(the_ids.size-1)+' id = ?'] + the_ids
        @items = @items.where where_array
      end

      # kaminari      
      @items_total_count_hack = @items.count if @items_total_count_hack
      @items.instance_variable_set :@total_count, @items_total_count_hack


      begin
        @items = @items.page(@wake_params[:page]).per(@wake_params[:per]||Defaults::PER_PAGE)
        just_to_force_the_select_itself = @items.all
      rescue ActiveRecord::StatementInvalid => @exception
        flash.now[:error] = @exception.message
        @items = nil
        return false
      else
        #Rails.logger.debug "Wake: #{@items.to_sql}"
        return true
      end
    end

    def wake_log_exception
      Rails.logger.error "#{@exception.message}\n\n#{@exception.backtrace.join "\n"}"
    end
    
    def wake_referer_params
      session[:wake_referer_params] = wake_strip_multipart params
    end
    
    def wake_constraints
      nil
    end
    
    
    def wake_strip_multipart(hash)
      return nil if hash.blank?
      return true if not hash.is_a? Hash
      ret = {}
      hash.each do |k,v| 
        ret[k] = wake_strip_multipart v
      end
      ret
    end
    
  end
      
end

ActionController::Base.send :extend, Wake::Extension


  # --- included ---

#   def self.included(base)
#     # # define & include session vars    
#     # base.send :define_method, :session_vars do
#     #   [:order,:search]
#     # end unless base.send :method_defined?, :session_vars
#     # 
#     # base.send :include, SessionVars
#     
#     base.send :before_filter, :wake_prepare
#     
#     # define _model and _ident ... guess form controller name
#     class_str = base.to_s.gsub(/.*::|Controller/,'').singularize    
# #    raise class_str
#     
#     # base.send :define_method, :_model do
#     #   Object.const_get class_str
#     # end unless base.send :method_defined?, :_model
#     # 
#     # base.send :define_method, :_ident do
#     #   class_str.underscore
#     # end unless base.send :method_defined?, :_ident    
#     
#     base.send :class_eval, <<-eos
#       def _model
#         #{class_str}
#       end
#       
#       def _ident
#         "#{class_str.underscore}"
#       end
#     eos
#   end    
  
#  def module
  




#      @items = @items.all
      # will_paginate
#      @items = @items.paginate(:page => @wake_params[:page], :per_page => Defaults::PER_PAGE)

      
      

#      raise "L: #{@items.to_sql}"
    
      # expecting model to have:
      # def wake_includes, wake_search_fields
