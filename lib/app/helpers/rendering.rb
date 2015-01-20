module Integrity
  module Helpers
    module Rendering
      def stylesheets(*sheets)
        sheets.each do |sheet|
          haml_tag(:link, :href => path("#{sheet}.css"),
                   :type => 'text/css', :rel => 'stylesheet')
        end
      end

      def javascripts(*scripts)
        scripts.each do |script|
          haml_tag(:script, :src => path("#{script}.js"),
            :type => 'text/javascript')
        end
      end

      def show(view, options={})
        @title = breadcrumbs(*options[:title])
        haml view
      end

      def partial(template, locals={})
        haml("_#{template}".to_sym, :locals => locals, :layout => false)
      end

      def errors_on(object, field)
        return "" unless errors = object.errors.on(field)
        errors.map {|e| e.gsub(/#{field} /i, "") }.join(", ")
      end

      def error_class(object, field)
        object.errors.on(field).nil? ? "" : "with_errors"
      end

      def checkbox(name, condition, extras={})
        attrs = {:name => name, :type => "checkbox", :value => "1"}
        attrs[:checked] = !!condition
        attrs.update(extras)
      end

      def dropdown(name, id, options, selected="")
        haml_tag(:select, :id => id, :name => name) {
          options.each { |opt|
            haml_tag :option, opt, :value => opt, :selected => (opt == selected)
          }
        }
      end

      def dropdown_with_titles(name, id, options, selected="")
        haml_tag(:select, :id => id, :name => name) {
          options.each { |opt|
            haml_tag :option, opt[:title], :value => opt[:value], :selected => (opt[:value] == selected)
          }
        }
      end

      def notifier_form
        Notifier.available.each_pair { |name, klass|
          haml_concat haml(klass.to_haml, :layout => :notifier, :locals => {
            :notifier => name,
            :enabled  => current_project.notifies?(name),
            :config   => current_project.config_for(name) })
        }
      end

      def json(resource)
        headers "Content-Type" => "application/json; charset=utf-8"
        resource.to_json
      end

      def json_error(code, message)
        status code
        json({ "error" => { "code" => code, "message" => message } })
      end
    end
  end
end
