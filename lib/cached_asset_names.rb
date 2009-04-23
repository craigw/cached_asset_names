if ActionController::Base.perform_caching
  ActionView::Helpers::AssetTagHelper.class_eval do
    def rewrite_asset_path(source)
      asset_id = rails_asset_id(source)
      if asset_id.blank?
        source
      elsif bust_cache?(source)
        source_parts = source.split(/\./)
        source_parts[0..-2].join('.') + "-v#{asset_id}." + source_parts[-1]
      else
        source + "?#{asset_id}"
      end
    end

    def join_asset_file_contents(paths)
      paths.collect { |path| 
        File.read(File.join(RAILS_ROOT, 'public', pre_cache_busting_filename(path)))
      }.join("\n\n")
    end

    def bust_cache?(source)
      source =~ %r{/(stylesheets|javascripts|images)/}
    end

    def pre_cache_busting_filename(path)
      if bust_cache?(path)
        path.gsub(/-v\d+\./, '.')
      else
        path.split("?").first
      end
    end
  end
end