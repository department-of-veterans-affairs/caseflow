# frozen_string_literal: true

# See annotate gem: https://github.com/ctran/annotate_models#configuration-in-rails
if Rails.env.development?
  require "annotate"
  task :set_annotation_options do
    # You can override any of these by setting an environment variable of the same name.
    Annotate.set_defaults(
      "active_admin" => "false",
      "additional_file_patterns" => [],
      "routes" => "false",
      "models" => "true",
      "position_in_routes" => "bottom",
      "position_in_class" => "bottom", # Add to the bottom to avoid collisions with custom comments
      "position_in_test" => "bottom",
      "position_in_fixture" => "bottom",
      "position_in_factory" => "bottom",
      "position_in_serializer" => "bottom",
      "show_foreign_keys" => "true",
      "show_complete_foreign_keys" => "true",
      "show_indexes" => "false",
      "simple_indexes" => "true",
      "model_dir" => "app/models",
      "root_dir" => "",
      "include_version" => "false",
      "require" => "",
      "exclude_tests" => "true",
      "exclude_fixtures" => "true",
      "exclude_factories" => "true",
      "exclude_serializers" => "true",
      "exclude_scaffolds" => "true",
      "exclude_controllers" => "true",
      "exclude_helpers" => "true",
      "exclude_sti_subclasses" => "true", # Not needed
      "ignore_model_sub_dir" => "false",
      "ignore_columns" => nil,
      "ignore_routes" => nil,
      "ignore_unknown_models" => "false",
      "hide_limit_column_types" => "integer,bigint,boolean",
      "hide_default_column_types" => "json,jsonb,hstore",
      "skip_on_db_migrate" => "true", # true => don't run annotate with every db:migrate b/c it adds more time
      "format_bare" => "true",
      "format_rdoc" => "false",
      "format_yard" => "false",
      "format_markdown" => "false",
      "sort" => "false", # Keep the same order as in schema.rb
      "force" => "false",
      "frozen" => "false",
      "classified_sort" => "true",
      "trace" => "false",
      "wrapper_open" => "(This section is updated by the annotate gem)",
      "wrapper_close" => nil,
      "with_comment" => "false" # Leave out comments because some of them are very long
    )
  end

  Annotate.load_tasks
end
