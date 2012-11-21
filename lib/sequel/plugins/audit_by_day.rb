module Sequel
  module Plugins
    module AuditByDay
      require "set"

      def self.configure(master, opts={})
        audit_foreign_key = opts[:foreign_key]
        default_valid_from = opts.fetch(:default_valid_from){ Time.utc(1000) }
        raise Error, ":foreign_key options is required for audit" unless audit_foreign_key
        raise Error, ":foreign_key column does not exists for audit" unless master.columns.include? audit_foreign_key
        updated_by_suffix = "_updated_by_id"
        version_columns = master.version_class.columns.collect do |column|
          column_str = column.to_s
          if column_str.end_with? updated_by_suffix
            column_str = column_str.gsub(updated_by_suffix, "").to_sym
          end
        end.compact
        master.instance_eval do
          @audit_foreign_key = audit_foreign_key
          @audit_checked_columns = Set.new version_columns
        end
      end

      module ClassMethods
        attr_reader :audit_foreign_key, :audit_checked_columns, :default_valid_from

        def find_for(audited_id, at)
          where(audit_foreign_key => audited_id, :for => at).with_current_version.first
        end

        def audit(master, previous_values, updated_values, update_time, updated_by)
          changed_values = updated_values.select do |column, updated_value|
            audit_checked_columns.include?(column) &&
            previous_values[column]!=updated_value
          end
          audit_for_day = find_for master.id, update_time
          audit_for_day ||= new({audit_foreign_key => master.id, :for => update_time})
          if updated_by.respond_to?(:admin_in_audit?) && updated_by.admin_in_audit?
            attrs = {admin_user_id: updated_by.id}
          else
            attrs = Hash[changed_values.collect{|column, _| ["#{column}_updated_by_id", updated_by]}]
            attrs[:admin_user_id] = nil
          end
          audit_for_day.update_attributes attrs.merge({
            partial_update: true, valid_from: self.class.default_valid_from
          })
        end
      end
    end
  end
end
