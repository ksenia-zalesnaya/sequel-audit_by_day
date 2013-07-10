module Sequel
  module Plugins
    module AuditByDay
      require "set"

      class AuditKindNotFound < ::StandardError; end

      def self.configure(master, opts={})
        audit_foreign_key = opts[:foreign_key]
        default_valid_from = opts.fetch(:default_valid_from){ Time.utc(1000) }
        updated_by_regexp = opts.fetch(:updated_by_regexp){ /(.+)_updated_by_(.+)_id/ }
        raise Error, ":foreign_key options is required for audit" unless audit_foreign_key
        raise Error, ":foreign_key column does not exists for audit" unless master.columns.include? audit_foreign_key
        version_columns = {}
        master.version_class.columns.each do |column|
          next unless column.to_s =~ updated_by_regexp
          column_name, column_kind = $1, $2
          version_columns[column_name] ||= {}
          version_columns[column_name][column_kind] = column
        end
        master.instance_eval do
          @audit_foreign_key = audit_foreign_key
          @audit_checked_columns = Set.new version_columns.keys
          @audit_version_columns = version_columns
          @audit_default_valid_from = default_valid_from
        end
      end

      module ClassMethods
        attr_reader :audit_foreign_key, :audit_checked_columns,
          :audit_version_columns, :audit_default_valid_from

        def find_for(audited_id, at)
          where(audit_foreign_key => audited_id, :for => at).
            with_current_version.limit(1).all.first
        end

        def audit(master, previous_values, updated_values, update_time, updated_by)
          changed_values = updated_values.select do |column_name, updated_value|
            audit_checked_columns.include?(column_name.to_s) &&
            previous_values[column_name]!=updated_value
          end

          audit_for_day = find_for master.id, update_time
          audit_for_day ||= new({audit_foreign_key => master.id, :for => update_time})

          attrs = {}
          updated_by_kind = updated_by.audit_kind.to_s
          changed_values.each do |column_name, _|
            unless audit_version_columns[column_name.to_s].has_key? updated_by_kind
              raise AuditKindNotFound, "no audit column for column: #{column_name} and kind: #{updated_by_kind}"
            end
            audit_version_columns[column_name.to_s].each do |kind, column|
              if kind==updated_by_kind
                attrs[column] = updated_by.id
              else
                attrs[column] = nil
              end
            end
            attrs["#{column_name}_at"] = ::Sequel::Plugins::Bitemporal.point_in_time
          end
          audit_for_day.update_attributes attrs.merge(valid_from: audit_default_valid_from)
        end
      end
    end
  end
end
