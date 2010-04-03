if ActionController::Base.perform_caching
  ActionView::Helpers::AssetTagHelper.class_eval do
    def rewrite_asset_path(source)
      RAILS_DEFAULT_LOGGER.warn "The cached_asset_names plugin " +
                                "functionality has been included in Rails. " +
                                "The plugin is now deprecated."
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

    def build_number
      # Ideally you should set this to the build number of your deployment to
      # get consistent versions across all of your application servers, but
      # we need to provide a default just in case.
      @@build_number ||= Time.now.to_i
    end

    def write_asset_file_contents_with_cached_asset_names(asset_file_path, asset_paths)
      write_asset_file_contents_without_cached_asset_names(asset_file_path, asset_paths)
      if asset_file_path =~ /\.css$/
        asset_file_contents = File.read(asset_file_path).split(/\n/)
        asset_file_contents.map! { |line|
          if line =~ /url\((\'?\/images\/.*\'?)\)/
            uri = line.scan(/url\((\'?\/images\/.*\'?)\)/).to_a[0].to_a[0]
            destination_parts = uri.split(/\./)
            file_ext = destination_parts.pop
            destination_parts[-1] += "-v#{build_number}"
            destination_parts.push file_ext
            destination = destination_parts.join('.')
            RAILS_DEFAULT_LOGGER.info "[cache] Rewriting #{uri} to cached url #{destination} in #{asset_file_path}"
            line.gsub!(uri, destination)
            line
          else
            line
          end
        }
        File.open(asset_file_path, 'w') do |f|
          f.write asset_file_contents
          f.flush
        end
      end
    end
    alias_method_chain :write_asset_file_contents, :cached_asset_names
  end
end